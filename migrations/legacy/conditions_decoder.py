#!/usr/bin/env python3
"""
conditions_decoder.py

Small prototype to decode Forgotten Server `players.conditions` PropStream blobs
into a JSON-friendly structure. It implements the PropStream reading logic used
in the server (little-endian native-width copies) and decodes the common
Condition attributes (type, id, ticks, outfit, skills, intervals, light, etc.).

Usage examples:
  python migrations/legacy/conditions_decoder.py --hex 010004000002FFFFFFFF0360EA00001A001B00000000FE
  python migrations/legacy/conditions_decoder.py --csv players_conditions_sample.csv

This is a prototype — it covers the attributes implemented in the current
server sources and is tolerant to missing optional attributes.
"""
from __future__ import annotations

import argparse
import binascii
import csv
import json
import struct
import sys
from typing import Any, Dict, List

# ConditionAttr_t values (from src/condition.h)
CONDITIONATTR_TYPE = 1
CONDITIONATTR_ID = 2
CONDITIONATTR_TICKS = 3
CONDITIONATTR_HEALTHTICKS = 4
CONDITIONATTR_HEALTHGAIN = 5
CONDITIONATTR_MANATICKS = 6
CONDITIONATTR_MANAGAIN = 7
CONDITIONATTR_DELAYED = 8
CONDITIONATTR_OWNER = 9
CONDITIONATTR_INTERVALDATA = 10
CONDITIONATTR_SPEEDDELTA = 11
CONDITIONATTR_FORMULA_MINA = 12
CONDITIONATTR_FORMULA_MINB = 13
CONDITIONATTR_FORMULA_MAXA = 14
CONDITIONATTR_FORMULA_MAXB = 15
CONDITIONATTR_LIGHTCOLOR = 16
CONDITIONATTR_LIGHTLEVEL = 17
CONDITIONATTR_LIGHTTICKS = 18
CONDITIONATTR_LIGHTINTERVAL = 19
CONDITIONATTR_SOULTICKS = 20
CONDITIONATTR_SOULGAIN = 21
CONDITIONATTR_SKILLS = 22
CONDITIONATTR_STATS = 23
CONDITIONATTR_OUTFIT = 24
CONDITIONATTR_PERIODDAMAGE = 25
CONDITIONATTR_ISBUFF = 26
CONDITIONATTR_SUBID = 27
CONDITIONATTR_ISAGGRESSIVE = 28
CONDITIONATTR_DISABLEDEFENSE = 29
CONDITIONATTR_SPECIALSKILLS = 30
CONDITIONATTR_MANASHIELD_BREAKABLE_MANA = 31
CONDITIONATTR_MANASHIELD_BREAKABLE_MAXMANA = 32
CONDITIONATTR_END = 254

# ConditionType_t flags (from src/enums.h)
CONDITION_TYPE_FLAGS = {
    1 << 0: "CONDITION_POISON",
    1 << 1: "CONDITION_FIRE",
    1 << 2: "CONDITION_ENERGY",
    1 << 3: "CONDITION_BLEEDING",
    1 << 4: "CONDITION_HASTE",
    1 << 5: "CONDITION_PARALYZE",
    1 << 6: "CONDITION_OUTFIT",
    1 << 7: "CONDITION_INVISIBLE",
    1 << 8: "CONDITION_LIGHT",
    1 << 9: "CONDITION_MANASHIELD",
    1 << 10: "CONDITION_INFIGHT",
    1 << 11: "CONDITION_DRUNK",
    1 << 12: "CONDITION_EXHAUST_WEAPON",
    1 << 13: "CONDITION_REGENERATION",
    1 << 14: "CONDITION_SOUL",
    1 << 15: "CONDITION_DROWN",
    1 << 16: "CONDITION_MUTED",
    1 << 17: "CONDITION_CHANNELMUTEDTICKS",
    1 << 18: "CONDITION_YELLTICKS",
    1 << 19: "CONDITION_ATTRIBUTES",
    1 << 20: "CONDITION_FREEZING",
    1 << 21: "CONDITION_DAZZLED",
    1 << 22: "CONDITION_CURSED",
    1 << 23: "CONDITION_EXHAUST_COMBAT",
    1 << 24: "CONDITION_EXHAUST_HEAL",
    1 << 25: "CONDITION_PACIFIED",
    1 << 26: "CONDITION_SPELLCOOLDOWN",
    1 << 27: "CONDITION_SPELLGROUPCOOLDOWN",
    1 << 28: "CONDITION_ROOT",
    1 << 29: "CONDITION_MANASHIELD_BREAKABLE",
}


