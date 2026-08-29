#!/bin/sh
set -euf

# Export container metadata and filesystem into a directory for debugging

image_name=''
output_directory=''
while [ "$#" -gt 0 ]; do
    case "$1" in
    -i | --image)
        image_name="$2"
        shift 2
        ;;
    -o | --output)
        output_directory="$2"
        shift 2
        ;;
    *)
        printf 'Unknown argument: %s\n' "$1"
        exit 1
        ;;
    esac
done

if [ -z "${image_name:-}" ]; then
    printf 'Image name not provided, use "-c/--container <name>"\n' >&2
    exit 1
fi
if [ -z "${output_directory:-}" ]; then
    printf 'Output directory path missing, use "-o/--output <directory>"\n' >&2
    exit 1
fi

output_directory="$(realpath -q "${output_directory}" || if printf '%s' "${output_directory}" | grep '^/' >/dev/null 2>&1; then printf '%s' "${output_directory}"; else printf '%s/%s' "${PWD}" "${output_directory}"; fi )"

if [ ! -e "${output_directory}" ]; then
    mkdir -p "${output_directory}"
fi
if [ "$(find "${output_directory}" -mindepth 1 -maxdepth 1 | wc -c)" -gt '0' ]; then
    printf 'Output directory %s not empty\n' "${output_directory}" >&2
    exit 1
fi

# Export env
docker image inspect "${image_name}" --format '{{range .Config.Env}}{{println .}}{{end}}' >"${output_directory}/env.txt"

# Export general metadata
docker image inspect "${image_name}" >"${output_directory}/metadata.txt"

# Export filesystem
tmpdir="$(mktemp -d)"
docker create --name "$(basename "${tmpdir}")" "${image_name}" --quiet >/dev/null
docker export "$(basename "${tmpdir}")" --output "${tmpdir}/container.tar"
mkdir -p "${output_directory}/fs"
tar -xf "${tmpdir}/container.tar" -C "${output_directory}/fs"
docker rm "$(basename "${tmpdir}")" >/dev/null
rm -rf "${tmpdir}"

printf 'Container %s exported to %s\n' "${image_name}" "${output_directory}" >&2
