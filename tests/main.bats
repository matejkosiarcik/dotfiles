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
    run find '.' -name 'install.sh' -exec bash -n {} \;
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]
}
