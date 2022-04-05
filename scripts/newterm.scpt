#!/usr/bin/env osascript

-- This scripts opens new Terminal window
-- Best usable as a key shortcut (using ie. iCanHazShortcut)

if application "Terminal" is running then
    tell app "Terminal"
        do script ""
        delay 0.1
        activate
    end tell
else
    tell app "Terminal" to activate
end if
