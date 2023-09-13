#!/bin/sh
set -euf

project_dir="$(dirname "$(readlink "$0")")"
cd "$project_dir"

PATH="$project_dir/python/bin:/opt/homebrew/bin:$PATH"
export PATH
PYTHONPATH="$project_dir/python"
export PYTHONPATH

# Set [and create] target directory
watchdir="$HOME/Pictures/Screenshots"
if [ ! -d "$watchdir" ]; then
    mkdir -p "$watchdir"
fi

# Rename existing files
tmpfile="$(mktemp)"
find "$watchdir" -maxdepth 1 -type f -iname '*.png' -print0 >"$tmpfile"
xargs -0 -n1 sh rename.sh <"$tmpfile"
rm -f "$tmpfile"

# Watch for changes and rename newly added files
watchmedo shell-command "$watchdir" \
    --wait \
    --quiet \
    --ignore-directories \
    --patterns '*.png' \
    --command 'if [ "$watch_event_type" = created ] && [ "$watch_object" = file ]; then sh rename.sh "$watch_src_path"; fi'
# NOTE: We could also listen for "move" events, but it would be really easy to fall into infinite loop
