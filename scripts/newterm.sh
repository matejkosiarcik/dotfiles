#!/bin/sh
set -euf

# This scripts opens new Terminal window
# Usable as a ket shortcut
osascript -e 'tell app "Terminal" to activate'
osascript -e 'tell app "Terminal" to do script ""'
