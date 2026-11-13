#!/bin/sh
set -euf

run_update_command() (
    update_command_name="${1}"
    if [ "${#}" -gt 1 ]; then
        update_command_name="${update_command_name} ${2}"
    fi
    update_command_logfile="$(mktemp)"
    trap 'rm -f "${update_command_logfile}"' 0 HUP INT TERM

    if "${@}" >"${update_command_logfile}" 2>&1; then
        return
    else
        update_command_status="${?}"
    fi

    printf 'Command "%s" failed, captured output follows:\n' "${update_command_name}" >&2
    cat "${update_command_logfile}" >&2
    exit "${update_command_status}"
)
