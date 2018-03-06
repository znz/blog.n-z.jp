---
layout: post
title: "jekyllをNetlifyにデプロイした"
date: 2018-03-06 21:59:59 +0900
comments: true
category: blog
tags: jekyll netlify
---
[OctopressからJekyllに移行]({% post_url 2018-03-03-welcome-to-jekyll %})して、さらにデプロイ先を [GitHub Pages](https://pages.github.com/) から [Netlify](https://www.netlify.com/) に変更しました。

<!--more-->

## 移行理由

github-pages gem は jekyll が古いということで使わなかったので、
GitHub Pages で push 時に自動で build が使えなさそうということと、
https 対応するのに GitHub Pages で独自ドメインだと Cloudflare と組み合わせるという話しかみつからなかった、
という点がひっかかって、
独自ドメインでも簡単に https 対応にできる Netlify を使ってみました。

## Netlify でサイト追加

まず、GitHub の方に jekyll 化したサイトのソースを push しておきました。
ログインして Sites から「New site from Git」を選んで GitHub の repository と連携させました。

## サイト設定

独自ドメインの CNAME 設定や preview などのドメインの一部に使われる Site name をわかりやすいもの (blog-n-z-jp) に変更しました。

## Build & deploy

## Deploy settings

最初は、サイト追加の時に設定できて、試行錯誤の末に以下のように設定しました。

| Build command | `jekyll build`
| Publish directory | `_site/`
| Production branch | `master`
| Branch deploys | `staging`

Branch deploys はとりあえず master 以外は staging しか使う予定がなかったので、
他のブランチを使ってしまった時に無駄なビルドが走るのを避けるために staging を設定しましたが、
All でもよかったかもしれません。

### Build environment variables

本番環境のみなら以下のように設定すると良さそうです。

| Key | Value
|-
| `JEKYLL_ENV` | `production`

staging では別の設定にしたかったのですが、
Web 上の設定では出来なさそうだったので、
[netlify.toml](https://www.netlify.com/docs/what-is-the-netlify-toml-file/)
を使って、以下のように設定して production と deploy になるようにしました。

<p class="filename">netlify.toml:</p>

```toml
[context.production.environment]
JEKYLL_ENV = "production"
[context.deploy-preview.environment]
JEKYLL_ENV = "preview"
[context.branch-deploy.environment]
JEKYLL_ENV = "staging"
```

そして、これを liquid テンプレートで
`{{ "{%" }} if jekyll.environment == 'production' %}`
のように使ったり、

```
{% raw %}
{% if jekyll.environment != 'production' %}
  <meta name="robots" content="noindex">
{% endif %}
{% endraw %}
```

のように使ったりしました。

## Deploy notifications

初期状態では

- Send commit status to GitHub when deploy succeeds
- Send commit status to GitHub when deploy fails
- Send commit status to GitHub when deploy starts

が設定されていたので、
Slack で Webhook 用の URL を生成して、以下のように設定できるものすべてを通知するようにしてみました。

- Send message to Slack when deploy starts
- Send message to Slack when deploy succeeds
- Send message to Slack when deploy fails
- Send message to Slack when deploy is locked
- Send message to Slack when deploy is unlocked

## Domain management

Add custom domain で blog.n-z.jp を追加しました。
そして Netlify の設定ではなく DNS サーバーの方で CNAME を znz.github.io から blog-n-z-jp.netlify.com に変更しました。

## HTTPS 設定

古い CNAME がキャッシュされていると Let’s Encrypt の証明書の設定に失敗してしまうので、
一晩待った後、
Let’s Encrypt の証明書を設定しました。

それから、
Force HTTPS
も有効にしました。

## Netlify DNS

Branch subdomains のところで Set up Netlify DNS を押してしまうとドメインが Netlify DNS に登録されてしまいます。
間違えて設定してしまっても、近くに元に戻せるボタンがないので戸惑いますが、
上の「アカウント名 &gt; サイト名」の「アカウント名」のところをクリックして上に戻って、
「DNS zones」の方に行けば削除できました。

他の独自ドメインで試している時に消し方がわからずにそのままにしていたら、
https が GlobalSign の証明書になっていたので、
独自ドメインで https を使うのに Let's Encrypt にする必要はないのかもしれません。
(今は削除して Let's Encrypt に変えてしまったので、本来はどうなのかは確認していません。)

## リダイレクト設定

`_redirects` ファイルを作成して、
`_config.yml` に以下のように設定して atom feed などの URL が変わったものの一部に対応しました。

```yaml
include:
- "_redirects"
```

## ヘッダー設定

[Headers & Basic Authentication \| Netlify](https://www.netlify.com/docs/headers-and-basic-auth/)
を参考にして
`_redirects` と同様に `_headers` を追加しました。
`_config.yml` の `include` にも追加が必要です。

<p class="filename">_headers:</p>

```
---
layout: null
---
/*
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  X-XSS-Protection: 1; mode=block
```

[Playground](https://play.netlify.com/headers) で試してみると、
以下の内容に変換されたので、
`netlify.toml` に書くのなら以下の内容になるようです。

```toml
[[headers]]
for = "/*"
[headers.values]
X-Content-Type-Options = "nosniff"
X-Frame-Options = "DENY"
X-XSS-Protection = "1; mode=block"
```
