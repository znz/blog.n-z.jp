---
layout: post
title: "rdoc と Netlify で静的サイト作成"
date: 2018-05-09 22:30 +0900
comments: true
category: blog
tags: netlify ruby
---
[Some links broken in README](https://bugs.ruby-lang.org/issues/14743)用のデモサイトとして、
rdoc で生成した結果を普通のサイトとして公開したかったので、
<https://github.com/ruby/docs.ruby-lang.org> を参考にして
Netlify を使って構築してみました。
(GitHub Pages だと任意のビルドコマンドが使えなさそうだったため、Netlify を選択)

<!--more-->

## 対象バージョン

- ruby 2.5.1 (.ruby-version や Gemfile で固定していないので Netlify 上では違うかも)
- rdoc 6.0.4

## Gemfile 作成

`bundle init` で雛形を作成して、
`gem "rdoc"` に変更して、
`bundle update` しました。

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gem "rdoc"
```

## Rakefile 作成

<https://github.com/ruby/docs.ruby-lang.org> の Rakefile や `RDoc::Task` のドキュメントを参考にして、
最低限の内容で作成しました。

```ruby
# frozen_string_literal: true

require "rdoc/task"

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
end

task default: :rdoc
```

これで `rake` や `rake rdoc` や `rake rerdoc` や `rake clobber_rdoc` が使えるようになりました。

## ドキュメント作成

`.document` と `README.md` などを作成しました。
`.document` でファイルを制限しないと `Gemfile` なども含まれてしまいました。

## GitHub に push

GitHub にレポジトリを作成して push しました。

## Netlify でビルド

連携先として GitHub からレポジトリを選んで、
ビルドコマンドとして `rake` を指定して、
公開するディレクトリは `html` を指定しました。

それから、デフォルトだとドメインがランダム生成された文字列になっているので、変更しました。

## まとめ

rdoc で普通のサイトを作ることはあまりなさそうですが、
gem のドキュメントとかで rdoc で生成した HTML を公開したい場合などで
Netlify との組み合わせが向いている場合があるかもしれません。
