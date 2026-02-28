# DEV_DOC

## Purpose
Developer guide for setting up, building, and maintaining this Inception stack.

## Prerequisites
- Linux VM
- Docker Engine
- Docker Compose plugin (`docker compose`)
- Make
- Domain mapping: `sykawai.42.fr` -> VM IP

## Setup From Scratch
1. Clone repository.
2. Create host persistence directories:
```bash
mkdir -p /home/sykawai/data/mariadb /home/sykawai/data/wordpress
```
3. Create secrets from templates and fill real values:
```bash
cp secrets/db_password.txt.example secrets/db_password.txt
cp secrets/db_root_password.txt.example secrets/db_root_password.txt
cp secrets/wp_admin_password.txt.example secrets/wp_admin_password.txt
cp secrets/wp_user_password.txt.example secrets/wp_user_password.txt
```
4. Update non-secret settings in `srcs/.env`.
5. Add hosts entry:
```text
<vm_ip> sykawai.42.fr
```

## Build and Run
- `make`: build and start all services
- `make down`: stop stack
- `make clean`: stop stack and remove compose volumes
- `make fclean`: clean + remove compose images/orphans
- `make re`: full rebuild (`fclean` then `up`)
- `make ps`: show service status

## Compose Layout
- `nginx`: public entrypoint, `443:443`, TLS only
- `wordpress`: internal PHP-FPM service on `9000`
- `mariadb`: internal DB service on `3306`

All services are connected via `inception` bridge network.

## Persistence
Named volumes:
- `mariadb_data` -> `/var/lib/mysql`
- `wordpress_data` -> `/var/www/wordpress`

Host persistence path:
- `/home/sykawai/data/mariadb`
- `/home/sykawai/data/wordpress`

## Useful Commands
Status and logs:
```bash
make ps
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml logs nginx wordpress mariadb
```

Inspect persistence/network:
```bash
docker volume ls
docker volume inspect <project>_mariadb_data
docker volume inspect <project>_wordpress_data
docker network ls
docker network inspect <project>_inception
```

Container checks:
```bash
docker compose -f srcs/docker-compose.yml exec nginx nginx -t
docker compose -f srcs/docker-compose.yml exec wordpress wp core is-installed --allow-root --path=/var/www/wordpress
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p
```

## Validation Modification Drill
If evaluator requests a config change (example: port change):
1. Edit the target config (`docker-compose.yml` or service config).
2. Rebuild: `make re`.
3. Re-test accessibility and service health.
