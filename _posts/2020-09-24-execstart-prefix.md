---
layout: post
title: "ExecStartのPrefixについて調べた"
date: 2020-09-24 12:30 +0900
comments: true
category: blog
tags: linux systemd chkbuild
---
`systemd` 240 あたりから `PermissionsStartOnly` は deprecated になっていて、
Prefix (`ExecStart=+` の `+` など) を代わりに使えば良いと twitter で教えてもらったので、
Prefix について調べてみました。

<!--more-->

## 動作確認環境

- Debian GNU/Linux 10 (buster)
- systemd 241-7~deb10u4

buster での動作が
[systemd.service(5)](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
の「Table 1. Special executable prefixes」での説明と違うようだったので、
sid でも確認してみました。

- Debian GNU/Linux bullseye/sid (unstable)
- systemd 246.6-1

## 確認用 unit /etc/systemd/system/hoge.service

```
[Service]
Type=oneshot
ExecStartPre=/bin/sh -c "id; pwd; touch /tmp/hoge0; ls -l /tmp"
ExecStartPre=+/bin/sh -c "id; pwd; touch /tmp/hoge1; ls -l /tmp"
ExecStartPre=!/bin/sh -c "id; pwd; touch /tmp/hoge2; ls -l /tmp"
ExecStartPre=+/sbin/runuser -u nobody -- sh -c "id; pwd; touch /tmp/hoge3; ls -l /tmp"
ExecStartPre=!/sbin/runuser -u nobody -- sh -c "id; pwd; touch /tmp/hoge4; ls -l /tmp"
ExecStart=/bin/sh -c "id; pwd; touch /tmp/hoge5; ls -l /tmp"
User=uucp
Group=uucp
WorkingDirectory=/home
PrivateTmp=true
```

## buster での結果

- Prefix なし: `User` で指定した権限で `PrivateTmp` も有効
- Prefix `+`: `root` 権限で `PrivateTmp` は有効 (ドキュメントでの説明と違う)
- Prefix `!`: `root` 権限で `PrivateTmp` は有効
- Prefix `!!`: 実行例には入れていませんが `User` で指定した権限で `PrivateTmp` も有効

```
Sep 24 03:43:07 buster32 systemd[1]: Starting hoge.service...
Sep 24 03:43:07 buster32 sh[7608]: uid=10(uucp) gid=10(uucp) groups=10(uucp)
Sep 24 03:43:07 buster32 sh[7608]: /home
Sep 24 03:43:07 buster32 sh[7608]: total 0
Sep 24 03:43:07 buster32 sh[7608]: -rw-r--r-- 1 uucp uucp 0 Sep 24 03:43 hoge0
Sep 24 03:43:07 buster32 sh[7612]: uid=0(root) gid=0(root) groups=0(root),10(uucp)
Sep 24 03:43:07 buster32 sh[7612]: /home
Sep 24 03:43:07 buster32 sh[7612]: total 0
Sep 24 03:43:07 buster32 sh[7612]: -rw-r--r-- 1 uucp uucp 0 Sep 24 03:43 hoge0
Sep 24 03:43:07 buster32 sh[7612]: -rw-r--r-- 1 root root 0 Sep 24 03:43 hoge1
Sep 24 03:43:07 buster32 sh[7616]: uid=0(root) gid=0(root) groups=0(root),10(uucp)
Sep 24 03:43:07 buster32 sh[7616]: /home
Sep 24 03:43:07 buster32 sh[7616]: total 0
Sep 24 03:43:07 buster32 sh[7616]: -rw-r--r-- 1 uucp uucp 0 Sep 24 03:43 hoge0
Sep 24 03:43:07 buster32 sh[7616]: -rw-r--r-- 1 root root 0 Sep 24 03:43 hoge1
Sep 24 03:43:07 buster32 sh[7616]: -rw-r--r-- 1 root root 0 Sep 24 03:43 hoge2
Sep 24 03:43:07 buster32 runuser[7620]: pam_unix(runuser:session): session opened for user nobody by (uid=0)
Sep 24 03:43:07 buster32 runuser[7620]: uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)
Sep 24 03:43:07 buster32 runuser[7620]: /home
Sep 24 03:43:07 buster32 runuser[7620]: total 0
Sep 24 03:43:07 buster32 runuser[7620]: -rw-r--r-- 1 uucp   uucp    0 Sep 24 03:43 hoge0
Sep 24 03:43:07 buster32 runuser[7620]: -rw-r--r-- 1 root   root    0 Sep 24 03:43 hoge1
Sep 24 03:43:07 buster32 runuser[7620]: -rw-r--r-- 1 root   root    0 Sep 24 03:43 hoge2
Sep 24 03:43:07 buster32 runuser[7620]: -rw-r--r-- 1 nobody nogroup 0 Sep 24 03:43 hoge3
Sep 24 03:43:07 buster32 runuser[7620]: pam_unix(runuser:session): session closed for user nobody
Sep 24 03:43:07 buster32 runuser[7625]: pam_unix(runuser:session): session opened for user nobody by (uid=0)
Sep 24 03:43:07 buster32 runuser[7625]: uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)
Sep 24 03:43:07 buster32 runuser[7625]: /home
Sep 24 03:43:07 buster32 runuser[7625]: total 0
Sep 24 03:43:07 buster32 runuser[7625]: -rw-r--r-- 1 uucp   uucp    0 Sep 24 03:43 hoge0
Sep 24 03:43:07 buster32 runuser[7625]: -rw-r--r-- 1 root   root    0 Sep 24 03:43 hoge1
Sep 24 03:43:07 buster32 runuser[7625]: -rw-r--r-- 1 root   root    0 Sep 24 03:43 hoge2
Sep 24 03:43:07 buster32 runuser[7625]: -rw-r--r-- 1 nobody nogroup 0 Sep 24 03:43 hoge3
Sep 24 03:43:07 buster32 runuser[7625]: -rw-r--r-- 1 nobody nogroup 0 Sep 24 03:43 hoge4
Sep 24 03:43:07 buster32 runuser[7625]: pam_unix(runuser:session): session closed for user nobody
Sep 24 03:43:07 buster32 systemd[1]: hoge.service: Succeeded.
Sep 24 03:43:07 buster32 systemd[1]: Started hoge.service.
```

## sid での結果

- Prefix なし: `User` で指定した権限で `PrivateTmp` も有効
- Prefix `+`: `root` 権限で `PrivateTmp` は無効 (`systemd-private-*` も見えている)
- Prefix `!`: `root` 権限で `PrivateTmp` は有効
- Prefix `!!`: 実行例には入れていませんが `User` で指定した権限で `PrivateTmp` も有効

```
Sep 24 03:38:36 sid systemd[1]: Starting hoge.service...
Sep 24 03:38:36 sid sh[611]: uid=10(uucp) gid=10(uucp) groups=10(uucp)
Sep 24 03:38:36 sid sh[610]: /home
Sep 24 03:38:36 sid sh[613]: total 0
Sep 24 03:38:36 sid sh[613]: -rw-r--r-- 1 uucp uucp 0 Sep 24 03:38 hoge0
Sep 24 03:38:36 sid sh[615]: uid=0(root) gid=0(root) groups=0(root),10(uucp)
Sep 24 03:38:36 sid sh[614]: /home
Sep 24 03:38:36 sid sh[617]: total 0
Sep 24 03:38:36 sid sh[617]: -rw-r--r-- 1 root root 0 Sep 24 03:38 hoge1
Sep 24 03:38:36 sid sh[617]: drwx------ 1 root root 6 Sep 24 03:38 systemd-private-4b8543de47a64328bbf6b4b7039f2b68-hoge.service-EvYTVg
Sep 24 03:38:36 sid sh[617]: drwx------ 1 root root 6 Sep 24 03:09 systemd-private-4b8543de47a64328bbf6b4b7039f2b68-systemd-logind.service-JeIq6i
Sep 24 03:38:37 sid sh[619]: uid=0(root) gid=0(root) groups=0(root),10(uucp)
Sep 24 03:38:37 sid sh[618]: /home
Sep 24 03:38:37 sid sh[621]: total 0
Sep 24 03:38:37 sid sh[621]: -rw-r--r-- 1 uucp uucp 0 Sep 24 03:38 hoge0
Sep 24 03:38:37 sid sh[621]: -rw-r--r-- 1 root root 0 Sep 24 03:38 hoge2
Sep 24 03:38:37 sid runuser[622]: pam_unix(runuser:session): session opened for user nobody by (uid=0)
Sep 24 03:38:37 sid runuser[624]: uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)
Sep 24 03:38:37 sid runuser[623]: /home
Sep 24 03:38:37 sid runuser[626]: total 0
Sep 24 03:38:37 sid runuser[626]: -rw-r--r-- 1 root   root    0 Sep 24 03:38 hoge1
Sep 24 03:38:37 sid runuser[626]: -rw-r--r-- 1 nobody nogroup 0 Sep 24 03:38 hoge3
Sep 24 03:38:37 sid runuser[626]: drwx------ 1 root   root    6 Sep 24 03:38 systemd-private-4b8543de47a64328bbf6b4b7039f2b68-hoge.service-EvYTVg
Sep 24 03:38:37 sid runuser[626]: drwx------ 1 root   root    6 Sep 24 03:09 systemd-private-4b8543de47a64328bbf6b4b7039f2b68-systemd-logind.service-JeIq6i
Sep 24 03:38:37 sid runuser[622]: pam_unix(runuser:session): session closed for user nobody
Sep 24 03:38:37 sid runuser[627]: pam_unix(runuser:session): session opened for user nobody by (uid=0)
Sep 24 03:38:37 sid runuser[629]: uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)
Sep 24 03:38:37 sid runuser[628]: /home
Sep 24 03:38:37 sid runuser[631]: total 0
Sep 24 03:38:37 sid runuser[631]: -rw-r--r-- 1 uucp   uucp    0 Sep 24 03:38 hoge0
Sep 24 03:38:37 sid runuser[631]: -rw-r--r-- 1 root   root    0 Sep 24 03:38 hoge2
Sep 24 03:38:37 sid runuser[631]: -rw-r--r-- 1 nobody nogroup 0 Sep 24 03:38 hoge4
Sep 24 03:38:37 sid runuser[627]: pam_unix(runuser:session): session closed for user nobody
Sep 24 03:38:37 sid sh[633]: uid=10(uucp) gid=10(uucp) groups=10(uucp)
Sep 24 03:38:37 sid sh[632]: /home
Sep 24 03:38:37 sid sh[635]: total 0
Sep 24 03:38:37 sid sh[635]: -rw-r--r-- 1 uucp   uucp    0 Sep 24 03:38 hoge0
Sep 24 03:38:37 sid sh[635]: -rw-r--r-- 1 root   root    0 Sep 24 03:38 hoge2
Sep 24 03:38:37 sid sh[635]: -rw-r--r-- 1 nobody nogroup 0 Sep 24 03:38 hoge4
Sep 24 03:38:37 sid sh[635]: -rw-r--r-- 1 uucp   uucp    0 Sep 24 03:38 hoge5
Sep 24 03:38:37 sid systemd[1]: hoge.service: Succeeded.
Sep 24 03:38:37 sid systemd[1]: Finished hoge.service.
```

## まとめ

前回の `runuser` で別ユーザーで `git pull` をするという目的では `PrivateTmp` は有効でも無効でもどちらでも良いのですが、
バージョンアップで動作が変わらなさそうなのと、余計な権限はいらないということで、 `!` を使うことにしました。

`PrivateTmp` も含めて完全に分離するなら、別 unit にする必要がありそうです。
今回はそこまでする必要がなさそうなので、 `ExecStartPre` のままにすることにしました。
