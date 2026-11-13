#!/bin/sh
set -euf

script_path="${0}"
case "${script_path}" in
*/*) ;;
*)
    if [ -f "${script_path}" ]; then
        script_path="$(pwd)/${script_path}"
    else
        script_path="$(command -v "${script_path}")"
    fi
    ;;
esac
while [ -L "${script_path}" ]; do
    script_directory="$(cd -P "$(dirname "${script_path}")" && pwd)"
    script_path="$(readlink "${script_path}")"
    case "${script_path}" in
    /*) ;;
    *) script_path="${script_directory}/${script_path}" ;;
    esac
done
source_dir="$(cd -P "$(dirname "${script_path}")" && pwd)"
export source_dir

PATH="/opt/homebrew/bin:${PATH}"
export PATH

# Prepare target directory
watchdir="${HOME}/Pictures/Screenshots"
if [ ! -d "${watchdir}" ]; then
    mkdir -p "${watchdir}"
fi

# Rename existing files
tmpfile="$(mktemp)"
find "${watchdir}" -maxdepth 1 -type f -iname '*.png' -print0 >"${tmpfile}"
# shellcheck disable=SC2016
xargs -0 -n1 sh -c 'sh "${source_dir}/rename.sh" "${1}" || true' - <"${tmpfile}"
rm -f "${tmpfile}"

# Watch for new files
# shellcheck disable=SC2016
fswatch "${watchdir}" --event=Created --event=MovedTo --event=Renamed -E --exclude '(^|/)\..+$' --exclude '(^|/)[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}( [0-9]+)?\.png$' --print0 |
    xargs -0 -n1 sh -c 'if [ -f "${2}" ]; then sh "${1}/rename.sh" "${2}" || true; fi' - "${source_dir}"
