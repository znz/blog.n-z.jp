---
layout: post
title: "R と Ruby によるデータ解析入門　読書会　第2回に参加しました"
date: 2014-05-17 13:00:00 +0900
comments: true
category: blog
tags: event amagasakirb r ruby
---
[5月17日 R と Ruby によるデータ解析入門　読書会　第2回(兵庫県)](http://kokucheese.com/event/index/168617/)
に参加しました。
今回は4章からでした。
次回は6月28日です。

<!--more-->

## メモ

以下今回のメモです。

- PDF をタブレットで読むのに `k2pdfopt` で変換すると読みやすい
- サンプルコード: <https://github.com/setoyama60jp/everyday>
- p.90 l.3 `@durarion` って `@duration` の typo?
- `duration` は今何分占有しているか
- `use_duration` は `Person` が何分占有するか
- `need_to_go?` は必ず3回というわけではなく540分の3の確率
- p.91 `カンマ句切り` -> `カンマ区切り` ?
- Producer Consumer パターンで Enumerator を使うという話
- `read.table` の `header` とか `sep` とか
- `ggplot2` では `+` がオーバーロードされているという話
- Safari Books Online の話
- 動画もあるという話
- 英語だと字幕がないと厳しい話
- 自動字幕の話
- 図4-3 の下に書いてある横軸が1から始まっているのは間違いで実際は0からなので、最初の方以外は ASCII コードに一致
- [ヤバイ経済学](http://amzn.to/2oFeaJZ) はオススメという話
- 実装例5-3 `Market` クラスはクラスにする必要性がない書き方になっている
- `pdf` と `dev.off` は p.52 に説明がある
- 5章のモデルがいまいちという話
- 実装例5-10 の最後のターンの処理ってループの外で良いのでは。
- 全体的に Ruby コードもいまいちという話
- `R` の `viewport` の話
- 実装詳細と実装説明の前にどういう出力を目指しているのか概要が欲しいという話
- 削るとか溶かすとかいう話
- エンロン事件のメールが公開されていてダウンロードできるのに驚いた話
- 6章は R で頑張っている
- Gmail の IMAP の `[Gmail]/送信済みメール` は言語設定で変わる話
- ビッグデータ的な公開されているデータはどういうのがあるのかという話
- p.157 `クォーテーションを含むメールアドレスがデータ内に存在する` からメールアドレスは面倒という話
- [ggplot2 の自分用メモ集を作ろう - Triad sou.](http://d.hatena.ne.jp/triadsou/20100528/1275042816)
- ビッグデータの話として有名な購入するデオドラントと石けんが変わって妊娠がわかったという話
- PDF から Web アルバムの話

<div class="amazon">
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4873116155&linkId=93771f6ce7137b8d3f96f2dd9a88c086" %}
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4492313788&linkId=73e3dc68b28971ba9842d4317e94adcb" %}
</div>
