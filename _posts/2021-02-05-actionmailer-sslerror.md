---
layout: post
title: "ActionMailerでのSSLErrorの解決方法"
date: 2021-02-05 20:30 +0900
comments: true
category: blog
tags: ruby
---
最近 Implicit TLS で Submission port に接続してエラーになって送信できない、という話を複数みかけたので、
そういうときに使えるように、多少まとまった解説を書いておきます。

<!--more-->

## 用語

- Implicit TLS (暗黙的な TLS) : 接続開始直後から暗号化通信を始める方式です。
- Explicit TLS (明示的な TLS) : 一度平文で接続した後、 STARTTLS などで暗号化通信に切り替える方式です。

## HTTP の場合

わかりやすいので HTTP の場合を先に紹介しておくと、 80/tcp の HTTP は平文で、 443/tcp の HTTPS が Implicit TLS になります。
HTTP では Explicit TLS は一般には使われていません。

## SMTP の場合

- Implicit TLS: 465/tcp が使われます。 smtps ポートと呼ばれたり submissions や ssmtp と呼ばれることもあるようです。(RFC8314)
- Explicit TLS: 25/tcp, 587/tcp が使われます。 25/tcp は smtp で昔からサーバー間の配送などにも使われているポートで、 587/tcp は submission ポートと呼ばれ、主にユーザーからサーバーへメールを送信するときに使われるポートです。平文で接続して、サーバーが対応している機能一覧に STARTTLS が入っているときに STARTTLS コマンドで TLS 接続に切り替えられます。

## ActionMailerでの設定

