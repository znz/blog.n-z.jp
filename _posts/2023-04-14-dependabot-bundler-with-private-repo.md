---
layout: post
title: "dependabotのbundlerでGitHubのprivate repositoriesを扱う"
date: 2023-04-14 16:50 +0900
comments: true
category: blog
tags: ruby github dependabot
---
dependabot の
[package-ecosystem](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#package-ecosystem)
の Bundler の Private repositories は x になっていて、対応していないようでしたが、もう少し調べて試してみると使えたので、その方法をまとめておきます。

<!--more-->

## 経緯

`.github/dependabot.yml` で `package-ecosystem: bundler` の設定をしているのに、
gem の更新の pull request が作成されない repository があったので調査しました。

他の `package-ecosystem` の設定と比較しても、設定内容に間違いはなさそうだったので、
色々調べたり考えたりした結果、
`gem 'some-private-gem', git: 'git@github.com:example-org/some-private-gem.git'`
のような private repositories を参照しているのが原因ではないかと思い当たりました。

## 動作確認

### private gem 作成

dependabot がひっかかってくれれば何でもいいので、
`bundle gem private-example-gem-repo` で作成して TODO のところを書き換えただけのものを作成して、
`gh repo create` で private repository を作成しました。

### private app 作成

`private-example-gem-repo` ディレクトリの横に `private-example-app-repo` というディレクトリを作って、
`bundle init` で作成した `Gemfile` に
`gem "private-example-gem-repo", path: "../private-example-gem-repo"`
を追加して gem として認識するのを確認しました。

そして、
`gem "private-example-gem-repo", git: "git@github.com:znz/private-example-gem-repo"`
に書き換えて private repository を参照する状態にしました。

### 更新対象を追加

適当な gem ということでダウンロード数の多いものから適当に rack を選んで、最新が 3.0.7 だったので、
`bundle add rack -v 3.0.0`
として、ちょっと古いバージョンを追加しました。

### `.github/dependabot.yml` 追加

<https://github.com/dependabot/dependabot-core/issues/3587#issuecomment-833795131>
を参考にして、以下の内容の `dependabot.yml` を追加しました。

```yaml
version: 2

registries:
  github-octocat:
    type: git
    url: https://github.com
    username: x-access-token
    password: ${{secrets.DEPENDABOT_PRIVATE_KEY}}

updates:
  - package-ecosystem: "bundler"
    directory: "/"
    insecure-external-code-execution: "allow"
    registries: "*"
    schedule:
      interval: "daily"
      time: "07:45"
```

### `dependabot.yml` 確認

GitHub の Web から `dependabot.yml` を開くと、以下のような説明の吹き出しに「View update status」というボタンがあったので開きました。

```
Dependabot
Dependabot creates pull requests to keep your dependencies secure and up-to-date.

You can opt out at any time by removing the .github/dependabot.yml config file.
```

### secrets 設定

`DEPENDABOT_PRIVATE_KEY` がないというエラーがでていたので、
<https://github.com/settings/tokens>
から、「Fine-grained personal access tokens (Beta)」を作成しました。

トークンの権限は `znz/private-example-gem-repo` の Contents (と mandatory でついた Metadata) を Read-only だけにしました。

名前などは適当にわかりやすいものにしておけば良いので、
dependabot example token と Allow dependabot to private-example-gem-repo にして、
有効期限は1ヶ月のままにしました。

そして app の repo に戻って、Settings の (Security の) Secrets and variables の Dependabot から New repository secret で
Name: `DEPENDABOT_PRIVATE_KEY` で Secret は先程生成したトークンの secret を設定しました。

### チェック実行

そうこうしているうちに設定していた 07:45 UTC を過ぎてしまったので、「View update status」からログを開いて「Check for updates」でチェックをすぐに実行したところ、
「Bump rack from 3.0.0 to 3.0.7」という pull request が作成されました。

「View update status」のリンク先は Insights の Dependency graph の Dependabot でも開けました。

### registries の必要性チェック

`dependabot.yml` の `repositories:` の設定をコメントアウトして「Check for updates」で再度チェックしたところ、エラーになったので、必要な設定だと確認できました。

### private repository の更新もチェック

`private-example-gem-repo` の方に適当なコミットを追加して「Check for updates」をしたところ、
「Bump private-example-gem-repo from `6890fd2` to `a469b1b`」という pull request が作成されて、
`git:` で使っている private repositories の更新にも対応していることが確認できました。

## 参考

- [package-ecosystem](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file#package-ecosystem)
- [Dependabot can't update bundler dependency files that reference private git repositories](https://github.com/dependabot/dependabot-core/issues/3587)

## まとめ

private repositories を参照している `Gemfile` を dependabot で更新したい時は `dependabot.yml` の `repositories` に以下のような設定を追加して、
`insecure-external-code-execution: "allow"` も必要に応じて追加しておきます。

```yaml
registries:
  github-octocat:
    type: git
    url: https://github.com
    username: x-access-token
    password: ${{secrets.DEPENDABOT_PRIVATE_KEY}}
```

`secrets` は repo レベルでも org レベルでも良いので、Settings の Secrets and variables の Dependabot から、対象の repositories にアクセスできる token を設定しておきます。

動作確認するためのログは `dependabot.yml` を開いたときの「View update status」か、Insights の Dependency graph の Dependabot からたどりつけます。
