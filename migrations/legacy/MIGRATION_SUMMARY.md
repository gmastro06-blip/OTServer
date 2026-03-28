Migration summary
=================

What I did
----------
- Imported legacy dump into a temporary DB and prepared migration scripts.
- Ran core migration scripts (accounts, players, guilds, houses). Target counts match legacy:
  - accounts: 4
  - players: 7
  - houses: 1066
- Regenerated content CSVs:
  - `items.csv` (32,030 rows)
  - `monsters.csv` (1,165 rows)
  - `npcs.csv`, `maps.csv`, `maps_spawn_monsters.csv`
- Configured Git LFS and migrated large binaries (*.otbm, *.lib). Forced push to remote completed.
- Verified Dockerized server starts successfully: logs show "Forgotten Server Online!".

Current artifacts
-----------------
- `migrations/legacy/` contains SQL migration scripts, CSV exports and helper scripts (`generate_items_csv.py`, ...).
- Large map files remain under `TFS 1.2_10_95_rl_map_cam/` locally; `global.otbm` is ~121MB and is currently not tracked in the index (it is ignored by `.gitignore`).

Note: `global.otbm` has been relocated locally to `artifacts/legacy_maps/global.otbm` and `artifacts/` is now ignored to prevent accidental commits.
Recommended next steps
----------------------
1. Lua script compatibility audit (manual review of complex scripts and event handlers).
2. Decide map handling: keep large maps in LFS, place them in a separate artifacts store, or host externally.
3. Decode `players.conditions` if you need exact runtime condition restoration (requires server C++ logic).
4. If you want a clean public repo, prepare a release ZIP containing migration artifacts but excluding very large binaries.

If you want, I can proceed with (A) a deeper Lua audit, (B) move/track maps with LFS, or (C) attempt to decode `players.conditions` (I will need more time). Tell me which to prioritize and I'll continue.
