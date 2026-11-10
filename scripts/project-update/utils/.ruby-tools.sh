#!/bin/sh
set -euf

is_ruby_version() {
    printf '%s\n' "${1}" | grep -qE '^(latest|[0-9]+(\.[0-9]+){0,2})$'
}

normalize_ruby_version() {
    version="${1}"

    case "${version}" in
    ruby-*)
        version="${version#ruby-}"
        ;;
    ruby[0-9]*)
        version="${version#ruby}"
        ;;
    *) ;;
    esac

    if is_ruby_version "${version}"; then
        printf '%s\n' "${version}"
    fi
}

ruby_version_from_version_file() {
    sed -n -E 's~[[:space:]]*#.*$~~;s~^[[:space:]]+~~;s~[[:space:]]+$~~;/^[^[:space:]]+$/{ p; q; }' <"${1}"
}

ruby_version_from_tool_versions() {
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($1 == "ruby") {
                print $2
                exit
            }
        }
    ' "${1}"
}

ruby_version_from_mise_config() {
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
            if (line ~ /^[[:space:]]*\[tools\.ruby\][[:space:]]*$/) {
                section = "ruby"
                next
            }
            if (line ~ /^[[:space:]]*\[/) {
                section = ""
                next
            }

            key = trim($1)
            value = trim($2)
            gsub(/^[\"\047]|[\"\047]$/, "", value)
            if ((section == "tools" && key == "ruby") || (section == "ruby" && key == "version")) {
                print value
                exit
            }
        }
    ' "${1}"
}

ruby_version_from_gemfile() {
    awk '
        {
            line = $0
            sub(/[[:space:]]*#.*/, "", line)
            if (line !~ /^[[:space:]]*ruby([[:space:]]|\()/) {
                next
            }

            sub(/^[[:space:]]*ruby[[:space:]]*(\([[:space:]]*)?/, "", line)
            quote = substr(line, 1, 1)
            if (quote != "\"" && quote != sprintf("%c", 39)) {
                next
            }
            line = substr(line, 2)
            quote_position = index(line, quote)
            if (quote_position > 1) {
                print substr(line, 1, quote_position - 1)
                exit
            }
        }
    ' "${1}"
}

ruby_version_from_lockfile() {
    awk '
        /^[[:space:]]*RUBY VERSION[[:space:]]*$/ {
            in_ruby_version = 1
            next
        }
        in_ruby_version && /^[[:space:]]*$/ {
            exit
        }
        in_ruby_version && $1 == "ruby" {
            version = $2
            sub(/p[0-9]+$/, "", version)
            print version
            exit
        }
    ' "${1}"
}

resolve_ruby_version() {
    directory="${1}"

    while true; do
        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.ruby-version" ]; then
                version="$(ruby_version_from_version_file "${version_directory}/.ruby-version")"
                version="$(normalize_ruby_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            for mise_file in '.mise.local.toml' 'mise.local.toml' '.mise.toml' 'mise.toml'; do
                if [ -f "${version_directory}/${mise_file}" ]; then
                    version="$(ruby_version_from_mise_config "${version_directory}/${mise_file}")"
                    version="$(normalize_ruby_version "${version}")"
                    if [ -n "${version}" ]; then
                        printf '%s\n' "${version}"
                        return
                    fi
                fi
            done
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/.tool-versions" ]; then
                version="$(ruby_version_from_tool_versions "${version_directory}/.tool-versions")"
                version="$(normalize_ruby_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/Gemfile" ]; then
                version="$(ruby_version_from_gemfile "${version_directory}/Gemfile")"
                version="$(normalize_ruby_version "${version}")"
                if [ -n "${version}" ]; then
                    printf '%s\n' "${version}"
                    return
                fi
            fi
        done

        for version_directory in "${directory}" "${directory}/.config"; do
            if [ -f "${version_directory}/Gemfile.lock" ]; then
                version="$(ruby_version_from_lockfile "${version_directory}/Gemfile.lock")"
                version="$(normalize_ruby_version "${version}")"
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

update_ruby_dependencies() {
    gemfile="${1}"
    update_target="${2}"
    directory="$(cd "$(dirname "${gemfile}")" && pwd -P)"
    gemfile_path="${directory}/Gemfile"
    lockfile_path="${directory}/Gemfile.lock"
    ruby_version="$(resolve_ruby_version "${directory}")"

    printf '# Resolved Ruby version %s for %s\n' "${ruby_version}" "${gemfile}" >&2

    if [ ! -e "${lockfile_path}" ]; then
        touch "${lockfile_path}"
    fi

    docker run --rm \
        --mount "type=bind,src=${gemfile_path},dst=/input/Gemfile,readonly=false" \
        --mount "type=bind,src=${lockfile_path},dst=/input/Gemfile.lock,readonly=false" \
        --env "UPDATE_TARGET=${update_target}" \
        --entrypoint '/bin/sh' \
        "ruby:${ruby_version}" \
        -c '
            set -euf
            mkdir -p "/work" "/bundle"
            cp "/input/Gemfile" "/input/Gemfile.lock" "/work/"
            cd "/work"

            export BUNDLE_DISABLE_SHARED_GEMS="true"
            export BUNDLE_FROZEN="false"
            export BUNDLE_PATH__SYSTEM="false"
            export BUNDLE_PATH="/bundle"
            export BUNDLE_GEMFILE="/work/Gemfile"

            case "${UPDATE_TARGET}" in
            major | minor | patch)
                bundle install --quiet
                bundle update --all --quiet "--${UPDATE_TARGET}" --strict
                ;;
            lock)
                ;;
            esac

            bundle lock --normalize-platforms

            cat "./Gemfile" >"/input/Gemfile"
            cat "./Gemfile.lock" >"/input/Gemfile.lock"
        '
}
