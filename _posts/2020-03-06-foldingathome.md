---
layout: post
title: "Folding@homeを動かしてみた"
date: 2020-03-06 20:00 +0900
comments: true
category: blog
tags: raspi linux
---
[分散コンピューティングFolding@home、新型コロナウイルスとの戦いを開始](https://it.srad.jp/story/20/03/05/1226252/)
というのをみて、
CPU リソースが余っている環境でちょっと動かしてみることにしました。

<!--more-->

## 試した環境

- Ubuntu 18.04.4 LTS (bionic)
- `fahclient_7.5.1_amd64.deb`

## BOINC?

BOINC だと Debian 公式パッケージがあるのですが、
[FAH ON BOINC](https://foldingathome.org/faqs/high-performance/fah-on-boinc/)
などによると対応していた時期はあったようですが、今は対応していないようで、
独自クライアントを使う必要があるようです。

## ダウンロード

<https://foldingathome.org/> の上の Start folding から Alternative Downloads とたどって
Debian / Mint / Ubuntu の fahclient をダウンロードします。

演算リソースを提供するだけなら fahcontrol と fahviewer は不要です。

## インストール

`sudo dpkg -i fahclient_7.5.1_amd64.deb` でインストールします。

いつまで動かし続けるかわからないので、 ID はデフォルトの匿名のまま、チームも所属せずに進めました。
passkey は optional ということで未設定のままにしました(fahcontrol などを使うのに必要なのかもしれません)。
power もデフォルトの medium のままにして systemd の CPUQuota で制限することにしました。

autostart は設定すると `update-rc.d` で `FAHClient` の自動起動が設定されました。

## CPU 制限設定

`sudo systemctl edit FAHClient.service` で

    [Service]
    CPUQuota=30%

という内容の `/etc/systemd/system/FAHClient.service.d/override.conf` を作成して
`top` で制限されているのを確認したり、
`systemctl status FAHClient.service` で `override.conf` も有効になっているのを確認したりしました。

1 コア以上を割り当ててもいいのなら 120% のように 100% を超える値を指定しても良さそうでした。

## 設定変更

`/etc/fahclient/config.xml`
を変更して再起動すれば良さそうです。

## 設定反映

反映するのに `sudo systemctl stop FAHClient.service` して `sudo systemctl start FAHClient.service` がなぜかプロセスが残っているか何かで失敗することがあったので、
`sudo /etc/init.d/FAHClient stop` を組み合わせて `sudo systemctl start FAHClient.service` し直したりしたら
うまくいったので、
`/etc/init.d/FAHClient` から自動生成された `FAHClient.service` だと systemd に直接対応しているものと比べて、
何かうまく連携できていないところがあるのかもしれません。

## パーミッション変更

`/var/lib/fahclient/` の中のディレクトリがなぜか other にも write 権限がついていたので、
`sudo chmod -R o-w /var/lib/fahclient` で修正しました。

`configs  cores  logs  log.txt  work` とあって `logs` と `work` は後からできていたので、
修正するのは起動後少し待ってからの方が良さそうです。

`/etc/default/FAHClient` を作って `/etc/init.d/FAHClient` が実行されている時の `umask` を調べてみたところ、
ちゃんと `0022` になっていたので、なぜ other の write パーミッションが付いているのかはわかりませんでした。

`log.txt` などのファイルのパーミッションは正常のようなので、
ディレクトリ作成部分のバグかもしれません。

## 実行状況確認

`tail -n1 /var/lib/fahclient/log.txt` で何パーセント進んでいるか表示できます。

詳しいログは `cat /var/lib/fahclient/log.txt` などで確認できます。

しばらく動かしてみたところ、処理能力に応じて 20 〜 21 分で 1% 進むぐらいの計算量が割り当てられるようです。

## fahcontrol と fahviewer

fahclient と並んで用意されていた fahcontrol と fahviewer も VirtualBox の中の環境に入れて試してみました。

fahcontrol を入れると Pause (一時停止) や Finish (現在までの計算結果を送信して停止) などが GUI でできるようになるようです。
([Uninstall](https://foldingathome.org/support/faq/installation-guides/linux/uninstall/) にアンインストール前に Finish でアップロードしてほしいと書いてあるので、アンインストールしたり、お試し環境ごとを止めたり消したりする前に Finish しておくと良さそうです。)

fahviewer は世界地図の上に分子構造っぽいのがでてきましたが、よくわかりませんでした。

## まとめ

余っている CPU 資源の一部を CPUQuota で制限しつつ、計算しまくるプロセスを動かす設定例として参考になると思います。

今回は folding@home を動かしてみましたが、マイニングを動かすとか、CI を回し続けるとかにも使えそうです。
