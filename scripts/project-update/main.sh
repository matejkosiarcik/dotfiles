#!/bin/sh
set -euf

print_help() {
    printf 'Usage: project-update [-h] [-t <target>]\n'
    printf '\n'
    printf '  -h                                            print help message\n'
    printf '  -t {major, minor, patch, lock}                semver upgrade target\n'
    printf '  -r {all, nodejs, python, ruby, rust, gitman}  which runtime to update\n'
}

source_dir="$(dirname "$(readlink "$0")")"
PATH="$source_dir/python-vendor/bin:$source_dir/node_modules/.bin:/opt/homebrew/bin:$PATH"
export PATH
PYTHONPATH="$source_dir/python-vendor"
export PYTHONPATH

target='major'
runtime='all'
while getopts "h?t:r:" o; do
    case "$o" in
    t)
        target="$OPTARG"
        ;;
    r)
        runtime="$OPTARG"
        ;;
    h)
        print_help
        exit 0
        ;;
    *)
        print_help
        exit 1
        ;;
    esac
done

if printf '%s' "$target" | grep -qvE '^(major|minor|patch|lock)$'; then
    printf 'Unsupported target %s\n' "$target" >&2
    print_help
    exit 1
fi

if printf '%s' "$runtime" | grep -qvE '^(all|nodejs|python|ruby|rust|gitman)$'; then
    printf 'Unsupported runtime %s\n' "$runtime" >&2
    print_help
    exit 1
fi

printf 'Updating %s runtime(s) to version: %s\n\n' "$runtime" "$target" >&2

glob() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        # This is a git repo
        while [ "$#" -ge 1 ]; do
            git ls-files "$1" "*/$1"
            git ls-files --others --exclude-standard "$1" "*/$1"
            shift
        done
    else
        # This is not a git repo
        while [ "$#" -ge 1 ]; do
            find . -name "$1" -maxdepth 1 | sed -E 's~^./~~'
            shift
        done
    fi
}

# JavaScript+NodeJS
if [ "$runtime" = 'all' ] || [ "$runtime" = 'nodejs' ]; then
    printf '## JavaScript > NodeJS ##\n' >&2
    if [ ! -e "$HOME/.npmrc" ] || [ "$(wc -c <"$HOME/.npmrc")" -eq '0' ]; then
        printf '# Placeholder\n' >>"$HOME/.npmrc"
    fi
    ncu_target="$target"
    if [ "$target" = 'major' ]; then
        ncu_target='latest'
    fi
    glob 'package.json' | while read -r file; do
        if [ ! -e "$file" ]; then
            continue
        fi

        printf '# Updating NPM package file at %s\n' "$file" >&2

        if [ "$target" != 'lock' ]; then
            ncu --cwd "$(dirname "$file")" --target "$ncu_target" --upgrade # package.json
        fi

        directory="$(dirname "$file")"
        dirname="$(cd "$directory" >/dev/null 2>&1 && basename "$PWD")"
        tmpdir="$(mktemp -d)"
        cp "$directory/package.json" "$tmpdir/package.json"
        docker run --rm \
            --volume "$tmpdir:/app/$dirname:rw" \
            --volume "$HOME/.npmrc:/root/.npmrc:ro" \
            --env CYPRESS_INSTALL_BINARY='0' \
            --env PUPPETEER_SKIP_CHROMIUM_DOWNLOAD='true' \
            --env PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD='1' \
            --env NODE_OPTIONS='--dns-result-order=ipv4first' \
            --entrypoint '/bin/sh' \
            --user 'root' \
            node:latest \
            -c "cd \"/app/$dirname\" && npm install --ignore-scripts --no-progress --no-audit --no-fund --loglevel=error && npm dedupe --ignore-scripts --no-progress --no-audit --no-fund --loglevel=error"
        mv "$tmpdir/package-lock.json" "$directory/package-lock.json"
        rm -rf "$tmpdir"
    done
fi

# Python+Pip
if [ "$runtime" = 'all' ] || [ "$runtime" = 'python' ]; then
    printf '## Python > Pip ##\n' >&2
    glob '*requirements*.txt' | while read -r file; do
        if [ ! -e "$file" ]; then
            continue
        fi

        printf '# Updating pip requirements file at %s\n' "$file" >&2

        if [ "$target" = 'major' ]; then
            pur --force --requirement "$file"
        elif [ "$target" != 'lock' ]; then
            pur --force "--$target" '*' --requirement "$file"
        fi
    done

    # TODO: Also update Pipfile
fi

# Ruby+Gem
if [ "$runtime" = 'all' ] || [ "$runtime" = 'ruby' ]; then
    printf '## Ruby > Gem ##\n' >&2
    glob 'Gemfile' | while read -r file; do
        if [ ! -e "$file" ]; then
            continue
        fi

        printf '# Updating Gemfile file at %s\n' "$file" >&2
        tmpdir="$(mktemp -d)"

        if [ "$target" = 'major' ] || [ "$target" = 'minor' ] || [ "$target" = 'patch' ]; then
            (
                cd "$(dirname "$file")" &&
                    BUNDLE_DISABLE_SHARED_GEMS=true \
                        BUNDLE_FROZEN=false \
                        BUNDLE_PATH__SYSTEM=false \
                        BUNDLE_PATH="$tmpdir" \
                        BUNDLE_GEMFILE="$PWD/Gemfile" \
                        bundle install --quiet &&
                    BUNDLE_DISABLE_SHARED_GEMS=true \
                        BUNDLE_FROZEN=false \
                        BUNDLE_PATH__SYSTEM=false \
                        BUNDLE_PATH="$tmpdir" \
                        BUNDLE_GEMFILE="$PWD/Gemfile" \
                        bundle update --all "--$target" --quiet
            )
        fi

        (
            cd "$(dirname "$file")" &&
                bundle config set frozen false &&
                BUNDLE_DISABLE_SHARED_GEMS=true \
                    BUNDLE_PATH__SYSTEM=false \
                    BUNDLE_PATH="$tmpdir" \
                    BUNDLE_GEMFILE="$PWD/Gemfile" \
                    bundle lock --normalize-platforms
        )

        rm -rf "$tmpdir"
    done
fi

# Rust+Cargo
if [ "$runtime" = 'all' ] || [ "$runtime" = 'rust' ]; then
    printf '## Rust > Cargo ##\n' >&2
    glob 'Cargo.toml' | while read -r file; do
        if [ ! -e "$file" ]; then
            continue
        fi
        printf '# Updating cargo file at %s\n' "$file" >&2

        if [ "$target" = 'major' ]; then
            (cd "$(dirname "$file")" && cargo upgrade --incompatible) # main
        elif [ "$target" = 'minor' ]; then
            (cd "$(dirname "$file")" && cargo upgrade) # main
        fi
        (cd "$(dirname "$file")" && cargo update) # lock
    done
fi

# Gitman
if [ "$runtime" = 'all' ] || [ "$runtime" = 'gitman' ]; then
    printf '## Gitman ##\n' >&2
    glob 'gitman.yml' '.gitman.yml' | while read -r file; do
        if [ ! -e "$file" ]; then
            continue
        fi
        printf '# Updating gitman file at %s\n' "$file" >&2

        if [ "$target" != 'lock' ]; then
            (cd "$(dirname "$file")" && gitman update --force) # main
        else
            (cd "$(dirname "$file")" && gitman install --force --fetch) # no-file
        fi
        (cd "$(dirname "$file")" && gitman lock) # lock
    done
fi
