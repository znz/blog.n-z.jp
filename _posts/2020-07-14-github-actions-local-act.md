---
layout: post
title: "GitHub Actionsをactを使ってローカルで実行する"
date: 2020-07-14 12:30 +0900
comments: true
category: blog
tags: ruby github
---
<https://github.com/nektos/act> という GitHub Actions のワークフローをローカルの docker で試せるものがあるので、
ワークフローのデバッグに使ってみました。

<!--more-->

## 動作確認環境

- macOS 10.14.6
- Docker Desktop 2.3.0.3
- act version 0.2.10

## インストール

`brew install nektos/tap/act` でインストールしました。

## サンプル

動作確認用に以下のようなファイルを用意しました。

### Gemfile

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "rake"
```

### Rakefile

```ruby
task :default do
  puts 'OK'
end
```

### .github/workflows/act.yml

```yaml
name: test-on-act

on: [push]
jobs:
  test:
    runs-on: ubuntu-18.04
    steps:
    - run: pwd
    - run: ls -al /github /home
    - run: |
        if [ -d /github/home -a ! -e /home/runner ]; then
          ln -s /github/home /home/runner
        fi
    - uses: actions/checkout@v2
    - uses: ruby/setup-ruby@master
      with:
        ruby-version: 2.6 # Not needed with a .ruby-version file
    - run: bundle install
    - run: bundle exec rake
```

## 失敗例

### act そのまま

`act` をそのまま実行すると `node:12.6-buster-slim` という Debian 環境で実行されて `/etc/lsb-release` がないので、
`ruby/setup-ruby` が失敗します。

```
$ act
(略)
::error::ENOENT: no such file or directory, open '/etc/lsb-release'
(略)
```

### act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04

デフォルトの `node` のイメージを使った実行は色々と違いが多いようなので、
本番環境のデバッグなどでは Alternative runner images に書いてある
`act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04`
を使うのが無難です。

18GB 以上あるようなので、
Docker Desktop の disk image size を増やしておかないと、
一度 disk full でエラーになりました。

[Configuration](https://github.com/nektos/act#configuration) によると
`.actrc` を用意しておけば毎回指定しなくてもいいようです。

### bundler のエラー

次に `/github/home/.rubies/ruby-2.6.6/bin/gem` が `ENOENT` で失敗しました。

```
::error::There was an error when attempting to execute the process '/github/home/.rubies/ruby-2.6.6/bin/gem'. This may indicate the process failed to start. Error: spawn /github/home/.rubies/ruby-2.6.6/bin/gem ENOENT
```

`ruby/setup-ruby` のバイナリ は、他にも `/home/runner` の存在を前提としている部分があるようなので、
`ln -s /github/home /home/runner` で回避しました。

## 感想

本番の GitHub Actions の環境との違いですんなり動かないところもあるようですが、
バイナリの違いなどでローカルの `docker-compose` 環境で再現しないエラーのデバッグのような用途には便利に使えました。

`git commit` しなくても実行できるので、細かく再現条件を絞り込むなどの試行錯誤には良さそうでした。

## 成功時のログ

最後に参考のため、成功したときのログを載せておきます。

```
% act -P ubuntu-18.04=nektos/act-environments-ubuntu:18.04
WARN[0000] unable to get git repo: unable to find git repo
WARN[0000] unable to get git revision: unable to find git repo
WARN[0000] unable to get git ref: unable to find git repo
[test-on-act/test] 🚀  Start image=nektos/act-environments-ubuntu:18.04
WARN[0000] unable to get git repo: unable to find git repo
WARN[0000] unable to get git revision: unable to find git repo
WARN[0000] unable to get git ref: unable to find git repo
[test-on-act/test]   🐳  docker run image=nektos/act-environments-ubuntu:18.04 entrypoint=["/usr/bin/tail" "-f" "/dev/null"] cmd=[]
[test-on-act/test]   🐳  docker cp src=/(略)/act-test/. dst=/github/workspace
WARN[0001] unable to get git repo: unable to find git repo
WARN[0001] unable to get git revision: unable to find git repo
WARN[0001] unable to get git ref: unable to find git repo
WARN[0001] unable to get git repo: unable to find git repo
WARN[0001] unable to get git revision: unable to find git repo
WARN[0001] unable to get git ref: unable to find git repo
[test-on-act/test] ⭐  Run pwd
| /github/workspace
[test-on-act/test]   ✅  Success - pwd
WARN[0001] unable to get git repo: unable to find git repo
WARN[0001] unable to get git revision: unable to find git repo
WARN[0001] unable to get git ref: unable to find git repo
WARN[0001] unable to get git repo: unable to find git repo
WARN[0001] unable to get git revision: unable to find git repo
WARN[0001] unable to get git ref: unable to find git repo
[test-on-act/test] ⭐  Run ls -al /github /home
| /github:
| total 20
| drwxr-xr-x 5 root root 4096 Jul 14 04:28 .
| drwxr-xr-x 1 root root 4096 Jul 14 04:28 ..
| drwxr-xr-x 2 root root 4096 Jul 14 04:28 home
| drwxr-xr-x 2 root root 4096 Jul 14 04:28 workflow
| drwxr-xr-x 3 root root 4096 Jul 14 04:28 workspace
|
| /home:
| total 8
| drwxr-xr-x 2 root root 4096 Apr 24  2018 .
| drwxr-xr-x 1 root root 4096 Jul 14 04:28 ..
[test-on-act/test]   ✅  Success - ls -al /github /home
WARN[0001] unable to get git repo: unable to find git repo
WARN[0001] unable to get git revision: unable to find git repo
WARN[0001] unable to get git ref: unable to find git repo
WARN[0001] unable to get git repo: unable to find git repo
WARN[0001] unable to get git revision: unable to find git repo
WARN[0001] unable to get git ref: unable to find git repo
[test-on-act/test] ⭐  Run if [ -d /github/home -a ! -e /home/runner ]; then
  ln -s /github/home /home/runner
