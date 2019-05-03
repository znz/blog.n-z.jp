---
layout: post
title: "zshでdockerコマンドなどの補完のoption-stackingを調べた"
date: 2019-05-03 13:33 +0900
comments: true
category: blog
tags: docker macos linux zsh
---
docker コマンドの zsh での補完の設定で `option-stacking` というのを知って調べてみました。

<!--more-->

## 確認環境

- macOS 10.14.4
- zsh 5.3 (x86_64-apple-darwin18.0)
- Docker version 18.09.2, build 6247962

## docker のインストール

`brew cask install docker` で入れたものを使っています。

## 補完を有効にする

以下のようにシンボリックリンクを作成しています。

```
ln -sf /Applications/Docker.app/Contents/Resources/etc/docker.zsh-completion /usr/local/share/zsh/site-functions/_docker
ln -sf /Applications/Docker.app/Contents/Resources/etc/docker-compose.zsh-completion /usr/local/share/zsh/site-functions/_docker-compose
ln -sf /Applications/Docker.app/Contents/Resources/etc/docker-machine.zsh-completion /usr/local/share/zsh/site-functions/_docker-machine
```

入っていない環境では <https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker> あたりからダウンロードしてくると良いようです。

## 設定変更

[zshでdockerコマンドを補完する](https://qiita.com/gott/items/17180001f39cfa9f8bbf)で知ったのですが、
docker の補完の独自設定として `option-stacking` という[設定があり](https://github.com/docker/cli/blob/3273c2e23546dddd0ff8bb499f4aba02fe60bf30/contrib/completion/zsh/_docker#L41-L43)、
`_arguments` に `-s` オプションをつけるかどうかを選べるようです。

zstyle 一般に `option-stacking` という設定があるわけではなく `_docker` 独自の設定名のようです。

```
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
```

を設定して有効にすると、 `-s` オプションがつくようになり、
たとえば `docker run -i[TAB]` で他の1文字オプションの補完ができるようになります。

デフォルトだとスペースが入って次の引数を入力する状態になります。
