# USER_DOC

## このスタックで提供されるもの
このプロジェクトは以下を提供します。
- HTTPS で保護された WordPress サイト
- サイト管理用の WordPress 管理画面
- 再起動後もコンテンツとデータベースが保持される永続データ

## プロジェクトの起動
以下を実行します。
```bash
make
```

## プロジェクトの停止
以下を実行します。
```bash
make down
```

## Webサイトへのアクセス
1. `/etc/hosts` で、ドメインが VM/ローカル IP を指していることを確認します。
2. 以下を開きます。  
   `https://<login>.42.fr`（このリポジトリの現在のデフォルト: `https://sykawai.42.fr`）
3. HTTP アクセス（`http://...`）は利用不可であるべきです。公開されるのは 443 番ポートの HTTPS のみです。

## 管理画面へのアクセス
1. 以下を開きます。  
   `https://<login>.42.fr/wp-admin`（または設定した `DOMAIN_NAME`）
2. このプロジェクトで設定した WordPress 管理者アカウントでログインします。

WordPress のインストール画面は表示されないはずです。コンテナ初期化時に `wp-cli` によってセットアップが自動実行されるためです。

## 認証情報の管理場所
- 非機密設定: `srcs/.env`
- パスワードファイル: `secrets/db_password.txt`, `secrets/db_root_password.txt`, `secrets/wp_admin_password.txt`, `secrets/wp_user_password.txt`

認証情報を変更した場合は、以下を実行します。
```bash
make re
```

## サービスを素早く確認
以下を実行します。
```bash
make ps
docker compose -f srcs/docker-compose.yml logs --tail=100
```

期待結果:
- `nginx`, `wordpress`, `mariadb` が起動している
- `https://<login>.42.fr` でサイトにアクセスできる
- WordPress 管理画面が正常に開く

## 再起動後の確認
1. VM を再起動します。
2. `make` を実行します。
3. 以下を確認します。
- 以前の投稿/固定ページ/コメントが残っている
- 管理者ログインが引き続き可能
- HTTPS アクセスが引き続き可能
