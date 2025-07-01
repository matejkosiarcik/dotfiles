#!/bin/sh

# Customize PATH
export PATH="$HOME/.config/matejkosiarcik/bin:$PATH"
export PATH="$HOME/.bin/sshpass/usr/local/bin:$PATH"

# Hide NodeJS warnings
NODE_NO_WARNINGS='1'
export NODE_NO_WARNINGS

# Docker compose bake
COMPOSE_BAKE='true'
export COMPOSE_BAKE

# Default HOMELAB_ENV value
HOMELAB_ENV='dev'
export HOMELAB_ENV

# gpg
GPG_TTY="$(tty)"
export GPG_TTY

# Aliases
alias tree='tree --ignore-case -CI ".build|.git|.hg|.svn|.venv|*.xcodeproj|*.xcworkspace|bower_components|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods|target|vendor|venv"'
alias pbfix='pbpaste | pbcopy'
alias o='open'
alias exa='exa --long --tree --git-ignore --time modified --time-style long-iso --extended  --all --ignore-glob ".git"'
# TODO: install exa as project dependency

# Git aliases
# TODO: install diff2html as project dependency
alias ds='git diff --staged | diff2html -s side -i stdin'
alias d2h='diff2html -s side -i stdin'
alias t='tig'
alias s='tig status'
alias g='git'

# Automatic PR creation
alias ghpr='gh pr create --assignee matejkosiarcik --title "Development PR" --body "" && sleep 2 && gh pr merge --auto --merge'
alias glpr='glab mr create --assignee matejkosiarcik --title "Development PR" --description "" --remove-source-branch && sleep 3 && glab mr merge "$(git branch --show-current)" --auto-merge --remove-source-branch --yes'

# Download video/audio from youtube with best quality
# `-f best` is not enough, because it is limited to 1080p (IIRC)
alias ytdv='yt-dlp --ignore-error --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4" --'
alias ytda='yt-dlp --ignore-error --format "bestaudio[ext=m4a]" --'

# azlint
alias azlint_lint='docker run --interactive --volume "$PWD:/project:ro" matejkosiarcik/azlint:dev lint'
alias azlint_fmt='docker run --interactive --volume "$PWD:/project" matejkosiarcik/azlint:dev fmt'

# Other
alias whatsmyip='curl --silent ipinfo.io | jq -r .ip'
alias csv2json='mlr --icsv --ojson --jlistwrap cat'
alias drawio='/Applications/draw.io.app/Contents/MacOS/draw.io'

# Open new terminal at current directory
tdup() {
    # TODO: make iterm2, hyper.js compatible
    # TODO: make ubuntu compatible
    open -a 'Terminal' "$PWD"
}

# Create directory (if not exists) and navigate to it
mcd() {
    # Validate argument count
    case "$#" in
    0)
        printf 'No arguments provided\n' >&2
        return 1
        ;;
    1) ;; # Valid
    *)
        printf 'Too many arguments provided\n' >&2
        return 1
        ;;
    esac

    # Run function
    mkdir -p "$1" || return 1
    cd "$1" || return 1
}

# Normalize 'open' on non-Macs
if [ "$(uname)" != 'Darwin' ]; then
    if grep -q Microsoft /proc/version; then # Ubuntu on Windows using the Linux subsystem
        alias open='explorer.exe'
    else
        alias open='xdg-open' # Linux
    fi
fi

# Normalize PasteBoard commands on non-Macs
if [ "$(uname)" != 'Darwin' ]; then
    if command -v xclip >/dev/null 2>&1; then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
    fi

    if command -v xsel >/dev/null 2>&1; then
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
    fi
fi

# runs specified commnand N times
runN() {
    if [ "$#" -lt 2 ]; then
        printf 'Not enough arguments. Run like "runN 2 echo foo".\n' >&2
        return 1
    fi

    count="$1"
    if [ "$count" -lt 0 ]; then
        printf "Can't repeat command negative amount of times." >&2
        return 1
    fi
    shift

    printf 'Executing "%s" for %s times.\n' "$*" "$count" >&2
    i='1'
    while [ "$i" -le "$count" ]; do
        printf '\n'
        printf '%s\n' "--- $i. run ---"
        printf '%s\n' "Start at: $(date +'%Y-%m-%d %H:%M:%S')"
        printf '\n'

        (set -euf && time "$@")
        statuscode="$?"
        if [ "$statuscode" != 0 ]; then
            printf 'Command "%s" returned %s. Stopping.\n' "$*" "$statuscode"
            return 1
        fi

        printf '\n'
        printf '%s\n' "End at: $(date +'%Y-%m-%d %H:%M:%S')"
        printf '%s\n' "^^^ $i. run ^^^"

        i="$((i + 1))"
    done
}

# print n-th line of file
# usage: `line 3 example.txt` or `line 3 <example.txt`
line() {
    (if [ "$#" -lt 2 ]; then cat; else cat "$2"; fi) |
        head -n "$1" |
        tail -n 1
}

gdiff() {
    if [ "$#" -lt 2 ]; then
        printf 'Not enough arguments' >&2
        return 1
    fi
    git diff --no-index "$1" "$2" | diff2html -s side -i stdin
}
