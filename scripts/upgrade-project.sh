#!/bin/sh
set -euf

# nodejs
ncu --deep -u

# pip requirements
# shellcheck disable=SC2016
find . -name 'requirements*.txt' -or -name '*requirements.txt' |
    xargs -0 sh -c 'printf "all\n" | pip-upgrade --skip-package-installation "$0"'
