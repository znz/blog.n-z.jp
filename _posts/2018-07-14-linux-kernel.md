---
layout: post
title: "Linux Kernel勉強会　2018年7月に参加しました"
date: 2018-07-14 18:39 +0900
comments: true
category: blog
tags: event linux-kernel
---
[Linux Kernel勉強会　2018年7月分](https://linux-kernel.connpass.com/event/92896/)
に参加しました。

今回は発表が充実していました。

<!--more-->

以下、メモです。

## ブートシーケンスの概要

特に資料は用意できなかったので、ホワイトボードに書いて概要を説明してみました。

BIOS や UEFI → ブートローダー (LILO や GRUB など) → kernel, initramfs, cmdline → initramfs の /init → real root の /sbin/init (sysvinit とか systemd とか)
という感じの話をしました。

## Linux kernel 起動前の話

ARM の起動部分の話でした。

- [ARM Trusted Firmware](https://github.com/ARM-software/arm-trusted-firmware)
- <https://github.com/MarvellEmbeddedProcessors/atf-marvell>
- [ARM boot](https://www.ujiya.net/linux/ARM%20boot)

## コンテキストの話

- [Unreliable Guide To Locking](https://github.com/torvalds/linux/blob/2db39a2f491a48ec740e0214a7dd584eefc2137d/Documentation/kernel-hacking/locking.rst)
- Q: ドライバーはどうやって作るの? → 似たようなものを参考にして作る
- SPDK

## initramfs の話

[initramfsについて](https://www.slideshare.net/znzjp/initramfs)を再演してみました。

## respberrypi のブートの話

- [Raspberry Pi boot modes](https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/README.md) ([source](https://github.com/raspberrypi/documentation/blob/4d139bed526f12955c2809b0a146e88b2922ab9a/hardware/raspberrypi/bootmodes/README.md))
- [Boot flow](https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/bootflow.md) ([source](https://github.com/raspberrypi/documentation/blob/4d139bed526f12955c2809b0a146e88b2922ab9a/hardware/raspberrypi/bootmodes/bootflow.md))
- OTP とは? one-time programmable?
- SD の bootcode.bin から起動

## プロセスID、スレッドID

以前の勉強会ではっきりしていなかった部分をちゃんと調べたという話でした。

- プロセス、スレッド、タスク
- task\_struct の pid がスレッドID で tgid がプロセスID
- fork(2) と clone(2)
- fork.c の do\_fork
- getpid(2) と gettid(2) の結果をプログラムを書いて確認
- top コマンドで H キーでスレッド表示して確認
- [clone(2)](https://linuxjm.osdn.jp/html/LDP_man-pages/man2/clone.2.html) の CLONE\_THREAD
- [pthread\_setname\_np](https://linuxjm.osdn.jp/html/LDP_man-pages/man3/pthread_setname_np.3.html)
- [pthread\_self](https://linuxjm.osdn.jp/html/LDP_man-pages/man3/pthread_self.3.html)

## セマフォ

実際のソースコードを引用しながら、実装を追いかけていく話でした。

- カーネルのセマフォの実装を読んでみた話
- Aeronet のドライバーで実際に使われている部分も読んでみた話

## クロージング

時間があれば話をすると言っていたものも含めて、早めに発表が全部終わったので、早めに終わりました。

- 8月は休み (夏休み)
- 次回は2018年9月22日(土)の予定
- テーマ案: yocto (build root)、ドライバーを作ってみよう、情報共有、参考ブログ、バグ披露
