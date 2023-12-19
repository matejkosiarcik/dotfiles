#!/bin/sh
set -euf
cd "$(dirname "${0}")"

case "$(uname -s)" in
'Darwin') sh 'setup-mac.sh' ;;
*) true ;;
esac

sh './default-programs/setup.sh'
