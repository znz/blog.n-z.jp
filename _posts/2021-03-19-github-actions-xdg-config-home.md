---
layout: post
title: "GitHub ActionsでXDG_CONFIG_HOMEが設定されるようになった影響を受けた"
date: 2021-03-19 12:09 +0900
comments: true
category: blog
tags: github ubuntu
---
現象としては、また何もしていないのに ruby のテストが壊れたように見えたのですが、
根本的な原因としてはテストの `XDG_CONFIG_HOME` 対応が不十分だったという話です。

<!--more-->

## 環境

- GitHub Actions の ubuntu-20.04 などの ubuntu 環境の Version: 20210309.1
- <https://github.com/ruby/actions> の coverage, draft release package 作成, snapshot 作成

## 原因

`run: env | sort` という step を入れている workflow があったので、失敗するようになる前と比較してみると以下の違いがありました。

増えた環境変数:

```
BASH_ENV=/etc/profile.d/env_vars.sh
NVM_DIR=/home/runner/.nvm
XDG_CONFIG_HOME=/home/runner/.config
```

`PATH` の変化:

```
-PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/opt/pipx_bin:/usr/share/rust/.cargo/bin:/home/runner/.config/composer/vendor/bin:/usr/local/.ghcup/bin:/home/runner/.dotnet/tools:/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
+PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/opt/pipx_bin:/usr/share/rust/.cargo/bin:/usr/local/.ghcup/bin:/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/runner/.dotnet/tools:/home/runner/.config/composer/vendor/bin:/home/runner/.local/bin
```

増えた `PATH` は `/home/runner/.local/bin` だけのようですが、順番が変わっているところがあるようです。

多少見やすいように加工すると以下のようになります。

```
変化前:
 ["/home/linuxbrew/.linuxbrew/bin",
  "/home/linuxbrew/.linuxbrew/sbin",
  "/opt/pipx_bin",
  "/usr/share/rust/.cargo/bin",
  "/home/runner/.config/composer/vendor/bin",
  "/usr/local/.ghcup/bin",
  "/home/runner/.dotnet/tools",
  "/snap/bin",
  "/usr/local/sbin",
  "/usr/local/bin",
  "/usr/sbin",
  "/usr/bin",
  "/sbin",
  "/bin",
  "/usr/games",
  "/usr/local/games",
  "/snap/bin"]
変化後:
 ["/home/linuxbrew/.linuxbrew/bin",
  "/home/linuxbrew/.linuxbrew/sbin",
  "/opt/pipx_bin",
  "/usr/share/rust/.cargo/bin",
  "/usr/local/.ghcup/bin",
  "/snap/bin",
  "/usr/local/sbin",
  "/usr/local/bin",
  "/usr/sbin",
  "/usr/bin",
  "/sbin",
  "/bin",
  "/usr/games",
  "/usr/local/games",
  "/snap/bin",
  "/home/runner/.dotnet/tools",
  "/home/runner/.config/composer/vendor/bin",
  "/home/runner/.local/bin"]
```

## 起きたこと

テストを実行するユーザーの環境に影響がないことを確認するために、
ruby/actions の方では `$HOME` や `$HOME/.config` などから書き込み権限をおとしているのですが、
`XDG_CONFIG_HOME` が設定されるようになってから、

```
Errno::EACCES: Permission denied @ dir_s_mkdir - /home/runner/.config/irb
```

というエラーがいくつかのテストで起きるようになっていました。

## 動作確認

手元でも `chmod a-w ~/.config` として、
`XDG_CONFIG_HOME=$HOME/.config make test-all TESTS='-v irb'`
で実行すると
[Fix errors when XDG_CONFIG_HOME points to non-writable directory](https://github.com/ruby/ruby/commit/e0dd072978e6c2c8180e75617e7ee37830caefa3)
で直した方は再現できたのですが、
[Try to fix errors in TestIRB::TestHistory too](https://github.com/ruby/ruby/commit/85f99f4b715a5954124d5014002c16652995b128)
で直した方はなぜか再現しなかったので、
GitHub Actions 上での動作確認になりました。
