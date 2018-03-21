---
layout: post
title: "Linux Kernel勉強会　2018年3月に参加しました"
comments: true
category: blog
tags: event linux-kernel
---
[Linux Kernel勉強会　2018年3月](https://linux-kernel.connpass.com/event/78175/)
に参加しました。

<!--more-->

以下、メモです。

## 全体

最近よく行っている
[本町オープンソースラボ](https://hommachi-open-source-lab.github.io/)
でした。
外にオープンソースラボと書いていないので、入口がわからなくて迷う人が多いようです。

今回は、発表者として登録していた人の発表がキャンセルになって、
代わりにホワイトボードを使った話がありました。

## ネットワークについて

- 外と中
- ハードウェアとソフトウェア
- カーネルとユーザーランド : 特権モードと特権なし
  - → 割り込み処理
  - ← API 呼び出し
- ネットワークとパケット
  - ヘッダ + ペイロード + チェックサム (FCS)
- sudo はカーネルの特権とは無関係
- シリアルが増えてパラレルが減った理由は?
  - → パラレルは到着タイミングを揃えるのが難しくなってクロック周波数を上げられなくなった。単純に線が太いというのもある。
  - PCIe などの PC の内部は調整ができるのでパラレル? シリアルが並んでいる?
- socket API
  - TCP だとパケットは隠されていて、ユーザーランドではファイルと同様のストリームに見える
- カーネルとハードウェアの間はパケットのはず
- Ethernet
- プロセスとスレッド
- OSI参照モデル

## もくもくタイム

しばらくもくもくの時間でした。

## Linux Kernel の code を読んでみよう

- 少し古いデータで1800万行
- 全部読むのは無理
- 動かしながらみることに
- 普通のプログラムならデバッガでみる
- カーネルの場合は別のマシンとかエミュレータ (QEMU) とか
- 環境構築: Buildroot がクロスコンパイラなどのビルドツールチェーンや busybox などを使った rootfs も用意してくれる
- qemu でのデモ
  - cortex-a57
  - gdb オプションと -S オプションで起動途中で止めて接続
- [arm64(aarch64)のLinuxカーネルをQEMU上でgdbデバッグする](https://qiita.com/takeoverjp/items/5df8e17f0c361ecd3563)
- aarch64 の読み方の例: えーあーきろくよん

## linux-insides の翻訳

- https://github.com/0xAX/linux-insides の翻訳
- linux-insides-ja というレポジトリがある?

## シェル

- シェルとは何か
- シェルの種類
- シェルスクリプトを試してみた

## NTP

- MIT の ntp のソースコードをみたり
- adjtimex(2) の man をみたり
- Unix 汎用的なものは adjtime らしい

## arm のブートシーケンスを読む

- arch/arm/boot
- arm/Booting の日本語訳があった
- arch/arm/tools に対応マシン一覧
- ATAG なんとかは ARM Linux Developer の ARM Booting Linux に書いてありそうというところで時間切れ

## inetd

- inetd のソースコードを見ていた
- Internet super-server

## gettimeofday

{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4777519864&linkId=de021da844c460aa86c7176c435c3bed" %}

- [Linuxカーネル「ソースコード」を読み解く (I・O BOOKS)](http://amzn.to/2DIECr4)
- gettimeofday を呼び出すだけのプログラムを strace して呼び出しをたどっていった
- [Buildroot の使い方 - 基本編](https://qiita.com/pu_ri/items/75c80e388c79fe0d3f0b)

## プロセススケジューラー

- [\[試して理解\]Linuxのしくみ ~実験と図解で学ぶOSとハードウェアの基礎知識](http://amzn.to/2FYq4pb)
- sched.c
- taskset で使う core を制限して確認

## IPv6

- OpenVPN 経由で IPv6 接続した話

## クロージング

- [本町オープンソースラボ](https://hommachi-open-source-lab.github.io/)の宣伝
- 次回4/15
