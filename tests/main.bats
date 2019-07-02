#!/usr/bin/env bats

@test 'shell - bash' {
    run bash -c 'source home/shell/custom.bash'
    [ "${status}" -eq '0' ]

    run bash -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
}

@test 'shell - sh' {
    run sh -c '. home/shell/custom.sh'
    [ "${status}" -eq '0' ]
}
