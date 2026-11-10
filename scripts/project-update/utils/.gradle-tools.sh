#!/bin/sh
set -euf

is_gradle_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){1,2})$'
}

normalize_gradle_version() {
    version="${1}"

    case "${version}" in
    gradle-*)
        version="${version#gradle-}"
        ;;
    v*)
        version="${version#v}"
        ;;
    *) ;;
    esac

    if is_gradle_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

gradle_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

gradle_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "gradle") {
                print $2
                exit
            }
        }
    ' "${1}"
}

gradle_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.gradle\][[:space:]]*$/) {
                section = "gradle"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && key == "gradle") || (section == "gradle" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

gradle_version_from_wrapper_file() {
    sed -n -E 's~.*gradle-([0-9]+(\.[0-9]+){1,2})-(bin|all)\.zip.*~\1~p' <"${1}"
}

is_java_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+)$'
}

normalize_java_version() {
    version="${1}"

    case "${version}" in
    java-* | jdk-* | temurin-* | corretto-* | zulu-*)
        version="${version#*-}"
        ;;
    *) ;;
    esac

    case "${version}" in
    1.8.*)
        version='8'
        ;;
    *)
        version="$(printf '%s\n' "${version}" | sed -n -E 's~^([0-9]+).*~\1~p')"
        ;;
    esac

    if is_java_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

java_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

java_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "java" || $1 == "temurin" || $1 == "corretto" || $1 == "zulu") {
                print $2
                exit
            }
        }
    ' "${1}"
}

java_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.(java|temurin|corretto|zulu)\][[:space:]]*$/) {
                section = "java"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && (key == "java" || key == "temurin" || key == "corretto" || key == "zulu")) || (section == "java" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

java_version_from_sdkman_config() {
    awk -F '=' '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "java") {
                print $2
                exit
            }
        }
    ' "${1}"
}

java_version_from_gradle_file() {
    sed -n -E '
        /JavaLanguageVersion\.of\([0-9]+\)/ { s~.*JavaLanguageVersion\.of\(([0-9]+)\).*~\1~p; q; }
        /jvmToolchain\([0-9]+\)/ { s~.*jvmToolchain\(([0-9]+)\).*~\1~p; q; }
        /JavaVersion\.VERSION_1_[0-9]+/ { s~.*JavaVersion\.VERSION_1_([0-9]+).*~\1~p; q; }
        /JavaVersion\.VERSION_[0-9]+/ { s~.*JavaVersion\.VERSION_([0-9]+).*~\1~p; q; }
    ' <"${1}"
}

gradle_workspace_directory() {
    directory="${1}"
    project_directory="${1}"

    while true; do
        for settings_file in 'settings.gradle' 'settings.gradle.kts'; do
            if [ -f "${directory}/${settings_file}" ]; then
                printf '%s\n' "${directory}"
                return
            fi
        done

        if [ -f "${directory}/gradlew" ] || [ -f "${directory}/gradle/wrapper/gradle-wrapper.properties" ]; then
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

is_gradle_workspace_entry() {
    gradle_file="${1}"
    project_directory="$(cd "$(dirname "${gradle_file}")" && pwd -P)"
    absolute_gradle_file="${project_directory}/$(basename "${gradle_file}")"
    workspace_directory="$(gradle_workspace_directory "${project_directory}")"

    for settings_file in 'settings.gradle' 'settings.gradle.kts'; do
        if [ -f "${workspace_directory}/${settings_file}" ]; then
            [ "${absolute_gradle_file}" = "${workspace_directory}/${settings_file}" ]
            return
        fi
    done

    [ "${project_directory}" = "${workspace_directory}" ]
}

resolve_gradle_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.gradle-version" ]; then
                version="$(gradle_version_from_version_file "${version_directory}/.gradle-version")"
                version="$(normalize_gradle_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(gradle_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_gradle_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(gradle_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_gradle_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/gradle/wrapper/gradle-wrapper.properties" ]; then
                version="$(gradle_version_from_wrapper_file "${version_directory}/gradle/wrapper/gradle-wrapper.properties")"
                version="$(normalize_gradle_version "${version}")"
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

