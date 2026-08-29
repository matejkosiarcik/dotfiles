#!/usr/bin/env python3

import argparse
import hashlib
import os
import re
import sys
import unicodedata
from os import path


# - Search files in given directory and return all of them recursively
# - Sorts files alphabetically (case insensitive and unicode encoding normalized)
def get_files(dir_path: str) -> list[str]:
    if not path.exists(dir_path):
        raise FileNotFoundError(f"Directory {dir_path} does not exist")

    found_files = []
    for directory_path, _, file_names in os.walk(dir_path, topdown=False):
        for file in file_names:
            file_path_full = path.join(directory_path, file)
            if path.exists(file_path_full) and path.isfile(file_path_full) and not path.islink(file_path_full):
                file_path_full = re.sub(f"{dir_path}/", "./", file_path_full, count=1)
                found_files.append(file_path_full)

    found_files.sort(key=lambda x: unicodedata.normalize("NFC", str.lower(x)))
    return found_files


def get_file_hash(filepath: str) -> str:
    if not path.exists(filepath):
        raise FileNotFoundError(f'File "{filepath}" does not exist')

    with open(filepath, "rb") as open_file:
        sha = hashlib.sha256()
        while buffer := open_file.read(16 * 1024 * 1024):
            sha.update(buffer)
        return sha.hexdigest()


# - Computes sha hash of individual files
# - Outputs in format "HASH FILE"
def main(argv: list[str]):
    # parse arguments
    parser = argparse.ArgumentParser(prog="dir2sha")
    parser.add_argument("directory", type=str, help="Root directory to search and analyze")
    args = parser.parse_args(argv)

    root_directory_path = args.directory
    if not path.exists(root_directory_path):
        raise FileNotFoundError(f"Directory {root_directory_path} does not exist")
    root_directory_path = path.abspath(path.realpath(root_directory_path))
    print(f"Analyzing {root_directory_path}", file=sys.stderr)

    found_files = get_files(root_directory_path)
    files_all_count = len(found_files)

    for [index, file_path] in enumerate(found_files):
        file_path_full = path.join(root_directory_path, re.sub("./", "", file_path, count=1))
        file_path_partial = unicodedata.normalize("NFC", file_path)
        file_hash = get_file_hash(file_path_full)
        print(f"{file_hash} {file_path_partial}", flush=True)

        files_done_count = index + 1
        files_done_percent = f"{(files_done_count / files_all_count * 100):.2f}"

        print(f"\rProgress {str(files_done_count).rjust(len(str(files_all_count)), ' ')} / {files_all_count} - {files_done_percent.rjust(6, ' ')}%", end="", file=sys.stderr)

    print("\nDone\n", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1:])
