---
layout: post
title: "systemdのtimerの時間が重なって想定外の挙動になっていた"
date: 2025-11-30 23:10 +0900
comments: true
category: blog
tags: linux systemd
---
概要としては systemd timer でデータベースのバックアップをしていて、
ディレクトリの中身のサイズの単調増加でバックアップ成功を確認していたら、
古いファイルの削除は systemd-tmpfiles に任せていたのとタイミングが重なって、
サイズの単調増加チェックが失敗するようになった、
という話です。

<!--more-->

## バックアップ設定

バックアップ先は `/srv/postgres-export` というディレクトリにしています。

バックアップ用スクリプトとして `/srv/postgres-export.sh` に以下の内容を用意しています。
最後の `test` でダンプが成功して容量が単調増加しているのを確認しています。

```bash
#!/bin/bash -x
set -euo pipefail
umask 027
DUMP_DIR="/srv/postgres-export"
OLD_TOTAL_SIZE=$(du -b "$DUMP_DIR" | awk '{print $1}')
if [ -z "$(dokku postgres:list)" ]; then
  echo "$0: No databases"
  exit 0
fi
for db in $(dokku postgres:list | awk 'NR>=2{print $1}'); do
  DUMP_FILE="$DUMP_DIR/${db}_$(date +'%Y%m%d%H%M%S')".dump
  dokku postgres:export "${db}" </dev/null >"$DUMP_FILE"
  test -s "$DUMP_FILE"
done
NEW_TOTAL_SIZE=$(du -b "$DUMP_DIR" | awk '{print $1}')
test "$OLD_TOTAL_SIZE" -lt "$NEW_TOTAL_SIZE"
```

`/srv/postgres-export.sh` を dokku ユーザー権限で定期実行しています。
バックアップ先は `ExecStartPre` に `+` をつけて root 権限で `install` コマンドを実行してパーミッションなどを含めて期待している状態にしています。
`OnFailure` で1人Slackに通知して失敗に気付けるようにしていたので、今回の失敗に気がつきました。

```ini
# /etc/systemd/system/postgres-export.service
[Unit]
Description=Backup dokku postgres
After=docker.service
Requires=docker.service
OnFailure=notify-to-slack@%n.service

[Service]
Type=oneshot
ExecStartPre=+/usr/bin/install -o dokku -g dokku -m 0750 -d /srv/postgres-export
ExecStart=/srv/postgres-export.sh
User=dokku
```

systemd timer で3時と15時に実行しています。

```ini
# /etc/systemd/system/postgres-export.timer
[Unit]
Description=Backup dokku postgres

[Timer]
OnCalendar=*-*-* 3,15:00
Persistent=true

[Install]
WantedBy=timers.target
```

## 通知設定

本筋とは関係ないですが、通知の設定もついでに公開しておきます。

こんな感じの `/usr/local/bin/notify-to-slack.rb` で通知しています。

```ruby
#!/usr/bin/ruby
# frozen_string_literal: true
require 'json'
require 'uri'
require 'open3'
require 'net/http'

unless ENV.key?('SLACK_WEBHOOK_URL')
  abort('Set SLACK_WEBHOOK_URL into /etc/systemd/system/notify-to-slack.env')
end
uri = URI(ENV['SLACK_WEBHOOK_URL'])
unit = ARGV.shift
text, status = Open3.capture2e(*%W"systemctl status --full #{unit}")
payload = { text: text }
payload[:username] = ENV['SLACK_USERNAME'] if ENV.key?('SLACK_USERNAME')
payload[:icon_emoji] = ENV['SLACK_ICON_EMOJI'] if ENV.key?('SLACK_ICON_EMOJI')
headers = {
  'content-type' => 'application/json',
}
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.set_debug_output $stderr if $DEBUG
response = http.post(uri.path, payload.to_json, headers)
puts "#{response} #{response.body}"
```

service unit はこんな感じです。

```ini
# /etc/systemd/system/notify-to-slack@.service
[Unit]
Description=Notify systemd %i unit status to slack

[Service]
Type=oneshot
ExecStart=/usr/local/bin/notify-to-slack.rb %i
User=nobody
Group=systemd-journal
# SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
EnvironmentFile=/etc/systemd/system/notify-to-slack.env
```

EnvironmentFile の内容は以下のような感じです。
置く場所は特に決まった場所がなさそうなので、
`service` ファイルと同じ場所に owner=root group=systemd-journal mode=0440 で置いています。

```sh
SLACK_USERNAME="hostname"
SLACK_ICON_EMOJI=":red_circle:"
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

## systemd-tmpfiles

`/etc/tmpfiles.d/postgres-export.conf` に

```text
d /srv/postgres-export - - - 7d
```

という設定をして1週間分残すようにしています。
`ExecStartPre` の方でパーミッションなどは設定しているので、こちらでは `-` にしています。

`systemctl list-timers` で確認すると、
`systemd-tmpfiles-clean.timer` が毎日 `15:00:14` で動いていました。

設定は以下の通りでした。

```ini
# /lib/systemd/system/systemd-tmpfiles-clean.timer
#  SPDX-License-Identifier: LGPL-2.1+
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

[Unit]
Description=Daily Cleanup of Temporary Directories
Documentation=man:tmpfiles.d(5) man:systemd-tmpfiles(8)

[Timer]
OnBootSec=15min
OnUnitActiveSec=1d
```

```ini
# /lib/systemd/system/systemd-tmpfiles-clean.service
#  SPDX-License-Identifier: LGPL-2.1+
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

[Unit]
Description=Cleanup of Temporary Directories
Documentation=man:tmpfiles.d(5) man:systemd-tmpfiles(8)
DefaultDependencies=no
Conflicts=shutdown.target
After=local-fs.target time-set.target
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=systemd-tmpfiles --clean
SuccessExitStatus=DATAERR
IOSchedulingClass=idle
```

## 原因

`postgres-export.timer` が 15:00:00 に動いて、
`systemd-tmpfiles-clean.timer` が 15:00:14 に動いているため、
`OLD_TOTAL_SIZE` の取得後、バックアップ中に `systemd-tmpfiles --clean` が動いてしまって、
`NEW_TOTAL_SIZE` の取得のタイミングではサイズが減っているのが原因でした。

Slack 通知は 15 時だけきていて 3 時にはきていなかったので、
その理由もこれで説明できます。

## 対応案

バックアップのサイズ制限が `systemd-tmpfiles` に依存しているので、
`postgres-export.timer` も `OnBootSec` と `OnUnitActiveSec` に変更して実行タイミングをずらすのが一番確実そうです。

個人サーバーで厳密な処理でもないので、
設定はこのままで、
次の再起動でタイミングがずれて解決でも、
大きな問題は良さそうです。

## まとめ

systemd timer のタイミングの組み合わせでたまたま些細な問題が起きたという例を紹介しました。

組み合わせが重要な timer が複数あるときは実行時刻や実行間隔の設定で問題が起きないように注意した方が良さそうです。
