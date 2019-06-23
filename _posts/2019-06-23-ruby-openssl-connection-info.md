---
layout: post
title: "rubyのopensslで接続しているバージョンやcipherや証明書の情報を確認する"
date: 2019-06-23 23:38 +0900
comments: true
category: blog
tags: ruby
---
ruby の openssl で接続している SSL/TLS のバージョンや cipher や接続先の証明書の情報の取り出し方を確認しました。

<!--more-->

## 確認バージョン

- ruby 2.5.5, 2.6.3, 2.7.0-Devi

not_after の取得は ruby 1.9.3 以前から使っているので、確認し直していませんが、古いバージョンでも証明書の取り出しは動くと思います。
ただし 1.9.2 より前のバージョンだと `ssl.hostname=` がないので、そこは動きません。
他の証明書取り出し以外の情報取得部分は古いと動かないかもしれません。

## プログラム例

```ruby
require 'socket'
require 'openssl'

host = ARGV.shift
port = ARGV.shift.to_i

TCPSocket.open(host, port) do |sock|
  ssl = OpenSSL::SSL::SSLSocket.new(sock)
  ssl.sync_close = true
  ssl.hostname = host
  ssl.connect

  p ssl.ssl_version
  p ssl.cipher

  cert = ssl.peer_cert

  ssl.close

  puts cert.to_text
  p cert.not_after
  p cert.issuer
  p cert.subject.to_a.assoc("CN")[1]
end
```

## 実行例

