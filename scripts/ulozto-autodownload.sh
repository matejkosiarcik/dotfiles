#!/bin/sh
set -euf

windows_count="$(osascript -e 'tell application "Safari" to get number of windows')"
printf 'Windows: %s\n' "${windows_count}"

urls_file="$(mktemp)"
window_i=1
while [ "${window_i}" -le "${windows_count}" ]; do
    tabs_count="$(osascript -e "tell application \"Safari\" to get number of tabs in window ${window_i}")"
    printf 'Tabs: %s in Window %s\n' "${tabs_count}" "${window_i}"

    tab_i=1
    while [ "${tab_i}" -le "${tabs_count}" ]; do
        osascript -e "tell application \"Safari\" to get URL of tab ${tab_i} of window ${window_i}" >>"${urls_file}"
        tab_i="$(expr "${tab_i}" + 1)"
    done

    window_i="$(expr "${window_i}" + 1)"
done

i=0
limit=4 # limit to not open tens of downloads simultaneously
grep -E '^https://uloz.to/file/' <"${urls_file}" | while read -r url && [ "${i}" -lt "${limit}" ]; do
    # this opens the script in a new Terminal.app window
    osascript -e "tell application \"Terminal\" to do script \"uloztod ${url}\""

    # when opening multiple ulozto download at once
    # it seems to fail with tor-socker-timeout
    # so manual timeout should help it
    sleep 60

    i="$(expr "${i}" + 1)"
done
rm -f "${urls_file}"
