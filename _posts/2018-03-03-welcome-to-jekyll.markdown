---
layout: post
title:  "OctopressからJekyllに移行しました"
date:   2018-03-03 10:00:03 +0900
category: blog
tags: jekyll
---
octopress が 3 系列の開発は止まっているようで、Jekyll は 3 系列なら直接使っても良さそうな感じだという話をみていたので、頑張って移行することにしました。

<!--more-->

## jekyll を始める

github-pages gem は jekyll が 3.6.2 と古い (最新は 3.7.3) ことと独自ドメインで https に対応するのに、 GitHub Pages + CloudFlare よりも Netlify を使って見たかったこともあり、 jekyll gem を直接使うことにしました。

せっかくなので AMP (Accelerated Mobile Page) に対応したいと思って [Amplify for Jekyll](https://github.com/ageitgey/amplify) をテーマとして使うことにしました。

README にはられているスクリーンショットなどは履歴にいらないなと思って、 `jekyll new blog` で新規作成してから、 amplify のファイルをコピーしてはじめました。

## Rabbit Slide Show 対応

`{% raw %}{% include rabbit-slide.html author="znz" slide="slide-name" title="スライドのタイトル" %}{% endraw %}` のように include で使いまわせるようにして、 amp-iframe を埋め込むようにしました。

初期の頃は slideshare も埋め込んでいましたが、こちらはやめました。

amp-iframe は https 必須のようで、 Rabbit Slide Show はすでに https 対応していたので、 https で埋め込むように変更しました。

## 画像対応

[amp-jekyll](https://github.com/juusaw/amp-jekyll) に fastimage gem で画像サイズを自動で埋め込んでくれるフィルターがあったので、
`Gemfile` に依存する nokogiri gem と fastimage gem を追加して、
`_plugins/amp_filter.rb` にフィルターを取り込んで、
`_layouts/page.html` と `_layouts/post.html` の `{% raw %}{{content}}{% endraw %}` を `{% raw %}{{ content | amp_images }}{% endraw %}` に変更しました。

これで画像自体は、
`{% raw %}![キャプション]({{ "/assets/images/screenshot.png" | relative_url }}){% endraw %}`
で埋め込めるようになりました。

`absolute_url` だと画像サイズがとれなかったので、
`relative_url` にする必要がありそうです。

## 記事間のリンク

今までは生成されるパス決め打ちで `[タイトル](/blog/YYYY-MM-DD-title.html)` でリンクしていましたが、
`{% raw %}[タイトル]({% post_url YYYY-MM-DD-title %}){% endraw %}`
のように `post_url` を使う書き方に変えました。
