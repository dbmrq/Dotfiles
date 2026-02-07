# Start Zellij automatically (if not already inside Zellij)
if [[ -z "$ZELLIJ" ]]; then
    zellij attach -c
fi

# Source Prezto
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Source common shell configuration (shared with bash)
if [[ -f "$HOME/.shell_common" ]]; then
    source "$HOME/.shell_common"
fi

# =============================================================================
# Zsh-specific options
# =============================================================================
bindkey -v
setopt menucomplete
setopt nobeep
setopt rmstarwait

# Fix Prezto's autocorrect (override common aliases with nocorrect versions)
alias cp='nocorrect cp -i'
alias ln='nocorrect ln'
alias mv='nocorrect mv -i'
alias rm='nocorrect rm -i'
alias cpi="${aliases[cp]:-cp} -i"
alias lni="${aliases[ln]:-ln} -i"
alias mvi="${aliases[mv]:-mv} -i"
alias rmi="${aliases[rm]:-rm} -i"

# =============================================================================
# macOS-specific aliases
# =============================================================================
alias dt="cd ~/Desktop"
alias icloud='cd ~/Library/Mobile\ Documents/com~apple~CloudDocs'
alias rmxattr='xattr -rc * .*'
alias rmdsstore="find . -name '*.DS_Store' -type f -delete"

# =============================================================================
# Completions
# =============================================================================
autoload -U compinit && compinit

# =============================================================================
# Machine-specific configuration
# =============================================================================
# Source local config if it exists (for machine-specific settings like uv, etc.)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
