#!/bin/sh
set -euf

# this removes excessive whitespace
# accepts 1 argument of file to format
strip_file() {
    printf '%s\n' "$(perl -pe 's~\r$~~' "${1}")" >"${1}"      # replace windows to unix newlines
    printf '%s\n' "$(cat -s "${1}")" >"${1}"                  # remove multiple empty lines and trailing newlines
    printf '%s\n' "$(sed '/./,$!d' "${1}")" >"${1}"           # remove leading newlines
    printf '%s\n' "$(sed 's~[[:space:]]*$~~' "${1}")" >"${1}" # remove trailing whitespace
}

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

# lists all text-based files in project_files
text_files() {
    project_files | while IFS= read -r file; do
        if [ "$(file "${file}" | grep -Ei '(text|svg)')" != '' ] ||
            [ "$(file --mime "${file}" | grep -Ei '(text|ascii|utf)')" != '' ]; then
            printf '%s\n' "${file}"
        fi
    done
}

# All text-based files
text_files | while IFS= read -r file; do
    strip_file "${file}"
done

### data/config ###

# JSON
project_files | grep '\.json$' | while IFS= read -r file; do
    printf '%s\n' "$(jsonlint "${file}" --pretty-print --indent '    ')" >"${file}"
done

# SVG
project_files | grep '\.svg$' | while IFS= read -r file; do
    svgcleaner "${file}" "${file}" --quiet --multipass \
        --coordinates-precision 1 --properties-precision 1 \
        --transforms-precision 3 --paths-coordinates-precision 1 \
        --convert-shapes no --trim-ids no
done

# SVG, XML
# for svg has to be after svgcleaner
project_files | grep -E '\.(svg|xml)$' | while IFS= read -r file; do
    printf '%s\n' "$(xmllint --format "${file}")" >"${file}"
done

# Xcode
# if [ -d "$(basename "${PWD}").xcodeproj" ]; then
#     synx "$(basename "${PWD}").xcodeproj" >/dev/null
# fi

### code ###

# Python
autopep8 '.' --recursive --in-place

# Shell
project_files | grep '\.sh$' | while IFS= read -r file; do
    shfmt -i 4 -p -w "${file}"
done

# Swift
swiftlint autocorrect --quiet 2>/dev/null || true
