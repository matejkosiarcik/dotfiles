#!/bin/sh
set -euf

find dist -type f -name '*.js' -maxdepth 1 | while read -r file; do
    content="$(printf '%s%s%s\n%s' '#' '!' '/usr/bin/env node' "$(cat "$file")")"
    printf '%s\n' "$content" >"$file"
    chmod a+x "$file"
done
