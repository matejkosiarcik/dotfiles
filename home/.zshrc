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

source "${ZSH}/oh-my-zsh.sh"
