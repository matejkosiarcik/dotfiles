#!/bin/sh
set -euf

is_go_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,2})$'
}

normalize_go_version() {
    version="${1}"

    case "${version}" in
    go[0-9]*)
        version="${version#go}"
        ;;
    *) ;;
    esac

    if is_go_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

go_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

go_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "go" || $1 == "golang") {
                print $2
                exit
            }
        }
    ' "${1}"
}

go_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.(go|golang)\][[:space:]]*$/) {
                section = "go"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && (key == "go" || key == "golang")) || (section == "go" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

go_version_from_mod_file() {
    awk '
        {
            line = $0
            sub(/[[:space:]]*\/\/.*/, "", line)
            sub(/^[[:space:]]+/, "", line)
            fields_count = split(line, fields, /[[:space:]]+/)
            if (fields_count < 2) {
                next
            }
            if (fields[1] == "toolchain" && fields[2] != "default") {
                found_toolchain = 1
                print fields[2]
                exit
            }
            if (fields[1] == "go" && go_version == "") {
                go_version = fields[2]
            }
        }

        END {
            if (!found_toolchain && go_version != "") {
                print go_version
            }
        }
    ' "${1}"
}

go_workspace_directory() {
    directory="${1}"
    project_directory="${1}"

    while true; do
        if [ -f "${directory}/go.work" ]; then
            printf '%s\n' "${directory}"
            return
        fi

        parent_directory="$(dirname "${directory}")"
        if [ "${parent_directory}" = "${directory}" ]; then
            break
        fi
        directory="${parent_directory}"
    done

    printf '%s\n' "${project_directory}"
}

resolve_go_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            for version_file in '.go-version' '.golang-version'; do
                if [ -f "${version_directory}/${version_file}" ]; then
                    version="$(go_version_from_version_file "${version_directory}/${version_file}")"
                    version="$(normalize_go_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(go_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_go_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(go_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_go_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/go.work" ]; then
                version="$(go_version_from_mod_file "${version_directory}/go.work")"
                version="$(normalize_go_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/go.mod" ]; then
                version="$(go_version_from_mod_file "${version_directory}/go.mod")"
                version="$(normalize_go_version "${version}")"
                if [ -n "${version}" ]; then
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

update_go_modules() {
    go_mod_file="${1}"
    update_target="${2}"

    printf '\n\n# Updating Go module at %s\n' "${go_mod_file}" >&2

    go_directory="$(cd "$(dirname "${go_mod_file}")" && pwd -P)"
    workspace_directory="$(go_workspace_directory "${go_directory}")"
    go_sum_path="${go_directory}/go.sum"
    go_version="$(resolve_go_version "${go_directory}")"

    if [ "${workspace_directory}" = "${go_directory}" ]; then
        project_directory='.'
    else
        project_directory="${go_directory#"${workspace_directory}/"}"
    fi

    printf '# Resolved Go version %s for %s\n' "${go_version}" "${go_mod_file}" >&2

    if [ ! -e "${go_sum_path}" ]; then
        touch "${go_sum_path}"
    fi

    run_docker_update run --rm \
        --mount "type=bind,src=${workspace_directory},dst=/input,readonly=false" \
        --env "INPUT_PROJECT_DIRECTORY=/input/${project_directory}" \
        --env "PROJECT_DIRECTORY=/work/${project_directory}" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "golang:${go_version}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "${PROJECT_DIRECTORY}"

            case "${UPDATE_TARGET}" in
            major | minor)
                go get -u "./..."
                go mod tidy
                ;;
            patch)
                go get -u=patch "./..."
                go mod tidy
                ;;
            lock)
                ;;
            esac

            cat "./go.mod" >"${INPUT_PROJECT_DIRECTORY}/go.mod"
            cat "./go.sum" >"${INPUT_PROJECT_DIRECTORY}/go.sum"
            if [ -f "/work/go.work.sum" ]; then
                cat "/work/go.work.sum" >"/input/go.work.sum"
            fi
        '
}
