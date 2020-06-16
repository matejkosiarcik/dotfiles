#!/bin/sh
set -euf
cd "$(dirname "${0}")"

rm -f "${HOME}/.bin/update-defaults"
printf '#!/bin/sh\npython3 %s/update-defaults.py ${@}\n' "${PWD}" >"${HOME}/.bin/update-defaults"
chmod +x "${HOME}/.bin/update-defaults"
