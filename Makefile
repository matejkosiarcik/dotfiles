# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh
.SHELLFLAGS := -ec
PROJECT_DIR := $(dir $(abspath $(MAKEFILE_LIST)))

# FIXME: make it compatible with windows (non-unix)
ACTIVATE_VENV := [ -n "$${VIRTUAL_ENV+x}" ] || [ -e /.dockerenv ] || . ./venv/bin/activate

.POSIX:

.DEFAULT: all
.PHONY: all
all: bootstrap install

.PHONY: bootstrap
bootstrap:
	# check if virtual environment exists or create it
	[ -n "$${VIRTUAL_ENV+x}" ] || [ -d venv ] \
		|| python3 -m venv venv \
		|| python -m venv venv \
		|| virtualenv venv \
		|| mkvirtualenv venv
	# install dependencies into existing or created virtual environment
	if $(ACTIVATE_VENV); then \
		pip install --upgrade pip && \
		pip install --requirement requirements.txt \
	;else exit 1; fi

.PHONY: install
install:
	if $(ACTIVATE_VENV); then \
		dotbot -c install.conf.yaml \
	;else exit 1; fi
