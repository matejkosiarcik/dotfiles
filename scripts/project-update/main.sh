#!/bin/sh
set -euf

print_help() {
    printf 'Usage: project-update [-h] [-t <target>]\n'
    printf '\n'
    printf '  -h                              print help message\n'
    printf '  -t {major, minor, patch, lock}  semver upgrade target\n'
}

source_dir="$(dirname "$(readlink "$0")")"
PATH="$source_dir/python/bin:$source_dir/node_modules/.bin:/opt/homebrew/bin:$PATH"
export PATH
PYTHONPATH="$source_dir/python"
export PYTHONPATH

target='major'
while getopts "h?t:" o; do
    case "$o" in
    t)
        target="$OPTARG"
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

if printf '%s' "$target" | grep -qvE '^(major|minor|patch|lock)$'; then
    printf 'Unsupported target %s\n' "$target"
    print_help
    exit 1
fi

glob() {
    while [ "$#" -ge 1 ]; do
        git ls-files "$1" "*/$1"
        git ls-files --others --exclude-standard "$1" "*/$1"
        shift
    done
}

# NodeJS
printf '## NodeJS ##\n'
ncu_target="$target"
if [ "$ncu_target" = 'major' ]; then
    ncu_target='latest'
fi
glob 'package.json' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi

    if [ "$target" != 'lock' ]; then
        ncu --cwd "$(dirname "$file")" --target "$ncu_target" --upgrade # package.json
    fi

    directory="$(dirname "$file")"
    dirname="$(cd "$directory" >/dev/null 2>&1 && basename "$PWD")"
    tmpdir="$(mktemp -d)"
    cp "$directory/package.json" "$tmpdir/package.json"
    docker run --rm \
        --volume "$tmpdir:/src/$dirname" \
        --volume "$HOME/.npmrc:/src/$dirname.npmrc:ro" \
        --env CYPRESS_INSTALL_BINARY=0 \
        --env PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
        --env PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
        --env NODE_OPTIONS='--dns-result-order=ipv4first' \
        --entrypoint /bin/sh \
        node:latest \
        -c "cd \"/src/$dirname\" && npm install --ignore-scripts && npm dedupe"
    mv "$tmpdir/package-lock.json" "$directory/package-lock.json"
    rm -rf "$tmpdir"
done

# Python
# TODO: Pipfile
printf '## Pip ##\n'
glob '*requirements*.txt' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi

    if [ "$target" = 'major' ]; then
        pur --force --requirement "$file"
    elif [ "$target" != 'lock' ]; then
        pur --force "--$target" '*' --requirement "$file"
    fi
done

# Rust
glob 'Cargo.toml' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi

    if [ "$target" = 'major' ]; then
        (cd "$(dirname "$file")" && cargo upgrade --incompatible) # main
    elif [ "$target" = 'minor' ]; then
        (cd "$(dirname "$file")" && cargo upgrade) # main
    fi
    (cd "$(dirname "$file")" && cargo update) # lock
done

# Gitman
printf '## Gitman ##\n'
glob 'gitman.yml' '.gitman.yml' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi

    if [ "$target" != 'lock' ]; then
        (cd "$(dirname "$file")" && gitman update --force) # main
    fi
    (cd "$(dirname "$file")" && gitman lock) # lock
done
