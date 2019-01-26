#!/bin/sh
set -euf

# finds all associated project files
_project_files="$(mktemp)"
project_files() {
    if [ "$(cat "${_project_files}")" = '' ]; then
        find '.' -type f -not -path '*.git/*' | while IFS= read -r file; do
            if [ -d '.git' ] && command -v git >/dev/null 2>&1 && git check-ignore "${file}" >/dev/null 2>&1; then
                continue
            fi
            printf '%s\n' "${file}" | sed 's~^\./~~' >>"${_project_files}"
        done
    fi
    cat "${_project_files}"
}

### document ###

# HTML
htmlhint --format unix '.' | grep -v '^$' | grep -Ev '^(.*)([0-9]+) problem(s?)(.*)$' |
    sed -E 's~\[error/(.*)\]$~[\1]~' | sed -E 's~(.*):([0-9]+):([0-9]+): ~\1:\2:\3: warning: ~' |
    sed -E "s~\\[(.*)\\] \\[(.*)\\]~'\\1' [\\2]~"

# Markdown
mdl '.' -g || true
project_files | grep -E '\.(md|markdown)$' | while IFS= read -r file; do
    markdownlint "${file}" || true
done

# SASS
sass-lint --verbose --no-exit --syntax scss --format unix | grep -Ev '([0-9]+) problems' | grep -v '^$' |
    sed -E 's~(w|W)arning/~~' | sed -E 's~(e|E)rror/~~' | sed -E 's~^(.*):([0-9]+):([0-9]+):~\1:\2:\3: warning:~'

### data/config ###

# JSON
project_files | grep '\.json$' | while IFS= read -r file; do
    jsonlint "${file}" --quiet --compact 2>&1 | sed -E 's~\.$~~' |
        sed -E 's~(.*): line ([0-9]+), col ([0-9]+), ~\1:\2:\3: warning: ~'
done

# SVG, XML
project_files | grep -E '\.(svg|xml)$' | while IFS= read -r file; do
    xmllint "${file}" --noout || true
done

# SVG
# has to be after xmllint
# generated PDFs should be the same for both methods (svg2pdf and rsvg-convert)
# if they differ, there is possibly some glitch in source SVGs
temp="$(mktemp -d)"
project_files | grep '\.svg$' | while IFS= read -r file; do
    target="${temp}/$(basename "${file}" '.svg').pdf"
    svg2pdf "${file}" "${target}.1"
    rsvg-convert "${file}" --format pdf --output "${target}.2"
    cmp --silent "${target}.1" "${target}.2" || {
        printf '%s: warning: Generated PDFs differ (unstable_svg)\n' "${file}"
    }
done
rm -rf "${temp}"

# Yaml
if [ -f '.yamllint.yml' ]; then
    yamllint '.' --format parsable --config-file '.yamllint.yml' || true
fi

### code ###

# Javascript, TypeScript
if [ "$(project_files | grep -E '\.(js|ts)$')" != "" ]; then
    # shellcheck disable=SC2046
    tslint --force --format verbose $(project_files | grep -E '\.(js|ts)$' | tr '\n' ' ') | grep -v '^$' |
        sed 's~^ERROR: ~~' | sed 's~\.$~~' | sed -E 's~^\((.+)\) (.*)$~\2 (\1)~' |
        sed -E 's~(.*)\[([0-9]+), ([0-9]+)\]~\1:\2:\3: warning~'
fi

# PHP
project_files | grep -E '\.php(\.mustache)?$' | while IFS= read -r file; do
    php -l "${file}" | grep -v '^$' | grep -v '^Errors' | grep -v '^No ' |
        sed -E 's~^(.+): (.+) in (.+) on line ([0-9]+)$~\3:\4: warning: \1 (\2)~' |
        sed -E 's~\(([a-zA-z0-9]+) ([a-zA-Z0-9]+)\)~(\1_\2)~'
done

# Python
project_files | grep '\.py$' | while IFS= read -r file; do
    pylint --output-format parseable "${file}" | grep -Ev '^([- ]+)$' | grep -v '^$' |
        grep -Ev '^([\*]+) Module' | grep -v '^Your code has been rated at ' |
        sed -E 's~(.*)\[(.*)\](.*)~\1\3 [\2]~' | sed -E 's~(.*):([0-9]+): ~\1:\2: warning:~' |
        sed -E 's~, \]$~]~'
done
flake8 '.' | sed -E 's~(.*):([0-9]+):([0-9]+): ([^ ]+) (.*)~\1:\2:\3: \5 [\4]~' |
    sed -E 's~(.*):([0-9]+):([0-9]+): ~\1:\2:\3: warning: ~' | sed 's~^./~~'
pycodestyle '.' | sed -E 's~(.*):([0-9]+):([0-9]+): ~\1:\2:\3: warning: ~' | sed 's~^./~~'

# Shell
project_files | grep '\.sh$' | while IFS= read -r file; do
    shellcheck --format gcc "${file}" || true
    # TODO: bash8
    shfmt -i 4 -p -l "${file}" |
        sed -E 's~(.*)~\1: warning: file badly formatted (bad_format)~g'
    bash -n "${file}" || true
    bash --posix -n "${file}" || true
    bash -o posix -n "${file}" || true
    dash -n "${file}" || true
    ksh -n "${file}" || true
    mksh -n "${file}" || true
    sh -n "${file}" || true
    yash -n "${file}" || true
    yash --posix -n "${file}" || true
    yash -o posixly-correct -n "${file}" || true
    zsh -n "${file}" || true
done

# Swift
swiftlint lint --quiet 2>/dev/null || true
