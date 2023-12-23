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
# NOTE: Test and remove below lines if new version is working reliably
# git fetch --all --tags --prune --prune-tags
# git remote prune origin

# Determine current and default branch names
current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$current_branch" = 'HEAD' ]; then
    printf 'You have detached HEAD, stopping.\n' >&2
    exit 1
fi
default_branch="$(git remote show origin | grep 'HEAD branch:' | sed -E 's~.+:[ \t]*~~')"

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
        printf 'There was problem during plain rebase. Trying rebase with "--onto".\n' >&2
        git rebase --onto "$default_branch" "origin/$current_branch" || {
            printf 'There was problem during `rebase --onto`. You need to resolve conflicts before manually.\n' >&2
            exit 1
        }
    }
fi

# Prune local things which no longer have remote equivalent
git fetch --all --tags --prune --prune-tags
git remote prune origin

# Remove local leftover branches which no longer exist on remote, eg. dependabot branches
git branch --merged "$default_branch" | grep -ve '\*' -e "$default_branch" -e "$current_branch" | xargs -n1 git branch -d

printf 'Done\n'
