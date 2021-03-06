---
layout: post
title: "RubyKaigi 2018の3日目に参加しました"
date: 2018-06-02 09:45 +0900
comments: true
category: blog
tags: event ruby rubykaigi
---
[RubyKaigi 2018](http://rubykaigi.org/2018/) の3日目に参加したので、
そのメモです。

発表資料へのリンクは
るびまの[RubyKaigi 2018 直前特集号](https://magazine.rubyist.net/articles/prerubykaigi2018/preRubyKaigi2018-index.html)
が RubyKaigi 2018 後にも更新されていて、非常に便利です。

<!--more-->

## DRECOM のスポンサーセッション

## Parallel and Thread-Safe Ruby at High-Speed with TruffleRuby

partial evaluation がすごかった。

JIT があると C 実装のメソッドを Ruby で書き直すと速くなることもあるんだろうか、
と思って見ていました。
(後の k0kubun さんのセッションでそういう話もありました。)

実装は大変そうだけど、中で自動でやってくれるのは良さそうでした。
prallel の共有オブジェクトとか int だけしか入ってない配列から他のオブジェクトを入れると Object 用の配列とか。

## IRB Reboot: Modernize Implementation and Features

- [Feature #14683: IRB with Ripper - Ruby trunk - Ruby Issue Tracking System](https://bugs.ruby-lang.org/issues/14683)
- [Feature #14787: Show documents when completion - Ruby trunk - Ruby Issue Tracking System](https://bugs.ruby-lang.org/issues/14787)
- `--no-document` を 2.6 からは外すと便利になる
- 2.5 まではインストールが速くなるからつけた方がいいんじゃないかなという話

現状の trunk の irb のネストの認識がおかしくなるエッジケースの例:

```ruby
case 5
when 3..
  puts(true)
else
  puts(false)
end
```

`puts(true)` の行で `*` になるのは行継続の意味なのでバグっている、
と発表中では言っていましたが、
`when (3..)` にしないと endless range にならなくて
`3..puts(true)` という range になるので、
正しかったようです。

## The Method JIT Compiler for Ruby 2.6

MJIT の現状報告でした。

- 質疑応答
  - Visual Studio 対応の話 → preview3 までには
  - 1個の so で 2M って多すぎ? → 詳細はあとで議論

## LuaJIT as a Ruby backend.

## How happy they became with H2O/mruby, and the future of HTTP

- mruby で h2o の設定の話
- 103 Early Hints と 425 Too Early

## Afternoon Break

## Three Ruby performance projects

## TRICK 2018 (FINAL)

- 警告網羅に挑戦すると面白いかも
- 予約語並べ替えも頑張れば挑戦できそう

## Closing

- 1,017 Attendees = 千台
- Next: Fukuoka, Apr 18th(thu)-20th(sat)

## After Party

騒がしくて会話はしにくかったのですが、
面識のなかった人とも話せてよかったです。

途中から akr さんの話があったり、
nobu さんのライブコミットがあったりして楽しめました。

あの[謎コミット](http://d.hatena.ne.jp/nagachika/20180602/ruby_trunk_changes_63545_63557#r63557)で
本当に `make commit` がなおっているのか気になります。
