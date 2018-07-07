#!/bin/sh
set -euf

args=''
if [ "${#}" -ge '1' ]; then
    args="${@}"
fi

curl -L -s "https://www.gitignore.io/api/${args}"
