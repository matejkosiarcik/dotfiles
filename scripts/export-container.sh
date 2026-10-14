#!/bin/sh
set -euf

# Export container metadata and filesystem into a directory for debugging

if [ "${#}" -eq 1 ] && { [ "${1}" = '-h' ] || [ "${1}" = '--help' ]; }; then
    printf 'Usage: %s <container-name>\n' "${0}"
    exit 0
fi

if [ "${#}" -ne 1 ]; then
    printf 'Usage: %s <container-name>\n' "${0}" >&2
    exit 1
fi

container_name="${1}"
if ! docker container inspect "${container_name}" >/dev/null 2>&1; then
    printf 'Container %s does not exist\n' "${container_name}" >&2
    exit 1
fi

directory_name="$(printf '%s' "${container_name}" | LC_ALL=C tr -c 'a-zA-Z0-9-' '-')"
output_directory="${PWD}/${directory_name}"
suffix='0'

while [ -e "${output_directory}" ] || [ -L "${output_directory}" ]; do
    suffix=$((suffix + 1))
    output_directory="${PWD}/${directory_name}-${suffix}"
done
mkdir -p "${output_directory}"

# Export env
docker inspect "${container_name}" --format '{{range .Config.Env}}{{println .}}{{end}}' | cat -s | sort --human-numeric-sort >"${output_directory}/env.txt"

# Export general metadata
docker inspect "${container_name}" | cat -s | jq --sort-keys '.' >"${output_directory}/metadata.txt"

# Export filesystem diff
docker diff "${container_name}" | cat -s | sort --human-numeric-sort --key=2 >"${output_directory}/diff.txt"

# Export stats
docker stats "${container_name}" --no-stream | cat -s >"${output_directory}/stats.txt"

# Export filesystem
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT HUP INT TERM
docker export "${container_name}" --output "${tmpdir}/container.tar"
mkdir -p "${output_directory}/fs"
tar -xf "${tmpdir}/container.tar" \
    -C "${output_directory}/fs" \
    --exclude='dev/*' \
    --exclude='proc/*' \
    --exclude='sys/*'
rm -rf "${tmpdir}"
trap - EXIT HUP INT TERM

printf 'Container %s exported to %s\n' "${container_name}" "${output_directory}" >&2
