---
layout: post
title: "DokkuへのデプロイをHerokuish BuildpacksからDockerfile Deploymentに変更した"
date: 2024-08-05 12:00 +0900
comments: true
category: blog
tags: dokku ruby rails
---
自分専用 Rails アプリの Dokku へのデプロイに
[Herokuish Buildpacks](https://dokku.com/docs/deployment/builders/herokuish-buildpacks/)
を使っていましたが、
Heroku が Ruby 対応を更新してくれるのに依存していて、
Ruby 自体のリリースから使えるようになるまでの待ちが長くて困ることが続いたので、
[Dockerfile Deployment](https://dokku.com/docs/deployment/builders/dockerfiles/)
に切り替えました。

<!--more-->

## 動作確認バージョン

- dokku 0.34.7
- herokuish 0.9.2
- ruby 3.2.4 から 3.2.5 (ここが問題)
- rails 7.1.3.4

## 現状確認

Dependabot の pull request で開発環境用の `Dockerfile.local` の `FROM ruby:3.2.4` が `FROM ruby:3.2.5` に更新されたので、
`.ruby-version` なども更新して `git push` したところ、以下のようにビルドに失敗しました。

```text
-----> Compiling Ruby/Rails
	   Command: 'set -o pipefail; curl -L --fail --retry 5 --retry-delay 1 --connect-timeout 90 --max-time 600 https://heroku-buildpack-ruby.s3.us-east-1.amazonaws.com/heroku-22/ruby-3.2.5.tgz -s -o - | tar zxf - ' failed on attempt 1 of 3.
	   Command: 'set -o pipefail; curl -L --fail --retry 5 --retry-delay 1 --connect-timeout 90 --max-time 600 https://heroku-buildpack-ruby.s3.us-east-1.amazonaws.com/heroku-22/ruby-3.2.5.tgz -s -o - | tar zxf - ' failed on attempt 2 of 3.

	   !
	   !     The Ruby version you are trying to install does not exist: ruby-3.2.5
	   !
	   !     Heroku recommends you use the latest supported Ruby version listed here:
	   !     https://devcenter.heroku.com/articles/ruby-support#supported-runtimes
	   !
	   !     For more information on syntax for declaring a Ruby version see:
	   !     https://devcenter.heroku.com/articles/ruby-versions
	   !
remote:  !     Failure during app build
```

対応されたら
[Heroku Changelog](https://devcenter.heroku.com/changelog)
に情報が載るはず、ということで数日待っていたのですが、
[7月26日のリリース](https://www.ruby-lang.org/en/news/2024/07/26/ruby-3-2-5-released/)
から
7月29日の[Node.js 20.16.0 now available](https://devcenter.heroku.com/changelog-items/2965)、
7月31日の[Heroku-20, Heroku-22 and Heroku-24 stacks updated](https://devcenter.heroku.com/changelog-items/2966)、
8月2日の[Early August 2024 PHP updates](https://devcenter.heroku.com/changelog-items/2967)
と別の更新だけ続いていて、
いつリリースされるかわからないものに依存するのは良くないと思ったので、
Ruby 3.3 系にして一時的な解決をするのではなく、
Dockerfile Deployment に切り替えることにしました。

## 本番用 Dockerfile

[znz/rails7-example](https://github.com/znz/rails7-example)
に Rails 7.1 で生成した本番用 Dockerfile を用意していたので、
それをコピーして使いました。

以下の点を変更しました。

- `ARG RUBY_VERSION=3.2.5` のバージョンを更新
- `FromAsCasing: 'as' and 'FROM' keywords' casing do not match` という警告が出るので `FROM base AS build` のように `FROM` 行の `as` を `AS` に変更
- `gem "bootstrap", "< 5"` などで依存している `execjs` で必要だったので `apt-get install` に `nodejs` を追加 (build stage と final stage の両方に必要だった)

nodejs が必要なのは bootstrap 4 から移行したり importmap-rails に移行したりすれば消せそうだと思っているので、一時的なものとして Debian パッケージの nodejs を使いました。
依存を外すか、ちゃんと最新の node を使うかどうかは別途対応したいと思っています。

## その他のファイル

Dockerfile の `ENTRYPOINT ["/rails/bin/docker-entrypoint"]` で使っている `bin/docker-entrypoint` もコピーしました。

`chown -R rails:rails db log storage tmp` でエラーになったので、今のところ使っていない `storage/.keep` も追加しました。

`config/database.yml` で `ENV.fetch('DATABASE_URL', '').sub(/^postgres/, "postgis")` のように `url` を設定していたら、
`assets:precompile` で
`ActiveRecord::AdapterNotSpecified: database configuration does not specify adapter (ActiveRecord::AdapterNotSpecified)`
というエラーになってしまったので、コメントにあった適当な URL をデフォルト値として使って adapter がわかるようにしました。

```yaml
production:
  url: <%= ENV.fetch('DATABASE_URL', 'postgres://myuser:mypass@localhost/somedatabase').sub(/^postgres/, "postgis") %>
```

## Gemfile から ruby を削除

[Gemfile の ruby](https://bundler.io/guides/gemfile_ruby.html) は主に Heroku 用の指定だときいているので、
herokuish Buildpacks を使わないなら不要 (`.ruby-version` や `Dockerfile` での指定と重複するため) ということで、
削除しました。
Gemfile.lock も更新して `RUBY VERSION` も消えました。

## 感想

できるだけ差分を小さくして、さっさと Dockerfile Deployment に移行したかったのですが、
意外と差分が増えてしまいました。

これで Heroku の対応を待たずに Docker images の更新だけ待てば良くなったので、バージョンを上げやすくなりました。
