#!/bin/sh
set -euf

# requires watchdog to be installed (via pip/python)
watchmedo shell-command \
    --patterns='*.png' \
    --ignore-directories \
    --command='if [ "$watch_object" = file ] && [ "$watch_event_type" = created ] && basename "$watch_src_path" | grep -E "^Screenshot .+\.png\$" >/dev/null 2>&1; then mv "$watch_src_path" "$(dirname "$watch_src_path")/$(basename "$watch_src_path" | sed -E "s~Screenshot ([0-9]{4})-([0-9]{2})-([0-9]{2}).+([0-9]{2})\.([0-9]{2})\.([0-9]{2})\.png~\1-\2-\3_\4-\5-\6.png~")"; fi' \
    "$HOME/Screenshots" &
