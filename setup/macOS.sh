#!/bin/sh
# This file setups fresh macOS installation
set -euf
sudo -v

# Close any open System Preferences panes, to prevent them from overriding
# settings we're about to change
osascript -e 'tell application "System Preferences" to quit'

#
# General system setup
#

# show ~/Library
chflags nohidden "${HOME}/Library"

# show /Volumes
sudo chflags nohidden /Volumes

# set system to restart when it freezes
sudo systemsetup -setrestartfreeze on

# disable startup sound
sudo nvram SystemAudioVolume=' '

#
## Global ##
#

# quit windows when quitting app
defaults write 'NSGlobalDomain' NSQuitAlwaysKeepsWindows -bool false

# expand save panel by default
defaults write 'NSGlobalDomain' NSNavPanelExpandedStateForSaveMode -bool true
defaults write 'NSGlobalDomain' NSNavPanelExpandedStateForSaveMode2 -bool true

# do not create .DS_Store on network volumes
defaults write 'com.apple.desktopservices' DSDontWriteNetworkStores -bool true

# do not ask to backup into new disk
defaults write 'com.apple.timemachine' DoNotOfferNewDisksForBackup -bool true

#
## Keyboard ##
#

# disable this "smart" quoting witchcraft
defaults write 'NSGlobalDomain' NSAutomaticDashSubstitutionEnabled -bool false
defaults write 'NSGlobalDomain' NSAutomaticQuoteSubstitutionEnabled -bool false

# disable autocorrect
defaults write 'NSGlobalDomain' NSAutomaticSpellingCorrectionEnabled -bool false

#
## Dock ##
#

# highlight hover effect
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# set icon size for Dock items 36px
defaults write com.apple.dock tilesize -int 36

# change minimize/maximize window effect
defaults write com.apple.dock mineffect -string 'scale'

# minimize windows into their app's icon
defaults write com.apple.dock minimize-to-application -bool true

# enable spring loading
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# show indicator lights for open apps
defaults write com.apple.dock show-process-indicators -bool true

# wipe all default apps
defaults write com.apple.dock persistent-apps -array

# always show dock
defaults write com.apple.dock autohide -bool false

# don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false

#
## Finder ##
#

# show filename extensions
defaults write 'NSGlobalDomain' AppleShowAllExtensions -bool true

# show hidden files in finder
defaults write 'com.apple.finder' AppleShowAllFiles -bool true

# do not warn before emptying trash
defaults write 'com.apple.finder' WarnOnEmptyTrash -bool false

# show path bar (bottom)
defaults write 'com.apple.finder' ShowPathbar -bool true

# display full POSIX path as window title
defaults write 'com.apple.finder' _FXShowPosixPathInTitle -bool true

# disable warning when changing a file extension
defaults write 'com.apple.finder' FXEnableExtensionChangeWarning -bool false

# sidebar icon size
defaults write 'NSGlobalDomain' NSTableViewDefaultSizeMode -int 2

#
## Safari ##
#

# disable opening "safe" files after download
defaults write 'com.apple.Safari' AutoOpenSafeDownloads -bool false

#
## Xcode ##
#

# show whitespace in xcode
defaults write 'com.apple.dt.xcode' DVTTextShowInvisibleCharacters -int 1

#
## Unused Apple apps ;) ##
#

# copy address as 'foo@bar.com' instead of 'Foo <foo@bar.com>'
defaults write 'com.apple.mail' AddressesIncludeNameOnPasteboard -bool false

# save files as UTF-8
defaults write 'com.apple.textedit' PlainTextEncoding -int 4
defaults write 'com.apple.textedit' PlainTextEncodingForWrite -int 4

# save new files in plain text
defaults write 'com.apple.textedit' RichText -int 0

#
# Reload changes
#

killall Finder

printf 'Some apps (Mail, TextEdit, Xcode) may need a restart to see changes.\n'
