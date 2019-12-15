---
layout: post
title: "GitHub Actions Meetup Osaka #1 に参加しました"
date: 2019-11-26 23:59 +0900
comments: true
category: blog
tags: github actions
---
[GitHub Actions Meetup Osaka #1](https://gaug.connpass.com/event/152956/)に参加して発表してきました。

<!--more-->

## LT 1

GitHub Actions で cloudflare のキャッシュをクリアする話でした。

以下メモです。

- heroku, github, cloudflare
- github actions で cloudflare のキャッシュをクリア
- api.cloudflare.com/client/v4/zones で zone の id 取得
- Cache Purge 用の API Token は別途生成
- secrets に Zone ID と API Token 設定

## 発表資料

LT の予定だったので、短い発表資料だけ用意していました。

{% include slides.html author="znz" slide="github-actions-osaka-meetup-osaka-1" title="workflow,job,step の使い分けの基準を考える" slideshare="znzjp/workflowjobstep" speakerdeck="znz/workflow-job-step-falseshi-ifen-kefalseji-zhun-wokao-eru" github="znz/github-actions-osaka-meetup-osaka-1" %}

## その他

メインの発表予定の人が体調不良で不参加になってしまって、時間があったので、
質疑応答から話を広げて ruby/ruby や ruby/actions でどのような感じで使っているのか実際のログやファイルを見ながら紹介していました。

## 懇談

発表の後は懇談の時間でした。
