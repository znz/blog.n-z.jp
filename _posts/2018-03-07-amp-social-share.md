---
layout: post
title: "amp-social-shareを設定した"
date: 2018-03-07 21:30 +0900
comments: true
category: blog
tags: jekyll amp
---
Jekyll + AMP への移行の続きとして、シェアボタンを設置しました。

<!--more-->

## amp-social-share

amp-social-share とは、このサイトだと下の Share on の横にある 60×44 のサイズのボタンです。
(Share on 自体は Amplify テーマにあった twitter に共有するリンクになっています。)

管理の手間を省くために、
octopress の時はシェア用に Zenback をつけていましたが、
AMP への対応状況がわからなかったので、
AMP 自体が対応している amp-social-share に置き換えました。

## Pre-configured providers

まず
[amp-social-share – AMP](https://www.ampproject.org/docs/reference/components/amp-social-share)
の Pre-configured providers のうち、
data-param-app_id が必須でそのままだと動かない facebook 以外すべてを追加してみました。

一番左の system は OS の共有ダイアログがでてくるものらしく、
PC だとボタン自体が表示されませんでした。

次の email はメーラーが開きました。

その他はそれぞれのサイトが開くようです。

SMS は macOS だと「メッセージ」アプリを開こうとするようです。

## Non-configured providers

その他のサイトも追加できるということで、
[＜amp-social-share＞ - ソーシャルシェアボタンを設置する \| AMPのタグリファレンス](https://syncer.jp/Web/AMP/Component/amp-social-share/)
を参考にして、
はてなブックマークと pocket と LINE を追加してみました。

参考にしたサイトの background-image はうまくいかなかったので、
pocket は font awesome のアイコンを使いました。
LINE は font awesome 5 ならアイコンがあるのですが、
AMP が 5 に対応していない
([:bug: Add new Font Awseome URL format, fixes #13770 and #13685](https://github.com/ampproject/amphtml/pull/13773)
がマージされているので対応していてドキュメントが追いついていないだけかと思って試したら、
使えなかった)
ようなので、
はてなブックマークと同様に文字でごまかしています。
(試した結果はブランチに残しているので、対応されたらマージする予定です。)
