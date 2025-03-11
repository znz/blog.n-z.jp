---
layout: post
title: "Raspberry Pi OSをqemuで動かしてread-onlyの挙動を確認する"
date: 2025-03-08 18:00 +0900
comments: true
category: blog
tags: linux raspberrypi qemu
---
ラズパイ3B とラズパイ3B+ が止まったままで、何かに使えないかと思いつつ、
ディスクアクセスが遅いので、
SD カードを read-only で使う用途はどうかと思っています。
そこで、実機で試す前に Raspberry Pi OS を qemu で動かして read-only の挙動を確認することにしました。

<!--more-->

## 動作確認バージョン

- qemu 9.2.2
- Raspberry Pi OS (64-bit)
  - Raspberry Pi OS Lite
  - Release date: November 19th 2024
  - Kernel version: 6.6
  - Debian version: 12 (bookworm)
  - Size: 438MB

## ダウンロード

「Raspberry Pi OS」で検索して、
<https://www.raspberrypi.com/software/>
から「See all download options」と辿って
<https://www.raspberrypi.com/software/operating-systems/>
に一覧があったので、そこから 64-bit の Raspberry Pi OS Lite をダウンロードしました。

## カーネルなどを取り出し

Linux 上では頑張ってループバックマウントして取り出す方法もありますが、
macOS でも使える方法として、
`p7zip` でディスクイメージファイルをアーカイブファイルとして扱って取り出しました。

```bash
unxz 2024-11-19-raspios-bookworm-arm64-lite.img.xz
7z l 2024-11-19-raspios-bookworm-arm64-lite.img
7z x 2024-11-19-raspios-bookworm-arm64-lite.img 0.fat
7z l 0.fat
7z x 0.fat bcm2710-rpi-3-b.dtb cmdline.txt config.txt kernel8.img initramfs8
```

パーティションが `0.fat` と `1.img` というファイルとして見えるので、
起動に使われる `0.fat` の方を取り出して、
さらにその中からカーネルなどを取り出しました。

## ディスクの拡張

`qemu-img create -b 2024-11-19-raspios-bookworm-arm64-lite.img -F raw -f qcow2 diff.qcow2 8G`
で差分ディスクを作成しても良かったのですが、
`p7zip` でのファイル取り出しが難しくなるので、
コピーしてリサイズすることにしました。

```bash
cp 2024-11-19-raspios-bookworm-arm64-lite.img disk.img
qemu-img resize disk.img 8G
```

リサイズ後は 8G の SDHC カードに書き込んだ状態に相当すると思います。

## 初回起動

`cmdline.txt` の内容を確認すると `init=` が `firstboot` になっていて、
初回起動用の特別処理がありそうとわかります。

```console
% cat cmdline.txt
console=serial0,115200 console=tty1 root=PARTUUID=8a438930-02 rootfstype=ext4 fsck.repair=yes rootwait quiet init=/usr/lib/raspberrypi-sys-mods/firstboot
```

`cmdline.txt` の内容を使って初回起動します。

`PARTUUID` は変化に合わせて指定するのは大変なのと、
`qemu` の引数でデバイスは固定なので、
`root=/dev/mmcblk0p2` に書き換えて使います。

その他のオプションは、
[Raspberry Pi OS 64-bit を qemu 7.2.0 で動作させる \| hiroの長い長い冒険日記](https://hiro20180901.com/2023/04/24/raspberry-pi-os-64-bit-runs-qemu-720-vritual-machine/)
の
[qemu のオプションについて](https://hiro20180901.com/2023/04/24/raspberry-pi-os-64-bit-runs-qemu-720-vritual-machine/#toc14)
などを参考にしています。

```bash
qemu-system-aarch64 -m 1024 -M raspi3b -kernel kernel8.img -initrd initramfs8 -dtb bcm2710-rpi-3-b.dtb -drive file=disk.img,format=raw -append "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait quiet init=/usr/lib/raspberrypi-sys-mods/firstboot" -serial stdio -no-reboot -device usb-kbd -device usb-tablet -device usb-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2222-:22
```

パーティションのリサイズと SSH ホスト鍵の自動生成などが実行されていました。

## 通常の起動

初回起動前と同様にファイルを取り出すと、
`PARTUUID` が変化して、
`quiet` と `init=` の指定が削除されていました。

```console
% cat cmdline.txt
console=serial0,115200 console=tty1 root=PARTUUID=071b9753-02 rootfstype=ext4 fsck.repair=yes rootwait
```

初回起動と同様に `root=` の指定は変更しています。

コンソールのサイズを変更するために
`bcm2708_fb.fbwidth=1280 bcm2708_fb.fbheight=768`
を追加しました。

```bash
qemu-system-aarch64 -m 1024 -M raspi3b -kernel kernel8.img -initrd initramfs8 -dtb bcm2710-rpi-3-b.dtb -drive file=disk.img,format=raw -append "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait bcm2708_fb.fbwidth=1280 bcm2708_fb.fbheight=768" -serial stdio -no-reboot -device usb-kbd -device usb-tablet -device usb-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2222-:22
```

`-no-reboot` を指定しているので、
自動で再起動するときに終了します。

## 2回目の起動

通常起動の初回(全体の2回目の起動)は、
キーボードの設定とユーザーの作成がありました。
昔の Raspbian で最初から作成されていた `pi` ユーザーは存在しないようです。

## ssh 接続

`sudo raspi-config` で `3 Interface Options` の `I1 SSH` で有効にすると
`ssh -p 2222 ${作成したユーザー}@localhost`
や
`ssh -p 2222 -l ${作成したユーザー} localhost`
で接続できるようになります。

## read only 化

`sudo raspi-config` で `4 Performance Options` の `P2 Overlay File System`
で overlay file system を Yes にすると `overlayroot` パッケージが追加インストールされて `initramfs` (`/boot/firmware` の `initramfs8` と `initramfs_2712`) が更新されて、
`cmdline.txt` の先頭に `overlayroot=tmpfs` が追加されていました。

`initramfs8` が更新されているので、
`p7zip` で取り出して、
それに合わせて
`qemu-system-aarch64 -m 1024 -M raspi3b -kernel kernel8.img -initrd initramfs8 -dtb bcm2710-rpi-3-b.dtb -drive file=disk.img,format=raw -append "overlayroot=tmpfs console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait bcm2708_fb.fbwidth=1280 bcm2708_fb.fbheight=768" -serial stdio -no-reboot -device usb-kbd -device usb-tablet -device usb-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2222-:22`
のように `overlayroot=tmpfs` を追加して起動して、
`df` などで確認すると `/` が `overlayroot` になっていました。

boot partition の write-protected を Yes にすると、
`/etc/fstab` の `/boot/firmware` の行の `defaults` が `defaults,ro` に変わっていました。

`/` の overlay 化と boot partition の write-protected は独立して設定できましたが、
overlay を Yes にして起動している状態だと、
`/etc/fstab` の書き換えが再起動時に反映できないので、
boot partition の write-protected は変更できませんでした。
そのため、一気に両方有効にした状態から戻すには、
overlay を No にして再起動した後、
boot partition の write-protected を No にする必要がありました。

## まとめ

`qemu` で `raspi3b` の動作確認ができました。

そして `overlayroot` などの read-only にする仕組みも確認できました。

[overlayrootでUbuntuを一時的に読み込み専用にする](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0568) によると `overlayroot` はもっと色々な機能があるようなので、
変更は USB マスストレージに保存するようにして SD カードは読み込み専用のまま書き込み内容も保存する、ということもできそうです。
