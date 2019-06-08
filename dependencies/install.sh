# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

if command -v brew >/dev/null 2>&1; then
    brew bundle
fi

if command -v apt >/dev/null 2>&1; then
    apt install -y $(cat 'apt.txt' | grep -v "#"  | tr '\n' ' ')
fi

npm install -g $(cat 'npm.txt' | grep -v '#' | tr '\n' ' ')

pip3 install -r 'requirements.txt'
