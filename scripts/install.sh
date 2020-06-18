#!/bin/sh
set -euf
cd "$(dirname "${0}")"

if [ -z "${DESTDIR+x}" ]; then
    DESTDIR="${HOME}/.bin"
fi
rm -rf "${DESTDIR:?}/*"

cp 'update-defaults.py' "${DESTDIR}/update-defaults"
chmod a+x "${DESTDIR}/update-defaults"

cp 'backup.sh' "${DESTDIR}/backup"
chmod a+x "${DESTDIR}/backup"

cp 'gupdate.sh' "${DESTDIR}/gupdate"
chmod a+x "${DESTDIR}/gupdate"
