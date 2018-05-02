---
layout: post
title: "matterbridgeを試している"
date: 2018-04-06 21:00 +0900
comments: true
category: blog
tags: debian ubuntu linux irc
---
[matterbridge](https://github.com/42wim/matterbridge) という「bridge between mattermost, IRC, gitter, xmpp, slack, discord, telegram, rocket.chat,hipchat (via xmpp), steam, twitch, ssh-chat and matrix with REST API」という説明のいろんなチャットのブリッジができるものを IRCnet と freenode 間で発言を転送するのに使ってみています。

<!--more-->

## 対象バージョン

- Raspbian GNU/Linux 9.4 (stretch)
- Matterbridge v1.9.0
- ruby 2.3.3p222 (2016-11-21) [arm-linux-gnueabihf]

## iso-2022-jp 対応

[Matterbridge の使っている go-charset が iso-2022-jp には対応していない](https://github.com/42wim/matterbridge/issues/400)ので、
[nkf-proxy.rb](https://gist.github.com/znz/c8d70ed84c385e88adb275fdc915d170#file-nkf-proxy-rb) というのを作って回避することにしました。
ついでに nkf の --fb-xml で utf-8 にはあるけど iso-2022-jp にはない文字は数値文字参照になるようにしました。

さらに汎用化して ansible-playbook の一部にしたものが [nkf-proxy.rb](https://github.com/znz/ansible-playbook-raspi201804/blob/4ab550802c494a83f8bc017d2a6d5d37d27a881d/provision/roles/matterbridge/files/nkf-proxy.rb) にあります。

## matterbridge.toml 作成

以下のような感じで設定しました。
2点間の接続なら自明かと思って、
`RemoteNickFormat` は `<{NICK}>` だけにしてしまいました。

他のチャンネルも設定していて、そちらには発言があるのですが、
nadoka jp や ruby-ja は最近ほぼ発言なしなので、
意味があるのかどうかは謎です。

```toml
[irc]

[irc.freenode]
Server="chat.freenode.net:6697"
Password=""
UseTLS=true
Charset="utf-8"
Nick="mattaribridge"
RemoteNickFormat="<{NICK}> "

[irc.ircnet]
Server="localhost:6668"
Charset="utf-8"
Nick="mattaribridge"
RemoteNickFormat="<{NICK}> "

[general]
RemoteNickFormat="[{PROTOCOL}/{BRIDGE}] <{NICK}> "

[[gateway]]
name="nadoka-gateway"
enable=true
[[gateway.inout]]
account="irc.freenode"
channel="#nadoka_jp"
[[gateway.inout]]
account="irc.ircnet"
channel="#nadoka:*.jp"

[[gateway]]
name="ruby-ja-gateway"
enable=true
[[gateway.inout]]
account="irc.freenode"
channel="#ruby-ja"
[[gateway.inout]]
account="irc.ircnet"
channel="#ruby-ja"
```

2018-05-02追記: `Charset=""` だと自動認識になって、たとえば「名古屋」が windows-1252 と誤認識されて文字化けする、ということが起きていたので、 `Charset="utf-8"` に修正しました。

## mattaribridge の IRC での挙動

普通の発言 (PRIVMSG) は転送されるのですが、
bot の発言 (NOTICE) や JOIN や QUIT などは転送されないようです。
設定で変更できるのかもしれませんが、
README や Wiki などをみた限りでは設定項目は見つけられませんでした。

## 今後の予定

気が向いたら mattermost や slack なども試してみるかもしれません。
