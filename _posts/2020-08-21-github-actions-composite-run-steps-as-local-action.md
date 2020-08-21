---
layout: post
title: "GitHub Actionsでcomposite run stepsを使って複数stepsをlocal actionにくくり出した"
date: 2020-08-21 19:15 +0900
comments: true
category: blog
tags: ruby github
---
[GitHub Actions: Composite Run Steps](https://github.blog/changelog/2020-08-07-github-actions-composite-run-steps/)
という機能が最近増えて、複数 step をまとめて共有できるようになったので、
ruby の snapshot アーカイブの作成でバージョンごとに重複する部分をまとめられないか試し始めました。
そのときにハマったポイントを紹介します。

<!--more-->

## 確認環境

<https://github.com/ruby/actions> で試しました。

## ファイル配置

local action として使う場合は `.github/actions/some-name/action.yml` として設置する必要がありました。

`some-name` の部分は任意の名前です。
エラーメッセージによるとファイル名は `action.yaml` でも良さそうです。
composite 以外の local action 用として `Dockerfile` も認識するようでした。

## checkout

snapshot 作成では主に <https://github.com/ruby/ruby> を使うので、
<https://github.com/ruby/actions> は checkout していなかったのですが、
local action を使う場合には local action のファイルを探すために checkout しておく必要がありました。

## Required property is missing: shell

workflow の方の step と違って、
action の方の step では shell の指定が必須でした。

## 感想

まだ使い始めたばかりですが、いくつかハマりポイントがあったので紹介してみました。
結局バージョンごとの分岐が増えるようだと共通化する意味がないどころか、
動作確認の手間が増えるだけなので、
どこまで使えるか徐々に試していこうと思っています。

## 参考

- [GitHub Actions: Composite Run Steps - GitHub Changelog](https://github.blog/changelog/2020-08-07-github-actions-composite-run-steps/)
- [Creating a composite run steps action](https://docs.github.com/en/actions/creating-actions/creating-a-composite-run-steps-action)
- [runs for composite run steps actions](https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#runs-for-composite-run-steps-actions)
