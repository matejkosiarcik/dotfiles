#!/bin/sh
set -euf
cd "$(dirname "${0}")"

reload() {
    rm -f "${HOME}/.${1}"
    ln -s "${PWD}/${1}" "${HOME}/.${1}"
}

reload 'config.sh'
reload 'config.bash'
reload 'config.zsh'
