#!/bin/sh
set -euf

# TODO: package into separate project

args=''
if [ "${#}" -ge '1' ]; then
    args="${*}"
fi

curl -L -s "https://gitignore.io/api/${args}"
