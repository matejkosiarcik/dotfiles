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

is_nodejs_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|lts|lts-[[:alnum:]-]+|[0-9]+(\.[0-9]+){0,2})$'
}

normalize_nodejs_version() {
    version="${1}"

    case "${version}" in
    v*)
        version="${version#v}"
        ;;
    node | latest)
        version='latest'
        ;;
    lts/'*')
        version='lts'
        ;;
    lts/*)
        version="lts-${version#lts/}"
        ;;
    *) ;;
    esac

    if is_nodejs_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

nodejs_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^=[:space:]]+$/{ p; q; }' <"${1}"
}

nodejs_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "node" || $1 == "nodejs") {
                print $2
                exit
            }
        }
    ' "${1}"
}

nodejs_version_from_mise_config() {
    awk -F '=' '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }

        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line ~ /^[[:space:]]*\[tools\][[:space:]]*$/) {
                section = "tools"
                next
            }
            if (line ~ /^[[:space:]]*\[tools\.(node|nodejs)\][[:space:]]*$/) {
                section = "nodejs"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && (key == "node" || key == "nodejs")) || (section == "nodejs" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

nodejs_version_from_package_json() {
    if ! command -v node >/dev/null 2>&1; then
        return
    fi

    node -e '
        const fs = require("fs");
        try {
            const packageJson = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
            const version = (packageJson.volta && packageJson.volta.node) || (packageJson.engines && packageJson.engines.node);
            if (typeof version === "string") {
                process.stdout.write(version);
            }
        } catch {
            process.exitCode = 1;
        }
    ' "${1}" 2>/dev/null || true
}

resolve_nodejs_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            for version_file in '.node-version' '.nvmrc'; do
                if [ -f "${version_directory}/${version_file}" ]; then
                    version="$(nodejs_version_from_version_file "${version_directory}/${version_file}")"
                    version="$(normalize_nodejs_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(nodejs_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_nodejs_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(nodejs_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_nodejs_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/package.json" ]; then
                version="$(nodejs_version_from_package_json "${version_directory}/package.json")"
                version="$(normalize_nodejs_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        parent_directory="$(dirname "${directory}")"
        if [ "${parent_directory}" = "${directory}" ]; then
            break
        fi
        directory="${parent_directory}"
    done

    printf '%s\n' 'latest'
}

update_nodejs_dependencies() {
    package_file="${1}"
    update_target="${2}"
    package_directory="$(dirname "${package_file}")"
    package_manager="$(detect_nodejs_package_manager "${package_directory}")"
    nodejs_version="$(resolve_nodejs_version "$(cd "${package_directory}" && pwd -P)")"
    ncu_target="${update_target}"

    if [ "${update_target}" = 'major' ]; then
        ncu_target='latest'
    fi

    printf '# Updating %s package file at %s\n' "${package_manager}" "${package_file}" >&2
    printf '# Resolved NodeJS version %s for %s\n' "${nodejs_version}" "${package_file}" >&2

    if [ ! -e "${HOME}/.npmrc" ] || [ "$(wc -c <"${HOME}/.npmrc")" -eq '0' ]; then
        printf '# Placeholder\n' >>"${HOME}/.npmrc"
    fi

    if [ "${update_target}" != 'lock' ]; then
        run_update_command ncu --upgrade --cwd "${package_directory}" --packageManager "${package_manager}" --target "${ncu_target}"
    fi

    package_directory_name="$(cd "${package_directory}" >/dev/null 2>&1 && basename "${PWD}")"
    tmpdir="$(mktemp -d)"
    cp "${package_directory}/package.json" "${tmpdir}/package.json"

    case "${package_manager}" in
    npm)
        # shellcheck disable=SC2016
        run_update_command docker run --rm \
            --volume "${tmpdir}:/app/${package_directory_name}:rw" \
            --volume "${HOME}/.npmrc:/root/.npmrc:ro" \
            --env CYPRESS_INSTALL_BINARY='0' \
            --env PUPPETEER_SKIP_CHROMIUM_DOWNLOAD='true' \
            --env PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD='1' \
            --env NODE_OPTIONS='--dns-result-order=ipv4first' \
            --env PROJECT_DIRECTORY="/app/${package_directory_name}" \
            --entrypoint '/bin/sh' \
            --user 'root' \
            "node:${nodejs_version}" \
            -c '
                set -euf
                cd "${PROJECT_DIRECTORY}"
                npm install --ignore-scripts --no-progress --no-audit --no-fund --loglevel=error
                npm dedupe --ignore-scripts --no-progress --no-audit --no-fund --loglevel=error
            '
        lockfile='package-lock.json'
        ;;
    pnpm)
        # shellcheck disable=SC2016
        run_update_command docker run --rm \
            --volume "${tmpdir}:/app/${package_directory_name}:rw" \
            --volume "${HOME}/.npmrc:/root/.npmrc:ro" \
            --mount "type=bind,src=${source_dir}/container-dependencies/corepack,dst=/deps/corepack,readonly" \
            --env CYPRESS_INSTALL_BINARY='0' \
            --env PUPPETEER_SKIP_CHROMIUM_DOWNLOAD='true' \
            --env PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD='1' \
            --env NODE_OPTIONS='--dns-result-order=ipv4first' \
            --env PROJECT_DIRECTORY="/app/${package_directory_name}" \
            --entrypoint '/bin/sh' \
            --user 'root' \
            "node:${nodejs_version}" \
            -c '
                set -euf
                mkdir "/tmp/deps"
                cp "/deps/corepack/package.json" "/deps/corepack/package-lock.json" "/tmp/deps/"
                npm ci --prefix "/tmp/deps" --no-audit --no-fund --no-progress --no-save --loglevel=error
                export PATH="/tmp/deps/node_modules/.bin:${PATH}"
                corepack pnpm install --dir "${PROJECT_DIRECTORY}" --lockfile-only --ignore-scripts --no-frozen-lockfile --reporter=silent
            '
        lockfile='pnpm-lock.yaml'
        ;;
    yarn)
        # shellcheck disable=SC2016
        run_update_command docker run --rm \
            --volume "${tmpdir}:/app/${package_directory_name}:rw" \
            --volume "${HOME}/.npmrc:/root/.npmrc:ro" \
            --mount "type=bind,src=${source_dir}/container-dependencies/corepack,dst=/deps/corepack,readonly" \
            --env CYPRESS_INSTALL_BINARY='0' \
            --env PUPPETEER_SKIP_CHROMIUM_DOWNLOAD='true' \
            --env PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD='1' \
            --env NODE_OPTIONS='--dns-result-order=ipv4first' \
            --env PROJECT_DIRECTORY="/app/${package_directory_name}" \
            --entrypoint '/bin/sh' \
            --user 'root' \
            "node:${nodejs_version}" \
            -c '
                set -euf
                mkdir "/tmp/deps"
                cp "/deps/corepack/package.json" "/deps/corepack/package-lock.json" "/tmp/deps/"
                npm ci --prefix "/tmp/deps" --no-audit --no-fund --no-progress --no-save --loglevel=error
                export PATH="/tmp/deps/node_modules/.bin:${PATH}"
                if corepack yarn --version | grep -q "^1\\."; then
                    corepack yarn install --cwd "${PROJECT_DIRECTORY}" --ignore-scripts --non-interactive --no-progress
                else
                    corepack yarn install --cwd "${PROJECT_DIRECTORY}" --mode=update-lockfile
                fi
            '
        lockfile='yarn.lock'
        ;;
    bun)
        # shellcheck disable=SC2016
        run_update_command docker run --rm \
            --volume "${tmpdir}:/app/${package_directory_name}:rw" \
            --volume "${HOME}/.npmrc:/root/.npmrc:ro" \
            --env CYPRESS_INSTALL_BINARY='0' \
            --env PUPPETEER_SKIP_CHROMIUM_DOWNLOAD='true' \
            --env PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD='1' \
            --env NODE_OPTIONS='--dns-result-order=ipv4first' \
            --env PROJECT_DIRECTORY="/app/${package_directory_name}" \
            --entrypoint '/bin/sh' \
            --user 'root' \
            oven/bun:latest \
            -c '
                set -euf
                cd "${PROJECT_DIRECTORY}"
                bun install --lockfile-only --ignore-scripts --no-progress
            '
        if [ -e "${tmpdir}/bun.lock" ]; then
            lockfile='bun.lock'
        else
            lockfile='bun.lockb'
        fi
        ;;
    *)
        printf 'Unsupported NodeJS package manager %s\n' "${package_manager}" >&2
        rm -rf "${tmpdir}"
        exit 1
        ;;
    esac

    cat "${tmpdir}/${lockfile}" >"${package_directory}/${lockfile}"
    if [ "${package_manager}" = 'bun' ] && [ "${lockfile}" = 'bun.lock' ] && [ -e "${package_directory}/bun.lockb" ]; then
        rm "${package_directory}/bun.lockb"
    fi
    rm -rf "${tmpdir}"
}
