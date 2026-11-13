# Helper Makefile to group development tasks

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh  # for compatibility (mainly with redhat distros)
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))
PATH := $(PROJECT_DIR)/venv/bin:$(PATH)

# Define portable datetime format
define_log_function := log_timestamp() { date_supports_milliseconds="$$(date '+%3N')"; case "$${date_supports_milliseconds}" in [0-9][0-9][0-9]) milliseconds_format='%3N' ;; *) milliseconds_format='000' ;; esac; date "+%Y-%m-%dT%H:%M:%S.$${milliseconds_format}Z"; }; log() { log_level="$$1"; shift; log_timestamp="$$(log_timestamp)"; printf '%s\n' "$${*}" | while IFS= read -r log_message || [ -n "$${log_message}" ]; do printf '%s [%s]: %s\n' "$${log_timestamp}" "$$log_level" "$${log_message}"; done >&2; }

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build # NOTE: "install" intentionally left out
	$(define_log_function); log INFO 'All development tasks completed successfully'
	printf '\n'

.PHONY: bootstrap
bootstrap:
	$(define_log_function); log INFO 'Installing dependencies (native)'

	rm -rf './venv' && \
		python3 -m venv './venv'

	PATH="$${PWD}/venv/bin:$${PATH}" \
	PIP_DISABLE_PIP_VERSION_CHECK='1' \
	PYTHONDONTWRITEBYTECODE='1' \
		python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt'

	# Python dependencies
	printf '%s\n' './scripts/project-update' | \
	while read -r dir; do \
		cd "$(PROJECT_DIR)/$${dir}" && \
		PIP_DISABLE_PIP_VERSION_CHECK='1' \
		PYTHONDONTWRITEBYTECODE='1' \
			python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt' --target './python-vendor' && \
		find './python-vendor/bin' -type f | while read -r file; do \
			if cat "$${file}" | grep -E '^\#\!' >/dev/null 2>&1; then \
				content="$$(tail -n +2 "$${file}")" && \
				printf '#%s/usr/bin/env python3\n%s\n' '!' "$${content}" >"$${file}" && \
			true; fi && \
		true; done && \
	true; done

	# NodeJS dependencies
	printf '%s\n%s\n' \
		'./scripts/convert2pdf' \
		'./scripts/project-update' | \
	while read -r dir; do \
		cd "$(PROJECT_DIR)/$${dir}" && \
		npm ci --no-save --no-progress --no-audit --no-fund --loglevel=error && \
	true; done

	$(define_log_function); log INFO 'Dependencies installed successfully'
	printf '\n'

.PHONY: server-bootstrap
server-bootstrap:
	$(define_log_function); log INFO 'Installing dependencies (server)'

	rm -rf './venv' && \
		python3 -m venv './venv'

	PATH="$${PWD}/venv/bin:$${PATH}" \
	PIP_DISABLE_PIP_VERSION_CHECK='1' \
	PYTHONDONTWRITEBYTECODE='1' \
		python3 -m pip install --quiet --no-compile --require-hashes --requirement './requirements.txt'

	$(define_log_function); log INFO 'Dependencies installed successfully'
	printf '\n'

.PHONY: build
build:
	$(define_log_function); log INFO 'Building repository components'
	npm --prefix './scripts/convert2pdf' run build
	$(define_log_function); log INFO 'Build was successful'
	printf '\n'


.PHONY: install
install:
	$(define_log_function); log INFO 'Installing dotfiles'
	PATH="$(PROJECT_DIR)/venv/bin:$${PATH}" \
		dotbot -c './install.conf.yml'
	$(define_log_function); log INFO 'Dotfiles installed successfully'
	printf '\n'

.PHONY: server-install
server-install:
	$(define_log_function); log INFO 'Installing server dotfiles'
	PATH="$(PROJECT_DIR)/venv/bin:$${PATH}" \
		dotbot -c './install-server.conf.yml'
	$(define_log_function); log INFO 'Server dotfiles installed successfully'
	printf '\n'

.PHONY: clean
clean:
	# Check if there is an active virtualenv and abort
	$(define_log_function); \
	if [ -n "$${VIRTUAL_ENV+x}" ]; then \
		log ERROR 'There is an active python virtualenv. Run "deactivate" and try again.'; \
		exit 1; \
	fi

	$(define_log_function); log INFO 'Cleaning repository'

	find "$(PROJECT_DIR)" -type d \( \
		-name '.bundle' -or \
		-name '.mypy_cache' -or \
		-name 'build' -or \
		-name 'dist' -or \
		-name 'gitman-repositories' -or \
		-name 'node_modules' -or \
		-name 'python-vendor' -or \
		-name 'target' -or \
		-name 'test-report' -or \
		-name 'vendor' -or \
		-name 'venv' \
	\) -prune -exec rm -rf {} \;

	$(define_log_function); log INFO 'Repository cleaned'
	printf '\n'
