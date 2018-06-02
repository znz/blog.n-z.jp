---
layout: post
title: "RubyKaigi 2018の1日目に参加しました"
date: 2018-05-31 22:22 +0900
comments: true
category: blog
tags: event ruby rubykaigi
---
[RubyKaigi 2018](http://rubykaigi.org/2018/) に1日目に参加したので、
そのメモです。

<!--more-->

## OTCBTC のスポンサーセッション

BTC というところか連想できるように暗号通貨などを取り扱っている会社っぽい感じだった。

## Proverbs

- matz のキーノート
- Proverbs : ことわざ
- 先人の知恵 wisdom
- 主に日本語のことわざから
- 名は体を表す
  - 名前重要
  - ソフトウェアには物理的な実体がない
  - 振る舞いに名前をつける
  - 悪い例: yield\_self
    - `def yield_self; yield self; end`
  - 何をしているかを表しているが、何をしたいかを表していない
  - `then` という別名を昨日コミットした
  - version.h 以外のコミットは5年ぶりぐらいらしい
  - True Names: 真の名前の話
  - Ruby という名前の話
  - ググラビリティが低い Bad Names: Go, Swift
  - 金持ちのスポンサーがついていれば問題ない(?)
  - 単語を組み合わせる (例: Ruby on Rails, TensorFlow)
  - スペルをいじる (例: Streem, Jupyter)
  - 変な単語を選ぶ (例: hHanami, Nokogiri, Kaminari)
- Time is Money
  - 時は価値なり
  - 価値は金に変換できる
  - 浪費例
  - Ruby は一般的に時間を有効活用して生産的になることを助けてくれる
  - 便利なメソッドがたくさんある, ライブラリーやフレームワークがたくさんある
  - 聞きたいときに聞ける人が多い
  - 簡潔さ: 見た目シンプル
  - rspec などのように乱用できる, TRICK
  - 型を書かなくて良い
  - コンパクトになる
  - 簡潔さは力なり succinctness is power -- Paul Graham
  - 色々他の発表者も紹介してたりとか
  - 高速化の話から Time is Money に戻った
- 塞翁が馬
  - Ruby is Dead Every Year
- ゆく河の流れは絶えずして、しかももとの水にあらず
  - Python 2→3 問題とか Ruby 1.8 → 1.9 とか
  - コミュニティベース
- スポンサー紹介
  - 旧バージョンの zozo スーツで作ったジーンズ
- 質疑応答
  - Q: TypeScript とかで型定義が流行っているのが個人的には嫌だが、JavaScript より TypeScript の方が良いと思っているので矛盾しているが、Ruby の今後は?
  - A: 言語仕様に型宣言が入ることはないと思っている
  - 静的な型チェックの話
  - Q: Ruby 3 の話? Higher level abstraction (マクロとか)?
  - A: 今は特にアイデアはない
  - Q: Type annotation とかなんとか
  - さっきの静的な型チェックの話の続き

## Lunch Time

小会議室4で Developer Meeting

## Analyzing and Reducing Ruby Memory Usage

他のことをしながら聞いていたのでメモは取れず。
2.6 での改善点の話っぽい感じだった。

## Deep Learning Programming on Ruby

- mxnet.rb は　pycall.rb を使わずに Ruby で直接 MXNet を使える
- MXnet は Python, C/C++ 以外も含めた多言語対応を考慮した作りになっている
- Apache MXNet はサポートしている組織が多い
- 高機能
- 命令型、記号型の両方の書き方ができる
- MXNet vs Tensorflow
- Keras のバックエンドとして使って比較した記事がある
- MXNet の方が GPU で良い結果がでる
- ONNX という学習データ交換用のフォーマットがある
- mxnet.rb の現状紹介
- デモは時間がかかりそうだったので後回し

- Red Chainer
- python の chainer の移植
- Numo::NArray を使用
- Red Data Tools の紹介
- Define-by-Run
- 高レベル API の提供
- (Relu.relu() って Relu() ってかけるとよさそう?)
- GPU 対応は sonots/cumo
- Apache Arrow サポート
- デモデータは red-datasets

- Ruby のデータサイエンス対応の現状
- Red Arrow が Arrow の公式 Ruby バインディングになった
- `Range#%` : `(1...10)%2` とかける

## All About RuboCop

自己紹介 (長い) の後、歴史、現状、将来の予定とかでした。

## RubyGems 3 &amp; 4

- 自己紹介
- <https://github.com/ruby/ruby/graphs/contributors?from=2017-12-25&to=2018-05-29&type=c>
- RailsGirls の紹介
  - RailsGirls からサポートされて RubyKaigi 2018 に参加している人もいるらしい
- RubyGems 2.7, 3.0, 4.0 の話をする
- 2.5 と 2.6 は単独リリースはもうない
  - セキュリティ修正はバックポートで Ruby 自体をアップデートして対応
- 2.7 は通常通りバグ修正とセキュリティ修正
- ビルドマトリックス
  - Ruby 1.8 を使ったことある人挙手 → 半分ぐらい
  - YAML のエンジン (syck, psych)
  - Bundler との統合
- 1.8 対応: `respond_to?` や `defined?` での分岐が多い
- Bundler 統合
  - ruby 添付と `gem --update-system` で入るもので処理が違う
  - 依存解決, test が分岐している
  - インストーラー
    - bundler をインストールする処理
    - 2.7 の初期は問題があった
    - 2.7.7 でだいぶこなれてきた
    - インストーラーのテストは大変
  - `exe/bundle` 問題
    - travis でいろんなアップデート処理が複雑に絡み合って bundle の実体がどこか
	- travis の問題なので直しようがなかったので、 travis の中の人の協力で半年がかりで直ったらしい
- Security
  - 2.7.6 が突然リリースされた
  - ハンドリングを調整中
- バージョンポリシー
  - 最新安定版を Ruby Core に入れる
  - Ruby 2.6 で 3.0
  - Ruby 2.7 か 3.0 で 4.0
- マージ方法
  - ディレクトリ構成を調整して今はコピーしてマージするだけ
  - 履歴が失われる
- stdlib を git submodule にしたい
  - <https://git.ruby-lang.org/>
- RubyGems 3
  - deprecated なものを削除したり、消す予定のものに警告を出すようにしたり
- `Gem::Deprecate` の紹介
- deprecated の扱い
  - gem-codesearch
  - DEMO: `gemsearch 'def then'`
  - `docker run --rm -t rubylang/all-ruby /all-ruby/all-ruby`
- `ubygems.rb` を消す話
- Ruby 2.2 以上のみをサポート
  - deprecated なコードを消しまくった
  - コードカバレッジが上がった
- Upgrade toolchain
  - hoe を使うのをやめた
  - bundle を使うわけにはいかないので独自対応
- rubygems-update
- 依存解決のライブラリのバージョンが rubygems と bundler で違う問題
- RubyGems 4
  - `--conservative` をデフォルト有効にするかも (`gem i rails --conservative` のように使う)
  - デフォルト gem の話 (`gem i csv --default` がほぼ無意味?)
  - `--user-install` をデフォルトに
    - system ruby だと sudo なしでエラーなのを解決したい
    - rbenv との組み合わせだと PATH の問題がある

## A parser based syntax highlighter

- VimConf と Okinawa RubyKaigi で同じテーマで話した
- Okinawa RubyKaigi より深い内容を話す
- 既存の highlighter は正規表現ベース
- 既存の highlighter の問題点
  - コードを読むのが辛い
  - 完璧じゃない
- Iro の紹介
  - ripper を使っている
  - Iro gem と Iro.vim が連携
- 利点
  - 読みやすい
  - 正しくハイライトできる
  - ローカル変数をハイライトできる (RubyMine でもできるらしい) (例: `p a; a = 1; p a` の最後の `a` の色が変わる)
  - 一つの実装で複数のエディターに対応できる
  - プロトコルとしての実装なので、Python にも対応するなど、複数の言語に対応できる
- ripper
  - Ripper.lex : どの位置から何文字を何としてハイライトするかを決めるのに使う
  - Ripper.sexp というのもある
  - 実際にはイベントドリブンな API を使っている
  - lex と sexp を知っているとイベントドリブンな API がわかりやすいので、使っていないが説明した
  - `on_TYPE` を (デザインパターンの visitor パターンで) 呼び出す
- Iro の実装
- インラインのハイライト
  - SQL というデリミターの here document の中は SQL でハイライトするなど
- FAQ?
  - パフォーマンス
    - Iro.vim は常用していて 3000行程度だと問題は感じない, 30000行ぐらいになるとつらい (vim の API が悪い?)
  - 壊れている Ruby コードは?
    - 編集中とか
	- そういう場合も ripper がそれっぽい結果を返してくれるのでそれっぽい感じになる
- まとめ
- オンラインデモもある: <http://ruby-highlight.herokuapp.com/>

## MEDLEY のスポンサーセッション

前回からのアップデートを含めての紹介でした。

## Lightning Talks

横のタイマーの画面では、終わったら `raise TalkTimeoutError` と出ていた。
交代の間は `talks.shift.ready?` と出ていた。

### From String#undump to String#unescape

- nginx のログが undump 案件だった
- 色々ググって bugs.ruby-lang.org まで探したら、実装すれば入るステータスのチケットがあったので、実装していれたので、 ruby 2.5 に入った
- 使ってみると `""` が必要だった
- string\_unescape gem を作った

### Create libcsv based ruby/csv compatible CSV library

- 英語だった。
- libcsv の方が速いらしい
- 今はマルチバイト非対応っぽい?

### Rib - Yet another interactive Ruby shell

- irb や pry より軽量らしい

### Improve JSON performance

- わかりやすい改善点で速くなるが、 pull request に反応がない
- https://github.com/flori/json/pull/345
- https://github.com/flori/json/pull/346

### Improve Red Chainer and Numo::NArray performance

- 実装の詳細なので LT だと難しかった

### Using Tamashii Connect Real World with Chatbot

### Find out potential dead codes from diff

- 静的コード検査での dead code での問題点
  - false positives : こっちにフォーカス
  - DSL : あきらめ
- diff からチェックするようにした
- 有用だった例
  - 未使用コードからの未使用コード
  - rename もれ

### Test asynchronous functions with RSpec

WebSocket のテストの話

### To refine or not to refine

### 5-Minute Recipe of Todo-app

### Symbolic Execution of Ruby Programs

- KLEE

### Schrödinger's branch

- ImageFlux
- RUBY IS DEAD EVERY YEAR に内容を変更
- ブランチの説明
- ruby\_2\_2 が EOL かどうか問題
