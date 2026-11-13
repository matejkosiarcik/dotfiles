#!/bin/sh
set -euf

get_creation_date() {
    if [ "$(uname -s)" = 'Darwin' ]; then
        stat -f '%SB' -t '%Y-%m-%d_%H-%M-%S' "${1}"
    else
        stat -c '%w' "${1}" | sed -E 's~^([0-9]{4}-[0-9]{2}-[0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2}).*$~\1_\2-\3-\4~'
    fi
}

if [ "${#}" -ne 1 ]; then
    printf 'Usage: %s <screen-recording-file>\n' "${0}" >&2
    exit 1
fi

old_filepath="${1}"
if [ ! -e "${old_filepath}" ]; then
    # printf 'Skipping file (not found) - %s\n' "$(basename "${old_filepath}")"
    exit 0
fi

targetdir="${HOME}/Movies/Screenrecording"
if [ ! -d "${targetdir}" ]; then
    mkdir -p "${targetdir}"
fi

old_filename="$(basename "${old_filepath}")"

if printf '%s\n' "${old_filename}" | grep -E '^.+ [0-9]{4}-[0-9]{2}-[0-9]{2} at [0-9]{2}\.[0-9]{2}\.[0-9]{2}( [\(]?[0-9]+[\)]?)?\.[mM][oO][vV]$' >/dev/null; then
    # Use the timestamp in macOS screen-recording filenames when available
    date="$(printf '%s\n' "${old_filename}" | sed -E 's~^.+ ([0-9]{4})-([0-9]{2})-([0-9]{2}) at ([0-9]{2})\.([0-9]{2})\.([0-9]{2})( [\(]?[0-9]+[\)]?)?\.[a-zA-Z0-9]+$~\1-\2-\3_\4-\5-\6~')"
elif printf '%s\n' "${old_filename}" | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}( [0-9]+)?\.[mM][oO][vV]$' >/dev/null; then
    # Do not rename files that already have the daemon's target format
    exit 0
else
    date="$(get_creation_date "${old_filepath}")"
fi

extension="$(printf '%s\n' "$(basename "${old_filename}")" | sed -E 's~^.+\.([a-zA-Z0-9]+)$~\1~' | tr '[:upper:]' '[:lower:]')"
new_filename="${date}.${extension}"
new_filepath="${targetdir}/${new_filename}"

i=1
while [ -e "${new_filepath}" ] || [ -L "${new_filepath}" ]; do
    i="$((i + 1))"
    new_filepath="${targetdir}/${date} ${i}.${extension}"
done

mv -n "${old_filepath}" "${new_filepath}"
