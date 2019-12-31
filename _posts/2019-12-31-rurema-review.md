---
layout: post
title: "るりまレビュー会 2019-12-31 に参加しました"
date: 2019-12-31 23:31 +0900
comments: true
category: blog
tags: ruby rurema
---
鹿児島Ruby会議01の懇親会での話をきっかけに始めたオンラインでの「るりまレビュー会」の今年最後の回が終わったので振り返りです。

<!--more-->

## きっかけ

<https://github.com/rurema/doctree> を中心に <https://github.com/rurema/bitclust> や <https://github.com/ruby/docs.ruby-lang.org> も関連するのですが、 issue や pull request が溜まっているのでなんとかしたいと思っていたという背景がありました。

鹿児島Ruby会議01の懇親会で pocke さんとそのあたりの話になって、日程を調整してみたところ、毎週火曜の夜が良さそうということになって、
最終的に20時から1時間ぐらいにやってみることになりました。

## 初回

最初は手探りで zoom.us でつなぎつつ [ruby-jp Slack](https://ruby-jp.github.io/) の `#rurema` チャンネルでどれをみていこうかというアンケートをやってみて、
bitclust の方からみていって、
doctree の pull request をちょっと見始めたあたりで終わりました。

## 2回目

そろそろオープンに募集すれば良さそうということで、
connpass で次回のイベントをたてることから始めました。

残りの時間はもくもく会的に issue や pull request を処理していたと思います。

## 3回目以降

このあたりからは zoom.us は繋いでいてもほぼ使わず、発言はほぼ Slack の方だけになって、
引き続きもくもく会的に issue や pull request を処理していったり、
手をつけるにはちょっと時間がかかりそうなものは issue に書いたりするようになっていきました。

## 5回目 (本日)

docs.ruby-lang.org の root 権限を sudo で使えるようにしてもらったので、
[Redirect /trunk to /master](https://github.com/ruby/docs.ruby-lang.org/issues/82)
の対応をしていました。

先に関連する変更として ja/master も追加したり、その内容の 2.8.0 も生成するようにしたりしていました。

[rdoc のセキュリティアップデートの pull request](https://github.com/ruby/docs.ruby-lang.org/pull/88) があったので
マージしてみたところ、 `bundle exec cap production deploy` が失敗してしまったので
[Revert してしまった](https://github.com/ruby/docs.ruby-lang.org/commit/e246d606cd496d88d8f4f6ad81b583310efa262f)
のがちょっと心残りです。

## 終わりに

hanachin さんと pocke さんはそれぞれのブログに何をやっていたか公開しているようなので、
私も公開するようにしていこうと思って、とりあえず今までの大雑把な流れを書いておきました。
