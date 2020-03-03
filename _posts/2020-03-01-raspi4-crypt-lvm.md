---
layout: post
title: "Raspberry Pi 4でUSB HDDの暗号化LVMを使う"
date: 2020-03-01 23:01 +0900
comments: true
category: blog
tags: raspi linux
---
Raspberry Pi 4B を `/boot` だけ micro SD カードに残して `/` は USB HDD の暗号化パーティションの中に設定して起動できるようになったので、その手順のメモです。

情報が少なくて、使い方を把握しきれていないのですが、 LVM のところは LVM thin provisioning にしてみました。


<!--more-->

## 動作確認環境

- Raspberry Pi 4B (4GB モデル)
- Raspbian Buster Lite
- 8GB の micro SDHC
- 4TB の USB HDD

自動起動できるように暗号化の鍵は `/boot/initramfs.gz` に平文で保存しています。
最初の鍵を SD カード上の `/etc/keys` で作成しているので、破棄する時にはそこも削除する必要があります。

## SD カード初期化

まずは普通に SD カードにインストールします。

- <https://www.raspberrypi.org/> から上の Downloads, Raspbian と辿って、 Raspbian Buster Lite をダウンロード (今回は Release date: 2020-02-13 で Size: 434 MB だった)
- `openssl dgst -sha256 ~/Downloads/2020-02-13-raspbian-buster-lite.zip` で sha256 を出力
- sha256 をコピーしてダウンロードページで検索を使って一致するのを確認 (目視で比較する必要はないという豆知識)
- 展開して img ファイルを取り出す
- ダウンロードページの上の方の文の [installation guide](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) のリンクを辿って OS ごとの手順を確認
- Mac OS のページの説明に従って書き込み
  - `diskutil list`
  - `diskutil unmountDisk /dev/disk2`
  - `sudo dd bs=1m if=$HOME/Downloads/2020-02-13-raspbian-buster-lite.img of=/dev/rdisk2 conv=sync` (途中で control+T を押すと進捗が確認できる)
  - `diskutil eject /dev/rdisk2`
- SD カードを Raspberry Pi 4B に挿して真ん中の micro HDMI に HDMI ケーブル、 USB HDD と USB キーボードを挿して起動
- ユーザー: `pi` , パスワード: `raspberry` でログイン

## 初期設定

`etckeeper` で設定変更を追いかけられるようにしてから `raspi-config` で設定しています。
(`sudo etckeeper vcs gc` は `git gc` を実行しているだけで必須ではないですが、 `/etc/.git` の容量削減ができます。)

```
sudo apt update
sudo apt install etckeeper
sudo etckeeper vcs gc
sudo raspi-config
```

- ホスト名設定 (`sudo hostnamectl set-hostname ホスト名` で設定するより `raspi-config` で設定する方が良さそう)
- ja_JP.UTF-8 ロケール生成、タイムゾーン設定、 Wi-Fi の国など l10n 設定
- (コンソールで文字化けする可能性があるので、デフォルトのロケールは英語のままの方がいいかも)
- (キーボードはどれを選べば日本語キーボードになるのかわからなかったのでそのまま)
- SSH server を有効に
- 再起動

## 初期化に必要なパッケージなどをインストール

ここからは ssh で接続して設定します。

`~/.ssh/config` には以下のような感じで設定しました。

```
Host raspi4b1.local raspi4b1
HostKeyAlias raspi4b1
Hostname raspi4b1.local
User pi
UserKnownHostsFile ~/.ssh/raspi.known_hosts
IdentitiesOnly yes
IdentityFile ~/.ssh/id_ed25519
```

暗号化に使う `cryptsetup` と鍵生成の時のエントロピー待ちを減らすための `haveged` (必須ではない) と `lvm2` をインストールします。
依存で `thin-provisioning-tools` も入ります。

```
sudo apt install cryptsetup
sudo apt install haveged
sudo apt install lvm2
```

## USB HDD 初期化

<https://wiki.alpinelinux.org/wiki/LVM_on_LUKS> を参考にして `sudo parted -a optimal` でパーティション設定します。
つないだのが 4TB の HDD で 2TiB を超えているので GPT にしています。
ESP (EFI System Partition) も作っていますが、今のところ使っていません。
Raspberry Pi 4B が USB 起動に対応したら使えるかもしれません。

```
print
mklabel gpt
Yes
mkpart primary fat32 0% 200M
name 1 esp
set 1 esp on
mkpart primary ext4 200M 100%
set 2 lvm on
name 2 crypto-luks
print
quit
```

LVM のパーティションに file system として ext4 を設定していますが、最終的にインストール後には消えていたので、実は違う、というのは気にしなくても良さそうでした。

## LUKS で暗号化パーティションのフォーマット

