#!/bin/sh
set -euf

if [ '$(shell uname)' == 'Darwin' ] && [ -f 'Brewfile' ]; then
    brew bundle
fi

if [ -f '.gitman.yml' ]; then
	gitman install
fi

if [ -f 'requirements.txt' ]; then
    pip install -r 'requirements.txt'
    if command -v pip2 >/dev/null 2>&1; then
        pip2 install -r 'requirements.txt'
    fi
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install -r 'requirements.txt'
    fi
fi

if [ -f 'package.json' ]; then
    npm install
fi

if [ -f 'Cartfile' ]; then
	carthage bootstrap --no-use-binaries
fi

if [ -f 'Gemfile' ]; then
    bundle install
fi

if [ -f 'bower.json' ]; then
    bower install
fi
