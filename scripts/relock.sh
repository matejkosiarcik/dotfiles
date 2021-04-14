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
    docker run --interactive --rm --volume "${directory}:/src" node:lts sh -c 'cd /src && export CYPRESS_INSTALL_BINARY=0 && npm install && npm dedupe'
    # TODO: check for .node-version to use specific project's version of node

    # remove node_modules (when on non-Linux, the node_modules are not usable anyway)
    rm -rf "${directory}/node_modules"
    printf 'Installing %s - DONE\n' "${directory}" >&2
}

if [ "${is_recursive}" -gt 0 ]; then
    # `grep .` is for returning non-0 when no match is found
    find . -type f -name 'package-lock.json' -or -name 'package.json' \( -not -path '*node_modules/*' -prune \) | grep . | while read -r package_file; do
        directory="$(dirname "${package_file}")"
        directory="$(node -e "console.log(require('path').resolve('.', '${directory}'))")"
        update_directory "${directory}"
    done
else
    update_directory "${PWD}"
fi
