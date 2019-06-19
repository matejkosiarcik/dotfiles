# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

case "$(uname -s)" in
'Darwin') sh 'macOS.sh' ;;
esac

# TODO: make it compatible with linux
if [ "$(uname -s)" == "Darwin" ]; then
    while IFS="" read -r line; do
        duti -s 'com.microsoft.VSCode' "${line}" all
    done <'textfiles.txt'

    while IFS="" read -r line; do
        duti -s 'org.videolan.vlc' "${line}" all
    done <'mediafiles.txt'
fi
