---
layout: post
title: "WeeChatでgitterに接続した"
date: 2018-03-29 23:18 +0900
comments: true
category: blog
tags: weechat slack linux ubuntu debian
---
GitHub のアカウントか Twitter のアカウントでサインインできる <https://gitter.im/> は
<https://irc.gitter.im/> に書いてあるように IRC での接続にも対応していて、
[WeeChat](https://weechat.org/) から簡単に接続できるようなので
試してみました。

<!--more-->

## 対象バージョン

- Ubuntu 16.04.4 LTS
- weechat-core, weechat-curses, weechat-perl, weechat-plugins, weechat-python 2.1-1

## ログイン情報の取得

<https://irc.gitter.im/> には

1. Click here to login and get your token
2. Connect to irc.gitter.im with your IRC client using SSL(port 6667 or 6697)
3. Provide the the token we give you (login to see token) as the Server Password
4. /NICK your github username
5. Profit

と書いてありますが、ログインすると、
表示内容が変わって、

1. Connect to irc.gitter.im with your IRC client using SSL
2. Server Password: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
3. /NICK znz
4. Profit

のようになるので、
このサーバーパスワードとニックネームも設定で使います。

## サーバー設定

サーバーを追加して NICK の設定をします。

    /server add gitter irc.gitter.im/6697 -ssl -autoconnect
    /set irc.server.gitter.nicks znz

## サーバーパスワード設定

保護データを使いたかったので、まずパスフレーズを設定しました。
すでに設定済みの場合は不要です。

    /secure passphrase this is my secret passphrase

保護データにパスワードを追加して、それを参照するようにサーバーパスワードを設定します。

    /secure set gitter_password xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    /set irc.server.gitter.password "${sec.data.gitter_password}"

## 接続

autoconnect を設定しているので、
再起動時は自動接続しますが、
設定中は手動で接続する必要があるので接続します。

    /connect gitter

するとサーバーに繋がって、
gitter で参加しているチャンネルが
`#red-data-tools/ja` や `#ruby/ruby`
のように出てきて見えるようになりました。

参加している Gitter のチャンネルはどこも発言がほとんどないのですが、
`#ruby/ruby` をみた感じだと右側の activity も IRC に流れてくるようです。

## ログ設定

    /set logger.level.irc 0

で IRC のデフォルトは止めていたので、

    /set logger.level.irc.server.gitter 9
    /set logger.level.irc.gitter 9

でサーバーバッファと全てのチャンネルで保存するようにしました。

設定の確認は

    /logger list

です。

設定の詳細は
[WeeChat ユーザーズガイドの 4.9. Logger](https://weechat.org/files/doc/stable/weechat_user.ja.html#logger_plugin)
に書いてありました。
