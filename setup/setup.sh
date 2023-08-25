#!/bin/sh
set -euf
cd "$(dirname "${0}")"

case "$(uname -s)" in
'Darwin') sh 'setup-mac.sh' ;;
*) true ;;
esac

# uses `duti` on macOS
# makes all extensions associated with given program
make_default_program() {
    program="$1"
    file_list="$2"

    while IFS="" read -r line; do
        filetype="$(printf '%s' "$line" | sed -E 's~ ?#.+$~~;s~ ~~g')"
        if [ "$filetype" = '' ]; then
            continue
        fi
        if [ "$(uname -s)" = 'Darwin' ]; then
            duti -s "$program" "$filetype" all || true
            associated_app="$(duti -x "$filetype" || true)"
            if ! printf '%s' "$associated_app" | grep "$program" >/dev/null; then
                printf 'Filetype %s could not be changed from %s\n' "$filetype" "$(printf '%s' "$associated_app" | tr '\n' ' ')"
            fi
        fi
    done <"$file_list"
}

make_default_program 'com.microsoft.VSCode' 'textfiles.txt'
make_default_program 'org.videolan.vlc' 'mediafiles.txt'
