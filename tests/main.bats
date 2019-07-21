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

@test 'bin - cldir' {
    run bash -n 'bin/cldir.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]
}

@test 'install' {
    run bash -n 'install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run bash -n 'home/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run bash -n 'home/git/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run bash -n 'home/shell/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run bash -n 'setup/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run bash -n 'bin/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run bash -n 'dependencies/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]
}
