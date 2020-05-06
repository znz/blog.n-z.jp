---
layout: post
title: "glusterのsnapshotを定期的に取るようにした"
date: 2020-05-06 17:37 +0900
comments: true
category: blog
tags: gluster debian linux
---
[USB HDDの暗号化LVMのLVをthin poolにした]({% post_url 2020-03-03-raspi4-crypt-lvm %})後、
gluster の方も thin pool にしていたのですが、
まだ snapshot を試していなかったので、
ちょっと試してみてから、
毎日 snapshot を取る設定をしてみました。

<!--more-->

## 環境

- Raspberry Pi 4B (4GB モデル)
- Raspbian Buster Lite
- 8GB の micro SDHC
- 4TB の USB HDD

## thin pool での gluster 設定

### thin pool と brick 作成

thin pool と brick 用の xfs を作成しました。

`mkfs.xfs` に `-i size=512 -n size=8192 -d su=128k,sw=10` を指定している例もありましたが、
デフォルトで問題なさそうだったので外しました。

```
pi@raspi4b1:~ $ sudo lvcreate --thin -L 2T -Zn vg4b1/gfspool4b1
  Thin pool volume with chunk size 1.00 MiB can address at most 253.00 TiB of data.
  Logical volume "gfspool4b1" created.
pi@raspi4b1:~ $ sudo lvcreate --thin -V 1T -n hyrule1 vg4b1/gfspool4b1
  Logical volume "hyrule1" created.
pi@raspi4b1:~ $  sudo mkfs.xfs -f /dev/vg4b1/hyrule1
meta-data=/dev/vg4b1/hyrule1     isize=512    agcount=33, agsize=8388480 blks
	 =                       sectsz=4096  attr=2, projid32bit=1
	 =                       crc=1        finobt=1, sparse=1, rmapbt=0
	 =                       reflink=0
data     =                       bsize=4096   blocks=268435456, imaxpct=5
	 =                       sunit=128    swidth=256 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=131072, version=2
	 =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
pi@raspi4b1:~ $
```

他のマシンでも同様に作成しました。

```
pi@raspi4b2:~ $ sudo lvcreate --thin -V 1T -n hyrule2 vg4b2/gfspool4b2
  Logical volume "hyrule2" created.
pi@raspi4b2:~ $ sudo mkfs.xfs /dev/vg4b2/hyrule2
meta-data=/dev/vg4b2/hyrule2     isize=512    agcount=33, agsize=8388480 blks
	   =                       sectsz=4096  attr=2, projid32bit=1
	   =                       crc=1        finobt=1, sparse=1, rmapbt=0
	   =                       reflink=0
data     =                       bsize=4096   blocks=268435456, imaxpct=5
	   =                       sunit=128    swidth=256 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=131072, version=2
	   =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
pi@raspi4b2:~ $
```

```
pi@raspi4b3:~ $ sudo lvcreate --thin -V 1T -n hyrule3 vg4b3/gfspool4b3
  Logical volume "hyrule3" created.
pi@raspi4b3:~ $  sudo mkfs.xfs /dev/vg4b3/hyrule3
meta-data=/dev/vg4b3/hyrule3     isize=512    agcount=33, agsize=8388480 blks
	 =                       sectsz=4096  attr=2, projid32bit=1
	 =                       crc=1        finobt=1, sparse=1, rmapbt=0
	 =                       reflink=0
data     =                       bsize=4096   blocks=268435456, imaxpct=5
	 =                       sunit=128    swidth=256 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=131072, version=2
	 =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
pi@raspi4b3:~ $
```

### fstab 設定

色々試行錯誤した結果、以下のようにしました。

- マウントポイントは共通の名前にしました。
- inode64 はデフォルトのようだったのでつけませんでした。
- nouuid はつけませんでした。
- acl はつけようとするとエラーになったのでつけませんでした。(ext3,4 だと明示的に設定が必要で xfs だとそもそもオプションではない?)
- noatime もつけませんでした。
- quota をつけました。

