---
layout: post
title: "鹿児島Ruby会議01に参加して発表してきました"
date: 2019-11-30 23:59 +0900
comments: true
category: blog
tags: ruby event
---
[鹿児島Ruby会議01](https://k-ruby.github.io/kagoshima-rubykaigi01/)に参加して発表してきました。

<!--more-->

以下メモです。

## 初鹿児島

九州は
中学校の修学旅行で長崎 (原爆関連) や阿蘇山 (天気が悪くて登れず) とか、
RubyKaigi 2019 で福岡とかしか行ったことがなかったので、
鹿児島県は初めて行きました。

## オープニング

- 鹿児島は日常的に灰が降るらしい
- 懇親会で 1~2分の Super Lightning Talks があるらしい
- Karaimo Ruby Community
- カライモ = サツマイモ
- 2011年から

## Ruby 3 の型解析に向けた計画（仮）

- 1ページで
- 型記述言語、型推論、型検査
- <https://github.com/mame/ruby-type-profiler>

- マニアックな Ruby 2.7 新機能紹介

- "Ruby core team"
- アクティブな開発者たちを漠然と指す謎ワード
- Ruby 界隈では開発者を「コミッタ」と呼ぶ

- 最近のコミット数グラフ

- 次は Ruby 2.7
- 議論は bugs.ruby-lang.org
- 議論促進のため開発者会議を毎月やっている

- パターンマッチ
- 何が嬉しいの?
- 短くてわかりやすい例が難しい
- 「記号処理」向きの言語機能
- Ruby で記号処理をすることはあまりない
- ポジティブに言えば Ruby の適用範囲が増える

- 記号処理とは
- 数値ではなく記号を扱う処理
- 具体的には言語処理系とか数式処理

- SKI コンビネータ計算
- あるルールで木を繰り返し簡単にしていく遊び

- パターンにマッチさせるプログラムを書くときにパターンマッチはとても便利です

- キーワード引数の分離
- 2.7 は 3.0 の非互換のための準備期間

- `foo(x: 43)` と `foo({x: 43})` が同じ意味
- 直感に反するというバグ報告に対応していった結果、複雑な挙動に
- `foo({}, **{})` → `foo({})`
- 3.0 では `foo(x: 43)` と `foo({x: 43})` を別物に
- 意図的に混同していたコードが動かない
  - `foo(x: 43)` + `def foo(opt={})` は 3.0 でも許すことに
  - `h = {x: 43}; foo(h)` + `def foo(x: 42)` は許さない
  - `foo(**h)` に書き直してね
- Ruby 2.7 は移行支援バージョン
- 変わる挙動に警告を出す
- www.ruby-lang.org に移行ガイド予定

- 委譲の新記法: `(...)`
- `bar ...` は endless range になる
- 行末だと警告

- numbered parameter
- 背景
- `ary.map(&:to_s)`
- ちょっと複雑になった時も対応できるように
- 入れ子とかでは使えなくしている

- 令和対応 (2.6.3 から)
- `Date#jisx0301`
- `"\u{32FF}".unicode_normalize(:nfkd)`

- 入らない機能 : pipeline operator (`|>`)
- 本来の目的: 非オブジェクト指向言語でメソッドチェーンっぽく書くためのハックだった
- 誤解: x を foo(1) の第1引数にする構文と思う人多数
- 狙っていたこと
- Range#each のカッコを省略したかった
- メソッドチェーンにコメントを書きたかった
- 2.7 ではここにコメントを書けるようになった

```ruby
  x
  # foo
    .foo 1
```

- 入らない機能: メソッド取り出し演算子 `.:`
- LISP-1 と LISP-2
- Python (LISP-1)
- Ruby (LISP-2)
- ユースケース
- 「関数型プログラミング?」の用途には不完全

- 他にも色々入ります

## bruby

- bash がスペースの扱いが厳しかったりして記述力が低いと感じた
- bash と ruby を相互変換
- 2週間で言語を作るのは難しい

## ruby-jp

- ruby-jp slack 入ってください
- 色々な情報が集まってます
- 色々な知見も
- gsub! と gsub の話とか
- ruby と関係のない話もたくさん

- 今回のテーマ: 越境 → ruby-jp は組織の境を超えている
- 大企業の人がたくさんいる Slack で盛り上がる感じをどんな組織の人も味わえる
- 一番重要なのは *人*

## ruby-vipsを利用した画像処理Tips

- libvips
- 処理速度が速くてメモリ消費量も少ない
- brew install vips でオプションをつけるといろんな機能ありに
- Ubuntu/Debian なら apt で
- gem install ruby-vips
- Rails なら image_processing gem 経由で使える
- 白黒画像への変換
- リサイズ
- kakari というサービスで使っている
- 処方箋のFAXを2値化して読みやすく

- 質疑応答
- imagemagick は pdf からの変換が遅い
- vips は速い
- alpha があると真っ黒になるなどパラメータが大変
- imagemagick で指定していたものを vips でも指定する必要がありそう
- 画像生成もできる?
- 可能

## コーヒーブレイク

- docs で問題が起きていたので調査していました

## Haconiwaが越えたあの夏〜3年間を振り返る

- コンテナの構成要素を知って ruby で書きたくなったのが始まり
- mruby を使った
- FastContainer
- CRIU

- mruby を選んだのは unshare などの都合

## RubyのOSSコードリーディング(仮題)

- 質疑応答
- メタプログラミングを使っているものは難しかった
- mame: 読んでいくときについでにテストを書いていくと貢献もできて良い

## 福岡の方から参りました Fukuoka.rb です

- fukuoka.rb で何をやっていたかという話

## かごっま弁のDeep LearningをRubyできばっ

- Ruby で Deep Learning 入門
- Chainer Tutorial がオススメ

## How to make a gem with Rust

- Ruby/Rails 7年
- Rust 3ヶ月

- メインは Rails、一部に Rust を使いたい
- malept/thermite
- テルミット法

- ruby_sys, ruru

- sinsoku/wasabi
- rust がサビだから
- sinsoku/rusty_rails

- Value を触っていると ruby 本体へのコントリビュートチャンスがあるかも

## あまり知られていないRubyの便利機能

時間があれば gem-codesearch などを使って客観的に調べようかと思っていたのですが、
時間がなかったので、色々なところで見かけたり見かけなかったりするものから、主観で選んで紹介してみました。

{% include slides.html author="znz" slide="kagoshima-rubykaigi01" title="あまり知られていないRubyの便利機能" slideshare="znzjp/ruby-199958323" speakerdeck="znz/amarizhi-rareteinairubyfalsebian-li-ji-neng" github="znz/kagoshima-rubykaigi01" %}

## "regional” wasn’t going to mean “provincial”

- 今年は地域Ruby会議が8回で多かった
- http://regional.rubykaigi.org/
  - “regional” wasn’t going to mean “provincial”—that regional conferences could be top-notch events—and that hope has been fulfilled beyond what we could possibly have wished for.
  ― ― D.A.Black
- The Well-Grounded Rubyist
- "ある地域でやる" は "田舎でやってるやつ" ではない

## Rubyで作るネット回線の自動速度測定ツール

- 20分だと思っていたので資料が多め

- 光が遅い?
- speedtest.net
- 速度計測するときに速い http ライブラリは?
- ベンチマーク
- curb 採用
- speedtest_net gem

- 8分で終わった。

## Location-based API with Ruby

- Pikamon API overview
- Multiple databases on Rails 6
- Geolocation using PostGIS

- nearby のデフォルトは 5m
- ApplicationRecord と PikamonRecord で connect_to
- PostGIS
- ラスター画像も扱える
- Raster rendering

- PostGIS は Open Street Map などで使われている
- t.st_point
- ST_DWithin
- ST_Distance

- Q&A
- guides.rubyonrails.org/active_record_multiple_databases.html
- postgis.net
- EPSG 4326
- djGrill/pikamon-api
- 'la' * 18 + '.com'

- 情報はどこで?
- stackoverflow, 日本語なら qiita.com
- 英語 locale で使えば Google の検索結果も英語で出てくる

## Rails Girlsのお話や、初めての方向けのコミュニティについてなどお話

- Affirmative Action http://railsgirls.jp/affirmative-action
- emori.house

- 質疑応答
- Rails Girls が活発な地域は?
- Tokyo, Kyoto
- 南九州や東北が弱い

## closing

- 参加者: 60名 (当日参加を含む)
- 発表者: 15名
- スタッフ: 12名

- 集合写真を撮影して懇親会へ
