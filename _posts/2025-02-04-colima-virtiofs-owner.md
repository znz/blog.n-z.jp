---
layout: post
title: "colimaのvirtiofsでファイルのオーナーの挙動を調べた"
date: 2025-02-04 12:00 +0900
comments: true
category: blog
tags: osx docker
---
`colima` を `--vm-type vz` で `--mount-type` を `virtiofs` (`vz` のときのデフォルト) で使っていると、
ファイルのオーナー(とグループ)が不思議な挙動をしていたので、調べてみた結果のメモです。
(グループはオーナーとセットで変化していたので、以下の説明では省略します。)

<!--more-->

## 動作確認環境

- macOS Sequoia 15.3
- colima 0.8.1

## 背景

macOS のデフォルトのログインユーザーの `uid` が `501` で、
`colima` (`lima`) の vm type を `qemu` で使っていると mount type が `9p` でも `sshfs` (`reverse-sshfs`) でも
`vscode` の `devcontainer` でファイルのオーナーが `1000(vscode)` にならずに、
`501` のままになってうまく動きませんでした。

vm type を `vz` にして `virtiofs` にすると期待通り `1000(vscode)` になったのですが、
`colima ssh` で確認するとオーナーは `1000` ではなく `501` になっていました。

vm type に関わらず `docker` の層では `userns-remap` は使われていないので、
そこの可能性はなさそうでした。

そういう状況だったので、どの層で `1000` に変わっているのかわかりませんでした。

## 判明した経緯

`postgres` のコンテナを調査するために `docker compose exec` で `root` 権限で入ったときに、
`postgres` ユーザーがオーナーのはずの `/var/lib/postgresql/data` のオーナーが `root` になっていました。

## 結論

`virtiofs` はファイル毎のオーナーは何も管理していなくて、
アクセスしたユーザーをオーナーとして返しているだけ
(確認用に色々なアクセスをするとキャッシュか何かでずれることがある)
ということがわかりました。

## 動作確認

```bash
docker run --rm -it -v $HOME:/work -u ubuntu ubuntu:24.04 stat /work
```

だとファイルオーナーなどの行は以下の3種類になりました。

```text
Access: (0750/drwxr-x---)  Uid: ( 1000/  ubuntu)   Gid: ( 1000/  ubuntu)
Access: (0750/drwxr-x---)  Uid: (    0/    root)   Gid: (    0/    root)
Access: (0750/drwxr-x---)  Uid: (  501/ UNKNOWN)   Gid: ( 1000/  ubuntu)
```

```bash
docker run --rm -it -v $HOME:/work -u ubuntu ubuntu:24.04 /bin/bash
```

で入ってゆっくり確認すると、ほぼ確実に `ubuntu` になっていました。

```bash
docker run --rm -it -v $HOME:/work -u nobody ubuntu:24.04
```

で確認すると `nobody` になっていました。

## まとめ

`virtiofs` では、
`uid` や `gid` の受け渡しがちゃんとできるはずなので、
macOS 側の `virtiofs` の実装がアクセスしてきた
`uid` や `gid` をファイルのオーナーやグループとして
わざわざ返しているように思いました。

ローカルで色々と試すときには余計なトラブルが減って良さそうですが、
アクセス制限が雑になってしまうという問題もありそうなので、
用途によっては他の mount type を使うなど、
気をつけた方が良さそうです。
