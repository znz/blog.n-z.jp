---
layout: post
title: "ENV.replaceで正常に設定されずにnilになることがある"
date: 2020-10-08 21:12 +0900
comments: true
category: blog
tags: ruby
---
docs.ruby-lang.org で [snap の ruby](https://snapcraft.io/ruby) が 2.7.2 (189) にあがって、
[rdoc-static-all.service](https://github.com/ruby/docs.ruby-lang.org/blob/598859fc6ef6a844777e2053cca325a4ee9742e5/provision/systemd/rdoc-static-all.service)
が失敗していたので原因を調べました。

<!--more-->

## 環境

- Debian GNU/Linux 10 (buster)
- snap でインストールした ruby 2.7.2 (rev 189)

## 概要

`ENV.replace` の引数が長いと `nil` になってしまうことがあり、
`ENV.clear` してから `ENV.replace` を呼べば回避できました。

## 解決済みの問題

rev 187 では bundle が動いていませんでしたが、
これは rev 189 で直っています。

```
admin@docs-2020:~$ PATH=/snap/bin:$PATH
admin@docs-2020:~$ ruby -v
ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-linux]
admin@docs-2020:~$ bundle version
Traceback (most recent call last):
	2: from /snap/ruby/187/bin/bundle:23:in `<main>'
	1: from /snap/ruby/187/lib/ruby/2.7.0/rubygems.rb:296:in `activate_bin_path'
/snap/ruby/187/lib/ruby/2.7.0/rubygems.rb:277:in `find_spec_for_exe': can't find gem bundler (>= 0.a) with executable bundle (Gem::GemNotFoundException)
```

## apt の ruby の影響

apt でも ruby をインストールしていると
`/usr/lib/ruby/vendor_ruby/rubygems/defaults/operating_system.rb`
の影響で irb, rdoc, ri が動かないので、
`DEBIAN_DISABLE_RUBYGEMS_INTEGRATION` に適当な値を設定する必要があります。

```
vagrant@buster:~$ PATH=/snap/bin:$PATH irb
Traceback (most recent call last):
	2: from /snap/ruby/189/bin/irb:23:in `<main>'
	1: from /snap/ruby/189/lib/ruby/2.7.0/rubygems.rb:296:in `activate_bin_path'
/snap/ruby/189/lib/ruby/2.7.0/rubygems.rb:277:in `find_spec_for_exe': can't find gem irb (>= 0.a) with executable irb (Gem::GemNotFoundException)
vagrant@buster:~$ DEBIAN_DISABLE_RUBYGEMS_INTEGRATION=1 PATH=/snap/bin:$PATH irb <<<"puts :hello"
Switch to inspect mode.
puts :hello
hello
nil
```

## さらに調査

ここまでは再現しやすい状況なので、普通に使っていても発生する可能性があります。

しかし、
docs.ruby-lang.org で発生していた以下のエラーは別の原因で、
さらに調査を続ける必要がありました。

```
Oct 07 13:20:08 docs-2020.ruby-lang.org env[6183]: rdoc --title Documentation for Ruby master --main README.md --output /var/www/docs.ruby-lang.org/releases/20200916140300/master -U --all --encoding=UTF-8 .
Oct 07 13:20:08 docs-2020.ruby-lang.org env[6183]: <internal:gem_prelude>:1:in `require': cannot load such file -- rubygems.rb (LoadError)
Oct 07 13:20:08 docs-2020.ruby-lang.org env[6183]:         from <internal:gem_prelude>:1:in `<internal:gem_prelude>'
Oct 07 13:20:08 docs-2020.ruby-lang.org env[6183]: rake aborted!
```

## 調査続行

色々調べていると RUBYLIB が違いで rubygems がみつからないということがわかり、
どこで変わっているのか調べてみると、
`bundle exec` でのプロセス起動時までは正常で、
起動された ruby の初期化処理のどこかで変になってそうだとわかりました。

```
vagrant@buster:~$ mkdir /tmp/t
vagrant@buster:~$ cd /tmp/t
vagrant@buster:/tmp/t$ bundle init
Writing new Gemfile to /tmp/t/Gemfile
vagrant@buster:/tmp/t$ DEBIAN_DISABLE_RUBYGEMS_INTEGRATION=1 PATH=/snap/bin:$PATH bundle exec printenv RUBYLIB
/snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4/lib:/snap/ruby/189/lib/ruby/2.7.0:/snap/ruby/189/lib/ruby/2.7.0/amd64
vagrant@buster:/tmp/t$ DEBIAN_DISABLE_RUBYGEMS_INTEGRATION=1 PATH=/snap/bin:$PATH bundle exec ruby -e 'puts ENV["RUBYLIB"]'
/snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4/lib
```

## 調査用コードでの調査

調べるのに使っていたコードの残骸は以下のような感じです。

`/tmp/tr.rb` に置いて書き換えつつ、
元の `RUBYOPT=-r/snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4/lib/bundler/setup` を置き換えるように
`env PATH=/var/www/docs.ruby-lang.org/shared/bundle/ruby/2.7.0/bin:/snap/bin:$PATH DEBIAN_DISABLE_RUBYGEMS_INTEGRATION=1 bundle exec env -u RUBYOPT ruby -r/tmp/tr -r/snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4/lib/bundler/setup -e 'p ENV["RUBYLIB"]'`
で試していました。

このコードになるまでの流れとしては、
`grep -r RUBYLIB /snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4`
から `RUBYLIB` が変化している可能性がありそうな場所の前後にデバッグプリントを入れて、
`ENV["RUBYLIB"]` が `nil` になっているとわかったので、
`ENV` の `[]=` や `delete` を置き換えて削除している場所がないか探して、
みつからなかったので、
`TracePoint` で `ENV` のほとんどのメソッド呼び出しを一覧してみて、
`replace` があやしそうと目星をつけて、
`replace` も置き換えて、ここが原因だと発見しました。

```ruby
class << ENV
  alias orig_setter []=
  def []=(k, v)
    puts 'ENV[]=', caller if k == "RUBYLIB"
    orig_setter(k, v)
  end

  alias orig_delete delete
  def delete(k)
    puts 'ENV.delete:', caller if k == "RUBYLIB"
    orig_delete(k)
  end

  alias orig_replace replace
  def replace(h)
    p(replace_RUBYLIB: h["RUBYLIB"])
    #puts 'ENV.replace:', h, caller
    ret = orig_replace(h)
    p(replace_RUBYLIB: h["RUBYLIB"])
    p(ENV_RUBYLIB: ENV["RUBYLIB"])
    ret
  end
end

trace = TracePoint.new(:c_call) do |tp|
  if tp.self == ENV && tp.method_id == :replace
    p tp
  end
end
#trace.enable
require '/snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4/lib/bundler/shared_helpers'
#trace.disable
p(ENV_RUBYLIB: ENV["RUBYLIB"])

require '/snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4/lib/bundler'

module Bundler
  module SharedHelpers
    def set_rubylib
p(ENV_RUBYLIB: ENV["RUBYLIB"])
      rubylib = (ENV["RUBYLIB"] || "").split(File::PATH_SEPARATOR)
p(rubylib: rubylib, bundler_ruby_lib: bundler_ruby_lib)
      rubylib.unshift bundler_ruby_lib unless RbConfig::CONFIG["rubylibdir"] == bundler_ruby_lib
p(rubylib: rubylib)
      Bundler::SharedHelpers.set_env "RUBYLIB", rubylib.uniq.join(File::PATH_SEPARATOR)
    end
  end
end
```

## 最小化

`/tmp/dump.rb` として以下のように最小化してバグ報告に使いました。

```ruby
class << ENV
  alias orig_replace replace
  def replace(h)
    p ENV
    p h
    orig_replace(h)
  end
end
```

`ENV` と `h` の `"RUBYLIB"` に対応する値はそれぞれ
`"/snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4/lib:/snap/ruby/189/lib/ruby/2.7.0:/snap/ruby/189/lib/ruby/2.7.0/amd64"`
と
`"/snap/ruby/189/lib/ruby/2.7.0:/snap/ruby/189/lib/ruby/2.7.0/amd64:/snap/ruby/189/lib/ruby/gems/2.7.0/gems/bundler-2.1.4/lib:/snap/ruby/189/lib/ruby/2.7.0:/snap/ruby/189/lib/ruby/2.7.0/amd64"`
でした。

## ワークアラウンド

`/tmp/clear-before-replace.rb` として以下のように `ENV.clear` してから `replace` すれば回避できることを確認しました。

```ruby
class << ENV
  alias orig_replace replace
  def replace(h)
    clear
    orig_replace(h)
  end
end
```

## バグ報告

[Bug #17254 ENV.replace may set nil instead of the proper value](https://bugs.ruby-lang.org/issues/17254)
として報告しておきました。

## docs にはワークアラウンド追加

docs.ruby-lang.org には、
[DEBIAN_DISABLE_RUBYGEMS_INTEGRATION=true の追加](https://github.com/ruby/docs.ruby-lang.org/commit/a045a214a37560d7a1a69d91987e07e4008d0b58)
と
[env-clear-before-replace.rb の追加](https://github.com/ruby/docs.ruby-lang.org/commit/ad1451cfa6d3b3ffbddc4be60b90a5cd6a81c12f)
をしました。
