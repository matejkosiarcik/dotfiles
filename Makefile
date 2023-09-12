# Helper Makefile to group development tasks

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh  # for compatibility (mainly with redhat distros)
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))
PATH := $(PROJECT_DIR)/venv/bin:$(PATH)

.POSIX:
.SILENT:

.DEFAULT: all
.PHONY: all
all: clean bootstrap build # `install` intentionally left out

.PHONY: bootstrap
bootstrap:
	# Check if virtual environment exists or create it
	[ -n "$${VIRTUAL_ENV+x}" ] || \
		[ -d venv ] \
		|| python3 -m venv venv \
		|| python -m venv venv \
		|| virtualenv venv \
		|| mkvirtualenv venv

	# Install project dependencies
	PATH="$$PWD/venv/bin:$$PATH" \
		python3 -m pip install --requirement requirements.txt

	# Python dependencies
	printf '%s\n%s\n%s\n%s\n' deamons/photo-import deamons/screenrecording-rename deamons/screenshots-rename scripts/project-update | \
	while read -r dir; do \
		cd "$(PROJECT_DIR)/$$dir" && \
		python3 -m venv venv && \
		PATH="$$PWD/venv/bin:$$PATH" \
		PIP_DISABLE_PIP_VERSION_CHECK=1 \
			python3 -m pip install --requirement requirements.txt --quiet --upgrade && \
	true; done

	# NodeJS dependencies
	printf '%s\n%s\n' scripts/photos-to-pdf scripts/project-update | \
	while read -r dir; do \
		cd "$(PROJECT_DIR)/$$dir" && \
		npm install --no-save --no-progress --no-audit --quiet && \
	true; done

.PHONY: build
build:
	npm --prefix scripts/photos-to-pdf run build

.PHONY: install
install:
	dotbot -c install.conf.yml

.PHONY: clean
clean:
	rm -rf venv
	rm -rf deamons/photo-import/venv
	rm -rf deamons/screenrecording-rename/venv
	rm -rf deamons/screenshots-rename/venv
	rm -rf scripts/photos-to-pdf/node_modules
	rm -rf scripts/photos-to-pdf/dist
	rm -rf scripts/project-update/node_modules
	rm -rf scripts/project-update/venv
