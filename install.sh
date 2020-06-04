#!/bin/sh
set -euf
cd "$(dirname "${0}")"

sh 'home/install.sh'
sh 'setup/install.sh'
sh 'dependencies/install-system.sh'
sh 'dependencies/install-other.sh'
