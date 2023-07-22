# Helper Makefile to group development tasks

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/sh  # for compatibility (mainly with redhat distros)
.SHELLFLAGS := -ec
PROJECT_DIR := $(abspath $(dir $(MAKEFILE_LIST)))

# Modify PATH to access dependency binaries
PATH := $(PROJECT_DIR)/venv/bin:$(PATH)

.POSIX:

.DEFAULT: all
.PHONY: all
all: clean bootstrap install

.PHONY: bootstrap
bootstrap:
	# check if virtual environment exists or create it
	[ -n "$${VIRTUAL_ENV+x}" ] || \
		[ -d venv ] \
		|| python3 -m venv venv \
		|| python -m venv venv \
		|| virtualenv venv \
		|| mkvirtualenv venv

	# install dependencies
	pip install --requirement requirements.txt

.PHONY: install
install:
	dotbot -c install.conf.yml

.PHONY: clean
clean:
	rm -rf venv
