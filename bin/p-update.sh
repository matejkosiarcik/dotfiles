#!/bin/sh
set -euf

if [ '$(shell uname)' == 'Darwin' ] && [ -f 'Brewfile' ]; then
    brew bundle
fi

if [ -f '.gitman.yml' ]; then
    gitman update
fi

if [ -f 'requirements.txt' ]; then
    pip install -r 'requirements.txt' --upgrade
    if command -v pip2 >/dev/null 2>&1; then
        pip2 install -r 'requirements.txt' --upgrade
    fi
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install -r 'requirements.txt' --upgrade
    fi
fi

if [ -f 'package.json' ]; then
    npm update
fi

if [ -f 'Cartfile' ]; then
    carthage update --no-use-binaries
fi

if [ -f 'Gemfile' ]; then
    bundle update --all
fi

if [ -f 'bower.json' ]; then
    bower update
fi
