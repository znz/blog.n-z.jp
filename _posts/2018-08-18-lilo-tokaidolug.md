---
layout: post
title: "LILO&東海道らぐオフラインミーティング 2018/8/18 に参加しました"
date: 2018-08-18 23:59 +0900
comments: true
category: blog
tags: lilo event linux
---

[LILO&amp;東海道らぐオフラインミーティング 2018/08/18](https://lilo.connpass.com/event/95172/) に参加しました。

今回もいつも通りのアンカンファレンス形式でした。

<!--more-->

以下、メモです。

## メモ

- 参加者数11名でした。
- LILOの繰越金を減らすため、参加費無料でした。
- 懇親会参加者は9名でした。

## オープニングや自己紹介など

## xv6

- Unix v6 を教育用に作り直したもの
- OS 作成の参考書籍とか
- デモ
- <https://github.com/mit-pdos/xv6-public>
- `make` して `make qemu-nox` とか
- `make qemu-nox-gdb` して gdb から `target remote :26000`
- UEFI は <http://yuma.ohgami.jp/> とか
- ディスクイメージは 5MB ぐらい
- コマンドはほとんどない
- オリジナルの Unix v6 は古いC言語で書かれている話とか

## 病気自慢

- 尿路結石
- 胆のうポリープ
- いぼ痔 : ジオン注射
- 心臓疾患?
- 排尿障害、頻尿

派生して Fitbit の話とか

## 休憩

14:45まで

## 後からきた人の自己紹介

## FreeWnn にパッチが送られてきた、どうしよう

- Wnn, Canna, sj3
- <https://osdn.net/projects/freewnn/ticket/38482>
- reproducible builds 対応パッチ
- <https://build.opensuse.org/request/show/628477>
- boo 番号 = bugzilla opensuse org での番号
- ビルド時間を入れている
- ホスト名を入れている
- <https://reproducible-builds.org/>
- パッチを試すと辞書が読めなくなったので decline

暗号化している部分だけのパッチだったので、復号している部分も対処が必要らしい。

`st_ctime`, `st_dev`, `st_ino` を埋め込んでいるのを 0 にしているパッチだったので、
`mtime` にすればどうだろうと提案してみた。

## 私の Mastodon とか Twitter とかの運用

- [4pk さん](https://social.mikutter.hachune.net/@4pk)
- 読み方: ふぉーぷく, よんぴーけー, よんぷく, よんぺけなど
- 最近は ふぉーぷく と読まれることが多い
- スーパーサイエンスハイスクール = SSH
- mikutter(PC), Mastalab, iMast, Twitter(mobile)は公式
- mikutter のデモ
- Twitter と Mastodon が同じタイムラインに流れている
- Portal プラグインでアカウントごとの操作も自動で切り替えできる
- [通知](https://mikutter4pk.hatenablog.com/entry/2018/08/09/035903)

- [※PDF版※mikutterの薄い本 vol.14『レズと青い鳥』 - - BOOTH（同人誌通販・ダウンロード）](https://mikutter-book.booth.pm/items/967435)
- Twitter の user stream 廃止の話

## Language Update 2018 - Ruby

LL の時間調整兼発表の練習

## Debconf18, COSCUP 2018 x openSUSE.Asia GNOME.Asia に行ってきたよ

- 間に OSC 京都があったので2度台湾に行った
- 宿や食事などは Debconf 自体とまとめて予約できた
- DebCamp : 7/21-7/27
- OpenDay : 7/28: Debian に限らずいろいろな話
- Debconf : 7/29-8/5
- COSCUP : 台湾で最大のオープンソースイベント
- openSUSE.Asia : 年1回, 去年は東京で LibreOffice mini conf と併催
- GNOME.Asia : これも年1回
- あとは写真のみ
- 新幹線
- カンファレンスキットでかばんや箸やコップがあって会期中はそれを使うようになっていた

## クロージング

- 次回は1月?
- また合同でやるかも
- OSC 大阪の翌日にするかも
