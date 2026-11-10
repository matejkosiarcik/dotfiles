#!/bin/sh
set -euf

update_gitman_dependencies() {
    gitman_file="${1}"
    update_target="${2}"

    printf '# Updating gitman file at %s\n' "${gitman_file}" >&2

    (
        cd "$(dirname "${gitman_file}")"
        if [ "${update_target}" = 'major' ] || [ "${update_target}" = 'minor' ] || [ "${update_target}" = 'patch' ]; then
            run_update_command gitman update --force # main
        elif [ "${update_target}" = 'lock' ]; then
            run_update_command gitman install --force --fetch # no-file
        fi
        run_update_command gitman lock # lock
    )
}
