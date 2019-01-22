# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

sh 'bin/install.sh'
sh 'home/install.sh'
sh 'setup/install.sh'
