---
layout: post
title: "Linux Kernel勉強会　2018年4月に参加しました"
comments: true
category: blog
tags: event linux-kernel
---
[Linux Kernel勉強会　2018年4月分](https://linux-kernel.connpass.com/event/83510/)に参加しました。

<!--more-->

以下、メモです。

## スケジューラーについて

<!-- pu_ri さん -->
- CFS, real-time
- スケジューリングポリシー
- nice
  - nice 値が 1 違うと 1.25 倍違う (CPU 時間では 10% ぐらい)
  - 50% 50% で動いているプロセスの片方を renice で +1 すると 10% ぐらいの差 (55% 45% ぐらい) になる
  - +2 にすると 20% ぐらいの差
  - +19 にするとほとんど割り当てられなくなる
- カーネル内部的には100から139

## カーネルソースマップ

- [Linuxカーネルのソースコードを機能とレイヤーで分類して表示してくれる「Linux kernel map」 - GIGAZINE](https://gigazine.net/news/20180322-linux-kernel-map/)
- ps では l で nice 値が見えるらしい http://www.itmedia.co.jp/help/tips/linux/l0684.html

## もくもくタイム

## linux-insides-ja 翻訳

- <https://github.com/xoxyuxu/linux-insides-ja>

## Linuxシステムコール

- [Linuxシステムコール基本リファレンス ──OSを知る突破口 (WEB+DB PRESS plus)](https://amzn.to/2qyjjEQ)

## .bashrc

.bashrc を設定していた話。

## プロセスに attach

- bash に sudo strace -p 別端末のbashのpid して観察

## スケジューラーについて

- `sched_init` から呼ばれている `cpu_rq` とか
- run queue の構造体とか `task_struct` とか

## `/proc/[pid]/`

`docker run -it --rm busybox` で色々調査。
(ubuntu だと strings がなかった。)

```
strings /proc/self/cmdline
strings /proc/self/environ
ls -l /proc/$$/exe
ls -l /proc/self/exe
ls -al /proc/self/fd
ls -al /proc/self/fd 4>/dev/null
cat /proc/$$/io
cat /proc/self/maps
cat /proc/self/mountinfo
cat /proc/self/mounts
cat /proc/self/mountstats
ls -l /proc/self/root
cat /proc/self/status
ls -al /proc/self/task/
```

- https://linuxjm.osdn.jp/html/LDP_man-pages/man5/proc.5.html を参考にして strings を使った
- [負け組アーキテクトの憂鬱 : NPTLが標準の2.6系kernelでLinuxThreadsを使う](http://orz.makegumi.jp/archives/1258430.html)
  によると LinuxThreads の頃はスレッドごとに pid が別々になっていて NPTL で同じ pid になっているということがわかった。
  ( `/proc/PID/task/` でみえるのがスレッド ID っぽい)

## kernel map リンク先を読む

昔の解読室という本を書いていた人がまとめている情報など。

## Linux のファイアフォール

- http://pcengines.ch/
- nftables の勉強をしていた。

## 次回

- テーマ未定 (その後の外への移動中の話によるとファイルシステムになりそう?)
- 5月19日(土) か 20日(日) に予定
- 同じ場所
