#!/bin/sh
set -euf

# Recreate package-lock.json and reinstall packages
# Works in CWD

find . \( -type d -name 'node_modules' -prune \) -exec rm -rf {} \;

update_directory() {
    directory="${1}"
    docker run --interactive --volume "${directory}:/src" node:lts sh -c 'cd /src && npm install && npm dedupe'
    # TODO: check directory (and recursively to root) for presence of .node-version to use specific project's version of node

    # remove node_modules (when on non-Linux, the node_modules are not usable anyway)
    rm -rf "${directory}/node_modules"
}

find . -type f -name 'package-lock.json' -not -path '*node_modules/*' | while read -r lockfile; do
    directory="$(dirname "${lockfile}")"
    directory="$(node -e "console.log(require('path').resolve('.', '${directory}'))")"

    if [ -e "${directory}/package.json" ]; then
        rm -f "${lockfile}"
        update_directory "${directory}"
    fi
done
