---
layout: post
title: "qemuでriscv64のDebian環境作成"
date: 2022-01-29 17:00 +0900
comments: true
category: blog
tags: linux debian qemu riscv
---
<https://wiki.debian.org/RISC-V> を参考にして、 qemu で RISC-V の Debian の環境を作ってみました。

<!--more-->

## 確認環境

- ホスト側 Ubuntu 21.10 (impish), Ubuntu 20.04.3 LTS (focal)
- QEMU emulator version 6.0.0 (Debian 1:6.0+dfsg-2expubuntu1.1)
- ゲスト側: Debian GNU/Linux bookworm/sid

## qemu インストール

まず、 `qemu-system-riscv64` コマンドが入っている `qemu-system-misc` をインストールします。
ディスクイメージを作成する環境と別の環境で実行するなら、実行する環境の方にインストールします。

```
sudo apt-get install -y qemu-system-misc
```

## chroot で debootstrap

次に Debian Wiki の「Creating a riscv64 chroot」の `debootstrap` の手順に従って、 `debootstrap` と riscv64 のバイナリをホスト側で動かすための `qemu-user-static` `binfmt-support` と riscv64 の apt アーカイブ鍵のための `debian-ports-archive-keyring` をインストールして、 `debootstrap` で `/tmp/riscv64-chroot` に `chroot` 環境を作成します。

```
sudo apt-get install debootstrap qemu-user-static binfmt-support debian-ports-archive-keyring
sudo debootstrap --arch=riscv64 --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg --include=debian-ports-archive-keyring unstable /tmp/riscv64-chroot http://deb.debian.org/debian-ports
```

## chroot 環境で事前設定

まず `apt-get update` などをしておきます。

作業場所はシェル変数 `CHROOT` に設定しておいて、この後も使っています。

```
CHROOT=/tmp/riscv64-chroot
sudo chroot "$CHROOT" apt-get update
sudo chroot "$CHROOT" apt-get -y install etckeeper
sudo chroot "$CHROOT" apt-get -y full-upgrade
```

次に Debian Wiki に書いてある他の設定をしていきます。
ネットワーク設定とパスワード設定は後でするので、ここでは設定しません。

```
sudo chroot "$CHROOT" ln -sf /dev/null /etc/systemd/system/serial-getty@hvc0.service
sudo chroot "$CHROOT" apt-get install -y linux-image-riscv64 u-boot-menu
sudo chroot "$CHROOT" apt-get install -y openntpd ntpdate
sudo chroot "$CHROOT" sed -i 's/^DAEMON_OPTS="/DAEMON_OPTS="-s /' /etc/default/openntpd
printf '\nU_BOOT_PARAMETERS="rw noquiet root=/dev/vda1"\nU_BOOT_FDT_DIR="noexist"\n' | sudo chroot "$CHROOT" tee -a /etc/default/u-boot
sudo chroot "$CHROOT" u-boot-update
```

## ネットワーク設定

最終的には `cloud-init` を使うことにしたのですが、ここでは使わない方法も説明しておきます。

`/etc/network/interfaces` を直接書き換えるのはいろいろ面倒なので、 `/etc/network/interfaces.d/` 以下にファイルを作成しました。
ホスト名を `/etc/hosts` に設定しておかないと `sudo` が使えないなどの問題がおきるので、 `/etc/hostname` の設定と `/etc/hosts` への追加もしました。

```
printf 'auto lo\niface lo inet loopback\n' | sudo chroot "$CHROOT" tee /etc/network/interfaces.d/lo
printf 'auto eth0\niface eth0 inet dhcp\n' | sudo chroot "$CHROOT" tee /etc/network/interfaces.d/eth0
echo "debian-riscv64" | sudo chroot "$CHROOT" tee /etc/hostname
echo "10.0.2.15 debian-riscv64" | sudo chroot "$CHROOT" tee -a /etc/hosts
```

## ユーザー設定

こちらも `cloud-init` を使わないときの方法を書いておきます。

gid や uid を固定したかったので、 `groupadd` と `useradd` で個別に追加しました。
`useradd` の `-p` には `/etc/shadow` に入る内容をそのまま書く必要があるので、別途用意した環境で `passwd` で設定してからコピーしてきました。

`sudo` の設定も追加しています。

