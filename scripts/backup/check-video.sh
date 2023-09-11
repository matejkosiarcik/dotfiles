#!/bin/sh
set -euf

# This script iterates video files in a given directory
# and checks them for errors - useful for example after downloading

root="."
if [ "$#" -ge 1 ]; then
    root="${1}"
fi
logfile='errors.txt'
rm -f "$logfile"

find "$root" \( -iname '*.mp4' -or -iname '*.mkv' -or -iname '*.avi' -or -iname '*.ts' -or -iname '*.3gp' \) | while read -r file; do
    infoline="$(printf 'Checking %s...' "$file")"
    printf '%s' "$infoline" >&2

    printf '%s\n' "$file" >>"$logfile"
    if ffmpeg -nostdin -v error -i "$file" -f null - >>"$logfile" 2>&1; then
        filestatus='-y-'
    else
        filestatus='XXX'
    fi
    printf '\n\n\n' >>"$logfile"

    printf '\r%s' "$infoline" | sed -E 's~.~ ~g' | tr -d '\n' >&2 # must wipe previous line before printing new line, otherwise old characters see through
    printf '\r%s \t%s\n' "$filestatus" "$file" >&2
done
