---
layout: post
title: "jessieからstretchにあげた"
date: 2019-03-31 10:43 +0900
comments: true
category: blog
tags: linux debian
---
jessie-updates が消えたので、そろそろあげないと、と思って、まだ jessie のままだったサーバーを stretch にあげてみたら、少しハマりました。

<!--more-->

## 環境

- さくらの VPS
- Debian GNU/Linux の jessie (oldstable) から stretch (stable) への更新

## ハマったところ

### runit

以前から [nadokaさん](https://github.com/nadoka/nadoka) の起動などに runit を使っていたのですが、 systemd に移行した関係で、 runit-systemd を入れないと runsvdir が動かなくなっていました。説明に「system-wide service supervision (systemd integration)」と書いてありました。

runit-sysv という名前で「system-wide service supervision (sysv integration)」という説明のパッケージもあるので、 sysvinit のままにする場合はこちらを入れる必要がありそうです。

### tdiary

tdiary が <http://on-o.com/~tkyn/diary/20161116.html> と同じ現象ではまりました。

具体的には index.rb にアクセスすると、

```
500 Internal Server Error
uninitialized constant Bundler (NameError)

/usr/share/tdiary/lib/tdiary/environment.rb:25:in `<top (required)>'
/usr/lib/ruby/2.3.0/rubygems/core_ext/kernel_require.rb:55:in `require'
/usr/lib/ruby/2.3.0/rubygems/core_ext/kernel_require.rb:55:in `require'
/usr/share/tdiary/lib/tdiary.rb:25:in `<top (required)>'
/usr/lib/ruby/2.3.0/rubygems/core_ext/kernel_require.rb:55:in `require'
/usr/lib/ruby/2.3.0/rubygems/core_ext/kernel_require.rb:55:in `require'
/usr/share/tdiary/index.rb:18:in `<top (required)>'
/usr/lib/ruby/2.3.0/rubygems/core_ext/kernel_require.rb:55:in `require'
/usr/lib/ruby/2.3.0/rubygems/core_ext/kernel_require.rb:55:in `require'
index.rb:2:in `<main>'
```

と出ていて、 `sudo apt install bundler` で入れてみても (たぶん `require` する場所を通らないので) 解決せず、参照したサイトに使っていないと書いてあったので、
`sudoedit /usr/share/tdiary/lib/tdiary/environment.rb` で

```
tdiary_spec = false # Bundler.definition.specs.find {|spec| spec.name == 'tdiary'}
```

と変更したら表示されるようになりました。

## jessie-updates の削除について

[debian(jessie)のdocker imageでapt-getのエラー→要らないエントリを消しましょう](https://qiita.com/henrich/items/d7c2c6d90f9c7d34e516) からリンクされている [サポート終了コンポーネントのアーカイブ削除に寄せて](https://henrich.github.io/blog/2019/03/26/%E3%82%B5%E3%83%9D%E3%83%BC%E3%83%88%E7%B5%82%E4%BA%86%E3%82%B3%E3%83%B3%E3%83%9D%E3%83%BC%E3%83%8D%E3%83%B3%E3%83%88%E3%81%AE%E3%82%A2%E3%83%BC%E3%82%AB%E3%82%A4%E3%83%96%E5%89%8A%E9%99%A4%E3%81%AB%E5%AF%84%E3%81%9B%E3%81%A6/) が参考になります。

古い環境の動作確認用などの特殊なもの以外は、そろそろ stretch に移行した方が良さそうということではないでしょうか。
