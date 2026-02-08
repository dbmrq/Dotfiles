# =============================================================================
# Zsh Configuration (standalone, no Prezto)
# =============================================================================

# Start Zellij automatically (if not already inside Zellij)
if [[ -z "$ZELLIJ" ]] && command -v zellij &>/dev/null; then
    zellij delete-all-sessions --yes 2>/dev/null
    zellij
fi

# =============================================================================
# Environment
# =============================================================================
# Default editor
export EDITOR='nvim'
export VISUAL='nvim'

# Smart URLs (from Prezto environment module)
autoload -Uz is-at-least
if [[ ${ZSH_VERSION} != 5.1.1 && ${TERM} != "dumb" ]]; then
    if is-at-least 5.2; then
        autoload -Uz bracketed-paste-url-magic
        zle -N bracketed-paste bracketed-paste-url-magic
    elif is-at-least 5.1; then
        autoload -Uz bracketed-paste-magic
        zle -N bracketed-paste bracketed-paste-magic
    fi
    autoload -Uz url-quote-magic
    zle -N self-insert url-quote-magic
fi

# General options
setopt COMBINING_CHARS      # Combine accents with base character
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell
setopt RC_QUOTES            # Allow 'Henry''s Garage' style quoting
unsetopt MAIL_WARNING

# Job options
setopt LONG_LIST_JOBS       # List jobs in long format
setopt AUTO_RESUME          # Resume existing job before creating new process
setopt NOTIFY               # Report background job status immediately
unsetopt BG_NICE            # Don't lower priority of background jobs
unsetopt HUP                # Don't kill jobs on shell exit
unsetopt CHECK_JOBS         # Don't report on jobs when shell exits

# =============================================================================
# History
# =============================================================================
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=10000
SAVEHIST=$HISTSIZE

setopt BANG_HIST              # Treat '!' specially during expansion
setopt EXTENDED_HISTORY       # Write ':start:elapsed;command' format
setopt SHARE_HISTORY          # Share history between sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when trimming
setopt HIST_IGNORE_DUPS       # Don't record duplicate events
setopt HIST_IGNORE_ALL_DUPS   # Delete old duplicate events
setopt HIST_FIND_NO_DUPS      # Don't display duplicates when searching
setopt HIST_IGNORE_SPACE      # Don't record events starting with space
setopt HIST_SAVE_NO_DUPS      # Don't write duplicates to history file
setopt HIST_VERIFY            # Don't execute immediately on expansion

alias history-stat="history 0 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head"

# =============================================================================
# Directory
# =============================================================================
setopt AUTO_CD              # cd without typing cd
setopt AUTO_PUSHD           # Push old dir onto stack on cd
setopt PUSHD_IGNORE_DUPS    # No duplicates in stack
setopt PUSHD_SILENT         # Don't print stack after pushd/popd
setopt PUSHD_TO_HOME        # pushd with no args goes home
setopt CDABLE_VARS          # cd to path in variable
setopt MULTIOS              # Write to multiple descriptors
setopt EXTENDED_GLOB        # Extended globbing syntax
unsetopt CLOBBER            # Don't overwrite with > (use >!)

alias -- -='cd -'
alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index

# =============================================================================
# Completions
# =============================================================================
autoload -Uz compinit && compinit

zstyle ':completion:*' menu select                      # Menu selection
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'     # Case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completions
zstyle ':completion:*:descriptions' format '%B%d%b'     # Bold descriptions

setopt MENU_COMPLETE    # Insert first match immediately
setopt NO_BEEP          # No beep on error
setopt RM_STAR_WAIT     # Wait before rm *

# =============================================================================
# Vi Mode with Keymap Indicator
# =============================================================================
bindkey -v
export KEYTIMEOUT=1

# Vi mode indicator variable (used in prompt)
VI_MODE_INDICATOR=">"

function zle-keymap-select {
    case $KEYMAP in
        vicmd) VI_MODE_INDICATOR="<" ;;
        viins|main) VI_MODE_INDICATOR=">" ;;
    esac
    zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-init {
    VI_MODE_INDICATOR=">"
    zle reset-prompt
}
zle -N zle-line-init

# Edit command in external editor (Ctrl-X Ctrl-E)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd '^X^E' edit-command-line
bindkey -M viins '^X^E' edit-command-line

# Better history search in vi mode
bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M vicmd '/' history-incremental-search-forward

# Home/End keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Delete key
bindkey '^[[3~' delete-char
bindkey -M vicmd '^[[3~' delete-char

# =============================================================================
# Prompt (from prompt_dbmrq_setup)
# =============================================================================
autoload -Uz add-zsh-hook
autoload -Uz vcs_info

# Git status hook for untracked files
function +vi-git_status {
    if [[ -n $(git ls-files --other --exclude-standard 2>/dev/null) ]]; then
        hook_com[unstaged]='%F{red}●%F{cyan}'
    fi
}