```
pi@raspi4b1:~ $ EDITOR=vi sudoedit /etc/fstab
pi@raspi4b1:~ $ cat /etc/fstab
proc            /proc           proc    defaults          0       0
PARTUUID=738a4d67-01  /boot           vfat    defaults          0       2
#PARTUUID=738a4d67-02  /               ext4    defaults,noatime  0       1
/dev/vg4b1/root4b1  /               ext4    defaults,usrquota,grpquota  0       1
# a swapfile is not a swap partition, no line here
#   use  dphys-swapfile swap[on|off]  for that
/dev/vg4b1/hyrule1 /export/hyrule xfs defaults,usrquota,grpquota 1 2
pi@raspi4b1:~ $ sudo mkdir -p /export/hyrule
pi@raspi4b1:~ $ sudo mount /export/hyrule
```

### probe

gluster はデフォルトだと IPv6 で listen していなかったので、
`sudo gluster peer probe IPv4のホスト名`
としました。

`/etc/hosts` に wireguard でのネットワークでのホスト名を `wg.example.jp` のようなドメインで作成して使っています。

### volume create and start

volume を作成します。

```
pi@raspi4b1:~ $  sudo gluster volume create hyrule replica 3 raspi4b{1,2,3}-v4.wg.example.jp:/export/hyrule/data
volume create: hyrule: success: please start the volume to access data
pi@raspi4b1:~ $ sudo gluster volume start hyrule
volume start: hyrule: success
pi@raspi4b1:~ $
pi@raspi4b1:~ $ sudo gluster volume status
Status of volume: hyrule
Gluster process                             TCP Port  RDMA Port  Online  Pid
------------------------------------------------------------------------------
Brick raspi4b1-v4.wg.example.jp:/export/hyr
ule/data                                    49152     0          Y       20300
Brick raspi4b2-v4.wg.example.jp:/export/hyr
ule/data                                    49152     0          Y       636
Brick raspi4b3-v4.wg.example.jp:/export/hyr
ule/data                                    49152     0          Y       15136
Self-heal Daemon on localhost               N/A       N/A        Y       20323
Self-heal Daemon on raspi4b2-v4.wg.example.
jp                                          N/A       N/A        Y       661
Self-heal Daemon on raspi4b3-v4.wg.example.
jp                                          N/A       N/A        Y       15160

Task Status of Volume hyrule
------------------------------------------------------------------------------
There are no active volume tasks

pi@raspi4b1:~ $
```

### mount

`sudo mount -t glusterfs -o acl raspi4b1-v4.wg.example.jp:hyrule /tmp/hyrule/` などでマウントテストしてうまくいったので、
`fstab` には以下のように設定しました。

```
raspi4b1-v4.wg.example.jp,raspi4b2-v4.wg.example.jp,raspi4b3-v4.wg.example.jp:hyrule /glfs/hyrule glusterfs acl,_netdev 0 0
```

## snapshot

### 作成テスト

末尾にタイムスタンプが付いていると試しに指定する時に面倒なので `no-timestamp` をつけました。

```
pi@raspi4b1:~$ sudo gluster snapshot config hyrule

Snapshot System Configuration:
snap-max-hard-limit : 256
snap-max-soft-limit : 90%
auto-delete : disable
activate-on-create : disable

Snapshot Volume Configuration:

Volume : hyrule
snap-max-hard-limit : 256
Effective snap-max-hard-limit : 256
Effective snap-max-soft-limit : 230 (90%)
pi@raspi4b1:~$ sudo gluster snapshot create ss-01 hyrule no-timestamp
snapshot create: success: Snap ss-01 created successfully
pi@raspi4b1:~$ sudo gluster snapshot list
ss-01
pi@raspi4b1:~$ sudo gluster snapshot info ss-01
(略)
pi@raspi4b1:~$ sudo gluster snapshot status ss-01
(略)
pi@raspi4b1:~$ sudo gluster snapshot activate ss-01
Snapshot activate: ss-01: Snap activated successfully
pi@raspi4b1:~$ sudo gluster snapshot info ss-01
(略)
pi@raspi4b1:~$ sudo gluster snapshot status ss-01
(略)
pi@raspi4b1:~$
```

