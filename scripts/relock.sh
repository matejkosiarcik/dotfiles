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
    case "$opt" in
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

    if [ ! -e "$directory/package.json" ]; then
        printf 'Skipping %s - directory contains "package-lock.json", but no "package.json" found\n' "$directory" >&2
        return
    fi

    printf 'Installing %s\n' "$directory" >&2
    rm -rf "$directory/package-lock.json" "$directory/node_modules"

    tmpdir="$(mktemp -d)"
    cp "$directory/package.json" "$tmpdir/"
    docker run --rm \
        --volume "$tmpdir:/src" \
        --volume "$HOME/.npmrc:/src/.npmrc:ro" \
        --env CYPRESS_INSTALL_BINARY=0 \
        --env PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
        --env PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
        --env NODE_OPTIONS='--dns-result-order=ipv4first' \
        node:20.1.0 \
        sh -c 'cd /src && npm install --ignore-scripts && npm dedupe'
    cp "$tmpdir/package-lock.json" "$directory/"
    rm -rf "$tmpdir"

    # remove node_modules (when on non-Linux, the node_modules are not usable anyway)
    rm -rf "$directory/node_modules"
    printf 'Installing %s - \033[32mDONE\033[0m\n' "$directory" >&2
}

if [ "$is_recursive" -gt 0 ]; then
    # `grep .` is for returning non-0 when no match is found
    find . -type f -name 'package.json' \( -not -path '*node_modules/*' -prune \) | sort --version-sort | while read -r package_file; do
        package_file="$(node -e "console.log(require('path').resolve('.', '$package_file'))")"
        directory="$(dirname "$package_file")"
        update_directory "$directory"
    done
else
    update_directory "$PWD"
fi
