---
layout: post
title: "ディスクの有無でGRUBの起動処理を変更する"
date: 2025-05-10 17:35 +0900
comments: true
category: blog
tags: linux grub
---
Linux と Windows のデュアルブートで、
Windows を起動したいときに起動中に操作するタイミングを逃すことがあるので、
物理スイッチでどうにかしたいという話をみかけたので、
試してみた、という話です。

<!--more-->

## 動作確認環境

- Ubuntu 24.04.2 LTS (noble)
- grub-common など 2.12-1ubuntu7.1
- limactl version 1.0.7

## 前提知識

`sudo update-grub` で `grub.cfg` が更新されます。

`/etc/grub.d/` に数字2桁で始まるファイル名のシェルスクリプトが並んでいて、
昔の init.d script のようにファイル名で sort された順番に実行されて、
その出力が `grub.cfg` になります。

その前に `/etc/default/grub` と `/etc/default/grub.d/` のファイルで `/etc/grub.d/` で使う環境変数を設定するようになっています。

## カスタマイズ方法確認

`/etc/grub.d/40_custom` に以下の内容があって、
`/etc` 以下に完結した設定にしたいなら、この下に追記すれば良さそうです。

```bash
#!/bin/sh
exec tail -n +3 $0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
```

`/etc/grub.d/41_custom` に以下の内容があって、
`/boot/grub/custom.cfg` を作成すると追加で読み込んでくれます。

```bash
#!/bin/sh
cat <<EOF
if [ -f  \${config_directory}/custom.cfg ]; then
  source \${config_directory}/custom.cfg
elif [ -z "\${config_directory}" -a -f  \$prefix/custom.cfg ]; then
  source \$prefix/custom.cfg
fi
EOF
```

## grub での起動確認

`lima.yaml` で

```yaml
video:
  display: default
```

にして、
GUI を表示されるようにして、
`/etc/default/grub` で `GRUB_TIMEOUT_STYLE=menu` と `GRUB_TIMEOUT=10` にしても GRUB メニューが表示されなかったので、
GRUB を経由していないのかと勘違いしていたのですが、
`/etc/default/grub.d/50-cloudimg-settings.cfg`
で `GRUB_TIMEOUT=0` に上書きされていたからでした。

`/etc/default/grub`:

```sh
# If you change this file, run 'update-grub' afterwards to update
# /boot/grub/grub.cfg.
# For full documentation of the options in this file, see:
#   info -f grub -n 'Simple configuration'

GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=`( . /etc/os-release; echo ${NAME:-Ubuntu} ) 2>/dev/null || echo Ubuntu`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""

# If your computer has multiple operating systems installed, then you
# probably want to run os-prober. However, if your computer is a host
# for guest OSes installed via LVM or raw disk devices, running
# os-prober can cause damage to those guest OSes as it mounts
# filesystems to look for things.
#GRUB_DISABLE_OS_PROBER=false

# Uncomment to enable BadRAM filtering, modify to suit your needs
# This works with Linux (no patch required) and with any kernel that obtains
# the memory map information from GRUB (GNU Mach, kernel of FreeBSD ...)
#GRUB_BADRAM="0x01234567,0xfefefefe,0x89abcdef,0xefefefef"

# Uncomment to disable graphical terminal
#GRUB_TERMINAL=console

# The resolution used on graphical terminal
# note that you can use only modes which your graphic card supports via VBE
# you can see them in real GRUB with the command `vbeinfo'
#GRUB_GFXMODE=640x480

# Uncomment if you don't want GRUB to pass "root=UUID=xxx" parameter to Linux
#GRUB_DISABLE_LINUX_UUID=true

# Uncomment to disable generation of recovery mode menu entries
#GRUB_DISABLE_RECOVERY="true"

# Uncomment to get a beep at grub start
#GRUB_INIT_TUNE="480 440 1"
```

`/etc/default/grub.d/50-cloudimg-settings.cfg`:

```sh
# Cloud Image specific Grub settings for Generic Cloud Images
# CLOUD_IMG: This file was created/modified by the Cloud Image build process

# Set the recordfail timeout
GRUB_RECORDFAIL_TIMEOUT=0

# Do not wait on grub prompt
#GRUB_TIMEOUT=0

# Set the default commandline
GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyAMA0"

# Set the grub console type
GRUB_TERMINAL=console
```

## フラグに使えそうなもの

[keystatus](https://www.gnu.org/software/grub/manual/grub/html_node/keystatus.html#keystatus)
だと元々のタイミング問題があるので、
[GRUBでUSBメモリの有無を判定してブート先を変更する - turgenev’s blog](https://turgenev.hatenablog.com/entry/2024/11/26/222250)
と同じようにディスクの有無が一番無難そうでした。

他の USB HID デバイスなどは接続状態を取得して変数に設定する方法がコマンド一覧ではみつけられませんでした。

## ディスクを追加して ID 確認

`lima` 環境なので、
`limactl disk create flagdisk --size=1G` で作成して、
`limactl edit` で以下のように追加します。

```yaml
additionalDisks:
- flagdisk
```

`ls -l /dev/disk/by-uuid/` や `blkid` などで追加したディスクの UUID を確認します。

```console
$ ls -al /dev/disk/by-uuid/ | grep vdb
lrwxrwxrwx 1 root root  10 May 10 18:08 38d0a130-0f21-4382-864f-8d61f9062db4 -> ../../vdb1
$ blkid /dev/vdb1
/dev/vdb1: LABEL="lima-flagdisk" UUID="38d0a130-0f21-4382-864f-8d61f9062db4" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="f8236d87-a4a0-4664-9dc7-9c3700758ebf"
```

## 動作確認用のファイル作成

詳細は調べていませんが、GRUB のメニューでキー操作がきかなかったので、
`save_env` で動作確認することにしました。

```console
$ sudo cp /boot/grub/grubenv /boot/grub/flagenv
```

GRUB の中で `save_env --file $prefix/flagenv 変数名` で書き込みます。

そして、起動後に `sudo grub-editenv /boot/grub/flagenv list` で内容を確認できます。


## 特定のディスクがあれば起動処理変更

### UUID で指定

`/boot/grub/custom.cfg` に以下の内容を作成しました。

```sh
search --no-floppy --fs-uuid --set=flagdisk 38d0a130-0f21-4382-864f-8d61f9062db4
save_env --file $prefix/flagenv flagdisk
if [ "${flagdisk}" ] ; then
  set default="1>2"
