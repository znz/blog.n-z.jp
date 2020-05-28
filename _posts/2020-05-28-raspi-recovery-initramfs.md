---
layout: post
title: "Raspberry Pi 4でUSB HDDの暗号化LVMのinitramfsを復旧した"
date: 2020-05-28 21:00 +0900
comments: true
category: blog
tags: raspi linux
---
Raspbian のカーネルが更新されてバージョンが変わったのに `mkinitramfs` し直す前に再起動してしまって、
起動できなくなってしまったので、
別マシンで `chroot mkinitramfs` するのが大変だったので、その記録です。

<!--more-->

## 環境

[前回の記事]({% post_url 2020-03-03-raspi4-crypt-lvm %}) の続きです。

- Raspberry Pi 4B (4GB モデル)
- Raspbian Buster Lite
- 8GB の micro SDHC
- 4TB の USB HDD

gluster のために、詳細が微妙に違う設定になっていて 3 台あって、
まずそのうち 1 台でカーネルの更新をして再起動してみると、
起動に失敗したので、他のマシンで復旧しました。

## USB HDD を別の Raspbian に接続

`lsblk` でどこに接続されているか確認します。

gluster で snapshot をとるようにしているので、
vg4b3 には lv がたくさんありますが、
追加で接続した USB HDD は sdb に見えているのが確認できます。

```
pi@raspi4b3:~$ lsblk
NAME                                               MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda                                                  8:0    0  3.7T  0 disk
├─sda1                                               8:1    0  190M  0 part
└─sda2                                               8:2    0  3.7T  0 part
  └─lvmcrypt4b3                                    254:0    0  3.7T  0 crypt
    ├─vg4b3-thin4b3_tmeta                          254:1    0  128M  0 lvm
    │ └─vg4b3-thin4b3-tpool                        254:3    0  900G  0 lvm
    │   ├─vg4b3-thin4b3                            254:4    0  900G  0 lvm
    │   └─vg4b3-root4b3                            254:5    0   10G  0 lvm   /
    ├─vg4b3-thin4b3_tdata                          254:2    0  900G  0 lvm
    │ └─vg4b3-thin4b3-tpool                        254:3    0  900G  0 lvm
    │   ├─vg4b3-thin4b3                            254:4    0  900G  0 lvm
    │   └─vg4b3-root4b3                            254:5    0   10G  0 lvm   /
    ├─vg4b3-gfspool4b3_tmeta                       254:6    0  128M  0 lvm
    │ └─vg4b3-gfspool4b3-tpool                     254:8    0  2.5T  0 lvm
    │   ├─vg4b3-gfspool4b3                         254:9    0  2.5T  0 lvm
    │   ├─vg4b3-hyrule3                            254:10   0  1.1T  0 lvm   /export/hyrule
    │   ├─vg4b3-900ac05c62654b5481009612577d2d42_0 254:11   0  1.1T  0 lvm
    │   ├─vg4b3-e3e17ca5f3714073afb83157a6f3e5ba_0 254:12   0  1.1T  0 lvm
    │   ├─vg4b3-d9a1b06e082e4bd19c9c1c251e4cdfc6_0 254:13   0  1.1T  0 lvm
    │   ├─vg4b3-86f01eb36aa9409982bbba311d4edbac_0 254:14   0  1.1T  0 lvm
    │   ├─vg4b3-111339b884d74b62be16bffb4becdf4b_0 254:15   0  1.1T  0 lvm
    │   ├─vg4b3-0a12a543c806419d83cf48e96bc66638_0 254:17   0  1.1T  0 lvm
    │   ├─vg4b3-cb7fa4c2e5664817b2155a70f18b37fa_0 254:18   0  1.1T  0 lvm
    │   ├─vg4b3-2532c7240bab4e07acec15644001b893_0 254:19   0  1.1T  0 lvm
    │   └─vg4b3-39d6cb7a7b3143caa54956ae188710ff_0 254:20   0  1.1T  0 lvm
    └─vg4b3-gfspool4b3_tdata                       254:7    0  2.5T  0 lvm
      └─vg4b3-gfspool4b3-tpool                     254:8    0  2.5T  0 lvm
	├─vg4b3-gfspool4b3                         254:9    0  2.5T  0 lvm
	├─vg4b3-hyrule3                            254:10   0  1.1T  0 lvm   /export/hyrule
	├─vg4b3-900ac05c62654b5481009612577d2d42_0 254:11   0  1.1T  0 lvm
	├─vg4b3-e3e17ca5f3714073afb83157a6f3e5ba_0 254:12   0  1.1T  0 lvm
	├─vg4b3-d9a1b06e082e4bd19c9c1c251e4cdfc6_0 254:13   0  1.1T  0 lvm
	├─vg4b3-86f01eb36aa9409982bbba311d4edbac_0 254:14   0  1.1T  0 lvm
	├─vg4b3-111339b884d74b62be16bffb4becdf4b_0 254:15   0  1.1T  0 lvm
	├─vg4b3-0a12a543c806419d83cf48e96bc66638_0 254:17   0  1.1T  0 lvm
	├─vg4b3-cb7fa4c2e5664817b2155a70f18b37fa_0 254:18   0  1.1T  0 lvm
	├─vg4b3-2532c7240bab4e07acec15644001b893_0 254:19   0  1.1T  0 lvm
	└─vg4b3-39d6cb7a7b3143caa54956ae188710ff_0 254:20   0  1.1T  0 lvm
sdb                                                  8:16   0  3.7T  0 disk
├─sdb1                                               8:17   0  190M  0 part
└─sdb2                                               8:18   0  3.7T  0 part
mmcblk0                                            179:0    0  7.2G  0 disk
├─mmcblk0p1                                        179:1    0  256M  0 part  /boot
└─mmcblk0p2                                        179:2    0    7G  0 part
```

