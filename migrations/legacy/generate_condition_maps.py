#!/usr/bin/env python3
"""
generate_condition_maps.py

Parse `src/condition.h` and `src/enums.h` to extract mappings for
`ConditionAttr_t` and `ConditionType_t` and emit JSON maps for easier
consumption by migration tooling.

Outputs:
 - condition_attr_map.json
 - condition_type_map.json
"""
from __future__ import annotations

import json
import os
import re
from typing import Dict

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
COND_H = os.path.join(ROOT, 'src', 'condition.h')
ENUMS_H = os.path.join(ROOT, 'src', 'enums.h')
OUT_ATTR = os.path.join(os.path.dirname(__file__), 'condition_attr_map.json')
OUT_TYPE = os.path.join(os.path.dirname(__file__), 'condition_type_map.json')


def parse_enum_block(text: str, enum_name: str) -> Dict[str, str]:
    # Find enum block
    m = re.search(r'enum\s+' + re.escape(enum_name) + r'\s*\{([\s\S]*?)\};', text)
    if not m:
        return {}
    body = m.group(1)
    items = []
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith('//'):
            continue
        # remove trailing comments
        line = re.sub(r'//.*', '', line).strip()
        # split by comma
        parts = [p.strip() for p in line.split(',') if p.strip()]
        for p in parts:
            if p:
                items.append(p)

    result = {}
    cur = 0
    for it in items:
        if '=' in it:
            name, expr = [s.strip() for s in it.split('=', 1)]
            # evaluate simple expressions like '1 << 3' or decimal literals
            expr = expr.replace('\t', ' ')
            if '<<' in expr:
                left, right = [x.strip() for x in expr.split('<<')]
                val = int(left) << int(right)
            else:
                try:
                    val = int(expr, 0)
                except Exception:
                    # fallback - store expression raw
                    val = expr
            result[name] = val
            if isinstance(val, int):
                cur = val + 1
        else:
            name = it
            result[name] = cur
            cur += 1

    return result


def main() -> int:
    with open(COND_H, 'r', encoding='utf-8') as fh:
        cond_text = fh.read()

    with open(ENUMS_H, 'r', encoding='utf-8') as fh:
        enums_text = fh.read()

    attr_map = parse_enum_block(cond_text, 'ConditionAttr_t')
    type_map = parse_enum_block(enums_text, 'ConditionType_t')

    with open(OUT_ATTR, 'w', encoding='utf-8') as fh:
        json.dump(attr_map, fh, indent=2, ensure_ascii=False)

    with open(OUT_TYPE, 'w', encoding='utf-8') as fh:
        json.dump(type_map, fh, indent=2, ensure_ascii=False)

    print(f"Wrote {OUT_ATTR} and {OUT_TYPE}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
