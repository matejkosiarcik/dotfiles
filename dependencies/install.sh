# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

## System-level package managers ##

if command -v brew >/dev/null 2>&1; then
    brew bundle
fi

if command -v apt >/dev/null 2>&1; then
    apt install -y $(cat 'apt.txt' | sed -E 's~(\s*)#(.*)~~' | grep -vE '^(\s*)$' | tr '\n' ' ')
fi

# TODO: yum install -y

## Language-specific package managers ##

npm install -g $(cat 'npm.txt' | sed -E 's~(\s*)#(.*)~~' | grep -vE '^(\s*)$' | tr '\n' ' ')

pip3 install -r 'requirements.txt'