## マウントするところまで

`cryptsetup luksOpen` で暗号化解除して、
`pvscan`, `vgscan`, `lvscan` で LVM の認識をして (あとで試してみたら scan は実行しなくても良さそうでした)、
`/tmp/raspi4b2` 以下にマウントしていきました。
`/boot` は EFI System Partition にして、
USB Mass Storage からの直接起動の準備中でした。
(これは成功したら後日別途書く予定です。)

```
pi@raspi4b3:~$ cat /etc/crypttab
# <target name> <source device>         <key file>      <options>
lvmcrypt4b3 /dev/disk/by-uuid/3c79891e-6abf-4559-8cde-4d298408c718 /etc/keys/lvmcrypt4b3.key luks,initramfs
pi@raspi4b3:~$ sudo cryptsetup luksOpen /dev/sdb2 lvmcrypt4b2
Enter passphrase for /dev/sdb2:
pi@raspi4b3:~$ lsblk
(snip)
sdb                                                  8:16   0  3.7T  0 disk
├─sdb1                                               8:17   0  190M  0 part
└─sdb2                                               8:18   0  3.7T  0 part
  └─lvmcrypt4b2                                    254:16   0  3.7T  0 crypt
    ├─vg4b2-thin4b2_tmeta                          254:21   0  128M  0 lvm
    │ └─vg4b2-thin4b2-tpool                        254:23   0  900G  0 lvm
    │   ├─vg4b2-thin4b2                            254:24   0  900G  0 lvm
    │   └─vg4b2-root4b2                            254:25   0   10G  0 lvm
    ├─vg4b2-thin4b2_tdata                          254:22   0  900G  0 lvm
    │ └─vg4b2-thin4b2-tpool                        254:23   0  900G  0 lvm
    │   ├─vg4b2-thin4b2                            254:24   0  900G  0 lvm
    │   └─vg4b2-root4b2                            254:25   0   10G  0 lvm
    ├─vg4b2-gfspool4b2_tmeta                       254:26   0  128M  0 lvm
    │ └─vg4b2-gfspool4b2-tpool                     254:28   0  2.5T  0 lvm
    │   ├─vg4b2-gfspool4b2                         254:29   0  2.5T  0 lvm
    │   ├─vg4b2-hyrule2                            254:30   0  1.1T  0 lvm
    │   ├─vg4b2-0a12a543c806419d83cf48e96bc66638_0 254:31   0  1.1T  0 lvm
    │   ├─vg4b2-cb7fa4c2e5664817b2155a70f18b37fa_0 254:32   0  1.1T  0 lvm
    │   ├─vg4b2-2532c7240bab4e07acec15644001b893_0 254:33   0  1.1T  0 lvm
    │   ├─vg4b2-39d6cb7a7b3143caa54956ae188710ff_0 254:34   0  1.1T  0 lvm
    │   ├─vg4b2-900ac05c62654b5481009612577d2d42_0 254:35   0  1.1T  0 lvm
    │   ├─vg4b2-e3e17ca5f3714073afb83157a6f3e5ba_0 254:36   0  1.1T  0 lvm
    │   ├─vg4b2-d9a1b06e082e4bd19c9c1c251e4cdfc6_0 254:37   0  1.1T  0 lvm
    │   ├─vg4b2-86f01eb36aa9409982bbba311d4edbac_0 254:38   0  1.1T  0 lvm
    │   └─vg4b2-111339b884d74b62be16bffb4becdf4b_0 254:39   0  1.1T  0 lvm
    └─vg4b2-gfspool4b2_tdata                       254:27   0  2.5T  0 lvm
      └─vg4b2-gfspool4b2-tpool                     254:28   0  2.5T  0 lvm
	├─vg4b2-gfspool4b2                         254:29   0  2.5T  0 lvm
	├─vg4b2-hyrule2                            254:30   0  1.1T  0 lvm
	├─vg4b2-0a12a543c806419d83cf48e96bc66638_0 254:31   0  1.1T  0 lvm
	├─vg4b2-cb7fa4c2e5664817b2155a70f18b37fa_0 254:32   0  1.1T  0 lvm
	├─vg4b2-2532c7240bab4e07acec15644001b893_0 254:33   0  1.1T  0 lvm
	├─vg4b2-39d6cb7a7b3143caa54956ae188710ff_0 254:34   0  1.1T  0 lvm
	├─vg4b2-900ac05c62654b5481009612577d2d42_0 254:35   0  1.1T  0 lvm
	├─vg4b2-e3e17ca5f3714073afb83157a6f3e5ba_0 254:36   0  1.1T  0 lvm
	├─vg4b2-d9a1b06e082e4bd19c9c1c251e4cdfc6_0 254:37   0  1.1T  0 lvm
	├─vg4b2-86f01eb36aa9409982bbba311d4edbac_0 254:38   0  1.1T  0 lvm
	└─vg4b2-111339b884d74b62be16bffb4becdf4b_0 254:39   0  1.1T  0 lvm
(snip)
pi@raspi4b3:~$ sudo pvscan
  PV /dev/mapper/lvmcrypt4b2   VG vg4b2           lvm2 [<3.64 TiB / <265.44 GiB free]
  PV /dev/mapper/lvmcrypt4b3   VG vg4b3           lvm2 [<3.64 TiB / <265.44 GiB free]
  Total: 2 [<7.28 TiB] / in use: 2 [<7.28 TiB] / in no VG: 0 [0   ]
pi@raspi4b3:~$ sudo vgscan
  Reading all physical volumes.  This may take a while...
  Found volume group "vg4b2" using metadata type lvm2
  Found volume group "vg4b3" using metadata type lvm2
pi@raspi4b3:~$ sudo lvscan
  ACTIVE            '/dev/vg4b2/thin4b2' [900.00 GiB] inherit
  ACTIVE            '/dev/vg4b2/root4b2' [10.00 GiB] inherit
  ACTIVE            '/dev/vg4b2/gfspool4b2' [2.50 TiB] inherit
  ACTIVE            '/dev/vg4b2/hyrule2' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/0a12a543c806419d83cf48e96bc66638_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/cb7fa4c2e5664817b2155a70f18b37fa_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/2532c7240bab4e07acec15644001b893_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/39d6cb7a7b3143caa54956ae188710ff_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/900ac05c62654b5481009612577d2d42_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/e3e17ca5f3714073afb83157a6f3e5ba_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/d9a1b06e082e4bd19c9c1c251e4cdfc6_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/86f01eb36aa9409982bbba311d4edbac_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b2/111339b884d74b62be16bffb4becdf4b_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/thin4b3' [900.00 GiB] inherit
  ACTIVE            '/dev/vg4b3/root4b3' [10.00 GiB] inherit
  ACTIVE            '/dev/vg4b3/gfspool4b3' [2.50 TiB] inherit
  ACTIVE            '/dev/vg4b3/hyrule3' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/0a12a543c806419d83cf48e96bc66638_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/cb7fa4c2e5664817b2155a70f18b37fa_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/2532c7240bab4e07acec15644001b893_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/39d6cb7a7b3143caa54956ae188710ff_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/900ac05c62654b5481009612577d2d42_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/e3e17ca5f3714073afb83157a6f3e5ba_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/d9a1b06e082e4bd19c9c1c251e4cdfc6_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/86f01eb36aa9409982bbba311d4edbac_0' [1.10 TiB] inherit
  ACTIVE            '/dev/vg4b3/111339b884d74b62be16bffb4becdf4b_0' [1.10 TiB] inherit
pi@raspi4b3:~$ mkdir /tmp/raspi4b2
pi@raspi4b3:~$ sudo mount /dev/vg4b2/root4b2 /tmp/raspi4b2
pi@raspi4b3:~$ sudo mount /dev/sdb1 /tmp/raspi4b2/boot
```

