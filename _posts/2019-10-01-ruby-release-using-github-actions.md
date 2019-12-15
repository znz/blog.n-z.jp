---
layout: post
title: "GitHub Actions をリリース作業の一部に使った Ruby がリリースされました"
date: 2019-10-01 23:30 +0900
comments: true
category: blog
tags: ruby github actions
---
[GitHub Actions](https://github.com/features/actions) で Ruby リリース用の tarball の準備 (正式リリース版になるのはリリースアナウンス後) をした初リリースがありました。

<!--more-->

## リリースアナウンス

セキュリティリリースのため、影響がありそうなら速やかに更新しましょう。
(shell.rb や WEBrick を本番環境で使うことは少ないとは思いますが。)

- <https://www.ruby-lang.org/ja/news/2019/10/01/ruby-2-6-5-released/>
- <https://www.ruby-lang.org/ja/news/2019/10/01/ruby-2-5-7-released/>
- <https://www.ruby-lang.org/ja/news/2019/10/01/ruby-2-4-8-released/>

## 発覚した問題点 (1) トリガー

<https://github.com/ruby/ruby> のデフォルトブランチ (master) の `.github/workflows/draft-release.yml` にいれておけば
タグを push した時にも実行されると思っていたのですが、
タグがさす安定版のコミットツリーには `.github/workflows/draft-release.yml` がないため、
`v2_6_5` などのタグが push されたタイミングでは実行されませんでした。

そのため、少し待ってみても <https://github.com/ruby/ruby/actions> に出てこないのを確認して、
<https://github.com/ruby/actions> の方に `draft/v2_6_5` などのタグを push して
(そしてトリガーに使うだけで残す必要はないのですぐ消して)
tarball を作成しました。

## 発覚した問題点 (2) 通知

Slack 通知のタイミングは

- draft-release workflow
  - tarball 作成をする job
    - 失敗時に通知
  - make check をする job
    - 失敗時に通知
    - 成功時に通知

としていたのですが、
tarball 作成も make check もある程度時間がかかるため、
tarball を作成して S3 にアップロードが完了した段階での通知もあった方が良いとわかりました。

今まではリリース作成する人が手元で tarball 作成して共有してからテストしていたので、
リリース作業の流れとしても、いくつかの環境でのチェックの一つとして同時実行される方が合理的でした。

## tarball 作成のトリガー

とりあえず今回は以下のようにコマンドを実行していましたが、スクリプトにした方が良いのでは、
という意見があったので、
[tool/trigger-draft-release.sh](https://github.com/ruby/actions/blob/4a7411bb7a7e5285ca14e79c4ab27010f7b1da22/tool/trigger-draft-release.sh)
としていれました。

```
sh -exc 'draft_v=v2_6_5; git tag draft/$draft_v; git push --tags; git tag -d draft/$draft_v; git push --delete origin draft/$draft_v'
sh -exc 'draft_v=v2_5_7; git tag draft/$draft_v; git push --tags; git tag -d draft/$draft_v; git push --delete origin draft/$draft_v'
sh -exc 'draft_v=v2_4_8; git tag draft/$draft_v; git push --tags; git tag -d draft/$draft_v; git push --delete origin draft/$draft_v'
```

この前の [GitHub Actions Meetup Osaka #0](https://gaug.connpass.com/event/144698/) で
`repository_dispatch` イベントを使えば外部からの http リクエストでトリガーできると知りました。
それを使うように変えるとしても、スクリプトにしておけば、実行手順は変えなくてすみそうです。

ただし、 `repository_dispatch` をトリガーするのに
[Personal access tokens](https://github.com/settings/tokens)
が必要だったので、そこをどうするのかが悩ましいです。

## 今後の予定

[upload-artifact](https://github.com/actions/upload-artifact) と [download-artifact](https://github.com/actions/download-artifact) で
同じ workflow の中の job をまたいだファイルのやりとりもできるようなので、
snapshot の方では `make check` に失敗したものは S3 にアップロードしないとか、
リリースの方ではリリースアナウンスに必要なハッシュ値を artifact においてダウンロードしやすくする、
などを試したいと思っています。
