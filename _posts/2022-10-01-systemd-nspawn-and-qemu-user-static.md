---
layout: post
title: "systemd-nspawnとqemu-user-staticで別archのシステムコンテナを使う"
date: 2022-10-01 19:00 +0900
comments: true
category: blog
tags: linux debian ubuntu nspawn machinectl
---
[systemd-nspawnやmachinectlで軽量システムコンテナを使う]({% post_url 2022-09-27-systemd-nspawn %})記事でホスト側と同じ arch のシステムコンテナは使えたので、
今回は `qemu-user-static` で別 arch のシステムコンテナを動かしてみます。

<!--more-->

## 動作確認環境

前回と同じ環境で確認しています。

- Apple M1 Pro の macOS Monterey 12.6
- limactl version 0.12.0
- aarch64 の Debian GNU/Linux 11 (bullseye)
- aarch64 の Ubuntu 22.04.1 LTS (jammy)

## 別 arch の準備

別 arch のバイナリを実行するために `qemu-user-static` を使うので、インストールしておきます。

```console
$ sudo apt install binfmt-support qemu-user-static
```

## s390x

実際の用途としては `amd64` と `arm64` (`aarch64`) が arch として使われることが多いと思いますが、
どちらからも別 arch になる例として、
比較的安定しているように感じた `s390x` を試しました。

```console
$ NAME=s390x-bullseye
$ mmdebstrap --arch=s390x --include=dbus \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   bullseye /tmp/$NAME.tar
$ sudo machinectl import-tar /tmp/$NAME.tar $NAME
$ sudo machinectl start $NAME
```

`ldd` で `s390x` になっているのが確認できます。
カーネルはホスト側のままで、 `uname -m` は `s390x` になっています。

```console
lima-debian-nspawn$ sudo machinectl shell s390x-bullseye
Connected to machine s390x-bullseye. Press ^] three times within 1s to exit session.
root@s390x-bullseye:~# ldd /bin/sh
	libc.so.6 => /lib/s390x-linux-gnu/libc.so.6 (0x0000004001855000)
	/lib/ld64.so.1 (0x0000004000000000)
root@bullseye-s390x:~# uname -a
Linux bullseye-s390x 5.10.0-18-arm64 #1 SMP Debian 5.10.140-1 (2022-09-02) s390x GNU/Linux
```

```console
lima-ubuntu-nspawn$ sudo machinectl shell s390x-bullseye
Connected to machine s390x-bullseye. Press ^] three times within 1s to exit session.
root@s390x-bullseye:~# ldd /bin/sh
	libc.so.6 => /lib/s390x-linux-gnu/libc.so.6 (0x0000004001856000)
	/lib/ld64.so.1 (0x0000004000000000)
root@s390x-bullseye:~# uname -a
Linux s390x-bullseye 5.15.0-47-generic #51-Ubuntu SMP Fri Aug 12 08:18:32 UTC 2022 s390x GNU/Linux
root@s390x-bullseye:~#
```

## mips

ビッグエンディアンの例として `mips` も試しました。
リリースが `buster` までなので、
`buster` を入れています。

なぜか `chfn` でエラーになるので、
`--essential-hook` と `--customize-hook`
を使って対処しています。

```console
$ NAME=mips-buster
$ mmdebstrap --arch=mips --include=dbus \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   --essential-hook='chroot "$1" dpkg-divert --rename /usr/bin/chfn' \
   --essential-hook='printf "#!/bin/bash\n" > "$1/root/chfn.fixup"' \
   --essential-hook='chmod +x "$1/root/chfn.fixup"' \
   --essential-hook='printf "#!/bin/bash\n{ printf \"%%q \" \"\$0\" \"\$@\"; echo; } >> /root/chfn.fixup\n" > "$1/usr/bin/chfn"' \
   --essential-hook='chmod +x "$1/usr/bin/chfn"' \
   --customize-hook='chroot "$1" rm /usr/bin/chfn' \
   --customize-hook='chroot "$1" dpkg-divert --remove --rename /usr/bin/chfn' \
   buster /tmp/$NAME.tar
$ sudo machinectl import-tar /tmp/$NAME.tar $NAME
$ sudo machinectl start $NAME
$ machinectl list
$ sudo machinectl shell mips-buster /root/chfn.fixup
```

