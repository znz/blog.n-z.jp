---
layout: post
title: "Ubuntu 22.04のパッケージ更新がWhich services should be restarted?で止まるのを防ぐ"
date: 2022-04-22 23:00 +0900
comments: true
category: blog
tags: linux ubuntu
---
Ubuntu 22.04 LTS には `needrestart` というパッケージが入っていて、パッケージの更新のときに「Daemons using outdated libraries」というダイアログに「Which services should be restarted?」という質問で再起動対象を選ぶ状態になることがあります。
開発環境や個人の環境なら、いちいち聞いてこなくても勝手に必要なデーモンは全部再起動してくれても大丈夫なので、そういう設定に変更しました。

<!--more-->

## 動作確認環境

- Ubuntu 22.04 LTS (jammy) の needrestart 3.5-5ubuntu2
- Ubuntu 21.10 (impish) の needrestart 3.5-4ubuntu2

lima 0.9.2 で動かしている arm64 版で動作確認しています。

## 設定内容

`/etc/needrestart/conf.d` の中に適当な `*.conf` ファイルを作成して設定します。
`/etc/needrestart/conf.d/README.needrestart` の説明によると Perl の sort 順で読み込まれるようなので、今回は頭に数字をつけて `50local.conf` という名前にしました。

```console
$ echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/50local.conf
$nrconf{restart} = 'a';
$ cat /etc/needrestart/conf.d/50local.conf
$nrconf{restart} = 'a';
```

## 動作確認

再起動されるデーモンが確実に存在しそうな glibc を `sudo apt reinstall libc6` で再インストールして動作確認しました。

設定前は `Restarting services...` の直後にダイアログがでてきていて、設定すると確認なしで進んでいます。

```console
$ sudo apt reinstall libc6
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
0 upgraded, 0 newly installed, 1 reinstalled, 0 to remove and 0 not upgraded.
Need to get 2707 kB of archives.
After this operation, 0 B of additional disk space will be used.
Get:1 http://ports.ubuntu.com/ubuntu-ports jammy/main arm64 libc6 arm64 2.35-0ubuntu3 [2707 kB]
Fetched 2707 kB in 3s (837 kB/s)
Preconfiguring packages ...
(Reading database ... 126073 files and directories currently installed.)
Preparing to unpack .../libc6_2.35-0ubuntu3_arm64.deb ...
Unpacking libc6:arm64 (2.35-0ubuntu3) over (2.35-0ubuntu3) ...
Setting up libc6:arm64 (2.35-0ubuntu3) ...
Processing triggers for libc-bin (2.35-0ubuntu3) ...
Scanning processes...
Scanning candidates...
Scanning linux images...

Running kernel seems to be up-to-date.

Restarting services...
 systemctl restart apt-cacher-ng.service cron.service irqbalance.service multipathd.service packagekit.service polkit.service rsyslog.service serial-getty@ttyAMA0.service snapd.service ssh.service systemd-journald.service systemd-networkd.service systemd-resolved.service systemd-timedated.service systemd-timesyncd.service systemd-udevd.service udisks2.service
Service restarts being deferred:
 systemctl restart ModemManager.service
 /etc/needrestart/restart.d/dbus.service
 systemctl restart getty@tty1.service
 systemctl restart networkd-dispatcher.service
 systemctl restart systemd-logind.service
 systemctl restart unattended-upgrades.service
 systemctl restart user@501.service

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
```

設定前に動作確認したときに出てきたダイアログは以下のような感じです。

	┌────┤ Daemons using outdated libraries ├─────┐
	│                                             │
	│                                             │
	│ Which services should be restarted?         │
	│                                             │
	│    [*] apt-cacher-ng.service                │
	│    [*] cron.service                         │
	│    [ ] dbus.service                         │
	│    [ ] getty@tty1.service                   │
	│    [*] irqbalance.service                   │
	│    [ ] ModemManager.service                 │
	│    [*] multipathd.service                   │
	│    [ ] networkd-dispatcher.service          │
	│    [*] packagekit.service                   │
	│    [*] polkit.service                       │
	│    [*] rsyslog.service                      │
	│    [*] serial-getty@ttyAMA0.service         │
	│    [*] snapd.service                        │
	│    [*] ssh.service                          │
	│    [*] systemd-journald.service             │
	│    [ ] systemd-logind.service               │
	│    [*] systemd-networkd.service             │
	│    [*] systemd-resolved.service             │
	│    [*] systemd-timesyncd.service            │
	│    [*] systemd-udevd.service                │
	│    [*] udisks2.service                      │
	│    [ ] unattended-upgrades.service          │
	│    [ ] user@501.service                     │
	│                                             │
	│                                             │
	│          <Ok>              <Cancel>         │
	│                                             │
	└─────────────────────────────────────────────┘


## その他の設定

`'a'` 以外に何が設定できるかとか、他に何が設定できるかなど、その他の設定は `/etc/needrestart/needrestart.conf` を参考にしてください。
設定ファイルの内容は perl で書く必要があります。

たとえば、以下のように説明されているので、 `$nrconf{restart} = 'l';` なら再起動せずに対象の一覧がでるだけになります。

    # Restart mode: (l)ist only, (i)nteractive or (a)utomatically.
    #
    # ATTENTION: If needrestart is configured to run in interactive mode but is run
    # non-interactive (i.e. unattended-upgrades) it will fallback to list only mode.
    #
    #$nrconf{restart} = 'i';

## まとめ

この件は lima で Ubuntu 21.10 を使っていて、いちいちダイアログが出てきて面倒だと思って調べて対処していました。

メッセージだけだと何のパッケージで出ているのか調べるのもやりにくく、Ubuntu 22.04 LTS がリリースされてからは、同じように感じる人が増えるかもしれないと思って、ブログ記事として残しておくことにしました。

2022-06-09 追記: [第718回　needrestartで学ぶパッケージのフック処理：Ubuntu Weekly Recipe](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0718)という記事があるようなので、さらに詳しいことが知りたいと思ったら、参考にしてみてください。
