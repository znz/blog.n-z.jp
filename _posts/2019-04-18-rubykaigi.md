---
layout: post
title: "RubyKaigi 2019の1日目に参加しました"
date: 2019-04-18 23:50 +0900
comments: true
category: blog
tags: event ruby rubykaigi
---
[RubyKaigi 2019](https://rubykaigi.org/2019/) に1日目に参加したので、
そのメモです。

とりあえずのメモなので、あとで更新するかもしれません。

<!--more-->

## スポンサーセッション

- GMOペパボ
- RAKSUL

## The Year of Concurrency

- キーノート
- 221 ページ
- Ruby is Good
- Productive, Flexible, Fun
- Ruby is Bad
- Performance, Multi-Cores, Bigger Team/Project
- Ruby is Good Enough
- Bit Sites Use Ruby : Github, Airbnb, Instacart, Cookpad
- 大体のケースでは十分速い
- Twitter Story
- Scala に移行した
- ずっと Ruby 1.8 を使っていたらしい
- 1.9 以降は速くなっている

- Ruby3 の3つの柱: Performance, Concurrency, Static Analysis
- Static Analysis
- 静的言語が流行っている
- DRY じゃないのでテストが嫌い
- PHP: Type Hinting
- Pytnon: Type Annotation
- JavaScript: TypeScript
- 型宣言 (Type Annotation) が嫌い
- DRY じゃないから
- 型宣言なしで動いているのに、型宣言をつけるのは機械に仕事をさせられている気がする (ので嫌い)
- 関連セッションの紹介
- Static Type Checking Components
- Type Definition Syntax (.rbi) : 通常のプログラムとは別に型定義を書いたファイル
- github.com/soutaro/ruby-signature
- Gems (TBD)
- Type Profiler
- 抽象解釈
- 型プロファイラで rbi ファイルを自動生成して十分でなければ自分で書き換える
- YARD から rbi への変換も提供予定
- Sorbet from Stripe, Steep
- どちらも rbi ファイル対応予定
- こういうものが揃うと普通の ruby のプログラムが型チェックできるようになる
- LSP (Language Server Protocol) でも使えそう

- Performance
- どの言語も速すぎるということはない
- ruby は文句をよく言われる
- 中国でパフォーマンス改善がホットなトピックだった
- メモリーが最初のボトルネックになっているらしい
- コンパクションGC は別のセッションで詳細説明あり
- ボトルネックはメモリーだけではない
- MJIT
- Pros: Portable, Reliable, Optimized
- Cons: Heavy, Inefficient (Memory-wise)
- CPU がボトルネックになっているものには良いが Rails では遅くなっている
- Rails メソッドが多いのでコンパイルしないといけないメソッドも多い、メモリ消費量が多い
- MIR (Lightweight JIT) が入って段階的な JIT になるかもしれない
- Multi-Cores
- もともと Web はマルチコアに向いている
- Concurrency が言語の未来に強く影響する
- Fiber は明示的なコンテキストの切り替えが必要
- Thread は GIL があって同時に 1 スレッドしか動かない
- マルチコアが使えて、使いやすくて、<!-- FIXME -->
- shared nothing
- Erlang のようにすべて Immutable には今からはできない
- Separate Object Space
- チャンネルでは Immutable なオブジェクトしか送れない
- Frozen Object
- Recursively Frozen Object は Deeply Frozen Object という印をつける
- Guild は Web Workers (JavaScript) のようなもの
- Isolated Blocks : 外側の環境を引き継がないブロック

- I/O ボトルネック
- node.js はシングルスレッド
- Fast VM, ノンブロッキング I/O
- AutoFiber (or Whatever) : 名前が決まらない
- 時間で勝手に切り替わらないので Thread より簡単
- 現在の Thread は段階的に廃止できる
- I Regret Adding Threads
- 正しく使うのが難しい、効果的に使うのが難しい、デバッグが難しい
- Guild (Isolates), AutoFiber (AsyncWhatever)
- Easy to use, Easy to debug, Easy to perform
- Go: goroutine, Elixir: process などは1種類しかない
- 最初から Concurrency 言語として設計しなかったので使い分けるしかない
- みなさんの意見を歓迎

- Ruby3
- 互換性も維持したい

- 3.0 では諦めたもの
- Frozen String Literals : ruby 3.0 ではデフォルトにするのは諦めた
- Obsolete '?' Literals
- Obsolete Backqoutes
- Keyword argument は変える
- (一個見逃し?)
- Numbered parameters : I know it's controversial
- Pattern matching : case in

- We need to survive
- すでに ruby で書かれたものがたくさんあるから、 ruby が好きだから
- みなさんは他の言語にいくということができるが、 matz や一部のコミッターは仕事でやっているので困る
- We Will Keep Moving Forward
- Wisely
- 闇雲に前に進むのではなく、賢く前に進みたい
- 間違えると些細な機能でも使っている人がいるので直しづらい
- 決まる前に言って欲しい
- ただし投票は受け付けません
- To Make the World Better Place

- (西島(@yuki24)さん) `obj::method` を地上げして、将来 `.:` を置き換えるというのはどうか? → 同じ文法で別の意味になるのは厳しそう
- (聞き取れず)
- メタプログラミングの型チェックは対応予定なし?
- retire 予定はない?
- (joker1007 さん) 関数型プログラミングサポート関連 順番を変えるとか → curry 以外は今のところない
- rdoc? → 型の記述の点で rdoc より YARD

## 福岡県知事

英語で話をしていた。
観光案内の他に mruby の話などもしていた。

## Ruby 3 Progress Report

- Static analysis
- 1 Type signature format
- Steep の型定義フォーマットがベースなので Day 3 の soutaro さんの発表
- 2 Level-1 type checking tool
- Day 1 午後に mame さんの発表
- 3 Type signature prototyping tool
- Day 1 午後に mame さんの発表
- 4 Level-2 type checking tool
- Day 2 stripe チーム (Sorbet) 、 Day 3 の soutaro さん (Steep) の発表

- JIT / Ruby 3x3 <!-- FIXME / . -->
- MJIT が 2.6 に入った
- MIR
- send-pop : day 3 うらべさん
- compacting GC : day 1 Aaron さん
- Write a Ruby interpreter in Ruby for Ruby 3 : day 1 ささださん

- Concurrency
- Matz keynote
- Guild : day 1 ささださん
- Auto-fibers : day 1 Samuel さん

- Other features
- Pattern matching : day 1 Tsujimoto さん
- RubyGems and Bundler Integration : day 2ではなく3 hsbt さん
- bundler は rubygems にマージ
- RubyGems.org で MFA (多要素認証) を設定しましょう
- bootstrap-sass で実際に問題が起きている

- No talk topics
- deprecated にしないもの
- Numbered parameters for Ruby 2.7
- `3.times{|i,| p i }` と `3.times{ p @1 }` が同じ (`|i|` ではない)
- `@` は twitter で使いにくい
- Keyword Arguments in Ruby 3
- 時間があるので背景を説明

## ランチタイム

屋台でうどんを食べて、2Fのスポンサーブースを回っていました。

## Terminal Editors For Ruby Core Toolchain

- いつもの長めの自己紹介タイム
- ブラックモンブラン
- 怪我の話からエディターの話へ
- GNU Readline
- Reline
- Win32 API を使って Windows サポート
- ANSI escape code の説明
- Win32 API の Console Functions を Fiddle 経由で使う
- Unicode サポートは大変
- 例えばキリル文字が gnome-terminal 上での表示幅が設定依存
- Terminal ninja
- emacs mode と vi mode があるので2つのエディターを作るようなもの
- vi mode ユーザーが5人いた。他の会場でのアンケートも合わせると世界で10人はいる。
- keiju さんの Reidline は昨日複数行に対応
- エディターが3つ : Textbringer, Reline (emacs mode), Reline (vi mode)

## Pragmatic Monadic Programing in Ruby

Cafe Nekonoya でコーヒーを待っていたら遅くなってしまって、途中から聞いていました。
`<<=` を使ってる人はいないだろうということで置き換えるという話のところでアンケートをとってみたら使っている人は一人いた。

## Afternoon break

5Fのスポンサーブースを回っていました。

## A Type-level Ruby Interpreter for Testing and Understanding

- 型注釈がないコードが対象
- 目的はテストと理解
- Type Profiler の解説
- デモのソースは <https://github.com/mame/ruby-type-profiler>
- ターミナルで動かしてもわかりにくいのでスライドで解説
- Type Profiler はプログラマの意図とは違う可能性がある
- 実際に動いた型になる
- 再帰にも対応
- send とか組合せ爆発とか
- 絶賛開発中
- 実装について
- 未実装なものがまだ多い
- 自分実施に適用
- optcarrot に適用
- 参考プロダクト
- まとめ

## Fibers Are the Right Solution

- なぜスケーラビリティは大切なのか?
- パフォーマンスの数字
- 並行とか並列とか
- Ruby をはやくしても Blocking のところが遅いままだと意味がない
- マルチプロセス、マルチスレッド
- GIL
- どのくらい作れるか
- 大量のロングランニングコネクション、大量の WebSocket
- Callback Hell
- Async/Await Hell
- Fiber はどうか
- スタックとインストラクションポインタは無くなっていない
- ファイバーとブロッキング I/O
- <https://github.com/socketry/async>
- スレッドよりファイバーの方が良いという話

## Pattern matching - New feature in Ruby 2.7

- experimental で trunk に入った case in の話
- 概要
- パターン紹介
- Array Pattern と RubyVM::AST との組み合わせ例
- Hash Pattern のハッシュのキーは今のところ Symbol だけ
- `deconstruct_keys` で引数の keys の利用は4個以下ぐらいだと nil の時に返すものをそのまま返した方が速かった
- 互換性の話
- 名前は gem-codesearch で調査して大丈夫だろうと決めたがより良い名前があれば提案すると良さそう
- Ruby っぽさ
- Array pattern は Exact match がデフォルト
- Hash pattern は Subset match がデフォルト
- 空ハッシュに対する挙動
- ダックタイピングしやすい
- Future work

## RubyKaigi 2019 Official Party

商店街貸切でした。
会いたい人がいてもいるかどうかもわからないし、人探しも難しいので、いたっぽい人を探すことはあっても、基本はその場であった知ってる人と話をすることが多かったです。
オープニングとクロージングはちょっとだけみましたが、あの辺りにいないとやっていることさえ気づかないような感じでした。
