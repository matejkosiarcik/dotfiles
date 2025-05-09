#!/bin/sh
set -euf

cd "$(dirname "$0")"
mkdir -p "$HOME/.log" "$HOME/Pictures/Import" "$HOME/Pictures/Import - Raw" "$HOME/Pictures/Not Import"

PATH="$PATH:/opt/homebrew/bin"
nohup sh photo-import/main.sh 2>&1 | ts '%Y-%m-%d %H:%M:%.S |' >>"$HOME/.log/photo-import.txt" &
nohup sh screenrecording-rename/main.sh 2>&1 | ts '%Y-%m-%d %H:%M:%.S |' >>"$HOME/.log/screenrecording-rename.txt" &
nohup sh screenshots-rename/main.sh 2>&1 | ts '%Y-%m-%d %H:%M:%.S |' >>"$HOME/.log/screenshots-rename.txt" &
