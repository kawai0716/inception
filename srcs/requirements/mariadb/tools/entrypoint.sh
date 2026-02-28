#!/usr/bin/env bash
set -euo pipefail

# Read secret file content (Docker secrets are mounted under /run/secrets/<name>)
read_secret() {
  local path="$1"
  local value
  if [ ! -f "$path" ]; then
    echo "Error: secret file not found: $path" >&2
    exit 1
  fi
  value="$(tr -d '\r\n' < "$path")"
  if [ -z "$value" ]; then
    echo "Error: secret file is empty: $path" >&2
    exit 1
  fi
  printf "%s" "$value"
}

sql_escape() {
  # Escape single quotes for SQL string literals.
  printf "%s" "$1" | sed "s/'/''/g"
}

# Required non-secret env (from .env)
: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"

# Secrets (from docker compose secrets)
MYSQL_PASSWORD="$(read_secret /run/secrets/db_password)"
MYSQL_ROOT_PASSWORD="$(read_secret /run/secrets/db_root_password)"
MYSQL_PASSWORD_SQL="$(sql_escape "$MYSQL_PASSWORD")"
MYSQL_ROOT_PASSWORD_SQL="$(sql_escape "$MYSQL_ROOT_PASSWORD")"
INIT_MARKER="/var/lib/mysql/.inception_initialized"

# Runtime dir is tmpfs-like in containers, so ensure it exists on every start.
mkdir -p /var/lib/mysql
mkdir -p /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld

# Initialize if marker is missing.
# This also recovers from a prior run that created the datadir but failed before SQL setup.
if [ ! -f "$INIT_MARKER" ]; then
  echo "[mariadb] Initializing database..."

  if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
  fi

  echo "[mariadb] Starting temporary server..."
  # Temporary server: no TCP, only unix socket. Good for safe init.
  mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  # Wait for server ready (bounded wait, not infinite)
  for i in {1..30}; do
    if mariadb-admin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  if ! mariadb-admin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; then
    echo "Error: MariaDB temp server did not start" >&2
    kill "$pid" 2>/dev/null || true
    exit 1
  fi

  echo "[mariadb] Creating database and users..."
  mariadb --socket=/run/mysqld/mysqld.sock <<-SQL
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD_SQL}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD_SQL}';
    FLUSH PRIVILEGES;
SQL

  echo "[mariadb] Stopping temporary server..."
  mariadb-admin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

  wait "$pid" 2>/dev/null || true
  touch "$INIT_MARKER"
  chown mysql:mysql "$INIT_MARKER"
  echo "[mariadb] Initialization done."
fi

# Exec the main process (PID 1 best practice)
if [ "${1:-}" = "mariadbd" ] || [ "${1:-}" = "mysqld" ]; then
  shift
  # Listen on all container interfaces so other services can connect over Docker network.
  exec mariadbd --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock --bind-address=0.0.0.0 "$@"
fi

exec "$@"
