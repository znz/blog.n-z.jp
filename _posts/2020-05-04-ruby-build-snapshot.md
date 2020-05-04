---
layout: post
title: "snapshot tarball や ractor ブランチを rbenv install できるようにするプラグインを作った"
date: 2020-05-04 23:50 +0900
comments: true
category: blog
tags: ruby
---
[Rubyのダウンロード](https://www.ruby-lang.org/ja/downloads/)にはリリースされたアーカイブの他に毎日作成している snapshot tarball があって、
`rbenv install 2.8.0-dev` のような `git` からのインストールだと `ruby` コマンドが必要なので、
`ruby` コマンドがない環境や `autoconf` などがない環境で開発版の `ruby` を試したい時などに便利です。
それを `rbenv install` でインストールできるようにするプラグイン
[ruby-build-snapshot](https://github.com/znz/ruby-build-snapshot)
を作りました。

<!--more-->

## 動作確認環境

- [現在の最新の rbenv](https://github.com/rbenv/rbenv/tree/c879cb0f2fb2b01c6ee73cdfb25c90d139febda9)
- [現在の最新の ruby-build](https://github.com/rbenv/ruby-build/tree/3ef704e7adb6cd71dc0d9b755ebfd7a06865b36a)
- [現在の最新の ruby-build-snapshot](https://github.com/znz/ruby-build-snapshot/tree/7fdc4a1b008efcdefa4e2851dbf56abeda96b35f)

## インストール

[rbenv/rbenv](https://github.com/rbenv/rbenv) を参考にして `rbenv` をインストールしておきます。

プラグインとして `ruby-build` に加えて `ruby-build-snapshot` をインストールします。

```console
$ mkdir -p "$(rbenv root)"/plugins
$ git clone --depth=1 https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
$ git clone --depth=1 https://github.com/znz/ruby-build-snapshot.git "$(rbenv root)"/plugins/ruby-build-snapshot
```

## 使い方

`ruby-build` に同梱されている `definitions` でインストールできるバージョンに加えて
`ruby-build-snapshot` の `definitions` で定義されているバージョンがインストールできるようになるので、
`rbenv install snapshot-master` や `rbenv install snapshot-ruby_2_7` のようにインストールできます。

snapshot tarball なので、インストールに失敗する可能性がありますが、
その場合は [ruby/actions](https://github.com/ruby/actions) の GitHub Actions のログを確認して
そもそも tarball がちゃんと出来ていないようなら、別の日に試してください。
ちゃんと出来ているようなのにうまく動かないようならバグ報告してもらえると直せるかもしれません。

```console
$ rbenv install --list | grep snapshot
snapshot-master
snapshot-ruby_2_5
snapshot-ruby_2_6
snapshot-ruby_2_7
$ rbenv install snapshot-master
$ rbenv install snapshot-ruby_2_7
```

## 実験的ブランチ対応

[Ruby3 さみっと online](https://rhc.connpass.com/event/169873/) で
Guild から Ractor (Reactor ではない) に名前が変わって、
説明は
<https://github.com/ko1/ruby/blob/ractor/ractor.ja.md>
にあります。

ブランチからビルドするのは多少面倒なので、
これも
`RUBY_CONFIGURE_OPTS=CFLAGS=-Wno-error=shorten-64-to-32 rbenv install ractor`
でインストールできるようにしました。
`ractor` を試した記事を検索すると情報が出てくるように、
今のところ `CFLAGS` の指定をしないとビルドが失敗するようです。

試すには、自分でビルドしなくても
[wakaba260/ruby-ractor-dev](https://hub.docker.com/r/wakaba260/ruby-ractor-dev)
という docker イメージを使うという手もあります。

## ruby-build as a standalone program

ここからはおまけの `ruby-build` 自体の話です。

`Dockerfile` などで単一のバージョンの `ruby` を入れるのに `rbenv` + `ruby-build` を使っているのを見かけることがありますが、
わざわざ別々になっていることからわかるように、複数バージョンの切り替えが不要なら `rbenv` なしで `ruby-build` だけを使えば良いです。

実際の `ruby-build` だけでの使い方は
[rbenv/ruby-build](https://github.com/rbenv/ruby-build) で「As a standalone program」と
書いてある方の説明を参考にしてください。

[ruby-build-snapshot](https://github.com/znz/ruby-build-snapshot)
も README には standalone の `ruby-build` と組み合わせる方法を書いてあります。

## ruby-build の definitions 追加方法

[rbenv-installの32行目](https://github.com/rbenv/ruby-build/blob/3ef704e7adb6cd71dc0d9b755ebfd7a06865b36a/bin/rbenv-install#L32)あたりをみると、
`rbenv` のプラグインとして `"$RBENV_ROOT"/plugins/*/share/ruby-build` があれば追加の `definitions` として使ってくれるようだったので、
そのように作りました。

standalone の時は環境変数 `RUBY_BUILD_DEFINITIONS` でパスを指定するのですが、
`rbenv` プラグインとしての自動認識と実装を共有する都合で、
`export RUBY_BUILD_DEFINITIONS=/path/to/ruby-build-snapshot/share/ruby-build`
のように `share/ruby-build` までつける必要がありました。

## definitions の更新

`ruby-build` の `share/ruby-build/2.8.0-dev` などを元にしているので、
`openssl` のバージョンの更新などに追随して更新する必要があるので、
[update.rb](https://github.com/znz/ruby-build-snapshot/blob/7fdc4a1b008efcdefa4e2851dbf56abeda96b35f/update.rb)
というスクリプトを作って `definitions` を生成しています。

これを GitHub Actions の on schedule で実行すれば、
自動的に追随できる予定です。
