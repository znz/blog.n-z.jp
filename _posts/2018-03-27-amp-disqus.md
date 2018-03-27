---
layout: post
title: "DisqusをAMP用に再度設定した"
date: 2018-03-27 23:30 +0900
comments: true
category: blog
tags: jekyll amp disqus
---
Jekyll の Amplify テーマだけだと関連記事へのリンクどころか、前後への記事へのリンクさえもないので、
関連リンクをつける意味もかねて公式に AMP 対応をうたっている Disqus を再度つけることにしました。

基本的には
[Disqus for Accelerated Mobile Pages (AMP)](https://github.com/disqus/disqus-install-examples/tree/master/google-amp)
の手順で設定しましたが、いくつかハマりどころがありました。

<!--more-->

## 設定変更

直接は関係ないですが、いくつか設定を変更しました。

- EXAMPLE.disqus.com/admin/settings/general/ で
  - Website Name を ZnZ Blog のままだったのを @znz blog に変更
  - Website URL を http://blog.n-z.jp/ から https://blog.n-z.jp/ に変更
  - Category が未選択だったのを Tech に変更
  - Language は Japanese のまま

## マイグレーション

Website URL の直下の説明にある「Changing domains? Learn how.」から Migrate Threads が開けたので、
Domain Migration Tool をみてみると http から https への変更は URL mapper を使うように案内が出ました。

戻って URL mapper の方に進むと CSV ダウンロードリクエストがあって、
そこからリクエストして少し待つとメールでダウンロード用の URL が届くのでダウンロードしました。
そして、
`ruby -nle 'puts "#$_,#{$_.sub(/^http:/, %(https:))}"' /tmp/znzblog-2018-03-27T13_13_51.077161-links.csv > /tmp/migrate.csv`
で https に書き換える用の CSV を作成して、
Upload a URL mapping
でアップロードしてしばらく待つと反映されました。

## 別ドメインに設置

disqus\_thread と script の HTML は別ドメインに置く必要があるらしいので、
Disqus を復活させるのを躊躇していたのですが、
[RawGit](https://rawgit.com/)
の CDN を使えば別リポジトリを用意しなくても良いということに気づいたので、使うことにしました。

jekyll に無視させるために `_` で始まる名前の `_disqus.html` にして、
master の URL だと更新した時に反映に時間がかかるため、
[\_disqus.html](https://github.com/znz/blog.n-z.jp/blob/master/_disqus.html)
を開いて、ショートカットキーの
<kbd>y</kbd> (Expand URL to its canonical form)
を使って、
`https://github.com/znz/blog.n-z.jp/blob/1d5c7e5949ec913739b8544d79d9bdca9fa365c9/_disqus.html`
という URL にした後、
RawGit の方で変換された
`https://cdn.rawgit.com/znz/blog.n-z.jp/1d5c7e5949ec913739b8544d79d9bdca9fa365c9/_disqus.html`
という URL を使いました。

## フレーム内の HTML 改変

`EXAMPLE.disqus.com` の `EXAMPLE` を自分のサイトの shortname に変更した他に、

```javascript
    var disqus_config = function () {
        this.page.url = window.location;  // Replace PAGE_URL with your page's canonical URL variable
        this.page.identifier = window.location.hash; // Replace PAGE_IDENTIFIER with your page's unique identifier variable
    };
```

の部分で `window.location.hash` は頭に `#` がついていて以前の octopress 2 の時の

{% raw %}
```javascript
        var disqus_identifier = '{{ site.url }}{{ page.url }}';
        var disqus_url = '{{ site.url }}{{ page.url }}';
```
{% endraw %}

と一致しなくて過去のコメントが出なかったので、

```javascript
    var disqus_config = function () {
        var parent_url = window.location.hash.replace(/^#/, "");
        this.page.url = parent_url;  // Replace PAGE_URL with your page's canonical URL variable
        this.page.identifier = parent_url; // Replace PAGE_IDENTIFIER with your page's unique identifier variable
    };
```

に変更しました。

## HTML に組み込み

[AMP の HTML に disqus を組み込む](https://www.monotalk.xyz/blog/amp-%E3%81%AE-html-%E3%81%AB-disqus-%E3%82%92%E7%B5%84%E3%81%BF%E8%BE%BC%E3%82%80/)
や
<https://github.com/j26design/Disqus-AMP-Integration>
などに書いてあるように、
AMP のエラーが出るので、

```html
<div overflow tabindex=0 role=button aria-label="Disqus Comments">Disqus Comments</div>
```

のような overflow がついた div が必要でした。

## Trusted Domains 追加

EXAMPLE.disqus.com/admin/settings/advanced/
から
Trusted Domains に cdn.rawgit.com を追加しました。

## まとめ

AMP に Disqus を組み込むこと自体は公式に対応していて、先人もいるので、
問題が起きてもすぐに解決できましたが、
移行については設定画面のメッセージや実際の挙動をみて考えるしかなくて、
少し大変でした。
