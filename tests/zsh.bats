@test 'shell - zsh' {
    run zsh -c 'source home/shell/custom.zsh'
    [ "${status}" -eq '0' ]

    run zsh -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
}

@test 'bin - cldir' {
    run zsh -n 'bin/cldir.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]
}

@test 'install' {
    run zsh -n 'install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run zsh -n 'home/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run zsh -n 'home/git/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run zsh -n 'home/shell/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run zsh -n 'setup/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run zsh -n 'bin/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]

    run zsh -n 'dependencies/install.sh'
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]
}