```
NEW_USER_ID=10001
NEW_USER_NAME=user1
#NEW_USER_PASSWORD=password
NEW_USER_CRYPTED_PASSWORD='$6$1d21kyR8pE4lrlbk$tYozc917kbLYZGfKvEvRGboHLXEtIN8DXayM144IRtqIO.3n1cicKATF1i/0YqBuHEIcSUEq9B/szH08rD0ZJ1'
sudo chroot "$CHROOT" groupadd -g "$NEW_USER_ID" "$NEW_USER_NAME"
sudo chroot "$CHROOT" useradd -d "/home/$NEW_USER_NAME" -m -g "$NEW_USER_NAME" -u "$NEW_USER_ID" -p "$NEW_USER_CRYPTED_PASSWORD" -s /bin/bash "$NEW_USER_NAME"
sudo chroot "$CHROOT" apt-get install -y sudo
echo "$NEW_USER_NAME ALL=(ALL) NOPASSWD:ALL" | sudo chroot "$CHROOT" tee "/etc/sudoers.d/$NEW_USER_NAME"
```

`chpasswd` を `echo "$NEW_USER_NAME:$NEW_USER_PASSWORD" | sudo chroot "$CHROOT" chpasswd` のように使う方法も試したのですが、以下の pam のエラーになって使えませんでした。

```
chpasswd: (user user1) pam_chauthtok() failed, error:
Authentication token manipulation error
```

## cloud-init

さきほど書いたように、最終的には `cloud-init` を入れて、ネットワーク設定やユーザー設定はそちらに任せることにしました。
`openssh-server` の設定もしてくれるのですが、一緒にインストールしておかないと、 `PasswordAuthentication yes` だけの `/etc/ssh/sshd_config` が作成されてしまって、後から `openssh-server` を入れても普通の動きにならないので、同時にインストールしています。

```
sudo chroot "$CHROOT" apt-get -y install cloud-init openssh-server
```

## ディスクイメージ作成前の最後の処理

`cloud-init` の `locale:` で自動で有効にしてくれないようなので、事前に有効にしておいたり、 `apt-get clean` をしたり、事前にディスクイメージファイルのサイズを減らせる処理があればしておきます。

```
sudo chroot "$CHROOT" sed -i -e 's/^# \(ja_JP\.UTF-8\)/\1/' /etc/locale.gen
sudo chroot "$CHROOT" etckeeper commit "Enable ja_JP.UTF-8"
sudo chroot "$CHROOT" etckeeper vcs gc
sudo chroot "$CHROOT" apt-get clean
```

## ディスクイメージファイル作成

Debian Wiki に書いてあるように `libguestfs-tools` に入っている `virt-make-fs` でディスクイメージファイルを作成して、 `qemu-system-riscv64` の実行ユーザーで読み書きできるようにします。
依存で入るパッケージが多いので、作成したディスクイメージを別の最低限のパッケージだけ入れた実行用の環境に持っていって動かしても良いでしょう。

`virt-make-fs` は何も表示が変わらないまま、何分か時間がかかるので、ゆっくり待ちます。

```
sudo apt-get install -y libguestfs-tools
sudo virt-make-fs --partition=gpt --type=ext4 --size=10G "$CHROOT"/ "$HOME/riscv64/rootfs.img"
sudo chown "$USER" "$HOME/riscv64/rootfs.img"
```

## 実行

実行環境に必要な `opensbi` と `u-boot-qemu` の他に、 `cloud-init` の [NoCloud データソース](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html)用の iso9660 イメージを作成するための `genisoimage` を入れています。

```
sudo apt-get install -y opensbi u-boot-qemu
sudo apt-get install -y genisoimage
```

以下の内容の `run-riscv64.sh` を作成して、 `$HOME/riscv64/user-data` も用意して `qemu-system-riscv64` を起動します。

`cloud-init` を使わないのなら、 `meta-data` の作成と `genisoimage` の実行と `-drive file=seed.iso,if=virtio` は不要です。

