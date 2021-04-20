#!/bin/sh
set -euf

# This script works mostly:
# - Takes open uloz.to URLs in a browser of your choice
# - Open each URL in a new Terminal.app window using ulozto-downloader

print_help() {
    printf 'ulozto-autodownload\n'
    printf '%s\n' '-h           Get help'
    printf '%s\n' '-b <string>  Browser to get links from. Default: Safari'
    printf '%s\n' '-l <int>     Limit max no. new downloads. Default: 1'
}

# parse arguments
limit=1
browser='Safari'
while getopts "h?l:b:" opt; do
    case "$opt" in
    h)
        print_help
        exit 0
        ;;
    b) browser="$OPTARG" ;;
    l) limit="$OPTARG" ;;
    *)
        printf 'Unsupported argument.' >&2
        exit 1
        ;;
    esac
done

# helper file for collecting URLs
urls_file="$(mktemp)"
trap 'rm -rf "${urls_file}"; trap - EXIT; exit' EXIT INT HUP TERM

# First collect URLs to download
printf 'Checking %s\n' "$browser" >&2
windows_count="$(osascript -e "tell application \"$browser\" to get number of windows")"
printf 'Got %s open windows\n' "$windows_count" >&2
window_i=1
while [ "$window_i" -le "$windows_count" ]; do
    tabs_count="$(osascript -e "tell application \"$browser\" to get number of tabs in window $window_i")"
    printf 'Got %s tabs in window %s\n' "$tabs_count" "$window_i"

    tab_i=1
    while [ "$tab_i" -le "$tabs_count" ]; do
        osascript -e "tell application \"$browser\" to get URL of tab $tab_i of window $window_i" | { grep -E '^https://uloz.to/file/' || true; } >>"$urls_file"
        tab_i="$((tab_i + 1))"
    done

    window_i="$((window_i + 1))"
done

# Download collected URLs
if [ "$(wc -l <"$urls_file")" -gt 0 ]; then
    i=0
    sort <"$urls_file" | uniq | while read -r url && [ "$i" -lt "$limit" ]; do
        # download the file in new Terminal.app window
        osascript -e "tell application \"Terminal\" to do script \"cd ~/Downloads && uloztod \\\"$url\\\"\""

        # close the tab afterwards
        osascript -e "tell application \"$browser\" to close every tab of every window whose url equals \"$url\""

        # when opening multiple simultaneous ulozto downloads at once
        # it seems to fail with tor-socker-timeout
        # so manual timeout should help it not overload this service hopefully
        sleep 60

        i="$((i + 1))"
    done
else
    printf 'No URLs found.\n' >&2
fi
