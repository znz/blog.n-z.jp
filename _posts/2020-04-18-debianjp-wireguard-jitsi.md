---
layout: post
title: "オンライン開催：東京エリア・関西合同Debian勉強会でwireguardの話をしました"
date: 2020-04-18 23:50 +0900
comments: true
category: blog
tags: wireguard debian linux
---
[オンライン開催：東京エリア・関西合同Debian勉強会 (2020/4/18(土))](https://debianjp.connpass.com/event/172494/)
で wireguard を半年ぐらい使ってたまった知見の話をしました。
もうひとつの発表はこの勉強会自体でも使った jitsi の話でした。

<!--more-->

## オンライン開催

Debian 勉強会はオフラインの勉強会が東京エリアと関西で長く続いているのですが、
最近の CIVID-19 による状況で先月から東京エリアの方でオンライン開催を試していて、
先月試した中で OSS で、自分達で用意したサーバー上でもある程度の人数ならいけそうだった
GCP 上の jitsi で今回は開催されました。

環境によっては音声に問題がおきたり、画面共有が見えなかったり、止まっていたりするなどの問題があったようで、
サーバーとクライアントの両方にそれなりのマシンスペックと帯域が必要そうでした。

個人的には macOS の Chrome で問題なく繋っていました。

## Wireguard 実践入門

{% include slides.html author="znz" slide="use-wireguard" title="Wireguard 実践入門" slideshare="znzjp/wireguard" speakerdeck="znz/wireguard-shi-jian-ru-men" github="znz/use-wireguard" %}

[LILO&amp;東海道らぐオフラインミーティング 2019/08/10]({% post_url 2019-08-10-lilo-tokaidolug %})
で話したときのものをベースにして、設定例を整理しなおしたり、
Linux 5.6 に WireGuard のカーネルモジュールが入った影響で wireguard-dkms の処理が変わっていたのを対処した話を入れたり、
設定途中のうまく繋らない状態を失敗例としていくつかあげてみたりしました。

## Jitsiを使ったビデオ会議サーバの作り方

jitsi (ジッチー) を自前サーバーで動かす方法の概要や前回や今回の CPU 負荷や通信量などの話がありました。

## 感想

最近はオンラインイベントだけになっていますが、
やはり既にいろいろな環境で使われている zoom や YouTube Live (これは双方向ではないけれど) などの方が通信は安定していると感じました。
