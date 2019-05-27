---
layout: post
title: "Docker Meetup Kansai #3 に参加しました"
date: 2019-05-24 23:59 +0900
comments: true
category: blog
tags: event docker
---
[Docker Meetup Kansai #3](https://dockerkansai.connpass.com/event/129089/) に参加したので、そのメモです。

<!--more-->

## DockerCon 2019振り返りとまとめ(仮)

- <https://www.docker.com/dockercon/2019-videos/>
- <https://www.slideshare.net/docker/>

## Dockerfile Best Practices DCSF19 を読み込む

- <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>
- `export DOCKER_BUILDKIT=1`
- `COPY` を後に
- `COPY` するのは `.` ではなく対象を狭く
- `apt-get update` と `apt-get install` を同じ `RUN` で
- 不要な依存関係を削除 `--no-install-recommends`
- `rm -rf /var/lib/apt/lists/*`
- できるだけ公式イメージを使う
- latest ではなくタグを指定する
- 必要最小限のものを探す (`openjdk:8` と `openjdk:8-jre-alpine` で 540 MB 違う)

- jar を `COPY` するのではなくビルドも Dockerfile で
- マルチステージビルド
- `FROM` が多い例: <https://github.com/moby/moby/blob/master/Dockerfile>
- `docker build --target stage_name` で特定のステージだけも可能
- `FROM` でも `openjdk:8-jre-$flavor AS release` のように `ARG` を使える
- Dockerfile を分けて実現していたようなことが 1 ファイルでできる
- 並列性や速度も BuildKit の利点

- experimental syntax
- シークレット ARG は docker history に残るのでダメ
- ssh key の COPY もダメ
- そういう時に代わりに使える機能が experimental syntax にある

- [BuildKitによる高速でセキュアなイメージビルド](https://www.slideshare.net/AkihiroSuda/buildkit)

## jupyterhub の dockerspawner の紹介

- <https://github.com/jupyterhub/dockerspawner>
- <https://www.hashicorp.com/blog/using-hashicorp-nomad-to-schedule-gpu-workloads>
- <https://zero-to-jupyterhub.readthedocs.io/en/latest/>
- <https://github.com/kubeflow/kubeflow/tree/master/components/jupyterhub>

## AB test with Docker

- <https://rails-follow-up-osaka.doorkeeper.jp/>
- <https://web-developers-meetup.doorkeeper.jp/>
- コンテナ 2 つ使う
- リロードで変わると困る → ALB の sticky session
- 複数画面同時に A/B すると確率が変わる → ディレクトリごとに ALB の target group 設定
- `/images` のような別ディレクトリがうまくいかなかった → S3
- <https://speakerdeck.com/chimame/b-test-with-docker>

## オンプレ✕社内Docker Registry✕Docker Buildに関する何か

- <https://github.com/SUSE/Portus>

## さくらインターネットからのおしらせ

- 日本 MSP 協会
- さくらインターネットの紹介

## 懇親会

## Docker開発環境のMac対応に苦戦した話

- Magento
- <https://docs.docker.com/docker-for-mac/osxfs-caching/>
- volume : cached や delegated を使うとはやくなる
- `/etc/localtime` がマウントできない → 環境変数
- コンテナにアクセスできない, 特に MySQL のダンプなどで困った
- <https://docs.google.com/presentation/d/1Gi2fQSw2ceyv9qYw1XXm1B_wy_sOGJIFjeMtSdEqBOA/edit#slide=id.p>

## (タイトル見逃し)

- 初心者向けの Docker 本の読書会をやっている話

## コンテナとオーケストレーションと、営業と

- 営業がなぜ新しい技術を勉強するのか?
