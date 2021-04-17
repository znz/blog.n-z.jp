---
layout: post
title: "オンライン開催：東京エリア・関西合同Debian勉強会でsystemdの話をしました"
date: 2021-04-17 23:50 +0900
comments: true
category: blog
tags: systemd debian linux
---
[オンライン開催：東京エリア・関西合同Debian勉強会（2021/04/17(土))](https://debianjp.connpass.com/event/208924/)
で crontab の代わりに systemd-timer を使う、および user 権限での systemd の話をしました。
もうひとつは Debian パッケージの説明文の翻訳の話でした。

<!--more-->

## オンライン開催

先月と同じく[無料版での時間無制限が延長されていた Google Meet](https://www.itmedia.co.jp/news/articles/2104/01/news108.html)での開催でした。

14時よりちょっと早めに接続して画面共有を確認しようとしたら、 macOS のセキュリティとプライバシーでの画面収録を Google Chrome に許可していなかったので、
許可した後、一度 Google Chrome を起動しなおす必要がありました。
そのため、最初の説明をしている間に一度起動しなおしていました。

## systemd 再入門

以前の記事の
[cron(crontab)の代わりにsystemdのtimerを使う]({% post_url 2017-06-04-cron-systemd-timer %})
や
[ユーザー権限のsystemdにFailed to connect to busで繋がらない時の対処方法]({% post_url 2020-06-02-systemd-user-bus %})
などを参考にして、追加で調べた情報も加えて発表しました。

{% include slides.html author="znz" slide="debian-meeting-202104" title="systemd 再入門" slideshare="znzjp/systemd-246336275" speakerdeck="znz/systemd-zai-ru-men" github="znz/debian-meeting-202104" %}

## Debian パッケージの説明文を翻訳してみよう

パッケージの説明の翻訳のシステムが今はこういうのを使っているというのを知らなかったので、参考になりました。

## 感想

前回の勉強会後に[BoF: 2021年の活動への抱負](https://tokyodebian-team.pages.debian.net/2021-01_tokyodebian_bof.txt)をみていたときに、
systemd の話ならできそうだったので、発表しますと言ってから、早めに 1/3 ぐらいの資料を用意したのですが、そのまま前日になってしまって、
「当日のスケジュール」を確認すると 40 分の枠になっていたので、ゆっくり話しても 40 分には足りないぐらいの資料を用意しておいたら、
質疑応答の時間も含めると良いぐらいの時間になっていた気がします。
