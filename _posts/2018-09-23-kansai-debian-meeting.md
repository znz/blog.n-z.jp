---
layout: post
title: "第 138 回関西 Debian 勉強会に参加しました"
date: 2018-09-23 13:30 +0900
comments: true
category: blog
tags: debian event
---
[第 138 回関西 Debian 勉強会](https://debianjp.connpass.com/event/101743/) に参加しました。

<!--more-->

以下、あまり取っていませんが、メモです。

## オープニングや自己紹介など

- <https://lists.debian.org/debian-devel-announce/2018/04/msg00006.html>
  - 2019-01-12 - Transition freeze
  - 2019-02-12 - Soft-freeze
  - 2019-03-12 - Full-freeze
- gnome 最小構成 + ibus-skk
- [銀鮒の里学校（ぎんぶなのさとがっこう）](http://www.funaan.org/ginbunaschool/)
- Debian + bluefish editor を使っている
- i3 を使っている人とか
- 手元は Windows で主にリモートで使っている人とか
- jvm とか
- emacs wnn tamago (野良ビルド) とか MATE + uim とか xfce + uim とか
- ubuntu ibus-mozc
- testing を macOS の VirtualBox にいれてみたらちらつく, 解像度の変更をしようとしたら選択肢が画面外, 標準でいれてみたら GNOME + wayland, 日本語入力できない (mac 上なので全角半角キーはないので、それが原因? → 違った。後述), 環境変数をみても日本語入力関係は見当たらない
- fictx-mozc

## 色々

- uim 問題
- <https://wiki.debian.org/ja/L10n/Japanese>
- [Status of GNOME 3.30 in Debian](https://people.debian.org/~fpeters/debian-gnome-3.30-status.html)
- [第 126 回関西 Debian 勉強会で喋りました - いくやの斬鉄日記](https://blog.goo.ne.jp/ikunya/e/e0f8703dcd9f2fccab500b4a23daa70f)
- less は euc-jp の locale で端末も less コマンドも使えば euc-jp のテキストを表示できる

その他色々とブレインストーミング的に話をしていました。

## 日本語入力

現時点での buster での状況です。

debian-testing-amd64-netinst.iso で日本語環境をほぼデフォルト (apt のミラーを変えたぐらい) でいれたら日本語入力できませんでしたが、
ibus-mozc をいれて gnome-control-center の Region & Language で入力ソースに「日本語 (Mozc)」を追加したら使えました。

使い方は Super+Space (は VirtualBox の外で取られるので Control+Space に変更) で「日本語」から「日本語 (Mozc)」に切り替えて、
そのあとは macOS の日本語入力と同じように「かな」で切り替えると日本語入力できたり「英数」で戻したりできました。
