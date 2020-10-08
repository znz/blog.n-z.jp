---
layout: post
title: "ChromiumがInternal Redirectで存在しないURLを開こうとする"
date: 2020-10-07 18:30 +0900
comments: true
category: blog
tags: web
---
とある URL を開こうとしたときに、
Chrome だと開けるのに Chromium や Firefox だと開けないということがありました。

<!--more-->

## 正常な場合

あるサイトから <https://cs.kddi.com/support/login.html> にリンクがあって、
ここは http の my.au.com へのリダイレクトを返してきます。

```
% curl 'https://cs.kddi.com/support/login.html' --head
HTTP/1.1 302 Found
Location: http://my.au.com/rd/csk/support/login.html
Content-Length: 0
Content-Type: text/html; charset=UTF-8
```

http だと、さらに <https://www.au.com/my-au/> にリダイレクトされて、
これが <https://www.kddi.com/terms/requirements/?bid=we-we-ft-0011> の動作環境に書いてあるブラウザーでの動作です。

```
% curl 'http://my.au.com/rd/csk/support/login.html' --head
HTTP/1.1 302 Found
Date: Thu, 08 Oct 2020 11:37:24 GMT
Server: Apache
Location: https://www.au.com/my-au/
Connection: close
Content-Type: text/html; charset=iso-8859-1
```

## 問題がある場合

しかし、 macOS の Chromium や Firefox だとなぜか内部的に https に書き換えてしまうらしく、
notfound のページにリダイレクトされてしまいます。

Chromium のデベロッパーツールでみると、
http から http への書き換えは
「307 Internal Redirect」と出ています。

```
% curl 'https://my.au.com/rd/csk/support/login.html' --head
HTTP/1.1 302 Found
Date: Thu, 08 Oct 2020 11:39:44 GMT
Server: Apache
Location: https://my.au.com/error/notfound.html
Connection: close
Content-Type: text/html; charset=iso-8859-1
```

こちらに飛ばされてしまう環境の場合、
<https://my.au.com/error/notfound.html> は行き止まりなので、
動作環境に入っていないから別のブラウザーなどで試せば良いと気付く手段も用意されていないようです。

## http → https ?

内部的に https に書き換えるといえば HSTS の Preload なので、
[HSTS Preload List](https://hstspreload.org/)
で調べてみましたが、設定されていないようでした。

au.com の方で includeSubDomains になっていて、
それを覚えてしまっているのかとも思いましたが、
それも設定されていませんでした。

## Chromium の謎挙動

Chromium で VPN 経由で自宅サーバーの Zabbix を開きっぱなしにしているのですが、
Chromium を再起動したタイミングで https になってエラーになっていたり、
ローカルの HTML ファイルからそこへのリンクをたどったときに https に書きかわっていることもあったので、
Chromium は何も設定していなくても勝手に http を https に書きかえてしまうことがあるようです。

今回の au の件は再現率 100% なので、ローカルでの挙動とは違うかもしれません。

## Firefox の場合

Firefox は Windows 版だと動作環境に入っていて問題なく正しい方にリダイレクトされるようなので、
さらに謎が深まります。

## au への問い合わせ

URL を含む詳細を含めたかったので、電話ではなくメールかフォームなどで問い合わせしたかったのですが、
問い合わせフォームにたどりつけなかったので、
Twitter で問い合わせてみましたが、そういう窓口ではなさそうなので、反応はないかもしれません。
