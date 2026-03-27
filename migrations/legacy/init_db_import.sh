#!/bin/bash
set -e
# init_db_import.sh
# Importa el volcado legacy en una base temporal y migra tablas clave

LEGACY_DB=legacy_import
TARGET_DB="${MYSQL_DATABASE:-forgottenserver}"

if [ -f /srv/servidor_from_TFS.sql ]; then
  echo "Creating legacy database ${LEGACY_DB} (latin1)..."
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`${LEGACY_DB}\` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;"

  echo "Importing legacy dump into ${LEGACY_DB} (latin1)..."
  mysql --default-character-set=latin1 -u root -p"$MYSQL_ROOT_PASSWORD" "${LEGACY_DB}" < /srv/servidor_from_TFS.sql

  echo "Migrating data from ${LEGACY_DB} -> ${TARGET_DB} using migration files"

  MIGRATIONS_DIR=/docker-entrypoint-initdb.d/migrations

  # Ensure migrations directory exists and contains our SQL files
  if [ -d "$MIGRATIONS_DIR" ]; then
    # Run migrations in safe order: accounts -> players -> guilds -> houses
    for f in \
      "$MIGRATIONS_DIR/migrate_accounts.sql" \
      "$MIGRATIONS_DIR/migrate_players.sql" \
      "$MIGRATIONS_DIR/migrate_guilds.sql" \
      "$MIGRATIONS_DIR/migrate_houses.sql"; do
      if [ -f "$f" ]; then
        echo "Running migration: $f"
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$TARGET_DB" < "$f"
      else
        echo "Migration file not found: $f (skipping)"
      fi
    done
  else
    echo "No migrations directory found at $MIGRATIONS_DIR; skipping file-based migrations."
  fi

  echo "Migration complete. Legacy DB ${LEGACY_DB} kept for reference."
else
  echo "No legacy dump found at /docker-entrypoint-initdb.d/servidor_from_TFS.sql; skipping migration."
fi
