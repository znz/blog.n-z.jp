---
layout: post
title: "systemd-nspawnやmachinectlで軽量システムコンテナを使う"
date: 2022-09-27 12:00 +0900
comments: true
category: blog
tags: linux debian ubuntu nspawn machinectl
---
`systemd-nspawn` やそれを使った `machinectl` でのノウハウがたまってきたので、何回かにわけてまとめていきたいと思います。

<!--more-->

## 動作確認環境

- Apple M1 Pro の macOS Monterey 12.6
- limactl version 0.12.0
- aarch64 の Debian GNU/Linux 11 (bullseye)
- aarch64 の Ubuntu 22.04.1 LTS (jammy)

## 環境作成

`limactl start --name=debian-nspawn template://debian`
と
`limactl start --name=ubuntu-nspawn template://ubuntu-lts`
で作成した環境で試しました。

特に差がない部分については、Debian での実行結果を載せています。

## 初期設定

コンテナのネットワーク設定との連携の都合で、ネットワークの設定を `ifupdown` から `systemd-networkd` と `systemd-resolved` に変更しておきます。

Ubuntu 22.04 では、細かく確認したわけではないのですが、 `netplan` (`/etc/netplan/50-cloud-init.yaml`) で `systemd-networkd` と `systemd-resolved` の設定がされているようなので、そのままで大丈夫でした。

Debian 11 では <https://wiki.debian.org/SystemdNetworkd> を参考にして `lan0.network` を作成しておきます。

```console
% limactl start --name=debian-nspawn template://debian
(略)
% limactl shell debian-nspawn
$ sudo mv /etc/network/interfaces{,.save}
$ printf '[Match]\nName=eth0\n\n[Network]\nDHCP=ipv4\n' | sudo tee /etc/systemd/network/lan0.network
[Match]
Name=eth0

[Network]
DHCP=ipv4
$ systemctl status systemd-networkd systemd-resolved
● systemd-networkd.service - Network Service
	 Loaded: loaded (/lib/systemd/system/systemd-networkd.service; disabled; vendor preset: enabled)
	 Active: inactive (dead)
TriggeredBy: ● systemd-networkd.socket
	   Docs: man:systemd-networkd.service(8)

● systemd-resolved.service - Network Name Resolution
	 Loaded: loaded (/lib/systemd/system/systemd-resolved.service; disabled; vendor preset: enabled)
	 Active: inactive (dead)
	   Docs: man:systemd-resolved.service(8)
			 man:org.freedesktop.resolve1(5)
			 https://www.freedesktop.org/wiki/Software/systemd/writing-network-configuration-managers
			 https://www.freedesktop.org/wiki/Software/systemd/writing-resolver-clients
$ sudo systemctl enable systemd-networkd systemd-resolved
Created symlink /etc/systemd/system/dbus-org.freedesktop.network1.service → /lib/systemd/system/systemd-networkd.service.
Created symlink /etc/systemd/system/multi-user.target.wants/systemd-networkd.service → /lib/systemd/system/systemd-networkd.service.
Created symlink /etc/systemd/system/sockets.target.wants/systemd-networkd.socket → /lib/systemd/system/systemd-networkd.socket.
Created symlink /etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service → /lib/systemd/system/systemd-networkd-wait-online.service.
Created symlink /etc/systemd/system/dbus-org.freedesktop.resolve1.service → /lib/systemd/system/systemd-resolved.service.
Created symlink /etc/systemd/system/multi-user.target.wants/systemd-resolved.service → /lib/systemd/system/systemd-resolved.service.
$ sudo poweroff
% limactl start debian-nspawn
(略)
% limactl shell debian-nspawn
```

固定アドレスのときは `Network` で以下のようにちゃんと設定しておきます。

```ini
[Match]
Name=eth0

[Network]
Address=192.168.0.2/24
Gateway=192.168.0.1
DNS=192.168.0.1
```

## インストール

`systemd-container` パッケージをインストールすると `/bin/machinectl` や `/usr/bin/systemd-nspawn` が使えるようになります。

```console
$ sudo apt install systemd-container
```

## btrfs を使う

`machinectl` は `btrfs` と組み合わせたときのみ使える機能があるようなので、 `btrfs` を使うようにしています。
`/` 自体が `btrfs` なら `sudo btrfs subvolume create /var/lib/machines` でサブボリュームを作成しておくだけで良さそうです。

