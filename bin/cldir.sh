#!/bin/sh
set -euf

# TODO: example usage
# TODO: help page
# TODO: make dry run

path='.'
# TODO: make cleaning for all supplied paths
if [ "${#}" -ge 1 ]; then
    path="${1}"
fi

### System Level stuff ###

dot_clean -m "${path}"                                      # for ._* files # macOS, BSD
find "${path}" -name '.DS_Store' -type f -exec rm -f {} \;  # macOS
find "${path}" -name '.localized' -type f -exec rm -f {} \; # macOS
find "${path}" -name 'Thumbs.db' -type f -exec rm -f {} \;  # Windows

### Development build files ###

find "${path}" -name 'build' -type d -exec rm -rf {} \; # General
find "${path}" -name '.build' -type d -exec rm -rf {} \; # SPM
find "${path}" -name 'node_modules' -type d -exec rm -rf {} \; # NPM
find "${path}" -name 'Pods' -type d -exec rm -rf {} \; # CocoaPods
find "${path}" -name 'Carthage' -type d -exec rm -rf {} \; # Carthage
find "${path}" -name 'target' -type d -exec rm -rf {} \; # Rust
find "${path}" -name 'CmakeFiles' -type d -exec rm -rf {} \; # Cmake
find "${path}" -name 'fastlane/screenshots' -type d -exec rm -rf {} \; # Carthage

# '.build|.git|.venv|*.xcodeproj|bower_components|build|external|Carthage|CMakeFiles|CMakeScripts|node_modules|Pods|target|vendor|venv'
