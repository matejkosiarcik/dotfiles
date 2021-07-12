#!/usr/bin/env bash
set -eufao pipefail

function usage {
    printf 'Usage: dir-clean dir [-h] [-n] [-i] [-f]\n'
    printf ' dir    directory to clean (recursively)\n'
    printf ' -h     show help message\n'
    printf ' -n     dry run\n'
    printf ' -i     interactive\n'
    printf ' -f     force\n'
}

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n\n' >&2
    usage >&2
    exit 1
fi
dir="$1"
shift

mode=''
while getopts "h?n?i?f?" opt; do
    case "$opt" in
    h)
        usage
        ;;
    n)
        mode='n'
        ;;
    i)
        mode='i'
        ;;
    f)
        mode='f'
        ;;
    *)
        usage >&2
        exit 1
        ;;
    esac
done
if [ "$mode" = '' ]; then
    printf 'No mode specified (specify either -n|-i|-f)\n\n' >&2
    usage >&2
    exit 1
fi

function handle_file {
    mode="$1"
    file="$2"

    case "$mode" in
    n)
        printf 'Would remove %s\n' "$file"
        ;;
    i)
        read -r -p "Remove $file? [y/N] " response
        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            printf 'Removing %s\n' "$file"
            rm -rf "$file"
        fi
        ;;
    f)
        printf 'Removing %s\n' "$file"
        rm -rf "$file"
        ;;
    *)
        printf 'Unrecognized mode: %s\n' "$mode"
        exit 1
        ;;
    esac
}

printf '### Remove dev folders ###\n'
find "$dir" -type d \( \
    -name '.bundle' -or \
    -name '.gradle' -or \
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
    \) -prune -exec sh -c 'handle_file "$0" "$1"' "$mode" '{}' \;

printf '### Remove OS junk files and dev cache files ###\n'
find "$dir" -type f \( \
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
    \) -exec sh -c 'handle_file "$0" "$1"' "$mode" '{}' \;

printf '### Remove Windows reserved files ###\n'
find "$dir" \( -iname 'CON' \
    -or -iname 'PRN' \
    -or -iname 'AUX' \
    -or -iname 'NUL' \
    -or -iname 'COM1' \
    -or -iname 'COM2' \
    -or -iname 'COM3' \
    -or -iname 'COM4' \
    -or -iname 'COM5' \
    -or -iname 'COM6' \
    -or -iname 'COM7' \
    -or -iname 'COM8' \
    -or -iname 'COM9' \
    -or -iname 'LPT1' \
    -or -iname 'LPT2' \
    -or -iname 'LPT3' \
    -or -iname 'LPT4' \
    -or -iname 'LPT5' \
    -or -iname 'LPT6' \
    -or -iname 'LPT7' \
    -or -iname 'LPT8' \
    -or -iname 'LPT9' \
    \) -exec sh -c 'handle_file "$0" "$1"' "$mode" '{}' \;

# remove symlinks
# printf '### Remove symlinks ###\n'
# find . -type l -exec sh -c 'printf "%s\n" "{}"' \;

# TODO: enable xattr without -c flag (unavailable on Ubuntu)
# printf '### Remove extended attributes ###\n'
# case "$mode" in
# n)
#     printf 'Would remove attributes from %s\n' "$dir"
#     ;;
# i)
#     read -r -p "Remove attributes from $dir? [y/N] " response
#     if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
#         printf 'Removing attributes from %s\n' "$dir"
#         xattr -rc "$dir"
#     fi
#     ;;
# f)
#     printf 'Removing attributes from %s\n' "$dir"
#     xattr -rc "$dir"
#     ;;
# *)
#     printf 'Unrecognized mode: %s\n' "$mode"
#     exit 1
#     ;;
# esac
