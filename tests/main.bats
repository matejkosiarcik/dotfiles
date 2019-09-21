#!/usr/bin/env bats

@test 'shell - bash' {
    run bash -c 'source home/shell/config.bash'
    [ "${status}" -eq '0' ]

    run bash -c 'source home/shell/config.sh'
    [ "${status}" -eq '0' ]
}

@test 'shell - sh' {
    run sh -c '. home/shell/config.sh'
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
