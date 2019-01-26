# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

sh 'default.sh'
case "$(uname -s)" in
'Darwin') sh 'macOS.sh' ;;
esac
