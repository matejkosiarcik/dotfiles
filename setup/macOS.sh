# shellcheck shell=sh
# This file setups fresh macOS installation
set -euf

#
# General system setup
#

# show ~/Library
chflags nohidden "${HOME}/Library"

# symlink iOS simulator to applications
sudo ln -sf '/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app' '/Applications/iOS Simulator.app'

# set system to restart when it freezes
sudo systemsetup -setrestartfreeze on

# disable startup sound
sudo nvram SystemAudioVolume=' '

#
# Modifying defaults to applications
#

# do not create .DS_Store on network volumes
defaults write 'com.apple.desktopservices' DSDontWriteNetworkStores -bool true

# show whitespace in xcode
defaults write 'com.apple.dt.xcode' DVTTextShowInvisibleCharacters -int 1

# show hidden files in finder
defaults write 'com.apple.dinder' AppleShowAllFiles -bool true

# do not warn before emptying trash
defaults write 'com.apple.finder' WarnOnEmptyTrash -bool false

# show path bar (bottom)
defaults write 'com.apple.finder' ShowPathbar -bool true

# display full POSIX path as window title\
defaults write 'com.apple.finder' _FXShowPosixPathInTitle -bool true

# disable warning when changing a file extension
defaults write 'com.apple.finder' FXEnableExtensionChangeWarning -bool false

# copy address as 'foo@bar.com' instead of 'Foo <foo@bar.com>'
defaults write 'com.apple.mail' AddressesIncludeNameOnPasteboard -bool false

# save file as UTF-8
defaults write 'com.apple.textedit' PlainTextEncoding -int 4
defaults write 'com.apple.textedit' PlainTextEncodingForWrite -int 4

# save new files in plain text
defaults write 'com.apple.textedit' RichText -int 0

# do not ask to backup into new disk
defaults write 'com.apple.timemachine' DoNotOfferNewDisksForBackup -bool true

#
# Modifying defaults of whole system
#

# show filename extensions
defaults write 'NSGlobalDomain' AppleShowAllExtensions -bool true

# disable this "smart" witchcraft
defaults write 'NSGlobalDomain' NSAutomaticDashSubstitutionEnabled -bool false
defaults write 'NSGlobalDomain' NSAutomaticQuoteSubstitutionEnabled -bool false

# disable autocorrect
defaults write 'NSGlobalDomain' NSAutomaticSpellingCorrectionEnabled -bool false

# disable automatic termination of inactive apps
defaults write 'NSGlobalDomain' NSDisableAutomaticTermination -bool true

# expand save panel by default
defaults write 'NSGlobalDomain' NSNavPanelExpandedStateForSaveMode -bool true

# quit windows when quitting app
defaults write 'NSGlobalDomain' NSQuitAlwaysKeepsWindows -bool false
