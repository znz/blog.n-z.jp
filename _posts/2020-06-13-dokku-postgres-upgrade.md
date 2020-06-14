---
layout: post
title: "dokku-postgresで使っているdocker imageのバージョンを上げた"
date: 2020-06-13 23:55 +0900
comments: true
category: blog
tags: dokku linux
---
`dokku-postgres` で使っている postgres の docker image のバージョンアップをしました。

<!--more-->

## 動作確認環境

- Ubuntu 18.04.4 LTS
- dokku version 0.20.4
- dokku-postgres 1.11.5
- dokku-maintenance 0.5.0

## 概要

まずは postgis のイメージを更新したので、以下のような手順になりました。

[postgis/tag](https://hub.docker.com/r/postgis/postgis/tags)
で確認すると同じタグ (`12-3.0`) のまま更新されているようだったので、
2020-06-10 に更新されていたので、
サービス名は日付を入れて「アプリ名-イメージ名-バージョン(.を_に置換)-イメージの日付」にしました。

```
APP=memo-app-r
OLD_SERVICE_NAME=memo-app-r-postgis-12-3_0
NEW_SERVICE_NAME=memo-app-r-postgis-12-3_0-2020-06-10
POSTGRES_IMAGE=postgis/postgis
POSTGRES_IMAGE_VERSION=12-3.0
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1
AWS_SIGNATURE_VERSION=s3v4
ENDPOINT_URL=https://minio.example.com
BUCKET_NAME=dokku-postgres
SCHEDULE="0 3 * * *"

docker pull $POSTGRES_IMAGE:$POSTGRES_IMAGE_VERSION
sudo systemctl start postgres-export
dokku maintenance:on $APP
dokku postgres:backup $OLD_SERVICE_NAME $BUCKET_NAME
dokku postgres:clone $OLD_SERVICE_NAME $NEW_SERVICE_NAME --image $POSTGRES_IMAGE --image-version $POSTGRES_IMAGE_VERSION
dokku postgres:link $NEW_SERVICE_NAME $APP
dokku postgres:promote $NEW_SERVICE_NAME $APP
dokku maintenance:off $APP
dokku postgres:unlink $OLD_SERVICE_NAME $APP
dokku postgres:destroy $OLD_SERVICE_NAME
dokku postgres:backup-auth $NEW_SERVICE_NAME $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $AWS_REGION $AWS_SIGNATURE_VERSION $ENDPOINT_URL
dokku postgres:backup $NEW_SERVICE_NAME $BUCKET_NAME
dokku postgres:backup-schedule $NEW_SERVICE_NAME "$SCHEDULE" $BUCKET_NAME
```

`dokku-postgres` の `README.md` には環境変数でイメージとバージョンを指定する例がありますが、
環境変数は `sudo` などを挟むと受け渡しが微妙なことがあるのと、
`DATABASE_IMAGE` と `DATABASE_IMAGE_VERSION` ではなく `POSTGRES_IMAGE` と `POSTGRES_IMAGE_VERSION` にしないときかなかったなど、
間違っている可能性があるようなので、
`--image` と `--image-version` で指定した方が安定しそうです。

## 詳細

まずメンテナンス時間を減らすためにイメージを pull しておきました。
次に独自に作っているローカルへの全データベースバックアップ (`postgres-export.service`) を実行しました。

ここからはユーザー操作によるデータベースへの書き込みを止めるため、
`dokku-maintenance` でメンテナンス中にしました。

移行前の最終状態のバックアップを `postgres:backup` で取った後、
`postgres:clone` で新しいイメージを使ったサービスを作成してデータをコピーしました。

次に `postgres:link`, `postgres:promote` で新サービスに `DATABASE_URL` を切り替えました。

ここまででデータベースの切り替えは終了しているので、
`maintenance:off` で元に戻しました。

あとは `postgres:unlink`, `postgres:destroy` で旧サービスを削除しました。

最後に `postgres:backup-auth` でバックアップ先の設定をし直したあと、
`postgres:backup` で動作確認して、
`postgres:backup-schedule` でバックアップの cron 設定をし直して、
移行完了しました。

## DATABASE_URL の scheme の postgis 対応

rails で `postgis` を使うのに `DATABASE_URL` を `postgres:` で始まる文字列ではなく `postgis:` で始まる文字列にする必要があるのですが、
以前は変更できなさそうだったので、 `config/database.yml` で
`url: <%= ENV.fetch('DATABASE_URL', '').sub(/^postgres/, "postgis") %>`
と書き換えていたのですが、
`POSTGRES_DATABASE_SCHEME=postgis`
でいけるとわかったので、
`dokku config:set memo-app-r POSTGRES_DATABASE_SCHEME=postgis`
のように設定しました。

## トラブル対処

データベースバージョンアップ中に変更してしまったため、
`dokku postgres:unlink $OLD_SERVICE_NAME $APP`
が実際にはうまくいかず、
環境変数 `DOKKU_POSTGRES_BLACK_URL` が `postges:` で始まる文字列のまま残ってしまったので、
そこだけは `dokku config:unset memo-app-r DOKKU_POSTGRES_BLACK_URL` で対処しておきました。

`head /home/dokku/memo-app-r/DOCKER_OPTIONS_*`
で確認すると `--link` の指定は残っていなかったので、
そこはちゃんと `unlink` できていたようです。
