---
layout: post
title: "docker-compose で動かしている postgres のバックアップとリストア"
date: 2018-04-19 23:30 +0900
comments: true
category: blog
tags: linux docker postgresql
---
docker-compose で動かしている postgres のバックアップとリストアが `pg_dump` の実行の仕方によっては `pg_restore` できないファイルができてしまってハマってしまったので、ちゃんとリストアできた方法をまとめました。

<!--more-->

## 環境

- Docker for Mac 10.03.0-ce-mac60 (23751)
  - Engine: 18.03.0-ce
  - Compose: 1.20.1

## docker-compose.yml

データベースも `docker-compose down -v` で消えてくれた方が、ちゃんと再現可能な環境になって良いかと思って、
データベースのデータの保存先は `./tmp/db:/var/lib/postgresql/data` のようにはせずに、
volumes にしました。

```yaml
---
version: '3'
services:
  db:
    image: postgres:latest
    volumes:
    - "db-data:/var/lib/postgresql/data"
    environment:
      POSTGRES_PASSWORD: mysecretpassword
  web:
    build: .
    command: bundle exec rails s -p 5000 -b 0.0.0.0
    volumes:
    - .:/app
    - bundle-cache:/usr/local/bundle
    ports:
    - "5000:5000"
    depends_on:
    - db
    environment:
      DATABASE_URL: postgres://postgres:mysecretpassword@db:5432
volumes:
  db-data:
  bundle-cache:
```

## 失敗例

`pg_dump` を `docker-compose exec` してみると、
`pg_restore` に失敗するファイルができました。
そして `pg_restore` の方はそもそも `-T` をつけないと、リストアが始まりませんでした。
`pg_dump` や `pg_restore` の引数は [dokku-postgres の functions](https://github.com/dokku/dokku-postgres/blob/master/functions) の `service_export` と `service_import` を参考にしています。

```console
$ docker-compose exec db pg_dump -Fc --no-acl --no-owner -U postgres -w example_development > tmp/example_development.pg_dump
$ docker-compose exec db pg_restore -cO -d example_development -U postgres -w < tmp/example_development.pg_dump
the input device is not a TTY
$ docker-compose exec -T db pg_restore -cO -d example_development -U postgres -w < tmp/example_development.pg_dump
pg_restore: [custom archiver] could not read from input file: end of file
```

## 成功例

`pg_dump` の方にも `-T` (Disable pseudo-tty allocation.) をつけると成功しました。
失敗した時とサイズを比べると失敗した方がサイズが大きかったので、内容の差分を調べてみると、改行コードが変換されてしまっていたようです。

```console
$ docker-compose exec -T db pg_dump -Fc --no-acl --no-owner -U postgres -w example_development > tmp/example_development.pg_dump
$ docker-compose exec -T db pg_restore -cO -d example_development -U postgres -w < tmp/example_development.pg_dump
```

## 感想

`docker-compose exec` の `-T` (Disable pseudo-tty allocation.) は
`docker exec` の `-t` (Allocate a pseudo-TTY) とは逆で、
地味にハマりどころになりそうだと思いました。

それから、バックアップはちゃんとリストアできるかどうか確認しておきましょう。
