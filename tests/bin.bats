#!/usr/bin/env bats

@test 'bin - cldir' {
    for shell in sh ksh bash zsh; do
        if [ "${shell}" = 'zsh' ] && [ "${DISABLE_ZSH}" = 'true' ]; then
            continue;
        fi

        run "${shell}" -n 'bin/cldir.sh'
        [ "${status}" -eq '0' ]
        [ "${output}" = '' ]
    done
}
