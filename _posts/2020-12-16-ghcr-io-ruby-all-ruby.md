---
layout: post
title: "all-rubyがghcr.io/ruby/all-rubyでも使えるようになった"
date: 2020-12-16 22:00 +0900
category: blog
tags: ruby docker
---
全バージョンの ruby の動作を比較するのに便利な [all-ruby](https://github.com/akr/all-ruby) というものがあります。
そのイメージが docker hub だけではなく ghcr.io からも pull できるようになったという話です。
この記事は[Qiita のアドベントカレンダーの記事として投稿したもの](https://qiita.com/znz/items/773b769a9b56c5416175)の転載です。

<!--more-->

## docker hub からのイメージでの実行例

従来はその docker image として docker hub の `rubylang/all-ruby` を使って、以下のように使っていました。(実行例の内容は `require` が不要になったライブラリです。)

```shell-session
$ docker run -it --rm rubylang/all-ruby env ALL_RUBY_SINCE=ruby-2.0 ./all-ruby -e 'p $".reject{|s|s.include?("/")}'
ruby-2.0.0-p0       ["enumerator.so"]
...
ruby-2.0.0-p648     ["enumerator.so"]
ruby-2.1.0-preview1 ["enumerator.so", "thread.rb"]
...
ruby-2.1.10         ["enumerator.so", "thread.rb"]
ruby-2.2.0-preview1 ["enumerator.so", "rational.so", "complex.so", "thread.rb"]
...
ruby-2.2.10         ["enumerator.so", "rational.so", "complex.so", "thread.rb"]
ruby-2.3.0-preview1 ["enumerator.so", "thread.rb", "rational.so", "complex.so"]
...
ruby-2.7.0-preview2 ["enumerator.so", "thread.rb", "rational.so", "complex.so"]
ruby-2.7.0-preview3 ["enumerator.so", "thread.rb", "rational.so", "complex.so", "ruby2_keywords.rb"]
...
ruby-3.0.0-preview1 ["enumerator.so", "thread.rb", "rational.so", "complex.so", "ruby2_keywords.rb"]
```

## ghcr.io からのイメージでの実行例

今年から docker hub の制限が厳しくなった影響を受けて、 GitHub Container Registry(ghcr.io) にも `docker push` されるようになり、 [ghcr.io/ruby/all-ruby](https://ghcr.io/ruby/all-ruby) でも使えるようになりました。

上の実行例は 3.0.0-preview1 のリリース前に `docker pull` したものだったので、 preview1 までになっていますが、以下の実行例は 3.0.0-preview2 以降で初めて実行した時の出力です。

```shell-session
$ docker run -it --rm ghcr.io/ruby/all-ruby env ALL_RUBY_SINCE=ruby-2.0 ./all-ruby -e 'p $".reject{|s|s.include?("/")}'
Unable to find image 'ghcr.io/ruby/all-ruby:latest' locally
latest: Pulling from ruby/all-ruby
852e50cd189d: Pull complete
3d2287ec382d: Pull complete
8532674f7cc9: Pull complete
c2b6a97405ca: Pull complete
Digest: sha256:8c48ad2185525c7a8b5c19fe31f286971b64b7dd41a06be7bee0bd6ba8646943
Status: Downloaded newer image for ghcr.io/ruby/all-ruby:latest
ruby-2.0.0-p0       ["enumerator.so"]
...
ruby-2.0.0-p648     ["enumerator.so"]
ruby-2.1.0-preview1 ["enumerator.so", "thread.rb"]
...
ruby-2.1.10         ["enumerator.so", "thread.rb"]
ruby-2.2.0-preview1 ["enumerator.so", "rational.so", "complex.so", "thread.rb"]
...
ruby-2.2.10         ["enumerator.so", "rational.so", "complex.so", "thread.rb"]
ruby-2.3.0-preview1 ["enumerator.so", "thread.rb", "rational.so", "complex.so"]
...
ruby-2.7.0-preview2 ["enumerator.so", "thread.rb", "rational.so", "complex.so"]
ruby-2.7.0-preview3 ["enumerator.so", "thread.rb", "rational.so", "complex.so", "ruby2_keywords.rb"]
...
ruby-3.0.0-preview2 ["enumerator.so", "thread.rb", "rational.so", "complex.so", "ruby2_keywords.rb"]
```

## まとめ

docker hub は `docker pull` の制限も厳しくなってしまったので、これからは `ghcr.io` からも `docker pull` できるということを知っておくと便利です。

## 余談

余談ですが、<https://hub.docker.com/r/rubylang/ruby> も `ghcr.io/ruby/ruby` で使えるようになる予定のようです。こちらを実際に使うのは公式なアナウンスをお待ちください。
