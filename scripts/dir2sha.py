#!/usr/bin/env python3

import os
import re
import subprocess
import sys
import unicodedata
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
            found_files.append(unicodedata.normalize("NFC", os.path.join(root, file)))

    print(f"Found {len(found_files)} files", file=sys.stderr)
    found_files.sort(key=str.casefold)
    print("Sorted files", file=sys.stderr)

    for file in found_files:
        output = subprocess.check_output(["shasum", "--binary", file], shell=False).decode("utf-8")
        # output = unicodedata.normalize("NFC", output)
        output = re.sub(fr"^([0-9a-f]+) [ *]{root_dir}(.+)$", r"\1 \2", output).strip()
        print(output)


if __name__ == "__main__":
    main(sys.argv[1:])
