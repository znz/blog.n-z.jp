---
layout: post
title: "一般ユーザー権限で入れるsshd専用コンテナをdockerで動かした"
date: 2018-07-31 23:55 +0900
comments: true
category: blog
tags: linux docker ssh
---
Docker コンテナの中で色々試すのに root 権限のままだと困ることもあるので、
一般ユーザー権限でログインできる sshd を起動したコンテナを作りました。

<!--more-->

## 検証環境

- Docker Community Edition : 18.06.0-ce-mac70 (26399)
  - Engine: 18.06.0-ce
  - Compose 1.22.0

## 最終的な Dockerfile

[前回]({% post_url 2018-07-27-sshd-in-docker %})は root 権限で入れるようにするために
`PermitRootLogin` や PAM の設定も変更していましたが、
一般ユーザー権限で入るので不要です。

X11 が不要なら xauth や AddressFamily も不要です。

ユーザー名は ubuntu にして、サンプルのパスワードは今回も screencast にしました。
一般的な ubuntu 環境に合わせて sudo も使えるようにしておきます。

シェルも bash を指定して、補完が使えるように bash-completion もいれておきます。

```docker
FROM ubuntu:18.04

RUN apt-get update && apt-get install -y openssh-server sudo bash-completion
RUN mkdir /run/sshd
RUN useradd -m -s /bin/bash ubuntu && gpasswd -a ubuntu sudo
RUN echo 'ubuntu:screencast' | chpasswd

# For X11Forwarding
RUN apt-get install -y xauth
RUN echo AddressFamily inet >> /etc/ssh/sshd_config

COPY --chown=ubuntu:ubuntu authorized_keys /home/ubuntu/.ssh/authorized_keys

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
```

## docker-compose.yml

以下の内容で docker-compose.yml を作成しておけば
Dockerfile の変更は `docker-compose build` と `docker-compose up -d` で、
docker-compose.yml の変更は `docker-compose up -d` で反映できました。

```yaml
version: '2.3'
services:
  x11-example:
    build: .
    ports:
    - "2222:22"
```

## 使ってみる

`ssh -X -p 2222 ubuntu@localhost` で入って `sudo apt install x11-apps` して `xeyes` などで動作確認できました。
