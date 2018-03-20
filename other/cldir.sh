#!/bin/sh
set -euf

if [ "${#}" -le '1' ]; then
    printf 'No path provided\n' >&2
    exit 1
fi

dot_clean -m "${1}" # for ._* files # BSD
find "${1}" -name '.DS_Store' -exec rm -f {} \;  # macOS
find "${1}" -name '.localized' -exec rm -f {} \; # macOS
find "${1}" -name 'Thumbs.db' -exec rm -f {} \;  # Windows
