#!/bin/sh
set -euf
cd "$(dirname "${0}")"

reload() {
    rm -f "${HOME}/.${1}"
    ln -s "${PWD}/${1}" "${HOME}/.${1}"
}

reload 'config-main.gitconfig'
reload 'config-personal.gitconfig'
reload 'config-touch4it.gitconfig'