## boot の比較

復旧を優先して詳細を見ていなかったのですが、
`pieeprom.sig`, `pieeprom.upd`, `recovery.bin`
がなくなっているようです。

```
pi@raspi4b3:~$ ls /tmp/raspi4b2/boot
COPYING.linux           bcm2708-rpi-zero.dtb      bcm2711-rpi-4-b.dtb  fixup4.dat    fixup_x.dat   kernel8.img   start4x.elf
LICENCE.broadcom        bcm2709-rpi-2-b.dtb       bootcode.bin         fixup4cd.dat  initramfs.gz  overlays      start_cd.elf
bcm2708-rpi-b-plus.dtb  bcm2710-rpi-2-b.dtb       cmdline.txt          fixup4db.dat  issue.txt     start.elf     start_db.elf
bcm2708-rpi-b.dtb       bcm2710-rpi-3-b-plus.dtb  cmdline.txt.bak      fixup4x.dat   kernel.img    start4.elf    start_x.elf
bcm2708-rpi-cm.dtb      bcm2710-rpi-3-b.dtb       config.txt           fixup_cd.dat  kernel7.img   start4cd.elf
bcm2708-rpi-zero-w.dtb  bcm2710-rpi-cm3.dtb       fixup.dat            fixup_db.dat  kernel7l.img  start4db.elf
pi@raspi4b3:~$ ls /boot
COPYING.linux           bcm2709-rpi-2-b.dtb       cmdline.txt   fixup4x.dat   kernel7.img   start.elf     start_x.elf
LICENCE.broadcom        bcm2710-rpi-2-b.dtb       cmdline.txt~  fixup_cd.dat  kernel7l.img  start4.elf
bcm2708-rpi-b-plus.dtb  bcm2710-rpi-3-b-plus.dtb  config.txt    fixup_db.dat  kernel8.img   start4cd.elf
bcm2708-rpi-b.dtb       bcm2710-rpi-3-b.dtb       fixup.dat     fixup_x.dat   overlays      start4db.elf
bcm2708-rpi-cm.dtb      bcm2710-rpi-cm3.dtb       fixup4.dat    initramfs.gz  pieeprom.sig  start4x.elf
bcm2708-rpi-zero-w.dtb  bcm2711-rpi-4-b.dtb       fixup4cd.dat  issue.txt     pieeprom.upd  start_cd.elf
bcm2708-rpi-zero.dtb    bootcode.bin              fixup4db.dat  kernel.img    recovery.bin  start_db.elf
```

