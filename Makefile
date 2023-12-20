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
all: clean bootstrap build # NOTE: "install" intentionally left out

.PHONY: bootstrap
bootstrap:
	python3 -m venv venv

	PATH="$$PWD/venv/bin:$$PATH" \
	PIP_DISABLE_PIP_VERSION_CHECK=1 \
		python3 -m pip install --requirement requirements.txt --quiet --upgrade

	# Python dependencies
	printf '%s\n%s\n%s\n%s\n%s\n' \
		deamons/notes-attachments-import \
		deamons/photo-import \
		deamons/screenrecording-rename \
		deamons/screenshots-rename \
		scripts/project-update | \
	while read -r dir; do \
		cd "$(PROJECT_DIR)/$$dir" && \
		PIP_DISABLE_PIP_VERSION_CHECK=1 \
			python3 -m pip install --requirement requirements.txt --target python --quiet --upgrade && \
		find python/bin -type f | while read -r file; do \
			if cat "$$file" | grep -E '^\#\!' >/dev/null 2>&1; then \
				content="$$(tail -n +2 "$$file")" && \
				printf '#%s/usr/bin/env python3\n%s\n' '!' "$$content" >"$$file" && \
			true; fi && \
		true; done && \
	true; done

	# NodeJS dependencies
	printf '%s\n%s\n' \
		scripts/convert2pdf \
		scripts/project-update | \
	while read -r dir; do \
		cd "$(PROJECT_DIR)/$$dir" && \
		npm install --no-save --no-progress --no-audit --quiet && \
	true; done

.PHONY: build
build:
	npm --prefix scripts/convert2pdf run build

.PHONY: install
install:
	PATH="$(PROJECT_DIR)/venv/bin:$$PATH" \
		dotbot -c install.conf.yml

.PHONY: clean
clean:
	rm -rf venv
	rm -rf deamons/notes-attachments-import/python
	rm -rf deamons/photo-import/python
	rm -rf deamons/screenrecording-rename/python
	rm -rf deamons/screenshots-rename/python
	rm -rf scripts/convert2pdf/node_modules
	rm -rf scripts/convert2pdf/dist
	rm -rf scripts/project-update/node_modules
	rm -rf scripts/project-update/python
