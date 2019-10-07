#!/usr/bin/env bats

function setup() {
    cd "$(dirname "${BATS_TEST_FILENAME}")/.." || exit 1
}

@test 'bin - cldir' {
    for shell in sh dash bash 'bash --posix' zsh yash; do
        if ! command -v "${shell}" >/dev/null 2>&1; then
            printf 'Skipping %s\n' "${shell}" >&3
            continue
        fi
        printf 'Testing %s\n' "${shell}" >&3

        run "${shell}" -n 'bin/cldir.sh'
        [ "${status}" -eq '0' ]
        [ "${output}" = '' ]
    done
}
