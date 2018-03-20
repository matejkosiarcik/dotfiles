# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

reload() {
    rm -f "${HOME}/${1}"
    cp "${1}" "${HOME}/${1}"
}

reload '.bashrc'
reload '.profile'
reload '.tigrc'
reload '.vimrc'
reload '.zshrc'
