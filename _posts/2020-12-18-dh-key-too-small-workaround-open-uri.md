---
layout: post
title: "Debianのrubyのopen-uriでdh key too smallになる問題に対処した"
date: 2020-12-18 23:30 +0900
comments: true
category: blog
tags: ruby debian
---
Debian GNU/Linux 10 (buster) の OpenSSL 1.1.1d の環境だと一部のサイトで「dh key too small」になってつながらないのですが、 ciphers に `DEFAULT:!DH` を設定するとつながるので、 open-uri 経由でも ciphers を設定したかったというのが発端です。

<!--more-->

## 動作確認環境

- Debian GNU/Linux 10 (buster)
- ruby 2.5.5p157 (2019-03-15 revision 67260) [x86_64-linux-gnu]
- OpenSSL 1.1.1d  10 Sep 2019

## 現象

[Feature #17173: open-uri で ciphers を設定したい - Ruby master - Ruby Issue Tracking System](https://bugs.ruby-lang.org/issues/17173) に書いたのですが、
以下のようにデフォルトの ciphers だと不適切なものが選ばれてしまって接続できなくて、 `DEFAULT:!DH` で `DH` を除外すると接続できます。

```console
% curl --head https://www.famitsu.com/
curl: (35) error:141A318A:SSL routines:tls_process_ske_dhe:dh key too small
zsh: exit 35    curl --head https://www.famitsu.com/
% curl --ciphers 'DEFAULT:!DH' --head https://www.famitsu.com/
HTTP/1.1 200 OK
Server: nginx/1.12.2
Date: Wed, 16 Sep 2020 04:48:25 GMT
Content-Type: text/html
Connection: keep-alive
Vary: Accept-Encoding
Accept-Ranges: bytes
Vary: Accept-Encoding
Strict-Transport-Security: max-age=60
```

ruby だと open-uri 経由だと ciphers の設定ができないのですが、
`Net::HTTP` を直接使うと設定できます。

```console
% ruby -r open-uri -e 'open("https://www.famitsu.com/")'
Traceback (most recent call last):
        13: from -e:1:in `<main>'
        12: from /usr/lib/ruby/2.5.0/open-uri.rb:35:in `open'
        11: from /usr/lib/ruby/2.5.0/open-uri.rb:735:in `open'
        10: from /usr/lib/ruby/2.5.0/open-uri.rb:165:in `open_uri'
         9: from /usr/lib/ruby/2.5.0/open-uri.rb:224:in `open_loop'
         8: from /usr/lib/ruby/2.5.0/open-uri.rb:224:in `catch'
         7: from /usr/lib/ruby/2.5.0/open-uri.rb:226:in `block in open_loop'
         6: from /usr/lib/ruby/2.5.0/open-uri.rb:755:in `buffer_open'
         5: from /usr/lib/ruby/2.5.0/open-uri.rb:337:in `open_http'
         4: from /usr/lib/ruby/2.5.0/net/http.rb:909:in `start'
         3: from /usr/lib/ruby/2.5.0/net/http.rb:920:in `do_start'
         2: from /usr/lib/ruby/2.5.0/net/http.rb:985:in `connect'
         1: from /usr/lib/ruby/2.5.0/net/protocol.rb:44:in `ssl_socket_connect'
/usr/lib/ruby/2.5.0/net/protocol.rb:44:in `connect_nonblock': SSL_connect returned=1 errno=0 state=error: dh key too small (OpenSSL::SSL::SSLError)
zsh: exit 1     ruby -r open-uri -e 'open("https://www.famitsu.com/")'
% ruby -r net/http -e 'http=Net::HTTP.new("www.famitsu.com", 443); http.use_ssl=true; http.ciphers="DEFAULT:!DH"; p http.get("/")'
#<Net::HTTPOK 200 OK readbody=true>
```

## workaround 作成

[nadoka さん](https://github.com/nadoka/nadoka) の title bot で実際に困っているので、
なんとかしたかったのですが、 open-uri の実装をみていて、
`http.use_ssl =` の呼び出しのところをフックして設定すれば良さそうと気付いたので、
以下のように対処することにしました。

```ruby
require 'net/http'
Net::HTTP.prepend Module.new {
  def use_ssl=(flag)
    super
    self.ciphers = "DEFAULT:!DH"
  end
}
```

## 実行例

以下の実行例のように読み込めるようになりました。

```console
% cat t.rb
require 'open-uri'
require 'net/http'
Net::HTTP.prepend Module.new {
  def use_ssl=(flag)
    super
    self.ciphers = "DEFAULT:!DH"
  end
}
uri = URI("https://www.famitsu.com/")
puts uri.read[0..100]
% ruby t.rb
<!DOCTYPE html>
<html lang="ja">
    <head>
        <meta charset="utf-8">
<meta name="format-detecti
```

## 感想

困っているものには回避策は入れましたが、
ちゃんと対応するのはどうするのがいいのか悩ましいです。

今回の問題自体は、
時間が経てば OS のバージョンアップで openssl などのバージョンがあがって解決するかもしれないし、
この openssl との相性の悪い設定の Web サーバーがなくなっていって解決するかもしれません。

そう考えると open-uri で設定できるようになっても、
Debian の安定版のパッケージとして使えるころには不要な機能になっている可能性も高いです。
もしかすると他の相性の悪い設定が生まれて、その回避に使える可能性もあります。

[チケット Feature #17173](https://bugs.ruby-lang.org/issues/17173)では ciphers の設定だけなら open-uri に追加しても良いという返事があったのですが、
他のパラメーターも設定したくなる可能性を考えると ciphers の追加だけでいいのか、
ciphers だけでも設定できるようにしてもらった方がいいのかが判断できていません。

YAGNI  という言葉があることも考えると、不要な可能性が高いかも、
と思って pull request は作成できずに止まっています。
