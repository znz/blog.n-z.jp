---
layout: post
title: "Omnibus GitLab の Mattermost のバックアップ設定"
date: 2018-03-27 21:35 +0900
comments: true
category: blog
tags: gitlab linux ubuntu
---
[Omnibus GitLab](https://docs.gitlab.com/omnibus/) の Mattermost のバックアップがちゃんと取れていなかったので直しました。

<!--more-->

## 対象バージョン

- gitlab-ce パッケージ 10.5.5-ce.0

## 現在の実装

[provision/roles/znz.gitlab-ce/files/gitlab-misc-backup.sh](https://github.com/znz/ansible-role-gitlab-ce/blob/04c671f963080ae0587507f98efb7f3791a0ac94/files/gitlab-misc-backup.sh):

```sh
#!/bin/sh
set -e
BACKUPS=/var/opt/gitlab/backups
umask 077
if [ ! -S /var/opt/gitlab/postgresql/.s.PGSQL.5432 ]; then
  sleep 5
fi
tar acf "$BACKUPS/$(date +%s_%Y_%m_%d)_etc_gitlab.tar.xz" -C / etc/gitlab
tar acf "$BACKUPS/$(date +%s_%Y_%m_%d)_var_opt_gitlab_mattermost.tar.xz" -C / var/opt/gitlab/mattermost
/opt/gitlab/embedded/bin/chpst -u gitlab-psql /opt/gitlab/embedded/bin/pg_dump -Fc -p 5432 -h /var/opt/gitlab/postgresql mattermost_production > "$BACKUPS/$(date +%s_%Y_%m_%d)_mattermost_production.dump"
```

## 以前の問題点

pg\_dump だけしかとっていなかったので、
リストアすると
GitLab での SSO (Single Sign On) の連携が壊れてしまいました。

## とりあえず復旧

`sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql gitlabhq_production`
で gitlab 側のデータベースにつないで、
`\x` で表示形式を変えた後、
`select * from oauth_applications;` で `uid` と `secret` を確認しておきます。

`/var/opt/gitlab/mattermost/config.json` の `"GitLabSettings": {` の下にある
`"Secret":` と `"Id":` に `secret` と `uid` を設定し直すと復旧できました。
(`sudo gitlab-ctl restart` で再起動が必要だったかもしれません。)

## バックアップの修正

Omnibus GitLab 自体のバックアップ方法を見直すと `/etc/gitlab` を `-C / etc/gitlab` でバックアップする方法があったので、
それを真似て `-C / var/opt/gitlab/mattermost` で `config.json` を含む設定全体をバックアップするようにしました。

後でみつけた
[gitlab-mattermost-backup](https://github.com/gitlab-tools/gitlab-mattermost-backup)
でも `/var/opt/gitlab/mattermost` と `mattermost_production` をバックアップしているので、
これで良さそうです。
(gitlab-mattermost-backup 自体は s3 へのバックアップ専用のようなので、使えませんでした。)

ついでにバックアップの方式を SQL でとる方式から `-Fc` をつけてアーカイブ形式に変更しました。

## まとめ

[Ansible Playbook for gitlab omnibus, gitlab-ci, and dokku](https://github.com/znz/ansible-playbook-gitlab-dokku)
で使っている box のバージョンを上げるために `vagrant destroy` して `vagrant up` してリストアしたところ、
バックアップが不完全だったことが発覚しました。

ちゃんとバックアップ方法が書かれている GitLab 本体はいいとしても、
Omnibus パッケージで一緒に入るのにバックアップ方法がはっきりしない Mattermost 側は
自分でバックアップ方法を考える必要があるので、
リストアまで含めて確認して運用する必要があると思いました。
