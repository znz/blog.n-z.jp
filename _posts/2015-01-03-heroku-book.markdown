---
layout: post
title: "heroku本を読んだ"
date: 2015-01-03 16:58:56 +0900
comments: true
category: blog
tags: book heroku
---
[プロフェッショナルのための 実践Heroku入門 プラットフォーム・クラウドを活用したアプリケーション開発と運用 (書籍)](http://amzn.to/2CXcdgi)
を読んだので、そのメモです。

<!--more-->

内容としては heroku をまだ使ったことない人には特におすすめで、使ったことがある人にもどういう思想で作られているのかなど参考になるのでおすすめだと思いました。
特に最後の The Twelve Factor App の翻訳は heroku に限らず参考になると思いました。

## メモ

- ceder → cedar (全般的に)
- p.47 rubyforge はもう終了しているのでダウンロードできなさそう。
- p.49 `brew --prefix readline` と `brew --prefix openssl` の周りに `$( )` が抜けている?
- p.55 gem install するのは bundle よりも bundler の方が良さそう。
- p.60 下から4行目 Frameowk → Framework
- p.69 下から2行目 PostgresSQL → PostgreSQL
- p.70 `(後述)` とあるが既に説明済み?
- p.79 webtype → web type
- p.79 `jobs:worK` → `jobs:work` ? (2カ所)
- p.91 newrelick → newrelic
- p.92 MG → MB ? (3カ所)
- p.101 sandobox → sandbox ?
- p.135 ctext 型をの → citext 型を
- p.159 注7 の URL がパスしかない

<div class="amazon">
{% include amazon.html src="https://rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=znz-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=4048915134&linkId=213982e551a13bf97b95f846a6a1edc1" %}
</div>
