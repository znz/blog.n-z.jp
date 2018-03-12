---
layout: post
title: "Docker Meetup Kansai #1に参加した"
date: 2018-03-12 19:00 +0900
comments: true
category: blog
tags: event docker
---
[Docker Meetup Kansai #1](https://dockerkansai.connpass.com/event/80776/)
に参加しました。

<!--more-->

以下、メモです。

## Kubernetes対応等、20分で分かる最近のDockerについて

- 自己紹介
- [コンテナ・ベース・オーケストレーション Docker/Kubernetesで作るクラウド時代のシステム基盤](http://amzn.to/2FA30Nj)
- Cloud Native と Docker プロジェクトの現状
  - スマホの普及で常時使われるようになって、サービスの停止が厳しくなってきた
  - Cloud Native: Availablity, Automation, Acceleration, Anywhere
  - CNCF : Linux Foundation のコンテナ版 (ベンダー中立の調整役)
  - コンテナ化, 動的なオーケストレーション, マイクロサービス指向
  - kubernetes はクラスタ管理, containerd は1ホスト
  - Docker Engine の現行アーキテクチャ
  - Docker Swarm (standalone swarm) vs Docker Swarm mode (SwarmKit) : Swarm mode は 1.12 から
  - 宣言型サービス・モデルのオーケストレーション
  - Docker for Windows などで kubenetes もすぐに動く
- デモ
  - Windows 10 だと Hyper-V で動く
  - docker コマンドで deploy して kubenetes の方で確認したりしていた
  - swarm mode のクラスタは init で出てきたコマンドを他のホストで実行して join するだけで簡単に構築できる
- 発表資料: <https://www.slideshare.net/zembutsu/distributed-docker-swarm-orchestration>

{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4798155373&linkId=2a1ffa646ea05ee81d50e0b121b4cca4" %}

## LT枠1『AWS FargateでサーバーレスなDocker環境』

- 自己紹介
  - AWS のコンサルの会社の人
- Amazon Elastic Container Service
- ホストの有効活用: Auto Scale (状況に応じてホストの増減), Spot Fleet (スポットインスタンスの活用)
- AWS Fargate
  - 秒単位課金
  - ECS の機能がそのまま利用可能
  - [AWS Fargate Advent Calendar 2017](https://qiita.com/advent-calendar/2017/aws-fargate) がすぐに埋まった
  - [AWS FargateでサーバーレスZabbix](https://qiita.com/taishin/items/22abc5e23e71db13ca5a)
  - (1) デバッグがつらい
    - docker exec できない
    - アウトプットは CloudWatch Logs のみ
    - デバッグの対応策: ssh 用の side-car container をつくる (完了したら削除)
  - (2) 監視どうする?
    - CloudWatch のメトリックスに対応
	- Datadog のライブコンテナ モニタリングを使いたい
    - Datadog の ECS インテグレーションが使えるかどうかわからない
- 質疑応答
  - prometheus? → 今後期待 <https://twitter.com/wakaba260yen/status/973146632005992448>

## LT枠2『コンテナ管理OSS「Rancher」〜便利なDockerを更に使いやすく〜』

- イベント #1 祝
- 出席率も良いらしい
- 自己紹介
  - CloudStack のメンバーが立ち上げたのが Rancher
- Rancher とは?
  - コンテナ管理/運用ツール
  - [開発、リリース、運用のサイクルを回す――アメブロのフロントエンドにおけるモダンなDevOps環境作り (1/2)](http://www.atmarkit.co.jp/ait/articles/1704/13/news017.html)
  - インストール簡単 : docker コマンド1行
  - 無料
  - オペレーションかんたん
  - Rancher CLI
  - 拡張性ばっちり
  - Rancher 2.0 から kubenetes への移行が簡単
- <https://rancherjp.connpass.com/>
- <http://slack.rancher.jp/>
- ハンズオンを全国を回ってやる予定
  - [Docker ハンズオン (初心者向け) in 大阪 #01](https://docker.connpass.com/event/82080/) 大阪 4/6(金) 19:00-21:00
  - [Docker ハンズオン (初心者向け) in 京都 #01](https://docker.connpass.com/event/82078/) 京都 4/7(土) 10:00-12:30

## LT枠3『Dockerを使ったクライアントハイパーバイザー』

- デスクトップ用途で docker を使っている話
- パッケージの更新の手間を省きたい
- ホストは Ubuntu 16.04
- 特権コンテナで画面も出るし Chrome も動くし音も出る
- 探してみつかった例は VNC か X サーバーはホスト側でソケットを bind mount で X サーバーを docker の中で動かす例はみつからなかった
- 特権コンテナでデバイス (`/run/udev`) などを bind mount してマウスなども使えるようにした
- 色々使おうとすると `/run/dbus` や `/run/systemd` なども必要になった
- 開発環境を分離できるようになった
- docker hub でイメージビルドして docker pull すると最新にできるようになった
- GPU を使うアプリは画面がちらつくなど怪しい動きをすることがある
- `--shm-size` を指定して増やさないと Chrome がメモリ不足で死ぬ
- ホスト側の無停止アップグレードはできない (CoreOS などに期待?)
- このアーキテクチャに何かしっくりくる名前をつけたい

## LT枠4『UCPでスタックを管理してみよう』

- リモートで発表
  - 向こうは夜中らしい
- 自己紹介
  - Docker Inc の人
  - サンフランシスコから
  - Windows Container
- Docker EE について
  - Docker EE
  - Universal Control Plane "UCP" : クラスタ管理ツール
  - Docker Trusted Registry "DTR"
- なぜ UCP?
- 普段コマンドラインでやっていることが GUI でできる
- バンドルをダウンロードして手元で実行もできる
- 権限管理もできて、特定のチームに特定のノードだけ使わせるということもできる

## 日本と世界のDockerコミュニティ

- <https://www.slideshare.net/AkihiroSuda>
  - 発表資料: [日本と世界のDockerコミュニティ](https://www.slideshare.net/AkihiroSuda/docker-90377069)
- 自己紹介
  - Moby のコミッター
- 地域ミートアップ
  - 日本では 東京, 大阪 (NEW)
- [くじらやさん](https://docker.connpass.com/)が新しく増えた
- Docker Tokyo
- 写真紹介
- 関連コミュニティもたくさん
- [Japan Container Days](https://containerdays.jp/) スライドにのっているプロモーションコードで割引あり
- 世界にも関連コミュニティがたくさん
- DockerCon (Docker社主催カンファレンス)
  - 併催イベントもある
- Docker のコンポーネントの多数はオープン
  - 一部例外あり
- Docker : Moby ≒ RHEL : Fedora
- Moby の開発者はたくさんいる
- Moby の最近の動向
  - containerd 1.0
  - BuildKit で docker build が速くなる
  - 他のイメージビルダも出てきている
  - Docker Registry API の OCI 標準化
  - Dockerfile は標準化されていない

## 感想

それぞれの発表の時間が短かったのか、
深い話はなかったですが、
Docker 周りの最近の状況を知ることができてよかったです。
