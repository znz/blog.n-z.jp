---
layout: post
title: "ext4の中のファイルをmacOS上のVirtualBoxの中でマウントして編集する"
date: 2020-02-08 23:20 +0900
comments: true
category: blog
tags: linux macos
---
ちょっとトラブルがあって Raspberry Pi に接続している USB HDD の中の `/etc/fstab` などを編集する必要があり、
誤操作しても問題が起きる可能性が低いマシンが macOS しかなかったので、
VirtualBox の中の Linux でマウントして編集しました。

osxfuse を使う方法もあるようですが、ファイルシステムを扱うのは本物の Linux を使う方が安心かと思って、
VirtualBox を使う方を選びました。

<!--more-->

## 動作環境

- macOS Catalina 10.15.2
- VirtualBox 6.1.2
- Vagrant 2.2.7
- bento/debian-10 (virtualbox, 202002.04.0)

## 準備

- brew cask で入れていた virtualbox と virtualbox-extension-pack と vagrant が古かったので `brew cask reinstall virtualbox virtualbox-extension-pack` と `brew cask reinstall vagrant` で更新
- 適当なディレクトリを作ってその中で `vagrant init bento/debian-10` して `config.vm.box = "bento/debian-10"` になっている `Vagrantfile` を作成
- `vagrant up` して box をダウンロードして初回起動するのを待つ
- `vagrant ssh` で入って `sudo poweroff` などで一度シャットダウン
- USB HDD を接続しておく
- USB の設定 (ポートの USB) を開く
- extension pack も入れているので USB 3.0 (xHCI) コントローラー を選択
- USB デバイスフィルターで右の `+` がついてる USB プラグのようなアイコンをクリックして USB HDD らしきものを選んで追加
  (試した環境では `Seagate Expansion Desk` が USB HDD で、他に `Apple Inc. Apple T1 Controller` というのがありました。)

## マウントして編集

- `vagrant up` で起動
- `vagrant ssh` で中に入る
- `lsblk` で sdb として認識されているのを確認
- 今回の対象のパーティションは `sdb2` なのでマウント先を `mkdir /tmp/sdb2` で作成 (ディレクトリ名は任意)
- `sudo mount /dev/sdb2 /tmp/sdb2` でマウント
- `EDITOR=vi sudoedit /tmp/sdb2/etc/fstab` で編集
- `sudo umount /tmp/sdb2` でアンマウント
- USB HDD を抜いて、動作確認
- ダメだったら挿し直して `lsblk` で認識待ちからやり直し

## 後始末

- VM を `sudo poweroff` などでシャットダウン
- `vagrant destroy` で VM を削除
- `vagrant box list` などで確認して、不要なら `vagrant box remove bento/debian-10` で box を削除
- `Vagrantfile` をディレクトリごと削除 (`Vagrantfile` と `.vagrant` の削除)

## まとめ

Raspberry Pi 4 で色々試行錯誤していて、
その中から記事にしやすかったものを公開しました。

ちゃんと確認できていないのですが、たぶん unattended-upgrades で再起動がかかってしまったのが原因だと思うので、
SD カード破損対策としての `/boot` の扱いはもうちょっと他の方法を考えた方が良さそうでした。
