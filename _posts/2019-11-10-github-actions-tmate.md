---
layout: post
title: "GitHub Actionsでtmateを使ってシェルに繋いでデバッグする"
date: 2019-11-10 15:00 +0900
comments: true
category: blog
tags: github
---
[tmate](https://tmate.io/) を使って GitHub Actions の環境に ssh またはブラウザーから端末のシェルに繋いで、調査やデバッグなどができます。

<!--more-->

## 環境

- GitHub Actions の ubuntu または macos
- [Debugging with tmate](https://github.com/marketplace/actions/debugging-with-tmate)
- <https://github.com/mxschmitt/action-tmate>
- [tmate](https://tmate.io/)

最初に試した時は macos には対応していなかったのですが、今は対応していました。 Windows は対応していません。

## 概要

[tmate](https://tmate.io/) という tmux のセッションを公開してリモートから接続できるものがあって、
そのサーバー側を GitHub Actions 側で動かしてくれる [Debugging with tmate](https://github.com/marketplace/actions/debugging-with-tmate) があります。

それを `steps` に追加すると URL にログが出てくるので、それを開くとシェルに接続できます。
(ssh 接続もできるようですが使ったことがないのでどういう感じかはわかりません。)

## 問題点

GitHub Actions のログ表示部分の挙動が微妙で URL が見えないままログ表示が更新されずに止まってしまうことがあります。
そういう時は諦めてキャンセルして再実行するしかなさそうです。

セッションは共有のようなので、複数のブラウザーで同じ URL を開くと同じシェルに繋がって、片方で入力したものが他方にも見えるなど、
操作が混ざっていました。

## 公認?

Marketplace に登録されていて、
[Streamline your workflow with GitHub Actions from open source maintainers - The GitHub Blog](https://github.blog/2019-10-08-github-actions-from-open-source-maintainers/)
でも紹介されているので、
シェルアクセスは許可されていないのに無理やり穴を開けている、という扱いにはならなさそうなので、
そのあたりは心配しなくても良さそうです。

Actions のログに残らないからといって、マイニングとかに使うのは当然ダメだと思います。

## 使用例

実用的に使った例としては
[ruby/ruby の macos.yml](https://github.com/ruby/ruby/blob/4570284ce14c9f00114039e9b619584a8cad6a50/.github/workflows/macos.yml)
から slack 通知などを削ったものを自分のレポジトリに置いて以下のように書き換えて試していました。

```yaml
name: ruby-macos
on:
  repository_dispatch:
    types:
      - ruby-macos

jobs:
  latest:
    runs-on: macos-latest
    strategy:
      matrix:
        test_task: [ "check", "test-bundler", "test-bundled-gems" ]
      fail-fast: false
    if: "!contains(github.event.head_commit.message, '[ci skip]')"
    steps:
      - name: Disable Firewall
        run: |
          sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
          sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
      # Not using official actions/checkout because it's unstable and sometimes doesn't work for a fork.
      - name: Checkout ruby/ruby
        run: |
          git clone --depth=50 https://github.com/ruby/ruby src
      - name: Install libraries
        run: |
          export WAITS='5 60'
          cd src
          tool/travis_retry.sh brew update
          tool/travis_retry.sh brew install gdbm gmp libffi openssl@1.1 zlib autoconf automake libtool readline
      - name: Set ENV
        run: |
          echo '##[set-env name=JOBS]'-j$((1 + $(sysctl -n hw.activecpu)))
      - name: Autoconf
        run: |
          cd src
          autoconf
      - name: Configure
        run: |
          mkdir build
          cd build
          ../src/configure -C --disable-install-doc --with-openssl-dir=$(brew --prefix openssl@1.1) --with-readline-dir=$(brew --prefix readline)
      - name: Make
        run: make -C build $JOBS
      - name: Tests
        run: make -C build $JOBS -s ${{ matrix.test_task }}
        env:
          MSPECOPT: "-ff" # not using `-j` because sometimes `mspec -j` silently dies
          RUBY_TESTOPTS: "-q --tty=no"
          # Remove minitest from TEST_BUNDLED_GEMS_ALLOW_FAILURES if https://github.com/seattlerb/minitest/pull/798 is resolved
          TEST_BUNDLED_GEMS_ALLOW_FAILURES: "minitest"
      - name: Setup tmate session
        uses: mxschmitt/action-tmate@v1
        if: always()
```
