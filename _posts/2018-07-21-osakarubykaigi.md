---
layout: post
title: "大阪Ruby会議01に参加しました"
date: 2018-07-21 22:00 +0900
comments: true
category: blog
tags: event ruby
twitter: true
---
[大阪Ruby会議01](https://rubykansai.doorkeeper.jp/events/72775) にスタッフとして参加しました。
あまりメモはとっていなかったので、[るびま](https://magazine.rubyist.net/)でのレポートに期待しています。

<!--more-->

## 概要

関西Ruby会議よりも規模を小さくして開催する地域Ruby会議ということで、大阪Ruby会議として開催されました。

前日に[Rubyビジネス創出展2018](https://ruby-b.doorkeeper.jp/events/73192)があり、
そこに matz が呼ばれていて、その次の日ということで matz の基調講演がありました。

## ハッシュタグ

ハッシュタグは[#osrk01](https://twitter.com/search?f=tweets&vertical=default&q=%23osrk01&src=typd)と
[#OsakaRubyKaigi](https://twitter.com/search?f=tweets&vertical=default&q=%23OsakaRubyKaigi&src=typd)だったようですが、
当日新しくできた(?)後者の方はほとんど使われていなかったようです。

## 受付

doorkeeper の iOS の受付アプリが非常に便利で、
QR コードを提示してもらえた人の受付はサクサクできました。

懇親会の受付も担当の人にアプリで受付開始用の QR コードを読み取ってもらうことで、
早めに懇親会会場にいってもらって受付を開始してもらうことができたようです。

受付をしていたので、オープニングなどはほとんど聞けなくて、
Keynote からちゃんと聞いていました。

## Keynote

松江Ruby会議09で話をした内容をベースにしたものだったようです。

質疑応答で then についての話がいくつかありましたが、
質問者は then 賛成派の人が多かったようです。

## スポンサーセッション

- Aiming さん
- Rails + BigQuery の話

<!-- https://twitter.com/yucky_sun/status/1020521668689592320 -->
<amp-twitter
  width="375"
  height="472"
  layout="responsive"
  data-tweetid="1020521668689592320">
</amp-twitter>

## 昼休み

## TechTalk : Complexity and you

良い話でした。

High value - Low value の軸と Hard to deliver - Easy to deliver の軸の図を使った話が中心だったので、
メモはほとんど取れず。

- 京都のバッグのコミット数グラフで一番下 (1コミット)
- then 反対派
- ARTSY の話
- 桁がすごいお金の話
- 本題: Complexity and you
- 過去の Web 開発
- 例: bitfission.com
- 今日の Web 開発
- 例: Google Flights
- High value - Low value の軸と Hard to deliver - Easy to deliver の軸
- 右下は Seductive distraction

- Rails で簡単にできることと React で簡単にできることがある

- "常に X 使え (使うな)" がうまくいかない理由

- 学習とはツールボックスの中身を増やしていくこと

## 休憩

## TechTalk : GR-CITRUS いろいろ

- [GR-CITRUS いろいろ](https://speakerdeck.com/tarosay/gr-citrus-iroiro)

紹介を中心とした話でした。

## スポンサーLT

- エネチェンジさん
- ロゴチェンジでノベルティは間に合わず

## LT 前半

イベントが終わった後のハッシュタグを追っていると joker1007 さんの発表資料が一番人気のようです。

- [Introducting Fn Project](https://www.slideshare.net/ayumin/introducing-fn-project)
- [怒り駆動開発 -キレる技術-](https://speakerdeck.com/joker1007/nu-riqu-dong-kai-fa-kireruji-shu-number-osrk01)
- [Rubyコミュニティの力が本当にすごいという話](https://www.slideshare.net/KyokaFujiike/osakarubykaigi01/KyokaFujiike/osakarubykaigi01)
- ExcelがいやでRubyを始めたけどExcelから離れられない話

## 休憩

## LT 後半

飛び込み LT を募集して 5 件増えました。

- CTOのおしごと
- [コミュニティを立ち上げて痛感した「ガチ初心者向け」勉強会の失敗しないやり方について](https://www.slideshare.net/yukimasaki/the-way-ofstudymeetingnotfailing)
- [もう「クレデンシャルください」なんて言わせない](https://speakerdeck.com/zaru_sakuraba/mou-kuredensiyarukudasai-nanteyan-wasenai)
  - (AWS \| GCP) KMS + [yaml\_vault](https://github.com/joker1007/yaml_vault)
- GIJI の紹介
  - 他の話が長くて GIJI の紹介自体はほとんどなかった
- Jupyter Notebook で Ruby に親しむ
  - <https://github.com/SciRuby/iruby>
- lambda\_driver gem の話
  - `(1..10).map(&5._(:+))`
  - `(5..15).map(&:to_s >> :length)`
  - `(5..15).select {|i| i.to_s.length == 1 }`
  - `(5..15).select(&:to_s >> :length >> :== * 1)`
  - ` f = ->(x, y) { x - y }`
  - `f.curry.(1).(2)`
  - `f.flip.(1).(2)`
- 割り込みで追加で一言
  - Jupyter Notebook で ansible の構成管理をしている例があるらしい
  - Ruby なら itamae (や mitamae?) で同様のことができるのでは
- ジュンク堂書店KOF店のご案内

## 懇親会

懇親会での LT で[プログラマの三大美徳](https://ja.wikipedia.org/wiki/%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9E#%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9E%E3%81%AE%E4%B8%89%E5%A4%A7%E7%BE%8E%E5%BE%B3)といっている中に憤怒が入っていて、そんなのあったっけ、と思って調べてみたら wikipedia だと怠惰（Laziness）、短気（Impatience）、傲慢（Hubris）なので、どこから出てきたのか気になりました。

このチェックリストも気になりました。

<!-- https://twitter.com/ayumin/status/1020611873580888064 -->
<amp-twitter
  width="375"
  height="472"
  layout="responsive"
  data-tweetid="1020611873580888064">
</amp-twitter>

懇親会で話をしていて [sample/trick2018 が追加されていない](https://bugs.ruby-lang.org/issues/14930)ことに気づいたので、
帰ってからチケットを書いたら、速攻で追加されました。
今回は上位5作品だったようです。
