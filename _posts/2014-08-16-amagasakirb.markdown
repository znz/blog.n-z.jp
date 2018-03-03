---
layout: post
title: "R と Ruby によるデータ解析入門　読書会　第3回に参加しました"
date: 2014-08-16 13:05:27 +0900
comments: true
category: blog
tags: event amagasakirb r ruby
---
[8月16日 R と Ruby によるデータ解析入門　読書会　第3回(兵庫県)](http://kokucheese.com/event/index/202642/ "8月16日 R と Ruby によるデータ解析入門　読書会　第3回(兵庫県)")
に参加しました。
今回は7章から最後まででした。

次回は9月27日(土)です。

<!--more-->

## メモ

以下今回のメモです。

- Mac の Spotlight 便利
- Windows 7 などの検索も便利
- WAV ファイルはリトルエンディアンとビッグエンディアンが混在
  - ビッグエンディアンの部分は文字列でリトルエンディアンのところは数値というだけに見える
- <https://github.com/setoyama60jp/everyday> に書籍中のソースコード
- p.196 泊数 → 拍数 ?
- p.198 GraphicsMagic → GraphicsMagick ?
- RMagic → RMagick ?
- Boid の 3 つのルールを知っていた or 知らなかった
- 8 章は R が出てこなかった
- p.218 case の when のところにせめてインデントがほしい
- いろいろとコーディングスタイルに突っ込みが入っていた
- 寿命は一定ではなく死ぬ確率があがっていくようにした方が良いのではないか

<div class="amazon">
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4873116155&linkId=01dd9ddb8bf0a8c870725ff3f395943e" %}
</div>

## 次回の本候補

<div class="amazon">
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4797380357&linkId=993ec1f2f43f0d1c9b0cb8252a7d05f6" %}
</div>

可能性がありそうなものからなさそうなものまで、いろいろと候補が挙がりましたが、「Rubyによるクローラー開発技法」に決まりました。

- [Rubyによるクローラー開発技法](http://amzn.to/2tgCy9E)
- [ハイパフォーマンス ブラウザネットワーキング ―ネットワークアプリケーションのためのパフォーマンス最適化](http://amzn.to/2CW10wN)は cuzic さんが既読ということで候補から外れました。
- [フルスクラッチから1日でCMSを作る シェルスクリプト高速開発手法入門](http://amzn.to/2tbQ7al)
- [Haskellによる並列・並行プログラミング](http://amzn.to/2thXbSY) は Haskell をそんなにわかっている人がいないということで候補から外れました。
- [新装版 リファクタリング―既存のコードを安全に改善する― (OBJECT TECHNOLOGY SERIES)](http://amzn.to/2FPlRoe) は流れで出てきただけだったのか、最終候補には残りませんでした。
- [すごいErlangゆかいに学ぼう!](http://amzn.to/2tdiF3h) も Erlang だからという理由で候補から外れました。
- [アルゴリズムパズル ―プログラマのための数学パズル入門](http://amzn.to/2CUorq9)や[プログラマのためのコードパズル ~JavaScriptで挑むコードゴルフとアルゴリズム](http://amzn.to/2FOyCzz)は予習が必要そうということで候補から外れました。
- [JavaScriptで学ぶ関数型プログラミング](http://amzn.to/2FSG2C5)も流れで出てきただけだったので、最終候補には残りませんでした。
- [入門 データ構造とアルゴリズム](http://amzn.to/2FQLwNi)も流れで出てきただけだったので、最終候補には残りませんでした。
- [オブジェクト指向JavaScriptの原則](http://amzn.to/2H0K4HV)も流れで出てきただけだったので、最終候補には残りませんでした。
- [JavaScript: The Good Parts ―「良いパーツ」によるベストプラクティス](http://amzn.to/2I0sWD9)も流れで出てきただけだったので、最終候補には残りませんでした。
- [パターン認識と機械学習の学習―ベイズ理論に挫折しないための数学](http://amzn.to/2FNUVoY)
  - 同じ ISBN で第2版として黒い表紙ではなく黄色い表紙の本が出ているそうです。
  - PRML (パターン認識と機械学習) をいきなりは難しいのでこれはどうかという話が出ましたが、 <https://github.com/herumi/prml> を git clone するなどして main.pdf を確認したところ、難しすぎるということで候補から外れました。
- [とある弁当屋の統計技師(データサイエンティスト) ―データ分析のはじめかた―](http://amzn.to/2FOzy73)
  - [とある弁当屋の統計技師(データサイエンティスト) 2 ―因子分析大作戦―](http://amzn.to/2tf6l2w)という続編も出ていて、良さそうな本だと思いましたが、一人でも読めそうということで候補から外れました。
- [型システム入門 −プログラミング言語と型の理論−](http://amzn.to/2FPAS9M)は積ん読のままということで候補から外れました。
- [戦略的データサイエンス入門 ―ビジネスに活かすコンセプトとテクニック](http://amzn.to/2I0jIGY)も流れで出てきただけだったので、最終候補には残りませんでした。
