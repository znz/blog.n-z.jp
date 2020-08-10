---
layout: post
title: "GnuPGのsecret keyをexportしてimportした"
date: 2020-08-10 12:30 +0900
comments: true
category: blog
tags: ruby
---
ある環境から別の環境に gnupg の secret key を 1 個だけコピーしたいことがあったので、
export して import してみました。

<!--more-->

## 確認環境

セキュリティ上の理由で細かいバージョンは省略しますが、
どちらも gpg (GnuPG) 2.2 系です。

## export 側

`gpg --list-secret-keys` で鍵 ID を確認します。

例えば以下なら 2 行目の末尾 8 文字の `B4222F7A` や 16 文字や全体が鍵 ID として使えます。

```
sec   rsa4096 2010-06-27 [SC] [有効期限: 2040-08-10]
      B863D6DCC2B957B852386CE0262ED8DBB4222F7A
```

`--export-secret-keys` で export しました。
ここでパスフレーズが要求されます。

クリップボード経由で安全にコピーできる経路ならファイルには書き込まない方が良さそうですが、
tmux の中でコピーしにくかったのでファイルを経由しました。

```
gpg --export-secret-keys --armor --output private-key $keyid
```

コピーし終わったら、 `shred --remove` などで安全に消しておきます。

```
shred --remove private-key
```

## import 側

ssh 経由などの安全な経路でコピーします。

`--allow-secret-key-import` 付きの `--import` で取り込みます。
ここでもパスフレーズが要求されます。

```
gpg --allow-secret-key-import --import private-key
```

こちらでも `shred --remove` などで安全に消しておきます。

## trust

trust db は鍵とは別なので、別途 `--edit-key` の trust で変更します。

```
gpg --edit-key $keyid
```

## 確認

import した鍵を使って、暗号化を解くなどが出来るのを確認します。

## 感想

本来 secret key は ssh なら環境ごとに鍵ペアを作成して公開鍵しか外に出さない、というのが望ましいのですが、
gnupg の鍵は信頼の輪などの都合もあって、そういうわけにもいかなくて難しいです。

secret key のコピーは目的によって、 `.gnupg` を全部コピー、鍵束 (keyring) ファイルをコピー、
鍵だけコピーという方法がありそうですが、今回は特定の鍵だけコピーしたかったので、
export して import をしました。
