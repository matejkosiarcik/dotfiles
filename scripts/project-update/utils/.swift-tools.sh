#!/bin/sh
set -euf

is_swift_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,2})$'
}

swift_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[0-9]+(\.[0-9]+){0,2}$/{ p; q; }' <"${1}"
}

swift_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "swift") {
                print $2
                exit
            }
        }
    ' "${1}"
}

swift_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.swift\][[:space:]]*$/) {
                section = "swift"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && key == "swift") || (section == "swift" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

swift_version_from_package_file() {
    sed -n -E 's~^[[:space:]]*//[[:space:]]*swift-tools-version:([0-9]+(\.[0-9]+){0,2}).*$~\1~p' <"${1}"
}

resolve_swift_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.swift-version" ]; then
                version="$(swift_version_from_version_file "${version_directory}/.swift-version")"
                if is_swift_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(swift_version_from_mise_config "${version_directory}/${mise_file}")"
                    if is_swift_version "${version}"; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(swift_version_from_tool_versions "${version_directory}/.tool-versions")"
                if is_swift_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/Package.swift" ]; then
                version="$(swift_version_from_package_file "${version_directory}/Package.swift")"
                if is_swift_version "${version}"; then
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

update_swift_dependencies() {
    package_file="${1}"
    update_target="${2}"

    printf '\n\n# Updating Swift package file at %s\n' "${package_file}" >&2

    package_directory="$(cd "$(dirname "${package_file}")" && pwd -P)"
    package_resolved_path="${package_directory}/Package.resolved"
    swift_version="$(resolve_swift_version "${package_directory}")"

    printf '# Resolved Swift version %s for %s\n' "${swift_version}" "${package_file}" >&2

    if [ ! -e "${package_resolved_path}" ]; then
        touch "${package_resolved_path}"
    fi

    docker run --rm \
        --mount "type=bind,src=${package_directory},dst=/input,readonly=false" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "swift:${swift_version}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            case "${UPDATE_TARGET}" in
            major | minor | patch)
                swift package update
                ;;
            lock)
                ;;
            esac

            swift package resolve

            cat "./Package.resolved" >"/input/Package.resolved"
            if [ -f ".swiftpm/configuration/Package.resolved" ]; then
                mkdir -p "/input/.swiftpm/configuration"
                cat ".swiftpm/configuration/Package.resolved" >"/input/.swiftpm/configuration/Package.resolved"
            fi
        '
}
