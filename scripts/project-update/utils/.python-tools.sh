#!/bin/sh
set -euf

is_python_version() {
    printf '%s\n' "${1}" | grep -qE '^[0-9]+(\.[0-9]+){0,2}$'
}

python_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[0-9]+(\.[0-9]+){0,2}$/{ p; q; }' <"${1}"
}

python_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "python" || $1 == "python3") {
                print $2
                exit
            }
        }
    ' "${1}"
}

python_version_from_mise_config() {
    awk -F '=' '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line ~ /^[[:space:]]*\[tools\][[:space:]]*$/) {
                section = "tools"
                next
            }
            if (line ~ /^[[:space:]]*\[tools\.(python|python3)\][[:space:]]*$/) {
                section = "python"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && (key == "python" || key == "python3")) || (section == "python" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

python_version_from_runtime_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;s~^python-([0-9]+(\.[0-9]+){0,2})$~\1~p' <"${1}"
}

python_version_from_pipfile() {
    awk -F '=' '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line ~ /^[[:space:]]*\[requires\][[:space:]]*$/) {
                in_requires = 1
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                in_requires = 0
                next
            }
            if (!in_requires) {
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if (key == "python_full_version") {
                full_version = value
            } else if (key == "python_version") {
                version = value
            }
        }

        END {
            if (full_version != "") {
                print full_version
            } else if (version != "") {
                print version
            }
        }
    ' "${1}"
}

python_version_from_pyproject() {
    awk '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line ~ /^[[:space:]]*\[project\][[:space:]]*$/) {
                in_project = 1
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                in_project = 0
                next
            }
            key = line
            sub(/[[:space:]]*=.*/, "", key)
            if (!in_project || trim(key) != "requires-python") {
                next
            }

            value = line
            sub(/^[^=]*=[[:space:]]*/, "", value)
            value = trim(value)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            sub(/^==/, "", value)
            print value
            exit
        }
    ' "${1}"
}

resolve_python_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            for version_file in '.python-version' '.python-versions'; do
                if [ -f "${version_directory}/${version_file}" ]; then
                    version="$(python_version_from_version_file "${version_directory}/${version_file}")"
                    if is_python_version "${version}"; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(python_version_from_mise_config "${version_directory}/${mise_file}")"
                    if is_python_version "${version}"; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(python_version_from_tool_versions "${version_directory}/.tool-versions")"
                if is_python_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/runtime.txt" ]; then
                version="$(python_version_from_runtime_file "${version_directory}/runtime.txt")"
                if is_python_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/Pipfile" ]; then
                version="$(python_version_from_pipfile "${version_directory}/Pipfile")"
                if is_python_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/pyproject.toml" ]; then
                version="$(python_version_from_pyproject "${version_directory}/pyproject.toml")"
                if is_python_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        parent_directory="$(dirname "${directory}")"
        if [ "${parent_directory}" = "${directory}" ]; then
            break
        fi
        directory="${parent_directory}"
    done

    printf '%s\n' 'latest'
}

