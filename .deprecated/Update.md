# Update

> Collection of scripts to update common package managers

# apt

```sh
sudo apt update  # update index
sudo apt upgrade # update packages
```

# Homebrew

```sh
brew update       # update brew itself
brew upgrade      # update formulas
brew cask upgrade # update casks
brew cleanup      # clean leftover artefacts
```

## NPM

```sh
npm update -g
```

## pip

```sh
python -m pip install --upgrade pip # update pip
python -m pip list --outdated --format=freeze | grep -v '^\-e' | cut -d '=' -f '1' | xargs -n1 pip install --upgrade # update packages
```

## Rustup

```sh
rustup self update # update rustup
rustup update      # update rust
```

## yum

```sh
yum update  # update yum
yum upgrade # update packages
```

## TODO:

- BSD ports
- chocolatey
- fink
- Gem
- macports
- rpm
- snap