```console
$ ruby s.rb blog.n-z.jp 443
"TLSv1.2"
["ECDHE-RSA-AES128-GCM-SHA256", "TLSv1/SSLv3", 128, 128]
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            03:4b:11:45:e5:2b:16:87:fc:6b:97:ee:11:00:d1:14:3e:73
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, O=Let's Encrypt, CN=Let's Encrypt Authority X3
        Validity
            Not Before: Apr 20 04:10:16 2019 GMT
            Not After : Jul 19 04:10:16 2019 GMT
        Subject: CN=blog.n-z.jp
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:b3:d7:f3:8e:f4:69:9a:6a:80:14:e3:dc:f5:e6:
                    e4:56:9e:fc:db:72:c9:93:e9:49:0b:c7:46:b9:ca:
                    e7:9a:21:ba:e2:e0:b3:7d:5c:dd:7c:fd:22:c2:e1:
                    f7:69:f0:f2:bf:ce:5c:1b:ca:9a:5a:72:19:9d:25:
                    99:00:f6:0d:6b:ee:40:86:ff:82:01:d7:f2:1f:16:
                    36:2f:89:85:78:28:fc:15:41:f3:fb:e8:b5:2c:33:
                    5c:6e:60:4f:13:c7:bd:10:fe:16:21:7c:ff:2e:f9:
                    fe:5e:5f:73:43:a8:38:25:94:23:e0:fb:df:cb:4c:
                    ff:26:48:6a:51:3d:e0:b2:71:67:b5:cd:8d:de:f9:
                    cc:d9:31:d8:ee:43:c8:78:46:8f:11:1e:9e:72:84:
                    2d:78:43:a0:8a:37:5e:48:53:cd:e3:c9:ec:04:fd:
                    28:37:da:d4:2a:17:53:84:ed:17:ac:3e:49:b9:3a:
                    42:b9:fb:90:44:43:73:86:dd:0a:c0:8a:85:ae:67:
                    5c:fa:9e:e8:94:a4:fd:09:dd:d5:39:0d:06:3a:82:
                    e2:12:5a:d5:37:26:62:86:98:56:c9:1d:e7:64:16:
                    e6:43:82:3b:31:bc:10:bb:6f:b6:80:65:9c:46:74:
                    d6:c7:24:5b:02:41:7b:cd:84:1e:90:86:3a:32:c5:
                    ee:6b
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier:
                47:17:D2:64:17:85:F4:76:13:13:43:FB:BC:E9:5B:1B:CC:6E:3C:FB
            X509v3 Authority Key Identifier:
                keyid:A8:4A:6A:63:04:7D:DD:BA:E6:D1:39:B7:A6:45:65:EF:F3:A8:EC:A1

            Authority Information Access:
                OCSP - URI:http://ocsp.int-x3.letsencrypt.org
                CA Issuers - URI:http://cert.int-x3.letsencrypt.org/

            X509v3 Subject Alternative Name:
                DNS:blog.n-z.jp
            X509v3 Certificate Policies:
                Policy: 2.23.140.1.2.1
                Policy: 1.3.6.1.4.1.44947.1.1.1
                  CPS: http://cps.letsencrypt.org

            CT Precertificate SCTs:
                Signed Certificate Timestamp:
                    Version   : v1(0)
                    Log ID    : 74:7E:DA:83:31:AD:33:10:91:21:9C:CE:25:4F:42:70:
                                C2:BF:FD:5E:42:20:08:C6:37:35:79:E6:10:7B:CC:56
                    Timestamp : Apr 20 05:10:16.095 2019 GMT
                    Extensions: none
                    Signature : ecdsa-with-SHA256
                                30:45:02:20:40:19:56:A0:EF:65:15:65:22:9F:32:95:
                                32:59:FA:87:F8:D3:44:8C:0E:09:E3:81:28:9B:5F:D0:
                                E4:16:ED:CF:02:21:00:AB:81:D9:7A:01:0F:21:38:31:
                                DD:12:37:E4:5E:49:9D:72:4B:FA:68:E3:16:07:69:D1:
                                EC:21:D5:E1:CC:6D:46
                Signed Certificate Timestamp:
                    Version   : v1(0)
                    Log ID    : 63:F2:DB:CD:E8:3B:CC:2C:CF:0B:72:84:27:57:6B:33:
                                A4:8D:61:77:8F:BD:75:A6:38:B1:C7:68:54:4B:D8:8D
                    Timestamp : Apr 20 05:10:16.186 2019 GMT
                    Extensions: none
                    Signature : ecdsa-with-SHA256
                                30:46:02:21:00:D3:D4:44:14:2D:CC:7D:86:B7:60:7E:
                                9B:B2:C5:EB:EA:23:13:DC:E7:61:3B:48:86:A2:38:F3:
                                B2:35:6A:53:C4:02:21:00:E6:03:30:CC:67:86:39:7B:
                                29:03:CC:94:4C:C5:25:4F:F0:C3:B8:36:1A:32:CD:BA:
                                F1:AC:7B:6E:A9:4E:2D:63
    Signature Algorithm: sha256WithRSAEncryption
         91:92:0c:c9:24:e5:cb:c8:73:c1:ce:6b:05:ce:56:e7:33:7a:
         e2:a0:af:3d:eb:e9:30:e6:75:42:0c:ed:3f:2a:97:27:7e:4b:
         61:91:a0:8d:de:d8:a4:9a:e2:0d:48:4e:53:38:8e:59:e3:a7:
         95:d0:71:46:47:10:a9:94:bb:8e:da:56:ba:47:a4:29:dd:47:
         3c:cd:f5:55:1e:fc:22:ea:37:da:94:ee:ca:37:c7:8a:db:f5:
         ba:04:28:17:c7:f2:e0:d3:f9:f4:0c:14:bc:48:05:52:ee:4a:
         21:a2:18:ca:e1:e2:53:9d:99:aa:34:0f:02:fd:9d:b5:d3:4b:
         41:9a:1c:96:88:4e:a8:37:d7:96:63:9d:64:c2:d2:3d:e7:4c:
         fc:fc:88:d1:53:ec:d3:77:d8:34:5a:48:9a:78:d0:66:a3:c9:
         6d:d5:13:e3:e1:d8:2b:66:bd:b0:66:75:c9:f1:f1:db:d6:41:
         88:e8:86:9b:2a:0a:d6:ef:9c:5b:a1:db:67:df:e7:16:4c:05:
         aa:17:4e:8b:40:d1:52:45:d2:ac:5b:e9:5f:55:52:98:70:d6:
         c4:3a:a2:89:84:cd:83:f8:c7:6d:11:db:81:74:d6:9e:40:a4:
         50:a7:ff:4c:80:7d:21:e9:ac:3f:ea:74:a1:a1:6c:87:f9:0b:
         c7:ab:da:de
2019-07-19 04:10:16 UTC
#<OpenSSL::X509::Name CN=Let's Encrypt Authority X3,O=Let's Encrypt,C=US>
"blog.n-z.jp"
```

