#!/usr/bin/env bash
set -eufo pipefail

# function cleanfile {
#     file="$1"
#     xattr "$file" | xargs -n1 -J% xattr -d % "$file"
# }
# export -f cleanfile

# find . -exec sh -c 'cleanfile "$0"' '{}' \;

function fun {
    file="$1"
    basename "$file"
}
export -f fun

find . -exec sh -c 'fun "$0"' '{}' \;
