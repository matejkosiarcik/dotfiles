# shellcheck shell=sh
set -euf

[ -d "${HOME}/bin" ] || mkdir "${HOME}/bin"
cd "$(dirname "${0}")"

install() {
    cp "${1}.sh" "${HOME}/bin/${1}"
    chmod +x "${HOME}/bin/${1}"
}

install 'azfmt'
install 'azlint'
install 'cldir'
