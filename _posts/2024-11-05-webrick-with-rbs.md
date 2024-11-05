---
layout: post
title: "RBS入りのWEBrick gemをリリースした"
date: 2024-11-05 12:00 +0900
comments: true
category: blog
tags: ruby rbs
---
[WEBrick](https://rubygems.org/gems/webrick) 1.9.0 として RBS による型情報つきの gem をリリースできたので、そのメモです。

<!--more-->

## バージョン

動作確認に使ったバージョンはこのあたりでした。

- ruby 3.3.5
- rbs 3.6.1
- steep 1.8.3
- webrick 1.8.2 → 1.9.0

## 使い方

`rbs_collection.yaml` がなければ `rbs collection init` で作成するなどして用意しておいて、以下のように `gems` に `- name: webrick` を追加して、
`rbs collection install` や `rbs collection update` を実行すると、
`rbs_collection.lock.yaml` が更新されて steep などで型情報が使えるようになりました。

```yaml
gems:
  - name: webrick
```

`rbs_collection.lock.yaml` には以下のように `source.type: rubygems` で追加されていました。

```yaml
- name: webrick
  version: 1.9.0
  source:
    type: rubygems
```

ffi 1.17.0 は
<https://github.com/ffi/ffi/issues/1107>
の問題があるので、
以下のように `name: ffi` に `ignore: true` を設定したものを `gems:` に追加しています。

```yaml
gems:
  - name: webrick
  - name: ffi
    ignore: true # https://github.com/ffi/ffi/issues/1107
```

## 現状の型情報

typeprof で生成された <https://github.com/ruby/webrick/pull/115> やソースコードを参考にしつつ、
`rbs prototype rb` で生成した `*.rbs` を更新する方法で、
<https://github.com/ruby/webrick/pull/151> として追加しました。

2週間ぐらいかけて一通りざっと対応しただけなので、
まだ <https://github.com/ruby/webrick/pull/155> のように間違っている部分や
考慮不足で使いにくい部分もあると思うので、改善案などあれば pull request や issue を
作成してもらえると良さそうです。

## 型付け中にひっかかった部分

### singleton(ClassName)

例外クラスの指定のようにクラスオブジェクト自体が引数になるときは、
`singleton(ClassName)` のように `singleton` を使う、
というのが知らないと難しそうだった。

```rbs
def self.register: (Numeric seconds, singleton(Exception) exception) -> Integer
```

### const_set で定義されている定数

`webrick/httpstatus` `const_set` されている定数は以下で補ったので、
VSCode に Steep 拡張機能を入れているときに `WEBrick::HTTPStatus::RC_OK: 200` などがホバーで確認できたり、補完がきいたりして便利です。

```ruby
require 'webrick'

puts WEBrick::HTTPStatus::constants.grep(/\ARC_/).map{"#{_1}: #{WEBrick::HTTPStatus.const_get(_1)}"}

puts WEBrick::HTTPStatus::CodeToError.each_value.map{"class #{_1.name.split(/::/).last} < #{_1.superclass.name.split(/::/).last}\nend"}
```

### method alias chain されているメソッド

```text
Non-overloading method definition of `parse` in `::WEBrick::HTTPRequest` cannot be duplicated(RBS::DuplicatedMethodDefinition)
```

は `https.rbs` に重複定義があったので、 `| ...` を追加して、

```rbs
    alias orig_parse parse

    def parse: (?(TCPSocket | OpenSSL::SSL::SSLSocket)? socket) -> void
             | ...
```

のように定義して回避しました。

`orig_parse` に再定義前の型が保存されているわけではなく、
再定義した `parse` と同じ型になってしまうようなので、
厳密には `alias` ではなく `def orig_parse: 元の型` にした方が良さそうでしたが、
直接使うメソッドではないと思って、そこはがんばらずに自動生成されたままにしました。


### いろいろな body

`webrick/httpresponse` は `body` に悩んで、コメントの

```ruby
    # Body may be:
    # * a String;
    # * an IO-like object that responds to +#read+ and +#readpartial+;
    # * a Proc-like object that responds to +#call+.
```

を参考にして、

```rbs
    interface _CallableBody
      def call: (_Writer) -> void
    end

    attr_accessor body: String | _ReaderPartial | _CallableBody
```

にしました。

`#read` は呼ばれていなかったので、 `_Reader & _ReaderPartial` ではなく `_ReaderPartial` だけにしました。

書き込みは `write` のみだったので、 `socket` の型は `_Writer` にしました。

### `=` つきメソッド

`=` つきのメソッドの返り値でちょっと悩んでしまいましたが、他の RBS ファイルを確認すると右辺の値の型をそのまま書くようだったので、そうしておきました。

### singleton

`set_redirect` は `singleton` を使って Redirect 系の例外クラスならどれでも受け付けるように

```rbs
    def set_redirect: (singleton(WEBrick::HTTPStatus::Redirect) status, URI::Generic | String url) -> bot
```

にしました。

### read_body

`IO?` 型が渡せなくなるらしいという話があったので、 `IO socket` を `IO? socket` に変更した方がいいかもしれないと思ったのですが、
返り値も `String?` になってしまうので、とりあえずそのままにしました。
実用上問題があれば、ユースケースと一緒に pull request を作ってほしいです。

最初は `void block` にしていたのですが `void` は返り値以外で書ける位置が制限されているらしいので `top` に変更しました。

```rbs
    def read_body: (IO socket, body_chunk_block block) -> String
                 | (nil socket, top block) -> nil
```

### Servlet の config や options の問題

`AbstractServlet` は `@config` が `HTTPServer` で `FileHandler` は `Hash[Symbol, untyped]` で困ったので、

```rbs
    class AbstractServlet
      @server: HTTPServer

      interface _Config
        def []: (Symbol) -> untyped
      end

      @config: _Config
```

にしました。

`@options` も `AbstractServlet` は `Array[untyped]` で `FileHandler` は `Hash[Symbol, untyped]` なので、
`AbstractServlet` の方は `untyped` にしました。

### 返り値の型

`do_GET` などが `AbstractServlet` は `-> bot` で `FileHandler` で `-> void` にしたのは型エラーにはならなかったので、継承で返り値がこのように変わるのは大丈夫のようです。

### Enumerable の型

`rbs prototype rb` で自動生成されただけの `cgi.rbs` に型エラーがあると思って確認すると、こんな感じで `include Enumerable[untyped]` になっていないからでした。

```console
% cat a.rb
class C
  include Enumerable

  def each
    yield nil
  end
end
% rbs prototype rb a.rb
class C
  include Enumerable

  def each: () { (untyped) -> untyped } -> untyped
end
```

`rbs prototype rb` は対応していなくて、
`typeprof` なら対応してそうでした。
`rbs prototype` には `rbs prototype runtime` もあるらしく、そちらなら対応しているらしいです。

### 位置引数でも &block でも受けとる場合の型

`webrick/httpserver.rbs` で

```ruby
    def mount_proc(dir, proc=nil, &block)
      proc ||= block
      raise HTTPServerError, "must pass a proc or block" unless proc
      mount(dir, HTTPServlet::ProcHandler.new(proc))
    end
```

に対応する型として、

```rbs
    def mount_proc: (String dir, ?HTTPServlet::ProcHandler::_Callable proc) -> void
                  | (String dir, ?nil proc) { (HTTPRequest, HTTPResponse) -> void } -> void
```

としてみました。

## 型付け後からリリースまでにひっかかった部分

確認のしやすさの都合で、
`bitclust` の型付け作業をしている作業ディレクトリで
webrick の rbs も作成していました。

そこから `ruby/webrick` にコピーして pull request を作成しました。

その前に手元で `rake build` して `rake install:local` して動作確認していました。

その結果、 `manifest.yaml` は `gemspec` と同じトップではなく `sig/manifest.yaml` に置く必要があるとわかりました。

リリースされる gem に rbs ファイルを含めるには `webrick.gemspec` で `sig/**/*.rbs` などを `s.files` に追加する必要がありました。

`stringio` を `manifest.yaml` に入れるとエラーになって困ったので調べてみると、
<https://github.com/ruby/rbs/tree/master/core> にあったので、
`core` のライブラリは不要なのかも、と思って書かなかったらエラーが消えました。
`require` が必要なのに `stringio` が `core` に入っているのは分類ミスのようなので、
そのうち移動するかもしれないようです。

直接のリリース権限はないので、他の標準添付から分離されたり、されつつある gem と同じように
<https://github.com/ruby/webrick/blob/master/.github/workflows/push_gem.yml>
が追加されて、タグの push でリリースができました。

最後の `Create GitHub release` の `GITHUB_TOKEN` の secrets の設定ミスがあったらしく、
タグを消して push しなおしたら、gem のリリースの方でリリース済みバージョンということでそこまで進まなかったので、
今回だけ `gh release create v1.9.0 --verify-tag --generate-notes` は手元で実行しました。

## そもそもの経緯

RBS による型付け作業を開始した [bitclust](https://github.com/rurema/bitclust) が webrick にも依存していて、
webrick の使っている部分だけ型付けをしてエラーがでないようにしていました。

しばらくして bitclust の型付けである程度ノウハウがたまったので、
webrick の型がちゃんとついている方が良さそうと思ったので、
bitclust 自体の作業を中断して、 webrick の方を一気に対応しました。

## 最後に

webrick は production 環境では使うべきでない、というものなので、一般公開用のサーバーとして使うことはないと思いますが、
限定された環境でのサーバーやソースコードを読む対象としてはまだまだ使われることがあると思うので、
機会があれば webrick の rbs を有効利用してみてください。
