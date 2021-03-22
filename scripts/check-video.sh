#!/bin/sh
set -euf

# This file iterates video files in a given directory
# and checks them for errors - useful for example after downloading

root="."
if [ "${#}" -ge 1 ]; then
    root="${1}"
fi
logfile='errors.txt'
rm -f "${logfile}"

find "${root}" \( -iname '*.mp4' -or -iname '*.mkv' -or -iname '*.avi' -or -iname '*.ts' \) | while read -r file; do
    infoline="$(printf 'Checking %s...' "${file}")"
    printf '%s' "${infoline}" >&2

    printf '%s\n' "${file}" >>"${logfile}"
    file_status="$(true && (ffmpeg -v error -i "${file}" -f null - >>"${logfile}" 2>&1 && printf '%s' '-y-') || printf 'XXX')"
    printf '\n\n\n' >>"${logfile}"

    printf '\r%s' "${infoline}" | sed -E 's~.~ ~g' | tr -d '\n' >&2 # must wipe previous line before printing new line, otherwise old characters see through
    printf '\r%s \t%s\n' "${file_status}" "${file}" >&2
done
