#!/bin/sh
set -euf

usage() {
    printf 'Usage: %s [-h] [-c COUNT | --count COUNT]\n' "${0##*/}"
}

count='1'
while getopts ':hc:-:' option; do
    case "${option}" in
    h)
        usage
        exit 0
        ;;
    c)
        count="${OPTARG}"
        ;;
    -)
        case "${OPTARG}" in
        count)
            if [ "${OPTIND}" -gt "${#}" ]; then
                printf 'Option --count requires a value.\n' >&2
                exit 1
            fi
            eval "count=\${${OPTIND}}"
            OPTIND="$((OPTIND + 1))"
            ;;
        *)
            printf 'Unknown option: --%s\n' "${OPTARG}" >&2
            exit 1
            ;;
        esac
        ;;
    :)
        printf 'Option -%s requires a value.\n' "${OPTARG}" >&2
        exit 1
        ;;
    *)
        printf 'Unknown option: -%s\n' "${OPTARG}" >&2
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"

if [ "${#}" -gt 0 ]; then
    printf 'Unknown argument: %s\n' "${1}" >&2
    exit 1
fi

if ! (printf '0+%s' "${count}" | bc >/dev/null 2>&1); then
    printf 'Count must be a valid number, got: %s\n' "${count}" >&2
    exit 1
fi

if ! sh -c '[ "${1}" -gt "0" ]' sh "${count}" >/dev/null 2>&1; then
    printf 'Count must be a valid number, got: %s\n' "${count}" >&2
    exit 1
fi

printf 'Generating %s passwords:\n' "${count}" >&2

interleave() {
    awk -v first="${1}" -v second="${2}" '
        BEGIN {
            max = length(first) > length(second) ? length(first) : length(second)
            for (i = 1; i <= max; i++) {
                printf "%s%s", substr(first, i, 1), substr(second, i, 1)
            }
        }
    '
    printf '\n'
}

i='0'
while [ "${i}" -lt "${count}" ]; do
    part_1="$(bw generate --lowercase --uppercase --number --length 20)"
    part_2="$(openssl rand -hex 10)" # alphanumeric length is 2x
    interleave "${part_1}" "${part_2}"
    i="$((i + 1))"
done
