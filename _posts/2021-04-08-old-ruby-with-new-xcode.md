---
layout: post
title: "ruby 2.6以前が新しいXcodeでビルドエラーになるときの回避方法"
date: 2021-04-08 12:00 +0900
comments: true
category: blog
tags: ruby
---
Ruby 3.0.1, 2.7.3, 2.6.7, 2.5.9 がリリースされたので、
`rbenv install 2.6.7` などでインストールしていると、
macOS Big Sur の環境でエラーになったので、
その回避方法の話です。

<!--more-->

## 動作確認環境

- macOS Big Sur 11.2.3
- Xcode 12.4

## エラー内容

以下のように `implicit-function-declaration` でエラーになります。
詳細は確認していませんが、Xcode 12 でデフォルトでエラーになるようになったそうです。

```
% rbenv install 2.6.7
Downloading openssl-1.1.1j.tar.gz...
-> https://dqw8nmjcqpjn7.cloudfront.net/aaf2fcb575cdf6491b98ab4829abf78a3dec8402b8b81efc8f23c00d443981bf
Installing openssl-1.1.1j...
Installed openssl-1.1.1j to /Users/kazu/.anyenv/envs/rbenv/versions/2.6.7

Downloading ruby-2.6.7.tar.bz2...
-> https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.7.tar.bz2
Installing ruby-2.6.7...
ruby-build: using readline from homebrew

BUILD FAILED (macOS 11.2.3 using ruby-build 20210405-2-g693a28e)

Inspect or clean up the working tree at /var/folders/zp/ypp1b45n11zcz72m6vqtkq340000gn/T/ruby-build.20210408003939.92428.ZAWGrP
Results logged to /var/folders/zp/ypp1b45n11zcz72m6vqtkq340000gn/T/ruby-build.20210408003939.92428.log

Last 10 log lines:
vm.c:2295:9: error: implicit declaration of function 'rb_native_mutex_destroy' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
        rb_native_mutex_destroy(&vm->waitpid_lock);
        ^
vm.c:2489:34: warning: expression does not compute the number of elements in this array; element type is 'const int', not 'VALUE' (aka 'unsigned long') [-Wsizeof-array-div]
                             sizeof(ec->machine.regs) / sizeof(VALUE));
                                    ~~~~~~~~~~~~~~~~  ^
vm.c:2489:34: note: place parentheses around the 'sizeof(VALUE)' expression to silence this warning
1 warning and 1 error generated.
make: *** [vm.o] Error 1
make: *** Waiting for unfinished jobs....
```

## 対処方法

`CFLAGS="-Wno-error=implicit-function-declaration"` を付けると回避できます。

```
% CFLAGS="-Wno-error=implicit-function-declaration" rbenv install 2.6.7
Downloading openssl-1.1.1j.tar.gz...
-> https://dqw8nmjcqpjn7.cloudfront.net/aaf2fcb575cdf6491b98ab4829abf78a3dec8402b8b81efc8f23c00d443981bf
Installing openssl-1.1.1j...
Installed openssl-1.1.1j to /Users/kazu/.anyenv/envs/rbenv/versions/2.6.7

Downloading ruby-2.6.7.tar.bz2...
-> https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.7.tar.bz2
Installing ruby-2.6.7...
ruby-build: using readline from homebrew
Installed ruby-2.6.7 to /Users/kazu/.anyenv/envs/rbenv/versions/2.6.7
```

## 関連情報

[Bug #17777: 2.6.7 fails to build on macOS: implicit declaration of function 'rb_native_mutex_destroy' is invalid in C99 - Ruby master - Ruby Issue Tracking System](https://bugs.ruby-lang.org/issues/17777)
だと `warnflags` という ruby のビルドが独自に見ている環境変数を使っているので、
`CFLAGS` の代わりに `warnflags` で指定しても良さそうです。

この issue で 2.6.8 では解決している可能性があるようですが、何らかの事情で古いバージョンを入れる必要があるときは今後も必要になりそうです。

それから 2.5 以前でも起きるという話もあるのですが、手元では `rbenv install 2.5.9` が `-Wno-error=implicit-function-declaration` なしで通ってしまったので確認できていません。
