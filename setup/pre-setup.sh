#!/bin/sh
set -euf

# Clean old scripts
rm -rf "$HOME/.bin"

# Setup directories
mkdir -p "$HOME/.lftp" "$HOME/.bin"
