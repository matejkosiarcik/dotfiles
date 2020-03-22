# shellcheck shell=sh

# settings
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Customize PATH
export PATH="${PATH}:${HOME}/bin:${HOME}/.bin:${HOME}/.jetbrains"

# Include other config files
# shellcheck source=/dev/null
[ -f "${HOME}/.config-secret.sh" ] && . "${HOME}/.config-secret.sh"
# shellcheck source=/dev/null
[ -f "${HOME}/.profile" ] && . "${HOME}/.profile"

# Aliases
alias logtree="tree --ignore-case -CI '.build|.git|.venv|*.xcodeproj|bower_components|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods|target|vendor|venv'"

# Git aliases
alias df="git df | h"
alias ds="git ds | h"
alias h='diff2html -s side -i stdin'
alias s="tig status"
alias t='tig'

gitup() {
    git fetch origin master:master || return 1
    git remote prune origin || return 1
    # if [ "$(git branch | grep '*' | cut -d' ' -f2)" = "$(git branch --merged master | grep -v 'master' | grep '*' | cut -d' ' -f2)" ]; then
    #     git rebase master
    # fi
    git branch --merged master | grep -v '*' | grep -v 'master' | xargs -n1 git branch -d || return 1

}

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
