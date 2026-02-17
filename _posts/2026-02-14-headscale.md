---
layout: post
title: "headscale+tailscaleに移行中"
date: 2026-02-14 23:00 +0900
comments: true
category: blog
tags: headscale tailscale
---
[LILO&東海道らぐオフラインミーティング 2026-02-01](https://lilo.connpass.com/event/381726/)
で発表したのですが、
VPN 環境を Headscale + Tailscale に移行しました。

<!--more-->

## 動作確認環境

- Headscale 0.27.1 から 0.28.0

イベントでの発表時点では 0.27.1 でしたが、その後 0.28.0 に上げたら状況が変わっていました。

## 発表資料

{% include slides.html author="znz" slide="lilo-20260201" title="Headscale + Tailscale に移行中" slideshare="znzjp/headscale-tailscale-at-2026-02-01" speakerdeck="znz/headscale-plus-tailscale-niyi-xing-zhong" github="znz/lilo-20260201" %}

## ユーザーとタグの扱い

0.28.0 に上げると、タグを設定しているノードは `tagged-devices` ユーザーに移動してしまいました。

発表中には口頭でユーザーを移動できるので、所有ユーザーは適当に設定していたと話しましたが、
<https://github.com/juanfont/headscale/pull/2922> でユーザーを変える機能は消えていました。

すべてのノードに `user:sakura` なら `tag:sakura` などのようにユーザー名と同じタグもつけていたので、
ACL に大きな影響はありませんでした。

しかし、ユーザーの端末にはタグをつけないことを想定しているようで、
`tag:zabbix-agent` と併用できなくなってしまうので、
そのあたりの ACL 設定を含めてどう移行しようか、
まだ悩み中です。

## まとめ

LILO&東海道らぐのイベントで発表した内容とその後の状況を紹介しました。

影響がなければ発表内容をまとめなおして記事にする予定だったのですが、状況が変わっていたので、その部分の追加の話になってしまいました。
