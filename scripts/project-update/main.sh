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

# shellcheck source=scripts/project-update/utils/.docker-tools.sh
. "${source_dir}/utils/.docker-tools.sh"
# shellcheck source=scripts/project-update/utils/.python-tools.sh
. "${source_dir}/utils/.python-tools.sh"
# shellcheck source=scripts/project-update/utils/.js-tools.sh
. "${source_dir}/utils/.js-tools.sh"
# shellcheck source=scripts/project-update/utils/.ruby-tools.sh
. "${source_dir}/utils/.ruby-tools.sh"
# shellcheck source=scripts/project-update/utils/.go-tools.sh
. "${source_dir}/utils/.go-tools.sh"
# shellcheck source=scripts/project-update/utils/.dotnet-tools.sh
. "${source_dir}/utils/.dotnet-tools.sh"
# shellcheck source=scripts/project-update/utils/.dart-tools.sh
. "${source_dir}/utils/.dart-tools.sh"
# shellcheck source=scripts/project-update/utils/.rust-tools.sh
. "${source_dir}/utils/.rust-tools.sh"
# shellcheck source=scripts/project-update/utils/.swift-tools.sh
. "${source_dir}/utils/.swift-tools.sh"
# shellcheck source=scripts/project-update/utils/.gitman-tools.sh
. "${source_dir}/utils/.gitman-tools.sh"
# shellcheck source=scripts/project-update/utils/.php-tools.sh
. "${source_dir}/utils/.php-tools.sh"

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
        update_gitman_dependencies "${file}" "${target}"
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

        update_composer_dependencies "${file}" "${target}"
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

        update_python_requirements "${file}" "${target}"
    done

    glob 'Pipfile' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_python_pipfile "${file}" "${target}"
    done
fi

# Ruby - Gem
if [ "${runtime}" = 'all' ] || [ "${runtime}" = 'ruby-gem' ]; then
    printf '\n\n## Ruby > Gem ##\n' >&2
    glob 'Gemfile' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

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
        update_swift_dependencies "${file}" "${target}"
    done
fi

printf 'Sucessfully updated dependencies\n' >&2