## mkinitramfs (失敗)

単純に `chroot` だけだとうまくいきませんでした。

```
pi@raspi4b3:~$ sudo chroot /tmp/raspi4b2/ mkinitramfs -o /boot/initramfs.gz
W: missing /lib/modules/4.19.97-v7l+
W: Ensure all necessary drivers are built into the linux image!
depmod: ERROR: could not open directory /lib/modules/4.19.97-v7l+: No such file or directory
depmod: FATAL: could not search modules: No such file or directory
cat: /var/tmp/mkinitramfs_gHjH8y/lib/modules/4.19.97-v7l+/modules.builtin: そのようなファイルやディレクトリはありません
find: ‘/var/tmp/mkinitramfs_gHjH8y/lib/modules/4.19.97-v7l+/kernel’: そのようなファイルやディレクトリはありません
cryptsetup: WARNING: Permissive UMASK (0022). Private key material within the
    initrd might be left unprotected.
/usr/share/initramfs-tools/hooks/cryptroot: 64: /usr/share/initramfs-tools/hooks/cryptroot: cannot open /proc/mounts: No such file
cryptsetup: WARNING: Couldn't determine root device
sed: /proc/cmdline を読み込めません: そのようなファイルやディレクトリはありません
grep: /proc/swaps: そのようなファイルやディレクトリはありません
/usr/share/initramfs-tools/hooks/cryptroot: 64: /usr/share/initramfs-tools/hooks/cryptroot: cannot open /proc/mounts: No such file
cryptsetup: ERROR: Couldn't resolve device
    /dev/disk/by-uuid/939cb4b1-46d5-470b-958b-a5f2de176608
/proc/devices: fopen failed: そのようなファイルやディレクトリはありません
Failed to set up list of device-mapper major numbers
Incompatible libdevmapper 1.02.155 (2018-12-18) and kernel driver (unknown version).
Command failed.
cryptsetup: WARNING: Couldn't determine cipher modules to load for lvmcrypt4b2
grep: /proc/cpuinfo: そのようなファイルやディレクトリはありません
W: Couldn't identify type of root file system for fsck hook
depmod: WARNING: could not open modules.order at /var/tmp/mkinitramfs_gHjH8y/lib/modules/4.19.97-v7l+: No such file or directory
depmod: WARNING: could not open modules.builtin at /var/tmp/mkinitramfs_gHjH8y/lib/modules/4.19.97-v7l+: No such file or directory
```

