---
layout: post
title: "rawgitを使うのをやめた"
date: 2018-10-19 22:35 +0900
comments: true
category: blog
tags: jekyll disqus netlify
---
[DisqusをAMP用に再度設定した]({% post_url 2018-03-27-amp-disqus %})ときに RawGit を使うようにしましたが、
終了するようなので、使わないようにしました。

<!--more-->

## 状況

[RawGit has reached the end of its useful life](https://rawgit.com/)
のアナウンスによると、すでに使われている URL については 2019 年 10 月までは使えて、
新規に使うことはできなくなっているようです。

マルウェアの配布などにも使われてしまっているというのも終了する理由のひとつのようです。

## netlify のリダイレクトの除外設定

まず `_disqus.html` のままだと jekyll で除外されてしまうので、
`disqus_thread.html` に名前を変更しました。

netlify の公式の設定例にしたがって、
デフォルトのドメインへのアクセスは全て独自ドメインの方にリダイレクトする設定を入れていたのですが、
`disqus_thread.html` だけ許可するようにしました。

```
# exclude
https://blog-n-z-jp.netlify.com/disqus_thread.html /disqus_thread.html 200
# Redirect default Netlify subdomain to primary domain
https://blog-n-z-jp.netlify.com/* https://blog.n-z.jp/:splat 301!
```

## Trusted Domains 追加

EXAMPLE.disqus.com/admin/settings/advanced/
から
Trusted Domains に `blog-n-z-jp.netlify.com` を追加しました。

## 埋め込み URL 変更

`https://cdn.rawgit.com/znz/blog.n-z.jp/1d5c7e5949ec913739b8544d79d9bdca9fa365c9/_disqus.html` を
`https://blog-n-z-jp.netlify.com/disqus_thread.html` に変更しました。

## X-Frame-Options

`X-Frame-Options: DENY` をつけていたので、
`disqus_thread.html` だけ `X-Frame-Options: allow-from https://blog.n-z.jp/` にして許可する必要がありました。

```
/*
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  X-XSS-Protection: 1; mode=block
/disqus_thread.html
  X-Frame-Options: allow-from https://blog.n-z.jp/
```

## 動作確認

コメントがついている
[cloudflareのDNS 1.1.1.1を使うとインターネットが遅くなるかもしれない]({% post_url 2018-04-04-cloudflare-dns %})
でちゃんとコメントが表示されるのを確認しました。

## まとめ

1 ファイルだけのドメインを変更するぐらい簡単にできるだろうと思っていたら、
リダイレクト設定だったり、ヘッダー設定だったり、意外とはまりどころがありました。

油断せずにちゃんと動作確認することが大事だと思いました。
