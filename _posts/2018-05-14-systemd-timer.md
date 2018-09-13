---
layout: post
title: "systemctl list-timers の LAST が未来になっていてタイマーが実行されなかった"
date: 2018-05-14 22:50 +0900
comments: true
category: blog
tags: linux debian ubuntu windows systemd
---
毎日実行されるはずのタイマーが実行されなかったので、
systemctl list-timers で確認してみると LAST が未来になっていました。

<!--more-->

## 環境

- Windows Server 2012 の Hyper-V 上の Ubuntu 16.04.4 LTS (xenial)

## 発生タイミング

再起動した直後の時計がずれているようで、
そのタイミングで実行されたタイムスタンプが残ってしまうようです。

## 修正方法

[systemd/タイマー - ArchWiki](https://wiki.archlinux.jp/index.php/Systemd/%E3%82%BF%E3%82%A4%E3%83%9E%E3%83%BC)
に

> タイマーがズレる場合は、 `/var/lib/systemd/timers` にある `stamp-*` ファイルを削除してみてください。stamp ファイルはタイマーが実行された最後の時刻を記録しており、ファイルを削除することでタイマーの次の作動時に systemd が再構成を行います。

と書いてあるように、
`sudo rm -v /var/lib/systemd/timers/stamp-*.timer`
で削除して、
`sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer snapd.refresh.timer`
で一度止めて
`sudo systemctl start apt-daily.timer apt-daily-upgrade.timer snapd.refresh.timer`
で再開すると LAST が n/a になって復活しました。

## hwclock

`sudo hwclock --show` でみるとずれているので、
`sudo hwclock --systohc` で設定し直しているのですが、
再起動時に再発することがあるようなので、
根本的な解決策はまだわかっていません。

## 対策案

仕方がないので、
`hwclock --systohc` を定期的に実行して、いつ再起動されても良いようにしようかと検討中です。
