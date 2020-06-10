---
layout: post
title: "wireguard-dkmsがubuntu 18.04でエラーになったので対処した"
date: 2020-06-10 21:29 +0900
comments: true
category: blog
tags: wireguard ubuntu linux
---
Ubuntu 18.04.4 LTS (bionic) でカーネルが `linux-image-4.15.0-101-generic` から `linux-image-4.15.0-106-generic` に更新されたところ、
`wireguard-dkms` でのカーネルモジュールのビルドが失敗して wireguard での接続ができなくなっていたので、
応急処置をして復旧しました。

<!--more-->

## 動作確認環境

- Ubuntu 18.04.4 LTS (bionic)
- amd64
- `linux-image-4.15.0-106-generic` `4.15.0-106.107`
- `wireguard-dkms` `1.0.20200520-0ppa1~18.04`

## 失敗時のログ

以下のように `compat/compat.h` のエラーで失敗していました。

```console
$ dpkg-reconfigure wireguard-dkms

-------- Uninstall Beginning --------
Module:  wireguard
Version: 1.0.20200520
Kernel:  4.15.0-101-generic (x86_64)
-------------------------------------

Status: Before uninstall, this module version was ACTIVE on this kernel.

wireguard.ko:
 - Uninstallation
   - Deleting from: /lib/modules/4.15.0-101-generic/updates/dkms/
 - Original module
   - No original module was found for this module on this kernel.
   - Use the dkms install command to reinstall any previous module version.

depmod...

DKMS: uninstall completed.

------------------------------
Deleting module version: 1.0.20200520
completely from the DKMS tree.
------------------------------
Done.
Loading new wireguard-1.0.20200520 DKMS files...
Building for 4.15.0-101-generic 4.15.0-106-generic
Building initial module for 4.15.0-101-generic
Done.

wireguard:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/4.15.0-101-generic/updates/dkms/

depmod...

DKMS: install completed.
Building initial module for 4.15.0-106-generic
ERROR: Cannot create report: [Errno 17] File exists: '/var/crash/wireguard-dkms.0.crash'
Error! Bad return status for module build on kernel: 4.15.0-106-generic (x86_64)
Consult /var/lib/dkms/wireguard/1.0.20200520/build/make.log for more information.
$ cat /var/lib/dkms/wireguard/1.0.20200520/build/make.log
DKMS make.log for wireguard-1.0.20200520 for kernel 4.15.0-106-generic (x86_64)
Wed Jun 10 08:34:05 EDT 2020
make: Entering directory '/usr/src/linux-headers-4.15.0-106-generic'
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/main.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/noise.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/peer.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/device.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/timers.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/queueing.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/send.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/receive.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/socket.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/peerlookup.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/allowedips.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/ratelimiter.o
  CC [M]  /var/lib/dkms/wireguard/1.0.20200520/build/cookie.o
In file included from <command-line>:0:0:
/var/lib/dkms/wireguard/1.0.20200520/build/socket.c: In function ‘send6’:
/var/lib/dkms/wireguard/1.0.20200520/build/compat/compat.h:102:42: error: ‘const struct ipv6_stub’ has no member named ‘ipv6_dst_lookup’; did you mean ‘ipv6_dst_lookup_flow’?
 #define ipv6_dst_lookup_flow(a, b, c, d) ipv6_dst_lookup(a, b, &dst, c) + (void *)0 ?: dst
                                          ^
/var/lib/dkms/wireguard/1.0.20200520/build/socket.c:139:20: note: in expansion of macro ‘ipv6_dst_lookup_flow’
   dst = ipv6_stub->ipv6_dst_lookup_flow(sock_net(sock), sock, &fl,
                    ^~~~~~~~~~~~~~~~~~~~
scripts/Makefile.build:330: recipe for target '/var/lib/dkms/wireguard/1.0.20200520/build/socket.o' failed
make[1]: *** [/var/lib/dkms/wireguard/1.0.20200520/build/socket.o] Error 1
make[1]: *** Waiting for unfinished jobs....
Makefile:1577: recipe for target '_module_/var/lib/dkms/wireguard/1.0.20200520/build' failed
make: *** [_module_/var/lib/dkms/wireguard/1.0.20200520/build] Error 2
make: Leaving directory '/usr/src/linux-headers-4.15.0-106-generic'
```

## 修正差分適用

<https://git.zx2c4.com/wireguard-linux-compat/commit/?id=e24c9a9265af40781fa27b5de11dd5b78925c5be>
で修正されているので、
`/usr/src/wireguard-1.0.20200520/compat/compat.h`
に適用して、ビルドし直せば解決します。

応急処置として、パッケージでインストールされているファイルを直接変更してしまいます。
`wireguard-dkms` のバージョンアップで修正済みのファイルに置き換えられることを期待しています。

```console
$ curl https://git.zx2c4.com/wireguard-linux-compat/patch/?id=e24c9a9265af40781fa27b5de11dd5b78925c5be | sudo sh -c 'cd /usr/src/wireguard-1.0.20200520 && patch -p2'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2550    0  2550    0     0   3144      0 --:--:-- --:--:-- --:--:--  3140
patching file compat/compat.h
$ sudo dkms install -m wireguard -v 1.0.20200520 -k 4.15.0-106-generic

Kernel preparation unnecessary for this kernel.  Skipping...

Building module:
cleaning build area.......
make -j4 KERNELRELEASE=4.15.0-106-generic -C /lib/modules/4.15.0-106-generic/build M=/var/lib/dkms/wireguard/1.0.20200520/build...........................
cleaning build area...

DKMS: build completed.

wireguard.ko:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/4.15.0-106-generic/updates/dkms/

depmod...........................................................................................................

DKMS: install completed.
```

すでに `4.15.0-106-generic` で起動している場合は、
`sudo dpkg-reconfigure wireguard-dkms`
でも大丈夫でした。

そしてモジュールがビルドできたら、
`sudo systemctl start wg-quick@wg0`
か
`sudo wg-quick up wg0`
などで起動できるか確認します。

## 感想

wireguard が使っているカーネルの機能の一部がバックポートの影響を受けやすいらしく、
同じようなビルドの失敗が繰り返されていて、
不便なことがたまに起きていましたが、
Ubuntu 20.04 からはカーネル本体に wireguard が入っていて、
`wireguard-dkms` で問題が起きることはないのと、
該当する修正差分の付近のバージョン分岐で 18.04 だけ抜けていたのが追加されたようなので、
今後は大丈夫なのではないかと思っています。
