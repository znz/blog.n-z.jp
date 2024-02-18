---
layout: post
title: "LILO&東海道らぐオフラインミーティング 2024-01-28 に参加しました"
date: 2024-01-28 23:30 +0900
comments: true
category: blog
tags: lilo event linux
---
[LILO&amp;東海道らぐオフラインミーティング 2024-01-28](https://lilo.connpass.com/event/306590/) に参加しました。
久しぶりのオフライン開催で、東海道らぐのノウハウを使ったオンラインとのハイブリッド開催でした。

<!--more-->

## 感想

Linux に関連するいろいろな種類の発表があって楽しめました。

発表は中継用の機材が挟まってプロジェクターにつながっているからか、解像度を下げないとなぜかプロジェクターの色が変になっていて、その調整に手間取ってしまいました。
資料も 16:9 のつもりで作っていたので 4:3 で発表したら幅が想定より文字が小さくなっていたり、下がちょっと兎と亀のあたりに重なったりしました。
(オンライン発表のときはみえるだろうと思って重なるところまで意図的に詰め込んでいることもあったのですが、今回は入りきっている想定でした。)

## 会場

いつもの「プレラにしのみや」ではなく「西宮市大学交流センター」で、駅の反対側でしたが、駅の中のアクタ西宮の案内をみて迷わずに行けました。

## 発表資料

前日の土曜日に [Open Source Conference 2024 Osaka](https://event.ospn.jp/osc2024-osaka/) や [Kyoto.rb Meetup](https://kyotorb.connpass.com/event/307215/) があると思いつつ、
こういうタイミングじゃないとなかなか作業できないと思って、自宅で lilo.linux.or.jp の Debian のバージョンアップをして、その報告をしました。

前のバージョンアップのときにひっかかったことがあるところばかり気にして、リリースノートのバージョンアップ作業のところだけみていたら、その後ろの非互換部分の確認漏れで mailman が消えて mailman3 へのバージョンアップ作業が一番大変でした。

{% include slides.html author="znz" slide="lilo-20240128" title="lilo.linux.or.jpをbusterからbullseyeに上げた" slideshare="znzjp/lilolinuxorjp-buster-bullseye" speakerdeck="znz/lilo-dot-linux-dot-or-dot-jpwobusterkarabullseyenishang-geta" github="znz/lilo-20240128" %}
