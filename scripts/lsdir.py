#!/usr/bin/env python3

import argparse
import os
import re
import sys
import unicodedata
from os import path
from typing import List


# Search files in given directory
# Remove root path (only output relative )
# Normalizes unicode encoding for all files (important when running this on multiple systems to get the same output)
# Sorts files alphabetically (case insensitive)
def get_files(dir_path: str) -> List[str]:
    found_files = []
    for root, _, files in os.walk(dir_path, topdown=False):
        for file in files:
            filepath = unicodedata.normalize("NFC", path.join(root, file))
            filepath = re.sub(rf"^{dir_path}/?", "", filepath)
            if path.exists(filepath) and path.isfile(filepath):
                found_files.append(filepath)

    found_files.sort(key=str.casefold)
    return found_files


def main(argv: List[str]):
    # parse arguments
    parser = argparse.ArgumentParser(prog="lsdir")
    parser.add_argument("directory", type=str, help="Root directory to search and analyze")
    args = parser.parse_args(argv)

    root_dir = args.directory
    root_dir = path.abspath(path.realpath(root_dir))
    if not path.exists(root_dir):
        raise FileNotFoundError(f"Directory {root_dir} does not exist")
    print(f"Searching {root_dir}", file=sys.stderr)

    found_files = get_files(args.directory)
    print(f"Found {len(found_files)} files", file=sys.stderr)

    for file in found_files:
        print(file)


if __name__ == "__main__":
    main(sys.argv[1:])
