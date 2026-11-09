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
    *)
        ;;
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
        for version_file in '.node-version' '.nvmrc'; do
            if [ -f "${directory}/${version_file}" ]; then
                version="$(nodejs_version_from_version_file "${directory}/${version_file}")"
                version="$(normalize_nodejs_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
            if [ -f "${directory}/${mise_file}" ]; then
                version="$(nodejs_version_from_mise_config "${directory}/${mise_file}")"
                version="$(normalize_nodejs_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        if [ -f "${directory}/.tool-versions" ]; then
            version="$(nodejs_version_from_tool_versions "${directory}/.tool-versions")"
            version="$(normalize_nodejs_version "${version}")"
            if [ -n "${version}" ]; then
                printf '%s\n' "${version}"
                return
            fi
        fi

        if [ -f "${directory}/package.json" ]; then
            version="$(nodejs_version_from_package_json "${directory}/package.json")"
            version="$(normalize_nodejs_version "${version}")"
            if [ -n "${version}" ]; then
                printf '%s\n' "${version}"
                return
            fi
        fi

        parent_directory="$(dirname "${directory}")"
        if [ "${parent_directory}" = "${directory}" ]; then
            break
        fi
        directory="${parent_directory}"
    done

    printf '%s\n' 'latest'
}