fi
[test-on-act/test]   ✅  Success - if [ -d /github/home -a ! -e /home/runner ]; then
  ln -s /github/home /home/runner
fi
WARN[0002] unable to get git repo: unable to find git repo
WARN[0002] unable to get git revision: unable to find git repo
WARN[0002] unable to get git ref: unable to find git repo
WARN[0002] unable to get git repo: unable to find git repo
WARN[0002] unable to get git revision: unable to find git repo
WARN[0002] unable to get git ref: unable to find git repo
[test-on-act/test] ⭐  Run actions/checkout@v2
WARN[0002] unable to get git repo: unable to find git repo
WARN[0002] unable to get git revision: unable to find git repo
WARN[0002] unable to get git ref: unable to find git repo
[test-on-act/test]   ✅  Success - actions/checkout@v2
WARN[0002] unable to get git repo: unable to find git repo
WARN[0002] unable to get git revision: unable to find git repo
WARN[0002] unable to get git ref: unable to find git repo
WARN[0002] unable to get git repo: unable to find git repo
WARN[0002] unable to get git revision: unable to find git repo
WARN[0002] unable to get git ref: unable to find git repo
[test-on-act/test] ⭐  Run ruby/setup-ruby@master
[test-on-act/test]   ☁  git clone 'https://github.com/ruby/setup-ruby' # ref=master
[test-on-act/test]   🐳  docker cp src=/(略)/.cache/act/ruby-setup-ruby@master dst=/actions/
[test-on-act/test]   ❓  ::group::Downloading Ruby
| https://github.com/ruby/ruby-builder/releases/download/enable-shared/ruby-2.6.6-ubuntu-18.04.tar.gz
[test-on-act/test]   💬  ::debug::Downloading https://github.com/ruby/ruby-builder/releases/download/enable-shared/ruby-2.6.6-ubuntu-18.04.tar.gz
[test-on-act/test]   💬  ::debug::Destination /tmp/d19ea388-29ef-4789-b0ea-93c4a370db15
[test-on-act/test]   💬  ::debug::download complete
| Took  12.55 seconds
[test-on-act/test]   ❓  ::endgroup::
[test-on-act/test]   ❓  ::group::Extracting Ruby
| [command]/bin/tar -xz -C /github/home/.rubies -f /tmp/d19ea388-29ef-4789-b0ea-93c4a370db15
| Took   0.68 seconds
[test-on-act/test]   ❓  ::endgroup::
[test-on-act/test]   ⚙  ::set-env:: PATH=/github/home/.rubies/ruby-2.6.6/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[test-on-act/test]   ❓  ::group::Installing Bundler
| [command]/github/home/.rubies/ruby-2.6.6/bin/gem install bundler -v ~> 2 --no-document
| Successfully installed bundler-2.1.4
| 1 gem installed
| Took   1.09 seconds
[test-on-act/test]   ❓  ::endgroup::
[test-on-act/test]   ⚙  ::set-output:: ruby-prefix=/github/home/.rubies/ruby-2.6.6
[test-on-act/test]   ✅  Success - ruby/setup-ruby@master
WARN[0019] unable to get git repo: unable to find git repo
WARN[0019] unable to get git revision: unable to find git repo
WARN[0019] unable to get git ref: unable to find git repo
WARN[0019] unable to get git repo: unable to find git repo
WARN[0019] unable to get git revision: unable to find git repo
WARN[0019] unable to get git ref: unable to find git repo
[test-on-act/test] ⭐  Run bundle install
| Don't run Bundler as root. Bundler can ask for sudo if it is needed, and
| installing your bundle as root will break this application for all non-root
| users on this machine.
| Fetching gem metadata from https://rubygems.org/.
| Resolving dependencies...
| Fetching rake 13.0.1
| Installing rake 13.0.1
| Using bundler 2.1.4
| Bundle complete! 1 Gemfile dependency, 2 gems now installed.
| Use `bundle info [gemname]` to see where a bundled gem is installed.
[test-on-act/test]   ✅  Success - bundle install
WARN[0026] unable to get git repo: unable to find git repo
WARN[0026] unable to get git revision: unable to find git repo
WARN[0026] unable to get git ref: unable to find git repo
WARN[0026] unable to get git repo: unable to find git repo
WARN[0026] unable to get git revision: unable to find git repo
WARN[0026] unable to get git ref: unable to find git repo
[test-on-act/test] ⭐  Run bundle exec rake
| OK
[test-on-act/test]   ✅  Success - bundle exec rake
```
