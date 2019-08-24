---
layout: post
title: "Docker Meetup Kansai #4 (19.08) に参加しました"
date: 2019-08-23 23:59 +0900
comments: true
category: blog
tags: event docker
---
[Docker Meetup Kansai #4 (19.08)](https://dockerkansai.connpass.com/event/141875/)
に参加して [Dokku の紹介](https://slide.rabbit-shocker.org/authors/znz/dokku-201908/) の発表をしてきました。

<!--more-->

以下メモです。

資料は公開されるようなので、少なめです。

## 会場

いつものさくらインターネットさんでした。

## 『Docker CE 19.03 新機能解説+Dockerネットワーク解説』

- Docker CE 19.03.1
- 呼称変更 (18.09 から)
  - Community (`docker version` だと `Docker Engine - Community` と出ていた)
  - Enterprise
  - Docker Enterprise が別にあるのでわかりにくい (Engine の Enterprise などを含む)
- ランタイム、デーモン、コマンドラインのパッケージが分離 (18.09 から)
- Buildkit
- Rootless docker

- Rootless docker
- そのままだと外と通信できないなどの制限はある
- get.docker.com/rootless のシェルスクリプトでインストールできる

- Buildkit
- `export DOCKER_BUILDKIT=1`
- コンテキスト・マウント
  - COPY ./app の代わりにマウントできる
- キャッシュはホスト側で保持
- シークレット・マウント
  - docker build --secret id=check,src=$HOME/.data/credentials -t myimage .
- SSH マウント
  - ssh-agent をマウント
- [https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md](https://github.com/moby/buildkit/blob/763379fb2c521e5804e7ce713ca5a59a2007d81e/frontend/dockerfile/docs/experimental.md)

- Docker ネットワーク概要
- bridge (bridge)
  - Linux のブリッジで中から外
  - docker-proxy プロセスが外から中
  - bridge0 は旧仕様で共同が異なる
  - --link はもう使えない
- host (host)
  - ホストとネットワーク共通
- none (null)
  - 疎通しない

## 『ゆるいdocker-composeでプロダクション環境を運用したるでっ!』

- docker-compose.yml をちょっと変更して本番環境でも使う
- デメリットの対策
- ダウンタイム
  - CDN with cache で減らす
  - docker-compose pull してから docker-compose down
- 不安定になったときにバージョンを戻すのも簡単
- 運用例

## 『コンテナイメージの脆弱性スキャンについて』

- 前回は Portus について
- 今回は Clair のあたり
- 高かったり、導入が大変だったりする印象

- Trivy aquasecurity/trivy
- 最近話題になってた日本人が作った OSS が海外企業に買われたやつ
- インストールなども簡単

- チェック対象
- Dockerfile に記載した OS パッケージ
- Gemfile.lock など

- 情報源は vuln-list-update で公開情報から更新されている

- Gemfile.lock などのファイル名は決め打ち

- 使い方: trivy イメージ名

## 交流の時間・懇親会 (Networking)

- 懇親会ご支援：日本MSP協会さま https://mspj.jp/

## LT枠1『PackerでぱかっとDockerイメージをビルドする』

- nickname: ねずみさん家。
- 自称 SRE
- HashiCorp のツール好き
- Packer とは
- イメージをビルドして ECR に push までやってみる
- テンプレートは JSON
- variables, builders, provisioners, post-processors
- パスワードは環境変数経由
- builders で alpine イメージからビルドを指定
- provisioners は今回は ansible を使う
- post-processors で ECR に push
- 実行: packer build path/to/template.json
- CI/CD と親和性が高い

## LT枠2『受託開発の現場におけるdocker利用事例』

- 手元のローカル環境での利用事例
- 事例1: CMS、スクラッチ PHP
- 公式イメージ → CentOS ベースで案件に合わせたイメージ作成
- 事例2: Heroku + PHP (Laravel)
- Laradock

- チーム運用での気づき
  - プロジェクト中の保守時間を見込む
  - 管理範囲を決める
  - 起動は簡単にしておく

## LT枠3『Dokkuの紹介』

5 分枠でしたが、発表者が埋まっていなかったから、他の LT ももうちょっと長めでも大丈夫なようだったので、
ちょっと長めになってしまいました。

発表資料は基本的に公開しているイベントで発表することが多いので、公開してイベントページからもリンク済みというのを言い忘れていました。

最初に聞いてみたところ、すでに Dokku を知っていた人は 2,3 人ぐらいのようでした。

{% include slides.html author="znz" slide="dokku-201908" title="Dokku の紹介" slideshare="znzjp/dokku-165791253" speakerdeck="znz/dokku-falseshao-jie" github="znz/dokku-201908" %}

## 追加宣伝

- cndk2019
- CFP 募集中 8/31 まで
- bit.ly/cndk2019cfp

- Rancher JP
- Cloud Native JP
- Redmine 大阪
  - redmine-osaka.net は docker-compose で動いているらしい

## クロージング

- 協賛: 日本MSP協会
<!-- さくらインターネット おおすみまさゆきさん -->
- さくらインターネットを使っている主な会社一覧
- VoiceTra : ポケトークのような感じの無料アプリ
- sakura.io 体験ハンズオン
