---
layout: post
title: "bundleコマンドの衝突回避方法"
date: 2020-05-13 20:00 +0900
comments: true
category: blog
tags: ruby
---
[Golangのbundleコマンド](https://qiita.com/deeeet/items/87aaca2ef9c8ab145877)が
Ruby の `bundler` の `bundle` コマンドと衝突して困る、という話があったのを思い出して、
`bundler` コマンドで実行できれば良いのでは、と試したら実行できました。
というわけで、衝突回避には `bundler` コマンドを使えばいいのではないでしょうか。

<!--more-->

## bundler コマンドの調査

`gem install` するのが `bundler` でコマンドが `bundle` なのが罠っぽいと思っていたのですが、
ブログ記事を書くにあたって、古いバージョンの挙動も確認してみたところ、
`bundler` 1.5 と 1.6 の頃は
`It's recommended to use Bundler through 'bundle' binary instead of 'bundler'`
と警告が出つつ使えていて、
1.7 からは `bin/bundle` と `bin/bundler` が同じ内容になっていたようです。

その後、途中多少違う実装になることがありつつ、最終的に
[Make `bundler` and `bundle` executables have the same functionality](https://github.com/rubygems/bundler/commit/2894378f018af36c9f0682f7032e934b76edc29f)
のコミットで `bundler` コマンドが `bundle` コマンドを `load` するようになって完全に同じになったようです。
