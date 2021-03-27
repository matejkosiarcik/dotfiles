#!/bin/sh
set -euf

# Recreate package-lock.json and reinstall packages

print_help() {
    printf 'relock\n'
    printf '%s\n' '-h    Get help'
    printf '%s\n' '-r    Search all directories recursively'
}

# parse arguments
is_recursive=0
while getopts "h?r?" opt; do
    case "${opt}" in
    h)
        print_help
        exit 0
        ;;
    r) is_recursive=1 ;;
    *)
        printf 'Unsupported argument.' >&2
        exit 1
        ;;
    esac
done

update_directory() {
    directory="${1}"

    if [ ! -e "${directory}/package.json" ]; then
        printf 'Skipping %s - directory contains "package-lock.json", but no "package.json" found\n' "${directory}" >&2
        return
    fi

    printf 'Installing %s\n' "${directory}" >&2
    rm -rf "${directory}/package-lock.json" "${directory}/node_modules"
    docker run --interactive --volume "${directory}:/src" node:lts sh -c 'cd /src && npm install && npm dedupe'
    # TODO: check for .node-version to use specific project's version of node

    # remove node_modules (when on non-Linux, the node_modules are not usable anyway)
    rm -rf "${directory}/node_modules"
    printf 'Installing %s - DONE\n' "${directory}" >&2
}

if [ "${is_recursive}" -gt 0 ]; then
    find . -type f -name 'package-lock.json' \( -not -path '*node_modules/*' -prune \) | while read -r lockfile; do
        directory="$(dirname "${lockfile}")"
        directory="$(node -e "console.log(require('path').resolve('.', '${directory}'))")"
        update_directory "${directory}"
    done
else
    update_directory "${PWD}"
fi