対象のカーネルのバージョンを追加の引数に指定しました。
これでも `/proc` などをマウントしていないと、何かがうまくいっていなさそうでした。

```
pi@raspi4b3:~$ sudo chroot /tmp/raspi4b2/ mkinitramfs -o /boot/initramfs.gz 4.19.118-v7l+
cryptsetup: WARNING: Permissive UMASK (0022). Private key material within the
    initrd might be left unprotected.
/usr/share/initramfs-tools/hooks/cryptroot: 64: /usr/share/initramfs-tools/hooks/cryptroot: cannot open /proc/mounts: No such file
cryptsetup: WARNING: Couldn't determine root device
sed: /proc/cmdline を読み込めません: そのようなファイルやディレクトリはありません
grep: /proc/swaps: そのようなファイルやディレクトリはありません
/usr/share/initramfs-tools/hooks/cryptroot: 64: /usr/share/initramfs-tools/hooks/cryptroot: cannot open /proc/mounts: No such file
cryptsetup: ERROR: Couldn't resolve device
    /dev/disk/by-uuid/939cb4b1-46d5-470b-958b-a5f2de176608
/proc/devices: fopen failed: そのようなファイルやディレクトリはありません
Failed to set up list of device-mapper major numbers
Incompatible libdevmapper 1.02.155 (2018-12-18) and kernel driver (unknown version).
Command failed.
cryptsetup: WARNING: Couldn't determine cipher modules to load for lvmcrypt4b2
grep: /proc/cpuinfo: そのようなファイルやディレクトリはありません
W: Couldn't identify type of root file system for fsck hook
```

