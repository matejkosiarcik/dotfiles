import os
import sys
import unicodedata
from typing import List


# Basically just list files in a given directory
# - normalizes unicode output encoding
# - sorts files alphabetically (case insensitive)
def main(args: List[str]):
    output_files = []
    for root, _, files in os.walk(args[0], topdown=False):
        for file in files:
            output_files.append(unicodedata.normalize("NFC", os.path.join(root, file)))
    output_files.sort(key=str.casefold)
    for file in output_files:
        print(file, end="\0")


if __name__ == "__main__":
    main(sys.argv[1:])
