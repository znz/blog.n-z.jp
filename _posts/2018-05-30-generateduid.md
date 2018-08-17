---
layout: post
title: "謎のUUID(GeneratedUID)を調査した"
date: 2018-05-30 13:55 +0900
comments: true
category: blog
tags: osx
---
wireshark のインストール中に出てきた FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000000 について気になったので、
調べてみました。

<!--more-->

## 環境

- macOS High Sierra 10.13.4

## 結論

結論から書いておくと root アカウントに対応する GeneratedUID でした。

```console
$ dscl . -list /Users GeneratedUID | grep AAAA | tail
_uucp                   FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000004
_warmd                  FFFFEEEE-DDDD-CCCC-BBBB-AAAA000000E0
_webauthserver          FFFFEEEE-DDDD-CCCC-BBBB-AAAA000000DD
_windowserver           FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000058
_www                    FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000046
_wwwproxy               FFFFEEEE-DDDD-CCCC-BBBB-AAAA000000FC
_xserverdocs            FFFFEEEE-DDDD-CCCC-BBBB-AAAA000000FB
daemon                  FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000001
nobody                  FFFFEEEE-DDDD-CCCC-BBBB-AAAAFFFFFFFE
root                    FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000000
```

## GeneratedUID と普通の uid の対応

GeneratedUID と UniqueID を並べてみて比較してみました。

nobody の -2 が FFFFFFFE になってしまいましたが、
hex にしてみると FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000000 + uid になるようです。

```console
$ join =(dscl . -list /Users GeneratedUID) =(dscl . -list /Users UniqueID | awk '$2=sprintf("%02X",$2)') | column -t | grep AAAA | tail
_uucp                  FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000004  04
_warmd                 FFFFEEEE-DDDD-CCCC-BBBB-AAAA000000E0  E0
_webauthserver         FFFFEEEE-DDDD-CCCC-BBBB-AAAA000000DD  DD
_windowserver          FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000058  58
_www                   FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000046  46
_wwwproxy              FFFFEEEE-DDDD-CCCC-BBBB-AAAA000000FC  FC
_xserverdocs           FFFFEEEE-DDDD-CCCC-BBBB-AAAA000000FB  FB
daemon                 FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000001  01
nobody                 FFFFEEEE-DDDD-CCCC-BBBB-AAAAFFFFFFFE  FFFFFFFE
root                   FFFFEEEE-DDDD-CCCC-BBBB-AAAA00000000  00
```

## UUID との比較

[UUID - Wikipedia](https://ja.wikipedia.org/wiki/UUID)
によると B はバリアントの 1 0 の「RFC4122で規格化されたバリアント」になりそうなのにバージョンが「C」で変です。

## GUIDパーティションテーブル

他に変な UUID は何があるかと思って、
[GUIDパーティションテーブル](https://ja.wikipedia.org/wiki/GUID%E3%83%91%E3%83%BC%E3%83%86%E3%82%A3%E3%82%B7%E3%83%A7%E3%83%B3%E3%83%86%E3%83%BC%E3%83%96%E3%83%AB)
をみてみると、
00000000-0000-0000-0000-000000000000 以外は bios\_grub 21686148-6449-6E6F-744E-656564454649 と Linux 予約済み 8DA63339-0007-60C0-C436-083AC8230908 が別バリアントでした。
