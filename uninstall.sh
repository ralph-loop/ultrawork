#!/bin/bash
#
# Ultrawork Uninstallation Script
# Removes ultrawork command and optionally cleans up all data
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
CLAUDE_DIR="${HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"
ULTRAWORK_SKILL_DIR="${SKILLS_DIR}/ultrawork"
CONFIG_DIR="${CLAUDE_DIR}/ultrawork"

# Parse arguments
PURGE=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --purge)
            PURGE=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --help|-h)
            echo "Ultrawork Uninstaller"
            echo ""
            echo "Usage: ./uninstall.sh [options]"
            echo ""
            echo "Options:"
            echo "  --purge    Remove all data including config, cache, and learned patterns"
            echo "  --force    Skip confirmation prompts"
            echo "  --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   Ultrawork Uninstaller                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
}

# Confirm action
confirm() {
    if [ "$FORCE" = true ]; then
        return 0
    fi

    read -p "$1 [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

# Remove skill files
remove_skills() {
    print_info "Removing skill files..."

    if [ -d "${ULTRAWORK_SKILL_DIR}" ]; then
        rm -rf "${ULTRAWORK_SKILL_DIR}"
        print_success "Removed ultrawork skill directory: ${ULTRAWORK_SKILL_DIR}"
    else
        print_warning "ultrawork skill directory not found (already removed?)"
    fi
}

# Remove config and data
remove_config() {
    print_info "Removing configuration and data..."

    if [ -d "$CONFIG_DIR" ]; then
        # List what will be removed
        echo ""
        echo "The following will be removed:"
        echo "  - ${CONFIG_DIR}/config.json (settings)"
        echo "  - ${CONFIG_DIR}/patterns.json (learned patterns)"
        echo "  - ${CONFIG_DIR}/cache/ (temporary data)"
        echo ""

        if confirm "Are you sure you want to remove all ultrawork data?"; then
            rm -rf "$CONFIG_DIR"
            print_success "Removed config directory: $CONFIG_DIR"
        else
            print_warning "Skipped config removal"
        fi
    else
        print_warning "Config directory not found (already removed?)"
    fi
}

# Summary
print_summary() {
    echo ""
    echo -e "${GREEN}Uninstallation complete!${NC}"
    echo ""

    if [ "$PURGE" = true ]; then
        echo "Removed:"
        echo "  - Skill directory (${ULTRAWORK_SKILL_DIR})"
        echo "  - Configuration (config.json)"
        echo "  - Learned patterns (patterns.json)"
        echo "  - Cache data"
    else
        echo "Removed:"
        echo "  - Skill directory (${ULTRAWORK_SKILL_DIR})"
        echo ""
        echo "Kept:"
        echo "  - Configuration: ${CONFIG_DIR}/config.json"
        echo "  - Learned patterns: ${CONFIG_DIR}/patterns.json"
        echo ""
        echo "To remove all data, run: ./uninstall.sh --purge"
    fi

    echo ""
    echo "To reinstall:"
    echo "  curl -fsSL https://raw.githubusercontent.com/ralph-loop/ultrawork/master/install.sh | bash"
}

# Main uninstallation flow
main() {
    print_header

    # Check if anything is installed
    if [ ! -d "${ULTRAWORK_SKILL_DIR}" ] && [ ! -d "$CONFIG_DIR" ]; then
        print_warning "Ultrawork does not appear to be installed."
        exit 0
    fi

    echo "This will uninstall ultrawork from: ${ULTRAWORK_SKILL_DIR}"
    if [ "$PURGE" = true ]; then
        echo -e "${YELLOW}WARNING: --purge flag is set. All data will be removed.${NC}"
    fi
    echo ""

    if ! confirm "Do you want to continue?"; then
        print_info "Uninstallation cancelled."
        exit 0
    fi

    echo ""
    remove_skills

    if [ "$PURGE" = true ]; then
        remove_config
    fi

    print_summary
}

# Run main function
main "$@"
