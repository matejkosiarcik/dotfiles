# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

case "$(uname -s)" in
'Darwin') sh 'macOS.sh' ;;
esac
