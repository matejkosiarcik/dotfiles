#!/usr/bin/env python3

import hashlib
import os
import re
import sys
import unicodedata
import argparse
from os import path
from typing import List

# Basically does:
# - Search files in given directory
# - Normalizes unicode encoding for all files (important when running this on multiple systems to get the same output)
# - Sorts files alphabetically (case insensitive)
# - Computes sha1 hash of individual files
# - Outputs in format "HASH FILE"
def main(argv: List[str]):
    # parse arguments
    parser = argparse.ArgumentParser(prog="dir2sha")
    parser.add_argument("directory", type=str, help="Root directory to search and analyze")
    args = parser.parse_args(argv)

    assert path.exists(args.directory), "Root directory should exist"
    root_dir = path.abspath(path.realpath(args.directory))
    print(f"Searching {root_dir}", file=sys.stderr)

    found_files = []
    for root, _, files in os.walk(root_dir, topdown=False):
        for file in files:
            filepath = unicodedata.normalize("NFC", path.join(root, file))
            if path.exists(filepath) and path.isfile(filepath):
                found_files.append(filepath)

    print(f"Found {len(found_files)} files", file=sys.stderr)
    found_files.sort(key=str.casefold)
    print("Sorted files", file=sys.stderr)

    for file in found_files:
        with open(file, "rb") as open_file:
            sha = hashlib.sha1()
            while buffer := open_file.read(1024 * 1024):
                sha.update(buffer)
            output_hash = sha.hexdigest()
            output_file = re.sub(fr"^{root_dir}/?", "", file)
            print(f"{output_hash} {output_file}")


if __name__ == "__main__":
    main(sys.argv[1:])
