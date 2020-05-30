---
layout: post
title: "Zabbix 5.0のTemplate App Dockerを使ってみた"
date: 2020-05-30 18:00 +0900
comments: true
category: blog
tags: zabbix docker linux
---
Zabbix 5.0 で Template App Docker というテンプレートが増えていると知ったので、
試してみました。
agent 側が zabbix-agent ではダメで zabbix-agent2 が必要というのがポイントでした。

<!--more-->

## 確認環境

- Zabbix Server 側: Raspbian GNU/Linux 10 (buster)
- zabbix-server-pgsql など: 5.0.1-1+buster
- Agent 側 (Docker 側): Debian GNU/Linux 10 (buster), Ubuntu 18.04.4 LTS (bionic)
- zabbix-agent2: 1:5.0.1-1+buster, 1:5.0.1-1+bionic

## 経緯

[Zabbix 5.0 最新情報のご紹介](https://event.ospn.jp/osc2020-online-nagoya/session/83369)
をみていて、
追加テンプレートのところに「Template App Docker」というのがあったので、
これはすぐに試せそうと思って試そうとしたら、
意外とハマりどころがありました。

## 確認

zabbix-agent のままだと
設定のホストのアイテムでキーが `docker.ping` のものが
`Unsupported item key.` で取得できませんでした。

`zabbix_get` でも試してみると以下のような感じでした。

```
$ zabbix_get -s 127.0.0.1 -k docker.ping
ZBX_NOTSUPPORTED: Unsupported item key.
```

これは `zabbix-agent` の代わりに `zabbix-agent2` を入れることで解決しました。

`zabbix-agent` が動いていると `zabbix-agent2` が port 10050 の listen に失敗するので、
stop して試してうまくいったので、
`zabbix-agent` の方は purge しました。

## グループ追加

`zabbix-agent2` を入れただけだと `docker` に接続する権限がなくて `docker.info` は取得できないままなので、
`adduser zabbix docker` や `gpasswd -a zabbix docker` などで `docker` グループ権限をつける必要があります。

今回は `ansible` での追加削除がしやすくなるかと思って、
`/etc/systemd/system/zabbix-agent2.service.d/docker.conf`
を以下の内容で作成して権限をつけました。

```
[Service]
SupplementaryGroups=docker
```

## 確認

設定のホストのアイテムでキーが `docker.info` のものを開いてテストで値が取得できるようになっていれば大丈夫です。
