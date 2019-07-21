# shellcheck shell=sh

# customize PATH
export PATH="${PATH}:${HOME}/.bin"

# Simple aliases
alias s="tig status"
alias t='tig'

alias df="git df | h"
alias ds="git ds | h"

# Advanced aliases
alias h='diff2html -s side -i stdin'
alias pine="tree --ignore-case -CI '.build|.git|.venv|*.xcodeproj|bower_components|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods|target|vendor|venv'"

# Open new terminal at current directory
tdup() {
    # TODO: make iterm2, hyper.js compatible
    # TODO: make ubuntu compatible
    open -a 'Terminal' "${PWD}"
}

# Create folder if not existed and go to it
mcd() {
    mkdir -p "${1}" && cd "${1}"
}

# Normalize 'open' on all systems
if [ "$(uname)" != 'Darwin' ]; then
    if grep -q Microsoft /proc/version; then # Ubuntu on Windows using the Linux subsystem
        alias open='explorer.exe'
    else
        alias open='xdg-open'
    fi
fi

# Smart alias for 'open'
# which also accepts no options to open current directory
o() {
    if [ "${#}" -eq 0 ]; then
        open '.';
    else
        open "${@}";
    fi;
}
