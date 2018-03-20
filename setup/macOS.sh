# shellcheck shell=sh
# This file setups fresh macOS installation
set -euf

# show hidden files in finder
defaults write 'com.apple.Finder' AppleShowAllFiles -bool true

# do not warn before emptying trash
defaults write 'com.apple.finder' WarnOnEmptyTrash -bool false

# show path bar (bottom)
defaults write 'com.apple.finder' ShowPathbar -bool true

# show filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# show ~/Library
chflags nohidden "${HOME}/Library"

# show whitespace in xcode
defaults write 'com.apple.dt.Xcode' DVTTextShowInvisibleCharacters -int 1

# save file as UTF-8
defaults write 'com.apple.TextEdit' PlainTextEncoding -int 4
defaults write 'com.apple.TextEdit' PlainTextEncodingForWrite -int 4

# save new files in plain text
defaults write 'com.apple.TextEdit' RichText -int 0

# do not ask to backup into new disk
defaults write 'com.apple.TimeMachine' DoNotOfferNewDisksForBackup -bool true

# copy address as 'foo@bar.com' instead of 'Foo <foo@bar.com>'
defaults write 'com.apple.TimeMachine' DoNotOfferNewDisksForBackup -bool true

# Symlink iOS simulator to applications
sudo ln -sf '/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app' '/Applications/iOS Simulator.app'

# set system to restart when it freezes
sudo systemsetup -setrestartfreeze on

# do not create .DS_Store on network volumes
defaults write 'com.apple.desktopservices' DSDontWriteNetworkStores -bool true

# disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# disable this witchcraft
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