`mips` になっていることが確認できます。

```console
$ sudo machinectl shell mips-buster
root@mips-buster:~# ldd /bin/sh
	libc.so.6 => /lib/mips-linux-gnu/libc.so.6 (0x3f636000)
	/lib/ld.so.1 (0x40000000)
root@mips-buster:~# uname -a
Linux mips-buster 5.10.0-18-arm64 #1 SMP Debian 5.10.140-1 (2022-09-02) mips GNU/Linux
```

Ubuntu 22.04 上ではなぜか `Failed to create /var/log/journal: Value too large for defined data type` で起動できませんでした。
(`--output=short-monotonic` は実際の時刻をマスクするためなので深い意味はありません。)

```console
kazu@lima-ubuntu-nspawn:~$ sudo machinectl start $NAME
Job for systemd-nspawn@mips-buster.service failed because the control process exited with error code.
See "systemctl status systemd-nspawn@mips-buster.service" and "journalctl -xeu systemd-nspawn@mips-buster.service" for details.
kazu@lima-ubuntu-nspawn:~$ sudo journalctl -u systemd-nspawn@mips-buster.service --output=short-monotonic
[202198.335176] lima-ubuntu-nspawn systemd[1]: Starting Container mips-buster...
[202198.344133] lima-ubuntu-nspawn systemd-nspawn[33578]: Failed to create /var/log/journal: Value too large for defined data type
[202198.389864] lima-ubuntu-nspawn systemd[1]: systemd-nspawn@mips-buster.service: Main process exited, code=exited, status=1/FAILURE
[202198.389964] lima-ubuntu-nspawn systemd[1]: systemd-nspawn@mips-buster.service: Failed with result 'exit-code'.
[202198.390239] lima-ubuntu-nspawn systemd[1]: Failed to start Container mips-buster.
[202202.560354] lima-ubuntu-nspawn systemd[1]: Starting Container mips-buster...
[202202.568335] lima-ubuntu-nspawn systemd-nspawn[33588]: Failed to create /var/log/journal: Value too large for defined data type
[202202.569273] lima-ubuntu-nspawn systemd[1]: systemd-nspawn@mips-buster.service: Main process exited, code=exited, status=1/FAILURE
[202202.569368] lima-ubuntu-nspawn systemd[1]: systemd-nspawn@mips-buster.service: Failed with result 'exit-code'.
[202202.569787] lima-ubuntu-nspawn systemd[1]: Failed to start Container mips-buster.
```

### 無視される apt-line 対応

`apt-get update` で以下のようにメッセージがでるので、
`/etc/apt/sources.list` の `security.debian.org` の行はコメントアウトするか、
削除すると良さそうです。
`/tmp/$NAME.tar` の後ろに `MIRROR` として `http://deb.debian.org/debian` を指定すると
`deb http://deb.debian.org/debian buster-updates main`
の行も消えてしまうようでした。

```console
root@mips-buster:~# cat /etc/apt/sources.list
deb http://deb.debian.org/debian buster main
deb http://deb.debian.org/debian buster-updates main
deb http://security.debian.org/debian-security buster/updates main
root@mips-buster:~# apt-get update
Hit:1 http://security.debian.org/debian-security buster/updates InRelease
Hit:2 http://deb.debian.org/debian buster InRelease
Hit:3 http://deb.debian.org/debian buster-updates InRelease
Reading package lists... Done
N: Skipping acquire of configured file 'main/binary-mips/Packages' as repository 'http://security.debian.org/debian-security buster/updates InRelease' doesn't support architecture 'mips'
```

## powerpc, ppc64

ビッグエンディアンの例として `powerpc` も試しました。

