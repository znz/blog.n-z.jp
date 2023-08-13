---
layout: post
title: "dokku環境でdocker system pruneで掃除した"
date: 2023-08-14 08:33 +0900
comments: true
category: blog
tags: dokku linux
---
[dokku](https://github.com/dokku/dokku)を動かしている VPS の環境で、
Zabbix の監視でディスク使用量が 90% を越えているとアラートがでたので、
`docker system prune` で掃除をしました。

<!--more-->

## 環境

- Ubuntu 20.04.6 LTS
- dokku 0.30.11
- docker-ce 5:24.0.5-1~ubuntu.20.04~focal

## 作業内容

- `df -hT` や `docker system df` で docker がディスク容量を消費しているというのを確認
- `docker system prune` で安全に削除できるものを削除 (必要なものは `dokku apps:list` で確認できる動いているものだけなので)
- `docker images` で確実に不要と判断できる古い `postgres` などのタグを `docker rmi postgres:15.3` などで削除
- 古い `herokuish` のイメージも不要そうだったので、 `docker rmi gliderlabs/herokuish:v0.5.41-18` と `docker rmi gliderlabs/herokuish:latest` や `docker rmi gliderlabs/herokuish:latest-20`, `docker rmi gliderlabs/herokuish:v0.6.1-20`, `docker rmi gliderlabs/herokuish:v0.6.1-22` も実行しました。

## 結果

`/` パーティションのディスク使用量が 90% 以上から 40% 未満に減って解決しました。
