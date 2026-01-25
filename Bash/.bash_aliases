# Bash configuration
# Sourced by ~/.bashrc

# Source common shell configuration (shared with zsh)
if [[ -f "$HOME/.shell_common" ]]; then
    source "$HOME/.shell_common"
fi

# =============================================================================
# Bash-specific options
# =============================================================================

# Enable Vi mode (similar to Zsh config)
set -o vi

# Better history
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable programmable completion (if not already)
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Simple colored prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
