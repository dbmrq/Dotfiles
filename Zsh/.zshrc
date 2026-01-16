# Source Prezto
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Options
bindkey -v
setopt menucomplete
setopt nobeep
setopt rmstarwait

# Fix Prezto's autocorrect
alias cp='nocorrect cp'
alias ln='nocorrect ln'
alias mv='nocorrect mv'
alias rm='nocorrect rm'
alias cpi="${aliases[cp]:-cp} -i"
alias lni="${aliases[ln]:-ln} -i"
alias mvi="${aliases[mv]:-mv} -i"
alias rmi="${aliases[rm]:-rm} -i"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias dt="cd ~/Desktop"
alias icloud='cd ~/Library/Mobile\ Documents/com~apple~CloudDocs'

# Utilities
alias mkdir='mkdir -pv'
alias zipr='f() { zip -r $1.zip $1 };f'
alias rmxattr='xattr -rc * .*'
alias rmdsstore="find . -name '*.DS_Store' -type f -delete"

# PATH
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="$PATH:$HOME/.local/bin"

# Completions
autoload -U compinit && compinit
