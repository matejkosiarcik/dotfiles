#!/bin/sh
set -euf

run_docker_update() (
    docker_update_log="$(mktemp)"
    trap 'rm -f "${docker_update_log}"' 0 HUP INT TERM

    if docker "${@}" >"${docker_update_log}" 2>&1; then
        return
    else
        docker_update_status="${?}"
    fi

    printf 'Docker update failed; captured output follows:\n' >&2
    cat "${docker_update_log}" >&2
    exit "${docker_update_status}"
)
