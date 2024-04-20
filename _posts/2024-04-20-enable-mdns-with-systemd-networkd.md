---
layout: post
title: "systemd-networkd環境でnetplanやvirbr0のmDNSを有効にする"
date: 2024-04-20 13:15 +0900
comments: true
category: blog
tags: linux debian ubuntu
---
LAN 内や仮想マシンとの間で mDNS での名前解決ができると便利なので、
`systemd-networkd` で netplan 管理のネットワークや `libvirt` 管理の `virbr0` などでも
mDNS を有効にするようにした方法のメモです。

<!--more-->

## 動作確認環境

- Ubuntu 22.04.4 LTS (jammy)
- Debian GNU/Linux 12 (bookworm)

以下の実行例では Ubuntu の方のプロンプトを `%` で Debian の方のプロンプトを `$` にしています。

## resolvectl mdns

mdns が有効になっているかどうかは `resolvectl mdns` で確認できます。

Global で yes になっている状態で、さらに mDNS を使いたい LAN につながっている interface で yes にすると使えます。

`resolve` なら名前解決だけ有効にします。

以下の例だと `eth0` や `virbr0` だけ mDNS が有効になっています。

```console
% resolvectl mdns
Global: yes
Link 2 (eth0): yes
Link 3 (wlan0): no
```

```console
$ resolvectl mdns
Global: yes
Link 2 (ens5): no
Link 3 (virbr0): yes
```

## Global

`/etc/systemd/resolved.conf` で `MulticastDNS=yes` になっていれば有効です。

Debian 12 ではデフォルトで有効になっていたので、新しい環境だとデフォルトで有効になっているかもしれません。

```console
% systemd-analyze cat-config systemd/resolved.conf | grep MulticastDNS
#MulticastDNS=no
MulticastDNS=yes
```

```console
$ systemd-analyze cat-config systemd/resolved.conf | grep MulticastDNS
#MulticastDNS=yes
```

`sudoedit /etc/systemd/resolved.conf`
などで編集した後、
`sudo systemctl restart systemd-resolved.service`
で反映します。

`sudo systemctl daemon-reload` は不要です。
`sudo systemctl reload systemd-resolved.service` は `Failed to reload systemd-resolved.service: Job type reload is not applicable for unit systemd-resolved.service.` と言われて使えませんでした。

## netplan

`/run/systemd/network/` で network ファイルのファイル名を調べて、
`/etc/systemd/network/調べたファイル名.network.d/mdns.conf`
のような drop-in ファイルを作って設定します。

```console
% ls /run/systemd/network/
10-netplan-eth0.link  10-netplan-eth0.network
% cat /etc/systemd/network/10-netplan-eth0.network.d/mdns.conf
[Network]
MulticastDNS=yes
```

`MulticastDNS=true` でも同じで、
`MulticastDNS=resolve` のように
この interface は名前解決だけ、という指定もできます。

`sudo mkdir /etc/systemd/network/10-netplan-eth0.network.d` して
`sudoedit /etc/systemd/network/10-netplan-eth0.network.d/mdns.conf`
などで編集した後、
`sudo systemctl reload systemd-networkd.service`
で反映します。
`sudo systemctl daemon-reload` は不要です。

`systemd-analyze cat-config systemd/network/10-netplan-eth0.network`
でちゃんとねらった interface に設定が入っているか確認しておくと良いかもしれません。

## virbr0

`libvirt` の `virbr0` は `systemd-networkd` 管理ではないため、
network ファイルの drop-in で設定できず、
`libvirt` の XML のネットワーク設定でも、
試したバージョンでは mDNS の設定はできませんでした。

何か方法がないか色々と調べてみたところ、
<https://www.libvirt.org/hooks.html#etc-libvirt-hooks-network>
で `/etc/libvirt/hooks/network` を用意すればできそうとわかったので、
以下のような `/etc/libvirt/hooks/network` を用意して、
`sudo virsh net-start default` でスタートすると有効にできました。

```bash
#!/bin/sh
if [ "default started" = "$1 $2" ]; then
    resolvectl mdns virbr0 yes
fi
```

最初は
`[ "default started" = "$1 $2" ] && resolvectl mdns virbr0 yes`
と書いていたら、
`/etc/libvirt/hooks/network default start begin -`
の段階で hook が失敗して、
`net-start` 自体も失敗して `virbr0` ができなかったので、
動作確認はしっかりしておいた方が良さそうです。

## まとめ

mDNS を有効にすることで DHCP で IP アドレスが変わっても `raspi.local` や `ubuntu-vm.local` のような名前でアクセスできるようになって便利になりました。

一時的に有効にするだけなら、毎回 `resolvectl mdns virbr0 yes` のようなコマンドを実行しても良いのですが、
ちゃんと設定することで再起動後でも自動で有効にできるようになりました。
