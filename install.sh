#!/bin/bash
#
# Ultrawork Installation Script
# Installs ultrawork command and alias for Claude Code
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
AGENT_DIR="${HOME}/.agent"
SKILLS_DIR="${AGENT_DIR}/skills"
ULTRAWORK_SKILL_DIR="${SKILLS_DIR}/ultrawork"
CONFIG_DIR="${AGENT_DIR}/ultrawork"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# GitHub raw content URL
GITHUB_RAW_URL="https://raw.githubusercontent.com/ralph-loop/ultrawork/master"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Ultrawork Installer                       ║"
    echo "║     Intelligent Task Orchestration for Claude Code           ║"
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

# Check if agent directory exists
check_agent_dir() {
    if [ ! -d "$AGENT_DIR" ]; then
        print_info "Creating agent directory: $AGENT_DIR"
        mkdir -p "$AGENT_DIR"
    fi
}

# Create skills directory if not exists
create_skills_dir() {
    if [ ! -d "$SKILLS_DIR" ]; then
        print_info "Creating skills directory: $SKILLS_DIR"
        mkdir -p "$SKILLS_DIR"
    fi
}

# Create config directory
create_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        print_info "Creating config directory: $CONFIG_DIR"
        mkdir -p "$CONFIG_DIR"
    fi
}

# Create ultrawork skill directory
create_ultrawork_skill_dir() {
    if [ ! -d "$ULTRAWORK_SKILL_DIR" ]; then
        print_info "Creating ultrawork skill directory: $ULTRAWORK_SKILL_DIR"
        mkdir -p "$ULTRAWORK_SKILL_DIR"
    fi
}

# Create symbolic link from ~/.claude/skills/ultrawork to ~/.agent/skills/ultrawork
create_symlink() {
    local CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
    local CLAUDE_ULTRAWORK_LINK="${CLAUDE_SKILLS_DIR}/ultrawork"

    # Create ~/.claude/skills directory if not exists
    if [ ! -d "$CLAUDE_SKILLS_DIR" ]; then
        print_info "Creating Claude skills directory: $CLAUDE_SKILLS_DIR"
        mkdir -p "$CLAUDE_SKILLS_DIR"
    fi

    # Remove existing symlink or directory
    if [ -L "$CLAUDE_ULTRAWORK_LINK" ]; then
        rm "$CLAUDE_ULTRAWORK_LINK"
        print_info "Removed existing symlink"
    elif [ -d "$CLAUDE_ULTRAWORK_LINK" ]; then
        print_warning "Directory exists at $CLAUDE_ULTRAWORK_LINK, skipping symlink"
        return
    fi

    # Create symlink (relative path)
    ln -s "../../.agent/skills/ultrawork" "$CLAUDE_ULTRAWORK_LINK"
    print_success "Created symlink: $CLAUDE_ULTRAWORK_LINK -> ~/.agent/skills/ultrawork"
}

# Download file from GitHub or copy from local
download_or_copy() {
    local filename=$1
    local dest=$2

    # Try local file first
    if [ -f "${SCRIPT_DIR}/skills/${filename}" ]; then
        cp "${SCRIPT_DIR}/skills/${filename}" "${dest}"
        return 0
    fi

    # Download from GitHub
    print_info "Downloading ${filename} from GitHub..."
    if curl -fsSL "${GITHUB_RAW_URL}/skills/${filename}" -o "${dest}"; then
        return 0
    else
        return 1
    fi
}

# Install skill files
install_skills() {
    print_info "Installing ultrawork skill..."

    # Create ultrawork skill directory
    create_ultrawork_skill_dir

    # Install ultrawork.md
    if download_or_copy "ultrawork.md" "${ULTRAWORK_SKILL_DIR}/ultrawork.md"; then
        print_success "Installed ultrawork.md"
    else
        print_error "Failed to install ultrawork.md"
        exit 1
    fi

    # Install ulw.md (alias)
    if download_or_copy "ulw.md" "${ULTRAWORK_SKILL_DIR}/ulw.md"; then
        print_success "Installed ulw.md (alias)"
    else
        print_error "Failed to install ulw.md"
        exit 1
    fi
}

# Create default config
create_default_config() {
    local config_file="${CONFIG_DIR}/config.json"

    if [ ! -f "$config_file" ]; then
        print_info "Creating default configuration..."
        cat > "$config_file" << 'EOF'
{
  "version": "1.0.0",
  "defaults": {
    "ralphLoop": false,
    "maxIterations": 100,
    "completionPromise": "DONE",
    "forceSwarm": false,
    "enableSkills": true
  },
  "modelRouting": {
    "research": "opus",
    "implementation": "sonnet",
    "simple": "haiku"
  },
  "skillPaths": [
    "~/.agent/skills/",
    ".agent/skills/"
  ],
  "learning": {
    "enabled": true,
    "minConfidence": 0.7
  }
}
EOF
        print_success "Created default config at $config_file"
    else
        print_warning "Config file already exists, skipping..."
    fi
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."

    local errors=0

    if [ -f "${ULTRAWORK_SKILL_DIR}/ultrawork.md" ]; then
        print_success "ultrawork.md installed"
    else
        print_error "ultrawork.md not found"
        ((errors++))
    fi

    if [ -f "${ULTRAWORK_SKILL_DIR}/ulw.md" ]; then
        print_success "ulw.md installed"
    else
        print_error "ulw.md not found"
        ((errors++))
    fi

    if [ -f "${CONFIG_DIR}/config.json" ]; then
        print_success "Config file exists"
    else
        print_warning "Config file not created"
    fi

    if [ $errors -gt 0 ]; then
        print_error "Installation completed with $errors error(s)"
        exit 1
    fi
}

# Print usage instructions
print_usage() {
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "Usage:"
    echo "  /ultrawork <task description> [options]"
    echo "  /ulw <task description> [options]"
    echo ""
    echo "Examples:"
    echo "  /ulw Build a REST API for user management"
    echo "  /ulw Fix the login bug --ralph-loop"
    echo "  /ulw Refactor auth system -iter=10"
    echo ""
    echo "Options:"
    echo "  --ralph-loop              Auto-retry until completion"
    echo "  -iter=N                   Max iterations (default: 100)"
    echo "  --completion-promise=TEXT Completion signal (default: DONE)"
    echo "  --force-swarm             Force multi-agent mode"
    echo "  --no-skills               Disable skill matching"
    echo ""
    echo "Config location: ${CONFIG_DIR}/config.json"
    echo ""
    echo "To uninstall:"
    echo "  curl -fsSL https://raw.githubusercontent.com/ralph-loop/ultrawork/master/uninstall.sh | bash"
}

# Main installation flow
main() {
    print_header

    echo "This will install ultrawork to: ${ULTRAWORK_SKILL_DIR}"
    echo ""

    # Check for existing installation
    if [ -f "${ULTRAWORK_SKILL_DIR}/ultrawork.md" ]; then
        print_warning "Existing installation detected."
        read -p "Do you want to overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        fi
    fi

    check_agent_dir
    create_skills_dir
    create_config_dir
    install_skills
    create_default_config
    create_symlink
    verify_installation
    print_usage
}

# Run main function
main "$@"
