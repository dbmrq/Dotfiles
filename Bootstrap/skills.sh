#!/usr/bin/env bash
#
# Agent Skills Manager
# Installs catalog skills from manifest and sets up agent symlinks
#

set -euo pipefail

# --- Script setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# --- Configuration ---
MANIFEST="$SCRIPT_DIR/skills-manifest.txt"
SKILLS_DIR="$HOME/.agents/skills"

# Agents to link (agent name and skills path pairs)
AGENTS=(augment cursor claude copilot)

# --- Functions ---

# Get the skills directory path for a given agent
# Arguments:
#   $1 - Agent name (augment, cursor, claude, copilot)
# Returns:
#   Path to the agent's skills directory
get_agent_path() {
    case "$1" in
        augment) printf '%s' "$HOME/.augment/skills" ;;
        cursor)  printf '%s' "$HOME/.cursor/skills" ;;
        claude)  printf '%s' "$HOME/.claude/skills" ;;
        copilot) printf '%s' "$HOME/.copilot/skills" ;;
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

install_from_manifest() {
    local manifest_file="$1"
    local global_flag="$2"  # "-g" for global, "" for local
    local label="$3"

    if [[ ! -f "$manifest_file" ]]; then
        return 0
    fi

    print_header "Installing $label skills..."

    local count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        print_info "Installing: $line"
        # shellcheck disable=SC2086
        # Use </dev/null to prevent npx from consuming the while loop's stdin
        if npx skills add $line $global_flag -y </dev/null; then
            ((count++))
        else
            print_warn "Failed to install: $line"
        fi
    done < "$manifest_file"

    if [[ $count -gt 0 ]]; then
        print_ok "Installed $count $label skill(s)"
    else
        print_info "No new $label skills to install"
    fi
}

install_catalog_skills() {
    # Check for npx
    if ! command_exists npx; then
        print_error "npx not found. Install Node.js first."
        return 1
    fi

    # Ensure temp directory is user-writable (npx can fail with system temp dirs)
    ensure_user_tmpdir

    # Install global skills from Bootstrap manifest
    install_from_manifest "$MANIFEST" "-g" "global"

    # Install project-local skills if .skills-manifest.txt exists in current directory
    local local_manifest=".skills-manifest.txt"
    if [[ -f "$local_manifest" ]]; then
        install_from_manifest "$local_manifest" "" "project-local"
    fi
}

update_catalog_skills() {
    if ! command_exists npx; then
        print_error "npx not found. Install Node.js first."
        return 1
    fi

    # Ensure temp directory is user-writable (npx can fail with system temp dirs)
    ensure_user_tmpdir

    # Update global skills
    print_header "Updating global skills..."
    if npx skills update -g -y </dev/null; then
        print_ok "Global skills updated"
    else
        print_warn "No global updates available or update failed"
    fi

    # Update project-local skills if .skills-manifest.txt exists
    if [[ -f ".skills-manifest.txt" ]]; then
        print_header "Updating project-local skills..."
        if npx skills update -y </dev/null; then
            print_ok "Project-local skills updated"
        else
            print_warn "No local updates available or update failed"
        fi
    fi
}

show_status() {
    print_header "Agent Skills Status"

    echo ""
    echo -e "${BOLD}Global skills directory:${NC} $SKILLS_DIR"
    if [[ -d "$SKILLS_DIR" ]]; then
        local skills
        skills=$(find "$SKILLS_DIR" -maxdepth 1 -type d -not -name ".*" -not -path "$SKILLS_DIR" | wc -l | tr -d ' ')
        echo "  $skills skill(s) installed"
    fi

    # Show project-local skills if present
    local local_skills_dir=".agents/skills"
    if [[ -d "$local_skills_dir" ]]; then
        echo ""
        echo -e "${BOLD}Project-local skills:${NC} $local_skills_dir"
        local local_skills
        local_skills=$(find "$local_skills_dir" -maxdepth 1 -type d -not -name ".*" -not -path "$local_skills_dir" | wc -l | tr -d ' ')
        echo "  $local_skills skill(s) installed"
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
main() {
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
            exit "$E_INVALID_ARG"
            ;;
    esac
}

# Only run if executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

