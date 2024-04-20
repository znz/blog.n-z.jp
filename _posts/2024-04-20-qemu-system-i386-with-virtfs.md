---
layout: post
title: qemu-system-i386をvirtfsで適当に動かして2038年問題を確認した
date: 2024-04-20 17:26 +0900
comments: true
category: blog
tags: qemu debian linux
---
[Tokyo Debian 64bit time_t transition](https://slide.rabbit-shocker.org/authors/kenhys/tokyodebian-timet-transition-202404/)
をみて、手抜きで実験環境を作れないかと思って、
ディスクイメージを用意せず、
ルートディレクトリを virtfs + 9p で試してみました。

<!--more-->

## 動作確認環境

- Debian GNU/Linux 12 (bookworm)

## ディレクトリを用意

`mmdebstrap` で用意しました。

カーネルがなかったのでインストールして、
[9psetup](https://wiki.qemu.org/Documentation/9psetup)
のためのモジュールを追加して initramfs を作りなおしました。

後でログインするのに必要だったので、パスワードも設定しました。

```bash
mmdebstrap --arch=i386 bookworm /tmp/target
chroot /tmp/target apt update
chroot /tmp/target apt install linux-image-686

echo 9p >> /tmp/target/etc/initramfs-tools/modules
echo 9pnet_virtio >> /tmp/target/etc/initramfs-tools/modules
chroot /tmp/target update-initramfs -u -k all

chroot /tmp/target passwd
```

`9p.ko` と `9pnet.ko` と `9pnet_virtio.ko` が追加されているのを確認しました。

```console
# lsinitramfs /tmp/target/boot/initrd.img-6.1.0-20-686 | grep 9p
usr/lib/modules/6.1.0-20-686/kernel/fs/9p
usr/lib/modules/6.1.0-20-686/kernel/fs/9p/9p.ko
usr/lib/modules/6.1.0-20-686/kernel/net/9p
usr/lib/modules/6.1.0-20-686/kernel/net/9p/9pnet.ko
usr/lib/modules/6.1.0-20-686/kernel/net/9p/9pnet_virtio.ko
```

手抜きでネットワーク設定なしで起動するので、後からインストールはできないので、
後で試す `sudo` も `chroot /tmp/target apt install sudo` で入れておきます。

## 起動

こんな感じで起動できました。

```bash
#!/bin/bash
set -euxo pipefail
rootdir=/tmp/target
kernel=$(echo "$rootdir"/boot/vmlinuz-*-686 | tail -n1)
initrd=$(echo "$rootdir"/boot/initrd.img-*-686 | tail -n1)
mount_tag=root_mount

exec qemu-system-i386 \
-M q35 \
-nographic \
-kernel "$kernel" -initrd "$initrd" \
-append "console=tty0 console=ttyS0,115200 root=$mount_tag rootflags=trans=virtio,version=9p2000.L,posixacl,msize=512000 rootfstype=9p rw " \
-virtfs "local,path=$rootdir,mount_tag=$mount_tag,security_model=passthrough"
```

* `-M q35` は適当です。
* 直接 `kernel` と `initrd` を使ってブートローダーなしで起動しています。
* 起動しても何も表示されなかったので、とりあえず `console=tty0 console=ttyS0,115200` をつけました。ここは手抜きでちゃんと調べていないです。
* root 関係は `mount -t 9p -o trans=virtio,version=9p2000.L,posixacl,msize=512000 $mount_tag /` 相当です。
* `msize` は `msize=104857600` だと `9pnet: Limiting 'msize' to 512000 as this is the maximum supported by transport virtio` と出たので最大値にしています。
* read only になっていたので `rw` をつけています。
* `security_model=mapped-xattr` だと "Too many levels of symbolic links" で` init` が起動できなかったので、 `security_model=passthrough` にしています。この影響で `qemu-system-i386` 自体を root 権限で実行する必要があります。

## 時刻を指定して起動

[qemuで指定した日時の時計でVMを起動する]({% post_url 2024-03-01-qemu-start-at-specific-datetime %})
でやったように `-rtc clock=vm,base=時刻` を追加して起動しました。

ついでに、未来の時刻のファイルがホスト側に作られるのを防ぐために `ro` に戻しました。
未来の時刻のファイルは `/run` などの tmpfs のところで試せます。

```bash
#!/bin/bash
set -euxo pipefail
rootdir=/tmp/target
kernel=$(echo "$rootdir"/boot/vmlinuz-*-686 | tail -n1)
initrd=$(echo "$rootdir"/boot/initrd.img-*-686 | tail -n1)
mount_tag=root_mount

exec qemu-system-i386 \
-M q35 \
-nographic \
-kernel "$kernel" -initrd "$initrd" \
-rtc clock=vm,base=2038-01-18T12:14:00 \
-append "console=tty0 console=ttyS0,115200 root=$mount_tag rootflags=trans=virtio,version=9p2000.L,posixacl,msize=512000 rootfstype=9p ro " \
-virtfs "local,path=$rootdir,mount_tag=$mount_tag,security_model=passthrough"
```

## 再現

ある程度前の時刻で起動して、スライドのコマンドを試してみると再現できました。

```
root@somehost:~# date
Mon Jan 18 12:15:20 UTC 2038
root@somehost:~# sudo date --set="2038-01-19 12:14:00"
sudo: unable to resolve host somehost: Temporary failure in name resolution
[   87.235368] systemd-journald[180]: Assertion 'clock_gettime(map_clock_id(clock_id), &ts) == 0' failed at src/basic/time-util.c:54, function now(). Aborting.
Tue Jan 19 12:14:00 UTC 2038
root@somehost:~# sudo ls
sudo: unable to determine tty: Value too large for defined data type
sudo: unable to get time of day: Value too large for defined data type
sudo: error initializing audit plugin sudoers_audit
```

## 起動失敗

`-rtc clock=vm,base=2038-01-19T12:00:00`
のように問題の時刻が近すぎると `/init` が失敗して起動できませんでした。

```console
[   10.107050] Run /init as init process
/init: line 7: mkdir: Value too large for defined data type
/init: line 8: mkdir: Value too large for defined data type
/init: line 9: mkdir: Value too large for defined data type
/init: line 10: mkdir: Value too large for defined data type
/init: line 11: mkdir: Value too large for defined data type
/init: line 12: mkdir: Value too large for defined data type
#!/bin/bash
/init: line 13: mount: Value too large for defined data type
/init: line 14: mount: Value too large for defined data type
/init: line 17: cat: Value too large for defined data type
Loading, please wait...
/init: line 36: mount: Value too large for defined data type
/init: line 39: ln: Value too large for defined data type
/init: line 40: ln: Value too large for defined data type
/init: line 41: ln: Value too large for defined data type
/init: line 42: ln: Value too large for defined data type
/init: line 44: mkdir: Value too large for defined data type
/init: line 45: mount: Value too large for defined data type
/init: line 89: cat: Value too large for defined data type
/init: line 208: mount: Value too large for defined data type
/init: line 209: mkdir: Value too large for defined data type
Begin: Loading essential drivers ... done.
/init: line 149: cat: Value too large for defined data type
Begin: Running /scripts/init-premount ... done.
Begin: Mounting root file system ... Begin: Running /scripts/local-top ... done.
Begin: Running /scripts/local-premount ... done.
No root device specified. Boot arguments must include a root= parameter.
/init: line 87: sh: Value too large for defined data type
/init: line 209: blkid: Value too large for defined data type
Warning: Type of root file system is unknown, so skipping check.
/init: line 172: mount: Value too large for defined data type
Failed to mount  as root file system.
/init: line 87: sh: Value too large for defined data type
done.
Begin: Running /scripts/local-bottom ... done.
Begin: Running /scripts/init-bottom ... done.
/init: line 272: mount: Value too large for defined data type
/init: line 275: run-init: Value too large for defined data type
Target filesystem doesn't have requested /sbin/init.
/init: line 275: run-init: Value too large for defined data type
/init: line 275: run-init: Value too large for defined data type
/init: line 275: run-init: Value too large for defined data type
/init: line 275: run-init: Value too large for defined data type
/init: line 275: run-init: Value too large for defined data type
No init found. Try passing init= bootarg.
/init: line 87: sh: Value too large for defined data type
/init: line 326: mount: Value too large for defined data type
/init: line 327: mount: Value too large for defined data type
/init: line 331: can't open /root/dev/console: no such file
[   10.323745] Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100
[   10.324641] CPU: 0 PID: 1 Comm: init Not tainted 6.1.0-20-686 #1  Debian 6.1.85-1
[   10.325282] Hardware name: QEMU Standard PC (Q35 + ICH9, 2009), BIOS 1.16.2-debian-1.16.2-1 04/01/2014
[   10.325906] Call Trace:
[   10.327185]  dump_stack_lvl+0x34/0x44
[   10.327881]  dump_stack+0xd/0x10
[   10.328084]  panic+0xad/0x25c
[   10.328257]  do_exit.cold+0x14/0x14
[   10.328477]  do_group_exit+0x2b/0x80
[   10.328685]  __ia32_sys_exit_group+0x15/0x20
[   10.328928]  ia32_sys_call+0x16b7/0x28a0
[   10.329133]  __do_fast_syscall_32+0x61/0xb0
[   10.329378]  ? syscall_exit_to_user_mode+0x20/0x40
[   10.329632]  ? ia32_sys_call+0x18a5/0x28a0
[   10.329843]  ? __do_fast_syscall_32+0x6b/0xb0
[   10.330057]  ? __do_fast_syscall_32+0x6b/0xb0
[   10.330269]  ? exit_to_user_mode_prepare+0x9d/0x170
[   10.330519]  ? sysvec_call_function_single+0x40/0x40
[   10.330782]  do_fast_syscall_32+0x29/0x60
[   10.330998]  do_SYSENTER_32+0x15/0x20
[   10.331214]  entry_SYSENTER_32+0x98/0xfa
[   10.331557] EIP: 0xb7f16559
[   10.332235] Code: 10 05 03 74 b8 01 10 06 03 74 b4 01 10 07 03 74 b0 01 10 08 03 74 d8 01 00 00 00 00 00 00 00 00 00 51 52 55 89 e5 0f 34 cd 80 <5d> 5a 59 c3 90 90 90 90 8d 76 00 58 b8 77 00 00 06
[   10.333106] EAX: ffffffda EBX: 00000001 ECX: 000000fc EDX: 00000001
[   10.333416] ESI: ffffffb4 EDI: 00000001 EBP: 00000000 ESP: bf947f14
[   10.333722] DS: 007b ES: 007b FS: 0000 GS: 0033 SS: 007b EFLAGS: 00000292
[   10.334865] Kernel Offset: disabled
[   10.335496] ---[ end Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100 ]---
```

## busybox を確認

`/init` でエラーメッセージがでているコマンドは `busybox` のようなので、
起動後の環境でも試してみたところ、
`sudo` と同様のエラーメッセージがでました。

```console
# busybox mkdir /run/foo
# busybox ls /run/foo
ls: /run/foo: Value too large for defined data type
```

## qemu のコンソール操作

`-nographic` で起動しているときに `C-a c` で qemu のモニターと呼ばれるコンソールと VM 側のコンソールの切り替えができます。

`(qemu)` のプロンプトで `q` (`quit`) を入力すると終了できるので、
引数に失敗して起動できないときなどに使っています。

## まとめ

bookworm の `sudo` や (起動に失敗した initramfs の中でも使われている) `busybox` などは 2038 年問題に対応していないことがわかりました。

以前試した `-rtc` をまた別の用途に使うことができました。

9p をルートディレクトリにするのは `qemu-system-*` 自体を root 権限で動かす必要があるようで、
実験環境以外では使いにくそうなので、普通はブートローダーを入れたディスクイメージを作った方が良さそうでしたが、
カーネルや initrd を取り出さなくても直接指定できるのは楽でした。
