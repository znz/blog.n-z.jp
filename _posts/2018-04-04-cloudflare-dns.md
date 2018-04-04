---
layout: post
title: "cloudflareのDNS 1.1.1.1を使うとインターネットが遅くなるかもしれない"
date: 2018-04-04 21:20 +0900
comments: true
category: blog
tags: dns linux
---
DNS の名前解決は速くなるかもしれませんが、その後の接続先が遠くなって遅くなるかもしれません。
プライバシー重視なら切り替えて行っていいかもしれませんが、速度のために切り替えるのはちょっと待ってください。

Google Public DNS も初期の頃は同じ問題があったので、時間が経てば解決するような気がしますが、CDN を使っているサイトが遅くなる可能性があります。

<!--more-->

以下、あるホストからの実測。
ここには結果を載せませんが、traceroute もしてみると、遠くなっているのがわかります。

## DNS の正引き

DNS の応答は速いです。
これはうたい文句通りです。

Query time のところがかかった時間です。

```
% dig www.google.com @1.1.1.1

; <<>> DiG 9.10.3-P4-Ubuntu <<>> www.google.com @1.1.1.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13150
;; flags: qr rd ra; QUERY: 1, ANSWER: 6, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1536
;; QUESTION SECTION:
;www.google.com.                        IN      A

;; ANSWER SECTION:
www.google.com.         54      IN      A       172.217.194.99
www.google.com.         54      IN      A       172.217.194.103
www.google.com.         54      IN      A       172.217.194.104
www.google.com.         54      IN      A       172.217.194.105
www.google.com.         54      IN      A       172.217.194.106
www.google.com.         54      IN      A       172.217.194.147

;; Query time: 1 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; WHEN: Wed Apr 04 21:21:57 JST 2018
;; MSG SIZE  rcvd: 139
% dig www.google.com @8.8.8.8

; <<>> DiG 9.10.3-P4-Ubuntu <<>> www.google.com @8.8.8.8
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 25482
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;www.google.com.                        IN      A

;; ANSWER SECTION:
www.google.com.         299     IN      A       172.217.161.228

;; Query time: 37 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Wed Apr 04 21:22:06 JST 2018
;; MSG SIZE  rcvd: 59
```

## ping 応答

2桁遅いです。
複数帰ってきていた他のIPアドレスも同じくらいでした。

```
% ping -c 5 172.217.194.99
PING 172.217.194.99 (172.217.194.99) 56(84) bytes of data.
64 bytes from 172.217.194.99: icmp_seq=1 ttl=44 time=79.3 ms
64 bytes from 172.217.194.99: icmp_seq=2 ttl=44 time=79.2 ms
64 bytes from 172.217.194.99: icmp_seq=3 ttl=44 time=79.4 ms
64 bytes from 172.217.194.99: icmp_seq=4 ttl=44 time=79.4 ms
64 bytes from 172.217.194.99: icmp_seq=5 ttl=44 time=79.2 ms

--- 172.217.194.99 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4005ms
rtt min/avg/max/mdev = 79.264/79.348/79.441/0.364 ms
% ping -c 5 172.217.161.228
PING 172.217.161.228 (172.217.161.228) 56(84) bytes of data.
64 bytes from 172.217.161.228: icmp_seq=1 ttl=55 time=0.833 ms
64 bytes from 172.217.161.228: icmp_seq=2 ttl=55 time=0.742 ms
64 bytes from 172.217.161.228: icmp_seq=3 ttl=55 time=0.990 ms
64 bytes from 172.217.161.228: icmp_seq=4 ttl=55 time=0.800 ms
64 bytes from 172.217.161.228: icmp_seq=5 ttl=55 time=0.736 ms

--- 172.217.161.228 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4000ms
rtt min/avg/max/mdev = 0.736/0.820/0.990/0.094 ms
```

## まとめ

DNS 応答のような最初の少しの部分が速くなるよりも、実際の通信部分が遅くなる方が影響が大きいと思うので、 1.1.1.1 を使うのはまだ早いかもしれません。

Google Public DNS も初期の頃は同じ問題があったと記憶しているので、 CDN もやっている Cloudflare が対応しないとは思えないので、時間が経てば解決するのではないでしょうか。

## 別のインパクト

IP アドレスで証明書が発行されることはないと思っていたので、 <https://1.1.1.1/> が正規の証明書で繋がるというのに驚きました。

これで DNS over HTTPS の最初の DNS サーバーのホスト名の解決問題が解消するので、 DNS over HTTPS が使われることが増えるかもしれません。
(ちなみに <https://8.8.8.8/> は `CN=*.c.docs.google.com` の証明書で、普通にブラウザーで開くとエラーになるようなので、ちゃんと証明書の検証をする DNS over HTTPS クライアントだと使えなさそうです。)
