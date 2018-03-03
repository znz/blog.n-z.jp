---
layout: post
title: "R と Ruby によるデータ解析入門　読書会　第1回に参加しました"
date: 2014-04-05 22:55:31 +0900
comments: true
category: blog
tags: event amagasakirb r ruby
---
[4月5日 R と Ruby によるデータ解析入門 読書会 第1回(兵庫県)](http://kokucheese.com/event/index/153995/)
に参加しました。
今回はまえがきから3章まででした。

次回は5月17日だそうです。

<!--more-->

## 会場

いつもの部屋に戻っていました。
今回は参加者が多くて、最終的には10名になっていました。

## メモ

以下今回のメモです。

- 「はじめに」の「カラーテレビを見るとカラーの夢を見る」から白黒テレビの時代は白黒の夢だったのかとか、テレビの普及以前はどうだったのかという話
- p.2 : 「C 言語はブール型を持たない」から C99 だと `_Bool` があるという話
- p.5 : 脚注の magic comment から書き方の流派の話
  - 2.0 からデフォルトエンコーディングは utf-8 になった。
  - 1.9 のデフォルトエンコーディングは us-ascii だった。
- p.13 ループ : `hungry?` と `full?` の中間の状態はないのか
- R で `demo('Japanese')` とか
- shoes の Debian パッケージは wheezy にはあるが sid だとなくなっていた。
- `sd` とかから名前の省略の話
- p.33 gforge のあたりから rubyforge はもうすぐ終了予定の話
  - [Announced today that we're sunsetting RubyForge. Last day will be May 15th. Begin your data migration now!](https://twitter.com/evanphx/status/399552820380053505)
- 1オリジンか0オリジンかとか西暦0年の有無の話とか Oracle と PostgreSQL の非互換の話とか
- p.39 「最も基礎的なデータ構造であるベクトル」からスカラーはないのかという話
- p.40 「二重角括弧は常に 1 つの値を返します」の意味が分かりにくいという話
- このあたりで REPL で毎回付いていた `[1]` はベクトルを表してるっぽいことに気付いた
- p.47 `rbind` は _r_ows bind だった。
  `help(rbind)` で `cbind` と一緒に説明が出てきた。
- p.57 `factor` の使用例 : 年を連続値ではなく離散値として扱うために使っているらしい。
- 3章は翻訳独自の追加の章
  - 更なる前提知識がないとこれでもまだ難しい
  - 8つの魔法とあるが、それぞれの説明の詳しさが違う
- p-value だけとりたい場合とかどうすればいいのかわからない
  - `t.test()` の返り値はオブジェクトっぽいがその属性の取り出し方がわからない
  - `help(t.test)` でいろいろ情報は出てきた
  - `v = t.test(hoge)` だと `v$p.value` とか `v["p.value"]` とかで取り出せた。
- `help` とかの使い方 (調べ方) を説明してほしかったという話
- プログラマ (言語オタク?) 向けには今回の読書会の本よりも
  <a href="http://www.amazon.co.jp/gp/product/4873115795/ref=as_li_ss_tl?ie=UTF8&amp;camp=247&amp;creative=7399&amp;creativeASIN=4873115795&amp;linkCode=as2&amp;tag=znz-22">アート・オブ・Rプログラミング</a>
  がオススメらしい。

<div class="amazon">
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4873116155&linkId=93771f6ce7137b8d3f96f2dd9a88c086" %}
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4873115795&linkId=210cc00a94fb8890251de4eea40c231a" %}
</div>

## 懇親会

花見によさそうな場所がなかったのと、天気が下り坂ということもあり、結局いつものさくら水産での懇親会でした。
