---
layout: post
title: "milter-managerのバージョンアップに失敗したので対処した"
date: 2022-09-29 10:20 +0900
comments: true
category: blog
tags: debian ubuntu linux milter-manager
---
[milter manager](https://milter-manager.osdn.jp/index.html.ja) が `apt full-upgrade` に失敗して、
`apt --fix-broken install` もきかなくて困ったので、
どう対処したのかのメモです。

<!--more-->

## 環境

- Ubuntu 20.04.5 LTS (focal)
- [Ubuntuへインストール](https://milter-manager.osdn.jp/reference/ja/install-to-ubuntu.html) の PPA でのインストール
- `milter-manager` の `2.1.5-2~ubuntu20.04.3` から `2.2.0-1.ubuntu20.04.1`

## 問題発生

`Conflict` や `Replace` の設定が不十分なのか、以下のようなエラーで止まってしまい、
`sudo apt --fix-broken install` もきかなくて困ってしまいました。

```console
% sudo apt full-upgrade
パッケージリストを読み込んでいます... 完了
依存関係ツリーを作成しています
状態情報を読み取っています... 完了
アップグレードパッケージを検出しています... 完了
以下のパッケージが自動でインストールされましたが、もう必要とされていません:
  libmilter-client0 libmilter-core0 libmilter-server0
これを削除するには 'sudo apt autoremove' を利用してください。
以下のパッケージは「削除」されます:
  libmilter-manager0
以下のパッケージが新たにインストールされます:
  libmilter-client2 libmilter-core2 libmilter-manager2 libmilter-server2 ruby-gio2 ruby-gobject-introspection
以下のパッケージはアップグレードされます:
  milter-manager ruby-milter-client ruby-milter-core ruby-milter-server
アップグレード: 4 個、新規インストール: 6 個、削除: 1 個、保留: 0 個。
788 kB 中 728 kB のアーカイブを取得する必要があります。
この操作後に追加で 1,070 kB のディスク容量が消費されます。
続行しますか? [Y/n]
取得:1 http://ppa.launchpad.net/milter-manager/ppa/ubuntu focal/main amd64 libmilter-core2 amd64 2.2.0-1.ubuntu20.04.1 [113 kB]
取得:2 http://ppa.launchpad.net/milter-manager/ppa/ubuntu focal/main amd64 libmilter-client2 amd64 2.2.0-1.ubuntu20.04.1 [94.5 kB]
取得:3 http://ppa.launchpad.net/milter-manager/ppa/ubuntu focal/main amd64 libmilter-server2 amd64 2.2.0-1.ubuntu20.04.1 [93.5 kB]
取得:4 http://ppa.launchpad.net/milter-manager/ppa/ubuntu focal/main amd64 milter-manager amd64 2.2.0-1.ubuntu20.04.1 [79.0 kB]
取得:5 http://ppa.launchpad.net/milter-manager/ppa/ubuntu focal/main amd64 ruby-milter-server amd64 2.2.0-1.ubuntu20.04.1 [55.3 kB]
取得:6 http://ppa.launchpad.net/milter-manager/ppa/ubuntu focal/main amd64 ruby-milter-client amd64 2.2.0-1.ubuntu20.04.1 [71.0 kB]
取得:7 http://ppa.launchpad.net/milter-manager/ppa/ubuntu focal/main amd64 ruby-milter-core amd64 2.2.0-1.ubuntu20.04.1 [70.6 kB]
取得:8 http://ppa.launchpad.net/milter-manager/ppa/ubuntu focal/main amd64 libmilter-manager2 amd64 2.2.0-1.ubuntu20.04.1 [152 kB]
728 kB を 8秒 で取得しました (88.0 kB/s)
changelog を読み込んでいます... 完了
apt-listchanges: これでよろしいですか [Y(はい)/n(いいえ)]
apt-listchanges: root にメール: apt-listchanges: ns6 の changelog
以前に未選択のパッケージ libmilter-core2 を選択しています。
(データベースを読み込んでいます ... 現在 172432 個のファイルとディレクトリがインストールされています。)
.../0-libmilter-core2_2.2.0-1.ubuntu20.04.1_amd64.deb を展開する準備をしています ...
libmilter-core2 (2.2.0-1.ubuntu20.04.1) を展開しています...
以前に未選択のパッケージ libmilter-client2 を選択しています。
.../1-libmilter-client2_2.2.0-1.ubuntu20.04.1_amd64.deb を展開する準備をしています ...
libmilter-client2 (2.2.0-1.ubuntu20.04.1) を展開しています...
dpkg: アーカイブ /tmp/user/0/apt-dpkg-install-RVioHt/1-libmilter-client2_2.2.0-1.ubuntu20.04.1_amd64.deb の処理中にエラーが発生しました (--unpack):
 '/usr/bin/milter-test-client' を上書きしようとしています。これはパッケージ libmilter-client0 2.1.5-2~ubuntu20.04.3 にも存在します
dpkg-deb: エラー: ペースト subprocess was killed by signal (Broken pipe)
以前に未選択のパッケージ libmilter-server2 を選択しています。
.../2-libmilter-server2_2.2.0-1.ubuntu20.04.1_amd64.deb を展開する準備をしています ...
libmilter-server2 (2.2.0-1.ubuntu20.04.1) を展開しています...
dpkg: アーカイブ /tmp/user/0/apt-dpkg-install-RVioHt/2-libmilter-server2_2.2.0-1.ubuntu20.04.1_amd64.deb の処理中にエラーが発生しました (--unpack):
 '/usr/bin/milter-test-server' を上書きしようとしています。これはパッケージ libmilter-server0 2.1.5-2~ubuntu20.04.3 にも存在します
dpkg-deb: エラー: ペースト subprocess was killed by signal (Broken pipe)
以前に未選択のパッケージ ruby-gobject-introspection:amd64 を選択しています。
.../3-ruby-gobject-introspection_3.4.1-2build1_amd64.deb を展開する準備をしています ...
ruby-gobject-introspection:amd64 (3.4.1-2build1) を展開しています...
以前に未選択のパッケージ ruby-gio2:amd64 を選択しています。
.../4-ruby-gio2_3.4.1-2build1_amd64.deb を展開する準備をしています ...
ruby-gio2:amd64 (3.4.1-2build1) を展開しています...
.../5-milter-manager_2.2.0-1.ubuntu20.04.1_amd64.deb を展開する準備をしています ...
milter-manager (2.2.0-1.ubuntu20.04.1) で (2.1.5-2~ubuntu20.04.3 に) 上書き展開しています ...
処理中にエラーが発生しました:
 /tmp/user/0/apt-dpkg-install-RVioHt/1-libmilter-client2_2.2.0-1.ubuntu20.04.1_amd64.deb
 /tmp/user/0/apt-dpkg-install-RVioHt/2-libmilter-server2_2.2.0-1.ubuntu20.04.1_amd64.deb
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

## 対処

中途半端にパッケージを指定して `apt remove` などをしようとしても無理だったのですが、最終的に一通り指定すると `remove` できました。

```console
% sudo apt remove libmilter-server0 libmilter-client0 libmilter-manager2 ruby-milter-client ruby-milter-server milter-manager
パッケージリストを読み込んでいます... 完了
依存関係ツリーを作成しています
状態情報を読み取っています... 完了
以下のパッケージが自動でインストールされましたが、もう必要とされていません:
  libev4 libmilter-core0 libmilter-core2 ruby-gio2 ruby-glib2 ruby-gobject-introspection ruby-milter-core ruby-pkg-config
これを削除するには 'sudo apt autoremove' を利用してください。
以下のパッケージは「削除」されます:
  libmilter-client0 libmilter-manager2 libmilter-server0 milter-manager ruby-milter-client ruby-milter-server
アップグレード: 0 個、新規インストール: 0 個、削除: 6 個、保留: 0 個。
8 個のパッケージが完全にインストールまたは削除されていません。
この操作後に 1,528 kB のディスク容量が解放されます。
続行しますか? [Y/n]
```

そして `milter-manager` をインストールしなおすと、ちゃんとインストールできました。

```console
% sudo apt install milter-manager
```

`systemctl status milter-manager.service` で確認すると起動していなかったので、
`sudo systemctl enable milter-manager.service --now` で起動して、
`/var/log/mail.log` もみて、動いていることを確認しました。

## 感想

PPA のパッケージはたまにこういうことがあるので、できるだけ使わないようにしたり、バージョンアップは対処できる余裕のあるときに限ったりした方が良さそうです。
