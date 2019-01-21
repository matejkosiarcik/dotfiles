#!/bin/sh
set -euf

# TODO: example usage
# TODO: help page
# TODO: make dry run

path='.'
# TODO: make cleaning for all supplied paths
if [ "${#}" -ge 1 ]; then
    path="${1}"
fi

dot_clean -m "${path}"                                      # for ._* files # BSD
find "${path}" -name '.DS_Store' -exec rm -f {} \;          # macOS
find "${path}" -name '.localized' -type f -exec rm -f {} \; # macOS
find "${path}" -name 'Thumbs.db' -exec rm -f {} \;          # Windows
