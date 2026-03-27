#!/bin/sh
set -e

# Wait for the database service to be reachable before starting tfs
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}
RETRY=${DB_RETRY:-60}

echo "Waiting for database ${DB_HOST}:${DB_PORT}..."
n=0
while ! nc -z ${DB_HOST} ${DB_PORT}; do
  n=$((n+1))
  if [ "$n" -ge "$RETRY" ]; then
    echo "Timeout waiting for ${DB_HOST}:${DB_PORT}"
    exit 1
  fi
  sleep 1
done

echo "Database reachable; starting tfs..."
exec /bin/tfs "$@"
