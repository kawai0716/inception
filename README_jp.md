*このプロジェクトは、42カリキュラムの一環として sykawai が作成しました。*

# Inception

## 概要
Inception は、Docker Compose を使って仮想マシン上に構築する小規模インフラプロジェクトです。
このスタックは、以下 3 つの専用コンテナで構成されています。
- ポート 443 のみを公開する唯一の公開エントリポイントとしての NGINX
- PHP-FPM を利用する WordPress
- 永続的なデータベース保存のための MariaDB

このプロジェクトの目的は、各サービスのイメージをカスタム Dockerfile から手動で構築し（既製のサービスイメージは不使用）、Docker ネットワークでサービスを分離し、TLSv1.2/TLSv1.3 で外部通信を保護し、Docker ボリュームでデータを永続化することです。

## プロジェクト構成
このプロジェクトでは、Docker を使って各サービスごとに実行時依存関係と起動ロジックをパッケージ化し、Docker Compose でスタック全体のライフサイクルをオーケストレーションします。

プロジェクトのソースは `srcs/` 配下に整理されています。
- `srcs/docker-compose.yml`: サービス構成、ネットワーク、ボリューム、secrets
- `srcs/.env`: 非機密の環境変数（ドメインとアプリ設定）
- `srcs/requirements/nginx`: NGINX Dockerfile、TLS 設定、entrypoint
- `srcs/requirements/wordpress`: WordPress/PHP-FPM Dockerfile、セットアップスクリプト
- `srcs/requirements/mariadb`: MariaDB Dockerfile と初期化スクリプト
- `secrets/`: Docker secrets としてマウントされるローカル秘密情報ファイル

## 設計上の選択
### 仮想マシン vs Docker
- 選択: 仮想マシン内で Docker コンテナを使用。
- 理由: ビルド/デプロイのサイクルが速く、サービス環境の再現性が高く、サービス分離が明確になるため。また、仮想マシン内で作業するという課題要件も満たせます。

### Secrets vs 環境変数
- 選択: ハイブリッド構成。
- 理由: 非機密設定は `.env` に保存し、パスワードは `/run/secrets/*` 配下の Docker secrets から読み込みます。これにより Dockerfile への資格情報の埋め込みを避け、漏えいリスクを低減します。

### Docker ネットワーク vs Host ネットワーク
- 選択: 専用ブリッジネットワーク（`inception`）。
- 理由: サービス間通信を内部に閉じ、公開ポートは NGINX の `443` のみに制限できるため。MariaDB と PHP-FPM をホストネットワークから直接到達不能にし、課題制約（`network: host` 禁止）を満たします。

### Docker ボリューム vs バインドマウント
- 選択: バインドマウントの driver options を設定した named volume。
- 理由: ボリュームのライフサイクルは Docker に管理させつつ、ホスト側では `/home/<login>/data` 配下への明示的な保存を実現し、課題要件を満たせます。
- この方式により永続化が保証され、保存データの手動確認も可能です。

## 手順
### 1. ローカル設定を準備
1. `srcs/.env` のドメインおよび非機密項目を更新します。
2. `secrets/` に必要な secret ファイルを作成/設定します。  
   `db_password.txt`, `db_root_password.txt`, `wp_admin_password.txt`, `wp_user_password.txt`
3. `srcs/docker-compose.yml` 内の `/home/yourlogin/data/...` を実際のログインユーザーのパスに置き換えます（例: `/home/sykawai/data/...`）。
4. ホスト側のディレクトリを作成します。  
   `mkdir -p /home/<login>/data/mariadb /home/<login>/data/wordpress`
5. VM の hosts にエントリを追加します。  
   `<your_local_ip> <login>.42.fr`

### 2. ビルドと起動
```bash
make
```

### 3. 停止
```bash
make down
```

### 4. クリーンリビルド
```bash
make re
```

## 参考資料
- Docker docs: https://docs.docker.com/
- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- NGINX docs: https://nginx.org/en/docs/
- WordPress CLI docs: https://developer.wordpress.org/cli/commands/
- MariaDB docs: https://mariadb.com/kb/en/documentation/
- OpenSSL docs: https://www.openssl.org/docs/

### AI 利用について
AI は以下の補助目的で利用しました。
- 設計判断のレビューと課題制約の解釈確認
- Docker/Compose および TLS 設定リファレンスの照合
- ドキュメントの明瞭性と構成の改善

実装判断、テスト、最終検証はすべてプロジェクト環境で手動実施しています。
