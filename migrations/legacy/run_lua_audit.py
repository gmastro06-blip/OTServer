#!/usr/bin/env python3
"""
run_lua_audit.py

Scan repository Lua scripts under `data/` and produce two reports:
 - lua_audit_top_files.txt : top Lua files by line count
 - lua_audit_pattern_counts.txt : counts of selected API patterns across files

This produces UTF-8 plain text outputs (fixes earlier encoding issue).
"""
from __future__ import annotations

import os
import re
from collections import Counter
from typing import List

BASE = os.path.dirname(__file__)
# repo root is two levels up from migrations/legacy
REPO_ROOT = os.path.abspath(os.path.join(BASE, '..', '..'))
DATA_DIR = os.path.join(REPO_ROOT, "data")
OUT_TOP = os.path.join(BASE, "lua_audit_top_files.txt")
OUT_PATTERNS = os.path.join(BASE, "lua_audit_pattern_counts.txt")

PATTERNS = [
    r"doPlayerAddItem",
    r"doSendMagicEffect",
    r"getPlayerStorageValue",
    r"setPlayerStorageValue",
    r"createItem",
    r"doTeleportThing",
    r"addEvent",
    r"registerCreatureEvent",
    r"registerEvent",
    r"doPlayerSendTextMessage",
]


def find_lua_files(root: str) -> List[str]:
    files: List[str] = []
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn.lower().endswith('.lua'):
                files.append(os.path.join(dirpath, fn))
    return files


def analyze_files(files: List[str]):
    file_lines = []
    pattern_counts = Counter()
    pat_regex = [(p, re.compile(p)) for p in PATTERNS]

    for f in files:
        try:
            with open(f, 'r', encoding='utf-8', errors='replace') as fh:
                lines = fh.readlines()
        except Exception:
            continue

        file_lines.append((f, len(lines)))
        text = ''.join(lines)
        for name, regex in pat_regex:
            count = len(regex.findall(text))
            if count:
                pattern_counts[name] += count

    file_lines.sort(key=lambda x: x[1], reverse=True)
    return file_lines, pattern_counts


def main() -> int:
    lua_files = find_lua_files(DATA_DIR)
    file_lines, pattern_counts = analyze_files(lua_files)

    with open(OUT_TOP, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join([f"{n:6d} {p}" for p, n in file_lines]))

    with open(OUT_PATTERNS, 'w', encoding='utf-8') as fh:
        for pat, cnt in pattern_counts.most_common():
            fh.write(f"{pat}: {cnt}\n")

    print(f"Wrote {OUT_TOP} and {OUT_PATTERNS} (scanned {len(lua_files)} .lua files)")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
