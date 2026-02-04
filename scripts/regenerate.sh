#!/bin/bash
# =============================================================================
# regenerate.sh - Force regeneration of specific documentation files
# =============================================================================
#
# Usage: ./scripts/regenerate.sh <doc-name.md> [<doc-name.md> ...]
#        ./scripts/regenerate.sh --all
#        ./scripts/regenerate.sh --category <category-name>
#
# Examples:
#   ./scripts/regenerate.sh 10-isb-core-architecture.md
#   ./scripts/regenerate.sh --category isb-core
#   ./scripts/regenerate.sh --all
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="$ROOT_DIR/docs/.meta/manifest.json"
STATE_DIR="$ROOT_DIR/.state"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo "Usage: $0 <doc-name.md> [<doc-name.md> ...]"
    echo "       $0 --all"
    echo "       $0 --category <category-name>"
    echo ""
    echo "Options:"
    echo "  --all                 Regenerate all documentation files"
    echo "  --category <name>     Regenerate all docs in a category"
    echo "  --list-categories     List available categories"
    echo "  --list-docs           List all documentation files"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Categories:"
    echo "  inventory (00-09)     Discovery and overview"
    echo "  isb-core (10-19)      ISB core components"
    echo "  isb-satellites (20-29) ISB extension repos"
    echo "  websites (30-39)      NDX websites"
    echo "  infrastructure (40-49) LZA and Terraform"
    echo "  cicd (50-59)          CI/CD pipelines"
    echo "  security (60-69)      Security and compliance"
    echo "  data (70-79)          Data flows and integrations"
    echo "  architecture (80-89)  Master diagrams"
    echo "  meta (90-99)          Issues and metadata"
}

list_categories() {
    if [ -f "$MANIFEST" ]; then
        echo "Available categories:"
        jq -r '.categories | to_entries[] | "  \(.key): \(.value.description) (\(.value.range))"' "$MANIFEST"
    else
        echo "Manifest not found. Default categories:"
        echo "  inventory, isb-core, isb-satellites, websites, infrastructure, cicd, security, data, architecture, meta"
    fi
}

list_docs() {
    if [ -f "$MANIFEST" ]; then
        echo "Documentation files:"
        jq -r '.documents | keys[]' "$MANIFEST" | sort
    else
        echo "Manifest not found. Listing docs directory:"
        ls -1 "$ROOT_DIR/docs/"*.md 2>/dev/null | xargs -n1 basename || echo "No docs found"
    fi
}

mark_for_regeneration() {
    local doc="$1"
    echo -e "${BLUE}Marking for regeneration:${NC} $doc"

    # Create state directory if needed
    mkdir -p "$STATE_DIR/regenerate"

    # Touch a marker file for this doc
    touch "$STATE_DIR/regenerate/$doc"

    # If manifest exists, clear the checksum to force regeneration
    if [ -f "$MANIFEST" ]; then
        # Create a temp file with updated manifest
        jq --arg doc "$doc" \
           '.documents[$doc].checksum = null | .documents[$doc].lastGenerated = null' \
           "$MANIFEST" > "$MANIFEST.tmp" && mv "$MANIFEST.tmp" "$MANIFEST"
    fi

    echo -e "${GREEN}  Queued for next update run${NC}"
}

# Parse arguments
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    --list-categories)
        list_categories
        exit 0
        ;;
    --list-docs)
        list_docs
        exit 0
        ;;
    --all)
        echo "Marking ALL documents for regeneration..."
        if [ -f "$MANIFEST" ]; then
            docs=$(jq -r '.documents | keys[]' "$MANIFEST")
            for doc in $docs; do
                mark_for_regeneration "$doc"
            done
        else
            for doc in "$ROOT_DIR/docs/"*.md; do
                mark_for_regeneration "$(basename "$doc")"
            done
        fi
        echo ""
        echo -e "${GREEN}All documents marked for regeneration.${NC}"
        echo "Run the update prompt to regenerate."
        ;;
    --category)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: --category requires a category name${NC}"
            echo ""
            list_categories
            exit 1
        fi
        category="$2"
        echo "Marking all '$category' documents for regeneration..."
        if [ -f "$MANIFEST" ]; then
            docs=$(jq -r --arg cat "$category" \
                '.documents | to_entries[] | select(.value.category == $cat) | .key' \
                "$MANIFEST")
            if [ -z "$docs" ]; then
                echo -e "${RED}No documents found in category: $category${NC}"
                echo ""
                list_categories
                exit 1
            fi
            for doc in $docs; do
                mark_for_regeneration "$doc"
            done
        else
            echo -e "${RED}Manifest not found. Cannot filter by category.${NC}"
            exit 1
        fi
        echo ""
        echo -e "${GREEN}Category '$category' marked for regeneration.${NC}"
        ;;
    *)
        # Process individual document names
        for doc in "$@"; do
            # Add .md extension if not present
            if [[ ! "$doc" == *.md ]]; then
                doc="${doc}.md"
            fi

            # Check if document exists
            if [ ! -f "$ROOT_DIR/docs/$doc" ] && [ -f "$MANIFEST" ]; then
                if ! jq -e --arg doc "$doc" '.documents[$doc]' "$MANIFEST" > /dev/null 2>&1; then
                    echo -e "${YELLOW}Warning: '$doc' not found in manifest or docs directory${NC}"
                    continue
                fi
            fi

            mark_for_regeneration "$doc"
        done
        echo ""
        echo -e "${GREEN}Documents marked for regeneration.${NC}"
        echo "Run the update prompt to regenerate."
        ;;
esac
