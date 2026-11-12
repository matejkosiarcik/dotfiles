#!/bin/sh
set -euf

print_help() {
    printf 'Usage: project-update [-h] [-t <target>] [-r <runtime[,runtime...]>]\n'
    printf '\n'
    printf '  -h                              print help message\n'
    printf '  -t {major, minor, patch, lock}  semver upgrade target\n'
    printf '  -r <runtime[,runtime...]>       runtimes to update; partial names are accepted\n'
    printf '                                  available: all, nodejs, dart-pub, dotnet-nuget, elixir-mix, go-mod, gradle,\n'
    printf '                                             haskell-cabal, haskell-stack, julia-pkg, php-composer,\n'
    printf '                                             python-pip, ruby-gem, rust-cargo, swift-swiftpm, gitman\n'
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
PATH="/opt/homebrew/bin:${PATH}"               # Homebrew
PATH="${source_dir}/node_modules/.bin:${PATH}" # NodeJS dependencies
PATH="${source_dir}/python-vendor/bin:${PATH}" # Python dependencies
export PATH
PYTHONPATH="${source_dir}/python-vendor"
export PYTHONPATH

# shellcheck source=scripts/project-update/utils/.misc-tools.sh
. "${source_dir}/utils/.misc-tools.sh"
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
# shellcheck source=scripts/project-update/utils/.elixir-tools.sh
. "${source_dir}/utils/.elixir-tools.sh"
# shellcheck source=scripts/project-update/utils/.gradle-tools.sh
. "${source_dir}/utils/.gradle-tools.sh"
# shellcheck source=scripts/project-update/utils/.rust-tools.sh
. "${source_dir}/utils/.rust-tools.sh"
# shellcheck source=scripts/project-update/utils/.swift-tools.sh
. "${source_dir}/utils/.swift-tools.sh"
# shellcheck source=scripts/project-update/utils/.haskell-tools.sh
. "${source_dir}/utils/.haskell-tools.sh"
# shellcheck source=scripts/project-update/utils/.julia-tools.sh
. "${source_dir}/utils/.julia-tools.sh"
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

runtime_matches() {
    if [ "${runtime}" = 'all' ]; then
        return 0
    fi

    printf '%s\n' "${runtime}" | tr ',' '\n' | (
        while IFS= read -r runtime_filter; do
            if [ -n "${runtime_filter}" ] && printf '%s\n' "${1}" | grep -Fq -- "${runtime_filter}"; then
                exit 0
            fi
        done

        exit 1
    )
}

printf 'Updating %s runtime(s) to version %s\n' "${runtime}" "${target}" >&2

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
            find "." -name "${1}" -maxdepth 1 | sed -E 's~^./~~'
            shift
        done
    fi
}

# Dart / Flutter - Pub
if runtime_matches 'dart-pub'; then
    printf '\n## Updating Dart / Flutter > Pub ##\n' >&2
    glob 'pubspec.yaml' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_dart_dependencies "${file}" "${target}"
    done
fi

# Elixir - Mix
if runtime_matches 'elixir-mix'; then
    printf '\n## Updating Elixir > Mix ##\n' >&2
    glob 'mix.exs' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_elixir_dependencies "${file}" "${target}"
    done
fi

# .NET - NuGet
if runtime_matches 'dotnet-nuget'; then
    printf '\n## Updating .NET > NuGet ##\n' >&2
    glob '*.csproj' '*.fsproj' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_dotnet_project "${file}" "${target}"
    done
fi

# Java / Kotlin / Android - Gradle
if runtime_matches 'gradle' || runtime_matches 'java' || runtime_matches 'kotlin' || runtime_matches 'android'; then
    printf '\n## Updating Java / Kotlin / Android > Gradle ##\n' >&2
    glob 'settings.gradle' 'settings.gradle.kts' 'build.gradle' 'build.gradle.kts' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_gradle_dependencies "${file}" "${target}"
    done
fi

# Gitman
if runtime_matches 'gitman'; then
    printf '\n## Updating Gitman ##\n' >&2
    glob 'gitman.yml' '.gitman.yml' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_gitman_dependencies "${file}" "${target}"
    done
fi

# Haskell - Cabal
if runtime_matches 'haskell-cabal'; then
    printf '\n## Updating Haskell > Cabal ##\n' >&2
    glob '*.cabal' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        if { [ "${runtime}" != 'all' ] && runtime_matches 'haskell-cabal'; } || ! is_haskell_stack_project "${file}"; then
            update_haskell_cabal_dependencies "${file}" "${target}"
        fi
    done
fi

# Haskell - Stack
if runtime_matches 'haskell-stack'; then
    printf '\n## Updating Haskell > Stack ##\n' >&2
    glob 'stack.yaml' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_haskell_stack_dependencies "${file}" "${target}"
    done
fi

# Julia - Pkg
if runtime_matches 'julia-pkg'; then
    printf '\n## Updating Julia > Pkg ##\n' >&2
    glob 'Project.toml' 'JuliaProject.toml' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_julia_dependencies "${file}" "${target}"
    done
fi

# JavaScript - NodeJS/NPM
if runtime_matches 'nodejs'; then
    printf '\n## Updating JavaScript > NodeJS ##\n' >&2
    glob 'package.json' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_nodejs_dependencies "${file}" "${target}"
    done
fi

# PHP - Composer
if runtime_matches 'php-composer'; then
    printf '\n## Updating PHP > Composer ##\n' >&2
    glob 'composer.json' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_composer_dependencies "${file}" "${target}"
    done
fi

# Python - Pip
if runtime_matches 'python-pip'; then
    printf '\n## Updating Python > Pip ##\n' >&2

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
if runtime_matches 'ruby-gem'; then
    printf '\n## Updating Ruby > Gem ##\n' >&2
    glob 'Gemfile' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_ruby_dependencies "${file}" "${target}"
    done
fi

# Rust - Cargo
if runtime_matches 'rust-cargo'; then
    printf '\n## Updating Rust > Cargo ##\n' >&2
    glob 'Cargo.toml' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_rust_dependencies "${file}" "${target}"
    done
fi

# Go - Modules
if runtime_matches 'go-mod'; then
    printf '\n## Updating Go > Modules ##\n' >&2
    glob 'go.mod' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_go_modules "${file}" "${target}"
    done
fi

# Swift - Swift Package Manager
if runtime_matches 'swift-swiftpm'; then
    printf '\n## Updating Swift > Package Manager ##\n' >&2
    glob 'Package.swift' | while read -r file; do
        if [ ! -e "${file}" ]; then
            continue
        fi

        update_swift_dependencies "${file}" "${target}"
    done
fi

printf '\n\nSucessfully updated dependencies\n\n' >&2
