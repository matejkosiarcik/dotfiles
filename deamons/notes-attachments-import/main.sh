#!/bin/sh
set -euf

project_dir="$(dirname "$(readlink "$0")")"
cd "$project_dir"

PATH="$project_dir/python/bin:/opt/homebrew/bin:$PATH"
export PATH
PYTHONPATH="$project_dir/python"
export PYTHONPATH

# Set [and create] target directory
if [ ! -e "$HOME/Notes" ]; then
    printf 'No notes folder found\n' >&2
    exit 0
fi
watchdir="$HOME/Notes/.attachments"

# Rename existing files
tmpfile="$(mktemp)"
find "$watchdir" -maxdepth 1 -type f -name '*.*' \( -not -name '.*' \) -print0 >"$tmpfile"
xargs -0 -n1 sh rename.sh <"$tmpfile"
rm -f "$tmpfile"

# Watch for changes and rename newly added files
watchmedo shell-command "$watchdir" \
    --wait \
    --quiet \
    --ignore-directories \
    --patterns '*.*' \
    --command 'if { [ "$watch_event_type" = modified ] || [ "$watch_event_type" = created ]; } && [ "$watch_object" = file ]; then sh rename.sh "$watch_src_path"; fi'
# NOTE: Because Notes can be inside of Dropbox, the events received aren't "created" as usual, but rather "modified"
