#!/bin/bash
# Docker Compose Helper Functions
# Sourced automatically by ~/.bash_aliases (via dotfiles)

# Directory where your main compose file lives
DOCKER_COMPOSE_DIR="$HOME/docker"

# ===========================================
# Quick aliases
# ===========================================
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# ===========================================
# Helper function with cheat sheet
# ===========================================
dhelp() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║              🐳 Docker Compose Cheat Sheet                       ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║  QUICK COMMANDS (run from anywhere):                             ║"
    echo "║    dps                    - List running containers              ║"
    echo "║    dhelp                  - Show this help                       ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║  CONTAINER MANAGEMENT (run from $DOCKER_COMPOSE_DIR):            ║"
    echo "║    dc up -d               - Start all containers                 ║"
    echo "║    dc down                - Stop all containers                  ║"
    echo "║    dc restart             - Restart all containers               ║"
    echo "║    dc restart <name>      - Restart specific container           ║"
    echo "║    dc stop <name>         - Stop specific container              ║"
    echo "║    dc start <name>        - Start specific container             ║"
    echo "║    dc logs <name>         - View logs for container              ║"
    echo "║    dc logs -f <name>      - Follow logs (live)                   ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║  UPDATES:                                                        ║"
    echo "║    dc pull                - Pull latest images                   ║"
    echo "║    dc pull <name>         - Pull specific image                  ║"
    echo "║    dc up -d               - Recreate with new images             ║"
    echo "║    dc up -d --force-recreate <name>  - Force recreate container  ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║  TROUBLESHOOTING:                                                ║"
    echo "║    dc ps                  - Show container status                ║"
    echo "║    dc config              - Validate compose file                ║"
    echo "║    docker stats           - Live resource usage                  ║"
    echo "║    docker system prune    - Clean up unused resources            ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ===========================================
# Quick navigation
# ===========================================
dcd() {
    cd "$DOCKER_COMPOSE_DIR"
    echo "📁 Now in: $DOCKER_COMPOSE_DIR"
    echo "💡 Tip: Run 'dhelp' for command reference"
}

# ===========================================
# Convenience wrappers (work from anywhere)
# ===========================================

# Start all containers
dup() {
    (cd "$DOCKER_COMPOSE_DIR" && docker compose up -d "$@")
}

# Stop all containers
ddown() {
    (cd "$DOCKER_COMPOSE_DIR" && docker compose down "$@")
}

# Restart container(s)
drestart() {
    if [ -z "$1" ]; then
        (cd "$DOCKER_COMPOSE_DIR" && docker compose restart)
    else
        (cd "$DOCKER_COMPOSE_DIR" && docker compose restart "$@")
    fi
}

# View logs
dlogs() {
    if [ -z "$1" ]; then
        echo "Usage: dlogs <container_name> [-f for follow]"
        echo "Containers: $(docker ps --format '{{.Names}}' | tr '\n' ' ')"
    else
        (cd "$DOCKER_COMPOSE_DIR" && docker compose logs "$@")
    fi
}

# Pull and update
dupdate() {
    echo "🔄 Pulling latest images..."
    (cd "$DOCKER_COMPOSE_DIR" && docker compose pull)
    echo "🚀 Recreating containers with new images..."
    (cd "$DOCKER_COMPOSE_DIR" && docker compose up -d)
    echo "✅ Update complete!"
}

# Show welcome message on first source
echo "🐳 Docker helpers loaded! Type 'dhelp' for commands."

