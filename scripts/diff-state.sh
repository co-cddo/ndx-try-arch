#!/bin/bash
# =============================================================================
# diff-state.sh - Show changes since last capture
# =============================================================================
#
# Usage: ./scripts/diff-state.sh [--verbose]
#
# This script compares the current state of repositories and AWS resources
# against what was captured in docs/.meta/captured-state.json
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CAPTURED="$ROOT_DIR/docs/.meta/captured-state.json"
DEPENDENCY_GRAPH="$ROOT_DIR/docs/.meta/dependency-graph.json"

VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=============================================="
echo " NDX Architecture - State Diff Report"
echo "=============================================="
echo ""

# Check if captured state exists
if [ ! -f "$CAPTURED" ]; then
    echo -e "${YELLOW}No captured state found at:${NC} $CAPTURED"
    echo "Run a full discovery to create initial state."
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo "Install with: brew install jq"
    exit 1
fi

echo "=== Repository Changes ==="
echo ""

REPO_COUNT=0
CHANGED_COUNT=0

for repo_dir in "$ROOT_DIR"/repos/*/; do
    if [ -d "$repo_dir" ]; then
        repo_name=$(basename "$repo_dir")
        REPO_COUNT=$((REPO_COUNT + 1))

        # Get current SHA
        current_sha=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || echo "unknown")

        # Get captured SHA from state file
        captured_sha=$(jq -r --arg name "$repo_name" \
            '.sources.repositories[$name].capturedSha // "not-captured"' \
            "$CAPTURED" 2>/dev/null || echo "not-captured")

        if [ "$current_sha" == "unknown" ]; then
            echo -e "${RED}  $repo_name${NC}"
            echo "     Status: Not a git repository"
        elif [ "$captured_sha" == "not-captured" ] || [ "$captured_sha" == "null" ]; then
            echo -e "${YELLOW}  $repo_name${NC}"
            echo "     Status: New (not yet captured)"
            echo "     Current: ${current_sha:0:7}"
            CHANGED_COUNT=$((CHANGED_COUNT + 1))
        elif [ "$current_sha" != "$captured_sha" ]; then
            echo -e "${BLUE}  $repo_name${NC}"
            echo "     Captured: ${captured_sha:0:7}"
            echo "     Current:  ${current_sha:0:7}"
            CHANGED_COUNT=$((CHANGED_COUNT + 1))

            if $VERBOSE; then
                echo "     Changes:"
                git -C "$repo_dir" log --oneline "${captured_sha}..${current_sha}" 2>/dev/null | head -10 | sed 's/^/       /'
                commit_count=$(git -C "$repo_dir" rev-list --count "${captured_sha}..${current_sha}" 2>/dev/null || echo "?")
                if [ "$commit_count" -gt 10 ] 2>/dev/null; then
                    echo "       ... and $((commit_count - 10)) more commits"
                fi
            fi
        else
            if $VERBOSE; then
                echo -e "${GREEN}  $repo_name${NC} - No changes"
            fi
        fi
    fi
done

echo ""
echo "Summary: $CHANGED_COUNT of $REPO_COUNT repositories have changes"
echo ""

# Check for affected documents if dependency graph exists
if [ -f "$DEPENDENCY_GRAPH" ] && [ "$CHANGED_COUNT" -gt 0 ]; then
    echo "=== Affected Documents ==="
    echo ""

    for repo_dir in "$ROOT_DIR"/repos/*/; do
        if [ -d "$repo_dir" ]; then
            repo_name=$(basename "$repo_dir")
            current_sha=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || echo "unknown")
            captured_sha=$(jq -r --arg name "$repo_name" \
                '.sources.repositories[$name].capturedSha // "not-captured"' \
                "$CAPTURED" 2>/dev/null || echo "not-captured")

            if [ "$current_sha" != "$captured_sha" ] && [ "$captured_sha" != "not-captured" ] && [ "$captured_sha" != "null" ]; then
                # Find affected documents from dependency graph
                affected=$(jq -r --arg repo "repo:$repo_name" \
                    '.edges[] | select(.from == $repo) | .to' \
                    "$DEPENDENCY_GRAPH" 2>/dev/null | sed 's/doc:/  /')

                if [ -n "$affected" ]; then
                    echo "  $repo_name affects:"
                    echo "$affected" | sed 's/^/    /'
                fi
            fi
        fi
    done
    echo ""
fi

# Show last capture time
last_capture=$(jq -r '.capturedAt // "never"' "$CAPTURED" 2>/dev/null || echo "unknown")
echo "Last capture: $last_capture"
echo ""

# Quick reset hints
echo "=== Quick Commands ==="
echo ""
echo "  View this report verbosely:    ./scripts/diff-state.sh --verbose"
echo "  Re-run all tasks:              rm -rf .state/"
echo "  Force regenerate all docs:     rm docs/.meta/captured-state.json && rm -rf .state/"
echo "  Regenerate single doc:         ./scripts/regenerate.sh <doc-name.md>"
echo "  Full clean slate:              rm -rf repos/ .state/ && rm docs/.meta/*.json"
echo ""
