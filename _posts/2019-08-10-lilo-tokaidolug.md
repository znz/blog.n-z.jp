---
layout: post
title: "LILO&東海道らぐオフラインミーティング 2019/08/10 に参加しました"
date: 2019-08-10 23:59 +0900
comments: true
category: blog
tags: lilo event linux
---

[LILO&amp;東海道らぐオフラインミーティング 2019/08/10](https://lilo.connpass.com/event/141391/) に参加しました。

今回もいつも通りのアンカンファレンス形式でした。

<!--more-->

以下、メモです。

## メモ

- 参加者数はたぶん 14 名でした。

## オープニングや自己紹介など

## 原田さん

- AI の話
- 最近どんなことをしているかとか
- ScanMusic というソフトで楽譜認識とか
- VirtualBox とか
- 実機でも複数 HDD にインストールして色々試してたりとか
- Jupyter NoteBook も使っているとか

- 海に潜った時の動画から3秒ごとの写真をとる
- 魚がうつっている写真
- あぶくばっかりの写真
- 2,30分学習させる
- 画像の自動分類
- 魚が3匹以上うつっている写真を抜き出すなど

- dlib で簡単な図形の中から円を学習させた

- PaintsChainer automatic colorization
- AutoDraw
- Google Colaboratory
- word2vec

- カメラの画像から輪郭抽出
- 顔のランドマーク認識
- Spyder

- Ubuntu 上の docker で jupyter notebook を使って CNN を勉強していた話は時間切れで省略

- 質疑応答
- 病気の画像診断はかなり進んできているらしい

## WireGuard を使ってみた

<https://github.com/znz/use-wireguard/blob/a35df9ad9a71ac451a4f043fff211811471a0975/use-wireguard.md>
を使って話しました。

都合により PDF などには変換していないので、元の markdown のままみてください。

## 休憩

## Linux Zaurus で Arch Linux

- 元 Intel の XScale をベースにした ARM v5te 世代
- mainline カーネルが対応している
- SD 1GB がないと最初に困る
- ext4 もデフォルトは対応していない
- CF のネットワークカード
- OESF 掲示板かいくつかのサイトでサポートされている
- バックアップしてから Kexecboot bootloader をインストール
- ext4 がチェックサムエラーになるので無効にする必要があった
- NetBSD は初期 OS から起動できるので簡単

## 小林さん

- Chromebook
- Play ストア
- VSCode
- Boostnote
- Node-RED
- ブラウザーで Google Drive や Google Docs など

- ウェアラブルデバイス
- maxim というメーカーが出している

- Google フォトで深センの話
- 窓に張り付いて掃除してくれる機械とか
- Nano Pi

- 質疑応答
- Node-RED で何をしている?
- 中小企業で Raspberry Pi 上で動かすなど
- Chromebook は deb パッケージをインストールできる (`boostnote_0.12.1_amd64.deb` など)

## IoT ハウス

- https://iot-house.jpn.org/
- BME680 Sensor
- 安く買える環境センサー
- IAQ を計算
- BME680 と Raspberry pi Zero で臭いセンサー <https://youtu.be/E2ePIIojxwU>

## 佐藤さん

- WordPress もげもげ
- www.k-of.jp のサイトが 2018 から WordPress ベースに
- 2018 はすでに静的サイトになっている
- ansible を使っている

## 休憩

- OPOLAR ハンディ扇風機

## OpenStreetMap / 3D

- まるいちさん
- 立体交差などがあるので、レイヤーがある
- 階など
- 3D 表示対応レンダラー
- OpenMapSurfer (限定的)
- F4map
- OSMBuildings
- 3D レンダリングの例
- OSC 広島が 2019/9/15

- 質疑応答
- データを作るのは大変
- 数秒おきに撮影できるカメラを使うとか
- 点字ブロックはサイズが決まっているのでそれを使って計算とか
- 屋内と屋外で点字ブロックの規格が違う
- 屋外は規格が決まっているらしい

## Linux の次世代デスクトップアプリ配布システムの比較

- ゆんたんさん
- <https://scrapbox.io/yuntan-t-blog/>
- Flatpak, Snap, AppImage
- TL;DR : Snap 最高
- Snap : Ubuntu が推進
- Flatpak : Gnome project が推進, Fedora に最初から入っている
- AppImage : インストールが不要
- 利用者視点ではなく開発者視点だとどうか
- 具体例として mikutter を 3 つ全てでパッケージングしてみた
- snap は既存の deb に依存できるのが楽
- github に push すると自動ビルド
- yuntan/mikutter-snap
- Snap アプリのメンテナはインストール数の統計情報を確認できる
- セキュリティ情報をメール通知してくれる
- Flatpak は依存も自分でビルドするように書く必要がある
- 自動ビルドがあるのは snap と同じ
- AppImage は Bash スクリプトを書く
- Docker で自動ビルドを構築する必要あり

- 質疑応答

今回の資料は [Linuxの次世代デスクトップアプリ配布システムの比較 - yuntan-t-blog](https://scrapbox.io/yuntan-t-blog/Linux%E3%81%AE%E6%AC%A1%E4%B8%96%E4%BB%A3%E3%83%87%E3%82%B9%E3%82%AF%E3%83%88%E3%83%83%E3%83%97%E3%82%A2%E3%83%97%E3%83%AA%E9%85%8D%E5%B8%83%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E3%81%AE%E6%AF%94%E8%BC%83)。

## クロージング

- 次回は今まで通りたぶん 1 月