ここのパスフレーズは後で鍵ファイルの登録をするまでの操作に使ったり、
SD カードが壊れて他の環境に繋いでデータを救出する時に使います。

鍵は失うと復元不可能になるという欠点と、 `luksRemoveKey` で削除してしまえば、ディスク全体を `shred` などで書き込みをしなくても消去相当にできる、という利点があります。

```
$ sudo cryptsetup luksFormat /dev/sda2

WARNING!
========
This will overwrite data on /dev/sda2 irrevocably.

Are you sure? (Type uppercase yes): YES
Enter passphrase for /dev/sda2:
Verify passphrase:
```

## 暗号化パーティションをマウントして LVM の初期化

暗号化パーティションを手動でマウントして Physical volume を作成します。

ここからは複数ディスクを同時接続してファイルを救出する時に困らないように、マシンごとに別の名前になるように `4b1` とつけています。
2台目なら `4b2` というようにしています。
(LVM で同じ名前を使っているディスクを同時に接続して使おうとしたら何か問題があったはず。)
(名前に `-` や `_` も使えるはずですが、 `/dev/mapper/` で `_` が `--` になるのだったか何だったか忘れましたが、そのまま出てこないところがあって不便だった覚えがあるので、英数字のみ使っています。)

```
$ sudo cryptsetup luksOpen /dev/sda2 lvmcrypt4b1
Enter passphrase for /dev/sda2:
$ sudo pvcreate /dev/mapper/lvmcrypt4b1
  Physical volume "/dev/mapper/lvmcrypt4b1" successfully created.
```

`sudo pvdisplay` や `sudo pvs` で確認します。
消すのは `pvremove` です。

次に volume group 作成をします。
4TB の USB HDD に対してはデフォルトの physical extent size は小さいようなので、
大きめの値を指定します。(ネットでみつけた例では 32MB を指定していました。)

```
$ sudo vgcreate -s 64MB vg4b1 /dev/mapper/lvmcrypt4b1
  Volume group "vg4b1" successfully created
```

`sudo vgdisplay` や `sudo vgs` で確認します。
消すのは `vgremove` です。

## thinpool 作成

LVM thinpool を作成します。

```
$ sudo lvcreate --thin -L 3T -c 64K vg4b1/thin4b1
  Thin pool volume with chunk size 64.00 KiB can address at most 15.81 TiB of data.
  Logical volume "thin4b1" created.
```

`-c 64K` がないと以下のように警告が出ていました。

```
$ sudo lvcreate --thin -L 3T vg4b1/thin4b1
  Thin pool volume with chunk size 2.00 MiB can address at most 506.00 TiB of data.
  WARNING: Pool zeroing and 2.00 MiB large chunk size slows down thin provisioning.
  WARNING: Consider disabling zeroing (-Zn) or using smaller chunk size (<512.00 KiB).
  Logical volume "thin4b1" created.
```

2020-03-03 追記: 残っている警告にも対処するために[後日の作り直し]({% post_url 2020-03-03-raspi4-crypt-lvm %})では `sudo lvcreate --thin -L 900G -Zn vg4b1/thin4b1` のように `-Zn` をつけました。

`sudo lvdisplay` や `sudo lvs` で確認します。
消すのは `lvremove` です。

## lsblk

lsblk でここまでの状況をみるとこのようになっていました。

```
$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda                         8:0    0  3.7T  0 disk
├─sda1                      8:1    0  190M  0 part
└─sda2                      8:2    0  3.7T  0 part
  └─lvmcrypt4b1           254:0    0  3.7T  0 crypt
    ├─vg4b1-thin4b1_tmeta 254:1    0    3G  0 lvm
    │ └─vg4b1-thin4b1     254:3    0    3T  0 lvm
    └─vg4b1-thin4b1_tdata 254:2    0    3T  0 lvm
      └─vg4b1-thin4b1     254:3    0    3T  0 lvm
mmcblk0                   179:0    0  7.3G  0 disk
├─mmcblk0p1               179:1    0  256M  0 part  /boot
└─mmcblk0p2               179:2    0  7.1G  0 part  /
```

## root パーティション作成

thinpool の中に root パーティションを作成して、フォーマットします。

```
sudo lvcreate --thin -V 10G -n root4b1 vg4b1/thin4b1
sudo mkfs.ext4 /dev/vg4b1/root4b1
```

rsync でルートパーティションのファイルを初回コピーします。

```
mkdir /tmp/root4b1
sudo mount /dev/vg4b1/root4b1 /tmp/root4b1
time sudo rsync -avx / /tmp/root4b1/
```

## 鍵ファイル作成

```
$ sudo install -d /etc/keys
$ sudo sh -c 'umask 377; openssl rand -out /etc/keys/lvmcrypt4b1.key'
$ sudo cryptsetup luksAddKey /dev/sda2 /etc/keys/lvmcrypt4b1.key
Enter any existing passphrase:
```