```
#!/bin/bash
set -eux -o pipefail
cd "$HOME/riscv64"
local_hostname=debian-riscv64
cat >meta-data <<EOF
instance-id: iid-local01
local-hostname: ${local_hostname}
EOF
genisoimage -output seed.iso -volid cidata -joliet -rock meta-data user-data
exec qemu-system-riscv64 -nographic -machine virt -m 1.9G \
 -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
 -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
 -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-device,rng=rng0 \
 -append "console=ttyS0 rw root=/dev/vda1" \
 -device virtio-blk-device,drive=hd0 -drive file=rootfs.img,format=raw,id=hd0 \
 -drive file=seed.iso,if=virtio \
 -device virtio-net-device,netdev=usernet -netdev user,id=usernet,hostfwd=tcp::22222-:22 \
 -smp cpus=4,sockets=1,cores=4,threads=1 \
 -virtfs local,path=$HOME/share,mount_tag=hostshare,security_model=mapped-xattr \
 -name ${local_hostname}
```

## 共有ディレクトリ設定

ホストとゲストでファイルのやりとりがしやすくなるかと思って、 `$HOME/share` を共有ディレクトリに設定しています。

ゲスト側から一般ユーザーでもファイルを作成しやすくするために、ホスト側ではパーミッションを `/tmp` と同じ `1777` にしています。

qemu のオプションの `-virtfs local,path=$HOME/share,mount_tag=hostshare,security_model=mapped-xattr` で共有しています。
`mount_tag` に指定した文字列がゲストでマウントするときの `/dev/vda1` などの代わりに指定する部分になります。
`security_model` は <https://wiki.qemu.org/Documentation/9psetup> に「Recommended option is "mapped-xattr".」と書いてあったので、 `mapped-xattr` にしています。

ゲストで `sudo mkdir -p /mnt/hostshare; sudo mount -t 9p hostshare /mnt/hostshare` のようにマウントできます。
`-o trans=virtio` などの `-o` のオプションはつけなくても大丈夫でした。

後述の `user-data` で `/etc/fstab` に以下のように設定されます。
`comment=cloudconfig` は `cloud-init` で設定された印のようなので、手動で追加する場合は不要です。

```
hostshare	/mnt/hostshare	9p	defaults,nofail,_netdev,comment=cloudconfig	0	2
```

単純に `defaults` だけだとマウントしようとするのが早すぎて、2回目以降の起動時に以下のようにエラーになるので、 `_netdev` を流用して遅延させています。
もっと良い指定があるのかもしれませんが、あまり重要なところではないので妥協しています。

```
[   10.346933] FS-Cache: Loaded
[   10.369875] 9pnet: Installing 9P2000 support
[   10.389904] 9p: Installing v9fs 9p2000 file system support
[   10.391969] FS-Cache: Netfs '9p' registered for caching
[FAILED] Failed to mount /mnt/hostshare.
See 'systemctl status mnt-hostshare.mount' for details.
```

## cloud-init 用 user-data

`cloud-init` 用に以下のような内容の `$HOME/riscv64/user-data` を作成しています。

`ssh_pwauth: true` で ssh でのパスワード認証を許可しています。

`chpasswd:` で `cloud-init` が Debian の場合にデフォルトで作成してくれる `debian` というユーザーのパスワードを `debian` にしています。
デフォルトユーザーの `debian` はパスワードなしで `sudo` が使えるようにする設定もされています。
`root` ユーザーでもログインできるようにしておくなら、 `- root:debian` を有効にします。

`manage_etc_hosts: true` で `/etc/hosts` の更新をして、 `sudo` の問題などがおきないようにしています。

`locale:` は `/etc/locale.gen` の設定変更はしてくれないようなので、あらかじめ `sudo chroot "$CHROOT" sed -i -e 's/^# \(ja_JP\.UTF-8\)/\1/' /etc/locale.gen` で有効にしています。

`qemu-guest-agent` も入れた方が良いかと思って `packages:` でのインストールを試してみたのですが、 RISC-V には対応していなかったのでコメントアウトしています。

`mounts:` と `runcmd:` で `hostshare` の `fstab` への追加と初回のマウントをしています。

さらに `runcmd:` で `cloud-init` での変更の `etckeeper` への反映もしています。

```
#cloud-config

ssh_pwauth: true
chpasswd:
  list:
  #- root:debian
  - debian:debian
  expire: false

manage_etc_hosts: true

timezone: Asia/Tokyo
locale: ja_JP.UTF-8
package_upgrade: true
#packages:
#- qemu-guest-agent

mounts:
- [ 'hostshare', '/mnt/hostshare', '9p', 'defaults,nofail,_netdev', '0', '2' ]

runcmd:
- [ mkdir, '-p', /mnt/hostshare ]
- [ mount, '-a' ]
- [ 'etckeeper', 'commit', 'cloud-init' ]
```

