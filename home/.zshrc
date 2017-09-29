
# Source Prezto {{{1
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi
#  }}}1

# Options {{{1

# export editor='vim'
# export VISUAL='vim'

bindkey -v

setopt menucomplete
setopt nobeep
setopt rmstarwait

#  }}}1

# Aliases {{{1

# Fix Prezto's BS {{{2

alias cp='nocorrect cp'
alias ln='nocorrect ln'
alias mv='nocorrect mv'
alias rm='nocorrect rm'
alias cpi="${aliases[cp]:-cp} -i"
alias lni="${aliases[ln]:-ln} -i"
alias mvi="${aliases[mv]:-mv} -i"
alias rmi="${aliases[rm]:-rm} -i"

#  }}}2

eval $(thefuck --alias)

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

alias brewu='~/.brewupdate.sh'

alias mkdir='mkdir -pv'

alias dt="cd ~/Desktop"
alias icloud='cd ~/Library/Mobile\ Documents/com~apple~CloudDocs'

alias chmodall='find . -type f -print0 | xargs -0 chmod 0644 && \
    find . -type d -print0 | xargs -0 chmod 0755'

alias rmxattr='xattr -rc * .*'
alias rmdsstore="find . -name '*.DS_Store' -type f -delete"

alias cleanzip="find . -type d -print0 | xargs -0 chmod 0755 && \
    find . -type f -print0 | xargs -0 chmod 0644 && \
    xattr -rc *; \
    xattr -rc .*; \
    find . -name '*.DS_Store' -type f -delete && \
    find . -name '__MACOSX' -type f -delete && \
    zip -r ../archive.zip ."

#  }}}1

# Autocompletion often doesn't work when you change permissions on /usr/local;
# this can help
# autoload -U compinit && compinit
# zmodload -i zsh/complist

