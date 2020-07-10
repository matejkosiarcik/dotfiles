#!/usr/bin/env python3
from typing import List
import sys
import os
import pathlib
import shutil
import argparse


files = [
    '.editorconfig',
    '.markdownlint.json',
    '.remarkrc',
    '.swiftlint.yml',
    '.yamllint.yml',
    '.pylintrc',
    'setup.cfg',
    os.path.join('.github', 'toc.yml'),
    os.path.join('.mergify', 'config.yml'),
]


def main(argv: List[str]):
    # parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--cwd', type=str, default='.', help='Path to project to update')
    parser.add_argument('--defaults', type=str, required=True, help='Path to defaults')
    parser.add_argument('-n', '--dry-run', action='store_true', default=False, help='Dry run')
    parser.add_argument('--init', action='store_true', default=False, help='Copy everything')
    parser.add_argument('-v', '--verbose', action='store_true', default=False, help='Additional logging')
    parser.add_argument('-i', '--interactive', action='store_true', default=False, help='Ask for not existent files')
    args = parser.parse_args(argv)

    # get source/target directories
    cwd = args.cwd
    defaults_dir = args.defaults
    assert os.path.exists(defaults_dir) and os.path.isdir(os.path.realpath(defaults_dir))
    dry_run = args.dry_run
    init = args.init
    verbose = args.verbose
    interactive = args.interactive

    def copy(source: str, target: str):
        if dry_run or verbose:
            print(f'Replace {os.path.basename(filepath)}')
        if not dry_run:
            if not os.path.exists(os.path.dirname(filepath)):
                os.mkdir(os.path.dirname(filepath))
            shutil.copyfile(defaults_filepath, filepath)

    # check all files
    for filename in files:
        filepath = os.path.join(cwd, filename)
        defaults_filepath = os.path.join(defaults_dir, filename)
        assert os.path.isfile(defaults_filepath)

        # if file exists, replace it
        if os.path.isfile(filepath):
            if not init:
                with open(filepath) as file:
                    file_str = file.read()
                with open(defaults_filepath) as default_file:
                    default_str = default_file.read()
                if file_str != default_str:
                    copy(defaults_filepath, filepath)
                elif verbose or dry_run:
                    print(f'No change {filename}')
            else:
                copy(defaults_filepath, filepath)
        else:
            if interactive:
                answer = input(f'Want to create {filename}? [y|N] ')
                if answer.lower() == 'y':
                    copy(defaults_filepath, filepath)
                elif verbose:
                    print(f'Ignore {filename}')
            elif verbose:
                print(f'Target missing {filename}')


if __name__ == "__main__":
    main(sys.argv[1:])
