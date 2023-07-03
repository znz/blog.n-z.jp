---
layout: post
title: "ruby-jpのrubotyのruboty-golfのメンテナンスをした"
date: 2023-07-03 15:30 +0900
comments: true
category: blog
tags: ruby
---
[ruby-jp Slack](https://ruby-jp.github.io/) で `ruboty list jobs` をみると `"35 * * * *" @ruboty golf set-topic codegolf` が消えていたので、追加しなおしてもうまく動いていなかったので、そのデバッグと修正をしました。

<!--more-->

## 環境

- [ruby-jp/ruboty-ruby-jp](https://github.com/ruby-jp/ruboty-ruby-jp)
- Heroku の Heroku-20 stack
- Ruby 2.7.8

## 調査

最初は `Error: #<UncaughtThrowError: uncaught throw #<ArgumentError: Required arguments :channel missing>>` と Slack の方にエラーメッセージの発言が出てきて、バックトレースもないので意味がわかりませんでした。
`"35 * * * *" @ruboty golf set-topic #codegolf` にしてみるなどの試行錯誤をしてみましたが、最後のチャンネル名の引数は `#` を省略するのが正しいようでした。

`ruboty golf list` は動いていたので、 `ruboty golf set-topic codegolf` も試してみると、
``Error: #<NoMethodError: undefined method `[]' for nil:NilClass>`` と返ってきて、
job 経由の問題ではなさそうでした。

`docker compose` を使ってローカルでもある程度試せるのですが、
Slack とのやりとり部分は
`ruboty-golf.rb` の中の `raise "Adapter must be a Ruboty::Adapters::SlackRTM" unless adapter.is_a?(Ruboty::Adapters::SlackRTM)` にひっかかって試せませんでした。

これ以上は Slack でやりとりしていてもわからないということで、
Heroku の方のログを開いて、エラーの情報がそちらに出るようにして試していました。

デバッグプリントを入れて調査した結果、
`make_channels_cache`
でチャンネル一覧が取れていないのが原因だとわかりました。

## 解決

根本的な原因としては、
`client.channels_list` などの `channels_*` の API を `conversations_*` に書き換える必要がありました。

最終的には `ruboty-channel-gacha.rb` にあったチャンネル一覧の取得を参考にして、修正できました。

さらにたまたま topic に設定する文字列が長すぎて `too_long` が返ってきていたので、
省略する処理も入れたのですが、
リンクを使っていたので、
250 文字以内になるように文字数で削ると、
`setTopic` した文字列と実際に設定される文字列が変わってしまって、
再設定しないようにする同値判定に失敗して毎回再設定されてしまったので、
行ごとに削るようにしてしまいました。

その後、 `ruboty-cron` の job での再設定もうまく動いたのを確認できました。

## まとめ

不定期に実行されるものは動かなくなっていても気付きにくく、手元での動作確認も難しいものは調査やデバッグが大変でしたが、少しずつ試して問題を解決することができました。

今回は Slack の API の変更が根本原因で動かなくなっていましたが、他にも外部要因で動いていない機能があったり、Heroku-22 Stack に更新しようとすると問題があって Heroku-20 Stack のままになっていたりするので、興味があれば ruby-jp Slack の `#ruby-jp` チャンネルなどで質問して挑戦してみてください。
必要なら Heroku の権限なども貰えると思います。
