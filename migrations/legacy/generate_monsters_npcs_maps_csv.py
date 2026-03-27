#!/usr/bin/env python3
"""
Generate CSVs for monsters, NPCs and maps/spawns.

Outputs:
- migrations/legacy/monsters.csv (name,file)
- migrations/legacy/npcs.csv (name,script,walkinterval,floorchange,file)
- migrations/legacy/maps.csv (filename,size_bytes)
- migrations/legacy/maps_spawn_monsters.csv (centerx,centery,centerz,entity_type,name,x,y,z,spawntime)
"""
import os
import csv
import xml.etree.ElementTree as ET


def write_csv(path, fieldnames, rows):
    with open(path, 'w', encoding='utf-8', newline='') as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.normpath(os.path.join(here, '..', '..'))

    monster_xml = os.path.join(repo, 'data', 'monster', 'monsters.xml')
    npc_dir = os.path.join(repo, 'data', 'npc')
    maps_dir = os.path.join(repo, 'data', 'world')
    spawn_xml = os.path.join(maps_dir, 'forgotten-spawn.xml')

    out_monsters = os.path.join(here, 'monsters.csv')
    out_npcs = os.path.join(here, 'npcs.csv')
    out_maps = os.path.join(here, 'maps.csv')
    out_spawns = os.path.join(here, 'maps_spawn_monsters.csv')

    # Monsters
    monsters = []
    if os.path.exists(monster_xml):
        tree = ET.parse(monster_xml)
        root = tree.getroot()
        for m in root.findall('monster'):
            monsters.append({'name': m.get('name',''), 'file': m.get('file','')})
    write_csv(out_monsters, ['name','file'], monsters)

    # NPCs
    npcs = []
    if os.path.isdir(npc_dir):
        for fn in sorted(os.listdir(npc_dir)):
            if not fn.lower().endswith('.xml'):
                continue
            fp = os.path.join(npc_dir, fn)
            try:
                tree = ET.parse(fp)
                root = tree.getroot()
                npcs.append({
                    'name': root.get('name',''),
                    'script': root.get('script',''),
                    'walkinterval': root.get('walkinterval',''),
                    'floorchange': root.get('floorchange',''),
                    'file': os.path.join('data','npc', fn)
                })
            except Exception:
                npcs.append({'name':'','script':'','walkinterval':'','floorchange':'','file':os.path.join('data','npc',fn)})
    write_csv(out_npcs, ['name','script','walkinterval','floorchange','file'], npcs)

    # Maps (list files)
    maps = []
    if os.path.isdir(maps_dir):
        for fn in sorted(os.listdir(maps_dir)):
            fp = os.path.join(maps_dir, fn)
            try:
                sz = os.path.getsize(fp)
            except Exception:
                sz = ''
            maps.append({'filename': os.path.join('data','world',fn), 'size_bytes': sz})
    write_csv(out_maps, ['filename','size_bytes'], maps)

    # Spawns: extract monsters and npcs from spawn xml
    spawns = []
    if os.path.exists(spawn_xml):
        try:
            tree = ET.parse(spawn_xml)
            root = tree.getroot()
            for sp in root.findall('spawn'):
                cx = sp.get('centerx','')
                cy = sp.get('centery','')
                cz = sp.get('centerz','')
                for child in sp:
                    if child.tag not in ('monster','npc'):
                        continue
                    etype = child.tag
                    name = child.get('name','')
                    x = child.get('x','')
                    y = child.get('y','')
                    z = child.get('z','')
                    st = child.get('spawntime','')
                    spawns.append({
                        'centerx': cx, 'centery': cy, 'centerz': cz,
                        'entity_type': etype, 'name': name, 'x': x, 'y': y, 'z': z, 'spawntime': st
                    })
        except Exception:
            pass
    write_csv(out_spawns, ['centerx','centery','centerz','entity_type','name','x','y','z','spawntime'], spawns)

    print(f"Wrote: {len(monsters)} monsters, {len(npcs)} npcs, {len(maps)} maps, {len(spawns)} spawn entries")


if __name__ == '__main__':
    main()
