---
layout: post
title: "Zabbix 6.0をTimescaleDB対応のPostgreSQLとの組み合わせでインストールした"
date: 2022-11-05 13:32 +0900
comments: true
category: blog
tags: zabbix
---
Zabbix 6.0 LTS を TimescaleDB 対応の PostgreSQL との組み合わせでインストールしてみました。

<!--more-->

## 動作確認環境

- Ubuntu 22.04.1 LTS (jammy)
- lxd 5.0.1-9dcf35b
- Zabbix 6.0 LTS (6.0.10 と一部 6.0.9)

## コンテナ作成

試行錯誤しやすいように LXD の環境で作成しました。
`lxd init` は最近よく使っている btrfs をストレージに使うように設定しました。

```console
# lxc launch ubuntu:22.04
```

## コンテナの初期設定

以下のシェルスクリプトで、ホスト側の `apt-cacher-ng` を使う設定と `etckeeper` のインストールと `needrestart` での問い合わせの停止などをしました。

```bash
#!/bin/bash
set -euxo pipefail
# lxc launch ubuntu:22.04
# ./init-instance.sh INSTANCE-NAME
INSTANCE=$1
IPV6ADDR=$(ip -6 -o addr show dev lxdbr0 scope global | awk '/inet6/{print $4}' | cut -d/ -f1)
cat >/tmp/apt.conf <<EOF
Acquire::http { Proxy "http://[$IPV6ADDR]:3142"; };
EOF
lxc file push /tmp/apt.conf $INSTANCE/etc/apt/apt.conf.d/50local
lxc exec $INSTANCE -- apt update
lxc exec $INSTANCE -- apt install etckeeper
echo '$nrconf{restart} = "a";' | lxc exec $INSTANCE -- tee /etc/needrestart/conf.d/50local.conf >/dev/null
lxc exec $INSTANCE -- apt full-upgrade -V -y
lxc exec $INSTANCE -- apt autoremove --purge -y
lxc exec $INSTANCE -- etckeeper vcs gc
```

## TimescaleDB のインストール

<https://docs.timescale.com/install/latest/self-hosted/installation-debian/> や <https://packagecloud.io/timescale/timescaledb/install> を参考にしてインストールしました。
docs.timescaledb.com の方は `https://packagecloud.io/timescale/timescaledb/debian/` と `debian` 固定になっていましたが、
Ubuntu なら `ubuntu` にする必要がありました。

