#!/bin/sh
set -euf

is_haskell_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,2})$'
}

normalize_haskell_version() {
    version="${1}"

    case "${version}" in
    ghc-*)
        version="${version#ghc-}"
        ;;
    ghc[0-9]*)
        version="${version#ghc}"
        ;;
    *) ;;
    esac

    if is_haskell_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

haskell_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

haskell_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "ghc" || $1 == "haskell") {
                print $2
                exit
            }
        }
    ' "${1}"
}

haskell_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.(ghc|haskell)\][[:space:]]*$/) {
                section = "haskell"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && (key == "ghc" || key == "haskell")) || (section == "haskell" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

haskell_version_from_cabal_project() {
    sed -n -E '/^[[:space:]]*with-compiler:[[:space:]]*/ { s~.*ghc-([0-9]+(\.[0-9]+){0,2}).*~\1~p; q; }' <"${1}"
}

haskell_version_from_cabal_file() {
    sed -n -E '/^[[:space:]]*tested-with:[[:space:]]*/ { s~.*GHC[[:space:]]*==[[:space:]]*([0-9]+(\.[0-9]+){0,2}).*~\1~p; q; }' <"${1}"
}

haskell_version_from_stack_file() {
    sed -n -E '/^[[:space:]]*(compiler|resolver|snapshot):[[:space:]]*ghc-[0-9]+(\.[0-9]+){0,2}([[:space:]]|$)/ { s~.*ghc-([0-9]+(\.[0-9]+){0,2}).*~\1~p; q; }' <"${1}"
}

haskell_workspace_directory() {
    directory="${1}"
    package_directory="${1}"

    while true; do
        if [ -f "${directory}/cabal.project" ]; then
            printf '%s\n' "${directory}"
            return
        fi

        parent_directory="$(dirname "${directory}")"
        if [ "${parent_directory}" = "${directory}" ]; then
            break
        fi
        directory="${parent_directory}"
    done

    printf '%s\n' "${package_directory}"
}

haskell_stack_workspace_directory() {
    directory="${1}"

    while true; do
        if [ -f "${directory}/stack.yaml" ]; then
            printf '%s\n' "${directory}"
            return
        fi

        parent_directory="$(dirname "${directory}")"
        if [ "${parent_directory}" = "${directory}" ]; then
            break
        fi
        directory="${parent_directory}"
    done

    return 1
}

is_haskell_stack_project() {
    package_file="${1}"
    package_directory="$(cd "$(dirname "${package_file}")" && pwd -P)"

    haskell_stack_workspace_directory "${package_directory}" >/dev/null
}

resolve_haskell_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            for version_file in '.ghc-version' '.haskell-version'; do
                if [ -f "${version_directory}/${version_file}" ]; then
                    version="$(haskell_version_from_version_file "${version_directory}/${version_file}")"
                    version="$(normalize_haskell_version "${version}")"
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
                    version="$(haskell_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_haskell_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(haskell_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_haskell_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/stack.yaml" ]; then
                version="$(haskell_version_from_stack_file "${version_directory}/stack.yaml")"
                version="$(normalize_haskell_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/cabal.project" ]; then
                version="$(haskell_version_from_cabal_project "${version_directory}/cabal.project")"
                version="$(normalize_haskell_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for cabal_file in "${version_directory}"/*.cabal; do
                if [ ! -f "${cabal_file}" ]; then
                    continue
                fi
                version="$(haskell_version_from_cabal_file "${cabal_file}")"
                version="$(normalize_haskell_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
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

update_haskell_cabal_dependencies() {
    cabal_file="${1}"
    update_target="${2}"
    package_directory="$(cd "$(dirname "${cabal_file}")" && pwd -P)"
    workspace_directory="$(haskell_workspace_directory "${package_directory}")"
    freeze_file_path="${workspace_directory}/cabal.project.freeze"
    haskell_version="$(resolve_haskell_version "${package_directory}")"

    printf '# Updating Haskell Cabal package at %s\n' "${cabal_file}" >&2
    printf '# Resolved Haskell version %s for %s\n' "${haskell_version}" "${cabal_file}" >&2

    if [ ! -e "${freeze_file_path}" ]; then
        touch "${freeze_file_path}"
    fi

    # shellcheck disable=SC2016
    run_update_command docker run --rm \
        --mount "type=bind,src=${workspace_directory},dst=/input,readonly=false" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "haskell:${haskell_version}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            case "${UPDATE_TARGET}" in
            major | minor | patch)
                cabal update
                ;;
            lock)
                ;;
            esac

            cabal freeze

            cat "./cabal.project.freeze" >"/input/cabal.project.freeze"
        '
}

update_haskell_stack_dependencies() {
    stack_file="${1}"
    update_target="${2}"
    stack_directory="$(cd "$(dirname "${stack_file}")" && pwd -P)"
    stack_lock_path="${stack_directory}/stack.yaml.lock"
    haskell_version="$(resolve_haskell_version "${stack_directory}")"

    printf '# Updating Haskell Stack project at %s\n' "${stack_file}" >&2
    printf '# Resolved Haskell version %s for %s\n' "${haskell_version}" "${stack_file}" >&2

    if [ ! -e "${stack_lock_path}" ]; then
        touch "${stack_lock_path}"
    fi

    # shellcheck disable=SC2016
    run_update_command docker run --rm \
        --mount "type=bind,src=${stack_directory},dst=/input,readonly=false" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "haskell:${haskell_version}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            case "${UPDATE_TARGET}" in
            major | minor | patch)
                stack update
                ;;
            lock)
                ;;
            esac

            stack config build-files

            cat "./stack.yaml.lock" >"/input/stack.yaml.lock"
        '
}
