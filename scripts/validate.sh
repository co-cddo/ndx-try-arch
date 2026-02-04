#!/usr/bin/env bash
# =============================================================================
# validate.sh - Run quality gates on documentation
# =============================================================================
#
# Usage: ./scripts/validate.sh [options]
#
# Options:
#   --all           Run all validation gates (default)
#   --structure     Run structure validation only
#   --content       Run content validation only
#   --links         Run link validation only
#   --mermaid       Run Mermaid diagram validation only
#   --coverage      Run coverage validation only
#   --fix           Attempt to auto-fix common issues
#   --json          Output results as JSON
#   -v, --verbose   Verbose output
#
# =============================================================================

# Requires bash 4+ for associative arrays, but we'll make it compatible
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DOCS_DIR="$ROOT_DIR/docs"
META_DIR="$DOCS_DIR/.meta"
MANIFEST="$META_DIR/manifest.json"
QUALITY_REPORT="$META_DIR/quality-report.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_DOCS=0
PASSED_DOCS=0
FAILED_DOCS=0
TOTAL_ISSUES=0

# Options
VERBOSE=false
JSON_OUTPUT=false
RUN_ALL=true
RUN_STRUCTURE=false
RUN_CONTENT=false
RUN_LINKS=false
RUN_MERMAID=false
RUN_COVERAGE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) RUN_ALL=true; shift ;;
        --structure) RUN_ALL=false; RUN_STRUCTURE=true; shift ;;
        --content) RUN_ALL=false; RUN_CONTENT=true; shift ;;
        --links) RUN_ALL=false; RUN_LINKS=true; shift ;;
        --mermaid) RUN_ALL=false; RUN_MERMAID=true; shift ;;
        --coverage) RUN_ALL=false; RUN_COVERAGE=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help)
            head -30 "$0" | tail -25
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if $RUN_ALL; then
    RUN_STRUCTURE=true
    RUN_CONTENT=true
    RUN_LINKS=true
    RUN_MERMAID=true
    RUN_COVERAGE=true
fi

log() {
    if ! $JSON_OUTPUT; then
        echo -e "$1"
    fi
}

log_verbose() {
    if $VERBOSE && ! $JSON_OUTPUT; then
        echo -e "  $1"
    fi
}

# =============================================================================
# Structure Validation
# =============================================================================
validate_structure() {
    local doc="$1"
    local issues=()

    # Check for H1 title
    if ! head -5 "$doc" | grep -q "^# "; then
        issues+=("Missing H1 title")
    fi

    # Check for Executive Summary section
    if ! grep -qi "## .*summary\|## .*overview" "$doc"; then
        issues+=("Missing executive summary section")
    fi

    # Check heading depth (max 4 levels)
    if grep -q "^##### " "$doc"; then
        issues+=("Heading depth exceeds 4 levels")
    fi

    echo "${issues[*]:-}"
}

# =============================================================================
# Content Validation
# =============================================================================
validate_content() {
    local doc="$1"
    local issues=()

    # Word count check (minimum 300 for non-index files)
    local filename=$(basename "$doc")
    if [[ "$filename" != "00-index.md" ]] && [[ "$filename" != "README.md" ]]; then
        local word_count=$(wc -w < "$doc" | tr -d ' ')
        if [ "$word_count" -lt 300 ]; then
            issues+=("Word count ($word_count) below minimum (300)")
        fi
    fi

    # Check for Mermaid diagram
    if ! grep -q '```mermaid' "$doc"; then
        issues+=("No Mermaid diagram found")
    fi

    # Check for TODO placeholders
    if grep -qi "TODO\|FIXME\|XXX\|PLACEHOLDER" "$doc"; then
        issues+=("Contains TODO/FIXME placeholders")
    fi

    # Check for source citations (should reference repos or files)
    if ! grep -qi "source:\|repo:\|github.com\|\.ts\|\.py\|\.yaml" "$doc"; then
        log_verbose "Warning: May be missing source citations"
    fi

    echo "${issues[*]:-}"
}

# =============================================================================
# Link Validation
# =============================================================================
validate_links() {
    local doc="$1"
    local issues=()
    local doc_dir=$(dirname "$doc")

    # Extract relative links
    local links=$(grep -oP '\[.*?\]\(\./[^)]+\)' "$doc" 2>/dev/null || true)

    while IFS= read -r link; do
        if [ -n "$link" ]; then
            # Extract path from markdown link
            local target=$(echo "$link" | grep -oP '\./[^)]+' | head -1)
            if [ -n "$target" ]; then
                # Remove anchor if present
                target="${target%%#*}"
                local full_path="$doc_dir/$target"
                if [ ! -f "$full_path" ]; then
                    issues+=("Broken link: $target")
                fi
            fi
        fi
    done <<< "$links"

    echo "${issues[*]:-}"
}