resolve_java_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            for version_file in '.java-version' '.jdk-version'; do
                if [ -f "${version_directory}/${version_file}" ]; then
                    version="$(java_version_from_version_file "${version_directory}/${version_file}")"
                    version="$(normalize_java_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.sdkmanrc" ]; then
                version="$(java_version_from_sdkman_config "${version_directory}/.sdkmanrc")"
                version="$(normalize_java_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(java_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_java_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(java_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_java_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for gradle_file in 'build.gradle' 'build.gradle.kts'; do
                if [ -f "${version_directory}/${gradle_file}" ]; then
                    version="$(java_version_from_gradle_file "${version_directory}/${gradle_file}")"
                    version="$(normalize_java_version "${version}")"
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

is_android_gradle_project() {
    rg -q --glob 'build.gradle' --glob 'build.gradle.kts' 'com\.android\.(application|library|dynamic-feature|test)|(^|[[:space:]])android[[:space:]]*\{' "${1}"
}

android_sdk_version_from_gradle_files() {
    rg --no-filename --glob 'build.gradle' --glob 'build.gradle.kts' -m 1 -o 'compileSdk(Version)?[[:space:]]*(=)?[[:space:]]*[0-9]+' "${1}" | sed -n -E 's~[^0-9]*([0-9]+).*~\1~p'
}

gradle_docker_image() {
    gradle_version="${1}"
    java_version="${2}"

    if [ "${gradle_version}" = 'latest' ]; then
        if [ "${java_version}" = 'latest' ]; then
            printf '%s\n' 'gradle:latest'
        else
            printf 'gradle:jdk%s\n' "${java_version}"
        fi
    elif [ "${java_version}" = 'latest' ]; then
        printf 'gradle:%s\n' "${gradle_version}"
    else
        printf 'gradle:%s-jdk%s\n' "${gradle_version}" "${java_version}"
    fi
}

update_gradle_dependencies() {
    gradle_file="${1}"
    update_target="${2}"
    project_directory="$(cd "$(dirname "${gradle_file}")" && pwd -P)"

    if ! is_gradle_workspace_entry "${gradle_file}"; then
        return
    fi

    workspace_directory="$(gradle_workspace_directory "${project_directory}")"
    gradle_lock_path="${workspace_directory}/gradle.lockfile"
    gradle_version="$(resolve_gradle_version "${workspace_directory}")"
    java_version="$(resolve_java_version "${workspace_directory}")"

    printf '# Updating Gradle project at %s\n' "${gradle_file}" >&2
    printf '# Resolved Gradle version %s and Java version %s for %s\n' "${gradle_version}" "${java_version}" "${gradle_file}" >&2

    if is_android_gradle_project "${workspace_directory}"; then
        android_sdk_version="$(android_sdk_version_from_gradle_files "${workspace_directory}")"
        if [ -n "${android_sdk_version}" ]; then
            gradle_image="ghcr.io/cirruslabs/android-sdk:${android_sdk_version}"
        else
            gradle_image='ghcr.io/cirruslabs/android-sdk:tools'
        fi
        gradle_command='./gradlew'

        if [ ! -f "${workspace_directory}/${gradle_command#./}" ]; then
            printf 'Android Gradle project %s requires a Gradle Wrapper\n' "${gradle_file}" >&2
            return 1
        fi

        printf '# Resolved Android SDK version %s for %s\n' "${android_sdk_version:-tools}" "${gradle_file}" >&2
    else
        gradle_image="$(gradle_docker_image "${gradle_version}" "${java_version}")"
        gradle_command='gradle'
    fi

    if [ ! -e "${gradle_lock_path}" ]; then
        touch "${gradle_lock_path}"
    fi

    # shellcheck disable=SC2016
    run_update_command docker run --rm \
        --user '0:0' \
        --mount "type=bind,src=${workspace_directory},dst=/input,readonly=false" \
        --env "GRADLE_COMMAND=${gradle_command}" \
        --env "GRADLE_USER_HOME=/tmp/gradle" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "${gradle_image}" \
        -c '
            set -euf
            mkdir -p "/work"
            cp -R "/input/." "/work/"
            cd "/work"

            if [ ! -s "./gradle.lockfile" ]; then
                rm -f "./gradle.lockfile"
            fi

            "${GRADLE_COMMAND}" dependencies --write-locks --no-daemon

            find "/work" -type f -name "*.lockfile" -print | while IFS= read -r updated_file; do
                relative_path="${updated_file#/work/}"
                mkdir -p "$(dirname "/input/${relative_path}")"
                cat "${updated_file}" >"/input/${relative_path}"
            done
        '
}