他に適当な場所がなかったので、 `/` 直下に `fallocate` でディスクイメージファイルを作成しています。
それを `btrfs` でフォーマットして、 `/var/lib/machines` にマウントします。
マウントオプションは `defaults` に含まれる `relatime` に追加で `lazytime` を指定しているのと、ちょっと圧縮を強めにした `compress=ztd:5` を指定しています。
`zstd` のデフォルトの 3 から 5 にしたのは適当で、ちゃんとした根拠はありません。

新しいファイルシステムをマウントするとパーミッションが変わってしまうので、 `/usr/lib/tmpfiles.d/systemd-nspawn.conf` の設定を反映させるために `systemd-tmpfiles --create` を実行しています。

```console
$ sudo fallocate -l 50G /machines.img
$ sudo apt install btrfs-progs
$ sudo mkfs.btrfs /machines.img
btrfs-progs v5.10.1
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               228788fc-dbbd-479f-8aee-f0e22791931a
Node size:          16384
Sector size:        4096
Filesystem size:    50.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP             256.00MiB
  System:           DUP               8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Runtime features:
Checksum:           crc32c
Number of devices:  1
Devices:
   ID        SIZE  PATH
	1    50.00GiB  /machines.img

$ echo /machines.img /var/lib/machines btrfs defaults,lazytime,compress=zstd:5 0 0 | sudo tee -a /etc/fstab
/machines.img /var/lib/machines btrfs defaults,lazytime,compress=zstd:5 0 0
$ sudo mount /var/lib/machines
$ grep ' /var/lib/machines ' /usr/lib/tmpfiles.d/systemd-nspawn.conf
Q /var/lib/machines 0700 - - -
$ sudo systemd-tmpfiles --create
```

Ubuntu 22.04 では `btrfs-progs` がインストール済みでバージョンも Debian 11 より新しいものでした。

```console
$ sudo mkfs.btrfs /machines.img
btrfs-progs v5.16.2
See http://btrfs.wiki.kernel.org for more information.

NOTE: several default settings have changed in version 5.15, please make sure
      this does not affect your deployments:
      - DUP for metadata (-m dup)
      - enabled no-holes (-O no-holes)
      - enabled free-space-tree (-R free-space-tree)

Label:              (null)
UUID:               d8d6616f-f2d4-478f-905b-4ecaee87d34f
Node size:          16384
Sector size:        4096
Filesystem size:    50.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP             256.00MiB
  System:           DUP               8.00MiB
SSD detected:       no
Zoned device:       no
Incompat features:  extref, skinny-metadata, no-holes
Runtime features:   free-space-tree
Checksum:           crc32c
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1    50.00GiB  /machines.img
```

## mmdebstrap で bullseye を試す

`debootstrap` よりも `mmdebstrap` の方が新しくて良さそうだったので、そちらを使って、Debian のホスト側と同じ `bullseye` を試します。

Ubuntu では `debian-archive-keyring` もインストールしておきます。(Debian ではすでに入っています。)

`--arch` は省略できますが、今後の都合で指定しています。

他は普通に使うのに必要な最低限の設定を追加しています。

`dbus` は `machinectl` での制御に必須なので明示的に追加しています。

ホストとコンテナが同じ arch なら `ifupdown` の代わりに `systemd-networkd` と `systemd-resolved` でネットワークの自動設定ができるので、
`/etc/network/interfaces` を無効化して、 `systemd-networkd` などを有効化しています。

設定する `SUITE` として `bullseye` を指定しています。

`TARGET` として tarball を作成するようにしています。
`/var/lib/machines/bullseye` のようにディレクトリを指定して作成することもできるのですが、
ファイルの owner などの問題が起きることがあったので、一度 tarball にしてから
`machinectl import-tar` で取り込む手順にしています。
その方が繰り返し `import` からやり直すこともできるという利点もあります。

