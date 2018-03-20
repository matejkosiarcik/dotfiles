# shellcheck shell=sh
# This file setups fresh macOS installation
set -euf

# show hidden files in finder
defaults write 'com.apple.Finder' 'AppleShowAllFiles' true
killall 'Finder'

# show whitespace in xcode
defaults write 'com.apple.dt.Xcode' 'DVTTextShowInvisibleCharacters' 1
killall 'Xcode'
