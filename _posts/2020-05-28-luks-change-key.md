---
layout: post
title: "暗号化LVMの鍵を交換した"
date: 2020-05-28 23:00 +0900
comments: true
category: blog
tags: raspi linux
---
暗号化LVMの鍵ファイルがコマンドの実行ミスで0バイトのファイルになっていたので、
ちゃんとした内容のあるファイルに入れ替えました。

<!--more-->

## 環境

[前回の記事]({% post_url 2020-05-28-raspi-recovery-initramfs %}) の続きです。

- Raspberry Pi 4B (4GB モデル)
- Raspbian Buster Lite
- 8GB の micro SDHC
- 4TB の USB HDD

## 鍵削除

0バイトのファイルが設定されていたので luks の keyslots から削除します。
復旧用のパスフレーズだけが keyslots に残っている状態にしました。

```
$ sudo cryptsetup luksDump /dev/sda2
$ sudo cryptsetup luksRemoveKey /dev/sda2 /etc/keys/lvmcrypt4b1.key
$ sudo cryptsetup luksDump /dev/sda2
```

## 鍵追加

`openssl rand` でランダムな内容のファイルを作成して、
`chattr +i` で間違えて変更してしまわないようにして、
復旧用のパスフレーズを使って追加しました。

```
$ sudo openssl rand -out /etc/keys/lvmcrypt4b1.key 4096
$ sudo chattr +i /etc/keys/lvmcrypt4b1.key
$ sudo cryptsetup luksAddKey /dev/sda2 /etc/keys/lvmcrypt4b1.key
Enter any existing passphrase:
$
```

## initramfs.gz 更新

最低限 `/boot/initramfs.gz` だけは更新しておきます。

```
$ sudo mkinitramfs -o /boot/initramfs.gz
cryptsetup: WARNING: Permissive UMASK (0022). Private key material within the
    initrd might be left unprotected.
```
