#!/bin/sh
set -euf
# Monitors files in current directory and calls `command` on change
# Ignores changes to gitignored files

if [ "$#" -lt 1 ]; then
    printf 'Command missing\n' >&2
    exit 1
fi
command="$1"

# Monitor everything (except certain ignored paths)
# For each change verify that file belongs in git (ignore change if not)
chokidar '**/*' --initial --silent \
    --command "if ! git check-ignore '{path}' >/dev/null 2>&1; then clear; $command; fi" \
    --ignore "**/.DS_Store" \
    --ignore "**/.bundle" \
    --ignore "**/.idea" \
    --ignore "**/.pytest_cache" \
    --ignore "**/.venv" \
    --ignore "**/.vs" \
    --ignore "**/.vscode" \
    --ignore "**/Desktop.ini" \
    --ignore "**/Thumbs.db" \
    --ignore "**/__pycache__" \
    --ignore "**/dist" \
    --ignore "**/node_modules" \
    --ignore "**/public" \
    --ignore "**/target" \
    --ignore "**/venv" \
    --ignore "**/tmp"
