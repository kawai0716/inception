#!/usr/bin/env bash
set -euo pipefail

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

# Required env (non-secret) from .env
: "${DOMAIN_NAME:?Missing DOMAIN_NAME}"
: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${WP_TITLE:?Missing WP_TITLE}"
: "${WP_ADMIN_USER:?Missing WP_ADMIN_USER}"
: "${WP_ADMIN_EMAIL:?Missing WP_ADMIN_EMAIL}"
: "${WP_USER:?Missing WP_USER}"
: "${WP_USER_EMAIL:?Missing WP_USER_EMAIL}"

# Secrets
MYSQL_PASSWORD="$(read_secret /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(read_secret /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(read_secret /run/secrets/wp_user_password)"

# Basic rule check (evaluation requirement)
if echo "$WP_ADMIN_USER" | grep -qiE 'admin|administrator'; then
  echo "Error: WP_ADMIN_USER must not contain 'admin' or 'administrator'." >&2
  exit 1
fi

# Ensure directories exist
mkdir -p /run/php /var/www/wordpress
chown -R www-data:www-data /var/www/wordpress

cd /var/www/wordpress

# Download WordPress only if not present (volume persistence)
if [ ! -f "wp-load.php" ]; then
  echo "[wordpress] Downloading WordPress core..."
  # --force to handle partially existing directories safely
  wp core download --allow-root --path=/var/www/wordpress --force
fi

# Wait for MariaDB (bounded wait; no infinite loop)
echo "[wordpress] Waiting for MariaDB..."
for i in {1..30}; do
  if mariadb-admin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; then
    break
  fi
  sleep 1
done
if ! mariadb-admin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; then
  echo "Error: MariaDB is not reachable." >&2
  exit 1
fi

# Create wp-config.php only once
if [ ! -f "wp-config.php" ]; then
  echo "[wordpress] Creating wp-config.php..."
  wp config create --allow-root \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${MYSQL_PASSWORD}" \
    --dbhost="mariadb:3306" \
    --path=/var/www/wordpress

  # Optional but common: allow reverse proxy HTTPS in WP
  wp config set --allow-root WP_HOME "https://${DOMAIN_NAME}" --type=constant --path=/var/www/wordpress
  wp config set --allow-root WP_SITEURL "https://${DOMAIN_NAME}" --type=constant --path=/var/www/wordpress
fi

# Install WP only if not installed yet
if ! wp core is-installed --allow-root --path=/var/www/wordpress >/dev/null 2>&1; then
  echo "[wordpress] Running wp core install..."
  wp core install --allow-root \
    --url="https://${DOMAIN_NAME}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}"

  echo "[wordpress] Creating normal user..."
  wp user create --allow-root \
    "${WP_USER}" "${WP_USER_EMAIL}" \
    --user_pass="${WP_USER_PASSWORD}" \
    --role=subscriber
fi

# Ensure permissions after setup (avoid upload issues)
chown -R www-data:www-data /var/www/wordpress

# Debian package may provide versioned php-fpm binary (e.g. php-fpm8.2).
if [ "${1:-}" = "php-fpm" ] && ! command -v php-fpm >/dev/null 2>&1; then
  PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
  PHP_FPM_BIN="php-fpm${PHP_VER}"
  if command -v "${PHP_FPM_BIN}" >/dev/null 2>&1; then
    set -- "${PHP_FPM_BIN}" "${@:2}"
  fi
fi

# Start php-fpm in foreground (PID 1 best practice)
exec "$@"
