#!/bin/sh
set -euf
cd "$(dirname "${0}")"

### Individual language packages ###

gem install bundler
bundle config set system 'true'
bundle install --gemfile 'other/Gemfile'
bundle config set system 'false'

pip3 install --requirement 'other/requirements.txt'

sed -E 's~(\s*)#(.*)~~' <'other/npm.txt' | grep -vE '^(\s*)$' | xargs npm install --global

sed -E 's~(\s*)#(.*)~~' <'other/cargo.txt' | grep -vE '^(\s*)$' | xargs cargo install

sed -E 's~(\s*)#(.*)~~' <'other/stack.txt' | grep -vE '^(\s*)$' | xargs stack install
