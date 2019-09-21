#!/bin/sh
set -euf
cd "$(dirname "${0}")"

find '.' -name 'install.sh' -depth 2 -exec sh {} \;
