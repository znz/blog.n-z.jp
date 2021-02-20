---
layout: post
title: "GitHub Actionsのservicesでmysqldで起動時にしか指定できないオプションを変更する"
date: 2021-02-20 20:20 +0900
comments: true
category: blog
tags: github
---
GitHub Actions の services で options に docker コマンドのオプションは渡せますが、
docker image の entrypoint に対する引数が指定できないので、
mysqld の起動時にしか指定できない設定を変更するのに苦労しました。

<!--more-->

## 確認環境

2021年1月25日時点で
<https://github.com/znz/test-20210125/blob/c45451e2a1443d80b2cd2bb49d15d5be3a1a7f01/.github/workflows/test.yml>
の設定を使って確認しました。

その後の変更で指定できるようになっているかもしれませんが、確認していません。

## 設定方法

services で mysqld を使う方法を調べていてみつけた

```
options: >-
  --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
```

をつけました。
health check 関係の設定をしておくと、ちゃんと起動を待ってから steps の実行に進んでいるように見えます。

`docker cp ./mysql/conf.d/test.cnf ${{ "{{" }} job.services.mysql.id }}:/etc/mysql/conf.d/`
のように `/etc/mysql/conf.d` に設定ファイルをコピーで送りこんで、
`docker restart ${{ "{{" }} job.services.mysql.id }}` でリスタートして、
以下のように再起動待ちをすることで実現しました。

```
for sleep in 0 ${WAITS:- 1 2 4 8 15 25 100}; do
  sleep "$sleep"
  health_status=`docker inspect --format="{{ "{{" }}if .Config.Healthcheck}}{{ "{{" }}print .State.Health.Status}}{{ "{{" }}end}}" ${{ "{{" }} job.services.mysql.id }}`
  if [ 'starting' != "$health_status" ]; then
    exit 0
  fi
done
exit 1
```

## 試行錯誤した点

docker で指定するコンテナ ID として services で指定した mysql は使えず、
context から `${{ "{{" }} job.services.mysql.id }}` のように取り出す必要がありました。

services の options で `-v` を使って steps と共有するディレクトリをマウントできるのですが、
`uses: actions/checkout@v2` でチェックアウトするよりも前に services が起動するので、
起動時に参照してほしいファイルの共有には使えませんでした。
services 実行中に読み書きするファイルの共有には使えそうです。

[act](https://github.com/nektos/act) が services の実行に対応していない (設定ファイルのパースには対応していて何も使われていない) ので、
GitHub 上で試行錯誤するしかありませんでした。
