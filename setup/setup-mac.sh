#!/bin/sh
# This file setups fresh macOS installation
# Inspirations:
# - https://github.com/mathiasbynens/dotfiles

set -euf

# Close any open System Preferences panes, to prevent them from overriding
# settings we're about to change
osascript -e 'tell application "System Preferences" to quit'

#
# General system setup
#

# Show ~/Library
chflags nohidden "$HOME/Library"

# Show /Volumes
sudo chflags nohidden /Volumes

# Set system to restart when it freezes
sudo systemsetup -setrestartfreeze on

# Disable startup sound
sudo nvram SystemAudioVolume=' '

#
## Global ##
#

# Quit all windows when quitting app
defaults write 'NSGlobalDomain' NSQuitAlwaysKeepsWindows -bool false

# Expand save panel by default
defaults write 'NSGlobalDomain' NSNavPanelExpandedStateForSaveMode -bool true
defaults write 'NSGlobalDomain' NSNavPanelExpandedStateForSaveMode2 -bool true

# Do not ask to backup into new disk
defaults write 'com.apple.timemachine' DoNotOfferNewDisksForBackup -bool true

# Save to disk, not iCloud
defaults write 'NSGlobalDomain' NSDocumentSaveNewDocumentsToCloud -bool false

#
## Keyboard/Typing ##
#

# Disable this "smart" quoting witchcraft
defaults write 'NSGlobalDomain' NSAutomaticDashSubstitutionEnabled -bool false
defaults write 'NSGlobalDomain' NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable autocorrect
defaults write 'NSGlobalDomain' NSAutomaticSpellingCorrectionEnabled -bool false

#
## Dock ##
#

# Highlight hover effect
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Show at botton of the screen
defaults write com.apple.dock orientation -string bottom

# Set icon size for Dock items
defaults write com.apple.dock tilesize -int 48

# Change minimize/maximize window effect
defaults write com.apple.dock mineffect -string 'scale'

# Minimize windows into their app's icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open apps
defaults write com.apple.dock show-process-indicators -bool true

# Wipe all default apps
defaults write com.apple.dock persistent-apps -array

# Always show dock
defaults write com.apple.dock autohide -bool false

# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false

#
## Finder ##
#

# Do not create .DS_Store on network volumes
defaults write 'com.apple.desktopservices' DSDontWriteNetworkStores -bool true

# Show filename extensions
defaults write 'NSGlobalDomain' AppleShowAllExtensions -bool true

# Show hidden files in finder
defaults write 'com.apple.finder' AppleShowAllFiles -bool true

# Do not warn before emptying trash
defaults write 'com.apple.finder' WarnOnEmptyTrash -bool false

# Show path bar (bottom)
defaults write 'com.apple.finder' ShowPathbar -bool true

# Display full POSIX path as window title
defaults write 'com.apple.finder' _FXShowPosixPathInTitle -bool true

# Disable warning when changing a file extension
defaults write 'com.apple.finder' FXEnableExtensionChangeWarning -bool false

# Big sidebar icons
defaults write 'NSGlobalDomain' NSTableViewDefaultSizeMode -int 3

# Show icons immediately in header
defaults write 'NSGlobalDomain' NSToolbarTitleViewRolloverDelay -float 0

#
## Screenshots ##
#
screenshots_dir="$HOME/Pictures/Screenshots"
mkdir -p "$screenshots_dir"

# No shadows
defaults write 'com.apple.screencapture' disable-shadow -bool false

# Change location
defaults write 'com.apple.screencapture' location -string "$screenshots_dir"

# Save screenshot immediately
defaults write 'com.apple.screencapture' show-thumbnail -bool false

# Default name
defaults write 'com.apple.screencapture' name 'Screenshot'

#
## Safari ##
#

# Disable opening "safe" files after download
defaults write 'com.apple.Safari' AutoOpenSafeDownloads -bool false

#
## Xcode ##
#

# Show whitespace in xcode
defaults write 'com.apple.dt.xcode' DVTTextShowInvisibleCharacters -int 1

#
## Unused Apple apps ;) ##
#

# Copy address as 'foo@bar.com' instead of 'Foo <foo@bar.com>'
defaults write 'com.apple.mail' AddressesIncludeNameOnPasteboard -bool false

# Save files as UTF-8
defaults write 'com.apple.textedit' PlainTextEncoding -int 4
defaults write 'com.apple.textedit' PlainTextEncodingForWrite -int 4

# Save new files in plain text
defaults write 'com.apple.textedit' RichText -int 0

#
# Reload changes
#

killall Finder
killall SystemUIServer
killall Dock

printf 'Some apps (Mail, TextEdit, Xcode) may need a restart to see changes.\n'
