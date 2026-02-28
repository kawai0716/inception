FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    php-fpm php-mysql \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# wp-cli (official phar)
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# PHP-FPM config (COPY does not expand wildcards on destination path)
COPY conf/www.conf /tmp/www.conf
RUN PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')" \
    && cp /tmp/www.conf "/etc/php/${PHP_VER}/fpm/pool.d/www.conf" \
    && rm -f /tmp/www.conf

# Entrypoint
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/wordpress

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm", "-F"]
