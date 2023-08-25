#!/bin/sh
set -euf

if [ "${DEVDIR+x}" = "" ]; then
    DEVDIR="$HOME/Dev"
fi

rsync -ar "$HOME/Dev/" "$HOME/Desktop/experiments/Target" --include='**.gitignore' --exclude='**/.git' --exclude='**/most-hlohovec' --filter=':- .gitignore' --delete
