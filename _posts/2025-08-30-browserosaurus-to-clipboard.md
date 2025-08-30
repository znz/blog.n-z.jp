---
layout: post
title: "BrowserosaurusでクリップボードにURLをコピーする"
date: 2025-08-30 15:00 +0900
comments: true
category: blog
tags: macos
---
今はデフォルトブラウザーとして
[Browserosaurus](https://github.com/will-stone/browserosaurus)
という実際にURLを開くアプリを選べるアプリを使っていて、
ブラウザーを開く変わりにクリップボードにURLを調べたことがあったので、
その方法のメモです。

<!--more-->

## 動作確認バージョン

- Browserosaurus Version 20.11.0
- Browserosaurus Version 20.12.0

この記事を書くときに
<https://github.com/will-stone/browserosaurus>
を確認したところ、

> This repository was archived by the owner on Aug 3, 2025. It is now read-only.

になっていて、
[The retirement of Browserosaurus — Will Stone](https://wstone.uk/blog/the-retirement-of-browserosaurus/)
というブログ記事へのリンクがあったので、
新しく使うなら、リンク先の記事の最後の方に書いてある別のアプリを候補にした方が良さそうです。

## クリップボードへのコピー

結論から先に書くと、
ブラウザーを選択するメニューが出ているときに、
`Command+c`
を押すとコピーできました。

ポップアップメニューの下のドメインが表示されている部分のクリックでもコピーできました。

## Browserosaurus のポリシーとか

Browserosaurus は簡単に使えるようにするため、
あらかじめソースに対応アプリ一覧が埋めこまれていて、
ユーザーが自由に対応アプリなどの設定を追加はできない、
という思想になっています。

そこで、機能を追加してもらうとしたらどんな感じだろうと思って、
ソースをながめてみると、
[Command+cでクリップボードにコピー](https://github.com/will-stone/browserosaurus/blob/5a0a8263d7f8de5fb0082e4b53f92fcbd8c7ecd1/src/main/state/middleware.action-hub.ts#L152-L154)
できるようになっていました。

記事を書きながら確認しなおしていたところ、
[URL barのクリック](https://github.com/will-stone/browserosaurus/blob/5a0a8263d7f8de5fb0082e4b53f92fcbd8c7ecd1/src/main/state/middleware.action-hub.ts#L106-L108)
でもコピーできるようになっていたので試したところ、
ポップアップメニューの下のドメインが表示されている部分のクリックでコピーできました。

## まとめ

クリップボードへのコピー方法を書いたドキュメントはみつけられませんでしたが、
ソースを確認することで機能が存在して使えることがわかりました。

以前に調べてから、記事を書くまで間が開いてしまって、
状況が変わっていて驚きました。

まだしばらくは問題なく使えそうですが、対応アプリの追加が望めなかったり、
新しい macOS で動かなくなる可能性があったりするので、
そのうち別アプリへの移行を検討したいと思いました。
