---
layout: post
title: "macOSのEmacs 26.1で絵文字が表示できるようになった😄"
date: 2018-07-18 23:24 +0900
comments: true
category: blog
tags: osx emacs
---
[emacs-jp/issuesで質問してみたら](https://github.com/emacs-jp/issues/issues/33)、
[QiitaのEmacsで絵文字を表示するの記事](https://qiita.com/tadsan/items/a67b28dd02bf819f3f4e)の人に Symbola のインストールは必要と教えてもらえて、
表示できなかった問題は解決しました。

<!--more-->

## 確認環境

- macOS High Sierra 10.13.6
- Emacs 26.1
- Symbola v.11.00

## フォントのインストール

[Unicode Fonts for Ancient Scripts](http://users.teilar.gr/%7Eg1951d/) から
Symbola をダウンロードして展開して出てきた
`Symbola.ttf` と `Symbola_Hinted.ttf` を `~/Library/Fonts` に入れました。

## 入力は変なことがある?

スマイル(☺️)は問題なく入力も表示もできました。

iTerm2 の中で入力した絵文字(😄)をコピーして使うのは問題なくできるのですが、
macOS 標準の日本語入力 (今はことえりじゃなかったはず) で入力しようとすると 0xD83D と 0xDE04 になってしまって入力できませんでした。
コードポイントから考えて、サロゲートペアの扱いがおかしい感じです。

## まとめ

Symbola フォントのインストールだけで Emacs 側は何もしなくても絵文字が表示できるようになりました。
BMP 外の絵文字については入力に問題がありそうですが、
とりあえず GitHub の通知メールで絵文字部分が謎の空白になる問題は解決したので
よかったです。
