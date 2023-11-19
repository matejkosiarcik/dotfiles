#!/bin/sh
set -euf

source_dir="$(dirname "$(readlink "$0")")"
export source_dir

PATH="$source_dir/python/bin:/opt/homebrew/bin:$PATH"
export PATH
PYTHONPATH="$source_dir/python"
export PYTHONPATH

# Set [and create] target directory
watchdir="$HOME/Notes/.attachments"
if [ ! -d "$watchdir" ]; then
    mkdir -p "$watchdir"
fi

# Rename existing files
tmpfile="$(mktemp)"
find "$watchdir" -maxdepth 1 -type f -name '*.*' \( -not -name '.*' \) -print0 >"$tmpfile"
xargs -0 -n1 sh "$source_dir/rename.sh" <"$tmpfile"
rm -f "$tmpfile"

# Watch for changes and rename newly added files
watchmedo shell-command "$watchdir" \
    --wait \
    --quiet \
    --ignore-directories \
    --patterns '*.*' \
    --command 'if { [ "$watch_event_type" = modified ] || [ "$watch_event_type" = created ]; } && [ "$watch_object" = file ]; then sh "$source_dir/rename.sh" "$watch_src_path"; fi'
# NOTE: Because Notes can be inside of Dropbox, the events received aren't "created" as usual, but rather "modified"
