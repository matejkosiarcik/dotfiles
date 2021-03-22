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
alias logtree='tree --ignore-case -CI ".build|.git|.hg|.svn|.venv|*.xcodeproj|*.xcworkspace|bower_components|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods|target|vendor|venv"'
alias m='make'
alias d='docker'
alias dr='docker run --interactive --tty'
alias db='docker build'

# Git aliases
alias df='git df | h'
alias ds='git ds | h'
alias h='diff2html -s side -i stdin'
alias s='tig status'
alias t='tig'
alias pbfix='pbpaste | pbcopy'

# Create Pull-Request on github
# alias ghpr='hub pull-request -a matejkosiarcik -l automerge,autoupdate -m "Automated PR"'
alias ghpr='gh pr create --assignee matejkosiarcik --title "Automated PR" --body ""'

# download video/audio from youtube with best quality
# -f best is not enough, because it is limited to 1080p (IIRC)
alias ytdv='youtube-dl --ignore-error --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4" --'
alias ytda='youtube-dl --ignore-error --format "bestaudio[ext=m4a]" --'

# download from uloz.to using ulozto-downloader wrapped in docker
alias uloztod='docker run --interactive --tty --volume "${PWD}:/downloads" matejkosiarcik/ulozto-downloader:dev --output /downloads --auto-captcha --parts 10'

# Update local repository
gitup() {
    git fetch --all --tags --prune --prune-tags

    if (git branch --list | grep -q master); then # check if master exists
        if [ "$(git rev-parse --abbrev-ref HEAD)" = master ]; then
            git pull --ff-only || return 1 # update master when it's checked
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
        # shellcheck disable=SC2086,SC2068
        open ${@}
    fi
}

# Smart alias for `code`
c() {
    if [ "${#}" -eq 0 ]; then
        code .
    else
        # shellcheck disable=SC2086,SC2068
        code ${@}
    fi
}

# runs specified commnand N times
runN() {
    if [ "${#}" -lt 2 ]; then
        printf 'Not enough arguments. Run like "runN 2 echo foo".\n'
        return 1
    fi

    count="${1}"
    if [ "${count}" -lt 0 ]; then
        printf "Can't repeat command negative amount of times." >&2
        return 1
    fi
    shift

    printf 'Executing "%s" for %s times.\n' "${*}" "${count}" >&2
    i='0'
    while [ "${i}" -le "${count}" ]; do
        printf '\n'
        printf '%s %s. run ---\n' '---' "$((i+1))"
        printf '\n'

        (set -euf && time "${@}")
        statuscode="${?}"
        if [ "${statuscode}" != 0 ]; then
            printf 'Command "%s" returned %s. Stopping.\n' "${*}" "${statuscode}"
            return 1
        fi
        i="$((i+1))"
    done
}

# print n-th line of file
# usage: `line 3 example.txt` or `line 3 <example.txt`
line() {
    (if [ "${#}" -lt 2 ]; then cat; else cat "${2}"; fi) | \
        head -n "${1}" | \
        tail -n 1
}