```console
$ sudo apt install mmdebstrap
(略)
$ sudo apt install debian-archive-keyring
(略)
$ mmdebstrap --arch=arm64 --include=dbus \
   --customize-hook='chroot "$1" mv /etc/network/interfaces /etc/network/interfaces.save' \
   --customize-hook='chroot "$1" systemctl enable systemd-networkd systemd-resolved' \
   bullseye /tmp/bullseye-arm64.tar
I: automatically chosen mode: unshare
I: chroot architecture arm64 is equal to the host's architecture
I: automatically chosen format: tar
I: using /tmp/mmdebstrap.cUm6DaB4cZ as tempdir
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
done
I: running --customize-hook in shell: sh -c 'chroot "$1" mv /etc/network/interfaces /etc/network/interfaces.save' exec /tmp/mmdebstrap.cUm6DaB4cZ
I: running --customize-hook in shell: sh -c 'chroot "$1" systemctl enable systemd-networkd systemd-resolved' exec /tmp/mmdebstrap.cUm6DaB4cZ
Created symlink /etc/systemd/system/dbus-org.freedesktop.network1.service → /lib/systemd/system/systemd-networkd.service.
Created symlink /etc/systemd/system/multi-user.target.wants/systemd-networkd.service → /lib/systemd/system/systemd-networkd.service.
Created symlink /etc/systemd/system/sockets.target.wants/systemd-networkd.socket → /lib/systemd/system/systemd-networkd.socket.
Created symlink /etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service → /lib/systemd/system/systemd-networkd-wait-online.service.
Created symlink /etc/systemd/system/dbus-org.freedesktop.resolve1.service → /lib/systemd/system/systemd-resolved.service.
Created symlink /etc/systemd/system/multi-user.target.wants/systemd-resolved.service → /lib/systemd/system/systemd-resolved.service.
I: cleaning package lists and apt cache...
done
done
I: creating tarball...
I: done
I: removing tempdir /tmp/mmdebstrap.cUm6DaB4cZ...
I: success in 15.0921 seconds
```

tarball が作成できたら、 `machinectl import-tar` で取り込みます。

```console
$ sudo machinectl import-tar /tmp/bullseye-arm64.tar bullseye-arm64
Enqueued transfer job 1. Press C-c to continue download in background.
Importing '/tmp/bullseye-arm64.tar', saving as 'bullseye-arm64'.
Imported 0%.
Imported 47%.
Imported 82%.
Imported 94%.
Imported 95%.
Imported 96%.
Imported 97%.
Imported 99%.
Operation completed successfully.
Exiting.
$ sudo ls -al /var/lib/machines
total 20
drwx------  1 root root   28 Sep 27 04:00 .
drwxr-xr-x 25 root root 4096 Sep 27 03:57 ..
drwxr-xr-x  1 root root  122 Sep 27 03:59 bullseye-arm64
$ sudo btrfs subvolume list /var/lib/machines
ID 257 gen 10 top level 5 path bullseye-arm64
$ machinectl list-images
NAME           TYPE      RO  USAGE CREATED                     MODIFIED
bullseye-arm64 subvolume no 101.6M Tue 2022-09-27 04:00:56 UTC n/a

1 images listed.
$ machinectl list
No machines.
```

インポートできたら `machinectl start` で起動します。
`machinectl shell` は `root` 権限が必要です。

```console
$ sudo machinectl start bullseye-arm64
$ machinectl list
MACHINE        CLASS     SERVICE        OS     VERSION ADDRESSES
bullseye-arm64 container systemd-nspawn debian 11      192.168.9.39…

1 machines listed.
$ machinectl shell bullseye-arm64
Failed to get shell PTY: Access denied
$ sudo machinectl shell bullseye-arm64
Connected to machine bullseye-arm64. Press ^] three times within 1s to exit session.
root@lima-debian-nspawn:~#
```

これで `apt update` などが動きます。

一般ユーザー権限で `machinectl shell` を実行すると、
Debian では上の例のように `Failed to get shell PTY: Access denied` になりますが、
Ubuntu 22.04 では以下のようにパスワードをきかれてしまいます。

```console
$ machinectl shell bullseye-arm64
==== AUTHENTICATING FOR org.freedesktop.machine1.shell ===
Authentication is required to acquire a shell in a local container.
Authenticating as: root
Password:
```

## トラブルシューティング

### shell が開けない

`Failed to get shell PTY: Access denied` は権限不足なので `sudo` で解決します。

### machinectl の操作がきかない

`machinectl shell` で `Failed to get shell PTY: Protocol error` になるときは `dbus` が動いていません。

`sudo systemd-nspawn -U -D /var/lib/machines/$NAME` を使って、システムコンテナではなく直接シェルを起動して `dbus` をインストールすれば解決します。