`debian-ports` からのインストールなので、 `debian-ports-archive-keyring` が必要です。
Ubuntu 22.04 ではさらに `--keyring=/usr/share/keyrings` も必要でした。
Debian では省略できますが、以下のコマンド例には入れています。

後述の問題があって、
`--variant` を変えているので、
起動して `apt` を普通に使うのに必要な最低限のパッケージを `--include` で追加しています。

この環境では、
`systemd-sysv` が入っていなくて、
`poweroff` などが使えないので、
`systemctl poweroff` で停止する必要がありました。

```console
$ sudo apt install debian-ports-archive-keyring
$ NAME=powerpc-sid
$ mmdebstrap --arch=powerpc --include=debian-ports-archive-keyring \
   --keyring=/usr/share/keyrings \
   --include=dbus \
   --variant=minbase --include=systemd,ifupdown,isc-dhcp-client,whiptail \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   sid /tmp/$NAME.tar http://deb.debian.org/debian-ports
$ sudo machinectl import-tar /tmp/$NAME.tar $NAME
$ sudo machinectl start $NAME
```

apt-line は `MIRROR` に指定したものだけになっていて、
`uname -m` が `ppc` になっていることが確認できます。

```console
root@powerpc-sid:~# cat /etc/apt/sources.list
deb http://deb.debian.org/debian-ports sid main
root@powerpc-sid:~# ldd /bin/sh
	libc.so.6 => /lib/powerpc-linux-gnu/libc.so.6 (0x3f5b0000)
	/lib/ld.so.1 (0x40000000)
root@powerpc-sid:~# uname -a
Linux powerpc-sid 5.10.0-18-arm64 #1 SMP Debian 5.10.140-1 (2022-09-02) ppc GNU/Linux
root@powerpc-sid:~# poweroff
bash: poweroff: command not found
root@powerpc-sid:~# systemctl poweroff
```

