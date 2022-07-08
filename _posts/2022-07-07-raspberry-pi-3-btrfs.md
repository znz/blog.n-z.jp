---
layout: post
title: "Raspberry Pi 3B+にRaspberry Pi OS Liteをbtrfsで入れた"
date: 2022-07-07 16:05 +0900
comments: true
category: blog
tags: raspi linux
---

## 動作確認環境

- Raspberry Pi 3B+
- Raspberry Pi OS Lite 64-bit (2022-04-04 の Bullseye)
- 8GB の micro SDHC
- 3TB の USB HDD

## 事前準備

まず 8GB の micro SDHC カードに Raspberry Pi Imager で Raspberry Pi OS Lite 64-bit (2022-04-04 の Bullseye) を書き込んでおきました。
そして、その micro SDHC カード、USB HDD (3TB)、有線 LAN、HDMI、USB 日本語キーボードを接続して起動しました。

3B+ は USB HDD からの起動がうまくいかなかったので、毎回 micro SDHC からの起動にしているため、
USB HDD は事前に GNU Parted で1パーティションだけにしておきました。
Parted の `mkpart` は引数を指定して実行すれば fs-type は省略できたので、以下のようにしました。

```
sudo parted /dev/sda
rm 1
rm 2
mkpart primary 0% 100%
print
q
```

## 起動直後

一度 root パーティションのリサイズと自動再起動があった後、キーボードの選択になるので、
Other → Japanese → Japanese - Japanese (OADG 109A)
と選びました。

そして最初のユーザー名とパスワードの設定になるので、適当に設定します。

## 自動設定

試行錯誤するのに毎回コマンドを入力するのは大変なので、シェルスクリプトにまとめて、それを実行しました。
ほぼ自動で進むようにしましたが、 `luksFormat` のような本当に危険なところだけはデフォルトのまま止まるようにしています。

```
wget -N https://www.n-z.jp/tmp/2022/raspi3bp.txt
chmod +x ./raspi3bp.txt
./raspi3bp.txt
```

## 設定内容の解説

以下は自動設定シェルスクリプトでやっている内容の解説です。

### 冒頭

シェルスクリプトを書くときのいつもの定型文の `set` と後で使う変数の設定です。

```
#!/bin/bash
set -euxo pipefail

ROOT_DEV=/dev/sda1
CRYPT_NAME=crypt3bp
CRYPT_KEY_NAME="$CRYPT_NAME"
CRYPT_KEY_SIZE=4096
ROOT_LABEL=raspi3bp
```

### etckeeper インストール

`etckeeper` は趣味でいつも入れているので、初期設定の履歴も残るように最初に入れています。

```
sudo apt-get update -y
sudo apt-get install etckeeper -y
sudo etckeeper vcs gc
```

## 暗号化設定

btrfs 自体に暗号化の機能は (まだ) なさそうなので、LUKS での暗号化を挟みます。

鍵ファイルは `openssl rand` でランダムな内容のファイルを作成しています。
長さは適当に 4096 バイトにしています。

`cryptsetup luksFormat` の第2引数に鍵ファイルを指定すると、パスフレーズの入力が省略できたので、それを使って自動化しています。
起動しなくなったときのリカバリ用にパスフレーズを設定しておきたいなら、後で `sudo cryptsetup luksAddKey /dev/sda1 --key-file /etc/keys/*.key` のような感じで追加します。

起動時に使う鍵ファイルの置き場所はいくつか候補がありますが、今回は initramfs の中に埋めこむことにしました。
平文で micro SDHC の中 (initramfs の中と最初に生成したコピー元の root パーティションの中) に入ることになるので、USB HDD とセットで紛失すると暗号化が解除できてしまうことになります。

`/etc/cryptsetup-initramfs/conf-hook` の `KEYFILE_PATTERN` で initramfs の中に鍵を埋め込みます。
`lsinitramfs /boot/initramfs.gz | grep cryptroot` で `cryptroot/keyfiles/*.key` に埋め込まれているのが確認できます。

