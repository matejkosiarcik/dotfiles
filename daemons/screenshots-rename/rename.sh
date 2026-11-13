#!/bin/sh
set -euf

get_creation_date() {
    if [ "$(uname -s)" = 'Darwin' ]; then
        stat -f '%SB' -t '%Y-%m-%d_%H-%M-%S' "${1}"
    else
        stat -c '%w' "${1}" | sed -E 's~^([0-9]{4}-[0-9]{2}-[0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2}).*$~\1_\2-\3-\4~'
    fi
}

if [ "${#}" -lt 1 ]; then
    printf 'Not enough arguments to rename file\n' >&2
    usage >&2
    exit 1
fi

file="${1}"

cd "$(dirname "${file}")"
old_filename="$(basename "${file}")"

if [ ! -e "${old_filename}" ] || [ ! -f "${old_filename}" ]; then
    # printf 'Skipping file (not found) %s\n' "${old_filename}"
    exit 0
fi

if printf '%s\n' "${old_filename}" | grep -E '^.+ [0-9]{4}-[0-9]{2}-[0-9]{2} at [0-9]{2}\.[0-9]{2}\.[0-9]{2}( [\(]?[0-9]+[\)]?)*\.png$' >/dev/null; then
    # Use the timestamp in macOS screenshot filenames when available
    date="$(printf '%s\n' "${old_filename}" | sed -E 's~^.+ ([0-9]{4})-([0-9]{2})-([0-9]{2}) at ([0-9]{2})\.([0-9]{2})\.([0-9]{2})( [\(]?[0-9]+[\)]?)*\.png$~\1-\2-\3_\4-\5-\6~')"
elif printf '%s\n' "${old_filename}" | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}( [0-9]+)?\.png$' >/dev/null; then
    # Do not rename files that already have the daemon's target format
    exit 0
else
    date="$(get_creation_date "${old_filename}")"
fi

new_filename="${date}.png"

# Check if the new file already exists (2 photos with the exact date taken)
i=1
if [ -e "${new_filename}" ] || [ -L "${new_filename}" ] || [ -e "${date} 1.png" ] || [ -L "${date} 1.png" ] || [ -e "${date} 01.png" ] || [ -L "${date} 01.png" ] || [ -e "${date} 001.png" ] || [ -L "${date} 001.png" ]; then
    # If we are adding "A.jpg", but it already exists, we will add "A 2.jpg"
    # But we need to rename the former image to "A 1.jpg"
    if [ -e "${new_filename}" ] || [ -L "${new_filename}" ]; then
        if [ ! -e "${date} 1.png" ] && [ ! -L "${date} 1.png" ] && [ ! -e "${date} 01.png" ] && [ ! -L "${date} 01.png" ] && [ ! -e "${date} 001.png" ] && [ ! -L "${date} 001.png" ]; then
            mv "${new_filename}" "${date} 1.png"
        fi
    fi
    i=2
    new_filename="${date} ${i}.png"
fi

# Determine full filename (increment index until it doesn't exists)
while [ -e "${new_filename}" ] || [ -L "${new_filename}" ]; do
    if [ "${new_filename}" = "${old_filename}" ]; then
        break
    fi
    i="$((i + 1))"
    new_filename="${date} ${i}.png"
done

if [ "${new_filename}" != "${old_filename}" ]; then
    mv "${old_filename}" "${new_filename}"
fi
