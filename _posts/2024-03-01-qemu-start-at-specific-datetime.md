---
layout: post
title: "qemuで指定した日時の時計でVMを起動する"
date: 2024-03-01 14:30 +0900
comments: true
category: blog
tags: qemu systemd debian linux
---
昨日のようなうるう日の検証やサマータイムの切り替わりのタイミングを検証したいなどの理由で任意の日時で
OS を動かしたいことがあります。
qemu は
[Invocation — QEMU documentation](https://www.qemu.org/docs/master/system/invocation.html)
の `-rtc base=datetime` で任意の時刻で起動開始できるので、
それを使ってやり方を確認しました。

<!--more-->

## 動作確認環境

- macOS Sonoma 14.3.1
- homebrew でインストールした qemu 8.2.1
- Debian 12 の 64-bit ARM qcow2

## ダウンロード

<https://www.debian.org/> から Download の下にある [Other downloads](https://www.debian.org/distrib/) をたどって、
[Use a Debian cloud image](https://cloud.debian.org/images/cloud/)
の
[64-bit ARM の qcow2](https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-arm64.qcow2)
を使いました。

## 起動確認

[Arm64Qemu - Debian Wiki](https://wiki.debian.org/Arm64Qemu) の step3: boot the image の以下を参考にしました。

```
qemu-system-aarch64 -m 2G -M virt -cpu max \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -drive if=none,file=debian-9.9.0-openstack-arm64.qcow2,id=hd0 -device virtio-blk-device,drive=hd0 \
  -device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22 \
  -nographic
```

とりあえず以下で起動確認できました。
詳細は確認していませんが、
`QEMU_EFI.fd` の代わりとして拡張子が `.fd` で aarch64 用になっているファイルを qemu の share から探して `-bios` に指定すると起動できました。

```console
% curl -sSLO https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-arm64.qcow2
% qemu-system-aarch64 -m 2G -M virt -cpu max -bios /opt/homebrew/Cellar/qemu/*/share/qemu/edk2-aarch64-code.fd -drive if=none,file=debian-12-nocloud-arm64.qcow2,id=hd0 -device virtio-blk-device,drive=hd0 -device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22 -nographic
```

ログインプロンプトの `localhost login:` がでてきたら、
パスワードなしで `root` でログインできるので、
確認が終わったら `poweroff` などで終了します。

## 事前準備

終了する前に `systemctl disable systemd-timesyncd.service` で時刻の自動修正を止めておきます。

```console
root@localhost:~# systemctl disable systemd-timesyncd.service
Removed "/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service".
Removed "/etc/systemd/system/dbus-org.freedesktop.timesync1.service".
```

時刻がずれていると `https` 接続で問題が起きるので、
時刻がずれた状態で必要なものをインストールしたりダウンロードしたりしておきます。

## 指定した時刻で起動

事前に `systemd-timesyncd.service` を止めておくか、
`-device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22`
を外してネットワークなしで起動すると、
`-rtc clock=vm,base=2024-02-29T01:02:03`
で指定した時刻で起動した状態になっていることを確認できました。

```console
% qemu-system-aarch64 -m 2G -M virt -cpu max -bios /opt/homebrew/Cellar/qemu/*/share/qemu/edk2-aarch64-code.fd -drive if=none,file=debian-12-nocloud-arm64.qcow2,id=hd0 -device virtio-blk-device,drive=hd0 -nographic -rtc clock=vm,base=2024-02-29T01:02:03
(snip)
localhost login: root
Linux localhost 6.1.0-18-arm64 #1 SMP Debian 6.1.76-1 (2024-02-01) aarch64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
dateroot@localhost:~# date
Thu Feb 29 01:03:42 UTC 2024
```

## 差分ディスクを使う

直接は関係ない話ですが、試行錯誤するなら、ダウンロードした `qcow2` はいじらずに、差分ディスクを作成して使うという方法も良さそうです。

```console
% curl -sSLO https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-arm64.qcow2
% qemu-img create -f qcow2 -b debian-12-nocloud-arm64.qcow2 -F qcow2 diff.qcow2
Formatting 'diff.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=2147483648 backing_file=debian-12-nocloud-arm64.qcow2 backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16
% qemu-system-aarch64 -m 2G -M virt -cpu max -bios /opt/homebrew/Cellar/qemu/*/share/qemu/edk2-aarch64-code.fd -drive if=none,file=diff.qcow2,id=hd0 -device virtio-blk-device,drive=hd0 -nographic -rtc clock=vm,base=2024-02-29T01:02:03
```

## まとめ

qemu で指定した日時で VM を起動できました。

時計がずれていたり巻き戻ったりすると起きる問題もあるので、
完全にその日時での動作と同じというわけにはいきませんが、
制限事項を知った上での動作検証には使えそうです。

制限事項に関連して、qemu を内部で使っている [lima](https://github.com/lima-vm/lima) などで無理矢理 `-rtc clock=vm,base=datetime` オプションを追加するのも、
少し試した範囲だと、想定していない動作になるようで、変なことが起きるようです。
そのため、直接 qemu コマンドを実行する使い方だけで試すのが無難そうです。
