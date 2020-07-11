#!/bin/sh
# This file backs up all system installed packages to Dropbox
set -euf

tmpdir="$(mktemp -d)"
cd "${tmpdir}"

if [ "$(uname -s)" = 'Darwin' ]; then
    printf 'Brew\n'
    brew bundle dump --file Brewfile
    brew cask ls -1 >brew-cask.txt
    brew ls -1 >brew.txt
elif [ "$(uname -s)" = 'Linux' ]; then
    if command -v apt >/dev/null 2>&1; then
        printf 'Apt\n'
        apt list --installed >apt.txt
    elif command -v dnf >/dev/null 2>&1; then
        printf 'Dnf\n'
        dnf list installed >dnf.txt
    fi
fi

printf 'Python\n'
pip3 list --format=freeze >requirements.txt

printf 'JavaScript\n'
npm list -g --depth 0 >npm.txt

printf 'Ruby\n'
gem list --quiet >Gemfile

printf 'Rust\n'
cargo install --list >cargo.txt
printf '\n\n' >>cargo.txt
cargo --list >>cargo.txt

printf 'Haskell\n'
cabal list --installed >cabal.txt
ghc-pkg list >ghc-pkg.txt

printf 'Swift\n'
mint list >Mintfile

printf 'Apps\n'
ls -1 /Applications >apps.txt

printf 'Editors\n'
code --list-extensions >vscode-extensions.txt
case "$(uname -s)" in
Darwin) cp "${HOME}/Library/Application Support/Code/User/settings.json" 'vscode-settings.json' ;;
Windows) cp %APPDATA%\\Code\\User\\settings.json vscode-settings.json ;;
Linux) cp "${HOME}/.config/Code/User/settings.json" 'vscode-settings.json' ;;
esac

computername="$(scutil --get ComputerName || cat /etc/hostname || uname -n)"
target="${HOME}/Dropbox/Backup/${computername}/packages"
[ -e "${target}" ] && rm -rf "${target}"
mkdir -p "${target}"
cp -r "${tmpdir}/" "${target}/"
