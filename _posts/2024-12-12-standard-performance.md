---
layout: post
title: "rubocopコマンドで使うstandard gemベースの設定を更新した"
date: 2024-12-12 19:00 +0900
comments: true
category: blog
tags: ruby rubocop
---
[rubocopコマンドでstandard gemベースの設定を使う]({% post_url 2020-10-21-rubocop-and-standard %}) で設定した内容から、
いつの間にか変更が必要になっていたので、設定を更新しました。

<!--more-->

## 動作確認バージョン

- ruby 3.2.6
- rubocop 1.68.0
- standard 1.42.1
- standard-custom 1.0.2
- standard-performance 1.5.0

## 差分

最初に差分をのせておきます。

`require:` の `standard/cop/block_single_line_braces` を `standard-custom` に変更しています。

`inherit_gem:` に `standard-custom: config/base.yml` と `standard-performance: config/base.yml` を足しています。

```diff
diff --git a/.rubocop.yml b/.rubocop.yml
index 59563e0..da89d44 100644
--- a/.rubocop.yml
+++ b/.rubocop.yml
@@ -6,10 +6,12 @@ require:
 - rubocop-performance
 - rubocop-rails
 - rubocop-capybara
-- standard/cop/block_single_line_braces
+- standard-custom

 inherit_gem:
   standard: config/base.yml
+  standard-custom: config/base.yml
+  standard-performance: config/base.yml

 AllCops:
   Exclude:
```

## きっかけ

仕事で関わっている rails アプリで `.github/dependabot.yml` に

```yaml
  allow:
  - dependency-type: all
```

を追加したところ、 `standard-performance` gem の更新の pull request も作成されていて、
気になって調べたところ、
Performance の cop が `rubocop-performance` gem に分離された影響で Performance department の設定が `standard-performance` gem に分離されているようでした。

`standard/cop/block_single_line_braces` として `standard` gem に同梱されていた独自 cop がいつの間にか `standard-custom` gem に分離されていました。

## 最小設定

現状で新規設定するなら必要なものは以下のようになりそうです。

```yaml
require:
  - rubocop-performance
  - standard-custom

inherit_gem:
  standard: config/base.yml
  standard-custom: config/base.yml
  standard-performance: config/base.yml
```

他の設定については、
[以前の記事]({% post_url 2020-10-21-rubocop-and-standard %})
を参考にしてください。

## 最後に

`standard` gem を直接使わずに `rubocop` 経由で設定だけ使うということをしているので、
`standard` gem の変更もある程度追いかけておく必要がありそうでした。
