#!/bin/sh
set -euf

source_dir="${source_dir:?source_dir must be set before sourcing this file}"

update_gitman_dependencies() {
    gitman_file="${1}"
    update_target="${2}"
    gitman_directory="$(cd "$(dirname "${gitman_file}")" && pwd -P)"
    gitman_filename="$(basename "${gitman_file}")"
    python_version="$(resolve_python_version "${gitman_directory}")"

    printf '# Updating gitman file at %s\n' "${gitman_file}" >&2
    printf '# Resolved Python version %s for %s\n' "${python_version}" "${gitman_file}" >&2

    # shellcheck disable=SC2016
    run_update_command docker run --rm \
        --mount "type=bind,src=${gitman_directory},dst=/input,readonly=false" \
        --mount "type=bind,src=${source_dir}/container-dependencies/gitman,dst=/deps/gitman,readonly" \
        --env "GITMAN_FILE=${gitman_filename}" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "python:${python_version}" \
        -c '
            set -euf
            python -m venv "/venv"
            . "/venv/bin/activate"
            python -m pip install --quiet --disable-pip-version-check --require-hashes --requirement "/deps/gitman/requirements.txt"

            mkdir "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            if [ "${UPDATE_TARGET}" = "major" ] || [ "${UPDATE_TARGET}" = "minor" ] || [ "${UPDATE_TARGET}" = "patch" ]; then
                gitman update --force
            elif [ "${UPDATE_TARGET}" = "lock" ]; then
                gitman install --force --fetch
            fi
            gitman lock

            cat "${GITMAN_FILE}" >"/input/${GITMAN_FILE}"
        '
}
