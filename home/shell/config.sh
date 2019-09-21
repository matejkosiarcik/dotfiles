# shellcheck shell=sh

export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# customize PATH
export PATH="${PATH}:${HOME}/.bin" # custom bin directory

# Aliases
alias logtree="tree --ignore-case -CI '.build|.git|.venv|*.xcodeproj|bower_components|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods|target|vendor|venv'"

# Git aliases
alias df="git df | h"
alias ds="git ds | h"
alias h='diff2html -s side -i stdin'
alias s="tig status"
alias t='tig'

# Open new terminal at current directory
tdup() {
    # TODO: make iterm2, hyper.js compatible
    # TODO: make ubuntu compatible
    open -a 'Terminal' "${PWD}"
}

# Create directory (if not exists) and navigate to it
mcd() {
    # Validate argument count
    case "${#}" in
        0) printf 'No arguments provided\n'; return 1;;
        1) ;; # Valid
        *) printf 'Too many arguments provided\n'; return 1;;
    esac

    # Run function
    mkdir -p "${1}" || return 1
    cd "${1}" || return 1
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
