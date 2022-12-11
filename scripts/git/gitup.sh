#!/bin/sh
set -euf
# Update local repository
# Rebase working branch on top of default branch (usually main/master)

if [ "$(git status --short)" != '' ]; then
    printf 'You have uncommitted changes!\n'
    exit 1
fi

# Update local repo from remote
git fetch --all --tags --prune --prune-tags
git remote prune origin

# Determine current and default branch names
current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$current_branch" = 'HEAD' ]; then
    printf 'You have detached HEAD!\n'
    exit 1
fi
default_branch="$(git remote show origin | grep 'HEAD branch:' | sed -E 's~.+:[ \t]*~~')"

# Update current branch
if [ "$current_branch" = "$default_branch" ]; then
    # update main/master when it's checked
    git pull --ff-only
else
    # update main/master when we are on different branch
    git fetch origin "$default_branch:$default_branch"
fi

# Rebase working branch on top of main/master
if [ "$current_branch" != "$default_branch" ]; then
    git rebase "$default_branch" || {
        git rebase --abort
        printf 'Error during rebase.\n'
        exit 1
    }
fi

# Remove merged branches
git branch --merged "$default_branch" | grep -ve '\*' -e "$default_branch" -e "$current_branch" | xargs -n1 git branch -d

printf 'Done\n'
