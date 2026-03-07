# Inception Mandatory 評価チェックリスト (sykawai)

このファイルは「各回答がSCALEのどの評価項目に対応しているか」を追える形にしたものです。  
形式はすべて `SCALE項目 -> 回答テンプレ -> 実演コマンド -> 合格ライン` で統一しています。

## 1. Preliminaries / Preliminary tests

`SCALE項目`:
- Preliminary tests
- General instructions（リポジトリ確認）

`回答テンプレ`:
- 「このリポジトリが提出物です。`srcs/` 配下に設定、ルートに `Makefile` です。」
- 「資格情報は `.env` と Docker secrets で管理し、平文パスワードはDockerfileに書いていません。」

`実演コマンド`:

```bash
cd ~/inception
git remote -v
git status
ls -la
ls srcs
ls README.md USER_DOC.md DEV_DOC.md Makefile
```

`合格ライン`:
- 正しいリポジトリである。
- 必須ファイルが揃っている。

## 2. Clean Docker State

`SCALE項目`:
- General instructions（評価前に Docker をクリーン）

`回答テンプレ`:
- 「評価要項指定のクリーンコマンドを先に実行します。」

`実演コマンド`:

```bash
docker stop $(docker ps -qa) 2>/dev/null || true
docker rm $(docker ps -qa) 2>/dev/null || true
docker rmi -f $(docker images -qa) 2>/dev/null || true
docker volume rm $(docker volume ls -q) 2>/dev/null || true
docker network rm $(docker network ls -q) 2>/dev/null || true
```

`合格ライン`:
- 直前状態の影響を受けずに検証開始できる。

## 3. Forbidden Patterns

`SCALE項目`:
- General instructions（`network: host` / `links` / `--link` 禁止）
- General instructions（`tail -f`, `bash`だけ起動, `sleep infinity`, `while true` 禁止）

`回答テンプレ`:
- 「`network: host` と `links` は使っていません。」
- 「エントリポイントは無限ループではなく、最後にメインプロセスを `exec` します。」

`実演コマンド`:

```bash
grep -n "network: host" srcs/docker-compose.yml || true
grep -n "links:" srcs/docker-compose.yml || true
grep -RIn -- "--link\|tail -f\|sleep infinity\|while true" srcs Makefile || true
```

`合格ライン`:
- 禁止事項に該当なし。

## 4. README / USER_DOC / DEV_DOC

`SCALE項目`:
- README check
- Documentation check

`回答テンプレ`:
- 「READMEは先頭行の指定形式、Description / Instructions / Resources / AI usageを満たしています。」
- 「`USER_DOC.md` は利用者向け、`DEV_DOC.md` は開発者向け運用手順です。」

`実演コマンド`:

```bash
head -n 2 README.md
grep -n "## Description\|## Instructions\|## Resources\|AI Usage" README.md
wc -l USER_DOC.md DEV_DOC.md
```

`合格ライン`:
- README必須要件が揃っている。
- `USER_DOC.md` と `DEV_DOC.md` が存在し空でない。

## 5. Activity Overview (口頭試問)

`SCALE項目`:
- Activity overview

`回答テンプレ`:
- 「Dockerはプロセス隔離、Composeは複数サービス定義と一括管理です。」
- 「Composeなしは単体 `docker run` の管理になり、依存関係・ネットワーク・ボリューム定義の一元化が弱くなります。」
- 「VMはOSごと仮想化、Dockerは軽量なコンテナ分離です。」
- 「本構成は `srcs/docker-compose.yml` に集約し、サービスごと Dockerfile を分離しています。」

`実演コマンド`:

```bash
sed -n '1,260p' srcs/docker-compose.yml
```

`合格ライン`:
- 4つの質問に簡潔に回答できる。

## 6. Build and Start via Makefile

`SCALE項目`:
- Docker Basics
- General instructions（Makefileからcompose起動）

`回答テンプレ`:
- 「起動は `make` のみで行い、内部で `docker compose` を呼びます。」

`実演コマンド`:

```bash
make init
make
make ps
docker compose -f srcs/docker-compose.yml ps
```

`合格ライン`:
- `mariadb` / `wordpress` / `nginx` が `Up`。

## 7. Docker Basics (Dockerfile / image / base)

`SCALE項目`:
- Docker Basics

`回答テンプレ`:
- 「各必須サービスに1つずつDockerfileがあります。」
- 「`FROM` は Debian系の固定タグで、`latest` は未使用です。」
- 「イメージ名はサービス名と一致させています。」

`実演コマンド`:

```bash
ls srcs/requirements/nginx/Dockerfile srcs/requirements/wordpress/Dockerfile srcs/requirements/mariadb/Dockerfile
grep -RIn "^FROM " srcs/requirements/*/Dockerfile
grep -RIn "latest" srcs/requirements/*/Dockerfile srcs/docker-compose.yml || true
docker compose -f srcs/docker-compose.yml config | sed -n '1,220p'
```

`合格ライン`:
- Dockerfile不足なし。
- `latest` 使用なし。
- compose上の `image` と `service` 名が一致。

## 8. Docker Network

`SCALE項目`:
- Docker Network

`回答テンプレ`:
- 「bridge networkを使い、`mariadb` / `wordpress` をサービス名で名前解決して通信します。」
- 「公開ポートは `nginx` の443だけです。」

`実演コマンド`:

```bash
docker network ls | grep inception
docker network inspect srcs_inception
```

`合格ライン`:
- プロジェクトネットワークが存在し、コンテナが接続されている。

## 9. NGINX with SSL/TLS

