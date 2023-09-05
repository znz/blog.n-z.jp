---
layout: post
title: "telnetの電子公告がShift_JISなのでRubyで変換しつつ表示する"
date: 2023-09-05 09:00 +0900
comments: true
category: blog
tags: ruby
---
<https://twitter.com/nunnun/status/1698607615184666947> の telnet による電子公告がトレンドに入っていたのをみかけたので、
macOS の端末の設定を Shift\_JIS にして telnet コマンドで確認した後、
Ruby で UTF-8 の端末のまま確認できるようにプログラムを書いて確認してみました。

<!--more-->

## 動作確認環境

最近の環境ならどこでも動くはずなので、大雑把に書いておきます。

- Linux, macOS
- Ruby 3.1, 3.2

## プログラム

以下の内容を適当なファイルに保存して実行してみてください。

```ruby
#!/usr/bin/ruby
# frozen_string_literal: true

require 'socket'

sock = Socket.tcp('koukoku.shadan.open.ad.jp', 23)
sock.set_encoding(Encoding::SJIS, Encoding::UTF_8)

last_read_time = Time.now
Thread.new do
  sleep 1 while 1 > (Time.now - last_read_time)
  sock.close_write
end

sock.each_char do |c|
  last_read_time = Time.now
  STDOUT.putc c
end
```

## 解説

最初の 4 行は `Socket` を使うためなどのお約束なのでいいとして、
ソケットオブジェクトの作成は `TCPSocket` ではなく `Socket.tcp` を使ってみました。

一番重要なエンコーディングの変換は `sock.set_encoding(Encoding::SJIS, Encoding::UTF_8)` で Ruby に任せています。

次に切断処理用のスレッドを作成しています。
表示が終わったっぽいところで自分で Control+C などで止めるなら不要なのですが、
プログラムにするなら自動で切れた方が良さそうということで、
何も送られてこなくなってそうだったら、
`close_write` で書き込み側を閉じて、
向こうから切断してもらうようにしました。

読み込み部分本体は `each_char` で 1 文字ずつ読んで出力することで、
遅さの演出もそのまま見えるようにしました。

`IO.copy_stream(sock, STDOUT)` だと文字化けしました。

## 感想

重要なのは `set_encoding` と `each_char` のループだけなので、簡単に書けるかなと思ったら、
表示が終わった後に自動で切断されなかったので、その処理で思ったより長くなってしまいました。
