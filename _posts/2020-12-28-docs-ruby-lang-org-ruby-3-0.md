---
layout: post
title: "docs.ruby-lang.orgのruby 3.0対応"
date: 2020-12-28 18:39 +0900
comments: true
category: blog
tags: ruby
---
Ruby 3.0.0 がリリースされた影響で[docs.ruby-lang.org](https://docs.ruby-lang.org/)のシステム側でいくつか対応が必要でした。
その対応が一通り終わったので、そのメモです。

<!--more-->

## 主なソースコード

- <https://github.com/ruby/docs.ruby-lang.org>
- <https://github.com/ruby/rurema-search>
- <https://github.com/rurema/bitclust>
- <https://github.com/rurema/doctree>
- <https://github.com/ruby/snap.ruby>

## docs.ruby-lang.org の生成対象更新

まず最初に
[Bump version to 3.0.0](https://github.com/ruby/docs.ruby-lang.org/commit/360bff5327c527270a9ef228cea25f1bf68ed541)
で [/en/3.0.0/](https://docs.ruby-lang.org/en/3.0.0/) と [/ja/3.0.0/](https://docs.ruby-lang.org/ja/3.0.0/) が増えました。

マージ後に `cap production deploy` で反映する必要がありました。

## snap.ruby の更新の影響反映

次に [snap の ruby](https://snapcraft.io/ruby) が 3.0.0 になって、
[`cannot snap-exec: cannot exec "/snap/ruby/200/bin/bundle": permission denied`](https://github.com/ruby/snap.ruby/issues/23)
というエラーで更新が失敗していたので報告して対応してもらって、
ssh で入って `bundle` コマンドを直接実行するとエラーになるのを誤報告してしまったので、
`.bashrc` にも

```
PATH=/snap/bin:$PATH
export DEBIAN_DISABLE_RUBYGEMS_INTEGRATION=true
```

を追加して、確認しやすくしておきました。

英語ドキュメントの生成は、それでも gem がなくて `LoadError` になるので、
`cap production deploy` しなおすと
`sudo systemctl start rdoc-static-all.service` で
英語ドキュメントの生成はできるようになりました。

## webrick の unbundle 対応

snap の ruby の更新の影響で、日本語ドキュメントの生成がこけるようになっていました。

調べてみると webrick が ruby 本体の配布に入らなくなった影響で bitclust の中で `require` している部分がこけるようになってしまったので、
[Add webrick dependency](https://github.com/rurema/bitclust/commit/7294bb17532dae206ba91506d56a2ae8a5af4ab7)
をマージ後に `cap production deploy` してみても解決せず、
[Do not require WEBrick on top level](https://github.com/rurema/bitclust/commit/0301375c20eb8c81fd7820c9b08af4f64a0b94fa)
のように必要になってから `require` するように変更したところ、
`sudo systemctl start bc-setup-all.service` で
日本語ドキュメントの生成ができるようになりました。

progressbar gem への依存もあるはずなのに、と思って
[使っているところ](https://github.com/rurema/bitclust/blob/35aabd6daa5d1096470f308f292a1e73e3636c11/lib/bitclust/progress_bar.rb)
をみてみると、なければ別の処理に切り替わるようになっていました。

## るりまサーチ対応

さらに、るりまサーチの方は `cap production deploy` しなおしても、
`rexml/document` の `LoadError` で動かなかったので、
最新なら直っているかもと思って、
<https://github.com/clear-code/rurema-search>
の master をマージしてみたのですが、
それでも直らなかったので、
[`Gemfile` に `rexml` を追加](https://github.com/ruby/rurema-search/commit/0456a7364e94877aefea1ae098d7d1b3e83a740a)
して解決しました。

`rexml` は 2.7 では default gem で `Gemfile` に書いていなくても使えたのですが、
3.0 では bundled gem になって、
`Gemfile` に書いていないと使えなくなった影響を受けていたようです。

## 手元での bundle install 時の問題

`Gemfile.lock` を更新するために macOS Catalina 10.15.7 側で `bundle install` すると

```
Call.c:334:5: error: implicit declaration of function 'rb_thread_call_without_gvl' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
```

で `ffi` gem のインストールに失敗しました。

これは
[古いRuby環境と古いRailsを動かすのにすこしハマった](https://qiita.com/Masato-I/items/6bafab572afc7cef2108)
を参考にして、

```
bundle config build.ffi '-- --with-cflags="-Wno-error=implicit-function-declaration"'
```

と設定することで回避できました。

同様のエラーが出る gem があれば、 `build.ffi` の `ffi` の部分を変更して設定していくことになりそうです。

手元だと ruby 3.0.0 を使うと `nokogiri` と `rroonga` のインストールに失敗したので、
ruby 2.6.6 (+ bundler 2.1.4) を使ったのですが、
`cap production deploy` で特に問題は起きなかったので、
Linux 環境だと大丈夫なのかもしれません。

## さらに修正

`sudo systemctl start update-rurema-index.service`
で問題なく更新できることを確認していたのですが、
ブラウザーから確認してみると、検索結果表示がエラーになっていて、
`/var/log/nginx/error.log` をみると

```
App 26140 output: Error: The application encountered the following error: cannot load such file -- bundler/setup (LoadError)
App 26140 output:     /usr/lib/ruby/2.5.0/rubygems/core_ext/kernel_require.rb:59:in `require'
(以下略)
```

のようにでていて、
Passenger ではシステム側の ruby 2.5 が使われていて、
rurema-search の deploy 時に snap の ruby を使うのが間違いだったとわかりました。

そこで、
[snap ruby を使うのをやめて](https://github.com/ruby/rurema-search/commit/127eb01f47c5a21ebe8730ca57c546c5bf2bb7a0)、
細かい調整も重ねて `cap production deploy` をすると検索結果の表示もなおりました。

この ruby のバージョンを戻した影響で rexml の追加は不要になっていましたが、
将来必要になるということで、そのままにしておきました。

## 感想

`vagrant` での動作確認環境があって `capistrano` での deploy である程度確認しやすくなっているのですが、
deploy するためには `git push` しておく必要があるなどのローカルのみでの変更の確認は不便な点がありました。

また snap ruby と system ruby のどっちを使っているかなど、色々とひっかかる点はありましたが、
最終的にはちゃんと更新に対応できて良かったです。