`-U` を忘れて `apt update` してしまうと、ファイルの owner がずれてしまいます。
そうなると復旧は困難なので、必要なファイルを直接 `/var/lib/machines/$NAME` の下からコピーしてバックアップして、コンテナを作りなおすのが無難です。

```console
$ sudo systemd-nspawn -U -D /var/lib/machines/bullseye
# apt update
# apt install dbus
```

他にもシェルからの操作で直す必要があるときは `systemd-nspawn -U -D` が使えます。

ファイルの編集だけで直せるときは `/var/lib/machines/$NAME` の下のファイルを直接編集してしまっても良いと思います。

### ネットワーク問題

`machinectl list` で `ADDRESSES` が `-` のときはネットワークにつながっていません。

```console
$ machinectl list
MACHINE        CLASS     SERVICE        OS     VERSION ADDRESSES
bullseye-arm64 container systemd-nspawn debian 11      -

1 machines listed.
```

ホスト側で `systemd-networkd` を使わずに `ifupdown` の `/etc/network/interfaces` での設定を使っていると `n/a` と `unmanaged` になります。

```console
$ networkctl
WARNING: systemd-networkd is not running, output will be incomplete.

IDX LINK            TYPE     OPERATIONAL SETUP
  1 lo              loopback n/a         unmanaged
  2 eth0            ether    n/a         unmanaged
  3 ve-bullseyeHYh7 ether    n/a         unmanaged

3 links listed.
```

コンテナ側でのネットワーク設定ができていないと `no-carrier` と `configuring` になります。

```console
$ networkctl
IDX LINK            TYPE     OPERATIONAL SETUP
  1 lo              loopback carrier     unmanaged
  2 eth0            ether    routable    configured
  3 ve-bullseyeHYh7 ether    no-carrier  configuring

4 links listed.
```

正常なときは `routable` と `configured` になります。

```console
$ networkctl
IDX LINK            TYPE     OPERATIONAL SETUP
  1 lo              loopback carrier     unmanaged
  2 eth0            ether    routable    configured
  3 ve-bullseyeHYh7 ether    routable    configured

3 links listed.
```

`systemd-networkd` と `systemd-resolved` を使うなら、
`mmdebstrap` の引数で以下のように設定しておきます。

```bash
--customize-hook='chroot "$1" mv /etc/network/interfaces /etc/network/interfaces.save'
--customize-hook='chroot "$1" systemctl enable systemd-networkd systemd-resolved'
```

Debian のデフォルトの `ifupdown` をそのまま使うなら、
`mmdebstrap` の引数で以下のように `host0` の設定を追加しておきます。

```bash
--customize-hook='printf "auto host0\niface host0 inet dhcp\n" > "$1"/etc/network/interfaces.d/host0'
```

## ホスト名を変更する

tarball 作成前なら `mmdebstrap` の引数で以下のようにホスト名の設定をしておきます。

```bash
--customize-hook='echo '"$NAME"' > "$1/etc/hostname"'
--customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"'
```

作成済みのコンテナで同様の設定をするなら以下のようになります。

```console
$ sudo machinectl shell bullseye-arm64
Connected to machine bullseye-arm64. Press ^] three times within 1s to exit session.
root@lima-debian-nspawn:~# cat /etc/hostname
lima-debian-nspawn
root@lima-debian-nspawn:~# echo bullseye-arm64 > /etc/hostname
root@lima-debian-nspawn:~# echo 172.0.1.1 bullseye-arm64 >> /etc/hosts
root@lima-debian-nspawn:~# poweroff

Connection to machine bullseye-arm64 terminated.
$ sudo machinectl start bullseye-arm64
$ sudo machinectl shell bullseye-arm64
Connected to machine bullseye-arm64. Press ^] three times within 1s to exit session.
root@bullseye-arm64:~#
```

## 自動起動

`machinectl enable` でホスト起動時にコンテナも自動起動するように設定できます。
`machinectl disable` で戻せます。

```console
$ sudo machinectl enable bullseye-arm64
Created symlink /etc/systemd/system/machines.target.wants/systemd-nspawn@bullseye-arm64.service → /lib/systemd/system/systemd-nspawn@.service.
$ sudo machinectl disable bullseye-arm64
Removed /etc/systemd/system/machines.target.wants/systemd-nspawn@bullseye-arm64.service.
$ sudo systemctl enable systemd-nspawn@bullseye-arm64.service
Created symlink /etc/systemd/system/machines.target.wants/systemd-nspawn@bullseye-arm64.service → /lib/systemd/system/systemd-nspawn@.service.
```

