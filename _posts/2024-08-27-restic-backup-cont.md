---
layout: post
title: "resticバックアップの設定を調整した"
date: 2024-08-27 19:00 +0900
comments: true
category: blog
tags: linux restic
---
[前回の記事]({% post_url 2024-08-08-restic-backup %})では exclude 指定が途中までだったので、
その見直しなどをしてバックアップを続けているので、その差分などのメモです。

<!--more-->

## 確認バージョン

- rclone v1.67.0
- restic 0.17.0

## 前提条件

- バックアップ用の `backup-operator` というユーザーを既に作成済みです。
- [InfiniCLOUD](https://infini-cloud.net/ja/index.html) で「外部アプリ接続」を許可して WebDAV の接続情報を取得済みで、
  バックアップ容量を確認しやすくしたり、不要になったときに削除しやすくしたりするために、データセット名 `/files/restic/ホスト名` でデータセットを作成しています。
  (この記事を参考にして登録するなら紹介コード `FRBVA` を使うと 5GB 貰えるそうです)

## systemd unit の変更

unit はこのように変更しました。

```
[Unit]
Description=Restic Backup

[Service]
Type=oneshot
User=backup-operator
Group=backup-operator
AmbientCapabilities=CAP_DAC_READ_SEARCH
Environment=RESTIC_PASSWORD_FILE=/home/backup-operator/.config/rclone/InfiniCLOUD.restic.password RESTIC_REPOSITORY=rclone:InfiniCLOUD-restic:
ExecStart=/usr/local/bin/restic unlock
ExecStart=/usr/local/bin/restic backup --exclude-caches --one-file-system --tag scheduled,boot /boot
ExecStart=/usr/local/bin/restic backup --exclude-caches --one-file-system --exclude-file=/home/backup-operator/.config/rclone/restic.excludes.txt --tag scheduled,root /
ExecStart=/usr/local/bin/restic check --with-cache --read-data-subset=5G
ExecStart=/usr/local/bin/restic forget --prune --keep-hourly 24 --keep-daily 30 --keep-monthly 6 --keep-weekly 4 --keep-yearly 3
Nice=5
IOSchedulingClass=best-effort
IOSchedulingPriority=5
```

変更点としては、以下のような感じです。

- mount したときの latest は boot よりも root になっていてほしいので、順番を入れ替えた。
- `--tag` に `boot` と `root` のパーティション名も足した。
- `--exclude-file` で除外設定ファイルを指定した。

## 除外設定ファイル

`/home/backup-operator/.config/rclone/restic.excludes.txt` には以下の内容を設定しました。
サーバーによっては存在しないファイルもありますが、複数サーバーで共通にしています。

```
/aquota.group
/aquota.user
/dev/**
/lost+found/**
/swapfile
/tmp/**
/var/lib/docker/**
/var/tmp/**
```

それぞれ以下のような理由で設定しています。

- ユーザーごとの使用量をチェックしやすくするために入れている quota のファイルを無視
- `/dev/` は `--one-file-system` で除外されるはずですが、 `/run` などとの動作の比較のため明示的に除外
- `/lost+found/` はバックアップしても問題はないのですが、不要なことが多いので除外
- `/swapfile` はスワップパーティションではなくスワップファイルで設定しているサーバーがあったため、無駄にバックアップ容量を使ってしまうので除外
- `/tmp` や `/var/tmp` は不要なファイルのみ存在するべきなので除外
- `/var/lib/docker` は docker の中は別の方法でバックアップすべきなので除外

`/var/cache` も除外しても良いのですが、まだ除外せずに様子をみています。

## restic mount

マウントするディレクトリを用意してマウントします。
`restic mount` は `Ctrl-c` で止めるまで他の操作ができなくなるので、別端末で中身を確認します。

```
% sudo -u backup-operator mkdir /tmp/restic
% restic.sh mount /tmp/restic
```

`fusermount: exec: "fusermount": executable file not found in $PATH`
で `mount` に失敗するときは `fuse` パッケージを入れる必要がありました。

別端末で `ls` や別シェルを開いて確認します。

```
% sudo -u backup-operator ls -al /tmp/restic/snapshots/latest/
% sudo -u backup-operator /bin/bash
```

`systemd-run --pipe` 経由だと `Ctrl-c` でちゃんと止まらなかったので、
`sudo -u backup-operator fusermount -u /tmp/restic`
で止めました。

最初は気付かずに二度目以降のマウントがうまくいかないと勘違いして、
`sudo RESTIC_PASSWORD_FILE=/home/backup-operator/.config/rclone/InfiniCLOUD.restic.password RESTIC_REPOSITORY=rclone:InfiniCLOUD-restic: XDG_CONFIG_HOME=/home/backup-operator/.config restic mount /tmp/restic`
のように root 権限でマウントし直してしまっていましたが、
ちゃんと止まっていなかっただけでした。

## macOS のバックアップ

macOS は以下のような設定をして `while sleep 3600; do date; ~/.config/rclone/restic-backup.sh; date; done` を開きっぱなしの端末の1タブで回しています。
出かけるときなどには簡単に止められるように自動実行にはしていません。

`Library` の中身がバックアップできていないので、そちらは今のところ Time Machine バックアップ任せになっています。

除外にはバックアップファイルの他に、容量の大きいファイルやディスクイメージファイルを指定していて、
こちらも今後さらに検討が必要そうです。

```
% cat ~/.config/rclone/restic-backup.sh
#!/bin/bash

# usage:
#  ~/.config/rclone/restic-backup.sh
#  env tag=manual ~/.config/rclone/restic-backup.sh

#if [[ -n $(pgrep 'restic' | grep 'restic backup') ]]; then
if [ -n "$(pgrep 'restic')" ]; then
  echo 'restic is already running...' 1>&2
  exit 0
fi

set -ux
: "${tag=scheduled}"
~/.config/rclone/restic.sh unlock
~/.config/rclone/restic.sh backup --exclude-caches --one-file-system --skip-if-unchanged --tag "${tag},Movies" "$HOME/Movies"
~/.config/rclone/restic.sh backup --exclude-caches --one-file-system --skip-if-unchanged --tag "${tag},Downloads" "$HOME/Downloads"
~/.config/rclone/restic.sh backup --exclude-caches --one-file-system --exclude-file="$HOME/.config/rclone/restic.excludes.txt" --tag "${tag},home" "$HOME"
~/.config/rclone/restic.sh check --with-cache --read-data-subset=5G
~/.config/rclone/restic.sh forget --prune --keep-hourly 24 --keep-daily 30 --keep-monthly 6 --keep-weekly 4 --keep-yearly 3
% cat ~/.config/rclone/restic.excludes.txt
# macOS
/Users/*/.Trash
/Users/*/Library/**

# [...]
node_modules
*~
*.o
*.lo
*.pyc

# .gnupg
.#*

# lima,colima
cidata.iso
basedisk
diffdisk

# misc
/Users/*/.dropbox/**
/Users/*/.npm/**
/Users/*/.ollama/models/**
/Users/*/.rustup/**

# my temp data
/Users/*/.anyenv/**
/Users/*/s/github.com/ruby/ruby/build/**
*.sparsebundle
*.qcow2
diff.img

# 別途バックアップ
/Users/*/Downloads/**
/Users/*/Movies/**

# 別途バックアップ予定
# Library の中で個別にバックアップ可能なもの
```

## 最後に

`restic` でのバックアップの現状の差分をまとめてみました。

とりあえず継続的にバックアップが取れているので、
VPS の OS のバージョンアップなどの大きな変更もやりやすくなったので、
古いままになっているのを更新していきたいと思っています。
