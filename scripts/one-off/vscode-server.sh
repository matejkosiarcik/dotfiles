#!/bin/sh
set -euf

server_1_name='Odroid H4 Ultra'
server_2_name='Odroid H3'
server_3_name='Raspberry Pi 4B 2G'
server_4_name='Raspberry Pi 4B 4G'
server_5_name='MacBook Pro 2012'

printf 'Select server:\n'
printf '\n'
printf '  1) %s\n' "$server_1_name"
printf '  2) %s\n' "$server_2_name"
printf '  3) %s\n' "$server_3_name"
printf '  4) %s\n' "$server_4_name"
printf '  5) %s\n' "$server_5_name"
printf '\n'

read -p 'Enter server: ' choice

chosen_server=''
case "$choice" in
1)
    chosen_server="$server_1_name"
    ;;
2)
    chosen_server="$server_2_name"
    ;;
3)
    chosen_server="$server_3_name"
    ;;
4)
    chosen_server="$server_4_name"
    ;;
5)
    chosen_server="$server_5_name"
    ;;
*)
    printf 'Invalid input\n' >&2
    exit 1
    ;;
esac

server_address="$(printf 'server-%s.matejhome.com' "$chosen_server" | tr '[:upper:]' '[:lower:]' | sed 's~ ~-~g')"
code --new-window --remote "ssh-remote+homelab@$server_address" '/home/homelab/git/homelab'
