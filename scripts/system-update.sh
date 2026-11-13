#!/bin/sh
set -euf
# This file updates all package-managers
# both system type and language specific

cd "${HOME}" # to be sure we don't update project instead of system

# Define portable datetime format
date_supports_milliseconds="$(date '+%3N' 2>&1)"
case "${date_supports_milliseconds}" in
[0-9][0-9][0-9]) milliseconds_format="%3N" ;;
*) milliseconds_format="000" ;;
esac
datetime_format="+%Y-%m-%dT%H:%M:%S.${milliseconds_format}Z"

log() {
    # $1 - log level
    # $2+ - message

    log_level="${1}"
    shift
    log_timestamp="$(date "${datetime_format}")"
    printf '%s\n' "${*}" | while IFS= read -r log_message; do
        printf '%s [%s]: %s\n' "${log_timestamp}" "${log_level}" "${log_message}"
    done >&2
}

run_update_command() (
    update_command_name="${1}"
    if [ "${#}" -gt 1 ]; then
        update_command_name="${update_command_name} ${2}"
    fi
    update_command_logfile="$(mktemp)"
    trap 'rm -f "${update_command_logfile}"' 0 HUP INT TERM

    if "${@}" >"${update_command_logfile}" 2>&1; then
        return
    else
        update_command_status="${?}"
    fi

    log ERROR "Command \"${update_command_name}\" failed, captured output follows:" >&2
    cat "${update_command_logfile}" | sed -E 's~^~  > ~' >&2
    exit "${update_command_status}"
)

run_update_command_and_ignore_status() (
    update_command_name="${1}"
    if [ "${#}" -gt 1 ]; then
        update_command_name="${update_command_name} ${2}"
    fi
    update_command_logfile="$(mktemp)"
    trap 'rm -f "${update_command_logfile}"' 0 HUP INT TERM

    if "${@}" >"${update_command_logfile}" 2>&1; then
        return
    else
        update_command_status="${?}"
    fi

    log WARNING "Command \"${update_command_name}\" failed, captured output follows:" >&2
    cat "${update_command_logfile}" | sed -E 's~^~  > ~' >&2
    log WARNING 'Ignoring failure and continuing' >&2
)

log_missing_command() {
    printf '%s\n' "Skipping $1: command not found" >&2
}

if command -v brew >/dev/null 2>&1; then
    if [ "$(uname -s)" = 'Linux' ]; then
        brew_name='LinuxBrew'
    elif [ "$(uname -s)" = 'Darwin' ]; then
        brew_name='HomeBrew'
    else
        brew_name='UnknownBrew'
    fi
    log INFO 'Updating' "${brew_name}"
    run_update_command brew update --quiet --force
    run_update_command brew upgrade --quiet --overwrite --yes
    run_update_command brew cleanup --quiet
else
    log_missing_command 'brew'
fi

### System package managers ###

if [ "$(uname -s)" = 'Darwin' ]; then
    true
    # if command -v softwareupdate >/dev/null 2>&1; then
    #     log INFO 'Updating macOS (softwareupdate)'
    #     run_update_command softwareupdate --install --all --agree-to-license --force
    # else
    #     log_missing_command 'softwareupdate'
    # fi
elif [ "$(uname -s)" = 'Linux' ]; then
    if command -v yum >/dev/null 2>&1 && ! command -v dnf >/dev/null 2>&1; then
        log INFO 'Updating Linux - Yum'
        run_update_command yum update
        run_update_command yum upgrade
    fi

    if command -v apt-get >/dev/null 2>&1; then
        log INFO 'Updating Linux - Apt'
        run_update_command apt-get update -qq
        run_update_command env DEBIAN_FRONTEND=noninteractive DEBCONF_TERSE=yes DEBCONF_NOWARNINGS=yes apt-get upgrade -qq --yes
        run_update_command apt-get clean -qq
    elif command -v apk >/dev/null 2>&1; then
        log INFO 'Updating Linux - Apk'
        run_update_command apk update --no-cache
    elif command -v dnf >/dev/null 2>&1; then
        log INFO 'Updating Linux - Dnf'
        run_update_command dnf upgrade -y
    elif command -v pacman >/dev/null 2>&1; then
        log INFO 'Updating Linux - Pacman'
        run_update_command pacman --noconfirm -Suy python python-pip make
    elif command -v swupd >/dev/null 2>&1; then
        log INFO 'Updating Linux - Swupd'
        run_update_command swupd update
    elif command -v zypper >/dev/null 2>&1; then
        log INFO 'Updating Linux - Zypper'
        run_update_command zypper update
    else
        printf '%s\n' 'Skipping system package updates: no supported package manager found' >&2
    fi
