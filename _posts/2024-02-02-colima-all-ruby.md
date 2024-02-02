---
layout: post
title: aarch64 の colima で all-ruby の i686-linux のバージョンも動かす
date: 2024-02-02 18:59 +0900
comments: true
category: blog
tags: ruby docker
---
Apple Silicon な macOS で colima を使って all-ruby を動かすと、
なぜか 1.6.8 以前が動いていなかったのですが、
`qemu-user-static` を入れたら動いた、という話です。

<!--more-->

## 動作確認環境

- Apple M1 Pro
- macOS Sonoma 14.3
- colima 0.6.7
- VM は aarch64 の Ubuntu 23.10 (mantic)

## VM 作成

クリーンな VM で再現実験をするため、通常の `colima start` の代わりに `profile` を指定して起動します。

```
%  colima start example
INFO[0000] starting colima [profile=example]
INFO[0000] runtime: docker
INFO[0001] creating and starting ...                     context=vm
INFO[0023] provisioning ...                              context=docker
INFO[0024] starting ...                                  context=docker
INFO[0025] done
```

`docker context` が混乱しないように通常の方は `colima stop` で止めてから作業しています。
動かしたまま作業するなら `docker context ls` などで確認します。

## 動作確認

`i686-linux` な 1.6.8 と `x86_64-linux` な 1.8.0 で動作確認すると、
1.8.0 は正常に動いていますが、
1.6.8 は謎のエラーになります。

```
% docker run --platform linux/amd64 --rm -it ghcr.io/ruby/all-ruby env ALL_RUBY_BINS='ruby-1.6.8 ruby-1.8.0' ./all-ruby -v
Unable to find image 'ghcr.io/ruby/all-ruby:latest' locally
latest: Pulling from ruby/all-ruby
004b32b1140b: Pull complete
253cedb3f24d: Pull complete
320af61238d7: Pull complete
c794b9fb941e: Pull complete
bd9ddc54bea9: Pull complete
Digest: sha256:423151ed73fa2240152eb536234be961bc011e41a6da98ae5fb3ac12e6a4dbf2
Status: Downloaded newer image for ghcr.io/ruby/all-ruby:latest
ruby-1.6.8 /all-ruby/bin/ruby-1.6.8: 1: /all-ruby/bin/ruby-1.6.8: Syntax error: "(" unexpected
	   exit 2
ruby-1.8.0 ruby 1.8.0 (2003-08-04) [x86_64-linux]
```

## ssh でインストール

`colima ssh` で入って、
必要に応じて `sudo apt update` して、
`qemu-user-static` をインストールします。

```
% colima ssh -p example -- sudo apt install qemu-user-static -y
WARN[0000] provisioning scripts should not reference the LIMA_CIDATA variables
WARN[0000] provisioning scripts should not reference the LIMA_CIDATA variables
WARN[0000] provisioning scripts should not reference the LIMA_CIDATA variables
WARN[0000] provisioning scripts should not reference the LIMA_CIDATA variables
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  qemu-user-static
0 upgraded, 1 newly installed, 0 to remove and 46 not upgraded.
Need to get 11.9 MB of archives.
After this operation, 117 MB of additional disk space will be used.
Get:1 http://ports.ubuntu.com/ubuntu-ports mantic-updates/universe arm64 qemu-user-static arm64 1:8.0.4+dfsg-1ubuntu3.23.10.2 [11.9 MB]
Fetched 11.9 MB in 4s (3372 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package qemu-user-static.
(Reading database ... 19083 files and directories currently installed.)
Preparing to unpack .../qemu-user-static_1%3a8.0.4+dfsg-1ubuntu3.23.10.2_arm64.deb ...
Unpacking qemu-user-static (1:8.0.4+dfsg-1ubuntu3.23.10.2) ...
Setting up qemu-user-static (1:8.0.4+dfsg-1ubuntu3.23.10.2) ...
Processing triggers for systemd (253.5-1ubuntu6) ...
```

## 動作確認

`docker run --platform linux/amd64 --rm -it ghcr.io/ruby/all-ruby ./all-ruby -v` などで `i686-linux` も動いているのが確認できます。

```
% docker run --platform linux/amd64 --rm -it ghcr.io/ruby/all-ruby env ALL_RUBY_BINS='ruby-1.6.8 ruby-1.8.0' ./all-ruby -v
ruby-1.6.8 ruby 1.6.8 (2002-12-24) [i686-linux]
ruby-1.8.0 ruby 1.8.0 (2003-08-04) [x86_64-linux]
```

## 削除

確認に使った VM を削除します。

```
% colima stop -p example
% colima delete example
are you sure you want to delete colima [profile=example] and all settings? [y/N] y
INFO[0008] deleting colima [profile=example]
INFO[0008] done
```

## まとめ

`all-ruby` で あるバージョンより古い ruby が動かなくて、
原因不明だったのですが、不便に感じつつ amd64 環境でも動かしていたら、
なぜか `i686-linux` のものが動いていないと気付いて、
hsbt さんに `qemu-user-static` が必要なんじゃないかと教えてもらって、
試してみたら動いたので、
クリーンな VM で再現確認をした、
という話でした。
