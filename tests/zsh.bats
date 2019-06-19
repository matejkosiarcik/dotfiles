@test 'shell - zsh' {
    run zsh -c 'source home/shell/custom.zsh'
    [ "${status}" -eq '0' ]
    echo "${output}"
    [ "${output}" == '' ]

    run zsh -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
    echo "${output}"
    [ "${output}" == '' ]
}
