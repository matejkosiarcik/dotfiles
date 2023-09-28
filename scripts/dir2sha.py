#!/usr/bin/env python3

import argparse
import hashlib
import os
import re
import sys
import unicodedata
from os import path
from typing import List


# - Search files in given directory
# - Normalizes unicode encoding for all files (important when running this on multiple systems to get the same output)
# - Sorts files alphabetically (case insensitive)
def get_files(dir_path: str) -> List[str]:
    if not path.exists(dir_path):
        raise FileNotFoundError(f"Directory {dir_path} does not exist")

    found_files = []
    for root, _, files in os.walk(dir_path, topdown=False):
        for file in files:
            filepath = unicodedata.normalize("NFC", path.join(root, file))
            if path.exists(filepath) and path.isfile(filepath):
                filepath = re.sub(rf"^{dir_path}/?", "", filepath)
                found_files.append(filepath)

    found_files.sort(key=str.casefold)
    return found_files


def get_file_hash(filepath: str) -> str:
    if not path.exists(filepath):
        raise FileNotFoundError(f"File {filepath} does not exist")

    with open(filepath, "rb") as open_file:
        sha = hashlib.sha1()
        while buffer := open_file.read(1024 * 1024):
            sha.update(buffer)
        return sha.hexdigest()


# - Computes sha1 hash of individual files
# - Outputs in format "HASH FILE"
def main(argv: List[str]):
    # parse arguments
    parser = argparse.ArgumentParser(prog="dir2sha")
    parser.add_argument("directory", type=str, help="Root directory to search and analyze")
    args = parser.parse_args(argv)

    root_dir = args.directory
    if not path.exists(root_dir):
        raise FileNotFoundError(f"Directory {root_dir} does not exist")
    root_dir = path.abspath(path.realpath(root_dir))
    print(f"Searching files in: {root_dir}", file=sys.stderr)

    found_files = get_files(args.directory)
    files_all_count = len(found_files)
    files_done_count = 0

    print(f"Total files: {files_all_count}", file=sys.stderr)
    for file in found_files:
        file_hash = get_file_hash(path.join(root_dir, file))
        print(f"{file_hash} {file}")
        files_done_count += 1
        files_done_percent = f"{(files_done_count / files_all_count * 100):.2f}"
        print(f"\rIn progress: {str(files_done_count).rjust(len(str(files_all_count)), ' ')} {files_done_percent}%", end="", file=sys.stderr)
    print(f"\nFinished: {root_dir}", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv[1:])
