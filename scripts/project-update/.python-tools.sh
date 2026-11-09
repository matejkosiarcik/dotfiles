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
        for version_file in '.python-version' '.python-versions'; do
            if [ -f "${directory}/${version_file}" ]; then
                version="$(python_version_from_version_file "${directory}/${version_file}")"
                if is_python_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
            if [ -f "${directory}/${mise_file}" ]; then
                version="$(python_version_from_mise_config "${directory}/${mise_file}")"
                if is_python_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        if [ -f "${directory}/.tool-versions" ]; then
            version="$(python_version_from_tool_versions "${directory}/.tool-versions")"
            if is_python_version "${version}"; then
                printf '%s\n' "${version}"
                return
            fi
        fi

        if [ -f "${directory}/runtime.txt" ]; then
            version="$(python_version_from_runtime_file "${directory}/runtime.txt")"
            if is_python_version "${version}"; then
                printf '%s\n' "${version}"
                return
            fi
        fi

        if [ -f "${directory}/Pipfile" ]; then
            version="$(python_version_from_pipfile "${directory}/Pipfile")"
            if is_python_version "${version}"; then
                printf '%s\n' "${version}"
                return
            fi
        fi

        if [ -f "${directory}/pyproject.toml" ]; then
            version="$(python_version_from_pyproject "${directory}/pyproject.toml")"
            if is_python_version "${version}"; then
                printf '%s\n' "${version}"
                return
            fi
        fi

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
        docker run --rm \
            --mount "type=bind,src=${requirements_path},dst=/input/${requirements_docker_filename},readonly=false" \
            --env "REQUIREMENTS_FILE=${requirements_docker_filename}" \
            --env "UPDATE_TARGET=${update_target}" \
            --entrypoint '/bin/sh' \
            "python:${python_version}" \
            -c '
                set -euf
                python3 -m venv /venv
                /venv/bin/python -m pip install --disable-pip-version-check --quiet --upgrade pur

                mkdir /work
                cp "/input/${REQUIREMENTS_FILE}" "/work/${REQUIREMENTS_FILE}"
                cd /work

                case "${UPDATE_TARGET}" in
                major)
                    /venv/bin/pur --force --requirement "${REQUIREMENTS_FILE}"
                    ;;
                minor | patch)
                    /venv/bin/pur --force "--${UPDATE_TARGET}" "*" --requirement "${REQUIREMENTS_FILE}"
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

        docker run --rm \
            --mount "type=bind,src=${requirements_path},dst=/input/requirements.in,readonly=false" \
            --mount "type=bind,src=${lockfile_path},dst=/input/requirements.txt,readonly=false" \
            --entrypoint '/bin/sh' \
            "python:${python_version}" \
            -c '
                set -euf
                python3 -m venv /venv
                /venv/bin/python -m pip install --disable-pip-version-check --quiet --upgrade pip-tools

                mkdir -p /work
                cp "/input/requirements.in" "/input/requirements.txt" "/work/"
                cd /work

                /venv/bin/pip-compile --generate-hashes --strip-extras --output-file="./requirements.txt" "./requirements.in"

                cat "./requirements.txt" >"/input/requirements.txt"
            '
    fi
}
