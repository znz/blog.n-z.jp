---
layout: post
title: "Cybozu Meetup Osaka 大阪のエンジニアが好きそうな話に参加しました"
date: 2018-10-02 19:00 +0900
comments: true
category: blog
tags: event
---
台風の影響で延期になっていた
[Cybozu Meetup Osaka 大阪のエンジニアが好きそうな話](https://cybozu.connpass.com/event/102153/)
に参加しました。

<!--more-->

## 会場

梅田阪急ビルオフィスタワー自体初めて入りましたが、
グランフロント大阪と同じように途中でエレベーターを乗り換えするような場所でした。

## トークセッション

- 大阪-松山-東京-自宅をつなぐリモートスクラム開発 by 太田 絵一郎
- Salary negotiation battle Round2 on Cybozu（サイボウズの給与交渉戦 第2ラウンド）by 佐藤 鉄平, 三苫 亮

食事をしながら聞いていたので、メモは取っていませんでした。
発表資料は公開されるようです。

## 質疑応答

- 一番効果があったのは? → 転職ドラフトを使った年が一番上がった
- 満足していますか? → 週3日在宅できていて満足度は高い
- チームへの貢献度をどういう尺度ではかっているのか? →　チームのリーダーにきくとか、今抜けられると困るかとかの需給の話も
- 給与を決めるのは? → 開発本部長、部長、その他しか階層がないので、部長が決めて開発本部長が承認
- 転職ドラフトを活用して来たのは 100 人中 5 ~ 10 人ぐらい
- https://twitter.com/aoi_erimiya/status/1047078091342974983
- 多くの人はガツガツとはこない
- マネージャー自身の給与交渉は? → 部長に関しては同じ。本部長は社長とやる。
- 予算が先に決まっているわけではないので、予算が理由であげられないということはない
- 業績が伸びているので、今のところは人件費が問題にはなっていない

## LT

### 大阪っぽくおせっかいする話

- 頼まれてないのに、他社の Web をレビュー
- マークアップもちゃんとしてる
- OSS のライセンスが minify してもちゃんと残ってる
- Google Lighthouse
- 細かい点は簡単に直せる
- 問題は速度
- rabify CDN というのを、この LT のためにリリースした

### GraphQL SQL

<!-- rito さん -->

- <https://speakerdeck.com/chimame/graphql-sql>
- GraphQL とは?
- API 用でかつ SQL っぽいもの
- サーバー側は各言語ごとにある
- SQL Library : RDBMS から NoSQL スキーマから GraphQL API を勝手に生やしてくれるもの
- PostGraphile : PostgreSQL 専用、認証は JWT
- HASURA GraphQL Engine : PostgreSQL 専用、 SaaS の一部を OSS に切り出し、認証は JWT 以外に Webhook 対応
- Prisma : 複数の RDBMS 対応、 GraphQL tutorial で紹介されていて一番勢いがある、認証は独自

- [Shinosaka.rb #31](https://shinosakarb.doorkeeper.jp/events/79932) の紹介
- Rails Follow-up Osaka の紹介

### エンジニアが好きそうな話

<!-- @QoopMk -->

- 泥酔していて間違えて登壇の方に申し込んだが、せっかくなので話をすることに
- リモートワーク × 食
- リモートワークで休憩が 2 時間ある
- 美味しいランチを食べにいける!
- いくつか店の紹介

### 大阪のローカルメディアに関わって良かったこと

- <https://bochi2.net/>
- 多言語対応のプラグインとか気軽に試せる
- Google Analytics の勉強にもなった
- ブログをやっていることが仕事に繋がったことも

### IT コミュニティ＠大阪

<!-- @mkkn_info -->

- 申し込むのが出遅れた
- イベントのサイトをよく作っている
- 地方でもコミュニティ活動しよう
- 人がたくさん集まるイベント ≠ いいイベント
- 関西フロントエンド UG
- 関西 PHP 勉強会
- [FRONTEND CONFERENCE 2018 - connpass](https://kfug.connpass.com/event/98855/)

## 懇親会

<!-- 40 分おし -->

## 感想

どんな感じの話があるのか、あまりわかっていないまま参加してみましたが、楽しめました。
