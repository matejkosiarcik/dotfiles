# Personal dotfiles

> Collection of my personal system config files and scripts

<!-- toc -->

- [About](#about)
- [Installation](#installation)
- [License](#license)

<!-- tocstop -->

## About

Repository is split into multiple directories:

| Directory  | Purpose                                                                                            |
|------------|----------------------------------------------------------------------------------------------------|
| `apps/`    | Applications - usually wrapping scripts using platypus                                             |
| `config/`  | Config files - installed into `$HOME`                                                              |
| `deamons/` | Scripts executed automatically in the background (system startup, directory monitoring, cron, ...) |
| `scripts/` | Scripts - to be added to `$PATH` and used interactively                                            |

## Installation

You probably don't want to actually install my dotfiles…
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
