---
layout: post
title: "Homebrewのzabbix-agentでipv6を有効にしてインストール"
date: 2023-06-28 10:00 +0900
comments: true
category: blog
tags: osx homebrew zabbix
---
Homebrew でインストールされる zabbix-agent は ipv6 が有効になっていないので、毎回有効にして `reinstall` していて、その手順を再現しやすいようにまとめなおしたので、そのメモです。

<!--more-->

## 確認環境

- `Homebrew 4.0.26-2-gc5cbe64`
- `Homebrew/homebrew-core (git revision 6e16b5d07a7; last commit 2023-06-28)`
- zabbix 6.4.4
- Apple M1 Pro の macOS Ventura 13.4.1 と Intel Mac の macOS Monterey 12.6.7

## 経緯

<https://github.com/Homebrew/homebrew-core/pull/114076>
で `--enable-ipv6` の追加の pull request を出してみたら、
upstream に言った方が良いとコメントがついたので、
upstream に言ってみて、考えておく、という感じの返事をもらったので、
待っている間に pull request が自動クローズされてしまって、
そのことはコメントに追記できずに終わってしまいました。

そして、現在の zabbix 6.4.4 でもデフォルトでは `--enable-ipv6` になっていないままなので、
自前ビルドで対応しています。

## 対応方法

今の Homebrew では、
`brew edit` した内容は `HOMEBREW_NO_INSTALL_FROM_API=1` がないと反映されず、
そもそも使われなくなったからか、
`/opt/homebrew/Library/Taps/homebrew/homebrew-core`
も自動更新されないようなので、以下のように自分で `git pull` する必要がありました。

Intel Mac だと `/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core` だったので、統一するために `$(brew --repository homebrew/homebrew-core)` を使いましたが、
M1 以降だけなら `git -C /opt/homebrew/Library/Taps/homebrew/homebrew-core pull --prune --autostash` で良さそうです。

`--enable-ipv6` の追加は、
今までは `vi` で編集していたのですが、
`sed` で自動化しました。
本来なら別の行に追加する方が良いのですが、
`sed` での編集のしやすさを考えて、
`--enable-agent` の行への追加にしています。

そして
`HOMEBREW_NO_INSTALL_FROM_API=1` と `--build-from-source` をつけて
`brew reinstall zabbix` しています。
`-v --display-times` は Intel Mac が遅くて進んでいるかどうかわかりにくかったのでつけています。

```bash
#!/bin/bash
set -euxo pipefail
git -C $(brew --repository homebrew/homebrew-core) pull --prune --autostash
HOMEBREW_EDITOR="sed -i '' -e 's/--enable-agent/--enable-agent --enable-ipv6/'" brew edit zabbix
HOMEBREW_NO_INSTALL_FROM_API=1 brew reinstall zabbix --build-from-source -v --display-times
HOMEBREW_EDITOR="sed -i '' -e 's/--enable-agent --enable-ipv6/--enable-agent/'" brew edit zabbix
```

## zabbix-agent の自動起動設定

`~/Library/LaunchAgents/com.zabbix.agentd.plist` を用意して、

```bash
launchctl unload ~/Library/LaunchAgents/com.zabbix.agentd.plist
launchctl load -w ~/Library/LaunchAgents/com.zabbix.agentd.plist
```

で再起動しています。
`load -w` のタイミングで許可のダイアログが出て許可したら更新完了です。

`com.zabbix.agentd.plist` は以下のような内容にしています。
`zabbix_agentd` のパスは Intel Mac だと `/usr/local/sbin/zabbix_agentd` でした。

`zabbix_agentd.conf` はどこでも好きな場所に置けば良さそうです。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>com.zabbix.agentd</string>
		<key>ProgramArguments</key>
		<array>
			<string>/opt/homebrew/sbin/zabbix_agentd</string>
			<string>-f</string>
			<string>-c</string>
			<string>/Users/kazu/zabbix-agentd/zabbix_agentd.conf</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
	</dict>
</plist>
```

## zabbix_agentd.conf

`zabbix_agentd.conf` は以下のような感じで設定しています。

```console
% grep -E '^[^#]' ~/zabbix-agentd/zabbix_agentd.conf
LogFile=/tmp/zabbix_agentd.log
Server=127.0.0.1,10.20.19.0/24,fdcb:a987:6543:2022::/64
Hostname=knmbp21
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=knmbp21
TLSPSKFile=/Users/kazu/zabbix-agentd/knmbp21.psk
```

## 感想

できるだけ環境を IPv6 のみにしていく途中で、ひっかかっている場所のひとつがこの zabbix-agent の formula です。

deb パッケージなどは Debian や Ubuntu 配布のものも、
zabbix 配布のものも `--enable-ipv6` でビルドされているので、
そのまま使えています。
なので、
zabbix のメジャーバージョンアップかどこかで、
デフォルトで zabbix-agent も IPv6 対応になって、
問題のある環境で `--disable-ipv6` するだけになればいいのに、
と思いつつ、
今は Homebrew では手動でビルドを続けています。
