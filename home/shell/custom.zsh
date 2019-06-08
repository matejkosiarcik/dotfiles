# shellcheck shell=bash
# shellcheck source=/dev/null # do not look for sourced files

source "${HOME}/.custom.sh"

# can not be in ".sh", because builtin is not available in classic sh
cd() {
    builtin cd "${@}" && ls -A >&2
}
