#!/bin/sh
set -euf

# First collect URLs to download
browser='Safari'
current_date="$(date -u +'%Y-%m-%dT%H:%M:%S')"

is_running="$(osascript -e "tell application \"System Events\" to (name of processes) contains \"$browser\"")"
if [ "$is_running" != 'true' ]; then
    printf '%s,0\n' "$current_date"
    exit 0
fi

windows_count="$(osascript -e "tell application \"$browser\" to get number of windows")"
total_tab_count=0
window_i=1
while [ "$window_i" -le "$windows_count" ]; do
    tabs_count="$(osascript -e "tell application \"$browser\" to get number of tabs in window $window_i")"
    total_tab_count="$((total_tab_count + tabs_count))"
    window_i="$((window_i + 1))"
done

printf '%s,%s\n' "$current_date" "$total_tab_count"
