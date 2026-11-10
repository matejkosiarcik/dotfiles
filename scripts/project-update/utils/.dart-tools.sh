#!/bin/sh
set -euf

is_dart_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,2})$'
}

normalize_dart_version() {
    version="${1}"

    case "${version}" in
    dart-*)
        version="${version#dart-}"
        ;;
    v*)
        version="${version#v}"
        ;;
    *) ;;
    esac

    if is_dart_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

is_flutter_version() {
    printf '%s\n' "${1}" | grep -qE '^(stable|beta|dev|master|latest|[0-9]+(\.[0-9]+){0,2})$'
}

normalize_flutter_version() {
    version="${1}"

    case "${version}" in
    flutter-*)
        version="${version#flutter-}"
        ;;
    v*)
        version="${version#v}"
        ;;
    *) ;;
    esac

    if is_flutter_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

dart_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

dart_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "dart") {
                print $2
                exit
            }
        }
    ' "${1}"
}

flutter_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "flutter") {
                print $2
                exit
            }
        }
    ' "${1}"
}

dart_version_from_mise_config() {
    dart_tool="${2}"
    awk -F '=' -v dart_tool="${dart_tool}" '
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
            if (line ~ "^[[:space:]]*\\[tools\\." dart_tool "\\][[:space:]]*$") {
                section = dart_tool
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && key == dart_tool) || (section == dart_tool && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

flutter_version_from_fvm_config() {
    awk '
        /"flutter"[[:space:]]*:|"flutterSdkVersion"[[:space:]]*:/ {
            value = $0
            sub(/^[^:]*:[[:space:]]*"/, "", value)
            sub(/".*$/, "", value)
            print value
            exit
        }
    ' "${1}"
}

dart_version_from_pubspec() {
    awk -F ':' '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line ~ /^[[:space:]]*environment:[[:space:]]*$/) {
                in_environment = 1
                next
            }
            if (line ~ /^[^[:space:]]/) {
                in_environment = 0
            }
            if (in_environment && trim($1) == "sdk") {
                value = trim($2)
                gsub(/^[\"\047]|[\"\047]$/, "", value)
                if (value ~ /^[0-9]+(\.[0-9]+){0,2}$/) {
                    print value
                    exit
                }
            }
        }
    ' "${1}"
}

flutter_version_from_pubspec() {
    awk -F ':' '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line ~ /^[[:space:]]*environment:[[:space:]]*$/) {
                in_environment = 1
                next
            }
            if (line ~ /^[^[:space:]]/) {
                in_environment = 0
            }
            if (in_environment && trim($1) == "flutter") {
                value = trim($2)
                gsub(/^[\"\047]|[\"\047]$/, "", value)
                if (value ~ /^[0-9]+(\.[0-9]+){0,2}$/) {
                    print value
                    exit
                }
            }
        }
    ' "${1}"
}

is_flutter_project() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.flutter-version" ] || [ -f "${version_directory}/.fvmrc" ] || [ -f "${version_directory}/.fvm/fvm_config.json" ]; then
                return 0
            fi

            if [ -f "${version_directory}/.tool-versions" ] && [ -n "$(flutter_version_from_tool_versions "${version_directory}/.tool-versions")" ]; then
                return 0
            fi

            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ] && [ -n "$(dart_version_from_mise_config "${version_directory}/${mise_file}" 'flutter')" ]; then
                    return 0
                fi
            done

            if [ -f "${version_directory}/pubspec.yaml" ] && grep -qE '^[[:space:]]*flutter:' "${version_directory}/pubspec.yaml"; then
                return 0
            fi
        done

        parent_directory="$(dirname "${directory}")"
        if [ "${parent_directory}" = "${directory}" ]; then
            break
        fi
        directory="${parent_directory}"
    done

    return 1
}

resolve_dart_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.dart-version" ]; then
                version="$(dart_version_from_version_file "${version_directory}/.dart-version")"
                version="$(normalize_dart_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(dart_version_from_mise_config "${version_directory}/${mise_file}" 'dart')"
                    version="$(normalize_dart_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(dart_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_dart_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/pubspec.yaml" ]; then
                version="$(dart_version_from_pubspec "${version_directory}/pubspec.yaml")"
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

resolve_flutter_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            for version_file in '.flutter-version' '.fvmrc' '.fvm/fvm_config.json'; do
                if [ -f "${version_directory}/${version_file}" ]; then
                    if [ "${version_file}" = '.flutter-version' ]; then
                        version="$(dart_version_from_version_file "${version_directory}/${version_file}")"
                    else
                        version="$(flutter_version_from_fvm_config "${version_directory}/${version_file}")"
                    fi
                    version="$(normalize_flutter_version "${version}")"
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
                    version="$(dart_version_from_mise_config "${version_directory}/${mise_file}" 'flutter')"
                    version="$(normalize_flutter_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(flutter_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_flutter_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/pubspec.yaml" ]; then
                version="$(flutter_version_from_pubspec "${version_directory}/pubspec.yaml")"
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

    printf '%s\n' 'stable'
}

