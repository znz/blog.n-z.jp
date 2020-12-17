---
layout: post
title: "macOSのWireGuardが1.0.10で繋らなくなったので一時的な対処をした"
date: 2020-12-17 18:00 +0900
comments: true
category: blog
tags: wireguard macos
---
Mac App Store から入れている WireGuard が 1.0.10 にあがって、
「有効化に失敗」「トンネルオブジェクトにネットワーク設定を適用できません」
と出て繋がらなくなってしまって困っていたのですが、回避方法を発見して繋がるようになりました。

<!--more-->

## 確認環境

- macOS Catalina 10.15.7
- WireGuard 1.0.10

## 状況

接続しようとしてしばらくすると
「有効化に失敗」「トンネルオブジェクトにネットワーク設定を適用できません」
というダイアログがでて接続に失敗します。

ログをみると
「[NET] Starting tunnel failed with setTunnelNetworkSettings timing out」
と出ていました。

Mac App Store から入れているので、前のバージョンに戻すというのも難しい状況です。

## 調査結果

すでに報告がないかと思って Mac App Store をみても特になさそうだったので、
開発元の方をたどってみると、
[Kit: PacketTunnelSettingsGenerator: do not require DNS queries if no DNS](https://git.zx2c4.com/wireguard-apple/commit/?id=20bdf46792905de8862ae7641e50e0f9f99ec946)
で修正が入っていて、既に 1.0.11 のリリース中のようでした。

## 一時的な対処

コミットメッセージから DNS 設定がないのが問題だろうということで、
トンネル設定の
`[Interface]`
セクションに
`DNS = 192.168.0.1`
のようなローカルのルーターの DNS 設定を決め打ちで埋めてみると繋がることが確認できました。
決めうちだと他のネットワークに移動したときに繋がらなくなるので、
これは一時的な対処として、
WireGuard が修正済みのバージョンになったら削除予定です。

ずっと入れておくなら `DNS = 8.8.8.8` などの Public DNS を使うという手もありそうですが、
別の問題が起きることがあるので、ローカルのルーターの方を使っています。
