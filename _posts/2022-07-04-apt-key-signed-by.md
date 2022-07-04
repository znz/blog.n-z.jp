---
layout: post
title: "apt-keyの代わりにsigned-byを使うときの鍵の置き場所"
date: 2022-07-04 14:30 +0900
comments: true
category: blog
tags: linux ubuntu debian
---
Docker イメージの中で Google Chrome を使いたいと思って、 apt でインストールするのに apt-line にちゃんと今風の signed-by を使いたいと思って調べていると間違った使い方が広まっていて、
最初に試した方法で signed-by を使うときに期待する安全性が得られていなかったので、正しいと思う方法をまとめました。

<!--more-->

## 動作確認環境

- Ubuntu 22.04 LTS (jammy)

## 間違った方法

signed-by で私が期待する安全性が得られないという意味で間違った例として <https://code.visualstudio.com/docs/setup/linux> のインストール手順にある以下の方法があります。

```
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
```

## 正しい方法

ダウンロードに使うのは wget でも curl でも何でも良いですが、ちゃんと signed-by で私が期待する効果を得られる方法は以下の手順になります。

```
sudo apt-get install wget
sudo mkdir -p /etc/apt/keyrings
sudo wget -q https://packages.microsoft.com/keys/microsoft.asc -O /etc/apt/keyrings/microsoft.asc
sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.asc] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
```

## 変更点

ポイントは以下です。

### trusted.gpg.d は使わない

`/etc/apt/trusted.gpg.d/` は apt-key add と同じように他の apt-line でも有効になってしまうので望ましくないです。
私はこれが起きないのを signed-by を使う方法に期待しています。

`/etc/apt/trusted.gpg.d` に鍵を置いた状態で `signed-by` を消してみて、 `apt update` でエラーにならなくて、
`/etc/apt/trusted.gpg.d` から鍵を消せばエラーになるので、 `signed-by` に関係なく鍵が使われることが確認できます。

### /etc/apt/keyrings を使う

[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)では `/etc/apt/keyrings` を使っていたので、そこを使うようにしました。

パッケージでインストールされる鍵は `/usr/share/keyrings` に入るので、
システム管理者が入れる鍵ということで `/usr/local/share/keyrings` に置いても良いかもしれません。

### (archを絞る)

apt-key の話とは関係ないですが、これも Docker Engine のインストールに合わせて、
`arch=amd64,arm64,armhf`
から
`arch=$(dpkg --print-architecture)`
に変更しました。

別 arch の Packages の無駄なダウンロードを省略できます。

### .asc のまま使う

`.asc` (ascii armor と呼ばれるテキスト形式) のままにすれば `.gpg` (バイナリ形式) に変換するための `gpg` をインストールしなくても良いです。

`/etc/apt/trusted.gpg.d/` に置く方法でも `signed-by` で指定する方法でも拡張子を `.asc` にしておけば中身は ascii armor 形式のままで使えます。

Docker image の生成は不要なパッケージのインストールは減らしたいです。
ダウンロードに使うコマンドも他で `curl` を使っているなら `curl` でダウンロードすれば良いと思います。

### `signed-by=` のパス

鍵の置き場所を変更したので、 `signed-by=` はちゃんと変更した場所を指定する必要があります。

## Docker で Google Chrome のインストール

元々 [google chrome をコマンドラインでインストールする](https://qiita.com/m-tmatma/items/10a02d60ae7b2cc6f32b) を参考にしてインストールしようとしていたところ、
今回の問題をみつけて、最終的には以下のような Dockerfile になりました。

```
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get install -y curl
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub -o /etc/apt/keyrings/google.asc
RUN echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/google.asc] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list
RUN apt-get update -y && apt-get install -y google-chrome-stable fonts-noto-cjk
RUN useradd user && install -o user -g user -d /home/user
```

これを `Dockerfile` として置いたディレクトリで以下のように動作確認しました。
一般ユーザー権限で headless chrome を使ってスクリーンショットを撮ったり、 DOM の表示をしてアクセスできていることを確認したりできました。

```
docker build -t chrome .
docker run --rm -it chrome
su - user -c 'google-chrome --no-sandbox --headless --disable-gpu --screenshot https://www.chromestatus.com/'
ls -l /home/user/screenshot.png
su - user -c 'google-chrome --no-sandbox --headless --dump-dom https://www.chromestatus.com/'
exit
docker rmi chrome
```

## 最後に

Google Chrome が公式サイトに apt でのインストール方法を書いていないので探すのに苦労しましたが、
Visual Studio Code on Linux のように公式のインストール手順に問題があることもあるようなので大変でした。

どちらも Linux のシステム管理に詳しい人がメインではなさそうなので、
そのあたりについては Docker Engine が信頼できそうで良かったです。

## 参考

- <https://code.visualstudio.com/docs/setup/linux>
- [非推奨となったapt-keyの代わりにsigned-byとgnupgを使う方法 - 2021-05-05 - ククログ](https://www.clear-code.com/blog/2021/5/5.html)
- [apt-key が非推奨になったので](https://zenn.dev/spiegel/articles/20220508-apt-key-is-deprecated) によると asc 対応は apt 1.4 かららしいが stretch (oldoldstable) で 1.4.11 なので、 `signed-by` に対応していて `.asc` に対応していない環境はないはず。
- [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- Deb822 ファイル形式を使うなら <https://wiki.debian.org/DebianRepository/UseThirdParty> を参考にしてください。
  Deb822 形式って何? と思う人には無関係なので、気にしなくて大丈夫です。
