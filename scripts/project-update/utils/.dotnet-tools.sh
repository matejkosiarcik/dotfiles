#!/bin/sh
set -euf

is_dotnet_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,3})$'
}

dotnet_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[0-9]+(\.[0-9]+){0,3}$/{ p; q; }' <"${1}"
}

dotnet_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "dotnet" || $1 == "dotnet-core") {
                print $2
                exit
            }
        }
    ' "${1}"
}

dotnet_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.(dotnet|dotnet-core)\][[:space:]]*$/) {
                section = "dotnet"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && (key == "dotnet" || key == "dotnet-core")) || (section == "dotnet" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

dotnet_version_from_global_json() {
    awk '
        /"sdk"[[:space:]]*:/ {
            in_sdk = 1
        }
        in_sdk && /"version"[[:space:]]*:/ {
            value = $0
            sub(/^.*"version"[[:space:]]*:[[:space:]]*"/, "", value)
            sub(/".*$/, "", value)
            print value
            exit
        }
    ' "${1}"
}

resolve_dotnet_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.dotnet-version" ]; then
                version="$(dotnet_version_from_version_file "${version_directory}/.dotnet-version")"
                if is_dotnet_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(dotnet_version_from_mise_config "${version_directory}/${mise_file}")"
                    if is_dotnet_version "${version}"; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(dotnet_version_from_tool_versions "${version_directory}/.tool-versions")"
                if is_dotnet_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/global.json" ]; then
                version="$(dotnet_version_from_global_json "${version_directory}/global.json")"
                if is_dotnet_version "${version}"; then
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

dotnet_workspace_directory() {
    project_directory="${1}"

    if git -C "${project_directory}" rev-parse --show-toplevel >/dev/null 2>&1; then
        git -C "${project_directory}" rev-parse --show-toplevel
    else
        printf '%s\n' "${project_directory}"
    fi
}

update_dotnet_project() {
    project_file="${1}"
    update_target="${2}"
    project_directory="$(cd "$(dirname "${project_file}")" && pwd -P)"
    project_file_path="${project_directory}/$(basename "${project_file}")"
    workspace_directory="$(dotnet_workspace_directory "${project_directory}")"
    dotnet_version="$(resolve_dotnet_version "${project_directory}")"

    if [ "${workspace_directory}" = "${project_directory}" ]; then
        project_path="$(basename "${project_file}")"
    else
        project_path="${project_file_path#"${workspace_directory}/"}"
    fi

    printf '# Resolved .NET SDK version %s for %s\n' "${dotnet_version}" "${project_file}" >&2

    if [ "${update_target}" != 'major' ]; then
        return
    fi

    docker run --rm \
        --mount "type=bind,src=${workspace_directory},dst=/input,readonly=false" \
        --env "PROJECT_PATH=${project_path}" \
        --entrypoint '/bin/sh' \
        "mcr.microsoft.com/dotnet/sdk:${dotnet_version}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            if dotnet package update --project "${PROJECT_PATH}"; then
                true
            else
                exit_code="${?}"
                if [ "${exit_code}" -ne 2 ]; then
                    exit "${exit_code}"
                fi
            fi

            cat "${PROJECT_PATH}" >"/input/${PROJECT_PATH}"
            find "/work" -type f \( -name "Directory.Packages.props" -o -name "packages.lock.json" \) -print | while IFS= read -r updated_file; do
                relative_path="${updated_file#/work/}"
                cat "${updated_file}" >"/input/${relative_path}"
            done
        '
}
