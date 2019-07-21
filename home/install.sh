#!/bin/sh
set -euf
cd "$(dirname "${0}")"

# Install subfolders
sh 'git/install.sh'
sh 'shell/install.sh'

# Reload individual files
reload() {
    rm -f "${HOME}/${1}"
    cp "${1}" "${HOME}/${1}"
}

reload '.emacs'
reload '.tigrc'
reload '.vimrc'

# Reload nested files
reload_nested() {
    mkdir -p "$(dirname "${HOME}/${1}")"
    reload "${1}"
}

reload_nested '.gnupg/gpg.conf'
reload_nested '.lftp/rc'
