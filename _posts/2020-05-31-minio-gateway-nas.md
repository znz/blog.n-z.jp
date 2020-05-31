---
layout: post
title: "MinioでGlusterFSのボリュームを使う"
date: 2020-05-31 12:30 +0900
comments: true
category: blog
tags: minio gluster linux
---
[dokku postgres](https://github.com/dokku/dokku-postgres)
のバックアップ先のひとつとして
GlusterFS のボリュームの一部を使おうと思って、
[MinIO](https://min.io/) を使ってみました。

<!--more-->

## 動作確認環境

- Raspbian GNU/Linux 10 (buster)
- glusterfs-server 5.5-3
- minio version RELEASE.2020-05-29T14-08-49Z

## minio gateway nas

複数サーバーで MinIO を動かすのに
[distributed MinIO](https://docs.min.io/docs/distributed-minio-quickstart-guide.html)
というのを検討していたのですが、
それぞれのサーバーに付いているストレージをそのまま使って共有するためのもので、
GlusterFS ですでに共有されているボリュームを使うのは違うようなので、
1 サーバーで動かしていました。

sらに調べていると `minio server` の代わりに
[minio gateway nas](https://docs.min.io/docs/minio-gateway-for-nas.html)
を使うと同じ NAS の共有ボリューム上で複数の minio インスタンスを実行できると書いてあったので、
そちらを使うようにしました。

[#6009](https://github.com/minio/minio/issues/6009) の時点では
`minio server` との実装の差はなかったような感じのコメントがあるようです。

他にも使用例を探してみたのですが、
[Minio on GlusterFS Volume Guide](https://gist.github.com/harshavardhana/bda9b18d40f9b733e32eaa3b0736ca70)
の複数の minio を同じマシンの別ポートで動かす例ぐらいしかみつけられませんでした。

そのため、同時アクセスがありそうな環境では本当に大丈夫なのかどうか、
もっと調べてから使った方が良さそうです。

## minio のインストール

<https://docs.min.io/> に書いてあるように
<https://dl.min.io/server/minio/release/linux-arm/> (Raspbian なので `linux-arm`) からダウンロードして
`/usr/local/bin/minio` に設置しました。

## systemd unit 作成

<https://github.com/minio/minio-service/tree/master/linux-systemd>
を参考にして `/etc/systemd/system/minio-gateway-nas.service` を作成しました。

`Wants` と `After` に gluster の mount ユニットを追加しています。

1024 以下 (未満?) のポート番号を使うには `AmbientCapabilities=CAP_NET_BIND_SERVICE` を指定する必要があるようですが、
使っていないのでコメントアウトしています。

`User` と `Group` はとりあえず動作確認用として `minio-user` を追加せず、
他で使っていなさそうだった `uucp` を流用しています。

`MINIO_VOLUMES` として共有ディレクトリを使うので、
`minio server` の代わりに `minio gateway nas` を使うようにしました。

```
[Unit]
Description=MinIO gateway nas
Documentation=https://docs.min.io
Wants=network-online.target glfs-hyrule.mount
After=network-online.target glfs-hyrule.mount
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
#AmbientCapabilities=CAP_NET_BIND_SERVICE
WorkingDirectory=/usr/local/

User=uucp
Group=uucp

EnvironmentFile=/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"

ExecStart=/usr/local/bin/minio gateway nas $MINIO_OPTS $MINIO_VOLUMES

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
```

## 環境変数設定

`/etc/default/minio` として以下のような設定をしました。

`/glfs/hyrule/minio-data/` は先ほどの `User` の権限で読み書きできるようにしておきます。

上の設定には入れていませんが、別途 `OnFailure` で Slack 通知を設定しているので、
`--anonymous` オプションを追加して secret key がログに出ないようにしています。

ufw でも制限していますが、
`--address` では平文でのアクセスを避けるために wireguard のアドレスのみ listen するようにしています。
気にしないのなら `--address :9199` のようにポート番号のみでも良さそうです。
IPv6 アドレスのみなら `--address [fdcb:a987:dead:beef::197]:9199` のようになります。


```
# Volume to be used for MinIO server.
MINIO_VOLUMES="/glfs/hyrule/minio-data/"
# Use if you want to run MinIO on a custom port.
MINIO_OPTS="--anonymous --address 10.2.1.197:9199"
# Access Key of the server.
MINIO_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
# Secret key of the server.
MINIO_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```
