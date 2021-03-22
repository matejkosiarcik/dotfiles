#!/bin/sh
set -euf

# This script backs up all system installed packages to Dropbox

tmpdir="$(mktemp -d)"
cd "${tmpdir}"
printf 'Running packages backup...\n'

if [ "$(uname -s)" = 'Darwin' ]; then
    printf '%s\n' '-- Brew --'
    brew bundle dump --file Brewfile
    brew list --formula -1 >brew.txt
    brew list --cask -1 >brew-cask.txt
elif [ "$(uname -s)" = 'Linux' ]; then
    if command -v apt >/dev/null 2>&1; then
        printf '%s\n' '-- Apt --'
        apt list --installed >apt.txt
    elif command -v dnf >/dev/null 2>&1; then
        printf '%s\n' '-- Dnf --'
        dnf list installed >dnf.txt
    fi
fi

printf '%s\n' '-- JavaScript --'
npm list -g --depth 0 >npm.txt
# TODO: denoland?

printf '%s\n' '-- Python --'
pip3 list --format=freeze >requirements.txt

printf '%s\n' '-- Ruby --'
gem list --quiet >Gemfile

printf '%s\n' '-- Rust --'
cargo install --list >cargo.txt
printf '\n\n' >>cargo.txt
cargo --list >>cargo.txt

# printf '%s\n' '-- Haskell --'
# cabal list --installed >cabal.txt
# ghc-pkg list >ghc-pkg.txt

printf '%s\n' '-- Swift --'
mint list >Mintfile

# TODO: nix?

if [ "$(uname -s)" = 'Darwin' ]; then
    printf '%s\n' '-- Apps --'
    ls -1 /Applications >apps.txt
fi

printf '%s\n' '-- Editors --'
code --list-extensions >vscode-extensions.txt
case "$(uname -s)" in
Darwin) cp "${HOME}/Library/Application Support/Code/User/settings.json" 'vscode-settings.json' ;;
Windows) cp %APPDATA%\\Code\\User\\settings.json vscode-settings.json ;;
Linux) cp "${HOME}/.config/Code/User/settings.json" 'vscode-settings.json' ;;
esac

printf '%s\n' '-- Cron --'
crontab -l >cron.txt

touch ".$(date '+%Y-%m-%d %H-%M-%S%z')" # mark datetime of current export

# Copy created directory to Dropbox under this computer's name
computername="$(scutil --get ComputerName || cat /etc/hostname || uname -n)"
target="${HOME}/Dropbox/Packages/${computername}"
[ -e "${target}" ] && rm -rf "${target}"
mkdir -p "${target}"
cp -r "${tmpdir}/" "${target}/"

printf 'Successfuly run packages backup.\n'
