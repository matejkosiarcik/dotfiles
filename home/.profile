# shellcheck shell=sh

# customize PATH
export PATH="${PATH}:${HOME}/.custom-user-scripts"

# Simple aliases
alias o='open'
alias t='tig'

# Advanced aliases
alias h='diff2html -s side -i stdin'
alias pine="tree --ignore-case -CI '.build|.git|*.xcodeproj|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods'"

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
