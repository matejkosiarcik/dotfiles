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
    run find '.' -name 'install.sh' -exec zsh -n {} \;
    [ "${status}" -eq '0' ]
    [ "${output}" = '' ]
}