`SCALE項目`:
- NGINX with SSL/TLS
- Simple setup（443のみ、http不可）

`回答テンプレ`:
- 「入口は NGINX の 443 のみで、TLSv1.2/1.3 のみ許可です。」
- 「証明書は自己署名をコンテナ内で生成しています。」

`実演コマンド`:

```bash
docker compose -f srcs/docker-compose.yml exec -T nginx nginx -T | grep -n "listen 443\|ssl_protocols\|server_name\|fastcgi_pass"
curl -vk https://sykawai.42.fr
curl -v http://sykawai.42.fr
```

任意（TLSバージョン確認）:

```bash
echo | openssl s_client -connect sykawai.42.fr:443 -tls1_2 2>/dev/null | grep Protocol
echo | openssl s_client -connect sykawai.42.fr:443 -tls1_3 2>/dev/null | grep Protocol
echo | openssl s_client -connect sykawai.42.fr:443 -tls1 2>/dev/null | head
```

`合格ライン`:
- HTTPSでWPが表示される。
- HTTPではアクセスできない。
- TLS1.2/1.3が有効。

## 10. WordPress + php-fpm and Volume

`SCALE項目`:
- WordPress with php-fpm and its volume

`回答テンプレ`:
- 「WordPressコンテナに NGINX は入れていません。PHP-FPMのみです。」
- 「初回起動でWPを自動初期化し、管理者+一般ユーザーを作成します。」
- 「管理者名は `admin`/`administrator` を含まない値です。」

`実演コマンド`:

```bash
docker compose -f srcs/docker-compose.yml exec -T wordpress wp core is-installed --allow-root --path=/var/www/wordpress
docker compose -f srcs/docker-compose.yml exec -T wordpress wp user list --allow-root --path=/var/www/wordpress --fields=ID,user_login,roles --format=table
docker volume inspect srcs_wordpress_data
```

`合格ライン`:
- インストール画面が出ない。
- 管理者と一般ユーザーの2ユーザーがある。
- volume が `/home/sykawai/data/wordpress` に対応している。

## 11. MariaDB and Volume

`SCALE項目`:
- MariaDB and its volume

`回答テンプレ`:
- 「MariaDBコンテナに NGINX は入っていません。」
- 「`/run/secrets/db_root_password` を使って root ログインします。」

`実演コマンド`:

```bash
docker compose -f srcs/docker-compose.yml exec -T mariadb sh -lc "ss -lntp | grep 3306"
docker compose -f srcs/docker-compose.yml exec -T mariadb sh -lc 'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES; USE wordpress; SHOW TABLES;"'
docker volume inspect srcs_mariadb_data
```

`合格ライン`:
- `wordpress` DBが存在。
- テーブルが存在。
- volume が `/home/sykawai/data/mariadb` に対応している。

## 12. Persistence

`SCALE項目`:
- Persistence!

`回答テンプレ`:
- 「投稿追加後に再起動してもデータが残ることを確認します。」

`実演コマンド`:

```bash
docker compose -f srcs/docker-compose.yml exec -T wordpress wp post create --allow-root --path=/var/www/wordpress --post_title='persist-check' --post_status=publish --porcelain
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml up -d
docker compose -f srcs/docker-compose.yml exec -T wordpress wp post list --allow-root --path=/var/www/wordpress --fields=ID,post_title,post_status --format=table
```

`合格ライン`:
- 再起動後も投稿/変更内容が残る。

## 13. Configuration Modification

`SCALE項目`:
- Configuration modification

`回答テンプレ`:
- 「指定されたサービス設定を変更し、再ビルド後の動作をその場で示します。」

`実演コマンド`:

```bash
# 例: nginx の公開ポートを 443:443 から 8443:443 に変更
make re
docker compose -f srcs/docker-compose.yml ps
```

`合格ライン`:
- 変更が反映され、機能が維持される。

## 14. Final Decision Rule

`SCALE項目`:
- Final evaluation policy

`回答テンプレ`:
- 「Mandatoryで1つでも未達があればその時点で終了。Mandatory完了後のみBonus評価です。」

`合格ライン`:
- Mandatory全項目の実演と説明が破綻なく通る。


## 15.追加実装対策

## `localhost:1000` で接続するための変更箇所メモ

現在の構成は `443/TLS(https)` のみ公開です。`http://localhost:1000` にするなら以下を変更します（実変更は未実施）。

1. 公開ポートの変更
- `srcs/docker-compose.yml` の `ports: "443:443"` を `1000:80`（HTTP化する場合）へ変更。
- `https` のままでよければ `1000:443` だけでも可（この場合URLは `https://localhost:1000`）。

2. NGINX 待受設定の変更（HTTP化する場合）
- `srcs/requirements/nginx/conf/nginx.conf` の `listen 443 ssl;` を `listen 80;` に変更。
- 同ファイルの SSL 設定行（証明書指定など）は不要になる。

3. （任意）Dockerfile の `EXPOSE` を合わせる
- `srcs/requirements/nginx/Dockerfile` の `EXPOSE 443` を `EXPOSE 80` に変更（必須ではない）。

4. （`https://localhost:1000` 運用時に推奨）ドメイン名
- `srcs/.env` の `DOMAIN_NAME` を `localhost` にすると証明書 CN とのズレが減る。

要点:
- `http://localhost:1000` を厳密に満たすなら `docker-compose.yml` と `nginx.conf` の両方を変更。
- `localhost:1000` で開ければよいだけなら、ポートだけ変えて `https://localhost:1000` が最短。
