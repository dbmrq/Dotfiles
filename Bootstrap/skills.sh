#!/usr/bin/env bash
#
# Agent Skills Manager
# Installs catalog skills from manifest and sets up agent symlinks
#

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

MANIFEST="$SCRIPT_DIR/skills-manifest.txt"
SKILLS_DIR="$HOME/.agents/skills"

# Agents to link (agent name and skills path pairs)
AGENTS=(augment cursor claude copilot)
get_agent_path() {
    case "$1" in
        augment) echo "$HOME/.augment/skills" ;;
        cursor)  echo "$HOME/.cursor/skills" ;;
        claude)  echo "$HOME/.claude/skills" ;;
        copilot) echo "$HOME/.copilot/skills" ;;
    esac
}

# --- Functions ---

setup_agent_symlinks() {
    print_header "Setting up agent skill symlinks..."

    for agent in "${AGENTS[@]}"; do
        local target
        target="$(get_agent_path "$agent")"
        local parent_dir
        parent_dir="$(dirname "$target")"

        # Skip if parent directory doesn't exist (agent not installed)
        if [[ ! -d "$parent_dir" ]]; then
            print_info "Skipping $agent (not installed)"
            continue
        fi

        # Check current state
        if [[ -L "$target" ]]; then
            local current
            current="$(readlink "$target")"
            if [[ "$current" == "$SKILLS_DIR" ]]; then
                print_ok "$agent already linked"
                continue
            else
                print_warn "$agent links to $current, relinking..."
                rm "$target"
            fi
        elif [[ -d "$target" ]]; then
            print_warn "$agent has local skills dir, skipping (merge manually if needed)"
            continue
        fi

        # Create symlink
        ln -s "$SKILLS_DIR" "$target"
        print_ok "$agent linked to shared skills"
    done
}

install_catalog_skills() {
    print_header "Installing catalog skills..."

    if [[ ! -f "$MANIFEST" ]]; then
        print_warn "No manifest found at $MANIFEST"
        return 0
    fi

    # Check for npx
    if ! command_exists npx; then
        print_error "npx not found. Install Node.js first."
        return 1
    fi

    local count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        print_info "Installing: $line"
        # shellcheck disable=SC2086
        # Use </dev/null to prevent npx from consuming the while loop's stdin
        if npx skills add $line -g -y </dev/null; then
            ((count++))
        else
            print_warn "Failed to install: $line"
        fi
    done < "$MANIFEST"

    if [[ $count -gt 0 ]]; then
        print_ok "Installed $count catalog skill(s)"
    else
        print_info "No new skills to install"
    fi
}

update_catalog_skills() {
    print_header "Updating catalog skills..."

    if ! command_exists npx; then
        print_error "npx not found. Install Node.js first."
        return 1
    fi

    if npx skills update -g -y 2>/dev/null; then
        print_ok "Skills updated"
    else
        print_warn "No updates available or update failed"
    fi
}

show_status() {
    print_header "Agent Skills Status"

    echo ""
    echo -e "${BOLD}Shared skills directory:${NC} $SKILLS_DIR"
    if [[ -d "$SKILLS_DIR" ]]; then
        local skills
        skills=$(find "$SKILLS_DIR" -maxdepth 1 -type d -not -name ".*" -not -path "$SKILLS_DIR" | wc -l | tr -d ' ')
        echo "  $skills skill(s) installed"
    fi

    echo ""
    echo -e "${BOLD}Agent symlinks:${NC}"
    for agent in "${AGENTS[@]}"; do
        local target
        target="$(get_agent_path "$agent")"
        if [[ -L "$target" ]]; then
            print_ok "$agent → $(readlink "$target")"
        elif [[ -d "$target" ]]; then
            print_warn "$agent has local directory (not linked)"
        else
            print_info "$agent not configured"
        fi
    done
}

# --- Main ---

case "${1:-install}" in
    install)
        setup_agent_symlinks
        install_catalog_skills
        ;;
    update)
        update_catalog_skills
        ;;
    link|symlinks)
        setup_agent_symlinks
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 [install|update|link|status]"
        echo ""
        echo "Commands:"
        echo "  install   Install catalog skills and setup symlinks (default)"
        echo "  update    Update catalog skills to latest versions"
        echo "  link      Only setup agent symlinks"
        echo "  status    Show current skills and symlink status"
        exit 1
        ;;
esac