update_python_requirements() {
    requirements_file="${1}"
    update_target="${2}"

    printf '# Updating pip requirements file at %s\n' "${requirements_file}" >&2

    requirements_directory="$(cd "$(dirname "${requirements_file}")" && pwd -P)"
    requirements_path="${requirements_directory}/$(basename "${requirements_file}")"
    python_version="$(resolve_python_version "${requirements_directory}")"

    case "${requirements_file}" in
    *.in)
        requirements_docker_filename='requirements.in'
        lockfile="${requirements_file%.in}.txt"
        ;;
    *.txt)
        requirements_docker_filename='requirements.txt'
        lockfile=''
        ;;
    *)
        printf 'Unsupported Python requirements file %s\n' "${requirements_file}" >&2
        return 1
        ;;
    esac

    printf '# Resolved Python version %s for %s\n' "${python_version}" "${requirements_file}" >&2

    if [ "${update_target}" != 'lock' ]; then
        # shellcheck disable=SC2016
        run_update_command docker run --rm \
            --mount "type=bind,src=${requirements_path},dst=/input/${requirements_docker_filename},readonly=false" \
            --mount "type=bind,src=${source_dir}/container-dependencies/pur,dst=/deps/pur,readonly" \
            --env "REQUIREMENTS_FILE=${requirements_docker_filename}" \
            --env "UPDATE_TARGET=${update_target}" \
            --entrypoint '/bin/sh' \
            "python:${python_version}" \
            -c '
                set -euf
                python3 -m venv "/venv"
                . "/venv/bin/activate"
                python -m pip install --quiet --disable-pip-version-check --require-hashes --requirement "/deps/pur/requirements.txt"

                mkdir "/work"
                cp "/input/${REQUIREMENTS_FILE}" "/work/${REQUIREMENTS_FILE}"
                cd "/work"

                case "${UPDATE_TARGET}" in
                major)
                    pur --force --requirement "${REQUIREMENTS_FILE}"
                    ;;
                minor | patch)
                    pur --force "--${UPDATE_TARGET}" "*" --requirement "${REQUIREMENTS_FILE}"
                    ;;
                esac

                cat "${REQUIREMENTS_FILE}" >"/input/${REQUIREMENTS_FILE}"
            '
    fi

    if [ -n "${lockfile}" ]; then
        if [ ! -e "${lockfile}" ]; then
            touch "${lockfile}"
        fi

        lockfile_path="${requirements_directory}/$(basename "${lockfile}")"

        # shellcheck disable=SC2016
        run_update_command docker run --rm \
            --mount "type=bind,src=${requirements_path},dst=/input/requirements.in,readonly=false" \
            --mount "type=bind,src=${lockfile_path},dst=/input/requirements.txt,readonly=false" \
            --mount "type=bind,src=${source_dir}/container-dependencies/pip-tools,dst=/deps/pip-tools,readonly" \
            --entrypoint '/bin/sh' \
            "python:${python_version}" \
            -c '
                set -euf
                python -m venv "/venv"
                . "/venv/bin/activate"
                python -m pip install --quiet --disable-pip-version-check --require-hashes --requirement "/deps/pip-tools/requirements.txt"

                mkdir -p "/work"
                cp "/input/requirements.in" "/input/requirements.txt" "/work/"
                cd "/work"

                pip-compile --generate-hashes --strip-extras --allow-unsafe --output-file="./requirements.txt" "./requirements.in"

                cat "./requirements.txt" >"/input/requirements.txt"
            '
    fi
}

update_python_pipfile() {
    pipfile="${1}"
    update_target="${2}"
    pipfile_directory="$(cd "$(dirname "${pipfile}")" && pwd -P)"
    pipfile_lock_path="${pipfile_directory}/Pipfile.lock"
    python_version="$(resolve_python_version "${pipfile_directory}")"

    printf '# Updating Pipfile at %s\n' "${pipfile}" >&2
    printf '# Resolved Python version %s for %s\n' "${python_version}" "${pipfile}" >&2

    if [ ! -e "${pipfile_lock_path}" ]; then
        touch "${pipfile_lock_path}"
    fi

    # shellcheck disable=SC2016
    run_update_command docker run --rm \
        --mount "type=bind,src=${pipfile_directory},dst=/input,readonly=false" \
        --mount "type=bind,src=${source_dir}/container-dependencies/pipenv,dst=/deps/pipenv,readonly" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "python:${python_version}" \
        -c '
            set -euf
            python -m venv "/venv"
            . "/venv/bin/activate"
            python -m pip install --quiet --disable-pip-version-check --require-hashes --requirement "/deps/pipenv/requirements.txt"

            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            export PIPENV_NOSPIN=1
            export PIPENV_VENV_IN_PROJECT=1
            export PIPENV_YES=1

            case "${UPDATE_TARGET}" in
            major | minor | patch)
                pipenv update --all
                ;;
            lock)
                pipenv lock
                ;;
            esac

            cat "./Pipfile" >"/input/Pipfile"
            cat "./Pipfile.lock" >"/input/Pipfile.lock"
        '
}
