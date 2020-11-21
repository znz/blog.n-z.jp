---
layout: post
title: "lxdでcloud-initを使ってchkbuildを動かしてみた"
date: 2020-11-21 21:30 +0900
comments: true
category: blog
tags: chkbuild lxd
---
32bit の x86 環境で chkbuild を動かしてみるのに [LXD](https://linuxcontainers.org/)環境を試してみました。
cloud-init で初期設定ができるようなので、 `lxc launch` だけで `chkbuild` が動くようにしてみました。

<!--more-->

## 動作確認環境

- Ubuntu 20.04
- lxd 4.x

## cloud-init

[cloud-init の FAQ の LXD](https://cloudinit.readthedocs.io/en/latest/topics/faq.html#lxd) に user data の指定方法があるので、それを参考にしてやってみました。

## lxd init

chkbuild はディスク容量が必要になるので、そこだけ増やして、他はデフォルトのままにしました。

```console
$ lxd init
Would you like to use LXD clustering? (yes/no) [default=no]:
Do you want to configure a new storage pool? (yes/no) [default=yes]:
Name of the new storage pool [default=default]:
Name of the storage backend to use (btrfs, dir, lvm, ceph) [default=btrfs]:
Create a new BTRFS pool? (yes/no) [default=yes]:
Would you like to use an existing empty block device (e.g. a disk or partition)? (yes/no) [default=no]:
Size in GB of the new loop device (1GB minimum) [default=12GB]: 30GB
Would you like to connect to a MAAS server? (yes/no) [default=no]:
Would you like to create a new local network bridge? (yes/no) [default=yes]:
What should the new bridge be called? [default=lxdbr0]:
What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]:
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]:
Would you like LXD to be available over the network? (yes/no) [default=no]:
Would you like stale cached images to be updated automatically? (yes/no) [default=yes]
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]:
```


## プロファイル例

`cloud-profile1.profile` として以下のようなファイルを用意して試しました。

```yaml
config:
  user.user-data: |
    #cloud-config
    package_upgrade: true
    packages:
    - git
```

profile を追加すると git が入っているのを確認できました。
default もつけておかないとネットワーク設定がなくなるので、
cloud-init の user data を追加するだけのプロファイルは default プロファイルと一緒に使うのが良さそうです。

```console
$ lxc profile create cloud-profile1
Profile cloud-profile1 created
$ cat cloud-profile1.profile | lxc profile edit cloud-profile1
$ lxc launch images:debian/10/cloud/i386 buster32 -p default -p cloud-profile1
Creating buster32
Starting buster32
$ lxc exec buster32 -- cloud-init status
status: done
$ lxc exec buster32 -- dpkg -l git | grep '^ii'
ii  git            1:2.20.1-2+deb10u3 i386         fast, scalable, distributed revision control system
$ lxc stop buster32
$ lxc delete buster32
```

```console
$ lxc launch images:debian/10/cloud/i386 buster32
Creating buster32
Starting buster32
$ lxc exec buster32 -- dpkg -l git | grep '^ii'
dpkg-query: no packages found matching git
$ lxc exec buster32 -- cloud-init query userdata
#cloud-config
package_upgrade: true
packages:
- git
$ lxc stop buster32
$ lxc delete buster32
```

## chkbuild 用の userdata.yaml 作成

`userdata.yaml` として `profile` では `config` の `user.user-data` の中身だった部分だけのファイルを作成して、
`lxc launch images:debian/10/cloud/i386 buster32 --config=user.user-data="$(cat userdata.yaml)"`
のように `--config` で直接指定して試しました。

provisioning と違って `lxc launch` したときしか実行できなさそうだったので、
用途によっては provisioning と併用した方が良さそうでした。

`users` で作成するユーザーは `uid` を指定できるようだったのですが、
`groups` で作成するグループの `gid` が指定できなかったので、
どちらも固定して外と共通の uid,gid にするのはあきらめました。

`runcmd` と `write_files` は他で設定したものをほぼそのまま持ってきました。

```yaml
#cloud-config
package_upgrade: true
packages:
- etckeeper
- git
- autoconf
- bison
- build-essential
- libssl-dev
- libyaml-dev
- libreadline-dev
- zlib1g-dev
- libncurses5-dev
- libffi-dev
- libgdbm6
- libgdbm-dev
- libdb-dev
- subversion
- ruby

groups:
- chkbuild-owner
- chkbuild

users:
- default
- name: chkbuild-owner
  primary_group: chkbuild-owner
  groups: chkbuild
  lock_passwd: true
  homedir: /home/chkbuild
  no_create_home: true
- name: chkbuild
  primary_group: chkbuild
  lock_passwd: true
  homedir: /home/chkbuild
  no_create_home: true

runcmd:
- install -o chkbuild-owner -g chkbuild -m 2755 -d /home/chkbuild
- install -o chkbuild-owner -g chkbuild -m 2775 -d /home/chkbuild/build
- install -o chkbuild-owner -g chkbuild -m 2775 -d /home/chkbuild/public_html
- [ su, chkbuild-owner, -c, "git clone https://github.com/ruby/chkbuild /home/chkbuild/chkbuild" ]
- ln -s /home/chkbuild /home/chkbuild/chkbuild/tmp
- systemctl enable --now chkbuild.timer

write_files:
- path: /etc/systemd/system/chkbuild.service
  content: |
    [Unit]
    Description=Run chkbuild

    [Service]
    Type=oneshot
    PermissionsStartOnly=true
    ExecStartPre=/sbin/runuser -u chkbuild-owner -- git pull origin master
    ExecStart=/home/chkbuild/chkbuild/start-build
    User=chkbuild
    Group=chkbuild
    WorkingDirectory=/home/chkbuild/chkbuild
    PrivateTmp=true

    # RUBYCI_NICKNAME
    # AWS_ACCESS_KEY_ID
    # AWS_SECRET_ACCESS_KEY
    EnvironmentFile=-/etc/systemd/system/chkbuild.env
  owner: root:root
  permissions: '0644'
- path: /etc/systemd/system/chkbuild.timer
  content: |
    [Unit]
    Description=Run chkbuild

    [Timer]
    OnBootSec=10min
    OnUnitInactiveSec=1h
    Persistent=true

    [Install]
    WantedBy=timers.target
  owner: root:root
  permissions: '0644'
```

## profile 作成

動作確認ができたら、以下のような `chkbuild-profile.yaml` を作成します。
(最初は `userdata.yaml` をそのまま使ってしまって設定されなくてしばらく悩みました。)

```yaml
config:
  user.user-data: |
    ここに userdata.yaml の内容をインデントして貼り付け
```

そして、以下のようにプロファイルに設定して起動しました。

```console
$ lxc profile create chkbuild
Profile chkbuild created
$ cat chkbuild-profile.yaml | lxc profile edit chkbuild
$ lxc launch images:debian/10/cloud/i386 buster32 -p default -p chkbuild
Creating buster32
Starting buster32
$
```

## 感想

`cloud-init` をちゃんと使ってみたのは始めてだったので、
一通りの設定を詰め込んでしまいましたが、
provisioning を実行できるところまでの設定にして、
後は provisioning で設定した方が良さそうに感じました。

profile としての yaml と user-data の中身だけの yaml が違うというのも、
気付かないと地味にはまるポイントになりそうでした。

chkbuild に関しては動かすだけだと実行結果が外から全く見えないので、
別途 Web サーバーを動かして見えるようにするか何かした方が良さそうでした。
