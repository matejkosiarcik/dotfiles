# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"
[ -d "${HOME}/bin" ] || mkdir "${HOME}/bin"

install() {
    cp "${1}.sh" "${HOME}/bin/${1}"
    chmod a+x "${HOME}/bin/${1}"
}

install 'cldir'
install 'fmt'
install 'gitignore'
install 'lint'
install 'update'
