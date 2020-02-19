---
layout: post
title: "docs.ruby-lang.orgをstretchからbusterに切り替えた"
date: 2020-02-18 23:59 +0900
comments: true
category: blog
tags: ruby
---
今週のるりまレビュー会に向けて
EC2 で動かしている docs.ruby-lang.org の Debian GNU/Linux 10 (buster) 版を用意して、
最終的に切り替えました。

<!--more-->

## 環境

`/etc/letsencrypt` や fastly の API Key など以外は
ほぼ
[ruby/docs.ruby-lang.org](https://github.com/ruby/docs.ruby-lang.org)
で再現できるはずです。

[ruby/rurema-search](https://github.com/ruby/rurema-search) も必要なので、
そこだけはちょっと注意が必要です。

## EC2 インスタンス作成

<https://wiki.debian.org/Cloud/AmazonEC2Image/Buster> を参考にして debian-10-amd64-2020 で検索して
debian-10-amd64-20200210-166 を利用しましたが、
The AMIs are owned by AWS account ID 136693071363. なのかどうかは確認方法がわかりませんでした。

他は既存の docs と同じような感じで作成しました。

## provision

`~/.ssh/config` の設定をいい感じにして `ssh docs-2020` でつながるようにして
`ansible-playbook -i docs-2020, provision/playbook.yml`
で基本的な設定をしました。

`ansible-playbook -i docs-2020, provision/users.yml`
で他ユーザーの追加もしました。

## /etc/letsencrypt

certbot の設定はどうしようか悩んだ結果、
VPC 内で (tar でまとめてから) scp してもっていってしまうことにしました。

証明書などがない状態で `https` の設定を入れていると nginx の restart に失敗してしまうので、
結局この方法が一番楽そうでした。

`/etc/letsencrypt` のコピーが終わってから
`ansible-playbook -i docs-2020, provision/letsencrypt.yml`
で certbot なども入れました。

## 今は生成していない古いドキュメントのコピー

`/var/www/docs.ruby-lang.org/shared/public/{en,ja}/{1.8.7,1.9.3,2.0.0,2.1.0,2.2.0,2.3.0}` は
今は生成していなくて、古いものをリンク切れにならないようにそのままおいているだけなので、
旧 docs からコピーしました。

`curl -v -H 'Host: docs.ruby-lang.org' -k https://18.178.72.192/ja/1.8.7/doc/index.html`
のような感じでちゃんと配置できているのを確認しました。

## rurema-search

ruby/rurema-search での `cap production deploy` と
`ansible-playbook -i docs-2020, provision/rurema-search.yml`
で設定ファイルの配置をしました。

## fastly purge key

`/home/rurema/.docs-fastly` も旧 docs からコピーしました。

## ドキュメント生成

README.md に書いてあるように

```
  sudo systemctl start rdoc-static-all.service bc-setup-all.service &
  sudo systemctl status rdoc-static-all.service bc-setup-all.service bc-static-all.service update-rurema-index.service
```

で生成と状況確認をしました。

## ホスト名

`hostnamectl set-hostname` で現在のホスト名と `/etc/hostname` は変わるものの、
`/etc/hosts` は変わりませんでした。

`/etc/hosts` にはプライベートアドレスから生成されたようなホスト名が 127.0.1.1 に設定されていて、
旧 docs は `/etc/hostname` に `docs.ruby-lang.org` と設定されていたので、
最終的に同様のホスト名に設定することにしました。

## doc.ruby-lang.org の https 設定追加

基本的に doc は docs へのリダイレクトだけで、リンクも http だけで https はないはずですが、
設定の練習も兼ねて https の設定を追加しました。

 `/.well-known/acme-challenge` だけ見えるようにして、他はリダイレクトとしたかったのですが、
nginx の設定ファイルで正規表現指定 (`location ~` とか `location ^~` とか) を混ぜるとうまくいかないなどで
なかなかうまくいかなくて時間がかかってしまいましたが、最終的に設定できました。

`sudo certbot certonly --webroot -w /var/www/html -d doc.ruby-lang.org`
で証明書を発行して、 `https` 側のリダイレクトだけする設定を追加して完了しました。

## 切り替え

`docs.ruby-lang.org` の fastly からバックエンドとしてみているドメインも切り替えました。
しかし、 fastly 側の設定で IP アドレスで指定されていて切り替わっていなかったので、
この記事を書いている時に fastly 側の設定も変更して切り替わりました。

## まとめ

実際には rurema-search のデプロイ忘れとかで前後していましたが、
おおまかにはこの記事に書いたような作業で移行できました。
