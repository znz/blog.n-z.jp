---
layout: post
title: "macOSの/etc/irbrcを調べた"
date: 2023-07-05 09:45 +0900
comments: true
category: blog
tags: osx ruby
---
macOS には謎の `/etc/irbrc` があって、今は自動で読み込まれることはありません。
中で ruby 1.9 の時に消えた `Array#nitems` が使われていて、自分で読み込んでもそのままでは動きません。
そこで、このファイルについて調査したので、その結果をまとめました。

<!--more-->

## 確認環境

macOS Ventura 13.4.1 にもまだ `/etc/irbrc` は存在しました。

## ネット上の情報

[ruby - Is /etc/irbrc installed by OS X? Does irb read it? - Stack Overflow](https://stackoverflow.com/questions/37617519/is-etc-irbrc-installed-by-os-x-does-irb-read-it)
によると OS X 10.11.5 の頃にすでに読み込まれていなくて、無意味なファイルになっていたことがわかります。

[Irb login not reading irbrc file - ruby-talk - Ruby Mailing List Mirror](https://rubytalk.org/t/irb-login-not-reading-irbrc-file/51836)
によると OS X 10.5.4 の Ruby 1.8.6 では読み込まれていたことがわかります。

`/etc/irbrc` のコメントに書かれている

```ruby
# Some default enhancements/settings for IRB, based on
# http://wiki.rubygarden.org/Ruby/page/show/Irb/TipsAndTricks
```

の wiki はもう存在しないようですが、
Internet Archive を使うと
<https://web.archive.org/web/20070814015441/http://wiki.rubygarden.org/Ruby/page/show/Irb/TipsAndTricks>
などで残っているようです。

## Apple Open Source を確認

[Apple Open Source](https://opensource.apple.com/releases/) から当時の Ruby (のパッチ) を探してみると、
OS X 10.5.4 の Ruby 1.8.6 には
<https://github.com/apple-oss-distributions/ruby/blob/ruby-67.3/patches/lib_irb_init.rb.diff>
というパッチで `/etc/irbrc` も読み込むようにしていたことがわかりました。

## 有効だった範囲を確認

GitHub にあって、リリースされた状態はタグで管理されていたので、
`git clone` して `git grep` で探してみました。

```console
$ git clone https://github.com/apple-oss-distributions/ruby
$ cd ruby
$ git tag | xargs -n1 git grep etc/irb
ruby-67:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67.2:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67.2:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67.3:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67.3:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67.4:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67.4:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67.6:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-67.6:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-75:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-75:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-75.1:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-75.1:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-75.2:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-75.2:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-75.3:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-75.3:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-79:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-79:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-83.1:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-83.1:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-83.3.1:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-83.3.1:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
ruby-83.4:patches/lib_irb_init.rb.diff:+    yield proc{|rc| "/etc/irb#{rc}"}
ruby-83.4:ruby/lib/irb/init.rb:    yield proc{|rc| "/etc/irb#{rc}"}
```

これが OS のどのバージョンになるのか <https://opensource.apple.com/releases/> と見比べてみたところ、

- Mac OS X 10.5 = ruby-67
- Mac OS X 10.7.5 = ruby-83.3.1
- Mac OS X 10.8 = ruby-83.4
- Mac OS X 10.8.4 = ruby-83.4
- OS X 10.9 = ruby-96

という感じだったので、
Mac OS X Leopard 10.5 の Ruby 1.8.6 から OS X Mountain Lion 10.8.4 の Ruby 1.8.7 までは使われていて、
OS X Mavericks 10.9 の Ruby 2.0.0 からは (たぶん `Array#nitems` でエラーになるので) 使われていなかったようです。

## まとめ

Ruby 1.8.6, 1.8.7 の時代に追加された `/etc/irbrc` が Ruby 2.0.0 のときに読み込み部分のパッチだけ消えて `/etc/irbrc` 自体は残ってしまっている、ということのようでした。

Apple の Open Source はメンテナンスが終わった古いバージョンもちゃんと公開が続いていて、非常に助かりました。

古いコードを新しい別のフレームワークで書き直すときなど、古いドキュメントが必要になることがあったときにみつからなくて苦労したことがあるので、古いものもちゃんと公開されているのはありがたいです。

## おまけ

ついでに
[【2023年版】"Rails is not currently installed on this system."というメッセージが出たときの対処方法 - Qiita](https://qiita.com/jnchito/items/e4872ff5c70a4c2219f1)
の `sudo gem install rails` も調べてみたところ、
ruby-79 からなので Mac OS X Lion 10.7 からのようです。

```console
$ git tag | xargs -n1 git grep 'sudo gem install rails'
ruby-101:extras/rails:  puts '    $ sudo gem install rails'
ruby-104:extras/rails:  puts '    $ sudo gem install rails'
ruby-106:extras/rails:  puts '    $ sudo gem install rails'
ruby-113:extras/rails:  puts '    $ sudo gem install rails'
ruby-113.40.1:extras/rails:  puts '    $ sudo gem install rails'
ruby-119:extras/rails:  puts '    $ sudo gem install rails'
ruby-119.50.2:extras/rails:  puts '    $ sudo gem install rails'
ruby-131:extras/rails:  puts '    $ sudo gem install rails'
ruby-131.200.3:extras/rails:  puts '    $ sudo gem install rails'
ruby-131.70.1:extras/rails:  puts '    $ sudo gem install rails'
ruby-141:extras/rails:  puts '    $ sudo gem install rails'
ruby-145.100.1:extras/rails:  puts '    $ sudo gem install rails'
ruby-145.40.1:extras/rails:  puts '    $ sudo gem install rails'
ruby-150:extras/rails:  puts '    $ sudo gem install rails'
ruby-161:extras/rails:  puts '    $ sudo gem install rails'
ruby-79:extras/rails:echo '    $ sudo gem install rails'
ruby-83.1:extras/rails:echo '    $ sudo gem install rails'
ruby-83.3.1:extras/rails:echo '    $ sudo gem install rails'
ruby-83.4:extras/rails:  puts '    $ sudo gem install rails'
ruby-96:extras/rails:  puts '    $ sudo gem install rails'
```
