---
layout: post
title: "jekyllを4.0.1に更新してstashして途中だったダークモード対応なども反映した"
date: 2020-05-10 21:59 +0900
comments: true
category: blog
tags: jekyll
---
このブログの `bundle update` で Jekyll が 4.0.1 に上がって、
ついでに `git stash pop` してみたら変更途中だったものがみつかったので、
取り込んでみました。

<!--more-->

## 確認バージョン

- ruby 2.7.1
- jekyll 4.0.1
- jekyll-last-modified-at 1.3.0
- liquid-c 4.0.0

## 警告対応

Jekyll が 4.0.1 に上がって、
Ruby 2.7 で使うと警告がたくさん出ていたのもおさまったようなので、
[プラグインで無理やり](https://github.com/znz/blog.n-z.jp/blob/885ce8933bd14d6e26af1ddd5d76a1575923e805/_plugins/supress_warning.rb)

## jekyll-last-modified-at 削除

バージョンアップでの変更点を確認しようと思って
<https://github.com/gjtorikian/jekyll-last-modified-at>
をみてみると、
read-only になっていたので、
説明をよくみてみると、
今は `page.last_modified_at` を使えばよいということで、
`_includes/` や `_layouts/` を確認してみると、
すでに `last_modified_at` は使っていなくて `page.last_modified_at` だけだったので、
`Gemfile` や `_config.yml` から削除しました。

## ダークモード対応

コードのハイライトに solarized-light を使っていて、
solarized-dark を使えばダークモード対応が簡単にできそうと思って、
途中まで試して、最後に `pre.highlighter-rouge, code.highlighter-rouge` の `border` と `background-color` の色だけ TODO で残っていたので、
solarized-dark の `.highlight` の `background-color` を使うようにしてコミットしました。

## liquid-c 追加

jekyll 4 の pre-release 対応が stash に残っていて、
`.jekyll-cache/` を `.gitignore` などに入れるのはすでに対応済みだったので、
`liquid-c` を `Gemfile` に追加するところだけ取り込みました。

jekyll の中で `liquid-c` があれば使って高速化してくれるようです。
