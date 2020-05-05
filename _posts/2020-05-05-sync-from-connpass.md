---
layout: post
title: "connpassのイベントをgitlab-ciで自動的に同期するようにした"
date: 2020-05-05 19:30 +0900
comments: true
category: blog
tags: linux
---
他の件で忙しくて、
2020-05-02 のイベントの案内を見逃していて、
<https://lilo.linux.or.jp/> の「What's New/おしらせ」の更新が間に合わなかったということがあったので、
<https://lilo.connpass.com/> でのイベントについては gitlab-ci で自動で同期するようにしました。

<!--more-->

## 環境

lilo.linux.or.jp の Web のメイン部分は履歴について公開許可を取るのが難しいので、
gitlab.com のプライベートになっています。

gitlab に push した時に webhook 経由で自動で git pull して反映する部分については
[以前の記事]({% post_url 2018-01-03-webhook-git-pull %})
に書いてあります。

## 同期スクリプト

柔軟性などを頑張るところでもないので、ある程度決め打ちで
https://lilo.connpass.com/ja.atom
から取ってきた情報を `index.html.ja` に反映するようにしました。

atom feed だと開催日時がメタデータとしては取れないようで、
summary の冒頭に入っている部分が自動生成のようだったので、
そこから取り出すことにしました。

終了判定は当日なら終了とみなすことにして、実行スケジュールを終了予定時刻の 17:00 にすることにしました。

置き換え対象も今の `li` の書き方を決め打ちで探すようにしました。

```ruby
#!/usr/bin/ruby
# coding: utf-8
# frozen_string_literal: true

# Settings on gitlab.com/lilo_jp/lilo_web
#
# - Pipeline schedule:
#   - cron: 0 17 * * *
#   - Time zone: Osaka
#
# - (Generate SSH key pair)
#
# - settings - ci_cd - variables:
#   - set SSH_PRIVATE_KEY
#
# - settings - repository - Deploy Keys:
#   - CI ssh key
#   - Check 'Write access allowed'

require 'open-uri'
require 'rss/atom'

week = {
  'Sun' => '日',
  'Mon' => '月',
  'Tue' => '火',
  'Wed' => '水',
  'Thu' => '木',
  'Fri' => '金',
  'Sat' => '土',
}

1.upto(10) do |n|
  puts Time.local(2020, 5, n).strftime('%Y/%m/%d（%a）').gsub(Regexp.union(week.keys), week)
end if false

def strip_tags(s)
  s.to_s.gsub(/<.+?>/, '')
end

html = File.read('index.html.ja')
new_entries = []

uri = URI('https://lilo.connpass.com/ja.atom')
feed = RSS::Parser.parse(uri.read, false)
feed.items.each do |item|
  unless /開催日時: (?<y>\d+)\/(?<m>\d+)\/(?<d>\d+)/ =~ item.summary.to_s
    raise "開催日時が見つかりません: #{item.summary}"
  end
  date = Time.local(y, m, d)
  li_left = date.strftime('<li>%Y/%m/%d（%a）に').gsub(Regexp.union(week.keys), week)
  li = li_left + "<a href=\"#{strip_tags(item.id).sub(/\?.*/, '')}\">#{strip_tags(item.title)}</a>が開催されま"
  if date < Time.now
    li += 'した'
  else
    li += 'す'
  end
  li += '。</li>'
  unless html.sub!(/^#{Regexp.quote(li_left)}.*/, li)
    new_entries << li + "\n"
  end
end

html.sub!(/(?<=<ul>\n)/) do
  new_entries.join('')
end

File.write('index.html.ja', html)
```

## .gitlab-ci.yml

GitHub Actions と違って、
`.gitlab-ci.yml` 自体には実行スケジュールが書けないのようなので、
スケジュール実行で実行する内容だけ書きました。

上のスクリプトのコメントに書いてあるように ssh の鍵ペアは別途生成して設定画面で設定しておきます。

```yaml
---
image: ruby:latest

job:on-schedule:
  only:
  - schedules
  script:
  - "which ssh-agent || ( apt-get update -y && apt-get install -y openssh-client )"
  - eval "$(ssh-agent -s)"
  - ssh-add <(echo "$SSH_PRIVATE_KEY")
  - install -m 700 -d ~/.ssh
  - ssh-keyscan -H "$CI_SERVER_HOST" >> ~/.ssh/known_hosts
  - git config --global user.name "gitlab-ci-runner"
  - git config --global user.email "webmasters@lilo.linux.or.jp"
  - git remote set-url --push origin git@$CI_SERVER_HOST:$CI_PROJECT_PATH.git
  - git checkout "$CI_COMMIT_REF_NAME"
  - git pull
  - env LANG=C.UTF-8 ruby update/sync-from-connpass.txt
  - if [[ "$(git status --porcelain=v1)" = " M index.html.ja" ]]; then
  -   git add index.html.ja
  -   git commit -m "Sync from connpass [ci skip]"
  -   git push
  - fi
```

docker の `ruby:latest` イメージはデフォルトだと POSIX locale になっていて、
``update/sync-from-connpass.txt:59:in `sub!': invalid byte sequence in US-ASCII (ArgumentError)``
というエラーになってしまったため、
`C.UTF-8` locale を使いました。

`if` のところが別々の `-` に入っているのが不思議な感じですが、
それぞれが `bash` スクリプトの 1 行になるようです。

## GitLab 上での設定

スクリプトのコメントに書いてあるような感じで設定しました。

スケジュールの間隔のパターンは「毎日 (午前4:00)」を選んでからカスタムを選びなおすと 17:00 に設定しやすかったです。

variables はスケジュールでも設定できるようでしたが、
他に CI で何かするかもしれないと思って、
`SSH_PRIVATE_KEY` はプロジェクト全体の方に設定しました。
Flags は、
Protect variable は private プロジェクトなら不要かと思ってチェックせずそのままにして、
Mask variable は複数行なので設定できませんでした。

この鍵ペアを使って git push する必要があるので、
デプロイキーに Write access allowed にチェックして追加しました。

## 実行タイミング

実際に 17:00 ちょうどに実行されるとは限らないようで、
17:05 ごろに実行されました。

最初の実行はエラーで失敗したので、数回修正と手動実行を繰り返して、
更新されるのを確認しました。

これで明日以降は lilo.connpass.com でイベントが作成されれば反映されるはずです。