# =============================================================================
# Mermaid Validation
# =============================================================================
validate_mermaid() {
    local doc="$1"
    local issues=()

    # Extract mermaid blocks and check basic syntax
    local mermaid_count=0
    local in_mermaid=false
    local mermaid_block=""

    while IFS= read -r line; do
        if [[ "$line" == '```mermaid' ]]; then
            in_mermaid=true
            mermaid_block=""
            mermaid_count=$((mermaid_count + 1))
        elif [[ "$line" == '```' ]] && $in_mermaid; then
            in_mermaid=false

            # Basic syntax checks
            if [[ "$mermaid_block" == *"graph "* ]] || [[ "$mermaid_block" == *"flowchart "* ]]; then
                # Check for common flowchart issues
                if echo "$mermaid_block" | grep -qP '\[\s*\]'; then
                    issues+=("Mermaid block $mermaid_count: Empty node label")
                fi
            fi

            if [[ "$mermaid_block" == *"sequenceDiagram"* ]]; then
                # Check for participant definitions
                if ! echo "$mermaid_block" | grep -q "participant\|actor"; then
                    log_verbose "Mermaid block $mermaid_count: Consider defining participants"
                fi
            fi
        elif $in_mermaid; then
            mermaid_block+="$line"$'\n'
        fi
    done < "$doc"

    # Check for mmdc if available (Mermaid CLI)
    if command -v mmdc &> /dev/null; then
        # More thorough validation could be done here
        log_verbose "Mermaid CLI available for deeper validation"
    fi

    echo "${issues[*]:-}"
}

# =============================================================================
# Coverage Validation
# =============================================================================
validate_coverage() {
    local issues=()

    # Check if manifest exists
    if [ ! -f "$MANIFEST" ]; then
        issues+=("Manifest file not found")
        echo "${issues[*]:-}"
        return
    fi

    # Get expected documents from manifest
    local expected_docs=$(jq -r '.documents | keys[]' "$MANIFEST" 2>/dev/null)

    for doc in $expected_docs; do
        if [ ! -f "$DOCS_DIR/$doc" ]; then
            issues+=("Missing documented file: $doc")
        fi
    done

    # Check for orphan docs (exist but not in manifest)
    for doc_file in "$DOCS_DIR"/*.md; do
        if [ -f "$doc_file" ]; then
            local doc_name=$(basename "$doc_file")
            if ! jq -e --arg doc "$doc_name" '.documents[$doc]' "$MANIFEST" > /dev/null 2>&1; then
                if [[ "$doc_name" != "README.md" ]]; then
                    issues+=("Orphan document: $doc_name (not in manifest)")
                fi
            fi
        fi
    done

    echo "${issues[*]:-}"
}

# =============================================================================
# Main Validation Loop
# =============================================================================

log "${BLUE}=============================================="
log " NDX Architecture - Quality Validation Report"
log "==============================================${NC}"
log ""

# Results file for tracking (avoid bash 4+ associative arrays)
RESULTS_FILE=$(mktemp)
trap "rm -f $RESULTS_FILE" EXIT

for doc_file in "$DOCS_DIR"/*.md; do
    if [ -f "$doc_file" ]; then
        doc_name=$(basename "$doc_file")
        TOTAL_DOCS=$((TOTAL_DOCS + 1))
        doc_issues=""

        log_verbose "Validating: $doc_name"

        if $RUN_STRUCTURE; then
            structure_issues=$(validate_structure "$doc_file")
            if [ -n "$structure_issues" ]; then
                doc_issues="${doc_issues}Structure: $structure_issues; "
            fi
        fi

        if $RUN_CONTENT; then
            content_issues=$(validate_content "$doc_file")
            if [ -n "$content_issues" ]; then
                doc_issues="${doc_issues}Content: $content_issues; "
            fi
        fi

        if $RUN_LINKS; then
            link_issues=$(validate_links "$doc_file")
            if [ -n "$link_issues" ]; then
                doc_issues="${doc_issues}Links: $link_issues; "
            fi
        fi

        if $RUN_MERMAID; then
            mermaid_issues=$(validate_mermaid "$doc_file")
            if [ -n "$mermaid_issues" ]; then
                doc_issues="${doc_issues}Mermaid: $mermaid_issues; "
            fi
        fi

        if [ -z "$doc_issues" ]; then
            PASSED_DOCS=$((PASSED_DOCS + 1))
            log_verbose "${GREEN}  PASSED${NC}"
            echo "$doc_name:PASSED" >> "$RESULTS_FILE"
        else
            FAILED_DOCS=$((FAILED_DOCS + 1))
            log "${YELLOW}$doc_name${NC}"
            log "  ${RED}$doc_issues${NC}"
            # Count issues (semicolon separated)
            issue_count=$(echo "$doc_issues" | tr ';' '\n' | grep -c . || echo 0)
            TOTAL_ISSUES=$((TOTAL_ISSUES + issue_count))
            echo "$doc_name:$doc_issues" >> "$RESULTS_FILE"
        fi
    fi
done

# Run coverage validation separately
if $RUN_COVERAGE; then
    log ""
    log "${BLUE}=== Coverage Validation ===${NC}"
    coverage_issues=$(validate_coverage)
    if [ -n "$coverage_issues" ]; then
        log "${RED}$coverage_issues${NC}"
        TOTAL_ISSUES=$((TOTAL_ISSUES + $(echo "$coverage_issues" | wc -l)))
    else
        log "${GREEN}All documents accounted for${NC}"
    fi
fi

# Summary
log ""
log "${BLUE}=== Summary ===${NC}"
log "Total documents: $TOTAL_DOCS"
log "Passed: ${GREEN}$PASSED_DOCS${NC}"
log "Failed: ${RED}$FAILED_DOCS${NC}"
log "Total issues: $TOTAL_ISSUES"
log ""

# Exit code based on results
if [ $FAILED_DOCS -gt 0 ] || [ $TOTAL_ISSUES -gt 0 ]; then
    log "${RED}Validation FAILED${NC}"
    exit 1
else
    log "${GREEN}Validation PASSED${NC}"
    exit 0
fi
