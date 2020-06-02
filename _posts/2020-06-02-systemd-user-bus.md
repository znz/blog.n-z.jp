---
layout: post
title: "ユーザー権限のsystemdにFailed to connect to busで繋がらない時の対処方法"
date: 2020-06-02 17:14 +0900
comments: true
category: blog
tags: linux debian ubuntu systemd
---
[systemd/ユーザー - ArchWiki](https://wiki.archlinux.jp/index.php/Systemd/%E3%83%A6%E3%83%BC%E3%82%B6%E3%83%BC)
などを参考にして、
`loginctl enable-linger user`
で `systemd` のユーザーインスタンスを起動していて、
`sudo -u user systemctl --user status`
などで
`Failed to connect to bus: No such file or directory`
となって繋がらなかったのですが、
`XDG_RUNTIME_DIR` を設定すればいいとわかりました。

<!--more-->

## 動作確認環境

- Ubuntu 18.04.4 LTS
- Raspbian GNU/Linux 10 (buster)

以上の環境で確認しましたが、
バージョンに依存することは少なそうなので、
古いバージョンや新しいバージョンでも同じだと思います。

## enable-linger 前

`enable-linger` 前は起動していないので、
`XDG_RUNTIME_DIR` を指定しても繋がりません。

```
$ sudo -u user systemctl --user status
Failed to connect to bus: No such file or directory
$ sudo -u user XDG_RUNTIME_DIR=/run/user/$(id -u user) systemctl --user status
Failed to connect to bus: No such file or directory
```

## enable-linger して確認

`enable-linger` で起動すると、
単純な `sudo` では繋がらないのですが、
`XDG_RUNTIME_DIR` を指定すると繋がります。

```
$ loginctl enable-linger user
$ sudo -u user systemctl --user status
Failed to connect to bus: No such file or directory
$ sudo -u user XDG_RUNTIME_DIR=/run/user/$(id -u user) systemctl --user status
● ubuntu
    State: running
     Jobs: 0 queued
   Failed: 0 units
    Since: Tue 2020-06-02 04:12:57 EDT; 5s ago
   CGroup: /user.slice/user-1000.slice/user@1000.service
           └─init.scope
             ├─4142 /lib/systemd/systemd --user
             └─4143 (sd-pam)
```

## disable-linger で停止

確認が終わって、不要なら
`disable-linger`
で戻しておきます。

```
$ loginctl disable-linger user
$ sudo -u user XDG_RUNTIME_DIR=/run/user/$(id -u user) systemctl --user status
Failed to connect to bus: No such file or directory
```

## 経緯

自分で調べたときは原因がよくわからなくて、
`pam_systemd` あたりで何か特殊な権限が設定されているのかと思っていたのですが、
[mameさん](https://github.com/mame)が同じ `Failed to connect to bus` で困っている時に
`sudo` だとダメだったので、
`ssh` で直接そのユーザーで入るようにした、
という話をしたところ、違いを調べてくれて、
`XDG_RUNTIME_DIR`
が違うということを教えてもらいました。
