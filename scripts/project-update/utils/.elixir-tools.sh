#!/bin/sh
set -euf

source_dir="${source_dir:?source_dir must be set before sourcing this file}"

is_elixir_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,2}(-otp-[0-9]+)?)$'
}

normalize_elixir_version() {
    version="${1}"

    case "${version}" in
    elixir-*)
        version="${version#elixir-}"
        ;;
    v*)
        version="${version#v}"
        ;;
    *) ;;
    esac

    if is_elixir_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

elixir_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

elixir_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "elixir") {
                print $2
                exit
            }
        }
    ' "${1}"
}

elixir_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.elixir\][[:space:]]*$/) {
                section = "elixir"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && key == "elixir") || (section == "elixir" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

elixir_version_from_mix_file() {
    awk '
        {
            line = $0
            sub(/#.*/, "", line)
            if (line ~ /^[[:space:]]*elixir[[:space:]]*:/ && match(line, /[0-9]+(\.[0-9]+){0,2}(-otp-[0-9]+)?/)) {
                print substr(line, RSTART, RLENGTH)
                exit
            }
        }
    ' "${1}"
}

resolve_elixir_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.elixir-version" ]; then
                version="$(elixir_version_from_version_file "${version_directory}/.elixir-version")"
                version="$(normalize_elixir_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(elixir_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_elixir_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(elixir_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_elixir_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/mix.exs" ]; then
                version="$(elixir_version_from_mix_file "${version_directory}/mix.exs")"
                version="$(normalize_elixir_version "${version}")"
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

update_elixir_dependencies() {
    mix_file="${1}"
    update_target="${2}"
    project_directory="$(cd "$(dirname "${mix_file}")" && pwd -P)"
    mix_lock_path="${project_directory}/mix.lock"
    elixir_version="$(resolve_elixir_version "${project_directory}")"

    printf '# Updating Elixir Mix project at %s\n' "${mix_file}" >&2
    printf '# Resolved Elixir version %s for %s\n' "${elixir_version}" "${mix_file}" >&2

    if [ ! -e "${mix_lock_path}" ]; then
        touch "${mix_lock_path}"
    fi

    # shellcheck disable=SC2016
    run_update_command docker run --rm \
        --mount "type=bind,src=${project_directory},dst=/input,readonly=false" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "elixir:${elixir_version}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            if [ ! -s "./mix.lock" ]; then
                rm -f "./mix.lock"
            fi

            mix local.hex --force
            mix local.rebar --force

            case "${UPDATE_TARGET}" in
            major | minor | patch)
                mix deps.update --all
                ;;
            lock)
                mix deps.get
                ;;
            esac

            if [ -f "./mix.lock" ]; then
                cat "./mix.lock" >"/input/mix.lock"
            fi
        '
}
