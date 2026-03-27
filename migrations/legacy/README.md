Instrucciones de importación — volcado legacy de TFS
=================================================

Resumen
-------
Este directorio contiene utilidades para importar el volcado legacy incluido en
la carpeta `TFS 1.2_10_95_rl_map_cam/servidor.sql` hacia la base de datos del
proyecto (esquema actual en `schema.sql`).

Pasos rápidos (PowerShell, desde la raíz del repo)
-------------------------------------------------
1. Copiar el volcado original al directorio de migraciones (opcional):

   Copy-Item "TFS 1.2_10_95_rl_map_cam\servidor.sql" "migrations\legacy\servidor_from_TFS.sql" -Force

2. Ejecutar el script de importación incluido (se pedirá la contraseña MySQL):

   .\migrations\legacy\import_legacy.ps1 -RunImport -DbName <nombre_db> -DbUser <usuario>

Comando alternativo (cmd):

   mysql --default-character-set=latin1 -u <user> -p <dbname> < "TFS 1.2_10_95_rl_map_cam\servidor.sql"

Importación automática con Docker
--------------------------------
Si inicias los servicios con `docker-compose up` desde la raíz del repo, el
servicio `db` está configurado para ejecutar cualquier archivo en
`/docker-entrypoint-initdb.d/` durante la primera inicialización del volumen
de datos. Hemos añadido un wrapper que importará `migrations/legacy/servidor_from_TFS.sql`
si ese fichero está presente. Nota: esto sólo ocurre cuando el volumen de datos
(`tfs-db-data`) está vacío (primera vez que se arranca la base de datos).

Notas importantes
------------------
- El volcado original fue generado con `CHARSET=latin1`. Importar usando
  `--default-character-set=latin1` para preservar bytes y luego convertir las
  tablas a `utf8mb4` si desea el charset moderno.
- Importar primero en una base de datos de desarrollo y hacer copia de seguridad.
- El esquema del proyecto (`schema.sql`) puede diferir (columnas renombradas,
  claves AUTO_INCREMENT, triggers). Es recomendable revisar y mapear tablas
  antes de usar los datos en producción.

Sugerencias de migración
------------------------
- Hacer un `diff` entre el volcado legacy y `schema.sql` para detectar columnas
  faltantes o renombradas.
- Importar en una base temporal y ejecutar transformaciones SQL (`INSERT ... SELECT`,
  `ALTER TABLE`) para mapear datos a la estructura nueva.

Soporte
-------
Si quieres, puedo generar scripts de mapeo/ALTER por tablas específicas —
dime qué tablas (por ejemplo: `accounts`, `houses`, `guilds`) quieres migrar.

Scripts de migración (opcional)
--------------------------------
En este directorio hay scripts SQL que realizan la migración para tablas clave:

- `migrate_accounts.sql`
- `migrate_players.sql`
- `migrate_guilds.sql`
- `migrate_houses.sql`

Para ejecutarlos manualmente (local):

```powershell
mysql -u root -p forgottenserver < migrations\legacy\migrate_accounts.sql
```

O usando el contenedor en ejecución:

```powershell
docker exec -i tfs-db-compose mysql -uroot -prootpass123 forgottenserver < migrations\legacy\migrate_accounts.sql
```

Estos scripts son idempotentes para un entorno de importación inicial; revisa y prueba
en una base temporal antes de usarlos en producción.