elif [ "$(uname -s)" = 'Windows' ]; then
    if command -v choco >/dev/null 2>&1; then
        log INFO 'Updating Windows - Chocolatey'
        run_update_command choco upgrade chocolatey
        run_update_command choco upgrade all
    else
        log_missing_command 'choco'
    fi
fi

### JavaScript ###

if command -v npm >/dev/null 2>&1; then
    log INFO 'Updating NodeJS - NPM'

    ORIGINAL_NODE_OPTIONS="${NODE_OPTIONS:-}"
    if [ -z "${ORIGINAL_NODE_OPTIONS}" ]; then
        NODE_OPTIONS='--dns-result-order=ipv4first'
    elif printf '%s\n' "${ORIGINAL_NODE_OPTIONS}" | grep -v -- '--dns-result-order=ipv4first' >/dev/null; then
        NODE_OPTIONS="${ORIGINAL_NODE_OPTIONS} --dns-result-order=ipv4first"
    else
        NODE_OPTIONS="${ORIGINAL_NODE_OPTIONS}"
    fi
    export NODE_OPTIONS

    run_update_command npm update -g

    NODE_OPTIONS="${ORIGINAL_NODE_OPTIONS}"
    export NODE_OPTIONS
else
    log_missing_command 'npm'
fi

### Python ###

# The option `--break-system-packages` is necessary for externally managed pip environments
# Here is related discussion for HomeBrew: https://github.com/orgs/Homebrew/discussions/3404
# if command -v python3 >/dev/null 2>&1; then
#     log INFO 'Updating Python - Pip'
#     pip_extra_args=''
#     if command -v python3 2>/dev/null | grep -i homebrew; then
#         pip_extra_args='--break-system-packages'
#     fi
#     # shellcheck disable=SC2248
#     run_update_command python3 -m pip install --quiet --upgrade pip setuptools wheel ${pip_extra_args}
#     update_outdated_pip_packages() {
#         # shellcheck disable=SC2248
#         python3 -m pip list --outdated | tail -n +3 | cut -d ' ' -f 1 | xargs -n1 python3 -m pip install --quiet --upgrade ${pip_extra_args}
#     }
#     run_update_command update_outdated_pip_packages
# else
#     log_missing_command 'python3'
# fi

# Pipx
if command -v pipx >/dev/null 2>&1; then
    log INFO 'Updating Python - Pipx'
    run_update_command pipx upgrade-all
else
    log_missing_command 'pipx'
fi

### Ruby ###

# if command -v gem >/dev/null 2>&1; then
#     log INFO 'Updating Ruby - Gems'
#     run_update_command gem update --system --quiet
#     run_update_command gem update --quiet
# else
#     log_missing_command 'gem'
# fi

### Rust ###

if command -v rustup >/dev/null 2>&1; then
    log INFO 'Updating Rust - Rustup'
    run_update_command rustup update
    run_update_command_and_ignore_status rustup self update # when installed with package manager rustup fails to self-update
else
    log_missing_command 'rustup'
fi

if command -v cargo-install-update >/dev/null 2>&1; then
    log INFO 'Updating Rust - Cargo'
    run_update_command cargo install-update -a
else
    log_missing_command 'cargo-install-update'
fi

### Haskell ###

# if command -v cabal >/dev/null 2>&1; then
#     log INFO 'Updating Haskell - Cabal'
#     run_update_command cabal update
# else
#     log_missing_command 'cabal'
# fi

# if command -v stack >/dev/null 2>&1; then
#     log INFO 'Updating Haskell - Stack'
#     run_update_command stack update
# else
#     log_missing_command 'stack'
# fi
