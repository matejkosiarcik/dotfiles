# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

reload() {
    rm -f "${HOME}/${1}"
    cp "${1}" "${HOME}/${1}"
}

reload '.bashrc'
reload '.emacs'
reload '.gitconfig'
reload '.lftp/rc'
reload '.profile'
reload '.tigrc'
reload '.vimrc'
reload '.zshrc'

# load platform dependent gitconfig
rm -f "${HOME}/.gitconfig_platform"
case "$(uname -s)" in
'Darwin') cp '.gitconfig_macos' "${HOME}/.gitconfig_platform" ;;
esac