<https://www.zabbix.com/documentation/6.0/jp/manual/installation/requirements> によると「TimescaleDB for PostgreSQL」は「2.0.1-2.7」となっていて、zabbix 6.0.9 は最新の 2.8 には対応していなかったので、2.7 に固定しています。
[英語の方](https://www.zabbix.com/documentation/6.0/en/manual/installation/requirements)をみると「2.0.1-2.8」になっているので、今の zabbix 6.0.10 は対応していますが、同様に困ったときのために、固定するままのスクリプトものせておきます。
TimescaleDB が PostgreSQL 15 に対応していないということで、PostgreSQL 14 になっています。

`/etc/apt/preferences.d/timescaledb` で TimescaleDB のバージョン固定もしていますが、一度設定が終われば zabbix 6.0.9 でも動いているように見えたので、不要かもしれません。

以下のシェルスクリプトでインストールしました。

```bash
#!/bin/bash
set -euxo pipefail
INSTANCE=$1
lxc exec $INSTANCE -- apt install gnupg postgresql-common apt-transport-https lsb-release wget -y
lxc exec $INSTANCE -- /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh || :
lxc exec $INSTANCE -- mkdir -p /etc/apt/keyrings
wget -O- https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor | lxc exec $INSTANCE -- tee /etc/apt/keyrings/timescale_timescaledb-archive-keyring.gpg >/dev/null
lxc exec $INSTANCE -- sh -c '
. /etc/os-release
{
  echo "deb [signed-by=/etc/apt/keyrings/timescale_timescaledb-archive-keyring.gpg] https://packagecloud.io/timescale/timescaledb/$ID/ $VERSION_CODENAME main"
  echo "deb-src [signed-by=/etc/apt/keyrings/timescale_timescaledb-archive-keyring.gpg] https://packagecloud.io/timescale/timescaledb/$ID/ $VERSION_CODENAME main"
} > /etc/apt/sources.list.d/timescale_timescaledb.list'
lxc exec $INSTANCE -- apt update
lxc exec $INSTANCE -- apt install timescaledb-2-postgresql-14='2.7.*' timescaledb-2-loader-postgresql-14='2.7.*' -y
lxc exec $INSTANCE -- timescaledb-tune --quiet --yes
lxc exec $INSTANCE -- systemctl restart postgresql.service
cat <<EOF | lxc exec $INSTANCE -- tee /etc/apt/preferences.d/timescaledb >/dev/null
Package: timescaledb-2-loader-postgresql-14 timescaledb-2-postgresql-14
Pin: version 2.7.*
Pin-Priority: 900
EOF
```

バージョンを固定しないなら以下のようになります。

```bash
#!/bin/bash
set -euxo pipefail
INSTANCE=$1
lxc exec $INSTANCE -- apt install gnupg postgresql-common apt-transport-https lsb-release wget -y
lxc exec $INSTANCE -- /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh || :
lxc exec $INSTANCE -- mkdir -p /etc/apt/keyrings
wget -O- https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor | lxc exec $INSTANCE -- tee /etc/apt/keyrings/timescale_timescaledb-archive-keyring.gpg >/dev/null
lxc exec $INSTANCE -- sh -c '
. /etc/os-release
{
  echo "deb [signed-by=/etc/apt/keyrings/timescale_timescaledb-archive-keyring.gpg] https://packagecloud.io/timescale/timescaledb/$ID/ $VERSION_CODENAME main"
  echo "deb-src [signed-by=/etc/apt/keyrings/timescale_timescaledb-archive-keyring.gpg] https://packagecloud.io/timescale/timescaledb/$ID/ $VERSION_CODENAME main"
} > /etc/apt/sources.list.d/timescale_timescaledb.list'
lxc exec $INSTANCE -- apt update
lxc exec $INSTANCE -- apt install timescaledb-2-postgresql-14 -y
lxc exec $INSTANCE -- timescaledb-tune --quiet --yes
lxc exec $INSTANCE -- systemctl restart postgresql.service
```

### Zabbix 6.0 のインストール

<https://www.zabbix.com/download?zabbix=6.0&os_distribution=ubuntu&os_version=22.04&components=server_frontend_agent&db=pgsql&ws=apache> を参考にして Zabbix 6.0 をインストールします。

`zabbix-agent` は `zabbix-agent2` にしました。

`zabbix-frontend-php` が `php` に `Depends` していて、
`php` が `Depends: php7.4` で、
`php7.4` が `Depends: libapache2-mod-php7.4 | php7.4-fpm | php7.4-cgi, php7.4-common` となっていて、
明示的に指定しないと `libapache2-mod-php7.4 ` 経由で `apache2` も入ってしまうので、
`php-fpm` も追加しました。

`php7.4-pgsql` の `7.4` は明示的に指定する必要がなさそうなので、
`php-pgsql` にしました。

```bash
#!/bin/bash
set -euxo pipefail
INSTANCE=$1
URL=$(lxc exec $INSTANCE -- sh -c '. /etc/os-release && echo https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4%2B${ID}${VERSION_ID}_all.deb')
wget -O- $URL | lxc exec $INSTANCE -- tee /tmp/zabbix-release.deb >/dev/null
lxc exec $INSTANCE -- dpkg -i /tmp/zabbix-release.deb
lxc exec $INSTANCE -- apt update
lxc exec $INSTANCE -- apt install zabbix-server-pgsql zabbix-frontend-php php-fpm php-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent2 -y
```

## データベースと zabbix-server の初期設定

他のスクリプトはできるだけ羃等にしていますが、これは羃等ではないので注意が必要です。

```bash
#!/bin/bash
set -uxo pipefail
INSTANCE=$1
PGPASSWORD=$(openssl rand -hex 32)
lxc exec $INSTANCE -- sudo -u postgres createuser zabbix
echo "ALTER ROLE zabbix WITH PASSWORD '$PGPASSWORD';" | lxc exec $INSTANCE -- sudo -u postgres psql
lxc exec $INSTANCE -- sudo -u postgres createdb -O zabbix zabbix
lxc exec $INSTANCE -- sh -c 'zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix'
echo 'CREATE EXTENSION IF NOT EXISTS timescaledb;' | lxc exec $INSTANCE -- sudo -u zabbix psql zabbix
lxc exec $INSTANCE -- sh -c 'cat /usr/share/zabbix-sql-scripts/postgresql/timescaledb.sql | sudo -u zabbix psql zabbix'
lxc exec $INSTANCE -- sh -c 'grep -q "^Include=" /etc/zabbix/zabbix_server.conf || echo "Include=/etc/zabbix_server.conf.d/*.conf" >> /etc/zabbix/zabbix_server.conf'
lxc exec $INSTANCE -- mkdir -p /etc/zabbix_server.conf.d
lxc exec $INSTANCE -- bash -c "install -m 640 -o root -g zabbix <(echo 'DBPassword=$PGPASSWORD') /etc/zabbix_server.conf.d/DBPassword.conf"
lxc exec $INSTANCE -- systemctl enable zabbix-server.service --now
```

### 実行例

シェルスクリプトではなく直接実行した結果の例は以下のような感じです。

まずユーザーとデータベースを作成します。

```console
# sudo -u postgres createuser --pwprompt zabbix
could not change directory to "/root": Permission denied
Enter password for new role:
Enter it again:
# sudo -u postgres createdb -O zabbix zabbix
could not change directory to "/root": Permission denied
```

初期データを入れます。

```console
# zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
(大量に流れていく)
COMMIT
```

`zabbix` データベースで `TimescaleDB` を有効にします。

```console
# echo 'CREATE EXTENSION IF NOT EXISTS timescaledb;' | sudo -u zabbix psql zabbix
could not change directory to "/root": Permission denied
WARNING:
WELCOME TO
 _____ _                               _     ____________
|_   _(_)                             | |    |  _  \ ___ \
  | |  _ _ __ ___   ___  ___  ___ __ _| | ___| | | | |_/ /
  | | | |  _ ` _ \ / _ \/ __|/ __/ _` | |/ _ \ | | | ___ \
  | | | | | | | | |  __/\__ \ (_| (_| | |  __/ |/ /| |_/ /
  |_| |_|_| |_| |_|\___||___/\___\__,_|_|\___|___/ \____/
			   Running version 2.7.2
For more information on TimescaleDB, please visit the following links:

 1. Getting started: https://docs.timescale.com/timescaledb/latest/getting-started
 2. API reference documentation: https://docs.timescale.com/api/latest
 3. How TimescaleDB is designed: https://docs.timescale.com/timescaledb/latest/overview/core-concepts

Note: TimescaleDB collects anonymous reports to better understand and assist our users.
For more information and how to disable, please see our docs https://docs.timescale.com/timescaledb/latest/how-to-guides/configuration/telemetry.

CREATE EXTENSION
```

`timescaledb` を使う設定を入れます。

```console
# cat /usr/share/zabbix-sql-scripts/postgresql/timescaledb.sql | sudo -u zabbix psql zabbix
could not change directory to "/root": Permission denied
NOTICE:  PostgreSQL version 14.5 (Debian 14.5-1.pgdg110+1) is valid
NOTICE:  TimescaleDB extension is detected
NOTICE:  TimescaleDB version 2.7.2 is valid
NOTICE:  TimescaleDB is configured successfully
DO
```

データベースのパスワードを zabbix-server に設定して起動します。

```console
# echo 'Include=/etc/zabbix_server.conf.d/*.conf' >> /etc/zabbix/zabbix_server.conf
# mkdir -p /etc/zabbix_server.conf.d
# install -m 640 -o root -g zabbix <(echo 'DBPassword=SomeDataBasePassword') /etc/zabbix_server.conf.d/DBPassword.conf
# systemctl enable zabbix-server.service --now
```

## Web UI の設定

`nginx` の `listen 8080` を有効にして `wget` で確認します。

```bash
#!/bin/bash
set -euxo pipefail
INSTANCE=$1
lxc exec $INSTANCE -- sed -i -e 's/^#\(.*listen.*\)/\1/' -e 's/^#\(.*server_name.*\)example\.com;/\1'$INSTANCE';/' /etc/nginx/conf.d/zabbix.conf
lxc exec $INSTANCE -- systemctl reload nginx
lxc exec $INSTANCE -- wget -O- http://localhost:8080
```

## Web UI の設定

ポートフォワーディングで入って、ブラウザーで `http://localhost:8080` を開いて初期設定を開始しました。
設定したデータベースのパスワード以外は適当に設定しました。

データベースのパスワードは `cat /etc/zabbix_server.conf.d/DBPassword.conf` で確認したものを設定しました。
Zabbixサーバー名は複数動かしたときに区別しやすくなるのでホスト名を設定しました。

### ロケール設定

日本語ロケールが選べなかったので、有効にして `php-fpm` を再起動して反映しました。

```bash
sed -i -e 's/^# \(ja_JP.UTF-8\)/\1/' /etc/locale.gen
dpkg-reconfigure -f noninteractive locales
systemctl restart php8.1-fpm.service
```

### グラフのフォント設定

グラフの中の日本語が文字化けするので、noto font を使うようにしました。
`zabbix-frontend-php` パッケージのインストール前に `fonts-ipafont` や `fonts-vlgothic` などの `/etc/alternatives/fonts-japanese-gothic.ttf` が設定されるフォントをインストールしておくと自動的に使われますが、最近だと noto の方が良いかなと思って、優先的に使う設定にしています。
後から `fonts-ipafont` などを入れた場合は `dpkg-reconfigure zabbix-frontend-php` で自動設定できます。

```bash
apt install fonts-noto
update-alternatives --install /usr/share/zabbix/assets/fonts/graphfont.ttf zabbix-frontend-font /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc 50
```

## 失敗

以前に Debian 11 で試したときの失敗例も載せておきます。

### TimescaleDB なし

TimescaleDB を有効にしていないのに使おうとするとこのようなエラーになりました。

```console
root@zabbix-202210:~# cat /usr/share/zabbix-sql-scripts/postgresql/timescaledb.sql | sudo -u zabbix psql zabbix
could not change directory to "/root": Permission denied
NOTICE:  PostgreSQL version 14.5 (Debian 14.5-1.pgdg110+1) is valid
ERROR:  TimescaleDB extension is not installed
CONTEXT:  PL/pgSQL function inline_code_block line 42 at RAISE
root@zabbix-202210:~# su postgres -c psql
could not change directory to "/root": Permission denied
psql (14.5 (Debian 14.5-1.pgdg110+1))
Type "help" for help.

postgres=# CREATE database example;
CREATE DATABASE
postgres=# \c example
You are now connected to database "example" as user "postgres".
example=# CREATE EXTENSION IF NOT EXISTS timescaledb;
FATAL:  extension "timescaledb" must be preloaded
HINT:  Please preload the timescaledb library via shared_preload_libraries.

This can be done by editing the config file at: /etc/postgresql/14/main/postgresql.conf
and adding 'timescaledb' to the list in the shared_preload_libraries config.
		# Modify postgresql.conf:
		shared_preload_libraries = 'timescaledb'

Another way to do this, if not preloading other libraries, is with the command:
		echo "shared_preload_libraries = 'timescaledb'" >> /etc/postgresql/14/main/postgresql.conf

(Will require a database restart.)

If you REALLY know what you are doing and would like to load the library without preloading, you can disable this check with:
		SET timescaledb.allow_install_without_preload = 'on';
server closed the connection unexpectedly
		This probably means the server terminated abnormally
		before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
example=# \dx
				 List of installed extensions
  Name   | Version |   Schema   |         Description
---------+---------+------------+------------------------------
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
(1 row)

example=#
\q
root@zabbix-202210:~#
```

### TimescaleDB が新しすぎ

Zabbix 6.0.9 だと
`TimescaleDB` を有効にするタイミングで現在の最新の 2.8.0 だと有効にするところまではうまくいくのですが、
`zabbix-server.service` が起動しませんでした。

```console
root@zabbix-202210:~# echo 'CREATE EXTENSION IF NOT EXISTS timescaledb;' | sudo -u zabbix psql zabbix
could not change directory to "/root": Permission denied
WARNING:
WELCOME TO
 _____ _                               _     ____________
|_   _(_)                             | |    |  _  \ ___ \
  | |  _ _ __ ___   ___  ___  ___ __ _| | ___| | | | |_/ /
  | | | |  _ ` _ \ / _ \/ __|/ __/ _` | |/ _ \ | | | ___ \
  | | | | | | | | |  __/\__ \ (_| (_| | |  __/ |/ /| |_/ /
  |_| |_|_| |_| |_|\___||___/\___\__,_|_|\___|___/ \____/
			   Running version 2.8.0
For more information on TimescaleDB, please visit the following links:

 1. Getting started: https://docs.timescale.com/timescaledb/latest/getting-started
 2. API reference documentation: https://docs.timescale.com/api/latest
 3. How TimescaleDB is designed: https://docs.timescale.com/timescaledb/latest/overview/core-concepts

Note: TimescaleDB collects anonymous reports to better understand and assist our users.
For more information and how to disable, please see our docs https://docs.timescale.com/timescaledb/latest/how-to-guides/configuration/telemetry.

CREATE EXTENSION
root@zabbix-202210:~# cat /usr/share/zabbix-sql-scripts/postgresql/timescaledb.sql | sudo -u zabbix psql zabbix
could not change directory to "/root": Permission denied
NOTICE:  PostgreSQL version 14.5 (Debian 14.5-1.pgdg110+1) is valid
NOTICE:  TimescaleDB extension is detected
NOTICE:  TimescaleDB version 2.8.0 is valid
NOTICE:  TimescaleDB is configured successfully
DO

root@zabbix-202210:~# systemctl start zabbix-server.service
Job for zabbix-server.service failed because the service did not take the steps required by its unit configuration.
See "systemctl status zabbix-server.service" and "journalctl -xe" for details.
root@zabbix-202210:~# tail -n2 /var/log/zabbix/zabbix_server.log
 16613:20221006:075126.437 Unsupported DB! timescaledb version is 20800 which is higher than maximum of 20799
 16613:20221006:075126.437 Recommended version should not be higher than TimescaleDB Community Edition 2.7.
root@zabbix-202210:~#
```

## まとめ

Zabbix 6.0 LTS を入れて監視設定を開始する準備ができました。
この後は設定のリフレッシュを兼ねて、Zabbix 5.0 からエクスポートしてインポートしたり、新しく設定したりしていく予定です。