## 解説

### 接続

まず `TCPSocket` を接続して `OpenSSL::SSL::SSLSocket.new` を作成しています。

`SSLSocket` を閉じた時に `TCPSocket` も閉じるように [`sync_close=`](https://docs.ruby-lang.org/ja/latest/method/OpenSSL=3a=3aSSL=3a=3aSSLSocket/i/sync_close=3d.html) で設定しています。
証明書の情報を表示するタイミングではソケットは不要なので、 `peer_cert` で取得した直後に `ssl.close` して閉じています。

[`hostname=`](https://docs.ruby-lang.org/ja/latest/method/OpenSSL=3a=3aSSL=3a=3aSSLSocket/i/hostname=3d.html) で TLS の Server Name Indication(SNI) 拡張のためにホスト名の設定をしています。
昔は設定しなくても大丈夫なことが多かったですが、今はちゃんと設定しないと繋ぎたいホストの証明書にならないことが多いと思います。

### `ssl_version`

`ssl_version` は [`SSL_get_version`](https://www.openssl.org/docs/man1.1.0/man3/SSL_get_version.html) に相当し、
今だとほとんど `"TLSv1.2"` という文字列が返ってきます。

<https://badssl.com/> を使って `ruby s.rb tls-v1-0.badssl.com 1010` や `ruby s.rb tls-v1-1.badssl.com 1011` だと `"TLSv1"` や `"TLSv1.1"` になるのを確認できました。

### `cipher`

[`cipher`](https://docs.ruby-lang.org/ja/latest/method/OpenSSL=3a=3aSSL=3a=3aSSLSocket/i/cipher.html) は [`SSL_get_current_cipher`](https://www.openssl.org/docs/manmaster/man3/SSL_get_current_cipher.html) に相当し、
nil または実際に使われている cipher を表す配列が返ってきます。

`["ECDHE-RSA-AES128-GCM-SHA256", "TLSv1/SSLv3", 128, 128]` の `"TLSv1/SSLv3"` は該当する cipher に最初に対応した SSL/TLS のバージョンで、今接続に使われている SSL/TLS のバージョンではないようです。

cipher の詳細は `openssl ciphers -v` で表示できます。

```console
$ openssl ciphers -v | grep ECDHE-RSA-AES128-GCM-SHA256
ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2 Kx=ECDH     Au=RSA  Enc=AESGCM(128) Mac=AEAD
```

### `peer_cert`

サーバーの証明書は [`peer_cert`](https://docs.ruby-lang.org/ja/latest/method/OpenSSL=3a=3aSSL=3a=3aSSLSocket/i/peer_cert.html) で取得できます。
中間証明書もほしいときは [`peer_cert_chain`](https://docs.ruby-lang.org/ja/latest/method/OpenSSL=3a=3aSSL=3a=3aSSLSocket/i/peer_cert_chain.html) で取得できます。
知らないと間違えて使ってしまいそうな [`cert`](https://docs.ruby-lang.org/ja/latest/method/OpenSSL=3a=3aSSL=3a=3aSSLSocket/i/cert.html) は、クライアント証明書を取得するメソッドで、クライアント証明書は使わないことが多いので、 `nil` が返ってくることがほとんどだと思います。

証明書の `openssl crt -in some.pem -noout -text` 相当のまとまった情報は `to_text` で取得できて、各種情報は情報から連想できるメソッド名で取得できます。

## 最後に

`OpenSSL::SSL::SSLSocket` から SSL/TLS の接続情報を取得する方法を紹介しました。

接続だけして切断すると攻撃とみなされてブロックされる可能性があるので、実際には他の通信のソケットを調べたいことが多いと思います。

たとえば `Net::HTTP` を直接使っていたり、 `open-uri` のように下回りに `Net::HTTP` を使っていたりする場合は、

```
Net::HTTP.prepend Module.new { def do_finish; p @socket.io.ssl_version; super; end }
```

のように適当なところに割り込ませることで情報を取得できるので、必要に応じてやってみると良いと思います。
(上の例は `http` も混ざると `ssl_version` の `NoMethodError` になるので、あくまでも割り込み場所の例です。またバージョンによっても変わる可能性があります。)