## 追加で bind mount して mkinitramfs (成功)

最終的に `/proc`, `/dev`, `/sys` を bind mount するとうまくいきました。

```
130 pi@raspi4b3:~$ sudo chroot /tmp/raspi4b2/ mkinitramfs -o /boot/initramfs.gz 4.19.118-v7l+
cryptsetup: WARNING: Permissive UMASK (0022). Private key material within the
    initrd might be left unprotected.
/usr/share/initramfs-tools/hooks/cryptroot: 64: /usr/share/initramfs-tools/hooks/cryptroot: cannot open /proc/mounts: No such file
cryptsetup: WARNING: Couldn't determine root device
sed: /proc/cmdline を読み込めません: そのようなファイルやディレクトリはありません
grep: /proc/swaps: そのようなファイルやディレクトリはありません
/usr/share/initramfs-tools/hooks/cryptroot: 64: /usr/share/initramfs-tools/hooks/cryptroot: cannot open /proc/mounts: No such file
cryptsetup: ERROR: Couldn't resolve device
    /dev/disk/by-uuid/939cb4b1-46d5-470b-958b-a5f2de176608
/proc/devices: fopen failed: そのようなファイルやディレクトリはありません
Failed to set up list of device-mapper major numbers
Incompatible libdevmapper 1.02.155 (2018-12-18) and kernel driver (unknown version).
Command failed.
cryptsetup: WARNING: Couldn't determine cipher modules to load for lvmcrypt4b2
grep: /proc/cpuinfo: そのようなファイルやディレクトリはありません
W: Couldn't identify type of root file system for fsck hook
pi@raspi4b3:~$ sudo mount --bind /proc /tmp/raspi4b2/proc
pi@raspi4b3:~$ sudo chroot /tmp/raspi4b2/ mkinitramfs -o /boot/initramfs.gz 4.19.118-v7l+
cryptsetup: WARNING: Permissive UMASK (0022). Private key material within the
    initrd might be left unprotected.
cryptsetup: ERROR: Couldn't resolve device /dev/mapper/vg4b2-root4b2
cryptsetup: WARNING: Couldn't determine root device
cryptsetup: ERROR: Couldn't resolve device
    /dev/disk/by-uuid/939cb4b1-46d5-470b-958b-a5f2de176608
W: Couldn't identify type of root file system for fsck hook
pi@raspi4b3:~$ sudo mount --bind /dev /tmp/raspi4b2/dev
pi@raspi4b3:~$ sudo chroot /tmp/raspi4b2/ mkinitramfs -o /boot/initramfs.gz 4.19.118-v7l+
cryptsetup: WARNING: Permissive UMASK (0022). Private key material within the
    initrd might be left unprotected.
cryptsetup: ERROR: Couldn't find sysfs directory for 254:25
pi@raspi4b3:~$ sudo mount --bind /sys /tmp/raspi4b2/sys
pi@raspi4b3:~$ sudo chroot /tmp/raspi4b2/ mkinitramfs -o /boot/initramfs.gz 4.19.118-v7l+
cryptsetup: WARNING: Permissive UMASK (0022). Private key material within the
    initrd might be left unprotected.
pi@raspi4b3:~$
```

## initramfs.gz の中身確認

このような感じで `initramfs.gz` の中身を確認できます。
以前の記事で鍵ファイルが 0 バイトになっていたのを直した部分は
次の記事に分割しています。

