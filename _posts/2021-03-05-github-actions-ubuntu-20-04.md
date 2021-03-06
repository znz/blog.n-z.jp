---
layout: post
title: "GitHub Actionsのubuntu-20.04対応"
date: 2021-03-05 23:30 +0900
comments: true
category: blog
tags: github ubuntu
---
GitHub Actions の ubuntu-latest が ubuntu-18.04 から ubuntu-20.04 に変わっても影響ないだろうと思っていたところが影響を受けていたので、その対応をした話です。

<!--more-->

## Gemfile (Gemfile.lock) で指定されているバージョン問題

`bundle install` が以下のメッセージで失敗していたので、
[Gemfile と Gemfile.lock を更新](https://github.com/ruby/actions/commit/4e67bce1683d2ee9c749e3caeca93e23f7cc7aa1)しました。

```
/usr/lib/ruby/2.7.0/rubygems.rb:275:in `find_spec_for_exe': Could not find 'bundler' (1.17.3) required by your /home/runner/work/actions/actions/tool/snapshot/Gemfile.lock. (Gem::GemNotFoundException)
To update to the latest version installed on your system, run `bundle update --bundler`.
To install the missing version, run `gem install bundler:1.17.3`
	from /usr/lib/ruby/2.7.0/rubygems.rb:294:in `activate_bin_path'
	from /usr/local/bin/bundle:23:in `<main>'
Error: Process completed with exit code 1.
```

さらに、手元だと ruby 2.7.2 で ubuntu-20.04 だと ruby 2.7.0 ということで問題がおきたので、
[Gemfile から ruby のバージョン指定を削除](https://github.com/ruby/actions/commit/b268e5e78bc8ba3a958c6d4c69752fed664c02e9)しました。
昔の Heroku で動していたときに必要だっただけで、今は不要でした。

```
Your Ruby version is 2.7.0, but your Gemfile specified ~> 2.7.2
```

## ruby2.5 から ruby2.7

[apt で参照するパッケージを ruby2.5 から ruby2.7 に変更](https://github.com/ruby/actions/commit/a246bb70628174cbbb7e1182b3d06584253f444b)しました。

`apt-get build-dep` でも使っているので、 `ruby` パッケージだとダメなので仕方がないです。
`ruby` パッケージの依存から取り出すようにしても良いかもしれませんが、
取り出す部分が将来の ubuntu で壊れる可能性もあるので、固定表記の方がわかりやすくて良いかと思いました。

`coverage.yml` と `doxygen.yml` は確実に ubuntu のバージョンに依存しているということで、
`runs-on: ubuntu-latest` を `runs-on: ubuntu-20.04` にした方が良いのかもしれません。

## bundle install の --path の DEPRECATED 対応

[警告通りに書き換え](https://github.com/ruby/actions/commit/28a38e62f4b0ae7ec16dcb4714a2cd7c0c26c373)ました。
これも Heroku で動かしていたときの名残のようなので、消してしまっても良いのかもしれません。

```
[DEPRECATED] The `--path` flag is deprecated because it relies on being remembered across bundler invocations, which bundler will no longer do in future versions. Instead please use `bundle config set path 'vendor/bundle'`, and stop using this flag
```

## aws s3 cp のエラー

`aws s3 cp` が `<botocore.awsrequest.AWSRequest object at 0xHHHHHHHHHHHH>` のような謎のメッセージを出して失敗するようになっていました。
「`botocore.awsrequest.AWSRequest object`」で検索すると、
[英語の記事](https://florian.ec/blog/github-actions-awscli-errors/)でリージョンを指定すれば良さそうとわかったので、
[`AWS_DEFAULT_REGION` を設定](https://github.com/ruby/actions/commit/3e18babbed5d960c97be5b75ea36b2f5c0c2006c)しました。
s3 はリージョンは無関係のはずなので、適当に `us-west-2` にしました。

## 感想

apt で入る ruby のバージョンアップによる影響は事前に気付いていてもおかしくない内容でしたが、
awscli の挙動の変化は予想外だったので、エラーメッセージに見えない謎のメッセージで検索するのを後回しにしてしまって、
解決するのに時間がかかってしまいました。