## 接続

起動して `cloud-init` での設定が終わるまで、しばらく待つと、 `ssh -p 22222 debian@localhost` で接続できるようになります。
`ssh-copy-id -p 22222 debian@localhost` で ssh 鍵をコピーしておくと認証が省略できて楽になります。

`~/.ssh/config` に以下のような設定をしておくとイメージを作りなおしたときにホスト鍵の削除が不要になったり、 `ssh riscv64` で入れたりします。

```
NoHostAuthenticationForLocalhost yes

Host riscv64
Hostname localhost
Port 22222
User debian
```

## poweroff

M1 Mac 上で lima で aarch64 の Ubuntu 21.10 で試しているのですが、なぜか `poweroff` をしても以下の行までで `qemu-system-riscv64` が終了せずに止まってしまうので、 `C-a x` で終了しています。
別途用意した amd64 の Ubuntu 20.04 の環境だとちゃんと終了したので、環境の問題のような気がします。

```
[  169.345939] systemd-shutdown[1]: Powering off.
[  169.348326] reboot: Power down
```

## create-riscv64.sh

今までの手順をまとめたものを `create-riscv64.sh` としてまとめて、それを使っています。

ホスト側の `/tmp/riscv64-chroot` を作業場所として使って、ホスト側に必要なパッケージをインストールして、最終的に `~/riscv64` にディスクイメージファイルなどを作成して、起動スクリプト `~/bin/run-riscv64.sh` と共有用ディレクトリ `~/share` も作成します。

```bash
#!/bin/bash
set -eux -o pipefail
export DEBIAN_FRONTEND=noninteractive

DIR="$(dirname "$0")"
CHROOT=/tmp/riscv64-chroot
FS_SIZE=10G

cd "$HOME"

[ -f "$HOME/riscv64/rootfs.img" ] && exit 0

mkdir -p "$HOME/bin"
mkdir -p "$HOME/riscv64"
install -m 1777 -d "$HOME/share"

sudo apt-get install -y qemu-system-misc qemu-user-static binfmt-support

sudo apt-get install -y debootstrap qemu-user-static binfmt-support debian-ports-archive-keyring
sudo debootstrap --arch=riscv64 --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg --include=debian-ports-archive-keyring unstable "$CHROOT" http://deb.debian.org/debian-ports
sudo chroot "$CHROOT" apt-get update
sudo chroot "$CHROOT" apt-get -y install etckeeper
sudo chroot "$CHROOT" apt-get -y full-upgrade

# Disable the getty on hvc0 as hvc0 and ttyS0 share the same console device in qemu.
sudo chroot "$CHROOT" ln -sf /dev/null /etc/systemd/system/serial-getty@hvc0.service
sudo chroot "$CHROOT" apt-get install -y linux-image-riscv64 u-boot-menu
sudo chroot "$CHROOT" apt-get install -y openntpd ntpdate
sudo chroot "$CHROOT" sed -i 's/^DAEMON_OPTS="/DAEMON_OPTS="-s /' /etc/default/openntpd
printf '\nU_BOOT_PARAMETERS="rw noquiet root=/dev/vda1"\nU_BOOT_FDT_DIR="noexist"\n' | sudo chroot "$CHROOT" tee -a /etc/default/u-boot
sudo chroot "$CHROOT" u-boot-update

sudo chroot "$CHROOT" apt-get -y install cloud-init openssh-server
sudo chroot "$CHROOT" sed -i -e 's/^# \(ja_JP\.UTF-8\)/\1/' /etc/locale.gen
sudo chroot "$CHROOT" etckeeper commit "Enable ja_JP.UTF-8"
sudo chroot "$CHROOT" etckeeper vcs gc
sudo chroot "$CHROOT" apt-get clean

sudo apt-get install -y libguestfs-tools
time sudo virt-make-fs --partition=gpt --type=ext4 --size="$FS_SIZE" "$CHROOT"/ "$HOME/riscv64/rootfs.img"
sudo chown "$USER" "$HOME/riscv64/rootfs.img"

sudo apt-get install -y opensbi u-boot-qemu
sudo apt-get install -y genisoimage
cat >"$HOME/bin/run-riscv64.sh" <<'RUN'
#!/bin/bash
set -eux -o pipefail
cd "$HOME/riscv64"
local_hostname=debian-riscv64
cat >meta-data <<EOF
instance-id: iid-local01
local-hostname: ${local_hostname}
EOF
genisoimage -output seed.iso -volid cidata -joliet -rock meta-data user-data
exec qemu-system-riscv64 -nographic -machine virt -m 1.9G \
 -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
 -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
 -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-device,rng=rng0 \
 -append "console=ttyS0 rw root=/dev/vda1" \
 -device virtio-blk-device,drive=hd0 -drive file=rootfs.img,format=raw,id=hd0 \
 -drive file=seed.iso,if=virtio \
 -device virtio-net-device,netdev=usernet -netdev user,id=usernet,hostfwd=tcp::22222-:22 \
 -smp cpus=4,sockets=1,cores=4,threads=1 \
 -virtfs local,path=$HOME/share,mount_tag=hostshare,security_model=mapped-xattr \
 -name ${local_hostname}
RUN
chmod +x "$HOME/bin/run-riscv64.sh"

cd "$HOME/riscv64"
cat >user-data <<EOF
#cloud-config

ssh_pwauth: true
chpasswd:
  list:
  #- root:debian
  - debian:debian
  expire: false

manage_etc_hosts: true

timezone: Asia/Tokyo
locale: ja_JP.UTF-8
package_upgrade: true
#packages:
#- qemu-guest-agent

mounts:
- [ 'hostshare', '/mnt/hostshare', '9p', 'defaults,nofail,_netdev', '0', '2' ]

runcmd:
- [ mkdir, '-p', /mnt/hostshare ]
- [ mount, '-a' ]
- [ 'etckeeper', 'commit', 'cloud-init' ]
EOF
```

