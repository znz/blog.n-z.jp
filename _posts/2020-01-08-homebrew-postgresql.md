---
layout: post
title: "Homebrewでインストールしたpostgresqlが起動しないのを調べた"
date: 2020-01-08 19:00 +0900
comments: true
category: blog
tags: osx homebrew postgresql
---
[ruby-jp Slack](homebrew-postgresql) の `#newbie` で `bin/rails db:create` が通らないという話があったので調べてみた結果のまとめです。

<!--more-->

## 確認環境

- macOS Mojave 10.14.6
- Homebrew 2.2.2-56-g33b4e08
- postgresql 12.1

## 状況

```
could not connect to server: No such file or directory
	Is the server running locally and accepting
	connections on Unix domain socket "/tmp/.s.PGSQL.5432"?
```

という部分を含むログを出してくれていたので、
何らかの原因で postgresql が起動していないような感じでした。

## brew info postgresql

homebrew でインストールした postgresql ということだったので、
まず `brew info` で公式の情報を見るべきだと思ったので試してみたところ、
以下のように pg gem のインストールに使うために手元でもインストール済みでした。

```
% brew info postgresql
postgresql: stable 12.1 (bottled), HEAD
Object-relational database system
https://www.postgresql.org/
/usr/local/Cellar/postgresql/12.1 (3,217 files, 37.3MB) *
  Poured from bottle on 2019-11-23 at 23:26:13
From: https://github.com/Homebrew/homebrew-core/blob/master/Formula/postgresql.rb
==> Dependencies
Build: pkg-config ✔
Required: icu4c ✔, krb5 ✘, openssl@1.1 ✔, readline ✔
==> Options
--HEAD
	Install HEAD version
==> Caveats
To migrate existing data from a previous major version of PostgreSQL run:
  brew postgresql-upgrade-database

To have launchd start postgresql now and restart at login:
  brew services start postgresql
Or, if you don't want/need a background service you can just run:
  pg_ctl -D /usr/local/var/postgres start
```

## brew services

`brew services start postgresql` や `brew services restart postgresql` を試してみたところ、成功したと出るものの、
`launchctl list` で確認してみると起動していません。(左端が `-` だと起動していなくて、起動しているとプロセス ID になります。)

```
% brew services start postgresql
==> Successfully started `postgresql` (label: homebrew.mxcl.postgresql)
% brew services restart postgresql
Stopping `postgresql`... (might take a while)
==> Successfully stopped `postgresql` (label: homebrew.mxcl.postgresql)
==> Successfully started `postgresql` (label: homebrew.mxcl.postgresql)
% launchctl list | grep postgresql
-	2	homebrew.mxcl.postgresql
```

## 直接起動を試す

info の最後にあったフォアグラウンドでの起動を試してエラーメッセージを確認することにしました。
すると以下のように古いバージョンで作成したデータベースがあったのが悪かったようです。

```
% pg_ctl -D /usr/local/var/postgres start
waiting for server to start....2020-01-08 17:33:03.538 JST [63441] FATAL:  database files are incompatible with server
2020-01-08 17:33:03.538 JST [63441] DETAIL:  The data directory was initialized by PostgreSQL version 11, which is not compatible with this version 12.1.
 stopped waiting
pg_ctl: could not start server
Examine the log output.
```

この記事を書いているときに、再現するために `/usr/local/var/postgres*` を消してから試すと別のエラーだったので、
作成されていなかったわけではないようです。

```
% pg_ctl -D /usr/local/var/postgres start
pg_ctl: directory "/usr/local/var/postgres" does not exist
```

## brew postgresql-upgrade-database

info にあった
`brew postgresql-upgrade-database`
を試すとデータベースが変換されて、
`brew services restart postgresql`
を再度実行すると起動するようになりました。

## データベースの場所

```
% launchctl list homebrew.mxcl.postgresql
{
	"StandardOutPath" = "/usr/local/var/log/postgres.log";
	"LimitLoadToSessionType" = "Aqua";
	"StandardErrorPath" = "/usr/local/var/log/postgres.log";
	"Label" = "homebrew.mxcl.postgresql";
	"TimeOut" = 30;
	"OnDemand" = false;
	"LastExitStatus" = 0;
	"PID" = 85701;
	"Program" = "/usr/local/opt/postgresql/bin/postgres";
	"ProgramArguments" = (
		"/usr/local/opt/postgresql/bin/postgres";
		"-D";
		"/usr/local/var/postgres";
	);
};
```

にもあるように、
`/usr/local/var/postgres`
がデータベースの場所でした。

`brew postgresql-upgrade-database`
の変換前のデータベースは
`/usr/local/var/postgres.old`
に残るようです。

## 削除してやり直し

削除して reinstall してみると、本来はインストール中に
`/usr/local/Cellar/postgresql/12.1/bin/initdb --locale=C -E UTF-8 /usr/local/var/postgres`
で作成されるようでした。

```
% brew services stop postgresql
Stopping `postgresql`... (might take a while)
==> Successfully stopped `postgresql` (label: homebrew.mxcl.postgresql)
%  rm -rf /usr/local/var/postgres*
% brew reinstall postgresql
==> Reinstalling postgresql
==> Downloading https://homebrew.bintray.com/bottles/postgresql-12.1.mojave.bottle.1.tar.gz
Already downloaded: /Users/kazu/Library/Caches/Homebrew/downloads/5dcc5e93577dd5495e0102569a6127a76bc1be3a0ce51d0d278aedacf535fde9--postgresql-12.1.mojave.bottle.1.tar.gz
==> Pouring postgresql-12.1.mojave.bottle.1.tar.gz
==> /usr/local/Cellar/postgresql/12.1/bin/initdb --locale=C -E UTF-8 /usr/local/var/postgres
==> Caveats
To migrate existing data from a previous major version of PostgreSQL run:
  brew postgresql-upgrade-database

To have launchd start postgresql now and restart at login:
  brew services start postgresql
Or, if you don't want/need a background service you can just run:
  pg_ctl -D /usr/local/var/postgres start
==> Summary
🍺  /usr/local/Cellar/postgresql/12.1: 3,217 files, 37.3MB
% brew services start postgresql
==> Successfully started `postgresql` (label: homebrew.mxcl.postgresql)
% launchctl list | grep postgresql
91589	0	homebrew.mxcl.postgresql
```
