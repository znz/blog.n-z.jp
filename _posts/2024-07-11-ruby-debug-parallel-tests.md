---
layout: post
title: "parallel_tests gemでのrspec実行のランダムな失敗をdebug gemで調査した"
date: 2024-07-11 09:59 +0900
comments: true
category: blog
tags: ruby
---
`parallel_tests` gem の `parallel_rspec` コマンドを使ったテストで、ランダムに失敗するという現象が出ていて、
一部だけ実行しても失敗しなかったり、全体を実行しても失敗の場所がバラバラだったりして、
デバッグプリントを入れるのも難しかったので、失敗したときに debug gem で調査しました。

<!--more-->

## 対象バージョン

- Ruby 3.2.4
- parallel_tests 4.7.1
- rspec-core 3.13.0
- debug 1.9.2

## binding.break に挑戦 (失敗)

ランダムに失敗するので、失敗するときに発生する例外を調べてみたところ、
`RSpec::Expectations::ExpectationNotMetError`  でした。
それを `TracePoint` でみつけて `binding.break` すればいいかと思って試してみたところ、うまくいきませんでした。

確認用に `RuntimeError` で実験してみたところ、
`tp.binding.break` はすぐに返ってきて `p` で `binding` の `inspect` が表示されて、
`rdbg --attach --port=10000` で確認すると `sleep` の行が実行中でした。
(`sleep` がないとすぐ終わってしまうので attach するタイミングをつくるために入れました。)

```ruby
require 'debug/session'
::DEBUGGER__.open_tcp host: nil, port: 10000, nonstop: true
TracePoint.trace(:raise) do |tp|
  case tp.raised_exception
  when RuntimeError
    p tp.binding.break
    sleep 10
  end
end
raise "foo"
```

## .rdbgrc で catch

`TracePoint` と debug gem は相性が悪そうということで、
ちゃんと debug gem の機能を使うことにしました。

ためしに `~/.rdbgrc` に以下のように書くとうまくいきました。

```text
catch RuntimeError
```

## コードに埋め込み

しかし、テスト対象の環境は docker コンテナで、毎回ファイルを作成するのは面倒なので、
Ruby のコード中でできないか探してみたところ、
`.rdbgrc` の内容は最終的に
<https://github.com/ruby/debug/blob/8abc50acba3d079aec8107c60ecae8a0285413ac/lib/debug/session.rb#L374>
の `add_preset_commands` で実行しているようだったので、
直接このメソッドを呼ぶことにしました。

その結果、最低限の rspec 環境ではこれを `spec/spec_helper.rb` に書くとうまくいきました。

```ruby
require 'debug/session'
::DEBUGGER__.open_tcp host: nil, port: 10000+ENV.fetch('TEST_ENV_NUMBER', '').to_i, nonstop: true
::DEBUGGER__::SESSION.add_preset_commands __FILE__, <<'COMMANDS'.lines # inline ~/.rdbgrc
catch RSpec::Expectations::ExpectationNotMetError
COMMANDS
```

<https://st0012.dev/ruby-debug-cheatsheet> によると `binding.b(do: "catch StandardError")` というのがあったので、
これに書き換えました。

実際のテスト対象の環境では `config/initializers/` に置いてみたら、他の処理が失敗したので、
spring gem のガードを追加して、最終的には以下になりました。

```ruby
unless ENV.fetch('DISABLE_SPRING', '0') != '1'
  require 'debug/session'
  ::DEBUGGER__.open_tcp host: nil, port: 10000+ENV.fetch('TEST_ENV_NUMBER', '').to_i, nonstop: true
  binding.b(do: 'catch RSpec::Expectations::ExpectationNotMetError')
end
```

そして、
`docker compose exec app env DISABLE_SPRING=1 RAILS_EAGER_LOAD=1 RUBYOPT='-W:deprecated' bundle exec parallel_rspec -n 4 --test-options="--seed $RANDOM --fail-fast"`
のように実行して、止まったところで
`bundle exec rdbg --attach --port 10000`
などでアタッチして調査しました。

`--test-options` の方に `--fail-fast` はつけても大丈夫でしたが、
`parallel_rspec` の方にも `--fail-fast` をつけると attach する前に終了してしまってうまくいきませんでした。

## socket を使った理由

`parallel_tests` は複数プロセスで同時実行していて、
tty が使いにくかったり、出力は親プロセスでキャプチャしていて対話環境に使えなかったりしたので、
socket 接続を使いました。

複数同時待受するのに、Unix Domain Socket のパスを考えるよりポート番号をずらす方が楽そうだったので、


ポート番号は適当に 10000 からにしましたが、ローカルだけなので他と重ならなければ何番でも良さそうです。
`parallel_tests` 環境なので、重ならないように `TEST_ENV_NUMBER` を足しています。

## まとめ

`spec/spec_helper.rb` などに以下のようなコードを追加すると失敗時にデバッガで調査できることがわかりました。

```ruby
require 'debug/session'
::DEBUGGER__.open_tcp host: nil, port: 10000+ENV.fetch('TEST_ENV_NUMBER', '').to_i, nonstop: true
binding.b(do: 'catch RSpec::Expectations::ExpectationNotMetError')
```

実際に止まる場所は自分の spec の中ではなく、
rspec の中なので非常にわかりにくいですが、
再現性が微妙なときにはそんなことも言っていられないので、
頑張って `up` や `frame` で移動して `info` などのコマンドや `p` メソッドを使って調査しました。