`systemd-nspawn@bullseye-arm64.service` の操作なので、
`sudo systemctl enable systemd-nspawn@bullseye-arm64.service`
のように `systemctl` を使っても同じですが、
短いので `machinectl` を使っています。

## systemd service

`systemd` の unit なので、
`systemctl edit systemd-nspawn@bullseye-arm64.service`
で個別の設定をしたり、
`systemctl edit systemd-nspawn@.service`
で共通の設定をしたりできます。

### /tmp の容量不足問題対応

`systemd-nspawn` のデフォルトでは `/tmp` が `tmpfs` になって、容量が少なくて困ることがあったので、
[systemd-nspawnのtmpディレクトリ](https://yaasita.github.io/2021/12/12/systemd-nspawn-tmpdir/)に書いてあるように
`SYSTEMD_NSPAWN_TMPFS_TMP=0` を設定しています。

```console
$ sudo systemctl edit systemd-nspawn@.service
$ cat /etc/systemd/system/systemd-nspawn\@.service.d/override.conf
[Service]
Environment=SYSTEMD_NSPAWN_TMPFS_TMP=0
```

参考サイトでは
`/etc/systemd/system/systemd-nspawn@.service`
を作成して変更しているようですが、
バージョンアップ時に困ることがあるので、
`systemd` の作法にのっとって、
`/etc/systemd/system/systemd-nspawn@.service.d/*.conf`
を作成するのがオススメです。

### nspawn ファイル

`/lib/systemd/system/systemd-nspawn@.service` では
`ExecStart=systemd-nspawn --quiet --keep-unit --boot --link-journal=try-guest --network-veth -U --settings=override --machine=%i`
となっていて、このオプションを変更したいこともあると思いますが、
これは
`/etc/systemd/system/systemd-nspawn@.service.d/*.conf`
ではなく
`/etc/systemd/nspawn/*.nspawn`
で変更するのがオススメです。

`--settings=override`
がついているので、
[systemd.nspawn(5)](https://www.freedesktop.org/software/systemd/man/systemd.nspawn.html)
に説明されているような設定が変更できます。
設定項目は `systemd` のバージョンによって使えるかどうかが違うことがあるので、対象の環境で `man systemd.nspawn` で確認してください。

`/etc/systemd/system/systemd-nspawn@NAME.d/override.conf` は `machinectl remove NAME` をしても残りますが、
`/etc/systemd/nspawn/NAME.nspawn` は `machinectl remove NAME` で一緒に削除されるようなので、
設定を使い回して作りなおしたいときは気を付けてください。

## コンテナを終了する

`machinectl poweroff` が普通の終了方法で、
`machinectl terminate` が強制終了です。

うまく終了してくれないと思ったときは、
`sudo systemctl stop systemd-nspawn@bullseye-arm64.service`
のように `systemctl stop` を使うと安全な方法から順番に試して最終的に全部止めてくれます。

## コンテナの削除

止めた状態で `machinectl remove NAME` で削除できます。

## まとめ

まず今回は `systemd-nspawn` や `machinectl` による最低限のシステムコンテナの作り方を紹介しました。

最終的に最低限のコンテナを増やして使って削除する手順はまとめなおすと以下のようになります。

```console
$ NAME=bullseye-arm64
$ mmdebstrap --arch=arm64 --include=dbus \
   --customize-hook='chroot "$1" mv /etc/network/interfaces /etc/network/interfaces.save' \
   --customize-hook='chroot "$1" systemctl enable systemd-networkd systemd-resolved' \
   --customize-hook='echo '"$NAME"' > "$1/etc/hostname"' \
   --customize-hook='echo "127.0.1.1 '"$NAME"'" >> "$1/etc/hosts"' \
   bullseye /tmp/$NAME.tar
$ sudo machinectl import-tar /tmp/$NAME.tar $NAME
$ sudo machinectl start $NAME
$ sudo machinectl shell $NAME
# 作業
$ sudo machinectl poweroff $NAME
$ sudo machinectl terminate $NAME
$ sudo machinectl remove $NAME
```

継続的に使うなら、
`sudo machinectl enable $NAME`
で自動起動します。
