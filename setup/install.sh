#!/bin/sh
set -euf
cd "$(dirname "${0}")"

case "$(uname -s)" in
'Darwin') sh 'macOS.sh' ;;
esac

# TODO: make it compatible with linux/windows
make_default_program() {
    while IFS="" read -r line; do
        filetype="$(printf '%s' "${line}" | sed -E 's~#.+~~;s~ ~~g')"
        if [ "${filetype}" = '' ]; then
            continue;
        fi
        if [ "$(uname -s)" = 'Darwin' ]; then
            duti -s "${1}" "${filetype}" all
            associated_app="$(duti -x "${filetype}")"
            if ! printf '%s' "${associated_app}" | grep "${1}" >/dev/null; then
                printf 'Filetype %s could not be changed from %s\n' "${filetype}" "$(printf '%s' "${associated_app}" | tr '\n' ' ')"
            fi
        fi
    done <"${2}"
}

make_default_program 'com.microsoft.VSCode' 'textfiles.txt'
make_default_program 'org.videolan.vlc' 'mediafiles.txt'
