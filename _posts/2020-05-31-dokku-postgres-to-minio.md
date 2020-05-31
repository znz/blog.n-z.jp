---
layout: post
title: "dokku-postgresからMinioにバックアップする"
date: 2020-05-31 12:45 +0900
comments: true
category: blog
tags: dokku minio linux
---
[dokku postgres](https://github.com/dokku/dokku-postgres)
のバックアップ先のひとつとして
[前の記事]({% post_url 2020-05-31-minio-gateway-nas %})で設定した
[MinIO](https://min.io/) を使ってみました。

<!--more-->

## 動作確認環境

Gluster + Minio 側:

- Raspbian GNU/Linux 10 (buster)
- glusterfs-server 5.5-3
- minio version RELEASE.2020-05-29T14-08-49Z

Dokku 側:

- Ubuntu 18.04.4 LTS
- dokku version 0.20.4
- dokku-postgres 1.11.5

## 認証情報設定

`dokku postgres:backup-auth` で認証情報を設定します。
`bash` なら `set +o history` で履歴に保存しないようにしておくと安全です。

間違えていた場合など、変更する時は `dokku postgres:backup-deauth` で消してから登録し直します。

```
set +o history
dokku postgres:backup-auth some-db AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY us-east-1 s3v4 http://10.2.1.197:9199
set -o history
dokku postgres:backup-deauth some-db
```

## 動作確認

`dokku postgres:backup` でバックアップできるのを確認します。

```
dokku postgres:backup some-db dokku-postgres
```

## 自動バックアップ設定

`dokku postgres:backup-schedule` で cron の設定ができます。
`/etc/cron.d/dokku-postgres-*` に設定ファイルが作成されるようです。

`dokku postgres:backup-unschedule` で削除できます。

```
dokku postgres:backup-schedule some-db '0 3 * * *' dokku-postgres
cat /etc/cron.d/dokku-postgres-*
dokku postgres:backup-unschedule some-db
```
