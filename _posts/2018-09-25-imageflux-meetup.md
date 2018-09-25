---
layout: post
title: "ImageFlux meetup#2 に参加しました"
date: 2018-09-25 23:25 +0900
comments: true
category: blog
tags: event
---
[ImageFlux meetup#2](https://imageflux.tech/)の
[大阪会場](https://sakura.doorkeeper.jp/events/79331)に
参加しました。

<!--more-->

以下、メモです。
最初はメモを取らずに聞いている予定だったので、前半はほぼメモなしで、
最後の質問タイムはそれなりにメモを取っていました。

## メモ

- ImageFlux
- よく使いそうなサイズ変換などができる
- 必要に応じて変換できる
- WebP 対応

- 画像アップロード時にサムネイルなどを作っているとバリエーションを増やすのが大変だった
- 安定している

- signed url というのがある?
- こちらも S3 → ImageFlux → Akamai → クライアント だった
- ネットワークレイテンシ >> 画像の変換処理にかかるオーバーヘッド
- ネットワークリソース >> (超えられない壁) >> CPU リソース
- WebP は Android は OS で対応しているが iOS はアプリで対応が必要
- 詳細画像は高画質にしたいので調整

- ImageFlux Live Streaming
- 配信者 -WebRTC-> ImageFlux Live Streaming -HLS-> 視聴者
- 事例: pixiv Sketch LIVE
- WebRTC SFU Sora に WebRTC から RTP を取り出してもらう
- RTCP というのもあるらしい
- 音声が途切れる方が不快なので映像の方を合わせる
- バッファリング
- secure reliable transport でやっているようなことをやっている
- トランスコード : GPU の話
- HLS セグメント化

- 時報ちゃんでデモ

- 5 月にクローズした配信サービスをやっていた話
- 一台のサーバー → Wowza
- sass を検討
- 遅延が 5 秒以内は大変だった
- ImageFlux Live Streaming の話

- [WebRTC の優位性](https://gist.github.com/voluntas/0715fc2ea27a49c2afd2ae80624ba3d2)
- RTP over SRTP over DTLS over UDP が映像や音声をやり取りできるメディアチャネルです
- WebRTC 自体は大規模配信には向いていない
- RTP を取り出せる機能を後付けした
- P2P はビジネス的には難しいとか、大規模配信が難しいとか、コントロールが難しいのでサーバーを経由
- WebRTC の優位性は 2 点 : 全部入り, 超低遅延
- ImageFlux Live Streaming における WebRTC の優位性
- WebRTC SFU Sora の SDK がそのまま使える
- [OpenMomo プロジェクト](https://gist.github.com/voluntas/51c67d0d8ce7af9f24655cee4d7dd253)

## 懇親会タイム

もともと懇親会として確保されていたところは質問に答える時間になりました。

- twitter のハッシュタグの質問に回答
- signed url というものがあってすでに利用されている
- 認証なしで http でとれるものについては変換可能、著作権などは責任を持てないので注意
- CDN は akamai に限らないし、必須ではない
- 最初のアクセスは重いのか? → オリジン画像を取りに行くので多少重い
- mercari が ImageFlux を使っているか?
- オリジンサーバーが変更された場合は?
- キャッシュのパージのタイミングは? → cache-control ヘッダーに準拠

- ImageFlux Live Streaming のアルファ版は問い合わせフォームから、ベータ版はまだ未定
- 制限は? → 機材の準備の関係などもあるのでなんとも言えない, アルファ版は機能の検証のみ、ベータ版でそのあたりの検証もできる予定

- どういった利用者を想定している? → 1:多で配信を想定しているので、個別チャットだと強みを出せない
- 得意とする映像の種類はあるのか? → 一般的な PC で扱う動画と同じで、動きが激しいものは苦手など、普通の感じ

- ImageFlux スマホでいろんなバリエーションの画像を要求された時にキャッシュはどうなる? → パラメーターごとにキャッシュされる
- ImageMagick では脆弱性の対応が必要になるが、対応は必要なのか? → ImageMagick は使っていないが ImageFlux でも使っているライブラリは影響を受ける、サービス側で対応するので、ユーザーの対応は必要なし
