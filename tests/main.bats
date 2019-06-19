#!/usr/bin/env bats

@test 'shell - bash' {
    run bash -c 'source home/shell/custom.bash'
    [ "${status}" -eq '0' ]
    [ "${output}" == '' ]

    run bash -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" == '' ]
}

@test 'shell - sh' {
    run sh -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" == '' ]
}

@test 'shell - zsh' {
    run zsh -c 'source home/shell/custom.zsh'
    [ "${status}" -eq '0' ]
    [ "${output}" == '' ]

    run zsh -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" == '' ]
}