`sudo mount -t glusterfs raspi4b1-v4.wg.example.jp:/snaps/ss-01/hyrule /tmp/test`
のように `${server}:/snaps/${snapshot_name}/${volume_name}` をマウントして確認しました。

```
pi@raspi4b1:~$ sudo gluster snapshot deactivate ss-01
Deactivating snap will make its data inaccessible. Do you want to continue? (y/n) y
Snapshot deactivate: ss-01: Snap deactivated successfully
```

### 最大数を減らして自動削除

どのくらいの容量になるか未定だったので、
最大 10 個に減らしました。
limit は volume ごとに設定できますが、
auto-delete は全体の設定だけで volume ごとには設定できませんでした。

```
pi@raspi4b1:~$ sudo gluster snapshot config hyrule

Snapshot System Configuration:
snap-max-hard-limit : 256
snap-max-soft-limit : 90%
auto-delete : disable
activate-on-create : disable

Snapshot Volume Configuration:

Volume : hyrule
snap-max-hard-limit : 256
Effective snap-max-hard-limit : 256
Effective snap-max-soft-limit : 230 (90%)
pi@raspi4b1:~$ sudo gluster snapshot config hyrule snap-max-hard-limit 10
Changing snapshot-max-hard-limit will limit the creation of new snapshots if they exceed the new limit.
Do you want to continue? (y/n) y
snapshot config: snap-max-hard-limit for hyrule set successfully
pi@raspi4b1:~$ sudo gluster snapshot config hyrule auto-delete enable
As of now, auto-delete option cannot be set to volumes

Usage:
snapshot config [volname] ([snap-max-hard-limit <count>] [snap-max-soft-limit <percent>]) | ([auto-delete <enable|disable>])| ([activate-on-create <enable|disable>])

1 pi@raspi4b1:~$ sudo gluster snapshot config auto-delete enable
snapshot config: auto-delete successfully set
pi@raspi4b1:~$ sudo gluster snapshot config

Snapshot System Configuration:
snap-max-hard-limit : 256
snap-max-soft-limit : 90%
auto-delete : enable
activate-on-create : disable

Snapshot Volume Configuration:

Volume : hyrule
snap-max-hard-limit : 10
Effective snap-max-hard-limit : 10
Effective snap-max-soft-limit : 9 (90%)
pi@raspi4b1:~$
```

### snapshot create

ばらつきが大きいですが、
13.5 秒から 23 秒ぐらいの範囲で約 18 秒前後かかっていました。

```
pi@raspi4b1:~$ time sudo gluster snapshot create hyrule-snapshot hyrule
snapshot create: success: Snap hyrule-snapshot_GMT-2020.05.06-07.15.28 created successfully

real    0m15.956s
user    0m0.158s
sys     0m0.095s
```

作成を繰り返して
`sudo gluster snapshot list`
で soft limit の 9 個だけ残っているのを確認しました。

### 自動実行

peer のうち 1 台だけに、
以下のような `gluster-snapshot@` を用意して、
`gluster-snapshot@hyrule.timer`
を `enable` と `start` しました。

```
pi@raspi4b3:/etc/systemd/system $ cat gluster-snapshot@.service
[Unit]
Description=Create gluster snapshot of volume %i
OnFailure=notify-to-slack@%n.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/gluster snapshot create %i-snapshot %i
pi@raspi4b3:/etc/systemd/system $ cat gluster-snapshot@.timer
[Unit]
Description=Create gluster snapshot of volume %i

[Timer]
OnCalendar=*-*-* 03:10:00
RandomizedDelaySec=30min
Persistent=true

[Install]
WantedBy=timers.target
pi@raspi4b3:/etc/systemd/system $
```

あとは
`systemctl start gluster-snapshot@hyrule.service` で動作確認をして、
`systemctl status gluster-snapshot@hyrule.service` や `journalctl -u gluster-snapshot@hyrule.service` でログを確認して、
`systemctl list-timers` で実行予定を確認して待つことにしました。

## 感想

[nfs-ganesha-gluster]({% post_url 2020-05-01-nfs-ganesha-gluster %})
と設定の話が前後してしまいましたが、
現状はこのような感じで自宅サーバーを動かしています。
