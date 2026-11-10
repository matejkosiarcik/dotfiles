#!/bin/sh
set -euf

print_help() {
    printf 'Usage: project-update [-h] [-t <target>] [-r <runtime>]\n'
    printf '\n'
    printf '  -h                                                              print help message\n'
    printf '  -t {major, minor, patch, lock}                                  semver upgrade target\n'
    printf '  -r {all, nodejs, dart-pub, dotnet-nuget, php-composer, python-pip, ruby-gem, rust-cargo, go-mod, swift-swiftpm, gitman}  which runtime to update\n'
}

# Resolve original script path to source utils
script_path="${0}"
case "${script_path}" in
*/*) ;;
*)
    script_path="$(command -v "${script_path}")"
    ;;
esac
while [ -L "${script_path}" ]; do
    script_directory="$(cd -P "$(dirname "${script_path}")" && pwd)"
    script_path="$(readlink "${script_path}")"
    case "${script_path}" in
    /*) ;;
    *)
        script_path="${script_directory}/${script_path}"
        ;;
    esac
done
source_dir="$(cd -P "$(dirname "${script_path}")" && pwd)"
PATH="${source_dir}/python-vendor/bin:${source_dir}/node_modules/.bin:/opt/homebrew/bin:${PATH}"
export PATH
PYTHONPATH="${source_dir}/python-vendor"
export PYTHONPATH

# shellcheck source=scripts/project-update/.python-tools.sh
. "${source_dir}/.python-tools.sh"
# shellcheck source=scripts/project-update/.js-tools.sh
. "${source_dir}/.js-tools.sh"
# shellcheck source=scripts/project-update/.ruby-tools.sh
. "${source_dir}/.ruby-tools.sh"
# shellcheck source=scripts/project-update/.go-tools.sh
. "${source_dir}/.go-tools.sh"
# shellcheck source=scripts/project-update/.dotnet-tools.sh
. "${source_dir}/.dotnet-tools.sh"
# shellcheck source=scripts/project-update/.dart-tools.sh
. "${source_dir}/.dart-tools.sh"
# shellcheck source=scripts/project-update/.rust-tools.sh
. "${source_dir}/.rust-tools.sh"
# shellcheck source=scripts/project-update/.swift-tools.sh
. "${source_dir}/.swift-tools.sh"

target='major'
runtime='all'
while getopts "h?t:r:" o; do
    case "${o}" in
    t)
        target="${OPTARG}"
        ;;
    r)
        runtime="${OPTARG}"
        ;;
    h)
        print_help
        exit 0
        ;;
    *)
        print_help
        exit 1
        ;;
    esac
done

if printf '%s' "${target}" | grep -qvE '^(major|minor|patch|lock)$'; then
    printf 'Unsupported target %s\n' "${target}" >&2
    print_help
    exit 1
fi

if printf '%s' "${runtime}" | grep -qvE '^(all|nodejs|dart\-pub|dotnet\-nuget|php\-composer|python\-pip|ruby\-gem|rust\-cargo|go\-mod|swift\-swiftpm|gitman)$'; then
    printf 'Unsupported runtime %s\n' "${runtime}" >&2
    print_help
    exit 1
fi

printf 'Updating %s runtime(s) to version: %s\n\n' "${runtime}" "${target}" >&2

glob() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        # This is a git repo
        while [ "${#}" -ge 1 ]; do
            git ls-files "${1}" "*/${1}"
            git ls-files --others --exclude-standard "${1}" "*/${1}"
            shift
        done
    else
        # This is not a git repo
        while [ "${#}" -ge 1 ]; do
            find . -name "${1}" -maxdepth 1 | sed -E 's~^./~~'
            shift
        done
    fi
}

# Dart / Flutter - Pub
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'dart-pub' ]; then
    printf '\n\n## Dart / Flutter > Pub ##\n' >&2
    glob 'pubspec.yaml' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        printf '\n\n# Updating Dart / Flutter package file at %s\n' "${file}" >&2
        update_dart_dependencies "${file}" "${target}"
    done
