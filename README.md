# Inception

## Description
This project builds a small Docker-based infrastructure in a VM using Docker Compose.
It contains three dedicated containers:
- NGINX (the only public entrypoint on port 443 with TLS)
- WordPress + PHP-FPM
- MariaDB

Two Docker named volumes provide persistence:
- WordPress database data
- WordPress site files

The project follows the mandatory constraints: custom Dockerfiles, dedicated network, no `network: host`, no `links`, no `latest` tag, and no passwords in Dockerfiles.

## Project Architecture and Design Choices
Sources are under `srcs/`:
- `srcs/docker-compose.yml`: services, network, volumes, secrets
- `srcs/.env`: non-secret runtime variables
- `srcs/requirements/nginx`: TLS NGINX image and config
- `srcs/requirements/wordpress`: WordPress + PHP-FPM image and setup
- `srcs/requirements/mariadb`: MariaDB image and initialization
- `secrets/`: local secret files (not tracked in git)

### Virtual Machines vs Docker
- VM provides full OS isolation and is heavier.
- Docker packages services as lightweight containers, making rebuild/debug faster and more reproducible.
- Inception uses Docker inside a VM to combine curriculum constraints with container benefits.

### Secrets vs Environment Variables
- `.env` stores non-sensitive configuration (domain, usernames, DB name, emails).
- Docker secrets store sensitive values (DB/user passwords) as files under `/run/secrets/*`.
- This reduces accidental credential leaks.

### Docker Network vs Host Network
- A custom bridge network isolates services and allows service-name DNS (`mariadb`, `wordpress`).
- Only NGINX exposes port `443`.
- `network: host` is not used.

### Docker Volumes vs Bind Mounts
- Mandatory data uses Docker named volumes.
- They are configured to persist under `/home/sykawai/data/...` on the host, matching the subject requirement.
- Data survives container recreation and VM reboot.

## Instructions
1. Prepare host paths:
```bash
mkdir -p /home/sykawai/data/mariadb /home/sykawai/data/wordpress
```
2. Prepare secrets (from templates):
```bash
cp secrets/db_password.txt.example secrets/db_password.txt
cp secrets/db_root_password.txt.example secrets/db_root_password.txt
cp secrets/wp_admin_password.txt.example secrets/wp_admin_password.txt
cp secrets/wp_user_password.txt.example secrets/wp_user_password.txt
```
Then edit each `secrets/*.txt` with real values.

3. Configure `srcs/.env` (`DOMAIN_NAME`, users, emails).

4. Add hosts entry in the VM:
```text
<vm_ip> sykawai.42.fr
```

5. Build and start:
```bash
make
```

6. Stop:
```bash
make down
```

7. Rebuild:
```bash
make re
```

## Resources
- Docker Docs: https://docs.docker.com/
- Docker Compose Spec: https://docs.docker.com/compose/compose-file/
- NGINX Docs: https://nginx.org/en/docs/
- WordPress CLI Docs: https://developer.wordpress.org/cli/commands/
- MariaDB Docs: https://mariadb.com/kb/en/documentation/
- OpenSSL Docs: https://www.openssl.org/docs/

### AI Usage
AI was used to:
- review configuration against mandatory constraints
- identify entrypoint/runtime edge cases
- improve documentation clarity

All final code changes and project decisions were manually reviewed and understood before adoption.
