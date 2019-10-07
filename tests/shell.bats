#!/usr/bin/env bats

function setup() {
    cd "$(dirname "${BATS_TEST_FILENAME}")/.." || exit 1
}

@test 'config - sh' {
    for shell in sh ksh mksh dash bash zsh yash; do
        if ! command -v "${shell}" >/dev/null 2>&1; then
            printf 'Skipping %s\n' "${shell}" >&3
            continue
        fi
        printf 'Testing %s\n' "${shell}" >&3

        run "${shell}" -c '. home/shell/config.sh'
        [ "${status}" -eq '0' ]

        run "${shell}" 'home/shell/config.sh'
        [ "${status}" -eq '0' ]
    done
}

@test 'config - bash' {
    run bash -c 'source home/shell/config.bash'
    [ "${status}" -eq '0' ]

    run bash 'home/shell/config.bash'
    [ "${status}" -eq '0' ]
}

@test 'config - zsh' {
    if ! command -v zsh >/dev/null 2>&1; then
        skip
    fi

    run zsh -c 'source home/shell/config.zsh'
    [ "${status}" -eq '0' ]

    run zsh 'home/shell/config.zsh'
    [ "${status}" -eq '0' ]
}
