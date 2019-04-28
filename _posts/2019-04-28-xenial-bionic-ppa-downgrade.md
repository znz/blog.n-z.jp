---
layout: post
title: "xenialからbionicにあげるとppaをダウングレードしないと更新できなかった"
date: 2019-04-28 12:24 +0900
comments: true
category: blog
tags: ubuntu linux
---
連休ということで、アップグレードで問題が起きてもゆっくり対応する時間が取れそうなので、
Ubuntu 16.04 LTS (xenial) から Ubuntu 18.04 (bionic) にあげてみました。
すると ppa で入れている milter-manager をダウングレードしないと更新できなかったので、そのメモです。

<!--more-->

## 環境

- Ubuntu 16.04 LTS (xenial) から Ubuntu 18.04 (bionic)
- milter-manager 2.1.4-2~xenial1 から 2.1.4-2~bionic1

## アップグレード

`do-release-upgrade` で Ubuntu 18.04 に更新しました。

その後 `sudo add-apt-repository -y ppa:milter-manager/ppa` で ppa の apt-line も登録し直しました。

## 状況

バージョンの xenial1 が bionic1 より新しいと ASCII コード順で判断されて、
bionic のパッケージに更新できませんでした。

```
% apt-cache policy milter-manager
milter-manager:
  インストールされているバージョン: 2.1.4-2~xenial1
  候補:               2.1.4-2~xenial1
  バージョンテーブル:
 *** 2.1.4-2~xenial1 100
        100 /var/lib/dpkg/status
     2.1.4-2~bionic1 500
        500 http://ppa.launchpad.net/milter-manager/ppa/ubuntu bionic/main amd64 Packages
```

## preferences 設定

`/etc/apt/preferences.d/milter-manager` に以下の内容を設定して、ダウングレードしてでもインストールできるようにしました。

```
Package: *
Pin: release o=LP-PPA-milter-manager
Pin-Priority: 1001
```

## 確認

更新できるようになったのを確認しました。

```
% apt-cache policy milter-manager
milter-manager:
  インストールされているバージョン: 2.1.4-2~xenial1
  候補:               2.1.4-2~bionic1
  バージョンテーブル:
 *** 2.1.4-2~xenial1 100
        100 /var/lib/dpkg/status
     2.1.4-2~bionic1 1001
       1001 http://ppa.launchpad.net/milter-manager/ppa/ubuntu bionic/main amd64 Packages
```

## 更新

というわけで更新できました。

```
% sudo apt full-upgrade -V
パッケージリストを読み込んでいます... 完了
依存関係ツリーを作成しています
状態情報を読み取っています... 完了
アップグレードパッケージを検出しています... 完了
以下のパッケージが自動でインストールされましたが、もう必要とされていません:
   libruby2.3 (2.3.1-2~16.04.12)
これを削除するには 'sudo apt autoremove' を利用してください。
以下のパッケージは「ダウングレード」されます:
   libmilter-client0 (2.1.4-2~xenial1 => 2.1.4-2~bionic1)
   libmilter-core0 (2.1.4-2~xenial1 => 2.1.4-2~bionic1)
   libmilter-manager0 (2.1.4-2~xenial1 => 2.1.4-2~bionic1)
   libmilter-server0 (2.1.4-2~xenial1 => 2.1.4-2~bionic1)
   milter-manager (2.1.4-2~xenial1 => 2.1.4-2~bionic1)
   ruby-milter-client (2.1.4-2~xenial1 => 2.1.4-2~bionic1)
   ruby-milter-core (2.1.4-2~xenial1 => 2.1.4-2~bionic1)
   ruby-milter-server (2.1.4-2~xenial1 => 2.1.4-2~bionic1)
アップグレード: 0 個、新規インストール: 0 個、ダウングレード: 8 個、削除: 0 個、保留: 0 個。
708 kB のアーカイブを取得する必要があります。
この操作後に追加で 6,144 B のディスク容量が消費されます。
続行しますか? [Y/n]
```

## まとめ

アルファベットが一巡したら素直に更新できなくなるという Ubuntu のコードネームに依存した現象なので、
特に対策が取られなければ 13 年ごとに発生しそうです。
