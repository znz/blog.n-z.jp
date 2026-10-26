---
layout: post
title: "Ruby で任意のユーザー入力を渡してはいけないメソッド"
date: 2026-10-09 11:00 +0900
comments: true
category: blog
tags: ruby
---
[「Ruby」の正規表現エンジン「Onigmo」にリモートコード実行の問題、セキュリティ更新を実施 - 窓の杜](https://forest.watch.impress.co.jp/docs/news/2150800.html)
のように Ruby 本体としては、そこに任意のユーザー入力を渡しているのはプログラム側の問題で Ruby 本体の脆弱性としては扱わない、
という方針になっているメソッドがあるので、思い付く限り列挙してみます。

<!--more-->

## eval 系

当然 `eval` は任意のコードを実行するためのものなので、外部入力を含む任意のユーザー入力を渡すようなものではありません。
`class_eval`, `module_eval`, `instance_eval` などの他の類似メソッドも同様です。

## system 系

`system` や `` Kernel#` `` や `spawn` などの外部コマンドを実行するメソッドに任意の入力を渡すとシェルコマンドインジェクションが可能になります。

Ruby 本体の機能ではありませんが、SQL も同様に直接外部入力を渡すと SQL インジェクションが可能になります。

## send 系

`send` や `public_send` なども任意のメソッドが呼び出せると引数の数に制限があっても、組み合わせ次第で任意コードの実行に繋がることがあります。

## Marshal 系

### Marshal.load

色々な方法で任意コードを実行する方法が発見され、仕組み的に根本的な解決は難しいとされています。
内部で `Marshal` を使う dRuby をそのままインターネット上に公開してはいけない理由でもあります。

### YAML.unsafe_load

YAML で昔の `load` が `unsafe_load` になり、名前からわかる通り信頼できない入力を渡すには危険なので、新しい `load` か `safe_load` を使います。

### JSON.load

[Security/JSONLoad](https://docs.rubocop.org/rubocop/latest/cops_security.html#securityjsonload) によると、
JSON は `JSON.parse` か `JSON.unsafe_load` を使うか、`create_addition:` を明示して `JSON.load` を使うと良さそうです。

## Regexp.new 系

`Regexp.new` や `Regexp.complie` や `/#{input}/` などで正規表現の一部として任意のユーザー入力を使うのは、
普通のプログラムではすべきではなく、
プログラム側の問題として Ruby 本体では脆弱性としては扱わないとしているようです。

2026-10-26 追記:
そらはさんが
[I personally oppose that 'compiling an untrusted pattern is unsupported usage of Regexp engine bundled to Ruby', except of DoS. But this isn't the case, it's not well documented, and is against the common sense to expect risk of memory corruption and RCE](https://x.com/sora_h/status/2113542482978087027)
と言っているように、正規表現エンジンで任意のパターンで DoS というのは DFA じゃない正規表現エンジンだとそういうものとして認識されてそうですが (`Regexp.linear_time?` や `Regexp.timeout` で緩和さているとはいえ)、
RCE は正規表現エンジンで想定できるリスクではないという考えもあるようです。
(Ruby 本体としては通常バグとして修正がリリースされているので、修正を影響のある脆弱性と受けとるかどうかは、CVE の有無に関わらずプロダクトごとに判断する必要があります。CVE はただの識別子なので、緊急対応する必要がないものも大量にあるのは普通のことです。)

## IO 系

### IO.read 系

[Security/IoMethods](https://docs.rubocop.org/rubocop/latest/cops_security.html#securityiomethods)
のように `|` で始まる文字列で任意コマンドが実行可能になるので危険です。

### File.read 系

任意コマンド実行ではないですが、 `|` が使えない `File.read` 系でも任意のファイルが読めて危険です。

### open-uri の open

関連して `open-uri` の `open` を使っていた場合の書き換え先としては `URI.open` になっていますが、
明確に URI だけ受け付けたい場合は `URI#open` に書き換える方が好みです。
(どこまで安全かは確認していません。)

```console
%  ruby -r open-uri -e 'URI.open("/etc/hosts"){}'
%  ruby -r open-uri -e 'URI("/etc/hosts").open{}'
-e:1:in '<main>': private method 'open' called for an instance of URI::Generic (NoMethodError)
```

## 番外編: ホスト名

任意の URL を入力して何か情報を返すサービスがあって、制限をしていないと、
たとえば自宅サーバーで動かして 192.168.0.1 の URL でルーターの情報を返してしまったり、
EC2 で動かしていて 169.254.169.254 の URL で EC2 のメタデータを返してしまったりする可能性が考えられます。

IP アドレス直接だけ塞いでも `169-254-169-254.nip.io` などの任意の FQDN で対象の IP アドレスを設定すればいいので、
普通の DNS 問い合わせを許可している限りホスト名レベルでの完全な対策は不可能です。

AI 時代で攻撃側はこういう対象は簡単に発見できそうなのに、防御側は何年も前から気にしていても未だに解決できていないことがあります。

隠しておくことによる防御が有効な時代ではなくなっているようなので、隠しておいた方が安全そうだと思っていた情報のうち、公開可能なものは機会をみて公開していこうと思っています。

## まとめ

Ruby には信頼できない任意のユーザー入力を想定していないメソッドがあります。
昔は (たぶん Perl 由来の) `taint` フラグや (Ruby 独自の) `untrust` フラグで対処しようとしていましたが、不十分だったのでフラグ自体が消えました。
安全でないユーザー入力を渡しているかどうかは、ちゃんと自分で管理する必要があるので、渡してしまわないように気をつけましょう。
