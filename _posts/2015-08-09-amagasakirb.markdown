---
layout: post
title: "8月9日 アンダースタンディングコンピュテーション読書会 第4回(兵庫県)に参加しました"
date: 2015-08-09 13:02:58 +0900
comments: true
category: blog
tags: event amagasakirb ruby
---
[8月9日 アンダースタンディングコンピュテーション読書会 第4回(兵庫県)](http://kokucheese.com/event/index/322444/ "8月9日 アンダースタンディングコンピュテーション読書会 第4回(兵庫県)")
に参加しました。
今回は8章から9章でした。

<!--more-->

## メモ

<div class="amazon pull-right">
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=487311697X&linkId=24668ad132994a64359b48ade66a6964" %}
</div>

以下、今回のメモです。

- <https://github.com/tomstuart/computationbook>
- <https://github.com/ko1/uc_ja>
- p.259 `to_s(2).scan(/.+?(?=.{8}*\z)/)` の書き換えの話
- `reserve` して `each_slice(8)` はどうかという話
- `Kernel#Integer` を使うかどうかという話
- 正規表現の先読みの話 `gsub(/(?=(.{3})+\z)/, ',')` など
- `does_it_say_no.rb` の話
- p.264 監訳注の `"no"` と言って停止というのは環境 (スタックの深さ) に依存して `"yes"` になることもある <https://github.com/ko1/uc_ja/issues/7>
- Quine から `HQ9+` の話 <https://ja.wikipedia.org/wiki/HQ9%2B>
- p.276 `Prime.each(n - 1)` の話
- p.296 `Array#product` の話 <http://docs.ruby-lang.org/ja/2.2.0/method/Array/i/product.html>
- p.299 `T``Type::BOOLEAN` の `T` が余分? <https://github.com/ko1/uc_ja/issues/8>
- 8章は時間がかかったが9章はすんなり読めた話
- 多重代入と `to_ary` と `to_a` などの話
- SlideShare と SpeakerDeck の違いの話
- `-Float::INFINITY` の話

## 次回の本の候補

- [Rubyのしくみ -Ruby Under a Microscope-](http://amzn.to/2oNiE0A)
- [Effective Ruby](http://amzn.to/2Fl7b2E)
- [10年戦えるデータ分析入門 SQLを武器にデータ活用時代を生き抜く (Informatics &amp;IDEA)](http://amzn.to/2oOm8j9)
- [ユーザーストーリーマッピング](http://amzn.to/2oNiMx6)
- [データ解析の実務プロセス入門](http://amzn.to/2FPS13c)
- [Pro Git 日本語版電子書籍公開サイト](https://progit-ja.github.io/ "Pro Git 日本語版電子書籍公開サイト")
- [Ruby on Rails ガイド (4.2 対応)](http://railsguides.jp/index.html "Ruby on Rails ガイド (4.2 対応)")
- [実践 機械学習システム](http://amzn.to/2oOLDRv)
- [ソフトウェアシステムアーキテクチャ構築の原理 第2版 ITアーキテクトの決断を支えるアーキテクチャ思考法](http://amzn.to/2CWOfSt)
- [システムテスト自動化 標準ガイド (CodeZine BOOKS)](http://amzn.to/2oO4Q5Y)
- [型システム入門 −プログラミング言語と型の理論−](http://amzn.to/2FP1zeI)

## 次回予定

<div class="amazon pull-right">
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4274069117&linkId=1c49dccda282a86fd35a94cbeb41ab81" %}
</div>

次回の本は
[型システム入門 −プログラミング言語と型の理論−](http://amzn.to/2FP1zeI)
に決定しました。
次回は10月の予定で詳細は未定です。