```
pi@raspi4b3:~$ file /tmp/raspi4b2/boot/initramfs.gz
/tmp/raspi4b2/boot/initramfs.gz: gzip compressed data, last modified: Thu May 28 11:03:40 2020, from Unix, original size 30624256
pi@raspi4b3:~$ zcat /tmp/raspi4b2/boot/initramfs.gz > /tmp/initramfs
pi@raspi4b3:~$ file /tmp/initramfs
/tmp/initramfs: ASCII cpio archive (SVR4 with no CRC)
pi@raspi4b3:~$ cpio -it < /tmp/initramfs | less
pi@raspi4b3:~$ (mkdir -p /tmp/initrd && cd /tmp/initrd && cpio -id < /tmp/initramfs)
pi@raspi4b3:~$ ls -al /tmp/initrd/cryptroot/
合計 16
drwxr-xr-x 3 pi pi 4096  5月 28 20:09 .
drwxr-xr-x 8 pi pi 4096  5月 28 20:09 ..
-rw-r--r-- 1 pi pi  118  5月 28 20:09 crypttab
drwx------ 2 pi pi 4096  5月 28 20:09 keyfiles
pi@raspi4b3:~$ ls -al /tmp/initrd/cryptroot/keyfiles/
合計 8
drwx------ 2 pi pi 4096  5月 28 20:09 .
drwxr-xr-x 3 pi pi 4096  5月 28 20:09 ..
-r-------- 1 pi pi    0  5月 28 20:09 lvmcrypt4b2.key
pi@raspi4b3:~$ ls -al /tmp/raspi4b2/etc/keys/
合計 8
drwxr-xr-x   2 root root 4096  3月  2 00:05 .
drwxr-xr-x 104 root root 4096  5月 28 18:03 ..
-r--------   1 root root    0  3月  2 00:05 lvmcrypt4b2.key
pi@raspi4b3:~$
```

## initramfs.gz をコピー

MacBook Pro に SD カードをマウントして、
initramfs.gz をコピーしました。

```
%  rsync -av raspi4b3:/tmp/raspi4b2/boot/initramfs.gz /Volumes/boot/initramfs.gz
```

## 取り外し

すべて `umount` して `vgchange -a` で `n` にすると安全に取り外せるようになるようです。

```
pi@raspi4b3:~$ sudo umount /tmp/raspi4b2/sys
pi@raspi4b3:~$ sudo umount /tmp/raspi4b2/proc
pi@raspi4b3:~$ sudo umount /tmp/raspi4b2/dev
pi@raspi4b3:~$ sudo umount /tmp/raspi4b2/boot
pi@raspi4b3:~$ sudo umount /tmp/raspi4b2
3 pi@raspi4b3:~$ sudo vgs
  VG    #PV #LV #SN Attr   VSize  VFree
  vg4b2   1  13   0 wz--n- <3.64t <265.44g
  vg4b3   1  13   0 wz--n- <3.64t <265.44g
pi@raspi4b3:~$ sudo vgchange -an vg4b2
  0 logical volume(s) in volume group "vg4b2" now active
pi@raspi4b3:~$
```

## 再起動

SD カードと USB HDD を付け直すと起動に成功しました。

## hook 追加

自動で initramfs を更新しないと、
手動実行を忘れた時や `unattended-upgrades` で更新された時に再起動に失敗してしまうので、
`/etc/kernel/postinst.d/local-mkinitramfs`
に以下の内容のファイルを置いて実行属性をつけて、
自動で更新されるようにしました。

```bash
#!/bin/sh -e
version="$1"
mkinitramfs -o "/boot/initramfs-${version}.gz" "${version}" >&2
version_suffix=$(echo "$version" | sed -e 's/^[0-9.]*-//')
current_suffix=$(uname -r | sed -e 's/^[0-9.]*-//')
if [ "$version_suffix" = "$current_suffix" ]; then
  cp -v "/boot/initramfs-${version}.gz" /boot/initramfs.gz >&2
fi
```

## 感想

initramfs を使うようにした時に懸念していた通り、
再起動に失敗することが起きたので、
復旧や根本的な対処を試すことができました。
