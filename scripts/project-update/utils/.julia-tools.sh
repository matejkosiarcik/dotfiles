#!/bin/sh
set -euf

is_julia_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,2})$'
}

normalize_julia_version() {
    version="${1}"

    case "${version}" in
    julia-*)
        version="${version#julia-}"
        ;;
    v*)
        version="${version#v}"
        ;;
    *) ;;
    esac

    if is_julia_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

julia_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

julia_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "julia") {
                print $2
                exit
            }
        }
    ' "${1}"
}

julia_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.julia\][[:space:]]*$/) {
                section = "julia"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && key == "julia") || (section == "julia" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

julia_version_from_project_file() {
    awk -F '=' '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line ~ /^[[:space:]]*\[compat\][[:space:]]*$/) {
                in_compat = 1
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                in_compat = 0
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if (in_compat && key == "julia" && value ~ /^[0-9]+(\.[0-9]+){0,2}$/) {
                print value
                exit
            }
        }
    ' "${1}"
}

julia_manifest_file() {
    project_directory="${1}"
    project_file="${2}"
    julia_version="${3}"

    case "$(basename "${project_file}")" in
    JuliaProject.toml)
        manifest_file='JuliaManifest.toml'
        manifest_prefix='JuliaManifest'
        ;;
    *)
        manifest_file='Manifest.toml'
        manifest_prefix='Manifest'
        ;;
    esac

    manifest_version="$(printf '%s\n' "${julia_version}" | sed -n -E 's~^([0-9]+\.[0-9]+).*~\1~p')"
    if [ -n "${manifest_version}" ]; then
        versioned_manifest_file="${manifest_prefix}-v${manifest_version}.toml"
        if [ -e "${project_directory}/${versioned_manifest_file}" ]; then
            printf '%s\n' "${versioned_manifest_file}"
            return
        fi
    fi

    printf '%s\n' "${manifest_file}"
}

resolve_julia_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.julia-version" ]; then
                version="$(julia_version_from_version_file "${version_directory}/.julia-version")"
                version="$(normalize_julia_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(julia_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_julia_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(julia_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_julia_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for project_file in 'Project.toml' 'JuliaProject.toml'; do
                if [ -f "${version_directory}/${project_file}" ]; then
                    version="$(julia_version_from_project_file "${version_directory}/${project_file}")"
                    version="$(normalize_julia_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        parent_directory="$(dirname "${directory}")"
        if [ "${parent_directory}" = "${directory}" ]; then
            break
        fi
        directory="${parent_directory}"
    done

    printf '%s\n' 'latest'
}

update_julia_dependencies() {
    project_file="${1}"
    update_target="${2}"
    project_directory="$(cd "$(dirname "${project_file}")" && pwd -P)"
    julia_version="$(resolve_julia_version "${project_directory}")"
    manifest_file="$(julia_manifest_file "${project_directory}" "${project_file}" "${julia_version}")"
    manifest_path="${project_directory}/${manifest_file}"

    printf '# Updating Julia project file at %s\n' "${project_file}" >&2
    printf '# Resolved Julia version %s for %s\n' "${julia_version}" "${project_file}" >&2

    if [ ! -e "${manifest_path}" ]; then
        touch "${manifest_path}"
    fi

    # shellcheck disable=SC2016
    run_update_command docker run --rm \
        --mount "type=bind,src=${project_directory},dst=/input,readonly=false" \
        --env "MANIFEST_FILE=${manifest_file}" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "julia:${julia_version}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            if [ ! -s "./${MANIFEST_FILE}" ]; then
                rm -f "./${MANIFEST_FILE}"
            fi

            case "${UPDATE_TARGET}" in
            major)
                julia --project="/work" -e "using Pkg; Pkg.update(; level=Pkg.UPLEVEL_MAJOR)"
                ;;
            minor)
                julia --project="/work" -e "using Pkg; Pkg.update(; level=Pkg.UPLEVEL_MINOR)"
                ;;
            patch)
                julia --project="/work" -e "using Pkg; Pkg.update(; level=Pkg.UPLEVEL_PATCH)"
                ;;
            lock)
                julia --project="/work" -e "using Pkg; Pkg.resolve()"
                ;;
            esac

            if [ -f "./${MANIFEST_FILE}" ]; then
                cat "./${MANIFEST_FILE}" >"/input/${MANIFEST_FILE}"
            fi
        '
}
