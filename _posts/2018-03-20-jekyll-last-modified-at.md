---
layout: post
title: "jekyll-last-modified-at を使うようにした"
date: 2018-03-20 23:05 +0900
comments: true
category: blog
tags: jekyll
---
sitemap.xml で lastmod が YAML front matter の date で指定した日時になっていて、
追記などをしたときに更新されないのが気になったので、
調べてみると
[jekyll-last-modified-at](https://rubygems.org/gems/jekyll-last-modified-at)
というプラグインがあったので使ってみることにしました。

<!--more-->

## 対象バージョン

- jekyll (3.7.3)
- jekyll-sitemap (1.2.0)
- jekyll-last-modified-at (1.0.1)

## 仕組み

[lib/jekyll-last-modified-at/determinator.rb](https://github.com/gjtorikian/jekyll-last-modified-at/blob/f1f3c18416efb25b8629617a84db37ef8b777306/lib/jekyll-last-modified-at/determinator.rb)
をみると、
ソースファイルの git の commit 日時を調べて、
なければソースファイルの mtime を使う、
という仕組みになっているようです。

## Gemfile 追加

`Gemfile` に
`gem 'jekyll-last-modified-at', group: :jekyll_plugins`
を追加して `bundle update` しました。

## _config.yml 設定

`plugins:` に `- jekyll-last-modified-at` を追加しました。
追加しなくても動いているようでしたが、念のため追加しました。

sitemap.xml 生成の時にエラーになったので、
以下の設定も入れて、
sitemap.xml からタグのページを隠していましたが、
別の方法で解決したので、設定は消して、
sitemap.xml にタグのページは入るように戻しました。
(`path: "tag/"` の状態でコミットしていましたが、きいていませんでした。)

```yaml
defaults:
- scope:
    path: "tag"
  values:
    sitemap: false
```

## metadata.json 対応

[dateModified を `page.date` から `page.last_modified_at` に変更](https://github.com/znz/blog.n-z.jp/commit/b98c4ebff6708d86a3df5c0a0b444d5619d4cbce#diff-3f407869149199117e619e461f6d1db3)しました。

## Last modified at: 追加

[`_layouts/post.html` に追加](https://github.com/znz/blog.n-z.jp/commit/b98c4ebff6708d86a3df5c0a0b444d5619d4cbce#diff-663f387b6a1a407ab38de055a12bc7c8)しました。

## 一部ページで設定しない

jekyll-tagging のページで
`Liquid Exception: No such file or directory - .../blog.n-z.jp/tag/event/index.html does not exist! in /_layouts/default.html`
のようなエラーになるので、
以下のように `page_path` をみて last modified を追加しないようにしました。

トップや jekyll-paginate のページも index.md の commit 日時になってしまうので、
みにいかないようにしました。

<p class="filename">_plugins/skip_last_modified_at.rb:</p>

```ruby
# frozen_string_literal: true

require 'jekyll-last-modified-at/determinator'

module SkipLastModifiedAt
  def last_modified_at_time
    return if page_path == 'index.html' # jekyll-paginate
    return if %r!\Atag/! =~ page_path # jekyll-tagging
    super
  end
end
class Jekyll::LastModifiedAt::Determinator
  prepend SkipLastModifiedAt
end
```
