# Inception Mandatory Evaluation Checklist (sykawai)

This checklist follows the 42 Inception SCALE flow so you can run the defense step-by-step.

## 1. Preliminaries

```bash
cd ~/inception
git remote -v
git status
```

Expected:
- Repository is the correct one.
- Evaluated learner can explain project structure and scripts.

## 2. Clean Docker State (as requested by scale)

```bash
docker stop $(docker ps -qa) 2>/dev/null || true
docker rm $(docker ps -qa) 2>/dev/null || true
docker rmi -f $(docker images -qa) 2>/dev/null || true
docker volume rm $(docker volume ls -q) 2>/dev/null || true
docker network rm $(docker network ls -q) 2>/dev/null || true
```

## 3. Repository and File Checks

```bash
ls -la
ls srcs
ls README.md USER_DOC.md DEV_DOC.md Makefile
```

Expected:
- `Makefile` exists at repo root.
- Required configuration files are under `srcs/`.
- `README.md`, `USER_DOC.md`, `DEV_DOC.md` exist.

## 4. Compose / Forbidden Patterns Checks

```bash
grep -n "network: host" srcs/docker-compose.yml || true
grep -n "links:" srcs/docker-compose.yml || true
grep -RIn -- "--link\|tail -f\|sleep infinity\|while true" srcs Makefile || true
```

Expected:
- No `network: host`.
- No `links`.
- No prohibited commands/patterns.

## 5. README / Documentation Checks

```bash
head -n 2 README.md
grep -n "## Description\|## Instructions\|## Resources\|AI Usage" README.md
wc -l USER_DOC.md DEV_DOC.md
```

Expected:
- First line format is correct and italicized.
- Required sections are present.
- `USER_DOC.md` and `DEV_DOC.md` are not empty.

## 6. Build and Start via Makefile

```bash
make init
make
make ps
docker compose -f srcs/docker-compose.yml ps
```

Expected:
- `mariadb`, `wordpress`, `nginx` are `Up`.

## 7. Docker Basics Validation

```bash
ls srcs/requirements/nginx/Dockerfile srcs/requirements/wordpress/Dockerfile srcs/requirements/mariadb/Dockerfile
grep -RIn "^FROM " srcs/requirements/*/Dockerfile
grep -RIn "latest" srcs/requirements/*/Dockerfile srcs/docker-compose.yml || true
```

Expected:
- One Dockerfile per mandatory service.
- No `latest` tag usage.

## 8. Docker Network Validation

```bash
docker network ls | grep inception
```

Expected:
- Project network (e.g. `srcs_inception`) exists.

## 9. NGINX + TLS Validation

```bash
docker compose -f srcs/docker-compose.yml ps
curl -vk https://sykawai.42.fr
curl -v http://sykawai.42.fr
```

Expected:
- HTTPS works.
- HTTP does not provide access.

Optional TLS protocol demonstration:

```bash
echo | openssl s_client -connect sykawai.42.fr:443 -tls1_2 2>/dev/null | grep Protocol
echo | openssl s_client -connect sykawai.42.fr:443 -tls1_3 2>/dev/null | grep Protocol
echo | openssl s_client -connect sykawai.42.fr:443 -tls1 2>/dev/null | head
```

Expected:
- TLSv1.2/TLSv1.3 work.
- TLSv1.0 fails.

## 10. WordPress + php-fpm Validation

```bash
docker compose -f srcs/docker-compose.yml exec -T wordpress wp core is-installed --allow-root --path=/var/www/wordpress
docker compose -f srcs/docker-compose.yml exec -T wordpress wp user list --allow-root --path=/var/www/wordpress --fields=user_login,roles --format=csv
```

Expected:
- WordPress is already installed.
- Admin username does not contain `admin/Admin/administrator`.

Manual checks:
- Access `/wp-admin` and log in as admin.
- Edit a page and verify reflected on website.
- Add comment with normal user.

## 11. MariaDB Validation

```bash
docker compose -f srcs/docker-compose.yml exec -T mariadb sh -lc "ss -lntp | grep 3306"
docker compose -f srcs/docker-compose.yml exec -T mariadb sh -lc 'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES;"'
```

Expected:
- MariaDB listens correctly.
- `wordpress` database exists.
- Learner can explain DB login method.

## 12. Volume Validation

```bash
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

Expected:
- Both volumes exist.
- `Options.device` paths point to:
  - `/home/sykawai/data/mariadb`
  - `/home/sykawai/data/wordpress`

## 13. Persistence Validation

Manual flow:
1. Create/update content in WordPress.
2. Reboot VM (or at least `make down` then `make`).
3. Verify content is still there.

Commands:

```bash
make down
make
```

## 14. Configuration Modification (Defense step)

Ask evaluated learner to change one service config (example: port), then rebuild and show it still works.

```bash
make re
docker compose -f srcs/docker-compose.yml ps
```

Expected:
- Modification is applied.
- Service remains functional.

## 15. Final Decision Guidance

- If any mandatory requirement fails, evaluation stops according to scale rules.
- If all mandatory checks pass, mark `Ok`.
- Bonus is evaluated only after perfect mandatory completion.
