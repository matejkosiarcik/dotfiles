# Personal dotfiles

> Collection of my personal system config files and scripts

<!-- toc -->

- [About](#about)
- [Installation](#installation)
- [License](#license)

<!-- tocstop -->

## About

Repository is split into multiple directories:

| Directory  | Purpose                            |
|------------|------------------------------------|
| `home/`    | Config files from $HOME            |
| `setup/`   | Scripts to run during installation |
| `scripts/` | Main `$PATH` scripts               |
| `deamons/` | Scripts executed on system startup |

## Installation

You probably don't want to actually install all my dotfiles…
So this section is mostly for my future self :\) .

Install project dependencies:

```bash
make bootstrap
```

Build subprojects:

```bash
make build
```

Install project system-wide:

```bash
make install
```

Or just run everything mentioned (and more):

```bash
make all install
```

## License

This project is licensed under the MIT License, see
[LICENSE.txt](LICENSE.txt) for full license details.
