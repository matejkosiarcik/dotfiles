#!/bin/sh

# Customize PATH
export PATH="${HOME}/.bin:${PATH}"

# gpg
GPG_TTY="$(tty)"
export GPG_TTY

# Include other config files
# shellcheck source=/dev/null
[ -f "${HOME}/.config-secret.sh" ] && . "${HOME}/.config-secret.sh"
# shellcheck source=/dev/null
[ -f "${HOME}/.profile" ] && . "${HOME}/.profile"

# Aliases
alias logtree="tree --ignore-case -CI '.build|.git|.hg|.svn|.venv|*.xcodeproj|*.xcworkspace|bower_components|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods|target|vendor|venv'"
alias m='make'

# Git aliases
alias df="git df | h"
alias ds="git ds | h"
alias h='diff2html -s side -i stdin'
alias s="tig status"
alias t='tig'

gitup() {
    git fetch --all --tags --prune --prune-tags

    if (git branch --list | grep -q master); then # check if master exists
        if [ "$(git rev-parse --abbrev-ref HEAD)" = master ]; then
            git pull --ff-only || return 1 # update master when we it's checked
        else
            git fetch origin master:master || return 1 # update master when we are on different branch
        fi

        git branch --merged master | grep -ve '\*' -e 'master' | xargs -n1 git branch -d || return 1
        if [ "$(git rev-parse --abbrev-ref HEAD)" != master ]; then
            git rebase master || return 1
        fi
    fi
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
    0)
        printf 'No arguments provided\n'
        return 1
        ;;
    1) ;; # Valid
    *)
        printf 'Too many arguments provided\n'
        return 1
        ;;
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
o() {
    if [ "${#}" -eq 0 ]; then
        open .
    else
        # shellcheck disable=SC2086
        open ${@}
    fi
}

# Smart alias for `code`
c() {
    if [ "${#}" -eq 0 ]; then
        code .
    else
        # shellcheck disable=SC2086
        code ${@}
    fi
}
