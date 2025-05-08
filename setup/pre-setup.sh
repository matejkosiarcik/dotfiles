#!/bin/sh
set -euf

rm -rf "$HOME/.config/matejkosiarcik"
mkdir -p "$HOME/.config/matejkosiarcik" "$HOME/.log"

# Clean old scripts
rm -rf "$HOME/.bin"

# Setup directories
mkdir -p "$HOME/.lftp" "$HOME/.bin"
