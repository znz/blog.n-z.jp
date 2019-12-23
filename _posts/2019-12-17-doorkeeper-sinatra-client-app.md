---
layout: post
title: "doorkeeper gem の動作確認用に sinatra で OAuth2 クライアントを作った"
date: 2019-12-17 23:59:00 +0900
comments: true
category: blog
tags: ruby rails doorkeeper
---
[doorkeeper gem](https://github.com/doorkeeper-gem/doorkeeper) を使った rails アプリの動作確認をするときに、
OAuth 2.0 のクライアントがないと実際のブラウザーでの動作確認が難しいため、
[sinatra](https://rubygems.org/gems/sinatra) を使って開発環境向けの OAuth 2.0 クライアントを作成しました。

<!--more-->

## 動作確認環境

- doorkeeper gem を使った rails アプリ
- [doorkeeper-sinatra-client-app](https://github.com/znz/doorkeeper-sinatra-client-app)

## 使い方

### doorkeeper 側

通常のクライアントの登録と同様に doorkeeper gem を使った rails アプリ側で `Doorkeeper::Application` を作成しておきます。
`name` は適当に設定して `scopes` は要件に合わせて変更します。
`redirect_uri` は sinatra のデフォルトのままなので、ポート 4567 です。

```ruby
application = Doorkeeper::Application.create!(
  name: 'Sample Client',
  redirect_uri: 'http://localhost:4567',
  scopes: 'public sample',
)
puts "CLIENT_ID=#{application.uid}"
puts "CLIENT_SECRET=#{application.secret}"
```

### クライアント側

`git clone` してきて、先ほど生成された `CLIENT_ID` と `CLIENT_SECRET` を環境変数で設定します。
`OAUTH2_SCOPE` も `Doorkeeper::application` に設定したものと同じものを設定します。

`use_doorkeeper scope: 'somepath` のように `use_doorkeeper` に `scope` を設定してパスを変更している場合は、
`ROUTE_USE_DOORKEEPER_SCOPE=somepath` も設定しておきます。

`example.env` を `.env` にコピーして設定して `dotenv` を使って、 `dotenv ruby oauth2-app.rb` で起動するという方法もあります。

起動したらブラウザーで `http://localhost:4567/` を開きます。

```console
git clone https://github.com/znz/doorkeeper-sinatra-client-app
cd doorkeeper-sinatra-client-app
bundle install
export CLIENT_ID=above_id
export CLIENT_SECRET=above_secret
export OAUTH2_SCOPE="public sample"
ruby oauth2-app.rb
open http://localhost:4567/
```

## ブラウザーでの操作

クッキーを消して動作確認したいことも多いと思うので、ブラウザーはシークレットモードなどを使うと便利です。

開発環境向けということで、 view は最低限のものしかないので、左上の `login` からログインします。
doorkeeper 側に飛んで、認証と認可が済んだら sinatra 側に戻ってきます。

承認だけではなく、否認の場合の挙動も確認できます。

承認後のページでは scope に関係なく使える Token Introspection の情報などを取得して表示するようにしています。

`reload` のリンクでトークンはそのままで情報を更新できます。
`expires_in` が減っていくのが確認できると思います。

アクセストークンが期限切れになったら `refresh` のリンクからリフレッシュトークンを使ってトークンを更新できます。

## トークン

デバッグや挙動の調査向けに開発環境向けなので、アクセストークンとリフレッシュトークンをブラウザー側にそのまま表示していますが、
OAuth2 では本来これらのトークンはブラウザー側には渡さないものなので、
プロダクション環境では使わないでください。

## カスタマイズ

独自の API の動作確認をしたい場合は `get '/info' do` のところを書き換えて追加してください。
ちゃんとエラー処理は入れつつ、出来るだけ本質的な部分だけがわかるように、シンプルに作ったつもりなので、詳細はソースを確認してください。

## confidential フラグ

doorkeeper gem の 5 から追加された `Doorkeeper::Application#confidential` が `false` のときは
`CLIENT_SECRET` が `nil` でも通るようです。

## PKCE

[Using PKCE flow](https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-PKCE-flow) などをみて、
`bundle exec rails generate doorkeeper:pkce` で migration を作成して有効にした状態にした後、
`pkce-app.rb` の方を使うと PKCE 対応のフローを確認できます。

`oauth2-app.rb` と `pkce-app.rb` の差分をみるとクライアント側で PKCE 対応に必要な部分がわかります。

簡単に説明すると最初の `authorize_url` に `code_challenge` と `code_challenge_method` をつけて、
認可直後のトークン取得時に `code_verifier` をつける、ということになります。

doorkeeper gem 側で PKCE 対応を有効にしても、
`code_challenge` などがなければ PKCE なしのまま認可できるので、
PKCE に対応していないクライアントとも共存可能です。

## Authorization Code

このクライアントは Authorization Code Grant Type のみ対応しています。

## 参考文献

<https://oauth.net/2/> から辿って行ってみていくのが新し目の情報がまとまっていて良さそうでした。
