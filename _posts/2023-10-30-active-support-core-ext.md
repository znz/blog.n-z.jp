---
layout: post
title: "Active Support 7.1でactive_support/core_extのrequireが別途必要になっていた"
date: 2023-10-30 09:30 +0900
comments: true
category: blog
tags: ruby
---
`require 'active_support'` していたプログラムで `#present?` を使っていたら、 `NoMethodError` になったので、
`require 'active_support/core_ext'` を足した、という話です。

<!--more-->

## 環境

- <https://github.com/ruby-jp/ruboty-ruby-jp>
- [Bump activesupport from 7.0.8 to 7.1.1](https://github.com/ruby-jp/ruboty-ruby-jp/commit/6c6fb8628c3cb81486252461cc2e8e60799573ec) から問題発生
- [Add active_support/core_ext for `present?`](https://github.com/ruby-jp/ruboty-ruby-jp/commit/54595c25cc8d482e55b21c6ad3eac4e7e6f57618) で修正

## 経緯

[ruby-jp Slack](https://ruby-jp.github.io/) の `#random` で「チャンネル紹介」が止まっているという報告をみかけたので調査開始。

ログをみると以下のように `present?` で `NoMethodError` になっていて、動いていなかった。

```text
1.1.0/lib/ruboty/cron/job.rb:11 run> terminated with exception (report_on_exception is true):
Oct 29 17:00:01 ruboty-ruby-jp app/bot.1 /app/ruboty-channel-gacha.rb:135:in `block in request_params': undefined method `present?' for nil:NilClass (NoMethodError)
```

Active Support の `core_ext` の使い方を[Active Support コア拡張機能 - Railsガイド](https://railsguides.jp/active_support_core_extensions.html)で確認すると、以下のように `require 'active_support'` と `require 'active_support/core_ext'` の両方が必要と書いてあった。

```ruby
require 'active_support'
require 'active_support/core_ext'
```

手元で動作確認。

```console
% ruby -e 'gem "activesupport", "~> 7.0.0"; require "active_support"; p 1.present?'
true
% ruby -e 'gem "activesupport", "~> 7.1.0"; require "active_support"; p 1.present?'
-e:one:in `<main>': undefined method `present?' for 1:Integer (NoMethodError)

gem "activesupport", "~> 7.1.0"; require "active_support"; p 1.present?
                                                              ^^^^^^^^^
% ruby -e 'gem "activesupport", "~> 7.1.0"; require "active_support/core_ext"; p 1.present?'
(略)/activesupport-7.1.0/lib/active_support/core_ext/array/conversions.rb:108:in `<class:Array>': undefined method `deprecator' for ActiveSupport:Module (NoMethodError)

  deprecate to_default_s: :to_s, deprecator: ActiveSupport.deprecator
                                                          ^^^^^^^^^^^
Did you mean?  deprecate_constant
	from (略)/activesupport-7.1.0/lib/active_support/core_ext/array/conversions.rb:8:in `<top (required)>'
	from <internal:(略)/rubygems/core_ext/kernel_require.rb>:96:in `require'
	from <internal:(略)/rubygems/core_ext/kernel_require.rb>:96:in `require'
	from (略)/activesupport-7.1.0/lib/active_support/core_ext/array.rb:5:in `<top (required)>'
	from <internal:(略)/rubygems/core_ext/kernel_require.rb>:148:in `require'
	from <internal:(略)/rubygems/core_ext/kernel_require.rb>:148:in `require'
	from (略)/activesupport-7.1.0/lib/active_support/core_ext.rb:5:in `block in <top (required)>'
	from (略)/activesupport-7.1.0/lib/active_support/core_ext.rb:3:in `each'
	from (略)/activesupport-7.1.0/lib/active_support/core_ext.rb:3:in `<top (required)>'
	from <internal:(略)/rubygems/core_ext/kernel_require.rb>:96:in `require'
	from <internal:(略)/rubygems/core_ext/kernel_require.rb>:96:in `require'
	from -e:1:in `<main>'
% ruby -e 'gem "activesupport", "~> 7.1.0"; require "active_support"; require "active_support/core_ext"; p 1.present?'
true
```

[core_ext の require の追加](https://github.com/ruby-jp/ruboty-ruby-jp/commit/54595c25cc8d482e55b21c6ad3eac4e7e6f57618)を git push して反映を確認。
`#slack_sandbox` チャンネルで動作確認。
明日の cron で表示されれば最終確認。

## 感想

絶対重要な機能というわけでもなくてゆるい運用なので、動いていないのは誰かからの指摘で気付くことも多いのですが、
とりあえずすぐに原因がわかってよかったです。

["Ruby on Rails 7.1 リリースノート - Railsガイド"のActive Support](https://railsguides.jp/v7.1/7_1_release_notes.html#active-support) の変更点をみても書いていないので、
元々 `require "active_support"` で読み込まれる機能は最小限だったのが、
Rails 7.1 で細分化が進んで `core_ext` などは別途 `require` が必要になったのもしれません。

使い方としては Rails ガイドや <https://github.com/rails/rails/issues/49495> などにあるように `core_ext` だけを使うときにも別途 `require "active_support"` が必要なのはそういうもののようです。

`irb` 上などでとりあえず全部読み込めばいいと思ったときは `require "active_support/all"` をしていたので、 `require "active_support"` の範囲は気にしていなかったので、勉強になりました。

## 2023-10-30 11:35 追記

今回の件は[amatsudaさん](https://github.com/amatsuda)に
<https://github.com/rails/rails/commit/0170745b376acd150fec5f8cc57253cc1ffe0cf2>
の変更の副作用だったと教えてもらえました。
「しかし、当然ながら、使いたいものは使う側が明示的にrequireするべきで、今までそれをせずに動いてたのはたまたまだし、今回修正していただいた方針で正しいとは思います。」
とも教えてもらったので、修正自体はこれでよさそうでした。