fi

# .NET - NuGet
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'dotnet-nuget' ]; then
    printf '\n\n## .NET > NuGet ##\n' >&2
    glob '*.csproj' '*.fsproj' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        printf '\n\n# Updating NuGet project at %s\n' "${file}" >&2
        update_dotnet_project "${file}" "${target}"
    done
fi

# Gitman
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'gitman' ]; then
    printf '\n\n## Gitman ##\n' >&2
    glob 'gitman.yml' '.gitman.yml' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi
        printf '\n\n# Updating gitman file at %s\n' "${file}" >&2

        (
            cd "$(dirname "${file}")"
            if [ "${target}" = 'major' ] || [ "${target}" = 'minor' ] || [ "${target}" = 'patch' ]; then
                gitman update --force # main
            elif [ "${target}" = 'lock' ]; then
                gitman install --force --fetch # no-file
            fi
            gitman lock # lock
        )
    done
fi

# JavaScript - NodeJS/NPM
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'nodejs' ]; then
    printf '\n\n## JavaScript > NodeJS ##\n' >&2
    glob 'package.json' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_nodejs_dependencies "${file}" "${target}"
    done
fi

# PHP - Composer
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'php-composer' ]; then
    printf '\n\n## PHP > Composer ##\n' >&2
    glob 'composer.json' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        printf '\n\n# Updating Composer package file at %s\n' "${file}" >&2
        (
            cd "$(dirname "${file}")"
            if [ "${target}" = 'major' ]; then
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
            elif [ "${target}" = 'minor' ]; then
                composer update --with-all-dependencies --no-install --no-interaction --no-scripts
            elif [ "${target}" = 'patch' ]; then
                composer update --patch-only --no-install --no-interaction --no-scripts
            elif [ "${target}" = 'lock' ]; then
                composer update --lock --no-install --no-interaction --no-scripts
            fi
        )
    done
fi

# Python - Pip
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'python-pip' ]; then
    printf '\n\n## Python > Pip ##\n' >&2

    # Projects with both requirements.in and requirements.txt
    glob '*requirements*.in' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        printf '\n\n# Updating pip requirements file at %s\n' "${file}" >&2

        update_python_requirements "${file}" "${target}"
    done

    # Projects with requirements.txt, but no requirements.in
    glob '*requirements*.txt' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        # Skip update if there is an associated requirements.in (already handled)
        if [ -e "${file%.txt}.in" ]; then
            continue
        fi

        printf '\n\n# Updating pip requirements file at %s\n' "${file}" >&2

        if [ "${target}" = 'lock' ]; then
            # There is no builtin way to update only lockfile, so skip it
            true
        else
            update_python_requirements "${file}" "${target}"
        fi
    done

    # TODO: Also update Pipfile
fi

# Ruby - Gem
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'ruby-gem' ]; then
    printf '\n\n## Ruby > Gem ##\n' >&2
    glob 'Gemfile' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        printf '\n\n# Updating Gemfile file at %s\n' "${file}" >&2
        update_ruby_dependencies "${file}" "${target}"
    done
fi

# Rust - Cargo
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'rust-cargo' ]; then
    printf '\n\n## Rust > Cargo ##\n' >&2
    glob 'Cargo.toml' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi
        printf '\n\n# Updating cargo file at %s\n' "${file}" >&2

        update_rust_dependencies "${file}" "${target}"
    done
fi

# Go - Modules
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'go-mod' ]; then
    printf '\n\n## Go > Modules ##\n' >&2
    glob 'go.mod' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi
        printf '\n\n# Updating Go module at %s\n' "${file}" >&2

        update_go_modules "${file}" "${target}"
    done
fi

# Swift - Swift Package Manager
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'swift-swiftpm' ]; then
    printf '\n\n## Swift > Package Manager ##\n' >&2
    glob 'Package.swift' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi
        printf '\n\n# Updating Swift package file at %s\n' "${file}" >&2

        update_swift_dependencies "${file}" "${target}"
    done
fi
