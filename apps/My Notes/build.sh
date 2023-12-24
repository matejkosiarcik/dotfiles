#!/bin/sh
set -euf

cd "$(dirname "$0")"

# TODO: Reenable platypus after https://github.com/sveinbjornt/Platypus/issues/262
if [ "$(uname -s)" != 'Darwin' ] || [ "$CI" = 1 ]; then
    printf 'App build skipped on non-macOS systems' >&2
    exit 0
fi

platypus \
    --name 'My Notes' \
    --optimize-nib \
    --overwrite \
    --background \
    --quit-after-execution \
    --interface-type None \
    --interpreter '/bin/sh' \
    --app-version '0.1' \
    --author 'Matej Kosiarcik' \
    --bundle-identifier 'com.matejkosiarcik.my-notes' \
    --app-icon "$PWD/appicon.icns" \
    "$PWD/main.sh" \
    "$PWD/My Notes.app"