[Configuration options](https://api.rubyonrails.org/classes/ActionMailer/Base.html#class-ActionMailer::Base-label-Configuration+options)
の `smtp_settings` に書いてあるように、
`enable_starttls_auto` はデフォルトが `true` なので、
Explicit TLS の設定例としては、

```ruby
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  domain: 'example.com',
  user_name: 'ユーザー名',
  password: 'パスワード',
  authentication: :login, # or :plain, :cram_md5
  #enable_starttls_auto: true, # default: true
  openssl_verify_mode: 'peer', # or 'none'
}
```

になります。

authentication が login か plain かはサーバーによって違うので、どちらを使えば良いのかの案内がない場合は両方試して使えた方にします。
cram_md5 は平文でパスワードを流さないための方式で、サーバー側にも平文でパスワードを持っておく必要があって、最近ではほぼ使われていません。

ここに `tls: true` や `ssl: true` などが入っていると Implicit TLS での接続になってしまって、
`enable_starttls_auto` の設定がきかなくなります。

最近みかけた例では `tls: 587` や `ssl: 465` のようなポート番号を設定しようとしているような間違いもありましたが、
これらも真になるので、 Implicit TLS になってしまい、接続エラーになります。

Implicit TLS の設定例としては、

```ruby
config.action_mailer.smtp_settings = {
  address: 'smtp.example.net',
  port: 465,
  domain: 'example.com',
  user_name: 'ユーザー名',
  password: 'パスワード',
  authentication: :login, # or :plain, :cram_md5
  openssl_verify_mode: 'peer', # or 'none'
  tls: true, # or ssl: true
}
```

になります。

## STARTTLS

直接 telnet で平文で接続して `EHLO` コマンドで確認すると、サーバーの応答に `STARTTLS` が入っているのが確認できます。

これをみて、 `STARTTLS` による Explicit TLS にするかどうかを決めるのが `enable_starttls_auto` なので、
`enable_starttls_auto` は最初から暗号化接続しようとする Implicit TLS では意味がない設定になります。

```text
$ telnet smtp.gmail.com 587
Trying XXXX:XXXX:XXXX:XXXX::XX...
Connected to smtp.gmail.com.
Escape character is '^]'.
220 smtp.gmail.com ESMTP xxxxxxxxxxxxxx.xx - gsmtp
EHLO example.com
250-smtp.gmail.com at your service, [XXXX:XXXX::XXXX:XXXX]
250-SIZE 35882577
250-8BITMIME
250-STARTTLS
250-ENHANCEDSTATUSCODES
250-PIPELINING
250-CHUNKING
250 SMTPUTF8
QUIT
221 2.0.0 closing connection xxxxxxxxxxxxxx.xx - gsmtp
Connection closed by foreign host.
```

## Explicit TLS 用のポート (submission ポート) に Implicit TLS (SMTPS) で接続した場合

OS によって多少エラーが違うようですが、接続時にエラーになります。

Ubuntu 20.04.2 LTS の場合:

```console
$ curl smtps://smtp.gmail.com:587/
curl: (35) error:1408F10B:SSL routines:ssl3_get_record:wrong version number
```

macOS Catalina 10.15.7 の場合:

```console
% curl smtps://smtp.gmail.com:587/
curl: (35) error:1400410B:SSL routines:CONNECT_CR_SRVR_HELLO:wrong version number
```

## openssl s_client での確認例

Explicit TLS 用のポート (submission ポート) に Implicit TLS (SMTPS) で接続するとエラーになります。

```console
$ openssl s_client -connect smtp.gmail.com:587
CONNECTED(00000003)
139901029647680:error:1408F10B:SSL routines:ssl3_get_record:wrong version number:../ssl/record/ssl3_record.c:331:
---
no peer certificate available
---
No client certificate CA names sent
---
SSL handshake has read 5 bytes and written 306 bytes
Verification: OK
---
New, (NONE), Cipher is (NONE)
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
---
```

Explicit TLS 用のポート (submission ポート) に STARTTLS で接続すると正しく繋がります。

```console
$ openssl s_client -connect smtp.gmail.com:587 -starttls smtp
CONNECTED(00000003)
depth=2 OU = GlobalSign Root CA - R2, O = GlobalSign, CN = GlobalSign
verify return:1
depth=1 C = US, O = Google Trust Services, CN = GTS CA 1O1
verify return:1
depth=0 C = US, ST = California, L = Mountain View, O = Google LLC, CN = smtp.gmail.com
verify return:1
---
Certificate chain
 0 s:C = US, ST = California, L = Mountain View, O = Google LLC, CN = smtp.gmail.com
   i:C = US, O = Google Trust Services, CN = GTS CA 1O1
 1 s:C = US, O = Google Trust Services, CN = GTS CA 1O1
   i:OU = GlobalSign Root CA - R2, O = GlobalSign, CN = GlobalSign
---
Server certificate
-----BEGIN CERTIFICATE-----
(略)
-----END CERTIFICATE-----
subject=C = US, ST = California, L = Mountain View, O = Google LLC, CN = smtp.gmail.com

issuer=C = US, O = Google Trust Services, CN = GTS CA 1O1

---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: ECDSA
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 2896 bytes and written 419 bytes
Verification: OK
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 256 bit
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
---
250 SMTPUTF8
QUIT
DONE
```

## ruby net/smtp での接続失敗確認例

上記の環境では以下のように試しても `SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)` になりましたが、
別の環境で試してみると `SSL_connect returned=1 errno=0 state=SSLv2/v3 read server hello A: unknown protocol (OpenSSL::SSL::SSLError)` になる環境もあったので、環境やバージョンによって、 Explicit TLS 用のポート (submission ポート) に Implicit TLS (SMTPS) で接続した場合のエラーが違うことがあるようです。

```console
$ ruby -r net/smtp -e 'smtp = Net::SMTP.new("smtp.gmail.com", 587); smtp.enable_tls; p smtp.start{}'
Traceback (most recent call last):
        5: from -e:1:in `<main>'
        4: from ...../lib/ruby/2.7.0/net/smtp.rb:518:in `start'
        3: from ...../lib/ruby/2.7.0/net/smtp.rb:552:in `do_start'
        2: from ...../lib/ruby/2.7.0/net/smtp.rb:584:in `tlsconnect'
        1: from ...../lib/ruby/2.7.0/net/protocol.rb:44:in `ssl_socket_connect'
...../lib/ruby/2.7.0/net/protocol.rb:44:in `connect_nonblock': SSL_connect returned=1 errno=0 state=SSLv2/v3 read server hello A: unknown protocol (OpenSSL::SSL::SSLError)
```

## 認証エラー

以下のようにユーザー名とパスワードを適当に指定すると `535-5.7.8 Username and Password not accepted. Learn more at (Net::SMTPAuthenticationError)` になりました。
エラーメッセージの部分はサーバーからの応答がそのまま入っているようなので、接続先によって変わってくると思います。
自前の postfix のサーバーだと `535 5.7.8 Error: authentication failed:  (Net::SMTPAuthenticationError)` でした。

```text
ruby -r net/smtp -e 'smtp = Net::SMTP.new("smtp.gmail.com", 587); smtp.enable_starttls_auto; p smtp.start{smtp.auth_login "user","pass"}'
ruby -r net/smtp -e 'smtp = Net::SMTP.new("smtp.gmail.com", 587); smtp.enable_starttls_auto; p smtp.start{smtp.auth_plain "user","pass"}'
```

## Implicit TLS 用のポート に Explicit TLS で接続した場合

応答待ちで止まってしまうようなので、実際にはタイムアウト待ちになるか、手動で止めることになりそうです。

## firewall などで塞がれている場合

Connection refused などの一般的なエラーになります。

```console
$ curl smtps://smtp.gmail.com:587/
curl: (7) Failed to connect to smtp.gmail.com port 587: Connection refused
```

## 参考

- [STARTTLS とは。SSL と TLS と STARTTLS の違い - wjmax blog](http://wjmax.hateblo.jp/entry/2017/01/22/152854)
- [SSL (TLS) 対応プロトコルのリスト - Qiita](https://qiita.com/n-i-e/items/e7fdb3ac64a6f172003f)
- [SMTP settings \| GitLab](https://docs.gitlab.com/omnibus/settings/smtp.html#gmail)

GitLab の SMTP settings はいろんなサーバー向けの設定がまとまっていて、
`config.action_mailer.smtp_settings` への読み替えもしやすいのですが、
不要な `gitlab_rails['smtp_tls'] = false` など、冗長な部分もあるようです。
