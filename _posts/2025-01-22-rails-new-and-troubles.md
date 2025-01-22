---
layout: post
title: "rails new したものをほぼそのままデプロイしたら少しはまった話"
date: 2025-01-22 16:00 +0900
comments: true
category: blog
tags: ruby rails
---
ちょっと試すために `rails new` して `scaffold` で作成したぐらいで、ほぼ生成されたままの状態の rails アプリを `minikube` 環境にデプロイしたら、
いくつかはまった点があったので、そのメモです。

<!--more-->

## 対象バージョン

- rails 8.0.1
- ruby 3.3.7

## rails new

`rbenv` + `ruby-build` で入れた ruby 3.3.7 を使って、
`gem exec rails new /path/to/test-app-202501 -n test-app -d postgresql --devcontainer` で作成しました。

使わない Action Mailer などを skip するオプションも足そうかと思ったのですが、できるだけデフォルトのままの方が良いかと思って、
skip せずに作成することにしたのですが、これも後ではまる原因のひとつになりました。

## scaffold

VSCode の devcontainer 環境で作業しました。

`bin/rails g scaffold post title content` でデータベースを使う部分を作成して、
`bin/rails db:migrate` でデータベースに反映して、
`config/routes.rb` の `root "posts#index"` を有効にしました。

手元で `localhost:3000` での動作確認ができたので、デプロイすることにしました。

## docker build

あらかじめ `minikube` の `registry` アドオンを有効にしているので、
`docker build -t localhost:5000/test-app:0.0.1 .` でビルドして、
`kubectl port-forward --namespace kube-system services/registry 5000:80 &` で接続できるようにして、
`docker push localhost:5000/test-app:0.0.1` で反映しようとしました。

しかし `docker build` が `psych-5.2.3` のビルドのところで `yaml.h not found` で失敗して止まっていました。

最近 ruby-jp Slack で slim イメージで開発版のパッケージが減ったという話をみていたので、
その影響だろうということで、
`libyaml-dev` を追加したら問題なく進みました。

```diff
diff --git a/Dockerfile b/Dockerfile
index 08ea262..ac48c38 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -30,7 +30,7 @@ FROM base AS build

 # Install packages needed to build gems
 RUN apt-get update -qq && \
-    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
+    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
     rm -rf /var/lib/apt/lists /var/cache/apt/archives

 # Install application gems
```

## DATABASE_URL

データベース設定を `DATABASE_URL` 環境変数でまとめて設定すれば楽かと思って設定したのですが、
ログをみると反映されずに `/var/run/postgresql/s.PGSQL.5432` に繋ぎにいこうとして失敗していました。

色々と試行錯誤した結果、
`config/database.yml` をそのまま使うなら、
`DB_HOST` と `TEST_APP_DATABASE_PASSWORD` を設定するのが無難という結論になりました。

データベースは別マシンの Linux 環境に直接入れていたので、
`sudo -u postgres createuser --echo --createdb --no-createrole --no-superuser --pwprompt test_app`
でユーザー(ロール)を作成して使いました。

元々 `DATABASE_URL` に設定していたユーザー名と違っていて、そちらのユーザーでデータベース `test_app_production` を作成してしまっていたため、
ログに以下のエラーが出て起動に失敗していました。

```text
bin/rails aborted!
ActiveRecord::StatementInvalid: PG::InsufficientPrivilege: ERROR:  permission denied for table schema_migrations (ActiveRecord::StatementInvalid)


Caused by:
PG::InsufficientPrivilege: ERROR:  permission denied for table schema_migrations (PG::InsufficientPrivilege)

Tasks: TOP => db:prepare
(See full trace by running task with --trace)
```

`test_app_production_cache`,
`test_app_production_queue`,
`test_app_production_cable`
は作成できていました。

この別データベースが存在する、というのも `DATABASE_URL` だとうまくいかない原因になってそうでした。
冒頭で skip を省略した影響がここに出ていそうです。

## まとめ

`docker build` の失敗は別プロジェクトの変更による一時的なものなので、
<https://github.com/rails/rails/pull/54237> で修正されていて、
次のパッチリリースではなおりそうです。

`DATABASE_URL` は生成された `config/database.yml` との相性の問題なので、
使う環境変数やデータベースに合わせて適切に変更する必要がありそうです。
