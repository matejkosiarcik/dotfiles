#!/bin/sh
# A script to get or rename files based on exif data creation date
set -euf

usage() {
    printf 'Usage: exifd [-h] [-f] [-r] [-v] <dir>\n'
    printf ' dir    directory to analyze\n'
    printf ' -h     show help message\n'
    printf ' -f     force (auto confirm renaming files)\n'
    printf ' -r     recurse into subdirectories\n'
    printf ' -v     verbose logging\n'
}

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n\n' >&2
    usage >&2
    exit 1
fi

mode='n'
recursive='0'
verbose='0'
while getopts "h?f?n?r?v?" opt; do
    case "$opt" in
    h)
        usage
        ;;
    n)
        mode='n'
        ;;
    f)
        mode='f'
        ;;
    r)
        recursive='1'
        ;;
    v)
        verbose='1'
        ;;
    *)
        usage >&2
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"

root_dir="$1"
cd "$root_dir"
if [ "$verbose" = '1' ]; then
    printf 'dir: %s\n' "$root_dir"
    printf 'mode: %s' "$mode"
    printf 'recursive: %s' "$recursive"
fi

check_dir() {
    current_dir="$1"
    printf '\nAnalyzing %s\n' "$current_dir"
    summaryfile="$(mktemp)"

    find "$current_dir" \( \
        -iname '*.3gp' -or \
        -iname '*.avi' -or \
        -iname '*.jpeg' -or \
        -iname '*.jpg' -or \
        -iname '*.m4a' -or \
        -iname '*.m4v' -or \
        -iname '*.mod' -or \
        -iname '*.mov' -or \
        -iname '*.mp4' -or \
        -iname '*.mpg' -or \
        -iname '*.wav' \
        \) -not -iname '._*' -maxdepth 1 -type f | sort --version-sort | while read -r file; do

        # Get photo creation date (and optionally rename the file if desired)
        date="$(exiff "-$mode" "$file")"
        printf "%s\n" "$date" | sed -E 's~_.*~~' >>"$summaryfile"
    done

    # If there were some collisions (multiple photos with the same exact date)
    # The first photo will lack suffix (as a consequence, it will be sorted last in programs such as file explorer)
    # So add 0 suffix to it
    if [ "$mode" = 'f' ]; then
        find "$current_dir" \( \
            -iname '*.3gp' -or \
            -iname '*.avi' -or \
            -iname '*.jpeg' -or \
            -iname '*.jpg' -or \
            -iname '*.m4a' -or \
            -iname '*.m4v' -or \
            -iname '*.mod' -or \
            -iname '*.mov' -or \
            -iname '*.mp4' -or \
            -iname '*.mpg' -or \
            -iname '*.wav' \
            \) -not -iname '._*' -maxdepth 1 -and -name "* 1.*" -type f | sort --version-sort | while read -r file; do
            filename="$(basename "$file")"
            fileext="$(printf '%s' "$filename" | sed -E 's~^.*\.~~')"
            filedate="$(basename "$file" " 1.$fileext")"
            oldfile="$(dirname "$file")/$filedate.$fileext"
            newfile="$(dirname "$file")/$filedate 0.$fileext"
            if [ -e "$oldfile" ]; then
                if [ ! -e "$newfile" ]; then
                    mv "$oldfile" "$newfile"
                else
                    printf 'ERROR: %s already exist!\n' "$newfile" >&2
                fi
            fi
        done
    fi

    printf 'Summary %s:\n' "$current_dir"
    sort --version-sort <"$summaryfile" | uniq -c
    rm -rf "$summaryfile"
}

dirfile="$(mktemp)"
if [ "$recursive" -eq 1 ]; then
    find . -type d >"$dirfile"
else
    if [ "$(find . -type d -mindepth 1 | wc -l)" -gt 0 ]; then
        printf 'WARNING: Found nested directories. Ignoring them and proceeding.\n'
    fi
    printf '.\n' >"$dirfile"
fi

while read -r dir; do
    check_dir "$dir"
done <"$dirfile"

rm -rf "$dirfile"
