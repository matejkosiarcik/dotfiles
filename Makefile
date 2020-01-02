# This Makefile does not contain any build steps
# It only groups scripts to use in project

MAKEFLAGS += --warn-undefined-variables

# ifeq ($(shell uname -s), "Darwin")
# 	bootstrap: mac_bootstrap
# endif
.PHONY: bootstrap
bootstrap: mac_bootstrap
	cd tests && npm install

.PHONY: mac_bootstrap
mac_bootstrap:
	if [ "$(uname -s)" = 'Darwin' ]; then brew bundle; fi

test: bats_test shell_test

bats_test:
	cd tests && npm run test

shell_test:
	sh 'home/install.sh'
	sh 'setup/install.sh'
	sh 'bin/install.sh'
