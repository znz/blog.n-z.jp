---
layout: post
title: "bitclustをGitHub Actionsでgem pushしてリリースしている"
date: 2020-05-19 21:15 +0900
comments: true
category: blog
tags: ruby github
---
最近は
[gempush.yml](https://github.com/rurema/bitclust/blob/2abb463d73fda5aa942d9321901e51c14b3091c1/.github/workflows/gempush.yml)
のように
GitHub Actions で gem push して bitclust 関連の gem をリリースしているので、
その手順の紹介です。

<!--more-->

## 参考情報

<https://github.com/actions/starter-workflows/blob/e3d245e1f3ec28f37a077909ded6e00c72f5338a/ci/gem-push.yml>
に参考にできそうな設定があったので、これをベースにして設定しました。

## 現 GitHub Packages (旧 GitHub Package Registry)

設定例の YAML では GPR という略称で書かれている
`rubygems.pkg.github.com` は repository と同名の gem しか push できないらしく、
<https://github.com/rurema/bitclust> では `bitclust-core`, `bitclust-dev`, `refe2` という gem なので
エラーになっていたので、今は使っていません。

このブロク記事を書いている時にさらに調べてみると、
[Publishing multiple packages to the same repository](https://help.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-rubygems-for-use-with-github-packages#publishing-multiple-packages-to-the-same-repository)
という情報を見つけたので、
以下のように `gem.metadata` の`github_repo` を適切に設定すればいけるのかもしれません。

```
gem.metadata = { "github_repo" => "ssh://github.com/OWNER/REPOSITORY" }
```

## RubyGems.org への push 準備

https://rubygems.org/profile/edit で確認できる API キーを使います。

その時に MFA Level を UI Only に下げておきます。
GitHub Actions では OTP を入力する手段がないので、
今のところ一時的にセキュリティレベルを下げるしかなさそうです。

次に API キーを
https://github.com/rurema/bitclust/settings/secrets
で `RUBYGEMS_AUTH_TOKEN` に設定します。

## push

`gempush.yml` で以下のように設定しているので、マッチするタグである `v1.2.5` のようなものを push するとリリースされます。

```
on:
  push:
    tags:
      - 'v*'
```

実行例:

```
% git pull
Already up to date.
% git grep -F 1.2.5
lib/bitclust/version.rb:  VERSION = "1.2.5"
% git tag -s -m '' v1.2.5
% git push --tags
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 795 bytes | 795.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:rurema/bitclust
 * [new tag]         v1.2.5 -> v1.2.5
%
```

## リリース確認

[GitHub Actions のログ](https://github.com/rurema/bitclust/runs/688817480?check_suite_focus=true)や
<https://rubygems.org/gems/refe2>
をみて、リリースされているのを確認します。

## リリース後作業

個人の repository なら残しておいても良いのかもしれませんが、
他の人も push できる repository だと他の人が使えてしまうため、
登録した Secret を Remove します。

rubygems.org で MFA Level を UI and API に戻しておきます。

最後に忘れずに `lib/bitclust/version.rb` のバージョンを更新して push しておきます。
