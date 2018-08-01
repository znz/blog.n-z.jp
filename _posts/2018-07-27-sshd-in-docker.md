---
layout: post
title: "X11クライアント用のsshd専用コンテナをdockerで動かした"
date: 2018-07-27 22:54 +0900
comments: true
category: blog
tags: linux docker ssh
---
X11クライアントを Docker コンテナの中で動かして、
リモートから使いたいと思ったので、
X11Forwarding の準備をした上で、
コマンドとして sshd を指定したコンテナを作りました。

<!--more-->

## 検証環境

- Docker Community Edition : 18.06.0-ce-mac70 (26399)
  - Engine: 18.06.0-ce
  - Compose 1.22.0

## 参考

[Dockerize an SSH service](https://docs.docker.com/engine/examples/running_ssh_service/)
の Dockerfile を参考にしました。

リンク先の内容が変わった時のために参考にした Dockerfile を引用しておくと、内容は以下の通り。

```docker
FROM ubuntu:16.04

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
```

## 変更した Dockerfile

最終的には以下のようになりました。
`FROM ubuntu:18.04` でも動作することを確認しています。

`authorized_keys` をコピーして公開鍵認証を使うようにすれば、
`chpasswd` と `PermitRootLogin` の変更は不要です。

```docker
FROM ubuntu:16.04

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/#\?PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN apt-get install -y xauth
RUN echo AddressFamily inet >> /etc/ssh/sshd_config
#COPY authorized_keys /root/.ssh/authorized_keys

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
```

## 動作確認手順

参考にした先では `docker port` の出力で `ssh -p` の引数を決めていましたが、
テスト中に何度も build し直していると変わりまくって不便だったので、
シェルの履歴で再利用できるように変更しました。

```console
$ docker build -t eg_sshd .
$ docker run -d -P --name test_sshd eg_sshd
$ docker port test_sshd 22
$ ssh -X -p $(docker port test_sshd 22|sed 's/.*://') root@localhost
```

パスワードは `chpasswd` で設定している `screencast` です。

## 後始末

これは参考にしたサイトそのままです。

```console
$ docker container stop test_sshd
$ docker container rm test_sshd
$ docker image rm eg_sshd
```

## 変更点などの説明

以下は変更した点などの説明です。

## ubuntu:18.04 対応

`PermitRootLogin` の行は 16.04 だとコメントアウトされていなくて、
18.04 だとコメントアウトされていたので両対応するために `#\?` にしています。

`AddressFamily inet`

## xauth

デスクトップ環境の入っていないサーバーで X11Forwarding が失敗する原因でよくある xauth の問題に対処するために xauth を入れておきます。

手元側が macOS なら `brew cask install xquartz` などで XQuartz を入れておき、
`~/.ssh/config` に `XAuthLocation /opt/X11/bin/xauth` を設定しておきます。

## ssh 設定

`~/.ssh/config` に `NoHostAuthenticationForLocalhost yes` も設定しておくと手元の Docker で試すときにホスト鍵の確認がなくなって便利です。

## デバッグ

xauth を入れても
`X11 forwarding request failed on channel 1`
で繋がらなかったので、
`CMD ["/usr/sbin/sshd", "-D", "-ddd"]`
にして
`docker logs test_sshd`
を確認したところ、

```
debug2: bind port 6503: Cannot assign requested address
debug3: sock_set_v6only: set socket 7 IPV6_V6ONLY
debug2: bind port 6504: Cannot assign requested address
debug3: sock_set_v6only: set socket 7 IPV6_V6ONLY
debug2: bind port 6505: Cannot assign requested address
```

のようなログが大量に出ていたので、
`AddressFamily inet`
を設定して解決しました。

今回の件に限らず docker は IPv6 対応が弱いのが辛いところです。

## 確認用ソフト

x11-apps を入れて xeyes で試すのをよくやっています。
xterm を入れて試すのも良さそうです。

## docker-compose.yml の例

以下のような `docker-compose.yml` を用意しておけば
`docker-compose build` して `docker-compose up -d` して
`ssh -X -p 2222 root@localhost` で入れるようになって、
image の入れ替えも `docker-compose build` して `docker-compose up -d` するだけなので、
用途によってはこちらの方が便利かもしれません。

```yaml
version: '2.3'
services:
  x11-example:
    build: .
    ports:
    - "2222:22"
```

docker-compose を使った場合の clean up は `docker-compose down -v --rmi local` のようです。

## まとめ

X クライアントを docker の中で動かす準備ができました。
docker コマンドそのままだと build し直て stop して rm して start し直したりするのが面倒なので、
docker-compose と組み合わせる方が良いかもしれません。
