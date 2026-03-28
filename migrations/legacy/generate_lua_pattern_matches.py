#!/usr/bin/env python3
"""
generate_lua_pattern_matches.py

Scan Lua files and write a CSV with file,line,pattern,line_text for every
match of selected patterns. Useful to prioritize manual fixes.
"""
from __future__ import annotations

import os
import re
import csv
from typing import List

BASE = os.path.dirname(__file__)
REPO_ROOT = os.path.abspath(os.path.join(BASE, '..', '..'))
DATA_DIR = os.path.join(REPO_ROOT, 'data')
OUT_CSV = os.path.join(BASE, 'lua_pattern_matches.csv')

PATTERNS = [
    'doPlayerAddItem',
    'doSendMagicEffect',
    'getPlayerStorageValue',
    'setPlayerStorageValue',
    'createItem',
    'doTeleportThing',
    'addEvent',
    'registerCreatureEvent',
    'registerEvent',
    'doPlayerSendTextMessage',
]


def find_lua_files(root: str) -> List[str]:
    files: List[str] = []
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn.lower().endswith('.lua'):
                files.append(os.path.join(dirpath, fn))
    return files


def scan_files(files: List[str]):
    compiled = [(p, re.compile(re.escape(p))) for p in PATTERNS]
    rows = []
    for f in files:
        try:
            with open(f, 'r', encoding='utf-8', errors='replace') as fh:
                for num, line in enumerate(fh, start=1):
                    for name, regex in compiled:
                        if regex.search(line):
                            rows.append((f, num, name, line.strip()))
        except Exception:
            continue
    return rows


def main() -> int:
    lua_files = find_lua_files(DATA_DIR)
    rows = scan_files(lua_files)

    with open(OUT_CSV, 'w', encoding='utf-8', newline='') as fh:
        w = csv.writer(fh)
        w.writerow(['file', 'line', 'pattern', 'text'])
        for r in rows:
            w.writerow(r)

    print(f'Wrote {OUT_CSV} ({len(rows)} matches)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
