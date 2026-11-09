#!/bin/sh
set -euf

detect_nodejs_package_manager() {
    if [ -e "${1}/pnpm-lock.yaml" ]; then
        printf '%s\n' 'pnpm'
    elif [ -e "${1}/yarn.lock" ]; then
        printf '%s\n' 'yarn'
    elif [ -e "${1}/bun.lock" ] || [ -e "${1}/bun.lockb" ]; then
        printf '%s\n' 'bun'
    else
        printf '%s\n' 'npm'
    fi
}
