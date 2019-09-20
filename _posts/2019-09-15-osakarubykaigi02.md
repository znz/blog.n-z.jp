---
layout: post
title: "大阪Ruby会議02に参加しました"
date: 2018-09-15 10:00 +0900
comments: true
category: blog
tags: event ruby
twitter: true
---
[大阪Ruby会議02](http://regional.rubykaigi.org/osaka02/) で発表しました。

<!--more-->

以下、メモです。
発表によってしっかりメモを取りつつ聞いていたり、メモはあまりとらずに聞いていたりしました。

## スポンサー LT : 開発メンバーの課題の探し方

<!-- エイチームフィナジー -->

- MBTI 心理学的タイプ論

## OSS Security The hard way

<!-- SHIBATA Hiroshi -->

- Attack Surface, Attack Vector
- CIA 機密性 完全性 可用性
- 他の言語でどう対処したか (Python や Go を特に参考にすることが多い)

- 受け付けた例
- `open` でコマンドが実行できる話
- open-uri を使って作った feed reader で任意の URL を設定できるようにしていると発動するかもしれない
- 権限昇格 : 対応するようになってからはみたことがない (root 権限が取れるなど)

- reject したもの (多い)
- s3 のバケットのファイル一覧が見える
- SSL や証明書の話 fastly や heroku にいってほしい

- 難しいもの (1割未満)
- ASAN (アドレスサニタイザー) で検出されたもの
- Rails とかで実際におこせるのか議論する
- SEGV

- リリースフロー
- Ruby 言語の窓口としては メール security@ と HackerOne <https://hackerone.com/ruby>
- security@ だと Bounty (報奨金) が出せないので HackerOne に誘導することもある
- ななおくさんが頻繁に報告してくれている
- 報告内容に Description, PoC, Impact があると非常に良い
- ダメな報告は Impact がないことが多い
- オープンな場でコードを扱うのが当たり前になっていると秘密裏にパッチなどを扱うのが大変
- 既存のアプリを壊さずに直すのが大変
- 別の脆弱性を引き起こさないように元の報告者と調整
- OS のディストリビューターや Heroku などのサービス提供者との調整とか
- ブランチメンテナーの予定をおさえてリリース日を決めたりとか
- CVE を割り当てたり
- まだ更新されていないアプリへの攻撃に利用されないように、具体的な攻撃方法は濁しつつアナウンスを書く

- CVE とは?
- 単なる識別番号
- 登録されたら脆弱性とかそういうものではない
- (issue のチケット番号とかと同じようなものかも)

- 意図せず公開されてしまって大変だったことも

- bug bounty
- Noise Problem : お金が絡むと治安が悪くなる
- 一番ひどかったのは過去の脆弱性レポートのコピペ

- 最近の攻撃例
- rest-client gem などのアカウントがハイジャックされて悪意のあるコードを含む gem がリリースされていた
- タイポスクワッティング : 綴り間違い以外にも `_` と `-` の違いとか有無とか
- セキュリティ研究者がリサーチ用に作っているものもあるらしく、中身をみて判断する必要がある

- `gem install` に hook をかけるので code injection される余地がある

- アカウントのハイジャック問題
- パスワードの使い回しが一番の問題

- パスワードを使いまわさない
- 22文字以上
- 2FA が設定できるものには設定する

- rubygems.org 側の対応
- メール通知とか GitHub 連携強化
- WebAuthn 対応

## チャットボットのススメ

今回も docker の中で実行しました。
XQuartz の設定で全画面を使うようにして、 rabbit は右クリックメニューからフルスクリーンを選ぶと上のメニューバーも隠すことができました。

{% include slides.html author="znz" slide="osakarubykaigi02-chatbot" title="チャットボットのススメ" slideshare="znzjp/ss-171884537" speakerdeck="znz/tiyatutobotutofalsesusume" github="znz/osakarubykaigi02-chatbot" %}

slideshare はスライドのアップロードし直しができなかったので、少し古い PDF になっています。

## プログラミングを一生の仕事にする 〜顧問プログラマを8年続けて分かったこと〜

<!-- Keynote 西見 公宏 -->

<!-- https://twitter.com/tsuka/status/1173082814507470849 -->

- [2019/09/15 大阪Ruby会議02 Keynote](https://www.slideshare.net/rootmoon/20190915-ruby02-keynote)

- オフィスをなくした会社としてテレビで紹介された画像の読み込みが遅くて肝心の下のテロップがでてこなかった

- 「プログラマとしての良心に最大限従うこと」

## Lunch

外に食事に出ていたのでみていないのですが、ランチ LT をその場で募集してやっていたようです。

## スポンサー LT : アジャイルウェア

前半の会社紹介と後半の実際の話でした。

## スポンサー LT : エネチェンジ

会社紹介は最後にちょっとだけで転職ノウハウの話がほとんどでした。

## 子どものためのプログラミング道場『CoderDojo』を支えるRailsアプリケーションの設計と実装

- CoderDojo Japan の話
- GitHub Pages で DojoCast をやっていたら deploy した時に再生がきれていた。
- 大きくなってきたので jekyll を卒業して rails アプリに
- coderdojo/stat
- 試してみて, 反応をみて, 次に繋げる

## Ruby/Rails Benchmarking and Profiling with TDD

<!-- Aiming のうえもりさん -->

- Ruby/Rails のベンチマークやプロファイリングの初心者向けの話
- 「推測するな計測せよ」
- 計測が最重要
- Benchmark
- プロファイリングとあわせてベンチマークは必ずとっておこう
- Stackprof
- CPU Clock Time : CPU の利用時間
- Wall Clock Time : 開始から終了までの時間。 Rails の場合はこれ
- Stackprof の結果の見方 TOTAL 呼び出しているメソッドの中も含む, SAMPLES 純粋にそのメソッドのサンプリング回数, デフォルトで SAMPLES によるソート
- Stackprof-webnav や `Stackprof --framegraph` など
- サンプルアプリ <https://github.com/yuemori/performance_test_app>
- 手動確認は色々と面倒 → Performance Spec
- gem 化はしてない
- 余談 rspec-benchmark, rails-perftest というのがすでにあった

## Suppress warnings

- `RUBYOPT=-w` で rails を動かすと警告たくさん
- `File.exists?` → `File.exist?` などは初めての OSS のコントリビューションにも良い

## 休憩

- ランチ LT の内容からロゴの説明
- OSS Gate の紹介

## スポンサー LT : インゲージ

- Re:lation
- spring, bootsnap の話

## Concerns about Concerns

- 発表開始時点の最新のツイートに発表資料 <https://twitter.com/netwillnet/status/1173116050373775360> [Concerns about Concerns - Speaker Deck](https://speakerdeck.com/willnet/concerns-about-concerns)
- Rails の Concerns の説明
- concerns のアンチパターンとその回避策
- ビジネスロジックはモデルに
- rubocop の ClassLength 対策で concerns に切り出すのではなくモデルに移動するなど責務の分散を考える
- 名前をつけたいだけなら concerning がある
- 委譲で実装するとプライベートメソッドを切り出しやすい
- 名前の衝突の心配も減る
- モジュールで実装すると責務がクラスに集約されてしまう
- 意見があったら clean-rails.org で

## Fat Modelに対処するための考え方と6つのリファクタリングパターン

- <https://twitter.com/purunkaoru/status/1173126149410418689> [Fat Modelに対処する 6つのリファクタリングパターン](https://speakerdeck.com/hotatekaoru/fat-modelnidui-chu-suru-6tufalserihuakutaringupatan)
- 初大阪、初関西らしい
- Fat Model とは
- Fat Model を起こさないためにパターン化をしたい
- ハンマー釘病

## What a cool Ruby-2.7

- 黒魔術芸人
- 2.7 の新機能を使った method_plus gem を作った
- Method クラスに色々生やす

## いつでもどこでもクールなRubyを書く方法

<!-- yebis0942 ふくだけんとさん -->

- <https://github.com/vzvu3k6k/baberu>
- js の babel のように変換するものを作っている話

## Ruby 3の型解析に向けた計画

- Ruby 3 に向けてのキーワード引数の変更予定の現状をちょっと紹介
- Ruby 3 の静的解析の構想と進捗
- 型プロファイラの設計と実装

- 質問 : 型注釈書きたいですか?
- <https://github.com/ruby/ruby-signature> コントリビュートチャンス!
- <https://github.com/mame/ruby-type-profiler>

## クロージング

- 集合写真撮影
