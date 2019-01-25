# shellcheck shell=sh
set -euf
cd "$(dirname "${0}")"

output="${HOME}/.custom-user-scripts"
if [ -d "${output}" ]; then
    rm -rf "${output}"
fi
mkdir "${output}"

install() {
    cp "${1}.sh" "${output}/${1}"
    chmod a+x "${output}/${1}"
}

install 'cldir'
install 'fmt'
install 'gitignore'
install 'lint'
install 'g-update'
