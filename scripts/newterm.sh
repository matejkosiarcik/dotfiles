#!/bin/sh
set -euf

# This scripts opens new Terminal window
# Best usable as a key shortcut (using ie. iCanHazShortcut)
osascript <<EOF
tell app "System Events"
    if (get name of every application process) contains "Terminal" then
        tell app "Terminal" to do script ""
    else
        tell app "Terminal" to activate
    end if
end tell
EOF
