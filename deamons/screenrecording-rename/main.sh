#!/bin/sh
set -euf

cd "$(dirname "$0")"
venvpath="$(dirname "$(readlink 'main.sh')")/venv/bin"
PATH="$PATH:/opt/homebrew/bin:$venvpath"

# Set [and create] target directory
watchdir="$HOME/Movies/Screenrecording"
if [ ! -d "$watchdir" ]; then
    mkdir -p "$watchdir"
fi

# Rename existing files
tmpfile="$(mktemp)"
find "$watchdir" -maxdepth 1 -type f \( -iname '*.mov' -or -iname '*.mp4' \) -print0 >"$tmpfile"
xargs -0 -n1 sh rename.sh <"$tmpfile"
rm -f "$tmpfile"

# Watch for changes and rename newly added files
watchmedo shell-command "$watchdir" \
    --wait \
    --quiet \
    --ignore-directories \
    --patterns '*.mov;*.mp4' \
    --command 'if [ "$watch_event_type" = created ] && [ "$watch_object" = file ]; then sh rename.sh "$watch_src_path"; fi'
# NOTE: We could also listen for "move" events, but it would be really easy to fall into infinite loop
