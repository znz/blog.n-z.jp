---
layout: post
title: "Dokkuをproxyとして複数のminio gateway nasをまとめた"
date: 2020-05-31 13:00 +0900
comments: true
category: blog
tags: dokku minio linux
---
`/etc/hosts` だと複数サーバーに1個の DNS 名をつけて
負荷分散や冗長化などができないので、
proxy を挟むことにしました。
そこに letsencrypt の証明書も入れようとすると、
別途設定するのは面倒なので、
`dokku-letsencrypt` が使えるように Dokku の 1 アプリとしてまとめました。

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
- dokku-letsencrypt 0.9.3

## dokku-proxy-to-minio

<https://docs.min.io/docs/setup-nginx-proxy-with-minio.html> の設定例と
[nginx.conf.sigil](https://github.com/dokku/dokku/blob/aa63e79aecafe226ce826497b12c5e74148d0e8a/plugins/nginx-vhosts/templates/nginx.conf.sigil)
を元にして
[dokku-proxy-to-minio](https://github.com/znz/dokku-proxy-to-minio)
を作成しました。

proxy としての動作には必要ないのですが、
Dokku の proxy 設定を動かすために `nginx:alpine` をベースイメージとして
web コンテナーを動かすようにしています。

## 使い方

README に書いたように `MINIO_SERVERS` にバックエンドの minio を設定しておきます。

今回は
[前の記事]({% post_url 2020-05-31-minio-gateway-nas %})
で設定した `minio gateway nas` で動かしている minio を指定しています。

```
$ dokku apps:create proxy-to-minio
-----> Creating proxy-to-minio...
$ dokku config:set proxy-to-minio MINIO_SERVERS="minio1.example.com:9000 minio2.example.com:9000 minio3.example.com:9000"
-----> Setting config vars
       MINIO_SERVERS:  minio1.example.com:9000 minio2.example.com:9000 minio3.example.com:9000
-----> Restarting app proxy-to-minio
 !     App proxy-to-minio has not been deployed
```

## デプロイ

普通の Dokku アプリとして `git push` でデプロイします。

```
$ git clone https://github.com/znz/dokku-proxy-to-minio
$ git remote add dokku dokku@dokku.me:proxy-to-minio
$ git push dokku master
```

## dokku-letsencrypt

`DOKKU_LETSENCRYPT_EMAIL` を設定して証明書を作成しました。

```
$ dokku config:set --no-restart proxy-to-minio DOKKU_LETSENCRYPT_EMAIL=your@email.tld
$ dokku letsencrypt:auto-renew proxy-to-minio
```

## dokku-postgres

[dokku-postgresからMinioにバックアップする]({% post_url 2020-05-31-dokku-postgres-to-minio %})記事に書いたように
`dokku postgres:backup-deauth` で消してから登録し直しました。

## Dokku のハマりどころ

`CHECKS` や `nginx.conf.sigil` は docker イメージの中に入れておかないと
最初にデプロイした時のものがずっと使われて変更が反映されませんでした。
