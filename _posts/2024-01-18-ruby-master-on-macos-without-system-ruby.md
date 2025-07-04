---
layout: post
title: "rubyのmasterがmacOSのsystem rubyに非対応になった"
date: 2024-01-18 15:10 +0900
comments: true
category: blog
tags: ruby macos
---
[ruby master の BASERUBY が 2.7 以上を要求するようになった](https://github.com/ruby/ruby/commit/b4ed5b7dfe9ca01ef48922d1b2c154767b7e4e86)ので、
リリースされていない ruby master を macOS で自前でビルドしている人は対処が必要な場合があります。

<!--more-->

## 動作確認環境

- macOS Sonoma 14.2.1
- Homebrew 4.2.4-38-g939edb0

## 短いまとめ

`configure` に `--with-baseruby=/opt/homebrew/Library/Homebrew/vendor/portable-ruby/current/bin/ruby` をつけるか、
他の方法で入れた `ruby` を使えば良いです。

## BASERUBY の更新

`git clone` などでソースをとってきた状態だと、リリース tarball には含まれている `configure` などが入っていなくて、
いくつかのファイルは `ruby` コマンドを使って生成されています。
そのときに使う `ruby` コマンドが `BASERUBY` でその最低要求バージョンが 2.5 から 2.7 になりました。

## macOS での影響

macOS では ruby や python などの処理系をシステム側から外していく方針のようで、
依存関係の関係でまだ外せていないものは古いまま残っています。
そのため、 `ruby` は 2.6 で止まっています。

```
% /usr/bin/ruby -v
ruby 2.6.10p210 (2022-04-12 revision 67958) [universal.arm64e-darwin23]
```

そこで他の `ruby` 処理系を `BASERUBY` として使う必要があります。

## Homebrew の portable-ruby を使う

Homebrew の中で `portable-ruby` の実行ファイルっぽいものを探したところ、
`/opt/homebrew/Library/Homebrew/vendor/portable-ruby/3.1.4/bin/ruby`
がみつかったので、
これを `configure` の引数に `--with-baseruby=/opt/homebrew/Library/Homebrew/vendor/portable-ruby/3.1.4/bin/ruby` と指定して使うことにしました。

```
% find /opt/homebrew -name ruby -type f
/opt/homebrew/Library/Homebrew/shims/mac/super/ruby
/opt/homebrew/Library/Homebrew/vendor/portable-ruby/3.1.4/bin/ruby
```

`portable-ruby` のバージョンが変わったら、また指定しなおしが必要になりますが、そういうときはちゃんと影響があるか知りたいので、
(`--with-baseruby=$(echo /opt/homebrew/Library/Homebrew/vendor/portable-ruby/*.*/bin/ruby)` のようにするのではなく) フルパスを明示的に使うようにしました。

`echo` しようとしてみつけたのですが、常に現在のバージョンを使うなら、
`/opt/homebrew/Library/Homebrew/vendor/portable-ruby/current/bin/ruby`
があるようなので、
`--with-baseruby=/opt/homebrew/Library/Homebrew/vendor/portable-ruby/current/bin/ruby`
でも良さそうです。

## 別案

リリースされた ruby のビルドには `BASERUBY` は不要なので、
あらかじめ `rbenv install 3.1.4` しておいてそちらを使うとか、
`brew install ruby` とか `brew install ruby@3.2` とかで入れた `ruby` を使うとか、
色々な方法がありそうです。

## まとめ

`--with-openssl-dir=/opt/homebrew/opt/openssl@3` で指定している `openssl` のインストールなどで、
手元の macOS 環境には必ず Homebrew が入っているので、
その `portable-ruby` も必ず入っているはずということで、
system ruby (`/usr/bin/ruby`) の代わりに使うようにしました。

Ubuntu は focal (20.04 LTS) でも ruby 2.7 なので、影響はなさそうでした。

Debian は bullseye (oldstable) が ruby 2.7 で buster (oldoldstable) が ruby 2.5 なので、
あまりなさそうですが、
buster 環境で ruby の master を試そうとすると対処が必要そうです。
