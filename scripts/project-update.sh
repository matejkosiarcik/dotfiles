#!/bin/sh
set -euf

# TODO: dry-run
# TODO: target version (major, minor, patch)

print_help() {
    printf 'Usage: project-update [-h] [-t <target>]\n'
    printf '\n'
    printf '  -h                       print help message\n'
    printf '  -t {major, minor, patch}  semver upgrade target\n'
}

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

if [ "$target" != 'major' ] && [ "$target" != 'minor' ] && [ "$target" != 'patch' ]; then
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
    ncu --cwd "$(dirname "$file")" --target "$ncu_target" --upgrade # main
    (cd "$(dirname "$file")" && relock)                             # lock
done

# Python
printf '## Pip ##\n'
glob '*requirements*.txt' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi
    if [ "$target" = 'major' ]; then
        pur --force --requirement "$file"
    else
        pur --force "--$target" --requirement "$file"
    fi
done

# Rust
if [ "$target" = major ]; then
    printf '## Cargo ##\n'
    glob 'Cargo.toml' | while read -r file; do
        if [ ! -e "$file" ]; then
            continue
        fi
        (cd "$(dirname "$file")" && cargo upgrade) # main
        (cd "$(dirname "$file")" && cargo update)  # lock
    done
else
    printf '## Skipping cargo ##\n'
fi

# Gitman
printf '## Gitman ##\n'
glob 'gitman.yml' '.gitman.yml' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi
    (cd "$(dirname "$file")" && gitman update) # main
    (cd "$(dirname "$file")" && gitman lock)   # lock
done
