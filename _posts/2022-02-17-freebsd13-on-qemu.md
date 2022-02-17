---
layout: post
title: "FreeBSD 13をqemuで動かしてみた"
date: 2022-02-17 19:30 +0900
comments: true
category: blog
tags: qemu aarch64 freebsd
---
FreeBSD は仮想マシンイメージも配布されているのに
[FreeBSD ハンドブックの第2章 FreeBSD のインストール](https://docs.freebsd.org/ja/books/handbook/bsdinstall/)には
「これらはインストール用のイメージではなく、 すでに設定済みの ("すでにインストールされた") インスタンスで、すぐに起動して、 インストール後の作業を行うことができます。」
と書いてあるだけで、起動方法が書いていなかったのですが、色々試していたら起動して使えました。

<!--more-->

## 動作確認環境

- MacBook Pro（14インチ、2021）, Apple M1 Pro
- macOS Monterey 12.2.1
- QEMU emulator version 6.2.0
- FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2.xz

## ダウンロード

[FreeBSD を入手する](https://www.freebsd.org/ja/where/)
から仮想マシンイメージの `aarch64` のリンク先を開いて、
`FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2.xz`
をダウンロードしました。

## 展開

とりあえず `$HOME/tmp` を作ってそこに展開しました。

```
mkdir -p ~/tmp
xzcat ~/Downloads/FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2.xz > ~/tmp/FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2
```

## GUI で実行

`-M` の machine として
`virt` `QEMU 6.2 ARM Virtual Machine (alias of virt-6.2)`
を使いました。

`-cpu` を指定しないと何も出てこなかったので、適当に試して起動できた `-cpu max` を使いました。

`-M` や `-cpu` のハードウェアの種類の指定はちゃんと調べていないので、もっと良い指定があるかもしれません。

起動するには bios が必要なので、
Debian や Ubuntu なら `qemu-efi-aarch64` に入っている `/usr/share/qemu-efi-aarch64/QEMU_EFI.fd` を、
macOS の Homebrew で入れた qemu なら `/opt/homebrew/Cellar/qemu/*/share/qemu/edk2-aarch64-code.fd` を指定します。

`-device virtio-gpu-pci` をつけておくと BIOS の画面は `virtio-gpu-pci` に出て、カーネルが起動してからは `serial0` の方に出ていました。

`-m 2g` や `-smp 4` は QEMU でよく使うメモリと CPU の指定です。

最後にディスクイメージを指定しています。

```
qemu-system-aarch64 -M virt -cpu max -device virtio-gpu-pci -bios /opt/homebrew/Cellar/qemu/6.2.0/share/qemu/edk2-aarch64-code.fd -m 2g -smp 4 ~/tmp/FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2
```

## CUI で実行

`-serial mon:stdio -nographic` で標準入出力に `monitor0` と `serial0` を接続して、
GUI なしで起動しました。

違いの理由は調べられていないのですが、 `-device virtio-gpu-pci` を残したままだと黒背景で、つけないと白背景 (または黒背景、つまり元の端末の設定のまま) になりました。

```
qemu-system-aarch64 -M virt -cpu max -bios /opt/homebrew/Cellar/qemu/6.2.0/share/qemu/edk2-aarch64-code.fd -m 2g -smp 4 -serial mon:stdio -nographic ~/tmp/FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2
```

## ディスクのリサイズ

デフォルトのディスクサイズだと小さいので、
[How to Resize a Disk in FreeBSD](https://www.vultr.com/ja/docs/how-to-resize-a-disk-in-freebsd/)
を参考にしてリサイズしました。

まず `qemu-img` でディスクイメージをリサイズします。

```
% qemu-img info ~/tmp/FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2
file format: qcow2
virtual size: 5.03 GiB (5402853376 bytes)
disk size: 2.58 GiB
cluster_size: 65536
Format specific information:
	compat: 0.10
	compression type: zlib
	refcount bits: 16
% qemu-img resize ~/tmp/FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2 20G
Image resized.
% qemu-img info ~/tmp/FreeBSD-13.0-RELEASE-arm64-aarch64.qcow2
file format: qcow2
virtual size: 20 GiB (21474836480 bytes)
disk size: 2.58 GiB
cluster_size: 65536
Format specific information:
	compat: 0.10
	compression type: zlib
	refcount bits: 16
```

次に起動中の以下の FreeBSD のロゴがでている画面で 2 を押してシングルユーザーモードで起動します。

```
\  ______               ____   _____ _____
  |  ____|             |  _ \ / ____|  __ \
  | |___ _ __ ___  ___ | |_) | (___ | |  | |
  |  ___| '__/ _ \/ _ \|  _ < \___ \| |  | |
  | |   | | |  __/  __/| |_) |____) | |__| |
  | |   | | |    |    ||     |      |      |
  |_|   |_|  \___|\___||____/|_____/|_____/      ```                        `
												s` `.....---.......--.```   -/
 /-----------Welcome to FreeBSD------------\    +o   .--`         /y:`      +.
 |                                         |     yo`:.            :o      `+-
 |  1. Boot Multi user [Enter]             |      y/               -/`   -o/
 |  2. Boot Single user                    |     .-                  ::/sy+:.
 |  3. Escape to loader prompt             |     /                     `--  /
 |  4. Reboot                              |    `:                          :`
 |  5. Cons: Dual (Video primary)          |    `:                          :`
 |                                         |     /                          /
 |  Options:                               |     .-                        -.
 |  6. Kernel: default/kernel (1 of 2)     |      --                      -.
 |  7. Boot Options                        |       `:`                  `:`
 |                                         |         .--             `--.
 |                                         |            .---.....----.
 \-----------------------------------------/
```

そのまま Enter で `/bin/sh` を起動して、
`gpart show` で確認します。

`CORRUPT` になっているので `gpart recover vtbd0` しておきます。

`gpart resize -i 3 vtbd0` でパーティションをリサイズして、
`service growfs onestart` でファイルシステムもリサイズします。

そして `poweroff` で停止してから `qemu` を起動しなおします。

```
Enter full pathname of shell or RETURN for /bin/sh:
root@:/ # gpart show
=>       3  10552443  vtbd0  GPT  (20G) [CORRUPT]
         3     66584      1  efi  (33M)
     66587   2097152      2  freebsd-swap  (1.0G)
   2163739   8388707      3  freebsd-ufs  (4.0G)

root@:/ # gpart recover vtbd0
vtbd0 recovered
root@:/ # gpart show
=>       3  41943029  vtbd0  GPT  (20G)
         3     66584      1  efi  (33M)
     66587   2097152      2  freebsd-swap  (1.0G)
   2163739   8388707      3  freebsd-ufs  (4.0G)
  10552446  31390586         - free -  (15G)

root@:/ # gpart resize -i 3 vtbd0
vtbd0p3 resized
root@:/ # gpart show
=>       3  41943029  vtbd0  GPT  (20G)
         3     66584      1  efi  (33M)
     66587   2097152      2  freebsd-swap  (1.0G)
   2163739  39779293      3  freebsd-ufs  (19G)

root@:/ # service growfs onestart
Growing root partition to fill device
vtbd0 recovering is not needed
vtbd0p3 resized
gpart: arg0 'gpt/rootfs': Invalid argument
super-block backups (for fsck_ffs -b #) at:
 8963328, 10243776, 11524224, 12804672, 14085120, 15365568, 16646016, 17926464, 19206912, 20487360, 21767808, 23048256, 24328704, 25609152, 26889600, 28170048, 29450496, 30730944, 32011392, 33291840, 34572288,
 35852736, 37133184, 38413632, 39694080
root@:/ # poweroff
```

## ログイン

説明がみつけられなかったのですが、
`root` ユーザーにパスワードなしでログインできました。

## freebsd-update

[第17章 FreeBSD のアップデートとアップグレード](https://docs.freebsd.org/ja/books/handbook/cutting-edge/)
によると、とりあえず `freebsd-update fetch` と `freebsd-update install` を実行すれば良さそうです。

## その後

`adduser` で一般ユーザーを作成したり、
[ruby-build の wiki](https://github.com/rbenv/ruby-build/wiki#freebsd) を参考にして
`pkg install` でパッケージをインストールしたりして、色々使ってみました。

## まとめ

最初は全く起動方法がわからなかった FreeBSD 13 の aarch64 版を `qemu-system-aarch64` で試すことができました。
とりあえず ruby のビルドを試すのに使っただけですが、今後も環境依存の何かを試したくなったときに使えそうです。
