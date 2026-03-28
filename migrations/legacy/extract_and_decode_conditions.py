#!/usr/bin/env python3
"""
extract_and_decode_conditions.py

Extract `conditions` hex blobs from the `INSERT INTO `players`` block in the
SQL dump `servidor_from_TFS.sql`, decode them using the existing
`conditions_decoder.py` logic and write a JSON and CSV summary to the
`migrations/legacy/` directory.

Produces:
  - players_conditions_decoded.json
  - players_conditions_summary.csv

Run from repository root:
  python migrations/legacy/extract_and_decode_conditions.py
"""
from __future__ import annotations

import importlib.util
import json
import os
import csv
import sys
from typing import List, Dict, Any

BASE = os.path.dirname(__file__)
SQL_FILE = os.path.join(BASE, "servidor_from_TFS.sql")
OUT_JSON = os.path.join(BASE, "players_conditions_decoded.json")
OUT_CSV = os.path.join(BASE, "players_conditions_summary.csv")
CONDITIONS_DECODER = os.path.join(BASE, "conditions_decoder.py")


def load_decoder_module(path: str):
    spec = importlib.util.spec_from_file_location("conditions_decoder", path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)  # type: ignore
    return module


def split_sql_tuple_fields(s: str) -> List[str]:
    fields: List[str] = []
    cur: List[str] = []
    in_quote = False
    i = 0
    while i < len(s):
        c = s[i]
        if c == "'":
            if not in_quote:
                in_quote = True
                cur.append(c)
                i += 1
                continue
            # in_quote is True
            # SQL escapes single quote by doubling it: ''
            if i + 1 < len(s) and s[i + 1] == "'":
                cur.append("'")
                i += 2
                continue
            # closing quote
            in_quote = False
            cur.append(c)
            i += 1
            continue

        if not in_quote and c == ',':
            fields.append(''.join(cur).strip())
            cur = []
            i += 1
            continue

        cur.append(c)
        i += 1

    if cur:
        fields.append(''.join(cur).strip())
    return fields


def unquote_sql_string(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == "'" and s[-1] == "'":
        inner = s[1:-1]
        return inner.replace("''", "'")
    return s


def extract_player_tuples(sql: str) -> List[str]:
    idx = sql.find("INSERT INTO `players`")
    if idx == -1:
        raise RuntimeError("players INSERT block not found in SQL dump")
    vals = sql.find("VALUES", idx)
    if vals == -1:
        raise RuntimeError("VALUES keyword not found for players insert")
    start = sql.find("(", vals)
    end = sql.find(");", vals)
    if start == -1 or end == -1:
        raise RuntimeError("Could not find tuples block boundaries")
    block = sql[start + 1:end]
    tuples = block.split("),\n(")
    # Clean parentheses on first/last
    if tuples:
        tuples[0] = tuples[0].lstrip()
        tuples[-1] = tuples[-1].rstrip()
    return tuples


def main() -> int:
    if not os.path.exists(SQL_FILE):
        print(f"SQL file not found: {SQL_FILE}")
        return 2

    decoder = load_decoder_module(CONDITIONS_DECODER)

    with open(SQL_FILE, 'r', encoding='utf-8', errors='replace') as fh:
        sql = fh.read()

    tuples = extract_player_tuples(sql)

    results: List[Dict[str, Any]] = []
    summary_rows: List[List[str]] = []

    for tup in tuples:
        fields = split_sql_tuple_fields(tup)
        if len(fields) < 25:
            # skip malformed tuple
            continue
        player_id = fields[0]
        try:
            pid = int(player_id)
        except Exception:
            pid = player_id

        name = unquote_sql_string(fields[1])
        cond_field = fields[24]
        hexstr = None
        if cond_field.startswith('0x') or cond_field.startswith('0X'):
            hexstr = cond_field[2:]
        elif cond_field == "''" or cond_field == "'" or cond_field == "":
            hexstr = ''
        else:
            # could be empty string specified as '' or other formats
            hexstr = ''

        decoded = []
        if hexstr:
            try:
                decoded = decoder.decode_hex_blob(hexstr)
            except Exception as e:
                decoded = [{"error": str(e)}]

        results.append({"id": pid, "name": name, "conditions": decoded})
        summary_rows.append([str(pid), name, str(len(decoded)), json.dumps(decoded, ensure_ascii=False)])

    with open(OUT_JSON, 'w', encoding='utf-8') as fh:
        json.dump(results, fh, indent=2, ensure_ascii=False)

    # CSV: id,name,num_conditions,conditions_json
    with open(OUT_CSV, 'w', encoding='utf-8', newline='') as fh:
        w = csv.writer(fh)
        w.writerow(['id', 'name', 'num_conditions', 'conditions_json'])
        for row in summary_rows:
            w.writerow(row)

    print(f"Wrote {OUT_JSON} and {OUT_CSV}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
