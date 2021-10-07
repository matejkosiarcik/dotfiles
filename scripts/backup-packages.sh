#!/bin/sh
set -euf

# This script backs up all system installed packages to Dropbox

tmpdir="$(mktemp -d)"
cd "$tmpdir"
printf 'Running packages backup...\n'

if command -v brew >/dev/null 2>&1; then
    printf '# Brew #\n'
    brew bundle dump --file Brewfile
    brew list --formula -1 >brew.txt
    brew list --cask -1 >brew-cask.txt
fi

if command -v apt >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
    printf '# Apt #\n'
    apt list --installed | grep '\[installed\]' | sed -E 's~/.*$~~' >apt.txt
fi
if command -v dnf >/dev/null 2>&1; then
    printf '# Dnf #\n'
    dnf list installed >dnf.txt
fi

printf '# JavaScript #\n'
if command -v npm >/dev/null 2>&1; then
    npm list -g --depth 0 >npm.txt
fi

printf '# Python #\n'
if command -v pip3 >/dev/null 2>&1; then
    pip3 list --format=freeze >requirements.txt
fi

printf '# Ruby #\n'
if command -v gem >/dev/null 2>&1; then
    gem list --quiet >Gemfile
fi

printf '# Rust #\n'
if command -v cargo >/dev/null 2>&1; then
    cargo install --list >cargo.txt
    printf '\n\n' >>cargo.txt
    cargo --list >>cargo.txt
fi

# printf '# Haskell #\n'
# cabal list --installed >cabal.txt
# ghc-pkg list >ghc-pkg.txt

printf '# Swift #\n'
if command -v mint >/dev/null 2>&1; then
    mint list >Mintfile
fi

printf '# Apps #\n'
if [ "$(uname -s)" = 'Darwin' ]; then
    ls -1 '/Applications' >apps.txt
fi

printf '# Editors #\n'
if command -v code >/dev/null 2>&1; then
    code --list-extensions >vscode-extensions.txt
fi
case "$(uname -s)" in
Darwin) cp "$HOME/Library/Application Support/Code/User/settings.json" 'vscode-settings.json' ;;
Windows) cp %APPDATA%\\Code\\User\\settings.json vscode-settings.json ;;
Linux) cp "$HOME/.config/Code/User/settings.json" 'vscode-settings.json' ;;
*) printf 'Could not copy VSCode settings, unsupported system %s\n' "$(uname -a)" ;;
esac

touch ".$(date '+%Y-%m-%dT%H-%M-%S%z')" # mark datetime of current export

# Copy created directory to Dropbox under this computer's name
computername="$(scutil --get ComputerName || cat /etc/hostname || uname -n)"
target="$HOME/Dropbox/Packages/$computername"
[ -e "$target" ] && rm -rf "$target"
mkdir -p "$target"
cp -r "$tmpdir/" "$target/"

printf 'Successfuly run packages backup.\n'
