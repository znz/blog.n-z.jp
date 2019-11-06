---
layout: post
title: "macOS CatalinaでHomebrew Caskで入れたEmacsにフルディスクアクセス権限がきかない"
date: 2019-11-06 19:00 +0900
comments: true
category: blog
tags: osx emacs
---
[ruby-jp Slack](https://ruby-jp.github.io/) の emacs チャンネルで Catalina だと Downloads などが `dired` で開けないという話があって、
自分の環境も同じだったので調べてみました。

<!--more-->

## 環境

- macOS Catalina 10.15.1
- Homebrew Cask で入れた GNU Emacs 26.3 (<https://emacsformacosx.com/> で配布されているバイナリと同じはず)

## 状況

起動時に `~/.Trash` にアクセスできないとエラーが出ていたり、 `~/Downloads/` や `~/Documents/` などのディレクトリや中のファイルが開けなかったりしました。

## 効果がなかった対処

これだけでは効果がなかっただけで、後の対処と組み合わせで必要なものがあるかもしれません。

- フルディスクアクセス権限を `/Applications/Emacs.app` に許可
- <https://gist.github.com/dive/f64c645a9086afce8e5dd2590071dbf9> の `fix-emacs-permissions-catalina.el` を実行
- どこかのタイミングで出てきた (File - Open File... のタイミング?) `ruby` も許可 (あとで確認してみるとフルディスクアクセス権限かと思っていたらアクセシビリティが許可されていました)

## 対処

<https://gist.github.com/dive/f64c645a9086afce8e5dd2590071dbf9#gistcomment-3049065> に書いてあるように

- メニューの File - Open File... (`ns-open-file-using-panel`) で出てくるダイアログから `~/Downloads/dummy.txt` などのエラーメッセージに出てくるディレクトリ直下のファイルを開く

という操作をすると `dired` でも `find-file` でも開けるようになりました。

コメントにも書いてありますが、ダイアログから開くファイルが `~/Documents/somedir/somefile` のようなサブディレクトリの中のファイルだと `~/Documents/` が `dired` で開けないままでした。

直下にファイルがなくてサブディレクトリしかない場合は `touch ~/Pictures/Photos\ Library.photoslibrary/dummy.txt` のように作成して開いて消しました。

## その他の情報

MacPorts 版などの自前ビルドでは大丈夫という話もあるようです。

根本的な原因はよくわかりませんが、
許可できたのを許可されていない状態に戻す方法もわからないし、
`~/Library/*/` の中はバラバラに許可を求められて、許可していくのが大変だったので、
詳しく調査する予定はありません。
