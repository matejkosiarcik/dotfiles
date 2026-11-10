#!/bin/sh
set -euf

is_php_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,2})$'
}

normalize_php_version() {
    version="${1}"

    case "${version}" in
    php-*)
        version="${version#php-}"
        ;;
    php[0-9]*)
        version="${version#php}"
        ;;
    *) ;;
    esac

    if is_php_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

php_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

php_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "php") {
                print $2
                exit
            }
        }
    ' "${1}"
}

php_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.php\][[:space:]]*$/) {
                section = "php"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && key == "php") || (section == "php" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

php_version_from_runtime_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;s~^php-([0-9]+(\.[0-9]+){0,2})$~\1~p' <"${1}"
}

php_version_from_composer_file() {
    sed -n -E 's~.*"php"[[:space:]]*:[[:space:]]*"([0-9]+(\.[0-9]+){0,2})".*~\1~p' <"${1}"
}

resolve_php_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.php-version" ]; then
                version="$(php_version_from_version_file "${version_directory}/.php-version")"
                version="$(normalize_php_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(php_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_php_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(php_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_php_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/runtime.txt" ]; then
                version="$(php_version_from_runtime_file "${version_directory}/runtime.txt")"
                version="$(normalize_php_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/composer.json" ]; then
                version="$(php_version_from_composer_file "${version_directory}/composer.json")"
                version="$(normalize_php_version "${version}")"
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

update_composer_dependencies() {
    composer_file="${1}"
    update_target="${2}"
    composer_directory="$(cd "$(dirname "${composer_file}")" && pwd -P)"
    composer_lock_path="${composer_directory}/composer.lock"
    php_version="$(resolve_php_version "${composer_directory}")"
    has_composer_lock='false'

    printf '\n\n# Updating Composer package file at %s\n' "${composer_file}" >&2
    printf '# Resolved PHP version %s for %s\n' "${php_version}" "${composer_file}" >&2

    if [ -e "${composer_lock_path}" ]; then
        has_composer_lock='true'
    else
        touch "${composer_lock_path}"
    fi

    (
        composer_tmpdir="$(mktemp -d)"
        trap 'rm -rf "${composer_tmpdir}"' 0 HUP INT TERM

        docker run --rm \
            --mount "type=bind,src=${composer_tmpdir},dst=/output,readonly=false" \
            --entrypoint '/bin/sh' \
            'composer:2' \
            -c '
                set -euf
                cp "$(command -v composer)" "/output/composer"
            '

        docker run --rm \
            --mount "type=bind,src=${composer_directory},dst=/input,readonly=false" \
            --mount "type=bind,src=${composer_tmpdir},dst=/composer,readonly=true" \
            --env "HAS_COMPOSER_LOCK=${has_composer_lock}" \
            --env "UPDATE_TARGET=${update_target}" \
            --env COMPOSER_ALLOW_SUPERUSER='1' \
            --entrypoint '/bin/sh' \
            "php:${php_version}" \
            -c '
                set -euf
                cp "/composer/composer" "/usr/local/bin/composer"
                chmod +x "/usr/local/bin/composer"

                mkdir -p "/work"
                cp -R "/input/." "/work/"
                cd "/work"

                if [ "${UPDATE_TARGET}" = "major" ]; then
                    if [ "${HAS_COMPOSER_LOCK}" = "true" ]; then
                        composer_major_updates="$(composer outdated --locked --direct --major-only --format=json)"
                        composer_major_packages="$(
                            # shellcheck disable=SC2016
                            printf "%s\\n" "${composer_major_updates}" | php -r '\''
                                $updates = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
                                $manifest = json_decode(file_get_contents("composer.json"), true, 512, JSON_THROW_ON_ERROR);
                                $require = $manifest["require"] ?? [];
                                $requireDev = $manifest["require-dev"] ?? [];

                                foreach ($updates["locked"] ?? [] as $update) {
                                    $package = $update["name"] ?? "";
                                    if (!is_string($package) || $package === "") {
                                        continue;
                                    }
                                    if (array_key_exists($package, $require)) {
                                        printf("production\t%s\n", $package);
                                    } elseif (array_key_exists($package, $requireDev)) {
                                        printf("development\t%s\n", $package);
                                    }
                                }
                            '\''
                        )"

                        printf "%s\\n" "${composer_major_packages}" | while IFS="$(printf "\\t")" read -r dependency_type package; do
                            if [ -z "${package}" ]; then
                                continue
                            fi

                            printf "\\n\\n# Updating major Composer constraint for %s\\n" "${package}" >&2
                            if [ "${dependency_type}" = "development" ]; then
                                composer require --dev --no-update --no-interaction --no-scripts "${package}"
                            else
                                composer require --no-update --no-interaction --no-scripts "${package}"
                            fi
                        done
                    fi
                    composer update --with-all-dependencies --no-install --no-interaction --no-scripts
                elif [ "${UPDATE_TARGET}" = "minor" ]; then
                    composer update --with-all-dependencies --no-install --no-interaction --no-scripts
                elif [ "${UPDATE_TARGET}" = "patch" ]; then
                    composer update --patch-only --no-install --no-interaction --no-scripts
                elif [ "${UPDATE_TARGET}" = "lock" ]; then
                    composer update --lock --no-install --no-interaction --no-scripts
                fi

                cat "./composer.json" >"/input/composer.json"
                cat "./composer.lock" >"/input/composer.lock"
            '
    )
}
