#!/bin/sh
set -euf
cd "$(dirname "${0}")"

while IFS="" read -r line; do
    duti -s 'com.microsoft.VSCode' "${line}" all
done <'textfiles.txt'

while IFS="" read -r line; do
    duti -s 'org.videolan.vlc' "${line}" all
done <'mediafiles.txt'