なぜか [Debian -- Ports](https://www.debian.org/ports/index.en.html) には書いていないのですが、
`ppc64` も試しました。

```console
$ sudo apt install debian-ports-archive-keyring
$ NAME=ppc64-sid
$ mmdebstrap --arch=ppc64 --include=debian-ports-archive-keyring \
   --keyring=/usr/share/keyrings \
   --include=dbus \
   --variant=minbase --include=systemd,ifupdown,isc-dhcp-client,whiptail \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   sid /tmp/$NAME.tar http://deb.debian.org/debian-ports
$ sudo machinectl import-tar /tmp/$NAME.tar $NAME
$ sudo machinectl start $NAME
```

apt-line は `MIRROR` に指定したものだけになっていて、
`uname -m` が `ppc64` になっていることが確認できます。

```console
root@ppc64-sid:~# cat /etc/apt/sources.list
deb http://deb.debian.org/debian-ports sid main
root@ppc64-sid:~# ldd /bin/sh
	libc.so.6 => /lib/powerpc64-linux-gnu/libc.so.6 (0x00000040018c0000)
	/lib64/ld64.so.1 (0x0000004000000000)
root@ppc64-sid:~# uname -a
Linux ppc64-sid 5.10.0-18-arm64 #1 SMP Debian 5.10.140-1 (2022-09-02) ppc64 GNU/Linux
```

## riscv64

`debian-ports` の中で今後一番正式リリースされる可能性が高そうだと思っている `riscv64` も試してみました。

```console
$ sudo apt install debian-ports-archive-keyring
$ NAME=riscv64-sid
$ mmdebstrap --arch=riscv64 --include=debian-ports-archive-keyring \
   --keyring=/usr/share/keyrings \
   --include=dbus \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   sid /tmp/$NAME.tar http://deb.debian.org/debian-ports
$ sudo machinectl import-tar /tmp/$NAME.tar $NAME
$ sudo machinectl start $NAME
```

`riscv64` になっていることが確認できます。

```console
root@riscv64-sid:~# cat /etc/apt/sources.list
deb http://deb.debian.org/debian-ports sid main
root@riscv64-sid:~# ldd /bin/sh
	libc.so.6 => /lib/riscv64-linux-gnu/libc.so.6 (0x0000004001840000)
	/lib/ld-linux-riscv64-lp64d.so.1 (0x0000004000000000)
root@riscv64-sid:~# uname -a
Linux riscv64-sid 5.10.0-18-arm64 #1 SMP Debian 5.10.140-1 (2022-09-02) riscv64 GNU/Linux
```

## 失敗例

### mmdebstrap ができない

`binfmt-support`と`qemu-user-static`パッケージのインストールが必要です。

```console
$ mmdebstrap --arch=s390x --include=dbus \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   bullseye /tmp/$NAME.tar
I: automatically chosen mode: unshare
W: binfmt_misc not found in /proc/filesystems -- is the module loaded?
W: binfmt_misc not found in /proc/mounts -- not mounted?
sh: 1: /usr/sbin/update-binfmts: not found
W: cannot find /usr/sbin/update-binfmts
E: s390x can neither be executed natively nor via qemu user emulation with binfmt_misc
```

### mmdebstrap で apt-get update didn't download anything


`ppc64` などの arch は `deb.debian.org/debian` からではなく `deb.debian.org/debian-ports` からダウンロードする必要があるので、
`TARGET` の後ろに `MIRROR` を指定する必要があります。

```console
$ mmdebstrap --arch=ppc64 --include=dbus \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   sid /tmp/$NAME.tar
I: automatically chosen mode: unshare
I: ppc64 cannot be executed, falling back to qemu-user
I: automatically chosen format: tar
I: using /tmp/mmdebstrap.LqsTD__QM4 as tempdir
I: running apt-get update...
done
Package files:
 100 /tmp/mmdebstrap.LqsTD__QM4/var/lib/dpkg/status
     release a=now
Pinned packages:
E: apt-get update didn't download anything
W: listening on child socket failed: Can't locate Dpkg/Vendor/Debian.pm in @INC (you may need to install the Dpkg::Vendor::Debian module) (@INC contains: /etc/perl /usr/local/lib/aarch64-linux-gnu/perl/5.32.1 /usr/local/share/perl/5.32.1 /usr/lib/aarch64-linux-gnu/perl5/5.32 /usr/share/perl5 /usr/lib/aarch64-linux-gnu/perl-base /usr/lib/aarch64-linux-gnu/perl/5.32 /usr/share/perl/5.32 /usr/local/lib/site_perl) at /usr/bin/mmdebstrap line 3908.

I: removing tempdir /tmp/mmdebstrap.LqsTD__QM4...
```

### mmdebstrap で GPG error になる

`debian-ports` を使う場合は `debian-ports-archive-keyring` をインストールしておく必要があります。
`--keyring` オプションは指定しなくても自動で使ってくれますが、
`--include=debian-ports-archive-keyring` で
`chroot` の中でもインストールしておく必要があります。

```console
$ mmdebstrap --arch=ppc64 --include=dbus \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   sid /tmp/$NAME.tar http://deb.debian.org/debian-ports
I: automatically chosen mode: unshare
I: ppc64 cannot be executed, falling back to qemu-user
I: automatically chosen format: tar
I: using /tmp/mmdebstrap.XApkViHjnR as tempdir
I: running apt-get update...
done
Get:1 http://deb.debian.org/debian-ports sid InRelease [69.6 kB]
Err:1 http://deb.debian.org/debian-ports sid InRelease
  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY E852514F5DF312F6
Reading package lists...
W: GPG error: http://deb.debian.org/debian-ports sid InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY E852514F5DF312F6
E: The repository 'http://deb.debian.org/debian-ports sid InRelease' is not signed.
E: apt-get update -oAPT::Status-Fd=<$fd> -oDpkg::Use-Pty=false failed
W: listening on child socket failed: Can't locate Dpkg/Vendor/Debian.pm in @INC (you may need to install the Dpkg::Vendor::Debian module) (@INC contains: /etc/perl /usr/local/lib/aarch64-linux-gnu/perl/5.32.1 /usr/local/share/perl/5.32.1 /usr/lib/aarch64-linux-gnu/perl5/5.32 /usr/share/perl5 /usr/lib/aarch64-linux-gnu/perl-base /usr/lib/aarch64-linux-gnu/perl/5.32 /usr/share/perl/5.32 /usr/local/lib/site_perl) at /usr/bin/mmdebstrap line 3908.

I: removing tempdir /tmp/mmdebstrap.XApkViHjnR...
```

Ubuntu 22.04 ではさらに `--keyring=/usr/share/keyrings` も必要でした。

```console
lima-ubuntu-nspawn$ mmdebstrap --arch=ppc64 --include=debian-ports-archive-keyring \
   --include=dbus \
   --variant=minbase --include=systemd,ifupdown,isc-dhcp-client,whiptail \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   sid /tmp/$NAME.tar http://deb.debian.org/debian-ports
I: automatically chosen mode: unshare
I: ppc64 cannot be executed, falling back to qemu-user
I: automatically chosen format: tar
I: using /tmp/mmdebstrap.iPfKWFBxAO as tempdir
dpkg: warning: failed to open configuration file '/home/kazu.linux/.dpkg.cfg' for reading: Permission denied
I: running apt-get update...
done
Get:1 http://deb.debian.org/debian-ports sid InRelease [69.6 kB]
Err:1 http://deb.debian.org/debian-ports sid InRelease
  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY E852514F5DF312F6
Reading package lists...
W: GPG error: http://deb.debian.org/debian-ports sid InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY E852514F5DF312F6
E: The repository 'http://deb.debian.org/debian-ports sid InRelease' is not signed.
E: apt-get update --error-on=any -oAPT::Status-Fd=<$fd> -oDpkg::Use-Pty=false failed
W: listening on child socket failed:
I: removing tempdir /tmp/mmdebstrap.iPfKWFBxAO...
E: mmdebstrap failed to run
lima-ubuntu-nspawn$ mmdebstrap --arch=ppc64 --include=debian-ports-archive-keyring \
   --keyring=/usr/share/keyrings \
   --include=dbus \
   --variant=minbase --include=systemd,ifupdown,isc-dhcp-client,whiptail \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   sid /tmp/$NAME.tar http://deb.debian.org/debian-ports
```

### powerpc-utils のインストールで失敗する

[#927255 - powerpc-utils is uninstallable - Debian Bug report logs](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=927255)
で報告されているように、
`powerpc` や `ppc64` では、
もう存在しない `pmac-utils` パッケージに依存している `powerpc-utils` が `Priority: important` になっているため、
`powerpc-ibm-utils` と `powerpc-utils` を除外したいのですが、
`mmdebstrap` は `debootstrap` の `--exclude` に相当するオプションがないので、
`Priority: important` を含まない variants に変更するなどの回避策をとる必要があります。

上の `ppc64` の例では `--variant=minbase` にして、
`Priority: important` のパッケージのうち、
システムコンテナとして起動するために `systemd` を、
`/etc/network/interfaces.d/` のために `ifupdown` を、
`debconf: unable to initialize frontend: Dialog` にならないようにするために `whiptail` を追加しています。

```console
$ mmdebstrap --arch=ppc64 --include=debian-ports-archive-keyring \
   --include=dbus \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   sid /tmp/$NAME.tar http://deb.debian.org/debian-ports
I: automatically chosen mode: unshare
I: ppc64 cannot be executed, falling back to qemu-user
I: automatically chosen format: tar
I: using /tmp/mmdebstrap.xFIaGsC7Uf as tempdir
I: running apt-get update...
done
I: downloading packages with apt...
done
I: extracting archives...
done
I: installing essential packages...
done
I: downloading apt...
done
I: installing apt...
done
I: installing remaining packages inside the chroot...
done
Reading package lists...
Building dependency tree...
gpgv is already the newest version (2.2.39-1).
passwd is already the newest version (1:4.11.1+dfsg1-2).
debian-archive-keyring is already the newest version (2021.1.1).
libpam-runtime is already the newest version (1.5.2-2).
apt is already the newest version (2.5.3).
libpam-modules-bin is already the newest version (1.5.2-2).
adduser is already the newest version (3.129).
libpam-modules is already the newest version (1.5.2-2).
mawk is already the newest version (1.3.4.20200120-3.1).
debconf is already the newest version (1.5.79).
Some packages could not be installed. This may mean that you have
requested an impossible situation or if you are using the unstable
distribution that some required packages have not yet been created
or been moved out of Incoming.
The following information may help to resolve the situation:

The following packages have unmet dependencies:
 powerpc-utils : Depends: pmac-utils but it is not installable
E: Unable to correct problems, you have held broken packages.
E: run_chroot failed: E: env --unset=APT_CONFIG --unset=TMPDIR /usr/sbin/chroot /tmp/mmdebstrap.xFIaGsC7Uf apt-get --yes install -oAPT::Status-Fd=<$fd> -oDpkg::Use-Pty=false tasksel-data cpio gpgv debian-ports-archive-keyring passwd debian-archive-keyring mount systemd-sysv cron-daemon-common logrotate udev debconf-i18n libpam-runtime fdisk apt vim-tiny libpam-modules-bin powerpc-ibm-utils systemd isc-dhcp-client powerpc-utils init e2fsprogs whiptail procps tzdata nano kmod nftables sensible-utils isc-dhcp-common iputils-ping vim-common netbase adduser less readline-common apt-utils dbus ifupdown libpam-modules iproute2 mawk debconf cron failed
W: listening on child socket failed: Can't locate Dpkg/Vendor/Debian.pm in @INC (you may need to install the Dpkg::Vendor::Debian module) (@INC contains: /etc/perl /usr/local/lib/aarch64-linux-gnu/perl/5.32.1 /usr/local/share/perl/5.32.1 /usr/lib/aarch64-linux-gnu/perl5/5.32 /usr/share/perl5 /usr/lib/aarch64-linux-gnu/perl-base /usr/lib/aarch64-linux-gnu/perl/5.32 /usr/share/perl/5.32 /usr/local/lib/site_perl) at /usr/bin/mmdebstrap line 3908.

I: removing tempdir /tmp/mmdebstrap.xFIaGsC7Uf...
```

### systemd-networkd が使えない

上の例では `ifupdown` で `host0` を設定するようにしていますが、
ホストと同 arch のときと同じように `systemd-networkd` を使おうとすると、
ホストとは別 arch だと以下のように `systemd-networkd` が `Could not create manager: Protocol not supported` で失敗してしまいます。

実行例の `-o short-monotonic` は実際の実行時刻をマスクしやすくするためにつけただけで、深い意味はありません。

```console
$ NAME=s390x-bullseye
$ mmdebstrap --arch=s390x --include=dbus \
   --customize-hook='chroot "$1" mv /etc/network/interfaces /etc/network/interfaces.save' \
   --customize-hook='chroot "$1" systemctl enable systemd-networkd systemd-resolved' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   bullseye /tmp/$NAME.tar
$ sudo machinectl import-tar /tmp/$NAME.tar $NAME
$ sudo machinectl start $NAME
$ sudo machinectl list
MACHINE        CLASS     SERVICE        OS     VERSION ADDRESSES
s390x-bullseye container systemd-nspawn debian 11      -

1 machines listed.
$ sudo journalctl -M $NAME -u systemd-networkd.service -o short-monotonic
-- Journal begins at Tue 2022-09-27 XX:09:10 JST, ends at Tue 2022-09-27 XX:17:01 JST. --
[ 2335.053341] s390x-bullseye systemd[1]: Starting Network Service...
[ 2335.133464] s390x-bullseye systemd-networkd[70]: Could not create manager: Protocol not supported
[ 2335.136634] s390x-bullseye systemd[1]: systemd-networkd.service: Main process exited, code=exited, status=1/FAILURE
[ 2335.137476] s390x-bullseye systemd[1]: systemd-networkd.service: Failed with result 'exit-code'.
[ 2335.137992] s390x-bullseye systemd[1]: Failed to start Network Service.
[ 2335.140647] s390x-bullseye systemd[1]: systemd-networkd.service: Scheduled restart job, restart counter is at 1.
[ 2335.140864] s390x-bullseye systemd[1]: Stopped Network Service.
[ 2335.142294] s390x-bullseye systemd[1]: Starting Network Service...
[ 2335.229011] s390x-bullseye systemd-networkd[93]: Could not create manager: Protocol not supported
[ 2335.244603] s390x-bullseye systemd[1]: systemd-networkd.service: Main process exited, code=exited, status=1/FAILURE
[ 2335.247153] s390x-bullseye systemd[1]: systemd-networkd.service: Failed with result 'exit-code'.
[ 2335.247369] s390x-bullseye systemd[1]: Failed to start Network Service.
[ 2335.247514] s390x-bullseye systemd[1]: systemd-networkd.service: Scheduled restart job, restart counter is at 2.
[ 2335.247650] s390x-bullseye systemd[1]: Stopped Network Service.
[ 2335.247886] s390x-bullseye systemd[1]: Starting Network Service...
[ 2335.332987] s390x-bullseye systemd-networkd[125]: Could not create manager: Protocol not supported
[ 2335.335588] s390x-bullseye systemd[1]: systemd-networkd.service: Main process exited, code=exited, status=1/FAILURE
[ 2335.335785] s390x-bullseye systemd[1]: systemd-networkd.service: Failed with result 'exit-code'.
[ 2335.336235] s390x-bullseye systemd[1]: Failed to start Network Service.
[ 2335.338367] s390x-bullseye systemd[1]: systemd-networkd.service: Scheduled restart job, restart counter is at 3.
[ 2335.339103] s390x-bullseye systemd[1]: Stopped Network Service.
[ 2335.340901] s390x-bullseye systemd[1]: Starting Network Service...
[ 2335.410493] s390x-bullseye systemd-networkd[132]: Could not create manager: Protocol not supported
[ 2335.413018] s390x-bullseye systemd[1]: systemd-networkd.service: Main process exited, code=exited, status=1/FAILURE
[ 2335.413209] s390x-bullseye systemd[1]: systemd-networkd.service: Failed with result 'exit-code'.
[ 2335.413542] s390x-bullseye systemd[1]: Failed to start Network Service.
[ 2335.415322] s390x-bullseye systemd[1]: systemd-networkd.service: Scheduled restart job, restart counter is at 4.
[ 2335.416169] s390x-bullseye systemd[1]: Stopped Network Service.
[ 2335.417684] s390x-bullseye systemd[1]: Starting Network Service...
[ 2335.487867] s390x-bullseye systemd-networkd[135]: Could not create manager: Protocol not supported
[ 2335.490660] s390x-bullseye systemd[1]: systemd-networkd.service: Main process exited, code=exited, status=1/FAILURE
[ 2335.490851] s390x-bullseye systemd[1]: systemd-networkd.service: Failed with result 'exit-code'.
[ 2335.491219] s390x-bullseye systemd[1]: Failed to start Network Service.
[ 2335.493203] s390x-bullseye systemd[1]: systemd-networkd.service: Scheduled restart job, restart counter is at 5.
[ 2335.493892] s390x-bullseye systemd[1]: Stopped Network Service.
[ 2335.494420] s390x-bullseye systemd[1]: systemd-networkd.service: Start request repeated too quickly.
[ 2335.494585] s390x-bullseye systemd[1]: systemd-networkd.service: Failed with result 'exit-code'.
[ 2335.495038] s390x-bullseye systemd[1]: Failed to start Network Service.
$ sudo machinectl poweroff $NAME
$ sudo machinectl terminate $NAME
$ machinectl list
MACHINE        CLASS     SERVICE        OS     VERSION ADDRESSES
s390x-bullseye container systemd-nspawn debian 11      -

1 machines listed.
$ sudo systemctl stop systemd-nspawn@s390x-bullseye.service
$ machinectl list
No machines.
$ sudo machinectl remove s390x-bullseye
```

## chfn でエラーになる

`mips` の `buster` 環境を普通に作成しようとすると、以下のように
`chfn: PAM: System error`
になってしまいます。

以前確認した範囲では
`mips64el` の `bullseye`、
`mipsel` の `bullseye`、
`alpha` の `sid`、
`hppa` の `sid`
でも同じでした。

動かすことを優先したため、原因は追求できていませんが、
システムコンテナとして実行してからは問題なく `chfn` が動くので、
何か実行時に必要なデーモンがあるのかもしれません。

```console
$ NAME=mips-buster
$ mmdebstrap --arch=mips --include=dbus \
   --customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   buster /tmp/$NAME.tar
Setting up systemd (241-7~deb10u8) ...
Created symlink /etc/systemd/system/getty.target.wants/getty@tty1.service → /lib/systemd/system/getty@.service.
Created symlink /etc/systemd/system/multi-user.target.wants/remote-fs.target → /lib/systemd/system/remote-fs.target.
Created symlink /etc/systemd/system/dbus-org.freedesktop.timesync1.service → /lib/systemd/system/systemd-timesyncd.service.
Created symlink /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service → /lib/systemd/system/systemd-timesyncd.service.
Initializing machine ID from random generator.
chfn: PAM: System error
adduser: `/usr/bin/chfn -f systemd Time Synchronization systemd-timesync' returned error code 1. Exiting.
dpkg: error processing package systemd (--configure):
 installed systemd package post-installation script subprocess returned error exit status 1
Setting up dmsetup (2:1.02.155-3) ...
Errors were encountered while processing:
 systemd
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

とりあえず無視するだけなら、以下の hook で通ります。

```bash
--essential-hook='chroot "$1" dpkg-divert --rename /usr/bin/chfn'
--essential-hook='chroot "$1" ln -s /bin/true /usr/bin/chfn'
--customize-hook='chroot "$1" rm /usr/bin/chfn'
--customize-hook='chroot "$1" dpkg-divert --remove --rename /usr/bin/chfn'
```

ちゃんと `chfn` の実行を再現するなら、以下のようにコマンドラインを残しておいて、後で `/root/chfn.fixup` を実行します。
上の例ではこれを使っています。

```bash
--essential-hook='chroot "$1" dpkg-divert --rename /usr/bin/chfn'
--essential-hook='printf "#!/bin/bash\n" > "$1/root/chfn.fixup"'
--essential-hook='chmod +x "$1/root/chfn.fixup"'
--essential-hook='printf "#!/bin/bash\n{ printf \"%%q \" \"\$0\" \"\$@\"; echo; } >> /root/chfn.fixup\n" > "$1/usr/bin/chfn"'
--essential-hook='chmod +x "$1/usr/bin/chfn"'
--customize-hook='chroot "$1" rm /usr/bin/chfn'
--customize-hook='chroot "$1" dpkg-divert --remove --rename /usr/bin/chfn'
```

[ビッグエンディアン検証環境構築 (Debian + systemd-nspawn) - Qiita](https://qiita.com/kakinaguru_zo/items/92e5a9bfdb26ffb810dc)
ではパッケージを減らして対応しているようです。

## まとめ

`qemu-user-static` を使って、別 arch のシステムコンテナを使うことができました。

以前試したときは、色々動かしていると `qemu-user-static` の制限やでうまく動かないものもあったので、
用途によっては `qemu-system-*` などのマシン自体のエミュレーションが必要になるかもしれませんが、
クロスコンパイルをしたり、ビッグエンディアンの動作確認をしたりするような用途には使えると思います。

`qemu` 自体も arch による実装の度合いの違いがあるようなので、ホストが arm で変だったとしても、
x86_64 だと大丈夫ということもあるかもしれません。
