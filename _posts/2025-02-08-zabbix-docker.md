---
layout: post
title: "zabbix-dockerを試した"
date: 2025-02-08 12:00 +0900
comments: true
category: blog
tags: linux zabbix docker
---
VPS や自宅サーバーなどを監視するのに自宅サーバーに入れた zabbix を使っていて、
サポートが終わったり終わりそうになったら新しい環境に入れなおしていたのですが、
今回は `zabbix-docker` を使って VPS 上で動かすことにしました。

<!--more-->

## 動作確認バージョン

- zabbix 7.2.3

## 参考文献

- <https://github.com/zabbix/zabbix-docker>
- [5 Installation from containers](https://www.zabbix.com/documentation/current/en/manual/installation/containers)
  ([7.2 の 5 Installation from containers](https://www.zabbix.com/documentation/7.2/en/manual/installation/containers))

## 簡単な使い方

```bash
git clone https://github.com/zabbix/zabbix-docker.git
git checkout 7.2
```

- `docker compose -f docker-compose_v3_ubuntu_pgsql_latest.yaml up -d` などの OS とデータベースは好みの組み合わせを起動
- `docker compose -f docker-compose_v3_ubuntu_pgsql_latest.yaml ps` で `PORTS` に `0.0.0.0:80->8080/tcp, [::]:80->8080/tcp, 0.0.0.0:443->8443/tcp, [::]:443->8443/tcp` とあるので `http://localhost/` を開く
- `Username: Admin`, `Password: zabbix` で `Sign in`
- `Administration` - `General` - `GUI` で `Default language` を `Japanese (ja_JP)` に変更 (タイムゾーンも必要に応じて変更)
- `データ収集` - `ホスト` - `Zabbix Server` から `Linux by Zabbix agent` を `リンクと保存データを削除` で削除 (zabbix-agent が動いていないため)

## 後始末

- 試し終わったら `docker compose -f docker-compose_v3_ubuntu_pgsql_latest.yaml down -v` でコンテナなどを削除
- `git clean -ndx` で確認した後、 `git clean -fdx` で `zbx_env/` などを削除

## 主なカスタマイズ

主な設定は `.env` の環境変数で変更できます。

たとえば 80 番ポートでの待ち受けが困るときは、
`ZABBIX_WEB_NGINX_HTTP_PORT=80`
で変更できます。

## 待受 IP アドレスを変更

docker compose での `ports` 設定は `ufw` での制限とは関係なく公開されてしまうので、
VPS 上でそのまま動かすとデフォルトパスワードで誰でもログインできてしまって危険なので、
`compose_zabbix_components.yaml` の `services.web-nginx.ports` に `host_ip` を追加しました。

実際には VPN 経由で接続できる IP アドレスにしました。
直接接続できなければ `127.0.0.1` にして ssh port forwarding などで接続すると良さそうです。


```yaml
 web-nginx:
  ports:
   - name: web-http
     target: 8080
     host_ip: "127.0.0.1" # add
     published: "${ZABBIX_WEB_NGINX_HTTP_PORT}"
     protocol: tcp
     app_protocol: http
   - name: web-https
     target: 8443
     host_ip: "127.0.0.1" # add
     published: "${ZABBIX_WEB_NGINX_HTTPS_PORT}"
     protocol: tcp
     app_protocol: https
```

## timescaledb を有効にする

`.env` で

```bash
POSTGRESQL_IMAGE=postgres
POSTGRESQL_IMAGE_TAG=16-alpine
#POSTGRESQL_IMAGE=timescale/timescaledb
#POSTGRESQL_IMAGE_TAG=2.17.2-pg16
```

を

```bash
#POSTGRESQL_IMAGE=postgres
#POSTGRESQL_IMAGE_TAG=16-alpine
POSTGRESQL_IMAGE=timescale/timescaledb
POSTGRESQL_IMAGE_TAG=2.17.2-pg16
```

に変更して、
`env_vars/.env_db_pgsql` の `ENABLE_TIMESCALEDB=true` を有効にしてから `docker compose -f docker-compose_v3_ubuntu_pgsql_latest.yaml up -d` します。

`管理` - `データの保存期間` で `次よりも古いものはレコードを圧縮` という設定があれば有効になっています。

有効にする前に起動した `zbx_env/` が残っていると有効にできないようなので、うまくいかないようなら削除してから起動しなおします。

## IPv6 を有効にする

`.env` で以下の設定を変更すると IPv6 が有効になって、
zabbix server から外部へ IPv6 での接続ができるようになりました。

```bash
FRONTEND_ENABLE_IPV6=true
BACKEND_ENABLE_IPV6=true
DATABASE_NETWORK_ENABLE_IPV6=true
ADD_TOOLS_ENABLE_IPV6=true
```

最初はよくわかっていなくて全部有効にしたのですが、
`frontend` と `tools_frontend` が外につながっていて、
`backend` と `database` は `internal: true` で内部のみになっているので、
最低限 `FRONTEND_ENABLE_IPV6=true` だけ変更すれば
zabbix server から IPv6 でつながりそうです。

## デフォルトのタイムゾーン変更

`env_vars/.env_web` には例がありませんが、
`PHP_TZ=Asia/Tokyo` を設定すればデフォルトのタイムゾーンを変更できました。

`env_vars/.env_web_override` を作成して書き込めば `git pull` などで更新するときに conflict しにくくて良さそうです。

## zabbix-agent なども起動

`docker compose -f docker-compose_v3_ubuntu_pgsql_latest.yaml --profile full up -d`
や
`docker compose -f docker-compose_v3_ubuntu_pgsql_latest.yaml --profile all up -d`
のように `--profile` を指定すると `zabbix-agent` なども起動できるようです。

## zabbix-agent2 を起動

`Website certificate by Zabbix agent 2` テンプレートの `web.certificate.get` を使いたかった関係で `zabbix-agent2` を起動したかったのですが、
`--profile full` にも `--profile all` にもなかったので、
独自に追加しました。

以下の内容を `override.yaml` などに用意して、
`docker compose -f docker-compose_v3_ubuntu_pgsql_latest.yaml -f override.yaml up -d`
で `zabbix-agent2` も起動できました。

```yaml
 zabbix-agent2:
  extends:
   file: compose_zabbix_components.yaml
   service: agent2
  image: "${ZABBIX_AGENT2_IMAGE}:${ZABBIX_UBUNTU_IMAGE_TAG}${ZABBIX_IMAGE_TAG_POSTFIX}"
  labels:
   com.zabbix.os: "${UBUNTU_OS_TAG}"
  profiles: !reset []
  # Allow access to external networks
  networks:
   tools_frontend:
```

## 実際の設定例

実際の本番環境用には docker compose で複雑なことをやっているので、
それを参考にして元の `zabbix-docker` は改変せずに
`git submodule` にして設定しました。

実際の設定のほとんどは
[zabbix-docker-override](https://github.com/znz/zabbix-docker-override)
に公開しています。

`compose.yaml` の `include` は

```yaml
   - path: ./local.env
     required: false
```

のような指定はできず、
文字列でパスの指定しかできなかったので、
`.gitignore` ではなく
`git update-index --skip-worktree local.env`
で使うのを想定して空の `local.env` を入れて、
`OVERRIDE_ZABBIX_WEB_NGINX_HTTP_HOST_IP` を VPN の IP アドレスにしています。

## まとめ

docker compose の機能を活用して、
`zabbix-docker` をうまく起動できました。

通知の設定などはまだ移行できていないので、
[4 Webhook](https://www.zabbix.com/documentation/current/en/manual/config/notifications/media/webhook)
([7.2](https://www.zabbix.com/documentation/7.2/en/manual/config/notifications/media/webhook))
のメディアごとの README などを参考にして設定していきたいです。
