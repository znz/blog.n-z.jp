---
layout: post
title: "sshをproxy経由でつなぐ"
date: 2018-08-12 12:31 +0900
comments: true
category: blog
tags: linux osx ssh
---
ssh を proxy 経由で接続してみることがあったので、
[connect](https://bitbucket.org/gotoh/connect/wiki/Home)
([connect-proxy](https://packages.debian.org/sid/connect-proxy))
と
[corkscrew](https://packages.debian.org/sid/corkscrew)
を試してみたのですが、
corkscrew は使わない方が良いです。

認証が不要なら nc (netcat) が使えます。

<!--more-->

## 環境

- 接続元 macOS High Sierra 10.13.6
- http proxy 詳細不明 (proxy 認証として BASIC 認証あり)
- ssh 接続先 Linux

## 認証が不要な場合

認証が不要なら macOS に元から入っている nc (netcat) を使うのが一番簡単です。

認証が必要な場合は以下のように繋がりませんでした。

```
$ ssh -o ProxyCommand='nc -X connect -x proxy.example.jp:3128 %h %p' ssh-user@ssh-host.inner.example.jp
nc: Proxy error: "HTTP/1.1 407 Proxy Authentication Required"
ssh_exchange_identification: Connection closed by remote host
```

## connect での proxy 認証

proxy 認証設定は
[connect](https://bitbucket.org/gotoh/connect/wiki/Home)
の表にあるように、
`CONNECT_USER` または `HTTP_PROXY_USER` と
`CONNECT_PASSWORD` と `HTTP_PROXY_PASSWORD` が使えるようなので、
`CONNECT_USER` と `CONNECT_PASSWORD` を使うことにしました。

## 接続テスト

認証が必要なければ
`ssh -o ProxyCommand='connect -H proxy.example.jp:3128 %h %p' ssh-user@ssh-host.inner.example.jp`
で繋がります。

パスワードを毎回入力するなら
`ssh -o ProxyCommand='env CONNECT_USER=proxyuser connect -H proxy.example.jp:3128 %h %p' ssh-user@ssh-host.inner.example.jp`
でいけました。

## ssh config に設定

`~/.ssh/config` に

```
Host *.inner.example.jp
ProxyCommand env CONNECT_USER=proxyuser CONNECT_PASSWORD=XXXXXXXX connect -H proxy.example.jp:3128 %h %p
User ssh-user
```

と設定しておくと
`ssh ssh-host.inner.example.jp`
で接続できるようになりました。

## corkscrew

GPL2 の corkscrew.c の一部をみると以下のようなところがあったりして、
[鼻から悪魔が飛び出し](http://www.st.rim.or.jp/~phinloda/cqa/cqa7.html)そうなので、
使わない方が良さそうだと思いました。

```c
                        } else {
                                char line[4096];
                                fscanf(fp, "%s", line);
                                up = malloc(sizeof(line));
                                up = line;
                                fclose(fp);
                        }
```

## corkscrew 失敗例

`brew install corkscrew` で入れたものは、
以下のように普通に試そうとしても動かなかったので、
どちらにしても使えませんでした。

```
$ ssh -o ProxyCommand='corkscrew proxy.example.jp 3128 %h %p' ssh-user@ssh-host.inner.example.jp
Proxy could not open connnection to ssh-host.inner.example.jp:  Proxy Authentication Required
ssh_exchange_identification: Connection closed by remote host
$  echo proxyuser:XXXXXXXX > ~/.ssh/proxy.txt
$  chmod 400 ~/.ssh/proxy.txt
$  ssh -o ProxyCommand='corkscrew proxy.example.jp 3128 %h %p ~/.ssh/proxy.txt' ssh-user@ssh-host.inner.example.jp
Proxy could not open connnection to ssh-host.inner.example.jp:  Proxy Authentication Required
ssh_exchange_identification: Connection closed by remote host
```

## まとめ

認証が不要なら、まずは nc (netcat) を使いましょう。
認証が必要なら別途何を使うか検討しましょう。

Emacs 関連で存在を知っていたので、
connect を選びましたが、
他にも同様のことができるものはありそうです。

[この fork](https://github.com/bryanpkc/corkscrew) だと改善されているようなので、
debian パッケージや homebrew がこちらを使うようになれば使っても良いのかもしれませんが、
現状の debian パッケージや brew で入る corkscrew は使わない方が良さそうです。

connect の方は proxy 認証として Basic 認証しか対応していない
(Digest 認証には対応していない)
と明記されていましたが、
corkscrew もソースをみる限りでは同じだったので、
Digest 認証が必要ならどちらも使えなさそうです。
