#!/bin/sh
set -euf
cd "$(dirname "${0}")"

# Install subfolders
sh 'git/install.sh'
sh 'shell/install.sh'

# Reload individual files
reload() {
    rm -f "$HOME/${1}"
    ln -s "$PWD/${1}" "$HOME/${1}"
}

reload '.emacs'
reload '.tigrc'
reload '.vimrc'

if [ -d "$HOME/.gnupg" ]; then
    reload '.gnupg/gpg.conf'
    reload '.gnupg/gpg-agent.conf'
fi

# Reload nested files
reload_nested() {
    mkdir -p "$(dirname "$HOME/${1}")"
    reload "${1}"
}

reload_nested '.lftp/rc'
