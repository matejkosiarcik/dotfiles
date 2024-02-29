#!/bin/sh
set -euf
# Update local repository
# Rebase working branch on top of default branch (usually main/master)

if [ "$(git status --short)" != '' ]; then
    printf 'You have uncommitted changes, stopping.\n' >&2
    exit 1
fi

# Update local repo from remote
git fetch --all --tags --no-prune

# Determine current and default branch names
current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$current_branch" = 'HEAD' ]; then
    printf 'You have detached HEAD, stopping.\n' >&2
    exit 1
fi
default_branch="$(git remote show origin | grep 'HEAD branch:' | sed -E 's~.+:[ \t]*~~')"
if [ "$default_branch" != 'master' ] && [ "$default_branch" != 'main' ]; then
    printf 'Default branch is %s.\n' "$default_branch" >&2
    printf 'Proceed anyway? [Y]es | [N]o :' >&2
    read -r proceed_1
    printf '\n' >&2
    if [ "$proceed_1" != 'y' ] && [ "$proceed_1" != 'Y' ]; then
        exit 0
    fi
fi

# Update current branch
if [ "$current_branch" = "$default_branch" ]; then
    # update main/master when it's checked
    git pull --ff-only --no-prune
else
    # update main/master when we are on different branch
    git fetch origin "$default_branch:$default_branch" --no-prune
fi

# Rebase working branch on top of main/master
if [ "$current_branch" != "$default_branch" ]; then
    git rebase "$default_branch" || {
        git rebase --abort

        printf 'There was problem during plain rebase.\n' >&2
        printf 'Continue with rebase --onto? [Y]es | [N]o :' >&2
        read -r next_step
        printf '\n' >&2

        if [ "$next_step" = 'y' ] || [ "$next_step" = 'Y' ]; then
            git rebase --onto "$default_branch" "origin/$current_branch" || {
                printf 'There was problem during `rebase --onto` as well.\n' >&2
                printf 'You need to resolve conflicts manually.\n' >&2
                exit 1
            }
        fi
    }
fi

# Prune local things which no longer have remote equivalent
git fetch --all --tags --prune --prune-tags
git remote prune origin

# Remove local leftover branches which no longer exist on remote, eg. dependabot branches
git branch --merged "$default_branch" | grep -ve '\*' -e "$default_branch" -e "$current_branch" | xargs -n1 git branch -d

printf 'Done\n'
