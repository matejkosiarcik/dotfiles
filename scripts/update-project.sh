#!/bin/sh
set -euf

# TODO: dry-run
# TODO: target version (major, minor, patch)

glob() {
    while [ "$#" -ge 1 ]; do
        git ls-files "$1" "*/$1"
        git ls-files --others --exclude-standard "$1" "*/$1"
        shift
    done
}

# NodeJS
printf '## NodeJS ##\n'
glob 'package.json' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi
    ncu --cwd "$(dirname "$file")" --target latest --upgrade # main
    (cd "$(dirname "$file")" && relock)                      # lock
done

# Python
printf '## Pip ##\n'
glob '*requirements*.txt' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi
    pur --force --requirement "$file"
done

# Rust
printf '## Cargo ##\n'
glob 'Cargo.toml' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi
    (cd "$(dirname "$file")" && cargo upgrade) # main
    (cd "$(dirname "$file")" && cargo update)  # lock
done

# Gitman
printf '## Gitman ##\n'
glob 'gitman.yml' '.gitman.yml' | while read -r file; do
    if [ ! -e "$file" ]; then
        continue
    fi
    (cd "$(dirname "$file")" && gitman update) # main
    (cd "$(dirname "$file")" && gitman lock)   # lock
done