`/boot/config.txt` の末尾に `initramfs initramfs.gz followkernel` を追加して initramfs を使う設定をします。
ファイル名が間違っていると、エラーもでずに起動の途中で止まるだけなので無駄に悩むことになります。

`/etc/kernel/postinst.d/local-mkinitramfs` にカーネルの更新時に initramfs も更新する設定を作成しています。

```
sudo apt-get install cryptsetup -y

#sudo parted /dev/sda
sudo mkdir -p /etc/keys
sudo openssl rand -out "/etc/keys/$CRYPT_KEY_NAME.key" 4096
sudo cryptsetup luksFormat "$ROOT_DEV" "/etc/keys/$CRYPT_KEY_NAME.key"
sudo cryptsetup open --type luks "$ROOT_DEV" "$CRYPT_NAME" --key-file "/etc/keys/$CRYPT_KEY_NAME.key"
echo "$CRYPT_NAME" "UUID=$(lsblk -no uuid "$ROOT_DEV")" "/etc/keys/$CRYPT_KEY_NAME.key" luks,initramfs | sudo tee -a /etc/crypttab >/dev/null
echo 'KEYFILE_PATTERN="/etc/keys/*.key"' | sudo tee -a /etc/cryptsetup-initramfs/conf-hook >/dev/null

sudo mkinitramfs -o /boot/initramfs.gz
echo initramfs initramfs.gz followkernel | sudo tee -a /boot/config.txt >/dev/null
sudo tee /etc/kernel/postinst.d/local-mkinitramfs >/dev/null <<'EOF'
#!/bin/sh -e
version="$1"
version_suffix=$(echo "$version" | sed -e 's/^[0-9.]*-//')
current_suffix=$(uname -r | sed -e 's/^[0-9.]*-//')
if [ "$version_suffix" = "$current_suffix" ]; then
  mkinitramfs -o "/boot/initramfs.gz" "${version}" >&2
fi
EOF
sudo chmod +x /etc/kernel/postinst.d/local-mkinitramfs
sudo etckeeper commit "local mkinitramfs"
```

### btrfs 作成

`btrfs` コマンドが入っていなかったのでインストールして、 `mkfs.btrfs` でフォーマットしています。
何度か試していると、ファイルシステムっぽい何かに見えることがあるのか、止まってしまうことがあったので、 `-f` オプションを付けています。

