---
layout: post
title: "dehydratedで証明書の更新エラー"
date: 2019-10-03 22:30 +0900
comments: true
category: blog
tags: linux letsencrypt dehydrated
---
2019年9月24日あたりから古い dehydrated で Let's encrypt の証明書が更新できなくなっていたらしく、
[Debian Bug #941414](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=941414) に書いてあるように
`grep` を `grep -i` に変更して解決しました。
以下、その詳細です。

<!--more-->

## 確認バージョン

- Ubuntu 18.04.3 LTS
- dehydrated 0.6.1-2

## エラーメッセージ

同じ問題に引っかかった人が検索で見つけやすいように、 nonce だけ書き換えてエラーメッセージ付近全体を貼り付けておきます。

```
(Less than 30 days). Renewing!
 + Signing domains...
 + Generating private key...
 + Generating signing request...
 + Requesting new certificate order from CA...
  + ERROR: An error occurred while sending post-request to https://acme-v02.api.letsencrypt.org/acme/new-order (Status 400)

Details:
HTTP/2 400
server: nginx
date: Thu, 03 Oct 2019 13:27:03 GMT
content-type: application/problem+json
content-length: 112
boulder-requester: 729354
cache-control: public, max-age=0, no-cache
link: <https://acme-v02.api.letsencrypt.org/directory>;rel="index"
replay-nonce: XXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

{
  "type": "urn:ietf:params:acme:error:badNonce",
  "detail": "JWS has no anti-replay nonce",
  "status": 400
}
```

## 対処方法

`sudoedit /usr/bin/dehydrated` で

```
    nonce="$(http_request head "${CA}" | grep Replay-Nonce: | awk -F ': ' '{print $2}' | tr -d '\n\r')"
```

を

```
    nonce="$(http_request head "${CA}" | grep -i Replay-Nonce: | awk -F ': ' '{print $2}' | tr -d '\n\r')"
```

に書き換えました。

```
    nonce="$(http_request head "${CA_NEW_NONCE}" | grep Replay-Nonce: | awk -F ': ' '{print $2}' | tr -d '\n\r')"
```

も同様に

```
    nonce="$(http_request head "${CA_NEW_NONCE}" | grep -i Replay-Nonce: | awk -F ': ' '{print $2}' | tr -d '\n\r')"
```

に書き換えましたが、参考にしたバグレポートにはこちらは書いていなかったので、不要かもしれません。

## 参考

- [`Trying to understand urn:acme:error:badNonce`](https://community.letsencrypt.org/t/trying-to-understand-urnerror-badnonce/102652)
- [New CDN for the Production API](https://community.letsencrypt.org/t/new-cdn-for-the-production-api/102629)
- [Confconsole Let's Encrypt - badNonce - JWS has no anti-replay nonce](https://github.com/turnkeylinux/tracker/issues/1359)
- [#941414 - dehydrated fails to find nonce - Debian Bug report logs](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=941414)

## 感想

30 日の余裕があるので、ある程度落ち着いて対処できてよかったです。

Debian や Ubuntu の安定版を使っていても、外部サービスに依存しているものは外部サービスの変更で動かなくなることがあるので、
`unattended-upgrades` などを使っていても完全放置はなかなか難しいようです。