dart_workspace_directory() {
    project_directory="${1}"

    if git -C "${project_directory}" rev-parse --show-toplevel >/dev/null 2>&1; then
        git -C "${project_directory}" rev-parse --show-toplevel
    else
        printf '%s\n' "${project_directory}"
    fi
}

update_dart_dependencies() {
    pubspec_file="${1}"
    update_target="${2}"

    printf '# Updating Dart / Flutter package file at %s\n' "${pubspec_file}" >&2

    project_directory="$(cd "$(dirname "${pubspec_file}")" && pwd -P)"
    workspace_directory="$(dart_workspace_directory "${project_directory}")"
    pubspec_lock_path="${project_directory}/pubspec.lock"

    if [ "${workspace_directory}" = "${project_directory}" ]; then
        project_path='.'
    else
        project_path="${project_directory#"${workspace_directory}/"}"
    fi

    if is_flutter_project "${project_directory}"; then
        dart_command='flutter'
        dart_version="$(resolve_flutter_version "${project_directory}")"
        dart_image="ghcr.io/cirruslabs/flutter:${dart_version}"
        runtime_name='Flutter'
    else
        dart_command='dart'
        dart_version="$(resolve_dart_version "${project_directory}")"
        dart_image="dart:${dart_version}"
        runtime_name='Dart'
    fi

    printf '# Resolved %s version %s for %s\n' "${runtime_name}" "${dart_version}" "${pubspec_file}" >&2

    if [ "${update_target}" = 'lock' ]; then
        return
    fi

    if [ ! -e "${pubspec_lock_path}" ]; then
        touch "${pubspec_lock_path}"
    fi

    run_update_command docker run --rm \
        --mount "type=bind,src=${workspace_directory},dst=/input,readonly=false" \
        --env "INPUT_PROJECT_DIRECTORY=/input/${project_path}" \
        --env "PROJECT_DIRECTORY=/work/${project_path}" \
        --env "UPDATE_TARGET=${update_target}" \
        --env "DART_COMMAND=${dart_command}" \
        --entrypoint '/bin/sh' \
        "${dart_image}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "${PROJECT_DIRECTORY}"

            case "${UPDATE_TARGET}" in
            major)
                "${DART_COMMAND}" pub upgrade --major-versions
                ;;
            minor)
                "${DART_COMMAND}" pub upgrade --tighten
                ;;
            patch)
                "${DART_COMMAND}" pub upgrade
                ;;
            lock)
                ;;
            esac

            cat "./pubspec.yaml" >"${INPUT_PROJECT_DIRECTORY}/pubspec.yaml"
            cat "./pubspec.lock" >"${INPUT_PROJECT_DIRECTORY}/pubspec.lock"
        '
}