class Reader:
    def __init__(self, data: bytes) -> None:
        self.data = data
        self.i = 0

    def remaining(self) -> int:
        return len(self.data) - self.i

    def _read(self, fmt: str) -> Any:
        size = struct.calcsize(fmt)
        if self.remaining() < size:
            raise EOFError("truncated data")
        val = struct.unpack_from(fmt, self.data, self.i)
        self.i += size
        return val[0] if len(val) == 1 else val

    def read_u8(self) -> int:
        return self._read("<B")

    def read_u16(self) -> int:
        return self._read("<H")

    def read_u32(self) -> int:
        return self._read("<I")

    def read_i32(self) -> int:
        return self._read("<i")

    def read_f32(self) -> float:
        return self._read("<f")

    def read_bool(self) -> bool:
        return bool(self.read_u8())

    def read_interval(self) -> Dict[str, int]:
        return {
            "timeLeft": self.read_i32(),
            "value": self.read_i32(),
            "interval": self.read_i32(),
        }

    def read_outfit(self) -> Dict[str, int]:
        # Outfit_t layout from src/enums.h
        out = {}
        out["lookType"] = self.read_u16()
        out["lookTypeEx"] = self.read_u16()
        out["lookHead"] = self.read_u8()
        out["lookBody"] = self.read_u8()
        out["lookLegs"] = self.read_u8()
        out["lookFeet"] = self.read_u8()
        out["lookAddons"] = self.read_u8()
        out["lookMount"] = self.read_u16()
        out["lookMountHead"] = self.read_u8()
        out["lookMountBody"] = self.read_u8()
        out["lookMountLegs"] = self.read_u8()
        out["lookMountFeet"] = self.read_u8()
        return out


def condition_type_names(mask: int) -> List[str]:
    names: List[str] = []
    for bit, name in CONDITION_TYPE_FLAGS.items():
        if mask & bit:
            names.append(name)
    if not names:
        names.append("CONDITION_NONE")
    return names