fi
```

以下のように Advanced options for Ubuntu (1) の Ubuntu, with Linux 6.8.0-55-generic (2) で起動できています。
(起動対象の指定は GRUB メニュー画面の順番で 0-オリジンの数値または menuentry の名前で指定、submenu の中は `>` で指定)

search の結果は `hd1,gpt1` になっていました。

```console
$ sudo grub-editenv /boot/grub/flagenv list
next_entry=
flagdisk=hd1,gpt1
$ ls -l /boot/vmlinuz*
lrwxrwxrwx 1 root root       24 May  7 09:06 /boot/vmlinuz -> vmlinuz-6.8.0-59-generic
-rw------- 1 root root 18287678 Feb 13 03:44 /boot/vmlinuz-6.8.0-55-generic
-rw------- 1 root root 18302580 Apr 12 06:25 /boot/vmlinuz-6.8.0-59-generic
lrwxrwxrwx 1 root root       24 Mar 13 17:43 /boot/vmlinuz.old -> vmlinuz-6.8.0-55-generic
$ uname -r
6.8.0-55-generic
```

`limactl edit` で `additionalDisks` の `- flagdisk` をコメントアウトして試すと元の状態で起動できました。
このとき、`${flagdisk}` は空文字列になっていました。

```console
$ uname -r
6.8.0-59-generic
$ sudo grub-editenv /boot/grub/flagenv list
next_entry=
```

### LABEL で指定

ラベルで指定する場合は `search` で `--fs-uuid` の代わりに `--label` を使います。

```sh
search --no-floppy --label --set=flagdisk lima-flagdisk
```

他は UUID のときと同じです。

ラベルならストレージが壊れたときに別のストレージに同じラベルをつけてフラグとして使う、ということもやりやすいですが、
同じラベルのストレージがあると混乱しやすいというデメリットもあるので、
用途次第で使いわけると良さそうです。

### file

`search` は `--file` で探すこともできます。

`lima` の `additionalDisks` の `flagdisk` は `/mnt` 以下の `/mnt/lima-flagdisk` にマウントされていたので、
`/mnt/lima-flagdisk/custom2.cfg` として以下のファイルを作成しました。

```sh
set default="1>2"
```

そして `/boot/grub/custom.cfg` を以下の内容にしました。

```sh
search --no-floppy --file --set=flagdisk /custom2.cfg
if [ "${flagdisk}" ] ; then
  source (${flagdisk})/custom2.cfg
fi
```

`--set=root` ではないので、
`source` の引数に `(${flagdisk})` をつけて、このパーティションの中のパスだと明示しています。
(ファイルパスの詳細は [GNU GRUB Manual 2.12: File name syntax](https://www.gnu.org/software/grub/manual/grub/html_node/File-name-syntax.html#File-name-syntax) 参照)

この方法ならフラグ用のディスクに別の起動内容も設定できます。

[source コマンド](https://www.gnu.org/software/grub/manual/grub/html_node/source.html#source)を使っているので、
元の `grub.cfg` の内容に追加したい内容だけ書きましたが、
[configfile コマンド](https://www.gnu.org/software/grub/manual/grub/html_node/configfile.html#configfile)で `grub.cfg` 全体を書いたファイルを使っても良さそうです。

[GRUB - ArchWiki](https://wiki.archlinux.org/title/GRUB) の例にあるように `chainloader` などで使っても良さそうです。

## ネットワーク経由で読み込み

[GNU GRUB Manual 2.12: Device syntax](https://www.gnu.org/software/grub/manual/grub/html_node/Device-syntax.html#Device-syntax)
には http や tftp も指定できるようなので、
http を試してみました。

まずホスト側で `http://192.168.253.133:8080/custom3.txt` を用意しました。

```console
% cat /tmp/x/custom3.txt
set default="1>2"
% ruby -run -e httpd -- --bind-address=0.0.0.0 /tmp/x
```

それを読み込む設定にしました。

```sh
$ cat /mnt/lima-flagdisk/custom2.cfg
net_dhcp
source (http,192.168.253.133:8080)/custom3.txt
```

これで古いカーネルの方で起動できました。

平文の http や tftp はセキュリティ的には脆弱なので、
テスト用とか LAN 内などの限られた範囲での利用にとどめておいた方が良さそうです。

ちょっと試した感じだとホスト名を指定したインターネット経由の読み込みがうまくいかず、
DNS の問題なのか、パス指定が間違えていたのかわかりませんでしたが、
セキュリティの問題もあるので、深追いはしませんでした。

## まとめ

`search` コマンドを使うことでディスクの有無で起動処理を分岐できました。
フラグ用に既存のディスクを流用したかったり、特定の GRUB の設定に分岐処理をまとめておきたかったりする場合はこの方法が良さそうです。

そもそも自由に書きかえてしまって良いディスクがあるなら、そのディスクに Windows 起動用のブートローダーを入れておくだけでも良さそうです。

本題とは外れますが、
`save_env` でデバッグ用の情報を残したり、
ネットワーク経由の読み込みも試したりしました。
