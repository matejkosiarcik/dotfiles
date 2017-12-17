# shellcheck shell=bash
# shellcheck source=/dev/null
# shellcheck disable=SC2034
source "${HOME}/.profile"
export ZSH="${HOME}/.oh-my-zsh"

unsetopt nomatch
plugins=(brew git osx zsh-autosuggestions zsh-syntax-highlighting)

ZSH_THEME="robbyrussell"
HIST_STAMPS="yyyy-mm-dd"
# DISABLE_LS_COLORS="true"
# DISABLE_AUTO_TITLE="true"
# ENABLE_CORRECTION="true"
# COMPLETION_WAITING_DOTS="true"

# has to be after plugins and variable definitions
source "${ZSH}/oh-my-zsh.sh"

# can not be in ".profile", because builtin is not available in classic sh
cd() {
    builtin cd "${@}" && ls -A >&2
}
