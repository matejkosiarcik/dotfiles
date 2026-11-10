#!/bin/sh
set -euf

is_rust_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|stable|beta|nightly|[0-9]+(\.[0-9]+){0,2})$'
}

rust_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

rust_version_from_toolchain_file() {
    awk -F '=' '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            line = trim(line)
            if (line ~ /^channel[[:space:]]*=/) {
                value = trim($2)
                gsub(/^[\"\047]|[\"\047]$/, "", value)
                found_channel = 1
                print value
                exit
            }
            if (fallback == "" && line !~ /^\[/ && line !~ /=/) {
                fallback = line
            }
        }

        END {
            if (!found_channel && fallback != "") {
                print fallback
            }
        }
    ' "${1}"
}

rust_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "rust") {
                print $2
                exit
            }
        }
    ' "${1}"
}

rust_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.rust\][[:space:]]*$/) {
                section = "rust"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && key == "rust") || (section == "rust" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

rust_version_from_cargo_toml() {
    awk -F '=' '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line ~ /^[[:space:]]*\[package\][[:space:]]*$/) {
                in_package = 1
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                in_package = 0
                next
            }
            if (in_package && trim($1) == "rust-version") {
                value = trim($2)
                gsub(/^[\"\047]|[\"\047]$/, "", value)
                print value
                exit
            }
        }
    ' "${1}"
}

rust_workspace_directory() {
    directory="${1}"
    project_directory="${1}"

    while true; do
        if [ -f "${directory}/Cargo.toml" ] && grep -qE '^[[:space:]]*\[workspace\][[:space:]]*$' "${directory}/Cargo.toml"; then
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

resolve_rust_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.rust-version" ]; then
                version="$(rust_version_from_version_file "${version_directory}/.rust-version")"
                if is_rust_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for toolchain_file in 'rust-toolchain.toml' 'rust-toolchain'; do
                if [ -f "${version_directory}/${toolchain_file}" ]; then
                    version="$(rust_version_from_toolchain_file "${version_directory}/${toolchain_file}")"
                    if is_rust_version "${version}"; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(rust_version_from_mise_config "${version_directory}/${mise_file}")"
                    if is_rust_version "${version}"; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(rust_version_from_tool_versions "${version_directory}/.tool-versions")"
                if is_rust_version "${version}"; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/Cargo.toml" ]; then
                version="$(rust_version_from_cargo_toml "${version_directory}/Cargo.toml")"
                if is_rust_version "${version}"; then
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

update_rust_dependencies() {
    cargo_file="${1}"
    update_target="${2}"

    printf '\n\n# Updating cargo file at %s\n' "${cargo_file}" >&2

    project_directory="$(cd "$(dirname "${cargo_file}")" && pwd -P)"
    workspace_directory="$(rust_workspace_directory "${project_directory}")"
    cargo_lock_path="${workspace_directory}/Cargo.lock"
    rust_version="$(resolve_rust_version "${project_directory}")"

    if [ "${workspace_directory}" = "${project_directory}" ]; then
        project_path='.'
    else
        project_path="${project_directory#"${workspace_directory}/"}"
    fi

    printf '# Resolved Rust version %s for %s\n' "${rust_version}" "${cargo_file}" >&2

    if [ ! -e "${cargo_lock_path}" ]; then
        touch "${cargo_lock_path}"
    fi

    docker run --rm \
        --mount "type=bind,src=${workspace_directory},dst=/input,readonly=false" \
        --env "PROJECT_DIRECTORY=/work/${project_path}" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "rust:${rust_version}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "${PROJECT_DIRECTORY}"

            case "${UPDATE_TARGET}" in
            major)
                cargo install cargo-edit --locked
                cargo upgrade --incompatible
                ;;
            minor)
                cargo install cargo-edit --locked
                cargo upgrade
                ;;
            patch | lock)
                ;;
            esac

            cargo update

            find "/work" -type f \( -name "Cargo.toml" -o -name "Cargo.lock" \) -print | while IFS= read -r updated_file; do
                relative_path="${updated_file#/work/}"
                cat "${updated_file}" >"/input/${relative_path}"
            done
        '
}