`sudo cryptsetup luksDump /dev/sda2` で keyslots に追加されているのを確認します。

## 起動処理変更

```
$ export EDITOR=vi
$ sudoedit /etc/fstab
(/ のパーティションを /dev/vg4b1/root4b1 に変更)
$ ls -la /dev/disk/by-uuid/
(sda2 をさしている uuid を確認)
$ sudoedit /etc/crypttab
(lvmcrypt4b1 /dev/disk/by-uuid/(sda2のUUID) /etc/keys/lvmcrypt4b1.key luks,initramfs を追加)
$ sudo cp /boot/cmdline.txt /boot/cmdline.txt.bak
$ sudoedit /boot/cmdline.txt
(root の変更と cryptdevice の追加)
$ echo 'initramfs initramfs.gz followkernel' | sudo tee -a /boot/config.txt
```

crypttab は `/dev/mapper/` 以下などに出てくる名前, 暗号化された内容を読み書きするブロックデバイス, 鍵ファイルのパス, オプションという指定で、
オプションは luks でブロックデバイスにメタ情報をかくなら luks で、 luks を使わずにブロックデバイス全体を使うなら細かく指定します。
initramfs というのは mkinitramfs を実行した時に `/` にマウントされているデバイス以外の鍵を initramfs に入れる場合に必要なオプションで、
`cryptsetup-initramfs` の `/usr/share/initramfs-tools/hooks/cryptroot` がみています。
最初は SD カードの方が `/` になっているので必要でした。

<https://www.raspberrypi.org/documentation/configuration/config-txt/boot.md> に書いてあるように initramfs の行だけは他の行と違って `=` 区切りでキーと値という設定ではないので注意が必要です。

設定変更後は以下のようになります。

```
 $ cat /etc/fstab
 proc            /proc           proc    defaults          0       0
 PARTUUID=738a4d67-01  /boot           vfat    defaults          0       2
 #PARTUUID=738a4d67-02  /               ext4    defaults,noatime  0       1
 /dev/vg4b1/root4b1  /               ext4    defaults,noatime  0       1
 # a swapfile is not a swap partition, no line here
 #   use  dphys-swapfile swap[on|off]  for that
 $ cat /tmp/root4b1/etc/crypttab
 # <target name>	<source device>		<key file>	<options>
 lvmcrypt4b1 /dev/disk/by-uuid/73a715f6-23e9-4cc5-83bb-8c32d6fda64c /etc/keys/lvmcrypt4b1.key luks,initramfs
 $ cat /boot/cmdline.txt
 console=serial0,115200 console=tty1 root=/dev/vg4b1/root4b1 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait cryptdevice=/dev/disk/by-uuid/73a715f6-23e9-4cc5-83bb-8c32d6fda64c:lvmcrypt4b1
```

## initramfs 作成

initramfs を作成します。
まだ確認がとれていないのですが、カーネルが更新されたら手動で生成し直す必要があるかもしれません。

```
$ echo 'KEYFILE_PATTERN="/etc/keys/*.key"' | sudo tee -a /etc/cryptsetup-initramfs/conf-hook
KEYFILE_PATTERN="/etc/keys/*.key"
$ sudo mkinitramfs -o /boot/initramfs.gz
cryptsetup: WARNING: Permissive UMASK (0022). Private key material within the
    initrd might be left unprotected.
cryptsetup: ERROR: Couldn't resolve device /dev/root
cryptsetup: WARNING: Couldn't determine root device
```

`KEYFILE_PATTERN` を設定していないと、最初の警告が出ず、 initramfs に key ファイルが入っていませんでした。

`lsinitramfs -l /boot/initramfs.gz | grep cryptroot` で `cryptroot/crypttab` と `cryptroot/keyfiles/lvmcrypt4b1.key` が入っているのを確認します。

## 変更後のコピー

`etc/crypttab`, `etc/fstab`, `etc/cryptsetup-initramfs/conf-hook`, `etc/keys/` の変更を反映するためにコピーし直します。

```
time sudo rsync -avx --delete / /tmp/root4b1/
```

## 再起動

再起動して `/` が `/dev/vg4b1/root4b1` になっていたら成功です。

## まとめ

SD カードの `/boot` から、暗号化 LVM の中の `/` を使って起動するところまでの手順をまとめてみました。

試行錯誤の過程は省いて、最低限の手順の説明だけになっているので、 `/boot` のファイルの編集ミスがあったら別マシンに SD カードをさして編集などは工夫してください。

カーネルが更新されたらどうするかとか、 `/boot` が壊れたらどうするかとか、 thinpool の使い方などについてはまた後日書くかもしれません。
