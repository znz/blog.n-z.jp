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

## 過去記事の移行

最低限の表示確認ができたところで、現在の blog.n-z.jp の記事を取り込みはじめました。

## カテゴリーからタグへの変更

カテゴリーは URL に使われるため、
`categories: foo bar` を `category: blog` と `tags: foo bar` に変更して、
URL が今まで通り `/blog/YYYY-MM-DD.html` になるように変更しました。

`ruby -pi -e 'sub(/^categories:/, "category: blog\ntags:")' _posts/*.markdown`
のように一括変換しました。

## URL 直書きのリンク

`http://example.com/` のように直接書いていてもリンクになっていたものが、リンクにならなくなったので、
`<http://example.com/>` のように `<>` でくくるようにしました。

## `|` 対応

箇条書きの中のリンクのテキストに `|` が入っているとテーブルになってしまうことがあるようで、
`\|` に書き換える必要がありました。

逆に今まで table が使えなくて無理やり他の表現を使っていたものを table に書き換えることができました。

## エスケープ追加

octopress だとコードブロックの中は `{{ "{{" }}` が自動でエスケープされてそのまま書けましたが、
jekyll 直接だと自動でエスケープされないので、
`{{ "{%" }} raw %}` と `{{ "{%" }} endraw %}`
を追加する必要がありました。

[octopress で ansible の記事を書く時のエスケープ]({% post_url 2014-05-20-octopress-ansible %}) の方法もそのまま使えました。

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

`{% raw %}ruby -pi -e 'sub(%r(/blog/(\d+-\d+-\d+-.+?)\.html), "{% post_url \\1 %}")' _posts/*.markdown{% endraw %}`
のように一括変換しました。

## タグクラウド

jekyll-tagging gem を使って、タグごとのページの生成と `_layouts/post.html` の post-meta の中に tags の追加をしました。
gem を入れればデフォルトで良い感じにしてくれるわけではなく、
layout などは自分でなんとかする必要がありました。

URL が `/blog/categories/タグ` から `/tag/タグ.html` に変わってしまうので、
[Jekyll + Netlify でのリダイレクト](https://qiita.com/gatespace/items/accb418239a45834d529) などを参考にして、
`_redirects` ファイルを用意しました。

## アマゾンへのリンク

アフィリエイトはあまり効果がないので、基本的には書影目的にアマゾンアソシエイトの iframe を埋め込んでいたのですが、
amp-iframe のファーストビューの領域の75%よりも下、または最上部から600pxより下という制限にひっかかって、
読書会のエントリーの最初に対象の書籍を埋め込んでいたのがエラーになったので、
iframe から `_includes/amazon.html` の amp-iframe に変更すると共に末尾に移動しました。

## gist 埋め込み

gist は jekyll-gist ではなく、
amp-gist を使うことでうまく埋め込めました。
