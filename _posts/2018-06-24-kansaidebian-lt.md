---
layout: post
title: 第136回関西Debian勉強会 + Linux Kernel 勉強会 LT大会に参加しました
date: 2018-06-24 22:26 +0900
comments: true
category: blog
tags: event debian linux
---
[第136回関西Debian勉強会 + Linux Kernel 勉強会 LT大会](https://debianjp.connpass.com/event/90376/)に参加しました。

<!--more-->

以下、メモです。
メモは控えめにして、しっかり聞いていました。
公開可能な資料は connpass のイベントページからリンクされるはず?

## オープニング

- [関西Debian勉強会](https://wiki.debian.org/KansaiDebianMeeting)の紹介
- [Linux Kernel勉強会](https://linux-kernel.connpass.com/)の紹介

## 自己紹介

- いつものように登録の逆順で自己紹介
- [ET West 2018（Embedded Technology West 2018）／IoT Technology West 2018 ［ET West・IoT West 総合技術展示会 関西］](http://www.jasa.or.jp/etwest/)

## 休憩

## あらためて mruby, mruby/c と Linux

- RubyKaigi で mruby/c を知った
- [mruby](https://github.com/mruby/mruby) は OS の上で動く
- [mruby/c](https://github.com/mrubyc/mrubyc) はハードウェアの上で直接動く
- HAL とか rrt0 とかがいい感じにしてくれるらしい

- Kernel/VM で EFI で mruby のバイトコードを動かす話があったらしい

## workqueue の実装を見てみた

- カーネル空間で走るユーザーコンテキストを持ったタスク
- 構造体の図を書くのが大変な話 (Draw でかいたらしい)
- [GPLv3](https://www.gnu.org/licenses/gpl-3.0.html) の話
- 「But this requirement does not apply if neither you nor any third party retains the ability to install modified object code on the User Product (for example, the work has been installed in ROM).」のあたり
- インストール手段がどういうものなのか要求されたら開示すればいいだけで、機能 (機材) をつけておく必要はないという感じ?
- 長期保守の話
- [2018年4月2日　最低でも20年 ―東芝らが取り組む"スーパーロングなカーネルサポート"プロジェクト：Linux Daily Topics｜gihyo.jp … 技術評論社](http://gihyo.jp/admin/clip/01/linux_dt/201804/02)

## 後から来た人の自己紹介

rabbit のサイズ調整に手間取ったので、その間に後から来た人の自己紹介をしてもらっていました。

## systemd でよく使うサブコマンド

ディスプレイの環境設定で解像度が 1280x800 だったので `rabbit -S 1280,800 systemd-subcommands.md` で表示してみたら、
下がちょっと切れていました。

{% include slides.html author="znz" slide="kansaidebian-lt-20180624" title="" slideshare="znzjp/systemd-102887739" speakerdeck="znz/systemddeyokushi-usabukomando" github="znz/kansaidebian-lt-20180624" %}

## 休憩

## RISC-V をさわってみた

- フリーでオープンなISA
- SoC 時代の RISC
- ツールチェインなどの upstream での対応も進んでいる
- Debian もポーティングが進んでいる
- <https://wiki.debian.org/RISC-V>
- qemu でデモ
- `uname -a` とか `cat /proc/cpuinfo` とか

## ターミナルで幸せに生きるために

- 日本語フォント
- Unicode が変 UAX#11, UTR#51
- 設定とかは <https://github.com/uwabami/locale-eaw-emoji> とかに公開している

フォント設定とかの話でした。

## Open Source Summit Japan 2018 に行ってきたよ

- (k-of.jp は 11/9-10)
- Linux Summit から名前が変わった
- 2018/6/20(水)-22(金) に開催されていた
- 写真でどんな感じだったのかの紹介でした

## クロージング

- 関西Debian勉強会の7月分は OSC 京都に振替の予定かと思いきや DebConf と重なるため申し込んでいないので次回は8月?
- Linux Kernel 勉強会は 7/14(土)
- OSC 京都は 8/3(金),4(土) KRP
- 関西Debian勉強会の8月は8月26日(日)
