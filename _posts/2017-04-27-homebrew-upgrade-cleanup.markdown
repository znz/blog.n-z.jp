---
layout: post
title: "homebrewの更新はbrew upgrade --cleanupだけでよくなっている"
date: 2017-04-27 20:00:48 +0900
comments: true
category: blog
tags: homebrew osx
---
Homebrew のパッケージの更新に昔は `brew update`; `brew upgrade`; `brew cleanup` と 3 コマンドを使っていましたが、今は `brew upgrade --cleanup` だけでよくなっています。

<!--more-->

## 2018-01-18 追記

Homebrew 2.0.0 から `brew cleanup` の自動実行がデフォルトになる予定らしく、
[Homebrew 1.9.0](https://brew.sh/2019/01/09/homebrew-1.9.0/) から

```
Warning: Calling 'brew upgrade --cleanup' is deprecated! Use 'HOMEBREW_INSTALL_CLEANUP' instead.
```

というメッセージが出るようになっているので、メッセージが不要なら代わりに

```
env HOMEBREW_INSTALL_CLEANUP=1 brew upgrade
```

と実行するとか、シェルの設定ファイルに

```
export HOMEBREW_INSTALL_CLEANUP=1
```

などと設定すると良いでしょう。

## 確認バージョン

- Homebrew 1.1.13

## brew update

Debian 系で使われている `apt` の `sudo apt-get update` に相当するパッケージ情報を更新するサブコマンドです。
基本的には `git` で更新しているだけなので、こけたら `git` コマンドを直接使ってなおす必要がありそうです。

今は他のサブコマンドを実行した時に情報が古ければ自動で更新されるので不要になっています。

## brew upgrade

パッケージを更新するサブコマンドです。

古いバージョンも残るので、 `gem update` に近いような気がします。

## brew cleanup

古いバージョンを消したり、ダウンロードしたファイルのキャッシュを消したりします。

`brew upgrade --cleanup` のように `upgrade` サブコマンドに `--cleanup` オプションをつけると `upgrade` 中に削除してくれるようです。
(例えば 2 個更新があった時に、更新、削除、更新、削除になる。)

後から `brew cleanup` するのと違って `upgrade` 中に削除してくれるので、何が削除されたのかの確認はしにくくなったり、問題が起きた時に戻しにくくなったりという欠点はありますが、一時的に空き容量が減るのが緩やかになったり、消し忘れがなくなるなどの利点があると思います。

## まとめ

`brew update`; `brew upgrade`; `brew cleanup` と 3 コマンドを連続で使っている人は、 `brew upgrade --cleanup` だけに置き換えると便利です。
