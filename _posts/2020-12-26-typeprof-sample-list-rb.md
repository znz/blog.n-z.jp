---
layout: post
title: "typeprofでsample/list.rbのバグを発見した話"
date: 2020-12-26 21:30 +0900
comments: true
category: blog
tags: ruby
---
先週、 Ruby 3.0.0 リリース前に typeprof をちょっと試してみようと思って sample のファイルで試していたらバグをみつけたので直したときの話です。

<!--more-->

## 確認バージョン

- ruby 3.0.0
- typeprof 0.11.0

リリース後の今日、再実行して確認しなおしているため、確認バージョンはリリースされたものになります。
実際にバグを発見したときのバージョンは先週のものになります。

## rbs の自動生成

型情報の rbs を自動生成するツールとして、
`rbs prototype rb`, `rbs prototype runtime`, `typeprof`
があって、一通り試していたのですが、
その中で実行時間が長い代わりに 3 つの中では一番詳細な解析をしてくれる `typeprof` を試したときにバグをみつけました。

## sample のファイル

[ruby の sample](https://github.com/ruby/ruby/tree/master/sample) にはいくつかのサンプルプログラムがあるのですが、
そのファイルの中で `class` 定義をして使っているだけのサンプルは少なく、適当に試した中で良い感じになったのは `list.rb` だけでした。

## 変更前の list.rb

[変更前の list.rb](https://github.com/ruby/ruby/blob/a45972f2a89d4b8c2b6c346a547140e8c3a4218d/sample/list.rb)
の全体を引用すると以下の内容です。

```ruby
# Linked list example
class MyElem
  # object initializer called from Class#new
  def initialize(item)
    # @variables are instance variable, no declaration needed
    @data = item
    @succ = nil
    @head = nil
  end

  def data
    @data
  end

  def succ
    @succ
  end

  # the method invoked by ``obj.data = val''
  def succ=(new)
    @succ = new
  end
end

class MyList
  def add_to_list(obj)
    elt = MyElem.new(obj)
    if @head
      @tail.succ = elt
    else
      @head = elt
    end
    @tail = elt
  end

  def each
    elt = @head
    while elt
      yield elt
      elt = elt.succ
    end
  end

  # the method to convert object into string.
  # redefining this will affect print.
  def to_s
    str = "<MyList:\n";
    for elt in self
      # short form of ``str = str + elt.data.to_s + "\n"''
      str += elt.data.to_s + "\n"
    end
    str += ">"
    str
  end
end

class Point
  def initialize(x, y)
    @x = x; @y = y
    self
  end

  def to_s
    sprintf("%d@%d", @x, @y)
  end
end

# global variable name starts with `$'.
$list1 = MyList.new
$list1.add_to_list(10)
$list1.add_to_list(20)
$list1.add_to_list(Point.new(2, 3))
$list1.add_to_list(Point.new(4, 5))
$list2 = MyList.new
$list2.add_to_list(20)
$list2.add_to_list(Point.new(4, 5))
$list2.add_to_list($list1)

# parenthesises around method arguments can be omitted unless ambiguous.
print "list1:\n", $list1, "\n"
print "list2:\n", $list2, "\n"
```

## 修正前の typeprof sample/list.rb

`typeprof sample/list.rb` の実行結果は以下のようになりました。

```console
$ typeprof sample/list.rb
# Global variables
$list1: MyList
$list2: MyList

# Classes
class MyElem
  @data: Integer | MyList | Point
  @succ: MyElem?
  @head: nil

  def initialize: (Integer | MyList | Point item) -> nil
  def data: -> (Integer | MyList | Point)
  def succ: -> MyElem?
  def succ=: (MyElem new) -> MyElem
end

class MyList
  @head: MyElem
  @tail: MyElem

  def add_to_list: (Integer | MyList | Point obj) -> MyElem
  def each: ?{ (MyElem) -> String } -> nil
  def to_s: -> String
end

class Point
  @x: Integer
  @y: Integer

  def initialize: (Integer x, Integer y) -> Point
  def to_s: -> String
end
```

よく見ると `@head: nil` が常に `nil` なので、不要そうに見えます。
さらにソースコードの方もよく見ると `MyList#add_to_list` の `if @head` で `@head` が偽になる可能性を考慮しているようなので、
`@head: MyElem` も常に真になるので変に見えます。

## 修正

初期化の `@head = nil` の場所が間違っていたように見えたので、
[diff](https://github.com/ruby/ruby/commit/144b11e03ee0994cacd3fa5eb9ff8b87bd627452#diff-18742388a7babfd1b13259fe5dbe222c27c77e696233876a4ba3d85c5c379b2e)
のように `MyList#initialize` に移動するように修正しました。

```diff
diff --git a/sample/list.rb b/sample/list.rb
index b4d1d653e4..7458ba0244 100644
--- a/sample/list.rb
+++ b/sample/list.rb
@@ -5,7 +5,6 @@ def initialize(item)
     # @variables are instance variable, no declaration needed
     @data = item
     @succ = nil
-    @head = nil
   end

   def data
@@ -23,6 +22,10 @@ def succ=(new)
 end

 class MyList
+  def initialize
+    @head = nil
+  end
+
   def add_to_list(obj)
     elt = MyElem.new(obj)
     if @head
```

## 修正後の typeprof sample/list.rb

`MyElem` から `@head: nil` が消えて、
`MyList` の `@head` が `MyElem?` になって、
`nil` になる可能性が増えています。

```console
% typeprof sample/list.rb
# Global variables
$list1: MyList
$list2: MyList

# Classes
class MyElem
  @data: Integer | MyList | Point
  @succ: MyElem?

  def initialize: (Integer | MyList | Point item) -> nil
  def data: -> (Integer | MyList | Point)
  def succ: -> MyElem?
  def succ=: (MyElem new) -> MyElem
end

class MyList
  @head: MyElem?
  @tail: MyElem

  def initialize: -> nil
  def add_to_list: (Integer | MyList | Point obj) -> MyElem
  def each: ?{ (MyElem) -> String } -> nil
  def to_s: -> String
end

class Point
  @x: Integer
  @y: Integer

  def initialize: (Integer x, Integer y) -> Point
  def to_s: -> String
end
```

## 感想

コミットメッセージには 2.7 で確認しなおして、
「Fix `warning: instance variable @head not initialized` and remove unused instance variable」
と書いてしまいましたが、経緯としては `typeprof` でバグを発見して修正したという話でした。

Ruby 3.0.0 ではインスタンス変数未初期化の警告は出なくなってしまいましたが、
型解析で代用できる部分があるかもしれません。

まだ型周りは色々と話を聞いたりちょっと試したりしているだけで良くわかっていないので、
もう少し実用しているプログラムでも試していきたいと思っています。
