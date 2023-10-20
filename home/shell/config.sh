#!/bin/sh

# Customize PATH
export PATH="$HOME/.bin/scripts:$PATH"

# gpg
GPG_TTY="$(tty)"
export GPG_TTY

# Aliases
alias tree='tree --ignore-case -CI ".build|.git|.hg|.svn|.venv|*.xcodeproj|*.xcworkspace|bower_components|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods|target|vendor|venv"'
alias pbfix='pbpaste | pbcopy'
alias o='open'
alias exa='exa --long --tree --git-ignore --time modified --time-style long-iso --extended  --all --ignore-glob ".git"'
# TODO: install exa as project dependency
alias diff='git diff --no-index'

# Git aliases
alias ds='git diff --staged | diff2html'
alias diff2html='diff2html -s side -i stdin'
# TODO: install diff2html as project dependency
alias t='tig'
alias s='tig status'
alias g='git'

# Automatic PR creation
alias ghpr='gh pr create --assignee matejkosiarcik --title "Automated PR" --body "" && sleep 2 && gh pr merge --auto --merge'
# alias glmr='glab mr create --assignee matej.kosiarcik --title "Automated MR" --description "" --remove-source-branch && sleep 2 && glab mr merge "$(git branch --show-current)" --when-pipeline-succeeds --remove-source-branch'

# Download video/audio from youtube with best quality
# `-f best` is not enough, because it is limited to 1080p (IIRC)
alias ytdv='youtube-dl --ignore-error --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4" --'
alias ytda='youtube-dl --ignore-error --format "bestaudio[ext=m4a]" --'

# azlint
alias azlint_lint='docker run --interactive --volume "$PWD:/project:ro" matejkosiarcik/azlint:dev lint'
alias azlint_fmt='docker run --interactive --volume "$PWD:/project" matejkosiarcik/azlint:dev fmt'
alias azc='printf "Formatting...\n" && azlint_fmt --only-changed && printf "Linting...\n" && azlint_lint --only-changed'
alias az='printf "Formatting...\n" && azlint_fmt && printf "Linting...\n" && azlint_lint'

# Other
alias whatsmyip='curl --silent ipinfo.io | jq -r .ip'
alias csv2json='mlr --icsv --ojson --jlistwrap cat'

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
