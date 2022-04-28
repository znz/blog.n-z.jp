---
layout: post
title: "Ubuntu 22.04でマシンによって更新されたりされなかったりするパッケージがあったのを調べた"
date: 2022-04-28 14:59 +0900
comments: true
category: blog
tags: linux ubuntu debian
---
Ubuntu や Debian には Phased Updates という仕組みがあって、デフォルトでは jammy-updates などのパッケージは最初は 10% だけで徐々に対象が増えていく、ということをしてレグレッションの問題を軽減しているようです。

<!--more-->

## 動作確認環境

- Ubuntu 22.04 LTS (jammy)

## 気付いた動作

`base-files` が環境によって更新されたりされなかったりしました。
`/etc/apt/preferences.d` などでの apt pinning や hold なども設定されていませんでした。

```console
$ sudo apt full-upgrade -qq
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
$ apt-cache policy base-files
base-files:
  Installed: 12ubuntu4
  Candidate: 12ubuntu4
  Version table:
     12ubuntu4.1 1 (phased 10%)
        500 http://ca.archive.ubuntu.com/ubuntu jammy-updates/main amd64 Packages
 *** 12ubuntu4 500
        500 http://ca.archive.ubuntu.com/ubuntu jammy/main amd64 Packages
        100 /var/lib/dpkg/status
```

調べてみると
[PhasedUpdates - Ubuntu Wiki](https://wiki.ubuntu.com/PhasedUpdates)
という機能の影響だったようで、それを気にせず更新する設定を探してみました。

## 設定例

### 積極的に更新

[Phased updates in APT in 21.04 - Foundations - Ubuntu Community Hub](https://discourse.ubuntu.com/t/phased-updates-in-apt-in-21-04/20345)
を参考にして全部許可すると以下のようになりました。

```console
$ echo 'APT::Get::Always-Include-Phased-Updates "true";' | sudo tee /etc/apt/apt.conf.d/99-Phased-Updates
$ apt-cache policy base-files
base-files:
  Installed: 12ubuntu4
  Candidate: 12ubuntu4.1
  Version table:
     12ubuntu4.1 500 (phased 10%)
        500 http://ca.archive.ubuntu.com/ubuntu jammy-updates/main amd64 Packages
 *** 12ubuntu4 500
        500 http://ca.archive.ubuntu.com/ubuntu jammy/main amd64 Packages
        100 /var/lib/dpkg/status
```

`APT::Get::Always-Include-Phased-Updates true;`
でも `"true"` と同じでしたが、
`APT::Get::Always-Include-Phased-Updates;`
は何も書かないのと同じ結果でした。

一時的に全部更新するだけなら、
`sudo apt -o APT::Get::Always-Include-Phased-Updates=true full-upgrade`
のように `-o` で指定できます。

### 全部待つ

Phased Update 中のものは更新しないように設定すると以下のようになりました。

```console
$ echo 'APT::Get::Never-Include-Phased-Updates "true";' | sudo tee /etc/apt/apt.conf.d/99-Phased-Updates
$ apt-cache policy base-files
base-files:
  Installed: 12ubuntu4
  Candidate: 12ubuntu4
  Version table:
     12ubuntu4.1 1 (phased 10%)
        500 http://ca.archive.ubuntu.com/ubuntu jammy-updates/main amd64 Packages
 *** 12ubuntu4 500
        500 http://ca.archive.ubuntu.com/ubuntu jammy/main amd64 Packages
        100 /var/lib/dpkg/status
```

## その他の設定

### GUI あり環境の設定

以前は apt コマンドが Phased Updates に対応していなくて、
Update Manager などが対応していただけだったらしく、
`Update-Manager::Never-Include-Phased-Updates`
などの Update Manager 向けもあるようですが、
GUI あり環境は試していないので、
Ubuntu 22.04 でどういう関係になっているのかは調べていません。

### タイミングを合わせる

ランダムなタイミングのままで良くて、複数のマシンごとのタイミングを合わせたい場合は、
[`apt_preferences`のPhased Updates](https://manpages.debian.org/bullseye/apt/apt_preferences.5.en.html#Phased_Updates)
によると、
Phased Updates のタイミングの計算に使われる `APT::Machine-ID` を同じ UUID に設定すれば良いそうです。

## 関連情報

### レポジトリ側

レポジトリ側のファイルの関連部分は
[DebianRepository/Format - Debian Wiki の Phased-Update-Percentage](https://wiki.debian.org/DebianRepository/Format#Phased-Update-Percentage)
でした。

ここは自分の側の設定でどうにかなる部分ではないので、値の確認だけしてみました。

```console
$ grep -r Phased-Update-Percentage /var/lib/apt/lists/ | sort | uniq -c
grep: /var/lib/apt/lists/lock: Permission denied
grep: /var/lib/apt/lists/partial: Permission denied
      3 /var/lib/apt/lists/ca.archive.ubuntu.com_ubuntu_dists_jammy-updates_main_binary-amd64_Packages:Phased-Update-Percentage: 10
      1 /var/lib/apt/lists/ca.archive.ubuntu.com_ubuntu_dists_jammy-updates_main_binary-amd64_Packages:Phased-Update-Percentage: 50
      1 /var/lib/apt/lists/ca.archive.ubuntu.com_ubuntu_dists_jammy-updates_main_binary-amd64_Packages:Phased-Update-Percentage: 70
      4 /var/lib/apt/lists/ca.archive.ubuntu.com_ubuntu_dists_jammy-updates_main_binary-amd64_Packages:Phased-Update-Percentage: 90
      3 /var/lib/apt/lists/ca.archive.ubuntu.com_ubuntu_dists_jammy-updates_main_binary-i386_Packages:Phased-Update-Percentage: 10
      1 /var/lib/apt/lists/ca.archive.ubuntu.com_ubuntu_dists_jammy-updates_main_binary-i386_Packages:Phased-Update-Percentage: 50
      8 /var/lib/apt/lists/ca.archive.ubuntu.com_ubuntu_dists_jammy-updates_universe_binary-amd64_Packages:Phased-Update-Percentage: 70
      5 /var/lib/apt/lists/ca.archive.ubuntu.com_ubuntu_dists_jammy-updates_universe_binary-i386_Packages:Phased-Update-Percentage: 70
```

### 対象パッケージ

Ubuntu は
[Phasing Ubuntu Stable Release Updates](https://people.canonical.com/~ubuntu-archive/phased-updates.html)
に Phased Update 中のパッケージの一覧があるようです。

## まとめ

検証用環境では `APT::Get::Always-Include-Phased-Updates "true";` にして、
本番環境では `APT::Get::Never-Include-Phased-Updates "true";` にするなど、
Phased Update の対応を変えたいときに参考にしてみてください。
