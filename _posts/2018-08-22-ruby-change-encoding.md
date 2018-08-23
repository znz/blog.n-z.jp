---
layout: post
title: "Rubyの文字列のエンコーディングは勝手に変わることがある"
date: 2018-08-22 22:22 +0900
comments: true
category: blog
tags: ruby
---
[String#append without changing receiver's encoding という issue](https://bugs.ruby-lang.org/issues/14975)
に関連した話です。

<!--more-->

## 確認バージョン

- ruby 1.9.0 以降 (開発中の 2.6.0 を含む)

## 現象

以下のように
[String#ascii\_only?](https://docs.ruby-lang.org/ja/latest/method/String/i/ascii_only=3f.html)
が `true` を返すような文字列とそうでない文字列を結合すると、
`ascii_only?` が `false` の文字列の Encoding に変わってしまいます。

具体的には以下のように ASCII のみの文字列に、
それとは違う Encoding (以下の例では UTF-8) で ASCII 外の文字を含む文字列をくっつけると
元の Encoding に関わらず UTF-8 になってしまう、
ということがおきます。
`String#+` のように別 String オブジェクトが作られるときは何の問題もなさそうですが、
`String#<<` などのように元の文字列を破壊的に変更する場合は、
勝手に Encoding が変わってしまうように見えます。

    $ ruby -e 's="".force_encoding("euc-jp");p s.encoding;s<<"\u3042";p s.encoding'
    #<Encoding:EUC-JP>
    #<Encoding:UTF-8>

## 感想

1.9.0 の頃からこういう挙動で、
1.8.x からの移行で何か困ることがあれば報告しようと思っていましたが、
特に何も問題は起きなかったので、
既存のコードにも新規のコードにも影響が少ないように考えられた仕様で、
そういうものだと思っていました。

## 回避策

元の報告者は ascii-8bit のままになっていて欲しかったようで、
現状では
[`StringIO`](https://docs.ruby-lang.org/ja/latest/class/StringIO.html)
を使うのが良さそうという話のようです。
