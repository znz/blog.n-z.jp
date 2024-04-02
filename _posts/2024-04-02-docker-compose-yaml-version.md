---
layout: post
title: "docker-compose.yamlのversionがobsoleteという警告がでるようになったので、不要になっていたのはいつからか調べた"
date: 2024-04-02 18:15 +0900
comments: true
category: blog
tags: docker
---
docker compose が最近のバージョンで `'version' is obsolete` という警告がでるようになったので、
警告にしたがって単純に削除する前に、いつから意味がないものになっていたのかを調べました。

<!--more-->

## 警告でみつかる情報

警告メッセージで検索すると
[``[BUG] `'version' is obsolete` · Issue #11628 · docker/compose``](https://github.com/docker/compose/issues/11628)
がでてきて、
メッセージ通り今は不要だということがわかります。
しかし、いつから不要だったのかはこの issue からわからなかったので、
さらに調べてみました。

## docker compose file format のバージョン

<https://docs.docker.com/compose/compose-file/compose-versioning/#compatibility-matrix> によると compose file format のバージョンは 3.8 まで上がっていましたが、
Docker Engine 19.03.0 から Compose specification にも対応していることがわかります。

Compose specification での version 指定は、
<https://docs.docker.com/compose/compose-file/04-version-and-name/> によると
後方互換性のための informative だけのものだったようです。

<!--
Version top-level element (optional)
The top-level version property is defined by the Compose Specification for backward compatibility. It is only informative.
-->

つまり、2019 年の 19.03.0 から version 指定は不要 (optional) だったということで、
今となってはそれより古いバージョンはほぼ使っていなさそうなので、
無条件に消してよさそうだと思いました。

もっと古いバージョンについては <https://docs.docker.com/compose/intro/history/> に

* Compose file format 1 with Compose 1.0.0 in 2014
* Compose file format 2.x with Compose 1.6.0 in 2016
* Compose file format 3.x with Compose 1.10.0 in 2017

とあって、その後 Swarm mode などとの関係で混乱していた 2.x と 3.x は Compose Specification にマージされたという歴史のようです。

## まとめ

docker compose ファイルの `version` 指定は 2019 年から使われている Compose specification で
`Version top-level element (optional)`
となっていて、すでに不要な状態が何年も続いているので、単純に消してしまって良さそうです。
