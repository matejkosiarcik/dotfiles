#!/bin/sh
set -euf
cd "$(dirname "${0}")"

reload() {
    rm -f "${HOME}/.${1}"
    ln -s "${PWD}/${1}" "${HOME}/.${1}"
}

reload 'custom.sh'
reload 'custom.bash'
reload 'custom.zsh'
