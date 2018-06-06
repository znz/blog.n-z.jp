---
layout: post
title: "RubyKaigi 2018の2日目に参加しました"
date: 2018-06-01 09:40 +0900
comments: true
category: blog
tags: event ruby rubykaigi
---
[RubyKaigi 2018](http://rubykaigi.org/2018/) の2日目に参加したので、
そのメモです。

発表資料へのリンクは
るびまの[RubyKaigi 2018 直前特集号](https://magazine.rubyist.net/articles/prerubykaigi2018/preRubyKaigi2018-index.html)
が RubyKaigi 2018 後にも更新されていて、非常に便利です。

<!--more-->

## SmartHR のスポンサーセッション

- [#RubyでSmartHRを助けて](https://twitter.com/search?q=%23Ruby%E3%81%A7SmartHR%E3%82%92%E5%8A%A9%E3%81%91%E3%81%A6&src=typd)

## My way with Ruby

- キーノートっぽい話題
  - 未来
  - 深掘り
  - 俯瞰した話
- 私のRubyist活動 : Ruby でできることを増やす、ライブラリーのメンテナンス
- メンテナンスしているライブラリーの数 : 130くらい
- Ruby でできるようになったことをたくさん紹介
- 必要になったからやっていたらこうなっただけ
- きっかけ1 Webフィード
- バリデーション機能付きの RSS/Atom パーサー
- デフォルトでバリデーション、オプションで無効にできる
- REXML = Ruby Electric XML (Java の Electric XML を参考にした)
- コード懇親会の宣伝
- REXML の話題に戻り
- 最近でも機能追加されている
- 利点: pure Ruby なので価値がある
- 将来: NodeSet, CSS セレクター, HTML5
- きっかけ2 プレゼンテーション
- Rabbit : Rubyist 向けのプレゼンツール
- RD = Ruby Document 対応
- いつも通り公開 : gem push
- <https://slide.rabbit-shocker.org/>
- Ruby/GTK3
- 必要な機能を実装して rabbit に戻る or 大体の機能を実装してから戻る
- Ruby でできることを増やす方が優先度が高いので後者を選ぶ
- 最近は Ruby/GI で手書きから自動生成に
- 性能は手書きより遅い
- 改善案 JITコンパイル
- Ruby/Pango
- Ruby/GdkPixbuf2
- Ruby/Poppler
- Ruby/GStreamer
- PDF output
- rcairo
- GC 問題があったが Ruby 2.4 で改善
- Easy to install : native-package-installer で gem install 時にシステムのパッケージをインストール
- rake-compiler : これも使っていたのでメンテナーになった
- きっかけ3 test
- test-unit
- 新機能
  - グループ化
  - データ駆動テスト
  - 逆順のバックトレース : Ruby 2.5.0 と同様にターミナルの時だけ逆順
  - Test double : test-unit-rr との統合
- きっかけ4 全文検索
- ライブラリー対クライアント
- groonga
- 使用例: slide の検索, るりまサーチ
- RDoc search はまだない
- ドキュメントの i18n
- yard, rdoc
- jekyll の i18n : 使用例は red-data-tools のサイト
- 複数のモデルにまたがって検索したいことがあるので、モデルに紐づけるのではなく、サーチャーというのを作る設計にしている
- Ranguba (WIP)
- ChupaText : テキスト抽出
- git-commit-mailer : Git 用のコミットメール
  - 利用例: tDiary など
  - commit-email.info : SaaS
- きっかけ5 データ処理
- CSV パーサー
- CSV フォーマットの問題点 : パースが遅い, なんでもあり
- Red Arrow : Apache Arrow Ruby
- Apache Arrow : インメモリデータ処理用のすごく速いデータフォーマット, いろんな言語がサポート
- Apache Parquet : 解析対象のデータを保存する用
- Red Data Tools
- Red Datasets
- 現在の対応データセット : Iris, CIFAR, Wikipedia
- groonga と組み合わせると wikipedia の全文検索が簡単に作れる
- jekyll + Jupyter notebook
- Red OpenCV
- Red Data Tools の Workshop が今日の午後にある 15:50-17:20

## 休憩

セッションにはいかずにスポンサーブースをみていました。

## Lunch Time

- 今日も小会議室4で Developer Meeting
- vs World の準備と ruby/spec の話でした。

## Guild Prototype

Guild (仮名) の進捗の話。

`Proc#isolate` は Guild とは関係なく有用なこともありそう。

GC で全部止まるのは厳しそうだけど、予定に入っていたので公開されるときには解決してるのかも。

Guild 間の通信の口が Guild ごとにしかないのは使いにくいのでは、という話を終わった後にしていたようだった。
Go のチャンネルみたいに複数持てるようにすると、受け取る方がいなくなったときに宙ぶらりんになるのが嫌だからこうしている、という話だった。

## extend your own programming language

[RubyでつくるRuby](https://amzn.to/2svAUgV)の MinRuby を拡張する話。
DSL で使うというのは、 Ruby のサブセットを安全に使えるので用途によっては便利そう。

## Ruby Programming with Type Checking

Steep の話。

発表とは直接は関係ないけど、
rurema には割と厳密に型が書いてあるんだから、
なんとか流用できないものなのかなとずっと思っています。
rdoc は適当にしか書いてなさそうなので、使えなさそうな印象があります。

## Afternoon Break

## RubyData Sendai Workshop in RubyKaigi 2018

セッション2つ分の時間のうちの前半は、
<https://github.com/RubyData/rubykaigi2018> の README の通りに準備してブラウザーを開いた後は、
rubykaigi2018 の中の Session1.ipynb を開いて titanic-passengers の CSV ファイルをダウンロードして RubyData/rubykaigi2018 の中において、
In の横のところを選んで Shift+Enter で実行していく、
という流れでした。

実行結果が `#<CZTop::Socket::PUB:...>` のようになっているところは、
正常に実行されると画像が出てくるので、
慌てずに Shift+Enter を押した後、
しばらく待つのが良いようです。

- <https://github.com/SciRuby/daru/wiki/pandas-vs-daru>

後半は LT でした。

- <https://red-data-tools.github.io/ja/>
- [#RubyKaigi 2018 LTで「Improve Red Chainer and Numo::NArray performance」というタイトルで発表しました。 - @naitohの日記](http://naitoh.hatenablog.com/entry/2018/06/01/120356)
- [John Resig - Write Code Every Day](https://johnresig.com/blog/write-code-every-day/)
- <https://github.com/red-data-tools/charty>

## コード懇親会

複数ある中で、お酒を飲まない人でも参加しやすそうだった
[コード懇親会](https://speee.connpass.com/event/85676/)
に参加してみました。

一人で[るりま](https://github.com/rurema/doctree)関連のことをやっていればいいかと思っていたら、
テーマが特にない人は他のチームに参加すれば良いということで、
一人来てくれたので、
[pull request ひとつ](https://github.com/rurema/doctree/pull/1277)
を任せることができて、
OSS Gate とはまた違った感じで contributor を増やせてよかったです。
