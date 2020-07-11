# Helper Makefile to group scripts for development

MAKEFLAGS += --warn-undefined-variables
.POSIX:

PROJECT_DIR := $(dir $(abspath $(MAKEFILE_LIST)))
SHELL := /bin/sh
.SHELLFLAGS := -ec
ACTIVATE_VENV := [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate

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
		python -m pip install --upgrade pip setuptools wheel && \
		python -m pip install --requirement requirements.txt \
	;else exit 1; fi

.PHONY: install
install:
	if $(ACTIVATE_VENV); then \
		dotbot -c install.conf.yaml \
	;else exit 1; fi
	sh 'setup/setup.sh'
