# DEV_DOC

## 目的
このドキュメントは、開発者として Inception スタックをセットアップ、実行、保守する方法を説明します。

## 前提条件
- Linux VM 環境（課題要件）
- Docker Engine
- Docker Compose プラグイン（`docker compose`）
- Make
- 設定済みのローカルドメイン: `<login>.42.fr` -> VM/ローカル IP

## 初期セットアップ
1. リポジトリを clone し、ルートディレクトリへ移動します。
2. `srcs/.env` を作成/更新し、非機密項目を設定します。
3. `secrets/` に secret ファイルを作成します。  
   `db_password.txt`, `db_root_password.txt`, `wp_admin_password.txt`, `wp_user_password.txt`
4. `srcs/docker-compose.yml` のホスト側データパスを更新します。  
   `/home/yourlogin/data/mariadb` と `/home/yourlogin/data/wordpress`
5. ホスト側の永続化ディレクトリを作成します。  
   `mkdir -p /home/<login>/data/mariadb /home/<login>/data/wordpress`

## ビルドと起動
リポジトリルートで Makefile ターゲットを使用します。
- `make`: `docker compose -f srcs/docker-compose.yml up --build -d`
- `make down`: コンテナ停止/削除
- `make clean`: コンテナとボリュームを停止/削除
- `make fclean`: `clean` + Docker system prune
- `make re`: フルリビルド（`fclean` 後に `up`）
- `make ps`: サービス状態の表示

## フォルダ構成
- `Makefile`: プロジェクトのエントリポイントコマンド
- `srcs/docker-compose.yml`: サービス、ネットワーク、ボリューム、secrets
- `srcs/.env`: 非機密の実行時変数
- `srcs/requirements/nginx/`: NGINX イメージのビルドコンテキストと TLS 設定
- `srcs/requirements/wordpress/`: `wp-cli` を使った WordPress + PHP-FPM セットアップ
- `srcs/requirements/mariadb/`: MariaDB の初期化と実行設定
- `secrets/`: コンテナにマウントされるローカル secret ファイル

## docker-compose 概要
サービス:
- `mariadb`: データベースサービス。Docker ネットワーク内の `3306` のみ公開
- `wordpress`: PHP-FPM + WordPress。`mariadb` に依存し、内部 `9000` を公開
- `nginx`: 唯一の公開サービス。ホスト `443:443` をバインドし、`wordpress` に依存

再起動ポリシー:
- 全サービスで `restart: unless-stopped` を使用

## ボリュームと永続化
定義されるボリューム:
- `mariadb_data` -> コンテナ内 `/var/lib/mysql`
- `wordpress_data` -> コンテナ内 `/var/www/wordpress`

どちらも、ローカル driver options で以下にマッピングされた Docker named volume です。
- `/home/<login>/data/mariadb`
- `/home/<login>/data/wordpress`

データはコンテナ再作成後も保持されるため、再起動/再ビルドをまたいで永続化されます。

## ネットワーク設計
- カスタムブリッジネットワーク: `inception`
- コンテナ間 DNS はサービス名（`mariadb`, `wordpress`）を使用
- `network: host` と `links` は不使用
- 外部から到達可能なのは `443` の NGINX のみ

## Secrets と環境変数
- `.env` には非機密設定（ドメイン、ユーザー名、データベース名、メール）を保存
- secret ファイルは Docker secrets 経由で `/run/secrets/*` にマウント
- entrypoint スクリプトは実行時に secret を読み、欠落時は即時失敗
- パスワードは Dockerfile に埋め込まない

## リビルドと変更フロー
イメージ/実行環境に影響する設定変更時:
1. ファイルを編集（`srcs/.env`、secret ファイル、設定、Dockerfile）
2. `make re` を実行
3. `make ps` と HTTPS アクセスで検証

単純な再起動時:
1. `make down`
2. `make`

## トラブルシューティング用コマンド
状態確認:
```bash
make ps
docker compose -f srcs/docker-compose.yml ps
```

ログ確認:
```bash
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml logs nginx wordpress mariadb
```

ボリューム/ネットワーク確認:
```bash
docker volume ls
docker volume ls | grep -E 'mariadb_data|wordpress_data'
docker volume inspect <project_name>_mariadb_data
docker volume inspect <project_name>_wordpress_data
docker network ls
docker network ls | grep inception
docker network inspect <project_name>_inception
```

コンテナ内シェル/デバッグ:
```bash
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p
docker compose -f srcs/docker-compose.yml exec wordpress wp core is-installed --allow-root --path=/var/www/wordpress
docker compose -f srcs/docker-compose.yml exec nginx nginx -t
```

## 設定変更テスト（評価要件）

評価中に、レビュアーから設定変更（例: ポート変更）を求められる場合があります。  
対応手順:
1. 設定を更新します（例: `docker-compose.yml` または `nginx.conf`）。
2. `make re` を実行します。
3. サービスの到達性を確認します。
