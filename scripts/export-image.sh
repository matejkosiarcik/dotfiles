#!/bin/sh
set -euf

# Export container metadata and filesystem into a directory for debugging

if [ "${#}" -eq 1 ] && { [ "${1}" = '-h' ] || [ "${1}" = '--help' ]; }; then
    printf 'Usage: %s <image-name>\n' "${0}"
    exit 0
fi

if [ "${#}" -ne 1 ]; then
    printf 'Usage: %s <image-name>\n' "${0}" >&2
    exit 1
fi

image_name="${1}"

# Pull image and ignore errors (image may already exist locally)
docker pull "${image_name}" >/dev/null || true
if ! docker image inspect "${image_name}" >/dev/null 2>&1; then
    printf 'Image %s does not exist\n' "${image_name}" >&2
    exit 1
fi

directory_name="$(printf '%s' "${image_name}" | LC_ALL=C tr -c 'a-zA-Z0-9-' '-')"
output_directory="${PWD}/${directory_name}"
suffix='0'

while [ -e "${output_directory}" ] || [ -L "${output_directory}" ]; do
    suffix=$((suffix + 1))
    output_directory="${PWD}/${directory_name}-${suffix}"
done
mkdir -p "${output_directory}"

# Export env
docker image inspect "${image_name}" --format '{{range .Config.Env}}{{println .}}{{end}}' | cat -s | sort --human-numeric-sort >"${output_directory}/env.txt"

# Export general metadata
docker image inspect "${image_name}" | cat -s | jq --sort-keys '.' >"${output_directory}/metadata.txt"

# Export filesystem
tmpdir="$(mktemp -d)"
temporary_container_name="$(basename "${tmpdir}")"
cleanup() {
    docker rm "${temporary_container_name}" >/dev/null 2>&1 || true
    rm -rf "${tmpdir}"
}
trap cleanup EXIT HUP INT TERM
docker create --name "${temporary_container_name}" "${image_name}" --quiet >/dev/null
docker export "${temporary_container_name}" --output "${tmpdir}/container.tar"
mkdir -p "${output_directory}/fs"
tar -xf "${tmpdir}/container.tar" \
    -C "${output_directory}/fs" \
    --exclude='dev/*' \
    --exclude='proc/*' \
    --exclude='sys/*'
cleanup
trap - EXIT HUP INT TERM

printf 'Image %s exported to %s\n' "${image_name}" "${output_directory}" >&2
