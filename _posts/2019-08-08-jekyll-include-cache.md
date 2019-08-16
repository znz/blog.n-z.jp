---
layout: post
title: "jekyll-include-cacheを使ってbuild速度を改善した"
date: 2019-08-08 21:45 +0900
comments: true
category: blog
tags: jekyll
---
[ruby-jp slack](https://ruby-jp.github.io/)
というところで
「最新の Jekyll 4.0.0.pre.alpha1 を使うとビルド時間が爆速になります」という話があったので、
そのリンク先を参考にして試してみたところ、
jekyll-include-cache を使うのが一番効果がありました。

<!--more-->

## 参考情報

- [Reduce 71.6% of building time by using Jekyll 4.0.0](https://github.com/yasslab/yasslab.jp/pull/123)
- [Help us benchmark Jekyll - Share - Jekyll Talk](https://talk.jekyllrb.com/t/help-us-benchmark-jekyll/1629)
- [How I reduced my Jekyll build time by 61% \| Forestry.io](https://forestry.io/blog/how-i-reduced-my-jekyll-build-time-by-61/) (この記事をみながら試しました)

## 確認環境

- jekyll 3.8.5
- jekyll-include-cache 0.2.0

## profile 結果観察

途中の試行錯誤はあまり重要ではないので省略して、
`bundle exec jekyll build --profile`
の結果をみて `_includes/head.html` が何度も読み込まれている上に重そうだったので、
中身を眺めていると、
`scssify` というフィルターが重そうと気づいて、とりあえず外してビルドしてみたところ、
約 130 秒かかっていたビルド時間が十数秒になったので、
ここがボトルネックだと判明しました。

## jekyll-include-cache 導入

最終的には
[Use jekyll-include-cache](https://github.com/znz/blog.n-z.jp/commit/ba1a093965f6cc9037308b074b5c9bf5b88c7de7)
のように `style amp-custom` タグ全体を別ファイルにして `include_cached` で読み込むようにしたところ、
ビルド時間が約 35 秒になりました。

## まとめ

このブログのテーマは
[Amplify for Jekyll](https://github.com/ageitgey/amplify)
ベースなのですが、
同様に `scssify` を使っていたり、
たくさんのページで使いまわしているのに生成が重い部品を使っていたりする jekyll を使っているサイトのビルド速度の改善に参考になるかもしれません。
