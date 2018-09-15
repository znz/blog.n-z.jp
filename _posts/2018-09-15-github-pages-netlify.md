---
layout: post
title: "GitHub Pages と Netlify の比較"
date: 2018-09-15 23:59 +0900
comments: true
category: blog
tags: netlify
---
静的サイトのホスティングサービスとして
GitHub Pages と Netlify の両方を使ってみて、
ある程度わかってきたのでいくつかの点で比較してみました。

<!--more-->

## 概要

基本的には GitHub Pages は手軽に使えて、
Netlify は高機能です。

## デプロイ

基本的にはどちらも `git push` でできます。

Netlify は Drag and Drop や専用の CLI など他の方法も使えますし、
git のホスティングも github.com 以外に、
生成元のソースを公開したくないのなら bitbucket.org や gitlab.com なども使えます。

git 管理しているかどうかに関わらず zip でまとめてあげることもできるようです。

今回の比較とは直接は関係ないですが、
手軽にデプロイできるサービスとして
[Now](https://zeit.co/now)
というのもあるようです。

## 使えるサイトジェネレーター

GitHub Pages は基本的には制限された jekyll で、
プラグインによっては別途生成して
生成したファイルを `git push` することになります。
手元で生成すれば何でも使えます。

Netlify は自由度が高くて、
公式のドキュメントにも色々のっていますが、
ある程度自由にビルドコマンドを設定できるので、
[rdoc さえ使える]({% post_url 2018-05-09-rdoc-netlify %})ようです。

## 動的サイト

静的サイト用なので、
基本的には disqus などの外部サービスに頼ることになります。

Netlify は [Forms](https://www.netlify.com/docs/form-handling/) で問い合わせフォームを作ったり、
[Functions](https://www.netlify.com/docs/functions/) で AWS Lambda をちょっと使ったりできるようです。
件数制限がありますが、ちょっとした個人サイトでは良いかもしれません。

## カスタムドメインと https

GitHub Pages は以前は Cloudflare などを使う必要がありましたが、
今はカスタムドメインでの Let's Encrypt による https 対応をしたので、
https はどちらも問題なく使えます。

サービス自体とは直接は関係ないですが、
このブログのようにサービスを乗り換える可能性があるなら、
github.io や netlify.com のサブドメインを使うのではなく、
最初から独自ドメインを使っておいた方が URL が変わらなくてオススメです。

## CDN

GitHub Pages はカスタムドメインの https 対応していなかった頃は
Cloudflare と組み合わせるという話があったようです。
今でも CDN が欲しいならそういう組み合わせもありそうです。

今回の比較には関係無いですが、
GitHub のファイルを Content-Type が適切に付いた状態で使いたいのなら
[RawGit](https://rawgit.com/)
がオススメです。
[このブログでも disqus の埋め込みで別ドメインが必要だった]({% post_url 2018-03-27-amp-disqus %})ので、
RawGit を使っています。

Netlify は Netlify 自体が CDN なので、何も追加する必要がありません。

## リダイレクト

GitHub Pages だと meta refresh を使うとか javascript でなんとかするしかなさそうです。

Netlify だと
[Redirects & Rewrite Rules](https://www.netlify.com/docs/redirects/)
にあるように `_redirects` ファイルか `netlify.toml` である程度自由度が高く設定できます。

ただし WikiWikiWeb のような `http://example.com/?PageName` は
`=` がないのでうまく取り出せないらしく、
設定の仕方がわからなかったので、
できないのかもしれません。

## まとめ

GitHub だけでホスティングをしたいのなら GitHub Pages が手軽で便利ですが、
GitHub Pages の自動ビルドで使えない jekyll プラグインを使いたいなど、
ちょっとでも凝ったことをしたいのなら、
Netlify も選択肢に入れてみるのをオススメします。
