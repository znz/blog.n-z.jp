---
layout: post
title: "ast-grepでgemspecのhomepageなどを書き換えた"
date: 2024-05-11 16:30 +0900
comments: true
category: blog
tags: ruby
---
ruby-gnome2 関連の gem で osdn.jp 終了の関係で rubygems.org からの URL がリンク切れになっていて、
いい感じに書き換える方法を検討して、
ast-grep を使ってみました。

<!--more-->

## 動作確認環境

- macOS Sonoma 14.4.1
- homebrew で入れた ast-grep 0.22.0
- homebrew で入れた sd 1.0.0

## コマンドラインのみで挑戦

最初に `--pattern` と `--rewrite` で試してみましたが、
桁揃えのためのスペースが消えてしまって、
期待していた文字列リテラルだけの置き換えができませんでした。

```console
% ast-grep --pattern 's.homepage = "https://ruby-gnome2.osdn.jp/"' --rewrite 's.homepage = "https://ruby-gnome.github.io/"' | head
./goffice/goffice.gemspec
@@ -23,7 +23,7 @@
24 24│   s.description   = "Ruby/GOFFICE is a Ruby binding of GOFFICE."
25 25│   s.author        = "The Ruby-GNOME Project Team"
26 26│   s.email         = "ruby-gnome2-devel-en@lists.sourceforge.net"
27   │-  s.homepage      = "https://ruby-gnome2.osdn.jp/"
   27│+  s.homepage = "https://ruby-gnome.github.io/"
28 28│   s.licenses      = ["LGPL-2.1+"]
29 29│   s.version       = ruby_glib2_version
30 30│   s.extensions    = ["dependency-check/Rakefile"]
```

## YAML ファイルを用意して挑戦

このような YAML ファイルで一部だけ書き換えに挑戦してみました。
`inside` で指定した中にあるところだけ書き換えできました。

```yaml
id: replace-homepage
language: ruby
rule:
  pattern: '"https://ruby-gnome2.osdn.jp/"'
  inside:
    pattern: 's.homepage = $URL'
fix: '"https://ruby-gnome.github.io/"'
```

`ast-grep scan -r YAMLファイル 対象ファイル` で試してみたところ、
うまくいっていたので、
`ast-grep scan -r ../homepage.yml -U`
で書き換えを実行しました。

```console
% ast-grep scan -r ../homepage.yml glib2/glib2.gemspec
glib2/glib2.gemspec
help[replace-homepage]:
@@ -26,7 +26,7 @@
27 27│     "many useful utility features."
28 28│   s.author        = "The Ruby-GNOME Project Team"
29 29│   s.email         = "ruby-gnome2-devel-en@lists.sourceforge.net"
30   │-  s.homepage      = "https://ruby-gnome2.osdn.jp/"
   30│+  s.homepage      = "https://ruby-gnome.github.io/"
31 31│   s.licenses      = ["LGPL-2.1+"]
32 32│   s.version       = ruby_glib2_version
33 33│   s.extensions    = ["ext/#{s.name}/extconf.rb"]
```

## 他の箇所も書き換え

他のファイルで `@homepage` への代入も書き換えても大丈夫そうだったので、
対象に追加しました。
[any](https://ast-grep.github.io/guide/rule-config/composite-rule.html#any) を使うと複数パターンの `OR` にできました。

```yaml
id: replace-homepage
language: ruby
rule:
  pattern: '"https://ruby-gnome2.osdn.jp/"'
  inside:
    any:
    - pattern: 's.homepage = $URL'
    - pattern: '@homepage = $URL'
fix: '"https://ruby-gnome.github.io/"'
```

## Markdown ファイルは sd で書き換え

ast-grep は Markdown ファイルには対応していないようで、
対象を確認してみたところ、単純な書き換えだけで大丈夫そうだったので、
sd コマンドで書き換えました。
拡張子のない README ファイルも同様でした。

```console
% find . -name '*.md' | xargs sd -s https://ruby-gnome2.osdn.jp/ https://ruby-gnome.github.io/
% find . -name 'README' | xargs sd -s https://ruby-gnome2.osdn.jp/ https://ruby-gnome.github.io/
```

## まとめ

<https://github.com/ruby-gnome/ruby-gnome/issues/1611> の報告から時間がたってしまいましたが、
手作業での変更ではなく、コマンドを使って間違いにくい方法で書き換えて
<https://github.com/ruby-gnome/ruby-gnome/pull/1615> を作成することができました。
