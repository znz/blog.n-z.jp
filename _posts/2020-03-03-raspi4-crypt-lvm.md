---
layout: post
title: "Raspberry Pi 4でUSB HDDの暗号化LVMのLVを作り直した"
date: 2020-03-03 23:32 +0900
comments: true
category: blog
tags: raspi linux
---
thin pool は glusterfs の snapshot を使えるかと思って導入したのですが、
glusterfs 用の thin pool には他の LV (logical volume) を混ぜない方が良いらしいので、
root 用の thin pool のサイズを縮小しようとしたらできなかったので、
LV を全部作り直しました。

<!--more-->

## 環境

[前回の記事]({% post_url 2020-03-01-raspi4-crypt-lvm %}) の続きです。

- Raspberry Pi 4B (4GB モデル)
- Raspbian Buster Lite
- 8GB の micro SDHC
- 4TB の USB HDD

## SD カードで起動

- `/boot/cmdline.txt` の `root=` を `root=/dev/mmcblk0p2` に戻す (`cryptdevice` はそのまま)
- `/boot/config.txt` の `initramfs initramfs.gz followkernel` を `#initramfs initramfs.gz followkernel` のようにコメントアウト

## 削除して再作成

```
$ sudo lvremove vg4b1/root4b1
Do you really want to remove active logical volume vg4b1/root4b1? [y/n]: y
  Logical volume "root4b1" successfully removed
$ sudo lvremove vg4b1/thin4b1
Do you really want to remove active logical volume vg4b1/thin4b1? [y/n]: y
  Logical volume "thin4b1" successfully removed
$ sudo lvcreate --thin -L 900G -Zn vg4b1/thin4b1
  Thin pool volume with chunk size 512.00 KiB can address at most 126.50 TiB of data.
  Logical volume "thin4b1" created.
$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda                         8:0    0  3.7T  0 disk
├─sda1                      8:1    0  190M  0 part
└─sda2                      8:2    0  3.7T  0 part
  └─lvmcrypt4b1           254:0    0  3.7T  0 crypt
    ├─vg4b1-thin4b1_tmeta 254:1    0  128M  0 lvm
    │ └─vg4b1-thin4b1     254:3    0  900G  0 lvm
    └─vg4b1-thin4b1_tdata 254:2    0  900G  0 lvm
	└─vg4b1-thin4b1     254:3    0  900G  0 lvm
mmcblk0                   179:0    0  7.3G  0 disk
├─mmcblk0p1               179:1    0  256M  0 part  /boot
└─mmcblk0p2               179:2    0  7.1G  0 part  /
$ sudo lvcreate --thin -V 10G -n root4b1 vg4b1/thin4b1
  Logical volume "root4b1" created.
$ sudo mkfs.ext4 /dev/vg4b1/root4b1
```

## コピーし直し

```
$ mkdir /tmp/root
$ sudo mount /dev/vg4b1/root4b1 /tmp/root
$ time sudo rsync -avx / /tmp/root/
```

## 再起動

- `/boot/cmdline.txt` の `root=` を `root=/dev/vg4b1/root4b1` に戻す
- `/boot/config.txt` の `#initramfs initramfs.gz followkernel` を `initramfs initramfs.gz followkernel` に戻す
- `sudo reboot` で再起動

## 雑感

カーネルがまだ更新されていなかったので、 `mmcblk0p2` を `root` にして起動し直すことができました。
`cryptdevice` の指定を残しておけば `cryptsetup` も問題なく動いて crypt から LVM の認識までそのままで大丈夫でした。

カーネルが更新されて `initramfs` の更新が必要なのに更新していなかった時に、この方法で復旧できるかもしれません。

HDD を使う起動をしてからの設定は `ansible` での provisioning しかしていなかったので、やり直しても問題はありませんでした。
ssh の host key も SD カード側で作成済みだったので、変更はありませんでした。

このやり直せる状態で、もうちょっと色々試すと良いのかもしれません。
(そういう用途には LVM の snapshot を使った方が良いかもしれません。)
