---
layout: post
title: "平成Ruby会議01に参加しました"
date: 2019-12-14 23:59 +0900
comments: true
category: blog
tags: event ruby
---
[平成Ruby会議 01](https://heiseirb.github.io/kaigi01/)に参加しました。

<!--more-->

## 参加理由

翌日に[Ruby Hack Challenge Holiday #9 Ruby 2.7 + 年末LT大会](https://rhc.connpass.com/event/155899/)があって、
両方参加すれば少ない移動で色々参加できそうと思って参加しました。

## 開場からオープニング

会場についてみると
[‎田代創大の「平成Ruby会議」](https://music.apple.com/jp/playlist/%E5%B9%B3%E6%88%90ruby%E4%BC%9A%E8%AD%B0/pl.u-d2b0kMXTMzmlp3)
がかかっていました。

## What is expected?

キーノートは、次にくる可能性のあるトークンがわかれば補完などで便利だけど、
Ruby 難しい、という感じの話でした。

以下、メモです。

- `def def` とかける
- 次にくることができるトークンがわかると嬉しいことがある
- Tokenization: `ruby --dump=y -e '1 + 2' | grep Shifting`
- Parsing: `ruby --dump=y -e '1 + 2'`
- Build AST: `ruby --dump=p -e '1 + 2'`
- Compile: `ruby --dump=i -e '1 + 2'`
- Parser が今日のトピック
- 前提知識が多くてついていくのが大変そうな話が続いていた
- bison がテーブルを圧縮している
- 状態 (lex_state) に依存しているので色々大変
- default reductions に依存していて難しい
- bison の内部依存になる
- tool/ytab.sed のようなコードもある
- テストが難しい

## Ruby2.7以降のiseqのバイナリ表現の改善について、Rubyアソシエーション開発助成金2019採択プロジェクトの途中経過について

キーノートが内部構造の話だったので、引き続き内部構造の話の A トラックにいました。

多少読み込みのオーバーヘッドは増えたが、サイズが減ってファイル IO が減る方が大きいので、
全体としては高速化されて、キャッシュサイズも小さくなって良くなっているようです。

以下、メモです。

- https://nagayamaryoga.github.io/study/
- bin = ISeq.compile
- iseq.eval
- bin = iseq.to_binary
- ISeq.load_from_binary(bin)
- アプリ起動の高速化
- 例 Bootsnap gem
- Rails 5.2 からデフォルト
- 一部のクラス定義は Ruby 2.7 から Ruby で定義 (実装は C のまま)
- バイナリをインタプリタに埋め込み
- バイナリサイズが元のソースに比べて巨大だった
- 要求: 情報を失わない、読み込みが高速、省サイズ
- 単一スクリプト
- ファイルサイズは約24%
- 読み込みは バイナリから ISeq は多少のオーバーヘッドで遅くなったがファイル読み込みと合わせると速くなった
- Rails プロジェクトでの評価
- キャッシュサイズは削減
- 初回起動はちょっと遅くなったが2回目以降はほぼ同じ
- 不要なフィールドの削除: 約20%減
- 可変長整数エンコーディング
- 8バイト → UTF-8 like な可変長符号
- 時間切れでまとめにジャンプ

## あなたのそのgem、Windowsでも動きますか？

middleman-lazy-img-loading gem 関連で
middlemann gem に pull request を出して
Windows 対応が必要になって、
Windows 対応の CI の知見が溜まった話でした。


以下、メモです。

- middleman gem
- https://middlemanapp.com
- middleman の拡張 gem を作った
- middleman-lazy-img-loading
- gemspec を bundle の形式に合わせて pull request を出した
- git を呼び出していたら Windows 対応大丈夫? という話があった
- middleman は Windows 対応をうたっているが CI は Linux だけだった
- Windows CI を追加した時の知見紹介

- デスクトップ OS のシェアは Windows が圧倒的に多い
- https://ecosystem.rubytogether.org/
- railsgirls.jp/install を参考にインストールできる
- あなたの gem を試して動きますか?

- shell command を使わない
- 例: `rm -rf ...` → `FileUtils.remove_entry_secure`
- Ruby 自体の Windows 対応はかなり力が入っている
- それでも Windows とその他の OS で処理を分けたい場合は `Gem.win_platform?`
- どうしても無理なら、その機能は Windows 対応を諦める

- Windows 対応 CI service
- GitHub Actions, AppVeyor, CircleCI
- OSS の場合無料で使えるもの
- GitHub Actions と CircleCI は cron 書式の定期実行ができる
- 行き詰まったら CI service を変えてみるという手も pull/2297

- Windows 対応やっていきましょう
- 「総体としてのRuby」は我々で良くしていける

- 10月から open のままでまだマージされていない

## ActiveSupport::Concernで開くメタプログラミングの扉

include と extend の使い分けとか、慣れてしまえば気にならないのですが、
ある程度整理された書き方に統一されるのは便利かもしれないと思いました。

append_features などのメタプログラミング用にオーバーライドして使うメソッドは
普通のプログラムでは使わないなあと思っているので、こういう用途で使うのか、
という点でも面白かったです。

以下、メモです。

- AS::C はメタプロの宝庫
- インスタンスメソッドとクラスメソッドを同時に定義するとわかりづらくなる
- モジュールが依存するモジュールも include する必要がある
- この発表では scope などをクラスマクロと呼んでいる
- AS::C を使うとまとめてかける
- AS::C はたった50行 (コメントなどを削除)
- class_methods, included
- included はレシーバー無しの時の動作を追加している
- append_features で実際に生やしている
- extended と append_features
- 多重継承の時の動作は難しいので図で説明
- メタプロは Ruby を使う強力な動機になる
- メタプロは初級者の最後の壁

## Async/Await functions in Ruby

Async/Await はまだ馴染みがないので、ききにきてみました。
Fiber もちゃんと使ったことがないので、
何か題材を考えて使ってみた方がいいのかもしれないと思いました。

以下、メモです。

- N+1 problems in GraphQL
- Gems for batching は色々
- 今回は graphql-batch の話
- Nested loaders は見た目が悪くなる
- JavaScript は Promise と Generator で Async/Await ができる
- Fiber (Ruby 1.9〜)
- JavaScript の Generator の代わりに Fiber
- Fiber で書き直し
- ネストを再帰に
- N+1 問題が残っている?
- まだうまくいかないというのがオチ
- 発表資料: https://twitter.com/sat0yu/status/1205708703850090497

## 既存RailsApplicationの高速化

特定の何かを高速化した話ではなく、
rubocop や rails_best_practice のようなチェッカーを作っているという話のようでした。

以下、メモです。

- 主にリクエスト時間を短くした話
- rails_best_practice などのようにチェックしたい
- https://github.com/cobafan/fast-rails を作った
- `AR#count` vs `AR#exists?`
- `#find with present?` vs `#any?`
- https://github.com/cobafan/fast_rails を作った
- レビューを大事にしたい

- 質疑応答
- count と 0 の比較は実行時ではなく字面で判定の方が良いのでは
- Rubocop に型対応を入れようとしているので、それに関連して良い感じにできるのでは。続きは懇親会で

## Good to know YAML

Psych のデータ構造やフック的な処理の追加方法についての話のようでした。
他の作業をしていたため、詳細はほとんど聞けませんでした。

以下、メモです。

- syck (さいく) については話さない
- YAML と Psych (さいく)
- load, load_file, parse, parse_file
- Psych::Nodes
- 重複キーの検出 3案
- yamcha gem

## rustで拡張モジュールを作成してgemにする

Ruby と Rust のデータのやりとり部分は大変そうで、
最後のベンチマークでも処理が短いからか、
速度も pure ruby 実装とそんなに変わらなかったのようなので、
C 拡張を使いたい場面と同様に rust 側で重い計算処理をするような用途じゃないと
あまり実用的な利点はなさそうな気がしました。

以下、メモです。

- Rust の `start_with`, `end_with` を使って `Symbol#start_with?`, `Symbol#end_with?` を作る
- rusty_symbol gem
- `bundle gem rusty_symbol --ext`
- rake-compiler : rust は未サポート
- Thermite で
- 鹿児島Ruby会議01の神速さんの発表資料を参考にした
- `cargo init --lib`
- Cargo.toml は .gemspec に似ている
- Hello world ブランチに Hello world の例を入れている
- シンボルは文字列の皮を被った整数値

## やわらか増税 〜はじめての増税対応〜

増税は切り替えのタイミングとか色々大変そうでした。
特に軽減税率のように単純に切り替えではないものも増えていて大変そうでした。
時間の mock がうまくいっていなくてバグっていたとか、ありがちな感じでなかなかつらそうです。
質疑応答のタイミングでは何だったか調べきれなかったので、
twitter のハッシュタグでは libfaketime を紹介しておきました。

以下、メモです。

- ショップオーナーに対するサービス利用料の増税
- ショップオーナーが設定する商品の増税 (軽減税率含む)
- いつから増税? → 一次ソースをみる → 国税庁
- 契約終了日をみる
- 商品価格は発送時の税率
- 9/30 に受注して 10/1 に出荷した場合は 10% (そうでなかったならオーナーが負担している)
- 定数で持つか DB に持つか → DB (taxes テーブル) を採用
- Time.current だとミリ秒まで持っているのでクエリキャッシュがきかない
- shouhizei gem https://github.com/colorbox/shouhizei

- 時刻を元に表示を切り替えたい
- API のレスポンスに "増税後の情報か?" という bool を追加

- テスト
- ActiveSupport::Testing::TimeHelpers#travel_to
- context に travel_to: をかけるようにした
- 増税前と増税後で大きなコンテキストを作ってコピーしておけば後から消すのも楽

- travel_to の設定漏れで増税後に master のテストがこけてしまって修正が必要だった

- 想定質問
- 送料と決済手数料の税率は?

- https://speakerdeck.com/uvb_76/yawaraka-zouzei

## ActiveRecordのpluckメソッドがおかしな挙動をしたので調べてみた

実際の挙動を追いかける部分では、
ライブデバッグというか binding.pry で調査デモをしていたので見入っていました。

## Regression Test for RuboCop

rubocop 自体の例外が起きるようになるような Regression をテストする話でした。
auto correct でコードが壊れるかどうかなどはまだ対象外のようでした。

[るりまレビュー会](https://rurema-review.connpass.com/)の宣伝を入れてくれていました。

以下、メモです。

- rubocop は良く壊れる
- Ruby の Syntax は難しい
- かっこの省略ができるのが特に大変らしい
- pocke/rubocop-regression-test
- いろんな組み合わせで例外を出さないかだけチェックしている
- false positive は人が見ないと難しそう
- cop の設定の組み合わせ
- テストはあるがそれだけだと見落としが多そう
- 実コードでチェック

- future work
- auto correct 無限ループ問題
- インデントが無限に増えるなど
- rubocop -a で壊れるのを検出したい
- プラグインのテスト

## スポンサー企業 LT

いろんなスポンサーがあるようで、
良い話も多かったです。

## 飛び込みLT

### OSS で結果を出す方法

OSS のコントリビュータ向けの良い話でした。

- 発表資料: http://twitter.com/knu/status/1205792280503705600

## RubyとLispの切っても切れない関係

早口の LT でした。

## TECH::EXPERT で学んだこと

ゆっくり話していました。

## Breaking Change

最後のキーノートでした。
破壊的変更の影響を受けたり緩和したりした話などでした。

以下、メモです。

- match?(nil) の話
- publish or public の方が public or private より重要
- SDP 安定依存の法則
- Rails はメソッドコメントがあるものが公開
- schema_migrations_table_name は使われていることが多かったので非推奨警告を出すことに
- Faker 2 での破壊的変更
- キーワード引数への変更だった
- gemdiff で差分をみたりして確認した
- ArgumentError だけだと正しいキーワード名がわからない

- 警告の pull request に書いたこと
- Context なぜ必要か
- How 実装ポイント
- Merit どんな得が
- Example 実例 Before After
- 互換 API を足して旧 API への警告
- 125 API
- RuboCop
- 変わる前の Faker のコミットハッシュを取得
- auto correct する cop を作成
- 移行スクリプトを発掘した
- 抜粋して紹介
- フィードバックを観測
- フィーッドバックに対して考えたこと
- rubocop-faker
- transpec に影響を受けた

- 作っただけだと使われない
- faker の警告メッセージに入れてもらった
- 前例、解決策、実例、メリット、心配だった点

- 1引数の時にキーワード引数から戻す?という議論がある

- Community is yourself <https://magazine.rubyist.net/articles/0028/0028-ForeWord.html>
