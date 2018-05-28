# shellcheck shell=sh

export PATH="${PATH}:${HOME}/bin:/Library/TeX"

# Simple aliases
alias o='open'
alias t='tig'

# Advanced aliases
alias h='diff2html -s side -i stdin'
alias pine="tree --ignore-case -CI '.build|.git|*.xcodeproj|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods'"

# Functions
tdup() {
    open -a 'Terminal' "${PWD}"
}

mcd() {
    mkdir -p "${1}" && cd "${1}"
}

tap() {
    mkdir -p "$(dirname "${1}")" && touch "${1}"
}
