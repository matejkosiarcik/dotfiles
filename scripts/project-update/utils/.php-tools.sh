#!/bin/sh
set -euf

update_composer_dependencies() {
    composer_file="${1}"
    update_target="${2}"

    printf '\n\n# Updating Composer package file at %s\n' "${composer_file}" >&2

    (
        cd "$(dirname "${composer_file}")"
        if [ "${update_target}" = 'major' ]; then
            if [ -e composer.lock ]; then
                composer_major_updates="$(composer outdated --locked --direct --major-only --format=json)"
                composer_major_packages="$(
                    # shellcheck disable=SC2016
                    printf '%s\n' "${composer_major_updates}" | php -r '
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
                    '
                )"

                printf '%s\n' "${composer_major_packages}" | while IFS="$(printf '\t')" read -r dependency_type package; do
                    if [ -z "${package}" ]; then
                        continue
                    fi

                    printf '\n\n# Updating major Composer constraint for %s\n' "${package}" >&2
                    if [ "${dependency_type}" = 'development' ]; then
                        composer require --dev --no-update --no-interaction --no-scripts "${package}"
                    else
                        composer require --no-update --no-interaction --no-scripts "${package}"
                    fi
                done
            fi
            composer update --with-all-dependencies --no-install --no-interaction --no-scripts
        elif [ "${update_target}" = 'minor' ]; then
            composer update --with-all-dependencies --no-install --no-interaction --no-scripts
        elif [ "${update_target}" = 'patch' ]; then
            composer update --patch-only --no-install --no-interaction --no-scripts
        elif [ "${update_target}" = 'lock' ]; then
            composer update --lock --no-install --no-interaction --no-scripts
        fi
    )
}
