# Personal dotfiles

> Collection of my personal system config files

<!-- toc -->

- [About](#about)
- [Installation](#installation)
- [License](#license)

<!-- tocstop -->

## About

Repository is split into these important parts:

| Directory | Purpose                              |
|-----------|--------------------------------------|
| home      | Config files from $HOME              |
| setup     | Scripts to run during computer setup |
| scripts   | Runtime scripts under $PATH          |

## Installation

You probably don't want to actually install all my dotfiles…
So this section is mostly for my future self :\) .

Install project dependencies:

```bash
make bootstrap
```

Install project system-wide:

```bash
make install
```

Or just run everything mentioned (and more):

```bash
make
```

## License

This project is licensed under the MIT License, see
[LICENSE.txt](LICENSE.txt) for full license details.
