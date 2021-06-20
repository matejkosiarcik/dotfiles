#!/usr/bin/env python3

import hashlib
import os
import re
import sys
import unicodedata
from os import path
from typing import List


# Basically just list files in a given directory
# - normalizes unicode output encoding
# - sorts files alphabetically (case insensitive)
def main(args: List[str]):
    root_dir = os.path.abspath(os.path.realpath(args[0]))
    print(f"Searching {root_dir}", file=sys.stderr)

    found_files = []
    for root, _, files in os.walk(root_dir, topdown=False):
        for file in files:
            filepath = unicodedata.normalize("NFC", os.path.join(root, file))
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
