# Lua Fix Suggestions

Resumen automático generado: `migrations/legacy/lua_pattern_matches.csv` (69 coincidencias) y `migrations/legacy/lua_audit_top_files.txt`.

Hallazgos principales
- `createItem` (25 ocurrencias): la mayoría ya usa `Game.createItem(...)` o existen wrappers en `data/lib/compat/compat.lua` (`doCreateItem`, `doCreateItemEx`). No es necesario cambio automático.
- `addEvent` (19): uso extendido en raids, globalevents y NPCs. API moderna mantiene `addEvent(fn, delay, ...)` — revisar llamadas que pasen funciones o nombres de eventos dinámicos.
- `registerEvent` / `registerCreatureEvent` (15): hay wrappers en `compat.lua`. Revisar los scripts que registran eventos por nombre para asegurar que los eventos existen.
- `getPlayerStorageValue` / `setPlayerStorageValue` (1 / 1): compat wrappers existen — OK.
- `doSendMagicEffect`, `doTeleportThing`, `doPlayerSendTextMessage`: wrappers definidos en `compat.lua`.

Prioridad recomendada (primeros archivos a revisar manualmente)
- `data/cpplinter.lua` (2402 líneas) — archivo de anotaciones; sin cambios urgentes, solo útil para IDE.
- `data/lib/compat/compat.lua` — ya contiene muchas compatibilidades; revisar si alguna función faltante debe añadirse.
- `data/npc/lib/npc.lua` y `data/actions/lib/actions.lua` — archivos grandes con múltiples `Game.createItem`/`addEvent` llamadas; revisar lógicas de objetivos y temporizadores.
- `data/scripts/globalevents/server_save.lua` y `data/scripts/globalevents/raids/*` — presencia de `addEvent` y cronologías; verificar temporizaciones y memoria de eventos en el servidor actual.

Automatizaciones seguras realizadas
- Generado `migrations/legacy/lua_pattern_matches.csv` con cada coincidencia (archivo, línea, patrón, texto) para revisión rápida.
- No se aplicaron cambios destructivos en los scripts Lua de `data/`.

Sugerencias de pasos siguientes (elige una):
1. Aplicar cambios automáticos triviales (ej.: reemplazar usos totalmente obsoletos) — **recomendado solo si confías en los cambios automáticos**.
2. Revisión manual de los 10 ficheros superiores listados en `lua_audit_top_files.txt` y corrección puntal (recomiendo empezar por `data/lib/compat/compat.lua`, `data/npc/lib/npc.lua`, `data/actions/lib/actions.lua`).
3. Ejecutar el servidor en entorno de pruebas y capturar errores Lua en logs, luego remediar caso por caso (más seguro).

Propuesta de acción ahora (puedo hacer esto ya):
- A: Preparar parche con cambios sugeridos automáticos para patrones sencillos (crea un branch y PR).
- B: Empezar revisión manual de los `N=10` ficheros principales y aplicar correcciones incrementales (haré commits por fichero).
- C: Ejecutar servidor en contenedor y reproducir errores Lua, listando fallos reales.

Decide A, B o C y procedo. Si prefieres B, dime si quieres que aplique cambios por fichero automáticamente (commit por fichero) o que solo reporte los cambios propuestos antes de commitear.
