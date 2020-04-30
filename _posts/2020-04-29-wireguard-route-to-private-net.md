---
layout: post
title: "wireguardでLANの中へのルーティングを設定する"
date: 2020-04-29 23:50 +0900
comments: true
category: blog
tags: wireguard debian linux
---
OpenVPN のサーバーを止めて WireGuard に完全に移行しようとしたところ、
WireGuard でつないでいるホストから家の LAN の中へのルーティングの設定をまだしていなかったことに気づいたので、
設定を追加しました。

<!--more-->

## 動作確認環境

- 外側ホスト Ubuntu 18.04.4 LTS
- VPN から LAN 内へのルーターとなるホスト Raspbian GNU/Linux 10 (buster)

## ネットワーク構成

- 物理: 外側ホスト -(インターネット)- 家庭用ルーター -(LAN)- Raspbian
- 論理: 外側ホスト -(wireguard 10.192.122.0/24)- Raspbian -(LAN 192.168.0.0/24)- LAN内の他のノード

## 外部ホスト側

LAN 内部に通信したい外部ホスト側では Peer ルーターとなるホストの Peer の AllowedIPs に LAN のサブネット (この例では `192.168.0.0/24`) を追加します。

```
[Interface]
Address = 10.192.122.1/32
ListenPort = 51820
PostUp = wg set %i private-key <(cat /etc/wireguard/privatekey.wg0)

[Peer]
PublicKey = xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=
AllowedIPs = 10.192.122.3/32
AllowedIPs = 192.168.0.0/24
```

## ルーターとなる LAN 内のホスト側

LAN の他のノードは wireguard のサブネットからのパケットが届いても、
そのままだと返事をデフォルトゲートウェイの方に送ってしまうので、
Raspbian で NAT します。

`sysctl` の設定は `/etc/sysctl.d/50-local.conf` を作成して、そちらで設定しても良いのですが、
設定をまとめるために `PostUp` に `sysctl net.ipv4.ip_forward=1` を入れています。
`sysctl net.ipv4.ip_forward=0` に戻す必要はないので、 `PostDown` の例を書いていますが、コメントアウトしています。

LAN 内の他のノードからは Raspbian との通信になるように NAT の設定をします。
`eth0` や `ens0` などの揺れをまとめるために out 側の指定は `e+` にしています。
Raspberry Pi は wlan0 もあるので、そちらも設定しています。

最初に中からつないでおかないと外からの接続ができないので、
適当に `ping` で接続開始するようにして、
`PersistentKeepAlive` で維持するようにしています。

```
[Interface]
Address = 10.192.122.3/32
ListenPort = 51820
PostUp = wg set %i private-key <(cat /etc/wireguard/privatekey.wg0)
PostUp = sysctl net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i %i -s 10.192.122.0/24 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -s 10.192.122.0/24 -o e+ -j MASQUERADE
PostUp = iptables -A FORWARD -i %i -s 10.192.122.0/24 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -s 10.192.122.0/24 -o wlan+ -j MASQUERADE
PostDown = iptables -A FORWARD -i %i -s 10.192.122.0/24 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -s 10.192.122.0/24 -o wlan+ -j MASQUERADE
PostDown = iptables -A FORWARD -i %i -s 10.192.122.0/24 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -s 10.192.122.0/24 -o e+ -j MASQUERADE
#PostDown = sysctl net.ipv4.ip_forward=0
PostUp = ping -c 1 10.192.122.1

[Peer]
PublicKey = TrMvSoP4jYQlY6RIzBgbssQqY3vxI2Pi+y71lOWWXX0=
Address = 10.192.122.1/32
Endpoint = peer1.example.com:51820
PersistentKeepAlive = 25
```

firewall での制限をしている場合は、
`ufw route allow from 10.192.122.0/24`
などでの許可も必要です。

## 動作確認

外側ホストから `ping 192.168.0.1` などが通るのを確認します。

## OpenVPN との違い

OpenVPN だとサーバー側の conf で

```
route 192.168.0.0 255.255.255.0
push "route 192.168.0.0 255.255.255.0"
```

と設定して、 LAN 側のノードの ccd で

```
iroute 192.168.0.0 255.255.255.0
```

と設定すれば OpenVPN に接続するノード全てから LAN 内への通信をルーティングできた
(LAN 側のノードで nat 設定は同じように必要だった)
のですが、
wireguard のこの設定方法だと、

- モバイルノード -(wireguard)- VPSのホスト -(wireguard)- LAN内のホスト

という接続で、モバイルノードの Peer が「VPSのホスト」だけだと、
そこの AllowedIPs に LAN のサブネットを追加しても LAN 内のホストに転送してくれないので
もうちょっと悩みそうです。

## その他 (tailscale)

最近は
[tailscale](https://tailscale.com/)
([tailscale/talescale](https://github.com/tailscale/tailscale))
という wireguard を使ったメッシュ型のネットワークをいい感じに管理してくれるサーバーがある (OSS で無料プランや有料のサーバーもある) ようなので、
用途によってはこちらを使うのも良いかもしれません。
