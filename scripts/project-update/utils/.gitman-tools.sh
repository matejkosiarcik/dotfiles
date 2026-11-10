#!/bin/sh
set -euf

update_gitman_dependencies() {
    gitman_file="${1}"
    update_target="${2}"

    (
        cd "$(dirname "${gitman_file}")"
        if [ "${update_target}" = 'major' ] || [ "${update_target}" = 'minor' ] || [ "${update_target}" = 'patch' ]; then
            gitman update --force # main
        elif [ "${update_target}" = 'lock' ]; then
            gitman install --force --fetch # no-file
        fi
        gitman lock # lock
    )
}
