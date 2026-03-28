# Resumen de revisión Lua — Top 10 archivos

Generado automáticamente: revisión rápida de `migrations/legacy/lua_pattern_matches.csv` y `migrations/legacy/lua_audit_top_files.txt`.

Prioridad: revisar manualmente estos archivos en orden.

1) data/cpplinter.lua
   - Archivo de anotaciones/IDE. Sin cambios urgentes.

2) data/lib/compat/compat.lua
   - Es el hub de wrappers (doPlayer*, doSend*, etc.). Verificar que cubre todas las llamadas obsoletas detectadas.
   - Acción: añadir wrappers faltantes o marcar funciones como deprecadas.

3) data/npc/lib/npcsystem/modules.lua
   - Revisa `registerEvent`/`addEvent` y manejo de callbacks.
   - Acción: asegurar que los eventos registrados existen y que no se usan cadenas dinámicas sin comprobación.

4) data/lib/core/achievements.lua
   - Uso de `addEvent`: verificar cancelación de timers y posibles fugas de memoria.
   - Acción: cambiar a patrones seguros (cierre/weak refs) si aplica.

5) data/lib/core/item.lua
   - Comprobar `Game.createItem` y manejo de `subType`/`decay`.
   - Acción: validar que se usan APIs modernas y manejar errores en la creación.

6) data/lib/core/player.lua
   - Reemplazar llamadas globales obsoletas por métodos `Player:` cuando sea posible.
   - Acción: proponer reemplazos automáticos para casos triviales (p.ej. `doPlayerAddItem` → `player:addItemEx`).

7) data/npc/lib/npcsystem/npchandler.lua
   - Revisar uso de `addEvent` en handlers de NPC (evitar crear eventos no cancelables).

8) data/npc/scripts/bank.lua
   - Revisar `registerEvent` y almacenamiento; validar accesos a `Player` y storage.

9) data/scripts/actions/others/taming.lua
   - Contiene `addEvent(Game.createItem, ...)`: preferir closures que llamen `Game.createItem(...)` para garantizar argumentos correctos.

10) data/scripts/lib/register_monster_type.lua
   - Validar `mtype:registerEvent` y que los nombres de eventos registrados existen; asegurar que `mtype` no sea nil.

Siguientes pasos recomendados (rápido):
- Ejecutar pruebas en entorno staging tras aplicar cambios en uno o dos archivos.
- Aplicar cambios automáticos solo para transformaciones triviales y seguras (ej.: reemplazos de wrapper por método cuando el patrón es claro).
- Crear commits por fichero para facilitar revisión (puedo hacerlo). 

He preparado este resumen y lo he añadido a la rama `migrations/legacy-add-reports`.