# Precmd to update prompt info
function prompt_precmd {
    # Show hostname in yellow if SSH session
    if [[ -n $SSH_TTY ]]; then
        ssh_prompt="%F{yellow}%m: "
    else
        ssh_prompt=""
    fi

    # Show path in red if not writable
    if [[ -w $PWD ]]; then
        path_color=""
    else
        path_color="%F{9}"
    fi

    vcs_info
}
add-zsh-hook precmd prompt_precmd

# vcs_info configuration
zstyle ':vcs_info:*' enable git hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{green}●%F{cyan}'
zstyle ':vcs_info:*' unstagedstr '%F{yellow}●%F{cyan}'
zstyle ':vcs_info:*' formats ' [%b%c%u]'
zstyle ':vcs_info:*' actionformats " [%b%c%u|%F{cyan}%a]"
zstyle ':vcs_info:git*+set-message:*' hooks git_status

# Prompt: hostname (yellow if SSH), path (red if not writable), git info, vi mode
# Insert mode: >  Normal mode: <  Root: >>
setopt PROMPT_SUBST
PROMPT='%B%F{cyan}${ssh_prompt}${path_color}%2~%F{cyan}${vcs_info_msg_0_} %(!.>>${VI_MODE_INDICATOR}.)${VI_MODE_INDICATOR}%f%b '
RPROMPT=''

# =============================================================================
# Zsh Plugins (from Homebrew)
# =============================================================================
# macOS (Homebrew)
if [[ -d /opt/homebrew/share ]]; then
    [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
        source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
        source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    [[ -f /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
        source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
# Linux
elif [[ -d /usr/share/zsh ]]; then
    [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
        source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
        source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    [[ -f /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
        source /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh
fi

# =============================================================================
# Modern CLI Replacements
# =============================================================================
# bat: cat with syntax highlighting
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    alias catp='bat'  # cat with pager
fi

# eza: modern ls with colors and icons
if command -v eza &>/dev/null; then
    alias ls='eza'
    alias ll='eza -l'
    alias la='eza -la'
    alias lt='eza --tree'
fi

# fzf: fuzzy finder (Ctrl-R for history, Ctrl-T for files, Alt-C for cd)
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)

    # Smart up-arrow: fzf history when line is empty, substring-search otherwise
    function _smart-history-up {
        if [[ -z $BUFFER ]]; then
            fzf-history-widget
        elif (( $+widgets[history-substring-search-up] )); then
            history-substring-search-up
        else
            up-line-or-history
        fi
    }
    zle -N _smart-history-up
    bindkey '^[[A' _smart-history-up

    # Keep down-arrow as substring-search (or regular history)
    if (( $+widgets[history-substring-search-down] )); then
        bindkey '^[[B' history-substring-search-down
    fi
else
    # No fzf: use history-substring-search if available
    if (( $+widgets[history-substring-search-up] )); then
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
    fi
fi

# Vi mode j/k for history (always substring-search)
if (( $+widgets[history-substring-search-up] )); then
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
fi

# zoxide: smarter cd (replaces fasd)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh --cmd cd)"  # replaces cd with zoxide
    # j: interactive list when no args, jump when args given
    function j {
        if [[ $# -eq 0 ]]; then
            cdi  # interactive (zoxide init --cmd cd creates cdi)
        else
            cd "$@"
        fi
    }
fi

# nnn: cd on quit (press ^G to quit and cd to last dir)
# Uses custom opener to open files in zellij pane when inside zellij
if command -v nnn &>/dev/null; then
    # Custom opener: opens text files in zellij pane or nvim
    export NNN_OPENER="$HOME/.nnn-opener"

    # Use trash instead of rm (macos: trash, linux: trash-cli)
    if [[ "$(uname -s)" == "Darwin" ]]; then
        command -v trash &>/dev/null && export NNN_TRASH="trash"
    else
        command -v trash-put &>/dev/null && export NNN_TRASH="trash-put"
    fi

    n() {
        # Block nesting of nnn in subshells
        [ "${NNNLVL:-0}" -eq 0 ] || {
            echo "nnn is already running"
            return
        }

        # cd on quit when pressing ^G
        export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

        # -c: use NNN_OPENER as CLI opener
        command nnn -c "$@"

        [ ! -f "$NNN_TMPFILE" ] || {
            . "$NNN_TMPFILE"
            rm -f -- "$NNN_TMPFILE" > /dev/null
        }
    }
fi

# =============================================================================
# Common Shell Configuration
# =============================================================================
[[ -f "$HOME/.shell_common" ]] && source "$HOME/.shell_common"

# =============================================================================
# macOS-specific aliases
# =============================================================================
if [[ "$(uname -s)" == "Darwin" ]]; then
    alias dt="cd ~/Desktop"
    alias icloud='cd ~/Library/Mobile\ Documents/com~apple~CloudDocs'
    alias rmxattr='xattr -rc * .*'
    alias rmdsstore="find . -name '*.DS_Store' -type f -delete"
fi

# =============================================================================
# Machine-specific configuration
# =============================================================================
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
