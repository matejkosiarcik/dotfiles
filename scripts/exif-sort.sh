#!/bin/sh
set -euf

usage() {
    printf 'Usage: exif-sort [-h] [-n] [-i] [-f] [-r] <dir>\n'
    printf ' dir    directory to analyze\n'
    printf ' -h     show help message\n'
    printf ' -n     dry run (do not rename anything)\n'
    printf ' -f     force (auto confirm renaming files)\n'
    printf ' -r     recurse into subdirectories\n'
}

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n\n' >&2
    usage >&2
    exit 1
fi

mode=''
recursive='0'
while getopts "h?n?f?r?" opt; do
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
    *)
        usage >&2
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"
if [ "$mode" = '' ]; then
    printf 'No mode specified (specify either -n|-f)\n\n' >&2
    usage >&2
    exit 1
fi

root_dir="$1"
# echo "mode: $mode"
# echo "recursive: $recursive"
# echo "dir: $dir"
cd "$root_dir"

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
        \) -maxdepth 1 -type f | sort --version-sort | while read -r file; do
        filedir="$root_dir/$(dirname "$file")"
        filename="$(basename "$file")"
        fileext="$(printf '%s' "$filename" | sed -E 's~^.*\.~~')"

        # Get photo creation date
        date="$(exif-file "$file")"

        if [ "$date" != '' ]; then
            printf "%s\n" "$date" | sed -E 's~_.*~~' >>"$summaryfile"
            printf '%s: %s\n' "$date" "$filename" >&2

            if [ "$mode" = 'f' ]; then
                newfilename="$date.$fileext"

                if [ "$newfilename" != "$filename" ]; then
                    # Check if the new file already exists (2 photos with the exact date taken)
                    # In such case name the second photo with an iterator suffix
                    i=0
                    while [ -e "$filedir/$newfilename" ]; do
                        i="$((i + 1))"
                        newfilename="$date $i.$fileext"
                    done

                    mv "$filedir/$filename" "$filedir/$newfilename"
                fi
            fi
        else
            printf 'ERROR: No date for %s\n' "$filename" >&2
        fi
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
            \) -maxdepth 1 -and -name "* 1.*" -type f | sort --version-sort | while read -r file; do
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
    cat "$summaryfile" | sort --version-sort | uniq -c
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

cat "$dirfile" | while read -r dir; do
    check_dir "$dir"
done

rm -rf "$dirfile"
