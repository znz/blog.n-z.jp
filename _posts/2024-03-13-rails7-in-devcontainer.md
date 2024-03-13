---
layout: post
title: "Rails 7を動かすためのdevcontainerの設定を更新した"
date: 2024-03-13 17:40 +0900
comments: true
category: blog
tags: ruby rails
---
[znz/rails7-example](https://github.com/znz/rails7-example)
という最低限の Rails 7 を devcontainer で動かす例の設定を更新した話です。

<!--more-->

## 環境

- Rails: 7.0.8.1 → 7.1.3.2
- コンテナ: mcr.microsoft.com/devcontainers/ruby 0-3.1-bullseye → 1-3.3-bullseye
- devcontainer 設定: 作成時に VSCode で自動生成できたもの → [3月9日時点の main ブランチの ruby-rails-postgres](https://github.com/devcontainers/templates/tree/3debff226fb944ac9916218367b3ecea37e2dd15/src/ruby-rails-postgres>)

## Rails のファイルの更新

`rails new /tmp/rails7-example -d postgresql` で生成したものと比較してマージしました。


`db/schema.rb` は自動生成対象ではなかったので削除したら、
devcontainer の起動時の `rake db:setup` が失敗するので、
後で戻しました。

`.devcontainer/Dockerfile` の `FROM mcr.microsoft.com/devcontainers/ruby:0-3.1-bullseye` の 3.1 で Ruby 3.1.4 になっていたのを
単純に `FROM mcr.microsoft.com/devcontainers/ruby:0-3.2-bullseye` のように 3.2 すると、
なぜか最新の 3.2.3 ではなく 3.2.2 になったので、
とりあえず 3.2.2 で更新しました。

## devcontainer の設定の更新

<https://containers.dev/> あたりから最新のテンプレートを探してみると、
<https://github.com/devcontainers/templates/tree/main/src/ruby-rails-postgres>
にあったので、その設定をマージして更新しました。

### Dockerfile

テンプレートを参考にして、
`.devcontainer/Dockerfile` の `FROM` は `mcr.microsoft.com/devcontainers/ruby:1-3.3-bullseye` に更新しました。

[devcontainers/images の ruby](https://github.com/devcontainers/images/tree/cdb8f1f1a51e084dbf5c12e296ec34050dd98c3a/src/ruby)
に `mcr.microsoft.com/devcontainers/ruby` の説明があって、
先頭の `0-` や `1-` は イメージのsemver だったとわかりました。

`0-` だと古い Ruby の拡張が入っていて、Ruby-LSP 拡張に更新するようにうながされるのですが、
`1-` だと大丈夫でした。

### devcontainer.json

次の `docker-compose.yml` の `volumes` の変更と組み合わせて `"workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",` に変わっていました。

`"postCreateCommand": "bundle install && rake db:setup"` はコメントアウトされているのを有効にしています。
今なら `rake db:setup` の代わりに `rails db:setup` でも良さそうです。

`customizations` は以下のように拡張機能を列挙しています。

```json
  "customizations": {
    "vscode": {
      "extensions": [
        "editorconfig.editorconfig",
        "github.vscode-github-actions",
        "hediet.debug-visualizer",
        "koichisasada.vscode-rdbg"
      ]
    }
  }
```

他のプロジェクトでの `devcontainer.json` での経験でわかったことも、ついでにメモしておきます。

プロジェクト自体の `docker-compose.yml` がある場合は `"dockerComposeFile": ["../docker-compose.yml", "docker-compose.yml"],` のように配列にして上書き部分だけを `.devcontainer/docker-compose.yml` に書くと良さそうです。

一部のサービスだけ起動したいときは `"runServices"` で列挙すると良さそうですが、全部起動すればいいなら列挙せずに省略する方が楽です。

起動前にホスト側で何か準備をする必要があれば `initializeCommand` が使えます。
コンテナの中で実行されるものは `postCreateCommand` の他に `postStartCommand` と `postAttachCommand` があるので、
実行したいタイミングや頻度などによって使いわけると良さそうです。

### docker-compose.yml

`volumes` が `- ../..:/workspaces:cached` に変わって `Rails.root` の親ディレクトリからコンテナの中で見えるようになりました。
`git` から見えてほしくないちょっとしたファイルなどを親ディレクトリに置くことがあるので、そういうものもコンテナの中から見えるようになったのは便利そうです。

隣に `git clone` したものが必要なときにも使えそうというのも良さそうで、
[bitclust](https://github.com/rurema/bitclust) の隣に [doctree](https://github.com/rurema/doctree) を置いて
開発するというのにも使えそうだと思いました。

テンプレートでは `config/database.yml` での設定を想定しているのかもしれませんが、
`DATABASE_URL` 環境変数を追加設定しています。

```yaml
    environment:
      DATABASE_URL: postgres://postgres:postgres@db:5432
```

完全に再作成したいときに
`devcontainer_postgres-data` ボリュームが残っているので、
`docker compose -f .devcontainer/docker-compose.yml down -v`
で消しています。

## Dockerfile

Rails 7.1 の `rails new` で `Dockerfile` も作成されるようになりましたが、
まだそのファイルは使えていません。

作成された `.dockerignore` は便利そうなので、他のプロジェクトにも必要な部分をコピーして使うと良さそうだと思いました。

## 感想

rails 7.1 だけ上げるつもりが docker image が ruby 3.2.2 に対応していなくて調べていたら、
いつの間にか devcontainer の設定更新がメインになってしまっていました。

これを使ってちょっと調べたいときに devcontainer で起動して、
`rails g` で適当に生成して試して、
`git stash -u && git stash drop` などで消す、
ということができるようになったので便利です。
