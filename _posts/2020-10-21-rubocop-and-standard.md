---
layout: post
title: "rubocopコマンドでstandard gemベースの設定を使う"
date: 2020-10-21 23:30 +0900
comments: true
category: blog
tags: ruby rubocop
---
rubocop gem の設定を調整するのが大変だと思っていたので、
standard gem の設定を元にすることにしました。
`standardrb` コマンドは今回は使いませんでした。

<!--more-->

## 動作確認バージョン

- ruby 2.6.6
- [rubocop](https://rubygems.org/gems/rubocop) 1.0.0
- [standard](https://rubygems.org/gems/standard) 1.0.0
- rubocop-rails 2.8.1

1.0.0 は今日リリースされていました。

## 基本設定

[RuboCoping with legacy: Bring your Ruby code up to Standard — Martian Chronicles, Evil Martians’ team blog](https://evilmartians.com/chronicles/rubocoping-with-legacy-bring-your-ruby-code-up-to-standard)
を参考にすると最低限の設定は、以下のようになりそうです。

```yaml
inherit_mode:
  merge:
  - Exclude

require:
- rubocop-performance
- standard/cop/semantic_blocks

inherit_gem:
  standard: config/base.yml
```

`inherit_mode` はなくても良さそうですが、後で使うために付けています。

## rubocop デフォルトとの主な違い

`Style/StringLiterals` と `Layout/SpaceInsideHashLiteralBraces` のデフォルトの違いが一番影響がありそうです。

rubocop のデフォルトの方に合わせるなら、
<https://docs.rubocop.org/rubocop/cops_style.html#stylestringliterals> などを参考にして、
以下の設定を追加すれば良さそうです。

```yaml
Style/StringLiteralsInInterpolation:
  EnforcedStyle: single_quotes

Layout/SpaceInsideHashLiteralBraces:
  EnforcedStyle: space
```

standard gem の設定は `inherit_gem` を見ればわかるように、
<https://github.com/testdouble/standard/blob/master/config/base.yml>
にあるので、迷う設定はこのファイルと rubocop のドキュメントを見比べて考えることになりそうです。

## TargetRubyVersion

standard gem の設定だと `AllCops` に `TargetRubyVersion: 2.5` が入っていて、
`.ruby-version` をみてくれない、というのも注意が必要そうです。

## rubocop-rails

すべての rubocop-rails の cop を有効にするには、以下の設定の追加が必要でした。

```yaml
require:
# ...
- rubocop-rails

AllCops:
  # ...
  NewCops: enable

Rails:
  Enabled: yes
```

## 全体例

今回は小さい rails アプリで試して、
rubocop のデフォルトから standard のデフォルトに全部切り替えることにしたので、
個別の設定調整なしで以下のようにしてみました。

```yaml
inherit_mode:
  merge:
  - Exclude

require:
- rubocop-performance
- rubocop-rails
- standard/cop/semantic_blocks

inherit_gem:
  standard: config/base.yml

AllCops:
  TargetRubyVersion: 2.6
  Exclude:
  - 'bin/*'
  - 'config/initializers/simple_form*.rb'
  - 'db/schema.rb'
  NewCops: enable

Rails:
  Enabled: yes
```

## 他 cop

standard gem の設定だと無効になっている cop も多いので、
余裕があれば、 Rails のように department まるごと enable にして試すと良さそうです。

例えば Style をまとめて有効にするには以下のようになります。

```yaml
Style:
  Enabled: yes
```


## 最後に

rubocop のすべての cop を有効にすると大変なので、
standard gem の設定を使う方法を紹介しました。

`standardrb` コマンドだとコマンドの使い方も実行したときの出力も違っていて、
そこまで一気に切り替えて慣れるのは大変そうだったので、
rubocop のまま standard gem ベースの設定を使うようにしました。

rubocop-rails などの他の gem の設定を追加するのも `standardrb` だと
追加で調べる必要がありそうなのも、避ける理由になりました。