## 困っていること

なぜか `gcc` で普通に実行ファイルを作成しただけで、警告が出るので困っています。

```console
debian@debian-riscv64:~$ echo 'int main(){return 0;}' | gcc -xc -
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crti.o: mis-matched ISA version 2.0 for 'i' extension, the output version is 2.1
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crti.o: mis-matched ISA version 2.0 for 'a' extension, the output version is 2.1
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crti.o: mis-matched ISA version 2.0 for 'f' extension, the output version is 2.2
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crti.o: mis-matched ISA version 2.0 for 'd' extension, the output version is 2.2
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtbeginS.o: mis-matched ISA version 2.0 for 'i' extension, the output version is 2.1
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtbeginS.o: mis-matched ISA version 2.0 for 'a' extension, the output version is 2.1
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtbeginS.o: mis-matched ISA version 2.0 for 'f' extension, the output version is 2.2
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtbeginS.o: mis-matched ISA version 2.0 for 'd' extension, the output version is 2.2
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtendS.o: mis-matched ISA version 2.0 for 'i' extension, the output version is 2.1
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtendS.o: mis-matched ISA version 2.0 for 'a' extension, the output version is 2.1
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtendS.o: mis-matched ISA version 2.0 for 'f' extension, the output version is 2.2
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtendS.o: mis-matched ISA version 2.0 for 'd' extension, the output version is 2.2
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtn.o: mis-matched ISA version 2.0 for 'i' extension, the output version is 2.1
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtn.o: mis-matched ISA version 2.0 for 'a' extension, the output version is 2.1
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtn.o: mis-matched ISA version 2.0 for 'f' extension, the output version is 2.2
/usr/bin/ld: warning: /usr/lib/gcc/riscv64-linux-gnu/11/crtn.o: mis-matched ISA version 2.0 for 'd' extension, the output version is 2.2
debian@debian-riscv64:~$
```

## まとめ

以前に試したときは試行錯誤を繰り返して qemu 環境が出来て、再現性のある作成スクリプトにできなかったのですが、今は Debian Wiki の内容をまとめなおすだけで作成できて簡単になっていました。
なぜ `openntpd` を入れるのかと思ったら `systemd-timesyncd` がないなど、意外な違いもありますが、だいたい問題なく試せそうです。

独自に追加した手順として `etckeeper` の追加や `cloud-init` の利用も入れています。
`etckeeper` は趣味で入れているだけなので、細かいことはいいとして、 `cloud-init` は名前の通りクラウド環境での初期設定によく使われていて、 `openssh-server` のホスト鍵の再作成などのディスクイメージの使い回しのときに便利な機能もあるので、他の機能も含めて慣れておくと便利そうです。
