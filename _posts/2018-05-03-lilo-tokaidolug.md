---
layout: post
title: "LILO&東海道らぐオフラインミーティング 2018/5/3 に参加しました"
date: 2018-05-03 21:30 +0900
comments: true
category: blog
tags: lilo event linux
---
[LILO&amp;東海道らぐオフラインミーティング 2018/05/03](https://lilo.connpass.com/event/85392/) に参加しました。

今回もアンカンファレンス形式でした。

<!--more-->

以下、メモです。

## メモ

- 登録参加者数 18名でした。
- 人数で割ると50円ぐらいになって細かすぎるのと、今までのお金が残っているということもあって、参加費無料でした。
- 懇親会参加者は12名でした。

## オープニングや自己紹介など

- 来週末の[LibreOffice Kaigi 2018](https://libojapan.connpass.com/event/81750/)の申し込みがまだ少ないらしい。

<!-- -13:25 -->

## IOTハウス

- ラズパイなどで色々やっている話
- USB GPIO MM-CP2112
- リセッタブルヒューズ
- fritzing で回路図
- ドップラセンサー
- IRKit

<!-- -13:40 -->

## Linux 初心者な私の最近の困りごと2つ

- 普段は Mac ユーザー
- バイオ系研究で Ubuntu を使っている
- ゲーミングPC、Anaconda を使って環境構築している
- アプリのトラブルは情報が多いが、ハードウェアやOS周りは情報が少ない
- 困りごと1
  - SSD が容量不足で新しい SSD に引っ越ししたい
  - 安全でベストな方法は?
  - 今までの環境はそのまま引き継ぎたい
  - win10 は削除したい
  - Mac なら Time Machine で簡単なのに
- 困りごと2
  - Lenovo Y520 に Ubuntu 16.04 をインストールしたい
  - GPU そのまま使える?
  - 冷却ファンはそのまま使える?
  - 仮想マシンで事前にテスト可能?
  - win10 は消したい
- 困りごと1 について話し合い
  - 外付けして home だけそっちにする?
  - Clonezilla でコピー?
- 困りごと2 について話し合い
  - thinkfan というのがある
  - ライブ USB で試すのが良さそう

<!-- -14:01 -->

## Wayland 環境で WebBrowser を動かしてみた

- PC では X11
- 評価ボードでは wayland
- Wayland 自体はプロトコルで X.org と比較するものではなく、Xプロトコルと比較するもの
- コンポジタ (Compositor) が X Server 相当
- コンポジタとしては Weston と Mutter がある
- Weston
  - 当初はサンプル扱いだったが、(他の実装がなかなか出てこなかったので) リファレンスに格上げされた
  - プラグインを組み合わせて使う
- R-Car という環境で試す話
- ベース環境構築
- ブラウザの選定 : Forefox or Chromium
- デモ展示の確認ができた Chromium を選定
- Yocto で meta-browser を使う設定をしてビルド
- Ubuntu 14.04 の gcc が古くてネイティブビルドのところでエラー
- chromium に --no-sandbox が必要
- EGLInitialize という対処が難しい部分でエラー
- デモで使われていた環境に合わせて仕切り直し
- 動いた
- 音声再生はまだおかしい

- 質疑応答
- 音声の再生の話
- Wayland は組み込みで全画面で使うようなものには向いているが、デスクトップ環境にはまだ向いていない。
- Ubuntu 17.10 は Mutter を使っていて GTK などのツールキットの出来次第だった。
- Wayland 環境は Matchbox という window manager に似ている?
- Wayland は GPU がないと実用にならない。

<!-- -14:26 -->

## 休憩

<!-- -14:35 -->

## Certificate Transparency

用意したスライドと[参考文献にあげたPDF](http://www.jnsa.org/seminar/pki-day/2016/data/1-2_oosumi.pdf)の一部を見せながら、概要などの話をしたり、
[ウェブ上での HTTPS 暗号化 – Google 透明性レポート](https://transparencyreport.google.com/https/certificates?hl=ja)や[crt.sh \| Certificate Search](https://crt.sh/) で検索してみながら話をしたり、
GitHub Pages のカスタムドメインで証明書が発行されていたのを見つけた話などをしました。

- 会場からの情報
  - [RFC 6962](https://tools.ietf.org/html/rfc6962) は Experimental
  - [Certificate Transparency Version 2.0](https://datatracker.ietf.org/doc/draft-ietf-trans-rfc6962-bis/)
- あとで技術書典関連のツイートを検索してみたらみつけた[@s01さん](https://twitter.com/s01/status/988263688049115136)の[GitHub Pages のカスタムドメインについてのツイート](https://twitter.com/s01/status/991539349245194241)で今は正式対応しているのを知ったので、調べてみると[2018-05-01から正式対応](https://blog.github.com/2018-05-01-github-pages-custom-domains-https/)していました。

{% include slides.html author="znz" slide="lilo-20180503" title="Certificate Transparency" slideshare="znzjp/certificate-transparency" speakerdeck="znz/certificate-transparency" github="znz/lilo-20180503" %}

 話をしている時には、結局わからなかったのですが、
<https://lilo.linux.or.jp/> の SCT がブラウザーでみると Cloudflare 'Nimbus2018' Log と Google 'Icarus' log なのに、
[Google 透明性レポートでみると](https://transparencyreport.google.com/https/certificates/34sV%2FpfQDyApTrx1VQF992vP575qE%2FCkW1crX2iW7qw%3D)、
`google_argon2018`, `google_pilot`, `google_rocketeer` で一致しないのが謎でした。

今ブログ記事を書いているタイミングで crt.sh の方でよくみてみると <https://crt.sh/?id=404271966> は 2018-04-18  03:36:39 UTC に

- https://ct.cloudflare.com/logs/nimbus2018
- https://ct.googleapis.com/logs/argon2018
- https://ct.googleapis.com/icarus

で Pre-certificate に対するもので、 <https://crt.sh/?id=408046645> は

- 2018-04-18  10:00:29 UTC https://ct.googleapis.com/logs/argon2018
- 2018-04-20  01:59:29 UTC https://ct.googleapis.com/pilot
- 2018-04-20  06:11:16 UTC https://ct.googleapis.com/rocketeer

で発行された証明書に対するもののようでした。
そして、 Google 透明性レポートは後者のものだけ出ていたようです。

<!-- -15:12 -->

## LibreOffice Kaigi 2018 の紹介

- [LibreOffice Kaigi 2018](https://libojapan.connpass.com/event/81750/)
- 午前中はハンズオン
- 午後のセッションの概要紹介
- アナウンス場所の話
- 次回の LILO の日程調整
  - 8/11 は OSM のイベントがある
  - 18,19になる可能性あり

<!-- -15:32 -->

## 初めての Linux 暇つぶし環境構築 2018

- イベントの話とか
- 初心者向けゲーム環境
- OSS Gaming on Linux : ディストリのパッケージにあるもの
- Web Gaming on Linux : Flash とか
- Windows Game on Wine : それなりに動く
  - 64ビットだとうまく動かないことがあるので、32bit版の方がオススメ
- Windows Steam on Wine : Wine32bit版+.NET Framework 4+Steam でたくさんのゲームが動くらしい
- Windows 版 LINE on Wine : Wine32bit版3.0以降(?)で動くらしい
- GOG.com Game and Antimicro : GOG.com で Linux ゲームを購入、キーボードエミュレーション Antimicro
- Android-x86 on Linux : Anbox, エミュレータ, Android-x86
- Emulation on Linux : 各種エミュレータが動作
- Exagear Desktop on ARM Android : ARM でもラズパイでも
- DOSBox-X on Linux : PC-98 サポート, Windows 9x も
- 動画ストリーム on Linux : Netflix, Google Play, Amazon 動画, DMM など
- AbemaTV on Linux : 普通にみれます
- プロジェクターで天井にうつすと大画面
- libdvdread4 on Linux
- BD は市販ソフト
- 電子書籍 on Linux : Kindle は Wine かブラウザーで、Google Play は普通に、楽天とかは Android のみ
- データマイニングなど
- 質疑応答
- DOSBox-X は実機なしで使える
- Wine はゲーム用途が多くなっている

<!-- -15:53 -->

## 休憩

<!-- -16:05 -->

## 雑誌の話

- スライドなどなしで WEB+DB PRESS を持って話だけ
- 技術系雑誌買ってますか?
- WEB+DB PRESS とか Software Design はおすすめ
- 読者投稿はかなり高い確率で載るらしい<!-- 1/2 ぐらいの確率で4回載ったらしい -->

<!-- -16:11 -->

## Discord インフラ勉強会への誘い

- オンラインのみの交流会＆勉強会
- 運営システムは Discord で VoIP も Linux でちゃんと使えている
- 開催頻度 : 本当に毎日やっている
- <https://discordapp.com/invite/yfhPSNz>
- VC =　Voice Chat
- WebRTC なのでどのプラットフォームでもいけるはず

<!-- -16:19 -->

## 技術書典に行ってきた話

- コミケの技術書のみを取り出したようなイベント
- 写真紹介
- 実際に買ってきた本を出してみんなで手にとってみていた。
- 時間に余裕をみて片付けをして撤収
