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
COMMANDS_DIR="${CLAUDE_DIR}/commands"
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

# Validate path is safe to delete
validate_path() {
    local path=$1
    local expected_parent=$2

    # Check path is not empty
    if [ -z "$path" ]; then
        print_error "Path is empty"
        return 1
    fi

    # Check path contains expected parent directory
    if [[ "$path" != *"$expected_parent"* ]]; then
        print_error "Path does not contain expected parent: $expected_parent"
        return 1
    fi

    # Check path is not a system directory
    case "$path" in
        /|/usr|/etc|/var|/home|/root|"$HOME"|"$HOME/")
            print_error "Refusing to delete system directory: $path"
            return 1
            ;;
    esac

    return 0
}

# Remove skill files (only ultrawork-related files)
remove_skills() {
    print_info "Removing ultrawork skill files..."

    # Validate path before deletion
    if ! validate_path "${COMMANDS_DIR}" ".claude/commands"; then
        print_error "Path validation failed. Aborting."
        exit 1
    fi

    # Show files to be deleted
    local has_files=false
    echo ""
    echo "The following files will be deleted:"
    if [ -f "${COMMANDS_DIR}/ultrawork.md" ]; then
        echo "  - ${COMMANDS_DIR}/ultrawork.md"
        has_files=true
    fi
    if [ -f "${COMMANDS_DIR}/ulw.md" ]; then
        echo "  - ${COMMANDS_DIR}/ulw.md"
        has_files=true
    fi

    if [ "$has_files" = false ]; then
        print_warning "No ultrawork skill files found (already removed?)"
        return
    fi

    echo ""

    if ! confirm "Do you want to delete these skill files?"; then
        print_warning "Skipped skill file removal"
        return
    fi

    # Delete only specific ultrawork files
    if [ -f "${COMMANDS_DIR}/ultrawork.md" ]; then
        rm -f "${COMMANDS_DIR}/ultrawork.md"
        print_success "Removed ultrawork.md"
    fi

    if [ -f "${COMMANDS_DIR}/ulw.md" ]; then
        rm -f "${COMMANDS_DIR}/ulw.md"
        print_success "Removed ulw.md"
    fi
}

# Remove config and data (only ultrawork-related files)
remove_config() {
    print_info "Removing configuration and data..."

    # Validate path before deletion
    if ! validate_path "${CONFIG_DIR}" ".claude/ultrawork"; then
        print_error "Path validation failed. Aborting."
        exit 1
    fi

    if [ -d "$CONFIG_DIR" ]; then
        # List what will be removed
        echo ""
        echo "The following files will be removed:"
        [ -f "${CONFIG_DIR}/config.json" ] && echo "  - ${CONFIG_DIR}/config.json (settings)"
        [ -f "${CONFIG_DIR}/patterns.json" ] && echo "  - ${CONFIG_DIR}/patterns.json (learned patterns)"
        [ -d "${CONFIG_DIR}/cache" ] && echo "  - ${CONFIG_DIR}/cache/ (temporary data)"
        echo ""

        if ! confirm "Are you sure you want to remove all ultrawork config data?"; then
            print_warning "Skipped config removal"
            return
        fi

        # Delete only specific ultrawork config files
        [ -f "${CONFIG_DIR}/config.json" ] && rm -f "${CONFIG_DIR}/config.json" && print_success "Removed config.json"
        [ -f "${CONFIG_DIR}/patterns.json" ] && rm -f "${CONFIG_DIR}/patterns.json" && print_success "Removed patterns.json"
        [ -d "${CONFIG_DIR}/cache" ] && rm -rf "${CONFIG_DIR}/cache" && print_success "Removed cache directory"

        # Remove directory only if empty
        if [ -d "${CONFIG_DIR}" ] && [ -z "$(ls -A "${CONFIG_DIR}")" ]; then
            rmdir "${CONFIG_DIR}"
            print_success "Removed empty directory: ${CONFIG_DIR}"
        elif [ -d "${CONFIG_DIR}" ]; then
            print_warning "Directory not empty, keeping: ${CONFIG_DIR}"
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
        echo "  - ${COMMANDS_DIR}/ultrawork.md"
        echo "  - ${COMMANDS_DIR}/ulw.md"
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
    if [ ! -f "${COMMANDS_DIR}/ultrawork.md" ] && [ ! -f "${COMMANDS_DIR}/ulw.md" ] && [ ! -d "$CONFIG_DIR" ]; then
        print_warning "Ultrawork does not appear to be installed."
        exit 0
    fi

    echo "This will uninstall ultrawork from: ${COMMANDS_DIR}"
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
