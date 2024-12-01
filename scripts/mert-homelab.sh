#!/bin/sh
set -euf

if [ "$#" -lt 1 ]; then
    printf 'Not enough arguments\n' >&2
    exit 1
fi

host="$1"

ssh -t "$host" 'cd "$HOME/git/homelab/servers/.current"; exec "$SHELL"'
