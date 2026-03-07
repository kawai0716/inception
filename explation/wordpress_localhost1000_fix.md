# WordPress URL Fix for `http://localhost:1000`

```bash
docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp config set --allow-root --path=/var/www/wordpress --type=constant WP_HOME "http://localhost:1000"

docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp config set --allow-root --path=/var/www/wordpress --type=constant WP_SITEURL "http://localhost:1000"

docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp option update --allow-root --path=/var/www/wordpress home "http://localhost:1000"

docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp option update --allow-root --path=/var/www/wordpress siteurl "http://localhost:1000"
```

確認:

```bash
curl -I http://localhost:1000
```

## Revert to `https://sykawai.42.fr`

```bash
docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp config set --allow-root --path=/var/www/wordpress --type=constant WP_HOME "https://sykawai.42.fr"

docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp config set --allow-root --path=/var/www/wordpress --type=constant WP_SITEURL "https://sykawai.42.fr"

docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp option update --allow-root --path=/var/www/wordpress home "https://sykawai.42.fr"

docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp option update --allow-root --path=/var/www/wordpress siteurl "https://sykawai.42.fr"
```

確認:

```bash
docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp option get --allow-root --path=/var/www/wordpress siteurl
```
