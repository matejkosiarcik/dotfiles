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

# Swift
swiftlint lint --quiet 2>/dev/null || true

# Markdown
mdl '.' -g || true

# Yaml
if [ -f '.yamllint.yml' ]; then
    yamllint '.' --format parsable --config-file '.yamllint.yml' || true
fi

# Shell
project_files | grep '\.sh$' | while IFS= read -r file; do
    shellcheck --format gcc "${file}" || true
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
