---
layout: post
title: "5月9日 アンダースタンディング コンピュテーション読書会　第３回(兵庫県)に参加しました"
date: 2015-05-09 13:08:12 +0900
comments: true
category: blog
tags: event amagasakirb ruby
---
[5月9日 アンダースタンディング コンピュテーション読書会　第３回(兵庫県)](http://kokucheese.com/event/index/287707/ "5月9日 アンダースタンディング コンピュテーション読書会　第３回(兵庫県)")
に参加しました。
今回はいつもの会場に戻って5章から7章でした。

<!--more-->

## メモ

<div class="amazon pull-right">
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=487311697X&linkId=24668ad132994a64359b48ade66a6964" %}
</div>

以下、今回のメモです。

- <https://github.com/tomstuart/computationbook>
- <https://github.com/ko1/uc_ja>
- p.135 `「コンピュータ」という言葉は「計算する人」(通常は女性)を意味していました。`
- アラン・チューリングの論文名の最後の単語の Entscheidungsproblem の読み方がわからないという話
- ドイツ語由来の英単語らしいという話
- the Entscheidungsproblem でヒルベルトの決定問題を意味する単語ではないかという話
- p.143 の `left[0..-2]` の `[0..-2]` がわかりにくい話
- 頭から削る `drop` はあるのに逆に末尾から削るメソッドがない話
- 頭から削るメソッドだけなのは `Enumerable` 由来のメソッドだからではないかという話
- cuzic さんが `Enumerator.new` を最近よく使うという話
- アラン・チューリングはチューリングマシンの実装については考えていなくて計算可能性などの数学的なことを重視していたという話
- `proc#[]` と `proc#call` が同じという話
- `x[]` のように引数なしの `call` でも `[]` で書けるという話
- p.168 ローカル変数名 (引数) に `proc` という名前を使っているのはグローバル関数の `proc` と紛らわしいので良くないという話
- ラムダ計算の話
- 最小構成要素を少なくしたかったという話
- YコンビネータとかZコンビネータとかIコンビネータとかの話
- SKK=I の話 (p.224に出てくる)
- p.194 `Enumerator::Lazy#force` の話
- `take` はまだ lazy のままで `first` は lazy ではなくなるという話
- 6章には [README.md](https://github.com/tomstuart/computationbook/tree/master/programming_with_nothing "README.md") から [解説ビデオ](http://rubymanor.org/3/videos/programming_with_nothing/ "解説ビデオ") へのリンクがある
- p.238 `Array#cycle`
- 次回は8月予定で具体的な日程は未定