`/tmp/target` にマウントして
[Snapper の推奨ファイルシステムレイアウト](https://wiki.archlinux.jp/index.php/Snapper#.E6.8E.A8.E5.A5.A8.E3.83.95.E3.82.A1.E3.82.A4.E3.83.AB.E3.82.B7.E3.82.B9.E3.83.86.E3.83.A0.E3.83.AC.E3.82.A4.E3.82.A2.E3.82.A6.E3.83.88)
を参考にしたレイアウトを作成しています。

```
sudo apt-get install btrfs-progs -y

mkdir -p /tmp/target
sudo mkfs.btrfs -f -L "$ROOT_LABEL" "/dev/mapper/$CRYPT_NAME"
sudo mount "/dev/mapper/$CRYPT_NAME" /tmp/target
cd /tmp/target
sudo btrfs subvolume create @
sudo btrfs subvolume create @home
sudo btrfs subvolume create @snapshots
sudo btrfs subvolume create @var_log

sudo btrfs subvolume create @tmp
sudo btrfs subvolume create @var_tmp
sudo btrfs subvolume create @var_cache

#sudo btrfs subvolume create @var_lib_snapd
#sudo btrfs subvolume create @var_snap
#sudo btrfs subvolume create @snap

#sudo btrfs subvolume create @var_lib_docker
#sudo btrfs subvolume create @var_lib_machines

sudo btrfs subvolume list .
```

### マウントとコピー

作成したレイアウトでマウントしなおして、 `rsync` でコピーしています。

スワップファイルは最初に 0 バイトで作成して `chattr +C` を設定する必要があるので、
`rsync` からは除外しています。
ファイルサイズは再起動後に `dphys-swapfile` で勝手に 100M になったので、適当で良さそうです。
(スワップファイルはスナップショットに影響があるようなので、後で何か変更するかもしれません。)

```
cd
sudo umount /tmp/target
sudo mount -o defaults,lazytime,commit=120,compress=lzo,subvol=@ "/dev/mapper/$CRYPT_NAME" /tmp/target
cd /tmp/target
sudo mkdir -p home
sudo mount -o subvol=@home "/dev/mapper/$CRYPT_NAME" home
sudo mkdir -p var/log
sudo mount -o subvol=@var_log "/dev/mapper/$CRYPT_NAME" var/log
sudo mkdir -p tmp
sudo mount -o subvol=@tmp "/dev/mapper/$CRYPT_NAME" tmp
sudo mkdir -p var/tmp
sudo mount -o subvol=@var_tmp "/dev/mapper/$CRYPT_NAME" var/tmp
sudo mkdir -p var/cache
sudo mount -o subvol=@var_cache "/dev/mapper/$CRYPT_NAME" var/cache
sudo dphys-swapfile swapoff
sudo rsync -aAHS --info=progress2 --exclude={"/var/swap","/boot/*","/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / ./
sudo truncate -s 0 var/swap
sudo chattr +C var/swap
sudo fallocate -l 2G var/swap
```

### マウント設定

元のルートパーティションのマウント設定をコメントアウトして、
btrfs のマウント設定を追加しています。

ほとんどのマウントオプションはサブボリュームごとの設定ができないようなので、 `subvol=@` のみに設定しています。
将来個別設定に対応する可能性があるので、 `mount` コマンドの出力などでオプションがちゃんと設定されていることを確認しておく必要があります。

起動時のルートの指定として
`/boot/cmdline.txt` の
`console=serial0,115200 console=tty1 root=PARTUUID=1e31f78c-02 rootfstype=ext4 fsck.repair=yes rootwait`
のような指定のうち、
`root=PARTUUID=1e31f78c-02 rootfstype=ext4`
の部分を
`root=LABEL=raspi3bp rootflags=subvol=@ rootfstype=btrfs`
のように置き換えています。

`rootflags` は `/etc/fstab` の設定が優先されるようなので、 `subvol=@` だけ指定しています。

```
sudo sed -i -e '/1$/s/^/#/' etc/fstab
sudo tee -a etc/fstab >/dev/null <<EOF
LABEL=$ROOT_LABEL / btrfs defaults,lazytime,commit=120,compress=lzo,subvol=@ 0 0
LABEL=$ROOT_LABEL /home btrfs subvol=@home 0 0
LABEL=$ROOT_LABEL /var/log btrfs subvol=@var_log 0 0
LABEL=$ROOT_LABEL /tmp btrfs subvol=@tmp 0 0
LABEL=$ROOT_LABEL /var/tmp btrfs subvol=@var_tmp 0 0
LABEL=$ROOT_LABEL /var/cache btrfs subvol=@var_cache 0 0
LABEL=$ROOT_LABEL /.snapshots btrfs subvol=@snapshots 0 0
LABEL=$ROOT_LABEL /mnt/btr_pool btrfs subvolid=5 0 0
EOF
if [ ! -f /boot/cmdline.txt.org ]; then
  sudo cp -a /boot/cmdline.txt /boot/cmdline.txt.org
fi
sudo sed -i -e "s/root.*ext4/root=LABEL=$ROOT_LABEL rootflags=subvol=@ rootfstype=btrfs/" /boot/cmdline.txt
```

## まとめ

config.txt の initramfs のファイル名の指定が間違っていて、起動しない原因を調べるのが大変でしたが、
とりあえず普通に起動するところまでできました。
