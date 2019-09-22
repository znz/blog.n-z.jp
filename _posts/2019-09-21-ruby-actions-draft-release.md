---
layout: post
title: "GitHub Actions で Ruby の tarball 作成などを試している"
date: 2019-09-21 20:00 +0900
comments: true
category: blog
tags: ruby github
---
[GitHub Actions](https://github.com/features/actions) で Ruby の snapshot tarball やリリース用の tarball の準備 (正式リリース版になるのはリリースアナウンス後) などを試しています。
現状のメモを残しておきます。

<!--more-->

## 環境

- まだ Beta 版の (HCL ではなく) YAML で記述するようになった GitHub Actions

## ソースコード

- [ruby/actions の .github/workflows](https://github.com/ruby/actions/tree/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows)
- [ruby/ruby の .github/workflows](https://github.com/ruby/ruby/tree/5cb283217b713605c6bddc527f96bbc773fd1fb9/.github/workflows)

## draft-release.yml

- [ruby/actions の draft-release.yml](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml)
- [ruby/ruby の draft-release.yml](https://github.com/ruby/ruby/blob/5cb283217b713605c6bddc527f96bbc773fd1fb9/.github/workflows/draft-release.yml)

### 概要

ruby/ruby の master branch の `tool/make-snapshot` を使ってリリース tarball の作成をして、
`.zip` なら `.zip.draft` のように `.draft` という拡張子を追加して `pub/tmp` に[アップロードして](https://github.com/ruby/actions/blob/bc874b1179c8b6bef71af4274fd2c8e2b5d9edd7/.github/workflows/draft-release.yml#L75)、
コミッター Slack に通知します。

その後、
[`needs: build-draft-release`](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L97)
で依存関係をつけている `check-draft-release` の方で `.draft` を削りつつダウンロードして、
`make check` によるテストと `make install` して `ruby -v` での動作確認をして、
成功か失敗かにかからわずコミッター Slack に通知しています。

通知を見て、リリース作業を進めるなり修正してパッケージを作り直したりすることを想定しています。

### 補足説明

- ブランチの `tool/make-snapshot` を使うこともあったようですが、元々はブランチからの安定版リリースでも trunk の `tool/make-snapshot` を使うことが想定されていたようです。
- `.draft` をつけているのは、正式リリースの tarball と間違えて使われてないようにするためで、正式リリースの時にはファイル名だけ変えれば良いという想定です。

### 使い方

`git clone https://github.com/ruby/actions`
した作業ディレクトリで
`git tag draft/v2_6_4; git push --tags; git tag -d draft/v2_6_4; git push --delete origin draft/v2_6_4`
のように動作確認していました。

`draft/` をつけているのは
`git clone git@git.ruby-lang.org:ruby.git`
した作業ディレクトリでシェルの履歴から間違えて実行しても問題が起きる可能性を減らすためで、本質的には不要です。

`ruby/ruby` の方では

```yaml
on:
  push:
    tags:
      - 'v*'
```

にしたので、 `v2_6_5` や `v2_7_0_preview2` などが `git push --tags` されると作成されるはずです。

### 内容

<https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions>
で取れると書いてある情報がまだ取れないものがある (`steps` の `output` など) ようなので、
最初に
[Example printing context information to the log file](https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions#example-printing-context-information-to-the-log-file)
のように情報をダンプしています。

配布 tarball にはバージョン管理されていない (`git add` されていない) けど含める必要があるファイルがあり、
その中に `ruby` コマンド (ちゃんと確認していないけど `miniruby` までで良いかも) を使って生成するものもあるので、
[ruby のビルドに必要なものをインストール](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L37-L41)
しています。

`Checkout ruby/ruby for tool/make-snapshot` では、
`uses: actions/checkout` を使わずに[自前で `git clone`](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L42-L43) しています。
最新の `tool/make-snapshot` だけあれば良いので `--depth=1` にしています。
[ubuntu.yml](https://github.com/ruby/ruby/blob/5cb283217b713605c6bddc527f96bbc773fd1fb9/.github/workflows/ubuntu.yml#L50) には
「Not using official actions/checkout because it's unstable and sometimes doesn't work for a fork.」と書いてあって、
それを参考にしたのと、慣れている `git` コマンド直接の方がわかりやすかったので `git clone` を使っていますが、
`uses:` に変更しても良いのかもしれません。

[Make pkg](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L44-L59) では
`$GITHUB_REF` から `draft/` を削って
タグから `tool/make-snapshot` に合わせたバージョン表記に変換して `$TARGET_VERSION` に入れて、
2.7 より前なら `svn` からのリリースなので `tool/make-snapshot -svn pkg ${TARGET_VERSION}` を使い、
2.7 以降なら `git` からのリリースなので `tool/make-snapshot -srcdir=ruby pkg ${TARGET_VERSION}` を使うようにしています。
`-srcdir=ruby` の場合は `ChangeLog` の生成に必要なものを追加で `git fetch` しています。
(`-git` は別途 `git clone` とかしてくるのが無駄なのもあって廃止されました。)

[Check pkg](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L60-L68) では
狙った `revision` からちゃんと作成されているか、 `ChangeLog` がちゃんと生成されてそうか、などを確認できるようにするための表示をしています。

[Upload s3](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L69-L80) では
S3 にアップロードしています。
別 job に受け渡しできる artifacts 機能があれば使いたかったのですが、なさそうだったので直接 S3 にあげています。
draft release では別にそれでも全く問題ないのですが、 snapshot の方でダメな状態のものになることがあるのがちょっと気になっています。

最後に失敗していたらコミッター Slack に通知しています。

S3 アップロードまで成功していたら
[`needs: build-draft-release`](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L97)
で依存関係にしている `check-draft-release` の job が実行されます。

まず
[Install libraries](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L100-L104)
で配布 tarball が依存してはいけない bison, autoconf, ruby などを明示的に除外してビルドに必要なパッケージをインストールしています。

次に
[Download draft](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L105-L110)
で `.draft` を削りつつ、サイズの一番小さい `tar.xz` をダウンロードして、
[Extract](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L111-L116)
で展開しています。

そして [ruby/ruby の ubuntu.yml](https://github.com/ruby/ruby/blob/5cb283217b713605c6bddc527f96bbc773fd1fb9/.github/workflows/ubuntu.yml) でやっているテストから `make check` を抜き出したものを実行しています。

それからちゃんとインストールできるかどうかのテストのために
[`make install` と `ruby -v`](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/draft-release.yml#L130-L135)
も実行しています。
snapshot の方で 2.4 は GitHub Actions では `make check` が失敗するので `make test` を使っていて、
あまり使われない draft-release にバージョン分岐を入れて複雑にするのは避けたかったので、
`if: always()` で `make check` の失敗にかかわらず `make install` と `ruby -v` を実行するようにしました。
(`make` 以前で失敗していても実行されますが、気にするようなものでもないと判断)

テスト後は成功か失敗かにかからわずコミッター Slack に通知して、リリース作業を進めるなり修正してパッケージを作り直したりすることを想定します。

### slack 通知

`ruby/ruby` 用に作成された `k0kubun/action-slack` をそのまま使っています。

ubuntu だけではなく macos と windows にも対応する必要があったため node で書いているということで、
ubuntu のみなら
[Implement Slack notification for Actions](https://github.com/ruby/ruby/commit/2f6c8ed26eec4ad2d2fdaa0823cc63ba32f4c7a2)
のように `.github/actions/notify-slack/action.yml` のようなファイルを用意して
docker で ruby を実行する、という方法でも良いそうです。

この方法は別の大変さがあるので、結局 `k0kubun/action-slack` をそのまま使いました。

## snapshot

- [snapshot.yml](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/snapshot.yml)

### 概要

以下のファイルを作成・更新して、 tarball からの `make` などの基本的なテストもしています。

- <https://cache.ruby-lang.org/pub/ruby/> の `snapshot.*` と `stable-snapshot.*`
- <https://cache.ruby-lang.org/pub/ruby/snapshot/> 以下の `snapshot-ブランチ名.*`

### 移行措置

`pub/ruby` 直下の snapshot と stable-snapshot は `github.com/ruby/snapshot` から作成した Docker Image を Heroku Scheduler で動かして作成していたものを移行したものです。

snapshot 以外の GitHub Actions のファイルも置くことになって `github.com/ruby/snapshot` が `github.com/ruby/actions` に rename されています。

GitHub Actions の Beta がとれたら完全に移行完了にして `github.com/ruby/actions` から Heroku Scheduler での実行用ファイルを削除する予定です。

### トリガー

```yaml
on:
  schedule:
    - cron: '30 12 * * *' # Daily at 12:30 UTC
```

で Heroku Scheduler の時の実行タイミングに合わせて 12:30 UTC (21:30 JST) に動かしています。

GitHub Actions に移行直後はテスト的に頻度をあげていましたが、
`make check` が失敗するタイミングで作成されてしまうことがあったため、
開発が落ち着いている可能性が高い以前通りの時間のみに戻しました。

### 内容

Draft Release の元になった内容のため、基本的にはほぼ同じです。

### matrix

matrix を試そうとしたこともあったのですが、

- tarball を作成してアップロード → チェック

という基本的な流れが、

- snapshot tarball を作成してアップロード → snapshot チェック
- stable-snapshot tarball を作成してアップロード → stable-snapshot チェック

という感じで同時に流れて欲しかったのに、
matrix だと needs は job 全体を待ってしまうらしく、

- tarball 作成とアップロード → すべて完了 → snapshot チェック

という感じで、作成とアップロード待ちを matrix のみにできず、
同時実行のために同じ job の続きの step にすると、
クリーンな環境で `make` できること、というのがチェックしにくくなる、
ということで、諦めて個別に書いています。

その副作用として `ruby_2_4` ブランチだと `make check` に失敗するので `make test` だけにしている、
というのが条件分岐が混ざって複雑な記述になることなく書けています。

その代わり、重複が多く長くなっています。

今のところ
yaml の anchor を使うと

```text
- Your workflow file was invalid: .github/workflows/dump.yml: Anchors are not currently supported. Remove the anchor 'echo-example'
```

のように明示的に拒否されるようなので、
yaml の機能でまとめるということもできません。

### 困っている点

Fastly-Soft-Purge をつけているるからか、
内容に変更がないとキャッシュが消えないことがあるようで、
個人的に動かしている Zabbix による last-modified の監視で変化しないことがあって困っています。

## update\_index

- [update\_index.yml](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/update_index.yml)

### 概要

[Rakefile](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/Rakefile)
で実行していた `update_index` を
[tool/snapshot/update\_index.rb](https://github.com/ruby/actions/blob/master/tool/snapshot/update_index.rb)
に切り出して実行するようにしたもので、
3 時間ごとに <https://cache.ruby-lang.org/pub/ruby/index.txt> を更新しています。

```yaml
on:
  schedule:
    - cron: '17 1-22/3 * * *'
```

### トリガー

snapshot などは含まれないため、
ほとんど更新されないので、
何か良いトリガーがあれば変えたいのですが、
簡単に使えるものはなさそうなので、定期実行のままにしています。

Webhook などで GitHub Actions の実行をトリガーできるのなら、
S3 側に設定を追加してもらって、
ファイルの追加・削除・変更でトリガーを呼んでもらえるようにできると良さそうです。

## coverage と doxygen

- [coverage.yml](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/coverage.yml)
- [doxygen.yml](https://github.com/ruby/actions/blob/d9a3e94059653e252cc51c371684c278522ef47a/.github/workflows/doxygen.yml)

### 概要

コミットに紐づいていなくて定期実行なので、
ruby/ruby から移動してきたものです。

定期的に coverage をとったり doxygen を作成したりして rubyci にアップロードしています。

GitHub Actions の Beta が取れたら正式運用になる予定で、
今のところアップロードされているファイルは公開されているものなので自由に参照しても構わないですが、
非公式扱いです。

## ruby/ruby 側の他の actions

### check\_branch

- [check\_branch.yml](https://github.com/ruby/ruby/blob/5cb283217b713605c6bddc527f96bbc773fd1fb9/.github/workflows/check_branch.yml)

github と git.ruby-lang.org の双方向同期のための仕組みの一つで、
master への pull request だけでマージボタンを押せるようにしているそうです。

### 各 OS での CI

- [macos.yml](https://github.com/ruby/ruby/blob/5cb283217b713605c6bddc527f96bbc773fd1fb9/.github/workflows/macos.yml)
- [ubuntu.yml](https://github.com/ruby/ruby/blob/5cb283217b713605c6bddc527f96bbc773fd1fb9/.github/workflows/ubuntu.yml)
- [windows.yml](https://github.com/ruby/ruby/blob/5cb283217b713605c6bddc527f96bbc773fd1fb9/.github/workflows/windows.yml)

それぞれの OS での CI です。

OS ごとにファイルが別れているのか良いかどうかはよくわかりませんが、
触り始める前にこうなっていたので、
今のところそのままにしています。

全部 clone するとタイムアウトするか何か問題があったらしく `--depth=50` がついています。
少なすぎると一度に `push` された時などに足りないことがあったか何かで、今は 50 になっています。

その他、色々と試行錯誤の結果、今の状態になっています。

## GitHub Actions 全体で困っている点

- 他の CI の `[ci skip]` に相当する機能がない
- `echo '##[set-env name=JOBS]'-j$((1 + $(nproc --all))` のように `##[なにか]` でできることが色々ありそうなのにドキュメントが見当たらない
- `set-env` しても `run:` の中では見えても `if:` の中で見えないので `[ci skip]` 的な用途に使えない (ログ表示で灰色の四角にできないのでスキップされたかどうかをログを開かないといけなくてあまり意味がない)
- Slack 通知で今実行している job や step へのログへのリンクが作成できない
- 特に schedule で実行していると `github.com/ruby/ruby/commit/コミットハッシュ/checks` も最新のログへのリンクにしかならないので、失敗したタイミングのログへのリンクが通知に残せない
