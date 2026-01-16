# Executes commands at login pre-zshrc.

# Browser
if [[ "$OSTYPE" == darwin* ]]; then
    export BROWSER='open'
fi

# Editors
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'

# Language
if [[ -z "$LANG" ]]; then
    export LANG='en_US.UTF-8'
fi

# Paths (ensure no duplicates)
typeset -gU cdpath fpath mailpath path

path=(
    /usr/local/{bin,sbin}
    $path
)

# Less
export LESS='-F -g -i -M -R -S -w -X -z-4'

if (( $#commands[(i)lesspipe(|.sh)] )); then
    export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

# Temporary files
if [[ ! -d "$TMPDIR" ]]; then
    export TMPDIR="/tmp/$LOGNAME"
    mkdir -p -m 700 "$TMPDIR"
fi
TMPPREFIX="${TMPDIR%/}/zsh"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