def parse_conditions(data: bytes) -> List[Dict[str, Any]]:
    r = Reader(data)
    conditions: List[Dict[str, Any]] = []

    while r.remaining() > 0:
        try:
            attr = r.read_u8()
        except EOFError:
            break

        # find start of a condition (TYPE)
        if attr != CONDITIONATTR_TYPE:
            # try to skip stray bytes until a TYPE or EOF
            continue

        cond: Dict[str, Any] = {}
        cond["type_raw"] = r.read_u32()
        cond["type"] = condition_type_names(cond["type_raw"])

        # now read header flags and following attributes until END
        while r.remaining() > 0:
            attr = r.read_u8()
            if attr == CONDITIONATTR_END:
                break

            if attr == CONDITIONATTR_ID:
                raw_id = r.read_u32()
                # cast to signed int8 (ConditionId_t)
                id8 = raw_id & 0xFF
                if id8 >= 0x80:
                    id8 -= 0x100
                cond["id"] = id8
            elif attr == CONDITIONATTR_TICKS:
                cond["ticks"] = r.read_u32()
            elif attr == CONDITIONATTR_ISBUFF:
                cond["is_buff"] = bool(r.read_u8())
            elif attr == CONDITIONATTR_SUBID:
                cond["subid"] = r.read_u32()
            elif attr == CONDITIONATTR_ISAGGRESSIVE:
                cond["is_aggressive"] = bool(r.read_u8())
            elif attr == CONDITIONATTR_DELAYED:
                cond["delayed"] = bool(r.read_u8())
            elif attr == CONDITIONATTR_PERIODDAMAGE:
                cond["period_damage"] = r.read_i32()
            elif attr == CONDITIONATTR_OWNER:
                cond["owner"] = r.read_u32()
            elif attr == CONDITIONATTR_INTERVALDATA:
                cond.setdefault("intervals", []).append(r.read_interval())
            elif attr == CONDITIONATTR_SPEEDDELTA:
                cond["speed_delta"] = r.read_i32()
            elif attr == CONDITIONATTR_FORMULA_MINA:
                cond.setdefault("formula", {})["mina"] = r.read_f32()
            elif attr == CONDITIONATTR_FORMULA_MINB:
                cond.setdefault("formula", {})["minb"] = r.read_f32()
            elif attr == CONDITIONATTR_FORMULA_MAXA:
                cond.setdefault("formula", {})["maxa"] = r.read_f32()
            elif attr == CONDITIONATTR_FORMULA_MAXB:
                cond.setdefault("formula", {})["maxb"] = r.read_f32()
            elif attr == CONDITIONATTR_LIGHTCOLOR:
                cond.setdefault("light", {})["color"] = r.read_u32()
            elif attr == CONDITIONATTR_LIGHTLEVEL:
                cond.setdefault("light", {})["level"] = r.read_u32()
            elif attr == CONDITIONATTR_LIGHTTICKS:
                cond.setdefault("light", {})["ticks"] = r.read_u32()
            elif attr == CONDITIONATTR_LIGHTINTERVAL:
                cond.setdefault("light", {})["interval"] = r.read_u32()
            elif attr == CONDITIONATTR_SOULTICKS:
                cond["soul_ticks"] = r.read_u32()
            elif attr == CONDITIONATTR_SOULGAIN:
                cond["soul_gain"] = r.read_u32()
            elif attr == CONDITIONATTR_SKILLS:
                cond.setdefault("skills", []).append(r.read_i32())
            elif attr == CONDITIONATTR_STATS:
                cond.setdefault("stats", []).append(r.read_i32())
            elif attr == CONDITIONATTR_SPECIALSKILLS:
                cond.setdefault("special_skills", []).append(r.read_i32())
            elif attr == CONDITIONATTR_DISABLEDEFENSE:
                # serialize used bool in C++ (1 byte)
                cond["disable_defense"] = r.read_bool()
            elif attr == CONDITIONATTR_OUTFIT:
                cond["outfit"] = r.read_outfit()
            elif attr == CONDITIONATTR_HEALTHTICKS:
                cond["health_ticks"] = r.read_u32()
            elif attr == CONDITIONATTR_HEALTHGAIN:
                cond["health_gain"] = r.read_u32()
            elif attr == CONDITIONATTR_MANATICKS:
                cond["mana_ticks"] = r.read_u32()
            elif attr == CONDITIONATTR_MANAGAIN:
                cond["mana_gain"] = r.read_u32()
            elif attr == CONDITIONATTR_MANASHIELD_BREAKABLE_MANA:
                cond["manashield_mana"] = r.read_u16()
            elif attr == CONDITIONATTR_MANASHIELD_BREAKABLE_MAXMANA:
                cond["manashield_maxmana"] = r.read_u16()
            else:
                # unknown attribute - try to read a uint32 as fallback to advance the stream
                # (this is a best-effort approach for older/newer attribute sets)
                try:
                    val = r.read_u32()
                    cond.setdefault("unknown_attrs", []).append({"attr": attr, "raw_u32": val})
                except EOFError:
                    cond.setdefault("unknown_attrs", []).append({"attr": attr, "error": "truncated"})
                    break

        conditions.append(cond)

    return conditions


def decode_hex_blob(hexstr: str) -> List[Dict[str, Any]]:
    if not hexstr:
        return []
    try:
        data = binascii.unhexlify(hexstr)
    except (binascii.Error, TypeError) as e:
        raise ValueError(f"invalid hex blob: {e}")
    return parse_conditions(data)


def main(argv: List[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Decode players.conditions PropStream blobs.")
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument("--hex", help="hex string of the blob to decode")
    group.add_argument("--bin", help="path to binary file containing a single blob")
    group.add_argument("--csv", help="CSV file (id,name,length,hex) to decode the 4th column hex blobs")
    p.add_argument("--json", help="write JSON output to this file (default: stdout)")
    args = p.parse_args(argv)

    outputs: List[Dict[str, Any]] = []

    if args.hex:
        outputs = decode_hex_blob(args.hex)
    elif args.bin:
        with open(args.bin, "rb") as fh:
            data = fh.read()
        outputs = parse_conditions(data)
    elif args.csv:
        with open(args.csv, newline="", encoding="utf-8") as fh:
            rdr = csv.reader(fh)
            for row in rdr:
                if not row:
                    continue
                # expect the hex to be at column index 3 (0-based) based on sample
                hexblob = row[3] if len(row) > 3 else ""
                decoded = decode_hex_blob(hexblob) if hexblob else []
                outputs.append({"row": row[:3], "conditions": decoded})

    out_text = json.dumps(outputs, indent=2, ensure_ascii=False)
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            fh.write(out_text)
    else:
        print(out_text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
