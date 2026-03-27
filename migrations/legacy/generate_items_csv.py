#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate migrations/legacy/items.csv from data/items/items.xml (ISO-8859-1 encoded XML).

Writes CSV with columns: id,orig_fromid,orig_toid,name,article,attributes
Attributes is a JSON-encoded object (may be nested).
"""
import os
import json
import xml.etree.ElementTree as ET
import csv
import sys


def parse_attribute(elem):
    """Parse an <attribute> element recursively and return a Python value.
    If the element has nested <attribute> children, returns a dict.
    Otherwise returns the element's "value" (or None).
    """
    value = elem.get("value")
    children = [c for c in elem if c.tag == "attribute"]
    if children:
        d = {}
        if value is not None:
            d["_value"] = value
        for child in children:
            k = child.get("key")
            v = parse_attribute(child) if list(child) else child.get("value")
            if k in d:
                if isinstance(d[k], list):
                    d[k].append(v)
                else:
                    d[k] = [d[k], v]
            else:
                d[k] = v
        return d
    else:
        return value


def gather_attributes(item_elem):
    out = {}
    for attr in item_elem.findall("attribute"):
        key = attr.get("key")
        val = parse_attribute(attr)
        if key in out:
            if isinstance(out[key], list):
                out[key].append(val)
            else:
                out[key] = [out[key], val]
        else:
            out[key] = val
    return out


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    items_xml = os.path.normpath(os.path.join(here, '..', '..', 'data', 'items', 'items.xml'))
    out_csv = os.path.join(here, 'items.csv')

    if not os.path.exists(items_xml):
        print(f"ERROR: items.xml not found: {items_xml}", file=sys.stderr)
        sys.exit(2)

    # Parse XML (ElementTree will respect the XML encoding declaration)
    tree = ET.parse(items_xml)
    root = tree.getroot()

    rows = []
    for item in root.findall('item'):
        name = item.get('name') or ''
        article = item.get('article') or ''
        attrs = gather_attributes(item)
        id_attr = item.get('id')
        fromid = item.get('fromid')
        toid = item.get('toid')

        if id_attr is not None:
            rows.append({
                'id': int(id_attr),
                'orig_fromid': '',
                'orig_toid': '',
                'name': name,
                'article': article,
                'attributes': attrs,
            })
        elif fromid is not None and toid is not None:
            try:
                f = int(fromid)
                t = int(toid)
            except Exception:
                f = None
                t = None
            if f is not None and t is not None:
                for i in range(f, t + 1):
                    rows.append({
                        'id': i,
                        'orig_fromid': f,
                        'orig_toid': t,
                        'name': name,
                        'article': article,
                        'attributes': attrs,
                    })
            else:
                rows.append({
                    'id': '',
                    'orig_fromid': fromid,
                    'orig_toid': toid,
                    'name': name,
                    'article': article,
                    'attributes': attrs,
                })
        elif fromid is not None:
            rows.append({
                'id': int(fromid) if fromid.isdigit() else '',
                'orig_fromid': fromid,
                'orig_toid': '',
                'name': name,
                'article': article,
                'attributes': attrs,
            })
        else:
            rows.append({
                'id': '',
                'orig_fromid': '',
                'orig_toid': '',
                'name': name,
                'article': article,
                'attributes': attrs,
            })

    def sort_key(r):
        try:
            return int(r['id'])
        except Exception:
            return float('inf')

    rows.sort(key=sort_key)

    # Write CSV (UTF-8)
    with open(out_csv, 'w', encoding='utf-8', newline='') as fh:
        writer = csv.DictWriter(fh, fieldnames=['id', 'orig_fromid', 'orig_toid', 'name', 'article', 'attributes'])
        writer.writeheader()
        for r in rows:
            out = r.copy()
            out['attributes'] = json.dumps(r['attributes'], ensure_ascii=False)
            writer.writerow(out)

    print(f"Wrote {len(rows)} rows to {out_csv}")


if __name__ == '__main__':
    main()
