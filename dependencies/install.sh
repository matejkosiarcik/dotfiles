# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

# mac/homebrew
case "$(uname -s)" in
'Darwin') brew bundle ;;
esac

# node/npm
while IFS='' read -r line; do
    npm install -g "${line}"
done <'npm.txt'

# python/pip
pip3 install -r 'requirements.txt'
