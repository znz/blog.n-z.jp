---
layout: post
title: "git-secretsを使ってデバッグプリントの混入を防ぐ"
date: 2020-03-08 10:30 +0900
comments: true
category: blog
tags: git
---
[git-secrets](https://github.com/awslabs/git-secrets) という AWS の鍵などのコミットを防ぐ用途に使われているものがあるのですが、
その設定にデバッグプリントも入れてみて、忘れた頃に引っかかってうまくいっているので、設定例を紹介します。

<!--more-->

## 動作確認環境

- git version 2.20.1 (Apple Git-117)
- homebrew で入れた git-secrets 1.3.0

## git-secrets インストール

公式サイトなどを参考にしてインストールして初期設定しておきます。

## 追加設定

rails アプリで以下のように設定しています。

```
git secrets --add --literal STDERR.puts
git secrets --add --literal tmp/page
git secrets --add '<%=\s*debug'
git secrets --add --allow '<%=\s*debug.*if'
git secrets --add --literal 'NOCOMMIT'
```

`--literal` 指定で追加することで正規表現のエスケープを気にせずに、
その文字列自体があると引っかかるようにできます。

デバッグプリントを入れるときに `STDERR.puts` をよく使っているので、それがひっかかるようにしています。
`tmp/page` は capybara でスクリーンショットを撮って調べたいときの保存場所に使っています。

次の2行は ERB でのデバッグプリントが引っかかるようにしています。
スペースにマッチするような書き方が難しくて、色々試した結果、この正規表現にした覚えがあります。
`if` がある場合を許容しているのは、 `if Rails.env.development?` のように開発環境のみなら残っていてもいいことがあると判断したからです。

最後の `NOCOMMIT` は完全に手動でコミットしたくない一時的な変更に印をつけたいときに使っています。
印としては何でもいいのですが、
git-secrets を設定していないときにはコミットできてしまうので、
そういう時でも意味不明な文字列にならない、かつ、
普通のコードでは出てこない文字列にする必要がありそうです。

## それでもコミットしたい時

`git commit --no-verify` のように `--no-verify` で hook を実行しなければコミットできます。

`--no-verify` は、
他の hook も無視してコミットしてしまうということなので、
いつも以上にコミット内容のチェックをした方が良さそうです。

## まとめ

git-secrets を使ってデバッグプリントの混入を防ぐ例を紹介しました。

特定の文字列を防ぐ hook なら、自分で書いてもそんなに大変ではないのですが、
git-secrets というよく使われているものを利用した方がバグも少なそうで良さそうと思って採用しました。

狙ったパターンにマッチするかどうかの確認は自作するにしても git-secrets を使うにしても必要なので、
そこの手間は軽減できませんでしたが、
hook の作成にかかる手間は軽減できました。
