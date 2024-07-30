#!/bin/sh
set -euf

# Disable for xargs
# shellcheck disable=SC2016

source_dir="$(dirname "$(readlink "$0")")"
export source_dir

PATH="$source_dir/python/bin:/opt/homebrew/bin:$PATH"
export PATH
PYTHONPATH="$source_dir/python"
export PYTHONPATH

watchdir="$HOME/Desktop"

# Move existing files
tmpfile="$(mktemp)"
find "$watchdir" -maxdepth 1 -type f \( -iname '*.mov' -or -iname '*.mp4' \) -print0 >"$tmpfile"
xargs -0 -n1 sh "$source_dir/move.sh" <"$tmpfile"
rm -f "$tmpfile"

# Watch for changes and rename newly added files
watchmedo shell-command "$watchdir" \
    --wait \
    --quiet \
    --ignore-directories \
    --patterns '*.mov;*.mp4' \
    --command 'if [ "$watch_object" = file ] && { [ "$watch_event_type" = created ] || [ "$watch_event_type" = modified ]; }; then sleep 1 && sh "$source_dir/move.sh" "$watch_src_path"; fi'
# NOTE: We could also listen for "move" events, but it would be really easy to fall into infinite loop
