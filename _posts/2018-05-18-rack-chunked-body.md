---
layout: post
title: "Rack で巨大なレスポンスを chunked で返す"
date: 2018-05-18 23:00 +0900
comments: true
category: blog
tags: ruby
---
[[ruby-list:50663]](http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/50663) の問題を確認するのに、
3[GiB](https://ja.wikipedia.org/wiki/%E3%82%AE%E3%83%93%E3%83%90%E3%82%A4%E3%83%88) ぐらいのテキストを返すサーバーが欲しかったので、
[Rack](https://rack.github.io/) で実装してみました。

<!--more-->

## 確認バージョン

- ruby 2.5.1
- rack 2.0.5

## config.ru

body として `Rack::Chunked::Body` を返せば良い感じになるかと思ったら、
`Content-Type` だけだと chunked のサイズなどもダウンロードしたファイルに入ってしまったので、
`Transfer-Encoding` も自前で設定するのが必須のようです。

ダウンロードしたファイルを開くのに困らないように、内容には適当に改行を入れるようにしています。

```ruby
require 'rack/chunked'

megatext = ("a"*1023+"\n")*1024
app = proc do |env|
  [200, {'Content-Type' => 'text/plain', 'Transfer-Encoding' => 'chunked'}, Rack::Chunked::Body.new([megatext].cycle.take(3*1024))]
end

run app
```

カレントディレクトリに `config.ru` を作成して `gem install rack` 済みの状態で rackup で起動できます。

## client.rb

path は無視して巨大ファイルを返すサーバーにしたので、ホスト名とポート以外は元の ruby-list のメールのままにしてみたところ、
再現しました。

```ruby
require 'open-uri'
require 'net/http'

uri = URI('http://localhost:9292/large_file')  # 3Gぐらいのファイル
http = Net::HTTP.new(uri.host, uri.port)
res = http.start {|h|
  h.get(uri)
}
p res
b = res.body                                # 正常の様に見える
open( 'dum.txt' , 'wb' ) { |f|
  f.write( b )
}
```

## 原因

http は関係なくて、 macOS の write(2) で 2GiB 以上を書き込もうとすると EINVAL になるのが原因でした。

Ubuntu 16.04 だとそもそもメモリが swap を足しても 2GiB に満たない環境で試したら 2GiB の文字列を作成しようとしたところで NoMemoryError になってしまいました。
(メモリに余裕のある環境だと書き込みまで問題なくできました。)
