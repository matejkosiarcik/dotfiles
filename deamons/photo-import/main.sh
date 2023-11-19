#!/bin/sh
set -euf

source_dir="$(dirname "$(readlink "$0")")"
export source_dir

PATH="$source_dir/python/bin:/opt/homebrew/bin:$HOME/.bin/scripts:$PATH"
export PATH
PYTHONPATH="$source_dir/python"
export PYTHONPATH

# Set [and create] target directory
watchdir="$HOME/Pictures/Import"
if [ ! -d "$watchdir" ]; then
    mkdir -p "$watchdir"
fi

# Rename existing files
tmpfile="$(mktemp)"
find "$watchdir" -maxdepth 1 -type f \( -iname '*.jpg' -or -iname '*.jpeg' -or -iname '*.png' -or -iname '*.mov' -or -iname '*.mp4' \) -print0 >"$tmpfile"
xargs -0 -n1 photo-exif-rename <"$tmpfile"
rm -f "$tmpfile"

# Watch for changes and rename newly added files
watchmedo shell-command "$watchdir" \
    --wait \
    --quiet \
    --ignore-directories \
    --patterns '*.jpg;*.jpeg;*.png;*.mov;*.mp4' \
    --command 'if [ "$watch_event_type" = created ] && [ "$watch_object" = file ]; then photo-exif-rename "$watch_src_path"; fi'
# NOTE: We could also listen for "move" events, but it would be really easy to fall into infinite loop
