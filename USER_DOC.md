# USER_DOC

## Services Provided
- HTTPS website via NGINX on port `443`
- WordPress application served by PHP-FPM
- MariaDB database backend
- Persistent WordPress files and database data under `/home/sykawai/data`

## Start / Stop
Start:
```bash
make
```
Stop:
```bash
make down
```

## Access Website and Admin
- Website: `https://sykawai.42.fr`
- Admin panel: `https://sykawai.42.fr/wp-admin`

If needed, set host resolution in `/etc/hosts`:
```text
<vm_ip> sykawai.42.fr
```

## Credentials Management
- Non-secret config: `srcs/.env`
- Secrets: `secrets/*.txt`

Create secrets from templates before first run:
```bash
cp secrets/db_password.txt.example secrets/db_password.txt
cp secrets/db_root_password.txt.example secrets/db_root_password.txt
cp secrets/wp_admin_password.txt.example secrets/wp_admin_password.txt
cp secrets/wp_user_password.txt.example secrets/wp_user_password.txt
```

Then edit each `secrets/*.txt` with real values.

## Service Health Check
```bash
make ps
docker compose -f srcs/docker-compose.yml logs --tail=100
```

Expected:
- `nginx`, `wordpress`, `mariadb` are `Up`
- `https://sykawai.42.fr` is reachable
- `wp-admin` login works

## Persistence Check
1. Create a post/comment in WordPress.
2. Reboot VM.
3. Run `make`.
4. Confirm the content still exists.
