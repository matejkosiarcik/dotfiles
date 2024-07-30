#!/bin/sh
set -euf

PATH="/opt/homebrew/bin:$HOME/.matejkosiarcik-dotfiles/bin:$PATH"
export PATH

# Prepare target directory
watchdir="$HOME/Pictures/Import"
if [ ! -d "$watchdir" ]; then
    mkdir -p "$watchdir"
fi

# Rename existing files
tmpfile="$(mktemp)"
find "$watchdir" \
    -maxdepth 1 \
    -type f \
    \( -iname '*.jpe' -or -iname '*.jpg' -or -iname '*.jpeg' -or -iname '*.png' -or -iname '*.mov' -or -iname '*.mp4' -or -name '*.heic' -or -name '*.heif' \) |
    grep -E -i '\.(?:hei[cf]|jpeg|jp[eg]|mov|mp4|png)$' |
    grep -E -v '/[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}(?: [0-9]+)?\.[A-Za-z0-9-]+$' >"$tmpfile" || true
# shellcheck disable=SC2016
xargs -n1 sh -c 'photo-exif-rename "$1" || true' - <"$tmpfile"
rm -f "$tmpfile"

# Watch for new files
# shellcheck disable=SC2016
fswatch "$watchdir" --event=Created --event=MovedTo --event=Renamed -E --exclude '(^|/)\..+$' --exclude '(^|/)[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}( [0-9]+)?\.[A-Za-z0-9-]+$' --print0 |
    xargs -0 -n1 sh -c 'if [ -f "$1" ]; then photo-exif-rename "$1" || true; fi' -
