#!/bin/sh
set -euf

source_dir="$(dirname "$(readlink "$0")")"
export source_dir

PATH="/opt/homebrew/bin:$PATH"
export PATH

# Prepare target directory
watchdir="$HOME/Pictures/Screenshots"
if [ ! -d "$watchdir" ]; then
    mkdir -p "$watchdir"
fi

# Rename existing files
tmpfile="$(mktemp)"
find "$watchdir" -maxdepth 1 -type f -iname '*.png' -print0 |
    grep -E -i -z '/Screenshot [0-9]{4}-[0-9]{2}-[0-9]{2} at [0-9]{2}\.[0-9]{2}\.[0-9]{2}(?: [0-9]+)?\.png$' >"$tmpfile" || true
xargs -0 -n1 sh -c 'sh "$source_dir/rename.sh" "$1" || true' - <"$tmpfile"
rm -f "$tmpfile"

# Watch for new files
# shellcheck disable=SC2016
fswatch "$watchdir" --event=Created --event=MovedTo --event=Renamed -E --exclude '(^|/)\..+$' --exclude '(^|/)[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}( [0-9]+)?\.png$' --print0 |
    xargs -0 -n1 sh -c 'if [ -f "$2" ]; then sh "$1/rename.sh" "$2" || true; fi' - "$source_dir"
