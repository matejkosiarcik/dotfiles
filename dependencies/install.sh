# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

case "$(uname -s)" in
'Darwin') brew bundle ;;
esac

if command -v npm >/dev/null 2>&1; then
    while IFS='' read -r line; do
        npm install -g "${line}"
    done <'npm.txt'
fi

if command -v pip3 >/dev/null 2>&1; then
    pip3 install -r 'requirements.txt'
fi
