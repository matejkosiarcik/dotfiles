import os
import sys
import unicodedata
from typing import List


def main(args: List[str]):
    output = []
    for root, _, files in os.walk(args[0], topdown=False):
        for file in files:
            output.append(unicodedata.normalize("NFC", os.path.join(root, file)))
    output.sort(key=str.casefold)
    for file in output:
        print(file, end="\0")


if __name__ == "__main__":
    main(sys.argv[1:])
