---
layout: post
title: "ruby開発版に右代入演算子とendなしメソッド定義が入った"
date: 2020-04-10 23:59 +0900
comments: true
category: blog
tags: ruby
---
ruby の開発版に実験的機能として右代入演算子と `end` なしでメソッド定義できる機能が入りました。

<!--more-->

## 試し方

rbenv + ruby-build を使っているのなら
[ruby-build の wiki](https://github.com/rbenv/ruby-build/wiki)
を参考にしてビルドに必要なパッケージをインストールしてから、
`rbenv install 2.8.0-dev`
でインストールして、
`rbenv shell 2.8.0-dev`
などで切り替えれば試せます。

## 右代入演算子

[R-assign (rightward-assignment) operator](https://bugs.ruby-lang.org/issues/15921)
で議論されていて、実装も可能だったということで入りました。

[開発者会議](https://bugs.ruby-lang.org/issues/16693)では `=>` でいいのかということで、
演算子の候補を考えている時間があったのですが、
Hash の `=>` を知らない人もいるのでは、というのを聞いて、
そういう人は `rescue` の `=>` なら知ってそう、
という感じのことを言ったら、
すでに右代入で使われていたということで、右代入演算子が `=>` で入りました。

`var = val` と `val => var` がほぼ同じということで、
`[]=` や多重代入などもできるようです。

```
% ruby -e 'Hash.new => h; "one" => h[1]; %w[two three] => h[2], h[3]; p h'
{1=>"one", 2=>"two", 3=>"three"}
```

`[1,2] => a,` や `[1,2] => a,*` のような多重代入は行が継続していると解釈されるので、
`[1,2] => a,*_` のようにする必要がありそうです。

ちなみに ruby 2.7 ではパターンマッチの短縮形の `expr in pat` を使って
右代入っぽいことはできますが、返り値を使うことはできません。

```
% ruby -e 'Hash.new in h; p h'
-e:1: warning: Pattern matching is experimental, and the behavior may change in future versions of Ruby!
{}
% ruby -e 'if Hash.new in h; end'
-e:1: warning: Pattern matching is experimental, and the behavior may change in future versions of Ruby!
-e:1: void value expression
if Hash.new in h; end
```

メソッドの引数部分では以下のような解釈になるようです。

```
m a => b  # -> m(**{a => b}) # unchanged
m(a => b) # -> m(**{a => b}) # unchanged
m((a => b)) # -> m((b = a))  # 2.7 SyntaxError
m (a => b)  # -> m((b = a))  # 2.7 SyntaxError
```

## `end` なしメソッド定義

[Endless method definition](https://bugs.ruby-lang.org/issues/16746)
はエイプリルフールネタとして作られたチケットだったようですが、
議論の末、 `def foo(a) = expression` という記法が実験的機能として導入されました。
個人的には Scala っぽいと思ったのですが、提案者も matz も特に scala のことは意識していなかったようです。
(影響を受けていた可能性はあります。)

`define_method` と違って `def` なのでスコープは別のままで、
`private def foo(a) = expression` のような使い方もできるようです。

空のメソッド定義 (`def foo;end`) は `def foo = nil` とか `def foo = ()` のように明示的に `nil` を返す式を書くことになるようです。

`foo=` メソッドの定義という解釈が優先されるため、
`def foo=expression` だと `end` なしメソッド定義だとは解釈されないので、
`def foo =expression` や ``def foo()=expression` のように書く必要がありそうです。

setter を `def foo=(x)=@x=x*2` のように書けるようになりそうです。

右代入と組み合わせるとどうなるのか試してみたら、現状だと
`def foo=(x)=((x*2)=>@x)`
と括弧をつける必要がありました。

## 感想

実験的機能なので、この時期に入れてみて様子をみるということで、12月までには最終的に次のバージョンに入るかどうか決まります。
気になる人は積極的に試してフィードバックすると良さそうです。
