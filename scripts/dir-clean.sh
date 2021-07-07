#!/bin/sh
set -euf

# Do not try to pass the directory as an argument
# The directory must be in cwd
if [ "$#" -gt 0 ]; then
    printf 'Too many arguments\n'
fi

printf '### Remove dev folders ###\n'
find . -type d \( \
    -name '.bundle' -or \
    -name '.idea' -or \
    -name '.venv' -or \
    -name '*.framework' -or \
    -name 'bower_components' -or \
    -name 'build' -or \
    -name 'Carthage' -or \
    -name 'CMakeFiles' -or \
    -name 'CMakeScripts' -or \
    -name 'dist' -or \
    -name 'node_modules' -or \
    -name 'Pods' -or \
    -name 'target' -or \
    -name 'vendor' -or \
    -name 'venv' \
    \) -prune -exec sh -c 'printf "Remove: %s\n" "$0" && rm -rf "$0"' '{}' \;

printf '### Remove OS junk files and dev cache files ###\n'
find . -type f \( \
    -name '._*' -or \
    -iname '.DS_Store' -or \
    -iname '.AppleDouble' -or \
    -iname '.LSOverride' -or \
    -iname '.localized' -or \
    -iname 'CMakeCache.txt' -or \
    -iname 'Thumbs.db' -or \
    -iname 'ehthumbs.db' -or \
    -iname 'ehthumbs_vista.db' -or \
    -iname 'desktop.ini' \
    \) -exec sh -c 'printf "Remove: %s\n" "$0" && rm -f "$0"' '{}' \;

# remove symlinks
# printf '### Remove symlinks ###\n'
# find . -type l -exec sh -c 'printf "%s\n" "{}"' \;

printf '### Remove extended attributes ###\n'
xattr -rc .
