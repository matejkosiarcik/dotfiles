#!/bin/sh
set -euf

count='1'
while [ "$#" -gt 0 ]; do
    case "$1" in
    -c | --count)
        count="$2"
        shift 2
        ;;
    *)
        printf 'Unknown argument %s\n' "$1"
        exit 1
        ;;
    esac
done

i='0'
while [ "$i" -lt "$count" ]; do
    part_1="$(bw generate --lowercase --uppercase --number --length 15)"
    part_2="$(openssl rand -hex 5)" # alphanumeric length is 2x
    part_3="$(bw generate --lowercase --uppercase --number --length 15)"
    printf '%s%s%s\n' "$part_1" "$part_2" "$part_3"
    i="$((i + 1))"
done
