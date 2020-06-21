---
layout: post
title: "Zabbix 5.0のSlack通知を使ってみた"
date: 2020-06-21 14:00 +0900
comments: true
category: blog
tags: zabbix
---
Zabbix 5.0 LTS では Slack への通知にネイティブで対応しているので、
使ってみようとしたところ、
はまりどころが多かったのですが、
使えるようになったので、そのメモです

<!--more-->

## 動作確認環境

- Raspbian GNU/Linux 10 (buster)
- zabbix-server-pgsqlなど 1:5.0.1-1+buster
  (https://www.zabbix.com/jp/download の方法でインストールしたもの)

## Slack トークン作成

<https://www.zabbix.com/integrations/slack>
の情報は古いままのようで、
アプリを作成するなら、
今は OAuth の Scope を選ぶ必要がありました。

[Incoming Webhook アプリ](https://slack.com/apps/A0F7XDUAZ--incoming-webhook-)
と同様に
[Bots アプリ](https://slack.com/apps/A0F7YS25R-bots)
を使うと、
連携アプリ数を抑えて他 (ruboty など) と共有して使えるようです。

別アプリを作るなら Scope は
<https://www.reddit.com/r/zabbix/comments/f9udjv/slack_integration/>
に書いてあるように `chat:write` と `incoming-webhook` が必要でした。

`xoxb-` で始まる文字列が bot 用のトークンになります。

今回は関係ないのですが、
[Token types](https://api.slack.com/authentication/token-types)
によると `xoxp-` が User tokens (クライアントアプリを作る時などに使う) で、
他には Workspace tokens などもあるようです。

## チャンネルにアプリを追加

チャンネルの右上の「詳細」の「その他」の「アプリを追加する」などから、
通知を出したいチャンネルにアプリを追加しておきます。

## グローバルマクロ設定

「管理」の「一般設定」から「マクロ」を開いて、以下のように Zabbix の URL のベース部分を設定しておきます。

- マクロ: `{$ZABBIX.URL}`
- 値: `http://127.0.0.1/zabbix/` のような zabbix の URL
- 説明: `For Slack media type` など適当に設定

bot token もメディアタイプの方に埋め込みたくないなら、ここで設定しておきます。

- マクロ: `{$SLACK_BOT_TOKEN}`
- 値: `xoxb-` で始まる文字列
- 説明: 適当に設定

## Slack メディアタイプのインポート

古いバージョンからのアップグレードで Slack メディアタイプがない場合は
<https://www.zabbix.com/integrations/slack>
の途中に書いてあるように、
「管理」の「メディアタイプ」で
[media_slack.xml](https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/media/slack/media_slack.xml)
をインポートすれば良いようです。

スクリプトにかなりのロジックが入っているようですが、
`Slack` という変数をみていて、
この定義はスクリプトの中になくて、
Zabbix 本体側で持っているようで、
全てスクリプトで実装しているわけではなさそうでした。

## トークンのテスト

「管理」の「メディアタイプ」の右の「アクション」の列にある「テスト」からテストできます。

- `bot_token` に `xoxb-` で始まる文字列を入れます。テストではマクロは展開されないようなので、直接入れる必要があります。
- 「メディアタイプのテストに失敗しました。」で `Slack notification failed : Field "event_id" is not a number` のようにマクロのままだとダメなフィールドがわかるので、適当に 1 などに書き換えていきます。
- 最終的に `event_id`, `event_nseverity`, `event_update_status`, `event_value`, `trigger_id` を 1 にしました。
- zabbix_url はグローバルマクロで `{$ZABBIX.URL}` を設定していても `Slack notification failed : Field "zabbix_url" must contain a schema` となるので `http://127.0.0.1/zabbix/` としました。

最後はチャンネル名が問題です。

- `{ALERT.SENDTO}` のままだと `Slack notification failed : channel_not_found` になります。
- プライベートチャンネルなどの bot のアカウントで存在が確認できないチャンネルも `channel_not_found` になります。
- パブリックチャンネルでアプリが追加されていないと `Slack notification failed : not_in_channel` になります。

チャンネルにアプリを追加しておくと「メディアタイプのテストに成功しました。」となって Slack 側に投稿されているのを確認できます。

## 通知設定

- メディアタイプ Slack を開いて `bot_token` を設定します。グローバルマクロに設定したなら `{$SLACK_BOT_TOKEN}` も使えます。
- <https://www.zabbix.com/integrations/slack> によると `slack_mode` は `alarm` の他に `event` を設定できるようです。
- メッセージテンプレートも必要なようなので、なければ設定しておきます。内容にこだわりがなければ追加で必要なメッセージタイプをテンプレート側はそのままで追加していけば良さそうです。
- 次に「管理」の「ユーザー」から対象ユーザーを開いて「メディア」でタイプ Slack を追加して、送信先を設定します。
  <https://www.zabbix.com/integrations/slack> によると、送信先には `#channel_name`, `@slack_user`, または `GQMNQ5G5R` のような ID が使えるらしいです。
- 最後に「設定」の「アクション」でメッセージの送信の設定をします。
  ここでメッセージのカスタマイズにチェックが入っていて、件名とメッセージが設定されていれば、メディアタイプ側でメッセージテンプレートがなくても通知されそうです。

## 感想

最初は
<https://www.zabbix.com/integrations/slack>
にしたがって独自アプリ作成を試していて、スコープの設定を試行錯誤するなど大変だったのですが、
一通り動作確認が終わった後に Bots でもいけるとわかって、
アプリ数を減らすことができました。

bot token も最初はグローバルマクロが使えないからプレースホルダっぽい文字列になっているのかと思っていたら、
テストの時にはグローバルマクロも含めてマクロが展開されないだけで、
通常の通知の時には使えました。
マクロにしておけばメディアタイプのエクスポートで意図せずトークンが漏洩する可能性も減らせそうです。
