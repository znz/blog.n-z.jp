---
layout: post
title: "docker-credential-helperでdocker/config.jsonから認証情報をなくす"
date: 2026-03-28 13:00 +0900
comments: true
category: blog
tags: docker macos pass
---
デフォルトだと `docker login` すると `~/.docker/config.json` に認証情報が保存されて、
あまり望ましくない状態なので、
`docker-credential-helper` で `keychain` や `pass` に保存する方法を確認しました。

<!--more-->

## 事前準備

`docker-credential-osxkeychain` や `docker-credential-pass` は `brew install docker-credential-helper` でインストールしました。

[`pass`](https://www.passwordstore.org/) を使うならあらかじめ設定しておきます。

[docker-credential-helpers の Releases](https://github.com/docker/docker-credential-helpers/releases) をみると、
Linux の secretservice と Windows の wincred にも対応しているようです。

## 設定

`~/.docker/config.json` (か場所を変更しているなら `${DOCKER_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/docker}/config.json`)
に

```json
{
  "credsStore": "osxkeychain"
}
```

や

```json
{
  "credsStore": "pass"
}
```

のように設定しておきます。

既存の設定があるなら、
`cat $DOCKER_CONFIG/config.json | jq '.["credsStore"]="pass"'`
のように `jq` で書き換えた内容を書き込んでも良いと思います。

[amazon-ecr-credential-helper](https://github.com/awslabs/amazon-ecr-credential-helper) もあるようで、
server ごとに別の credential helper を使いたい場合は `credsStore` の他に `credHelpers` という設定があるようです。

## ログインしなおし

`docker login -u username -p password server` でログインしなおすと `docker/config.json` の `auths` の値が空になって、
`pass` の場合は `docker-credential-helpers/$(server を base64 した文字列)/username` の中に `password` が入っていました。

## まとめ

昔から悪意のあるプログラムを実行してしまうと平文の機密情報は漏洩する危険がありましたが、
AI 時代で平文の機密情報の危険性が増しているので、出来るだけ平文で保存しないように移行している一部として、
Docker の認証情報を移行しました。

Docker の場合は既存の credential helpers があって簡単に移行できました。

他のものについても引き続き調査中です。
