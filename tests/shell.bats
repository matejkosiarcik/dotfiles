#!/usr/bin/env bats

@test 'config - sh' {
    for shell in sh bash; do
        if [ "${shell}" = 'zsh' ] && [ "${DISABLE_ZSH}" = 'true' ]; then
            continue;
        fi

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
    if [ "${DISABLE_ZSH}" = 'true' ]; then
        continue;
    fi

    run zsh -c 'source home/shell/config.zsh'
    [ "${status}" -eq '0' ]

    run zsh -c 'source home/shell/config.sh'
    [ "${status}" -eq '0' ]
}
