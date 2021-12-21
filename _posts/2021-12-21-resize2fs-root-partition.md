---
layout: post
title: "ルートパーティションを再起動時にresize2fsで縮小する"
date: 2021-12-21 19:45 +0900
comments: true
category: blog
tags: debian ubuntu linux
---
VPS や Vagrant などを使っていて、 `ext4` のルートパーティションが自動でディスクいっぱいまで拡張されて、他のパーティションを作りたいのに空き容量がないということがあります。
そういうときに `resize2fs` で縮小したくても、ルートパーティションはアンマウントできないので、拡張はできても縮小はできません。
手元の実環境なら、別のディスクから起動して操作するのも可能ですが、環境によってはそれも難しいです。

そういうときに `initramfs` の中で `resize2fs` するとうまくいきました。

<!--more-->

## 動作確認環境

- Ubuntu 18.04, 20.04

`initramfs` の仕組みは Debian でも同じなので、 Debian でも同じ方法が使えるはずです。

## 注意事項

パーティションを縮小するので、実際に使っているサイズより小さくしようとするとたぶん壊れます。
他にも失敗すると壊れる可能性が高いので、バックアップを取ってから作業するか、初期設定中などの壊れても大丈夫な環境で作業してください。

## 必要なバイナリのコピー

`/etc/initramfs-tools/hooks/resizefs` として以下の内容のファイルを作成して、実行属性をつけておきます。

```sh
#!/bin/sh

set -e

PREREQS=""

prereqs() { echo "$PREREQS"; }

case $1 in
    prereqs)
        prereqs
        exit 0
    ;;
esac

. /usr/share/initramfs-tools/hook-functions

copy_exec /sbin/e2fsck
copy_exec /sbin/resize2fs

exit 0
```

`initramfs` を作成するときに実行されるフックで、 `copy_exec` を使って実行ファイルとそれに必要なライブラリを `initramfs` にコピーします。

## リサイズ処理の追加

`/etc/initramfs-tools/scripts/local-premount/resizefs` として以下の内容をカスタマイズしたファイルを作成して、実行属性をつけておきます。

```sh
#!/bin/sh

set -e

PREREQ=""

prereqs()
{
        echo "${PREREQ}"
}

case "${1}" in
        prereqs)
                prereqs
                exit 0
                ;;
esac

/sbin/e2fsck -yf "$ROOT"
/sbin/resize2fs "$ROOT" 20G
/sbin/e2fsck -yf "$ROOT"

exit 0
```

`20G` のところは `df` コマンドで確認した実際に使っているサイズより大きいサイズを余裕をもって指定しています。

参考にした
[linux - Is it possible to on-line shrink a EXT4 volume with LVM? - Server Fault](https://serverfault.com/questions/528075/is-it-possible-to-on-line-shrink-a-ext4-volume-with-lvm)
では、 `/dev/sda1` を指定していたり、 `/sbin/mdadm -A /dev/md0` や `/sbin/lvm vgchange -ay vg0` と組み合わせて `/dev/vg0/root` などを指定する例も書いてありますが、 LVM で管理されているルートパーティションは `vgchange` を使わなくても `"$ROOT"` で扱えました。

## initramfs 更新

`sudo update-initramfs -u -k all` で更新します。

中身を確認するのに、最近は単純に `cpio` では確認できなくなっている ([第384回　Initramfsのしくみ：Ubuntu Weekly Recipe｜gihyo.jp … 技術評論社](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0384#:~:text=run%20%20sbin%20%20scripts-,2020%E5%B9%B410%E6%9C%88%E8%BF%BD%E8%A8%98,-2017%E5%B9%B4%E3%81%AE)の「2020年10月追記」を参照) ので、 `lsinitramfs` で確認します。

```console
$ lsinitramfs /boot/initrd.img-* | grep resize
scripts/local-premount/resizefs
usr/sbin/resize2fs
scripts/local-premount/resizefs
usr/sbin/resize2fs
```

この例では `/boot/initrd.img-*` にマッチするファイルが2個あるので、2回ずつ表示されています。

## reboot

`sudo reboot` で再起動して、しばらく待ちます。
環境によっては結構時間がかかるようです。

再起動後に `lvresize` で `LV` も縮小して、 `resize2fs` で `LV` いっぱいに拡大しなおします。

```console
$ sudo lvresize -L 20G /dev/ubuntu-vg/root
WARNING: Reducing active and open logical volume to 20.00 GiB.
THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce ubuntu-vg/root? [y/n]: y
Size of logical volume ubuntu-vg/root changed from 58.09 GiB (14872 extents) to 20.00 GiB (5120 extents).
Logical volume ubuntu-vg/root successfully resized.
$ sudo resize2fs /dev/ubuntu-vg/root
resize2fs 1.45.5 (07-Jan-2020)
The filesystem is already 5242880 (4k) blocks long. Nothing to do!
```

今回は `resize2fs` も `lvresize` もどちらも 20GiB で同じだったので、最後の `resize2fs` では何も変わらなかったようです。

## まとめ

コンソールが使いにくい環境での `ext4` のルートパーティションの縮小方法を紹介しました。
`ext4` 以外の `xfs` などでもコマンドを変えれば同様の方法で可能だと思います。
他にもルートパーティションのマウント前に実行したいコマンドがあれば応用できると思います。
