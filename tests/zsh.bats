@test 'shell - zsh' {
    run zsh -c 'source home/shell/custom.zsh'
    [ "${status}" -eq '0' ]

    run zsh -c 'source home/shell/custom.sh'
    [ "${status}" -eq '0' ]
}
