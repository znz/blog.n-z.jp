---
layout: post
title: "restic+rcloneでInfiniCLOUDにバックアップするようにした"
date: 2024-08-08 19:00 +0900
comments: true
category: blog
tags: linux restic
---
<!--more-->

## 確認バージョン

- Ubuntu 20.04.6 LTS
- rclone v1.67.0
- restic 0.17.0

## 前提条件

- バックアップ用の `backup-operator` というユーザーを既に作成済みです。
- [InfiniCLOUD](https://infini-cloud.net/ja/index.html) で「外部アプリ接続」を許可して WebDAV の接続情報を取得済みで、
  バックアップ容量を確認しやすくしたり、不要になったときに削除しやすくしたりするために、データセット名 `/files/restic/ホスト名` でデータセットを作成しています。
  (この記事を参考にして登録するなら紹介コード `FRBVA` を使うと 5GB 貰えるそうです)

## インストール

apt や snap でインストールできるバージョンは古いので、最新版をダウンロードしてインストールしました。

rclone は <https://rclone.org/downloads/> から「Intel/AMD - 64 Bit」の .deb をダウンロードしてインストールしました。

```console
% wget -N https://downloads.rclone.org/v1.67.0/rclone-v1.67.0-linux-amd64.deb
% sudo dpkg -i rclone-v1.67.0-linux-amd64.deb
```

`restic` は [Official Binaries](https://restic.readthedocs.io/en/stable/020_installation.html#official-binaries) にリンクがある
GitHub Releases からダウンロードしてインストールしました。

```console
% wget -N https://github.com/restic/restic/releases/download/v0.17.0/restic_0.17.0_linux_amd64.bz2
% bunzip2 restic_0.17.0_linux_amd64.bz2
% sudo install restic_0.17.0_linux_amd64 /usr/local/bin/restic
```

[Full backup without root](https://restic.readthedocs.io/en/latest/080_examples.html#full-backup-without-root)
に書いてあるようにバックアップを実行するユーザーにだけ実行できるようにして、
`setcap` するという方法もあるのですが、
今回は
[`systemd.exec` の `AmbientCapabilities=`](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#AmbientCapabilities=)
を使いました。

`setcap` を使うなら以下のような感じになります。
`setcap` の方が `rclone` には権限が渡らなくて安全だと思うのですが、
今回は利便性をとりました。

```console
% sudo install -o root -g $GID -m 750 restic_0.17.0_linux_amd64 /usr/local/bin/restic
% sudo setcap cap_dac_read_search=+ep /usr/local/bin/restic
```

## 補完

`restic generate` で補完設定や man page などを生成できるので、
bash と zsh の補完設定だけ生成しました。

```console
% sudo restic generate --bash-completion /etc/bash_completion.d/restic --zsh-completion /usr/local/share/zsh/site-functions/_restic
writing bash completion file to /etc/bash_completion.d/restic
writing zsh completion file to /usr/local/share/zsh/site-functions/_restic
```

## rclone の設定

`rclone config` で以下のような感じで設定しました。

- `n) New remote`
- `name> InfiniCLOUD-restic`
- `Storage> webdav`
- `url>` データセットの WebDAV 接続 URL
- `vendor> other`
- `user>` ユーザーID
- `y) Yes type in my own password` でアプリパスワード
- `bearer_token>` は空のまま

今回は他の環境で作成した設定を流用するために `touch` でファイル作成して直接編集しました。

```console
% sudo -u backup-operator rclone config touch
% sudoedit /home/backup-operator/.config/rclone/rclone.conf
```

動作確認します。
エラーが出なければ URL は認証情報は大丈夫そうです。

```console
% sudo -u backup-operator rclone lsjson InfiniCLOUD-restic:
[
]
```

(ここで <https://rclone.org/webdav/> を参考にして
`vendor = owncloud` などを試してみても
`mtime` は保存されなかったので、
InfiniCLOUD は `X-OC-Mtime` には対応していないようですが、
`restic` で保存してくれるので問題なさそうです。)

## restic の設定

`restic` の自動化に必要なので、
パスワードジェネレーターで生成したパスワードをファイルに保存しておきます。
将来は [systemd-creds](https://wiki.archlinux.jp/index.php/Systemd-creds) 管理にしたいですが、
現状は普通のファイルに保存しています。

```console
% sudo touch /home/backup-operator/.config/rclone/InfiniCLOUD.restic.password
% sudo chmod 400 /home/backup-operator/.config/rclone/InfiniCLOUD.restic.password
% sudo chown backup-operator: /home/backup-operator/.config/rclone/InfiniCLOUD.restic.password
% sudo tee /home/backup-operator/.config/rclone/InfiniCLOUD.restic.password
```

## restic init

数秒の待ちの後、初期化が完了します。

```console
% sudo -u backup-operator RESTIC_PASSWORD_FILE=/home/backup-operator/.config/rclone/InfiniCLOUD.restic.password RESTIC_REPOSITORY=rclone:InfiniCLOUD-restic: restic init
created restic repository 994a5f36a5 at rclone:InfiniCLOUD-restic:

Please note that knowledge of your password is required to access
the repository. Losing your password means that your data is
irrecoverably lost.
```

## ラッパースクリプトの用意

`systemd` の `service` と同じ権限での動作確認や各種サブコマンドの実行のため、
`systemd-run` を経由して実行するラッパースクリプトを用意しておきます。

実行結果を直接見えるようにするのに `--scope` だと
`Unknown assignment: AmbientCapabilities=CAP_DAC_READ_SEARCH`
になってうまくいかなかったので、
`--pipe` を使っています。

```console
% vi restic.sh
% sudo install restic.sh /usr/local/bin/
%  rm restic.sh
% cat /usr/local/bin/restic.sh
#!/bin/sh
exec sudo systemd-run --pipe -p AmbientCapabilities=CAP_DAC_READ_SEARCH --uid=backup-operator --gid=backup-operator -E RESTIC_PASSWORD_FILE=/home/backup-operator/.config/rclone/InfiniCLOUD.restic.password -E RESTIC_REPOSITORY=rclone:InfiniCLOUD-restic: restic "$@"
```

ファイルが少ない `/etc` を使って動作確認しました。
ファイルが読み込めないというエラーが出ていないので、
`AmbientCapabilities=CAP_DAC_READ_SEARCH`
で大丈夫だと確認できました。

```console
% restic.sh backup -n --exclude-caches --one-file-system /etc
Running as unit: run-u177.service
repository 994a5f36 opened (version 2, compression level auto)
created new cache in /home/backup-operator/.cache/restic
no parent snapshot found, will read all files
[0:00]          0 index files loaded

Files:        3509 new,     0 changed,     0 unmodified
Dirs:          686 new,     0 changed,     0 unmodified
Would add to the repository: 15.144 MiB (10.576 MiB stored)

processed 3509 files, 13.836 MiB in 0:00
```

## systemd の unit ファイル作成

- `User=`, `Group=`, `AmbientCapabilities=` は今までの説明の通り、一般ユーザー権限でフルバックアップするための設定です。
- `Environment=` の設定は `restic` のドキュメントを参考にしてください。
- `ExecStart=` のコマンドは [Restic - ArchWiki](https://wiki.archlinux.jp/index.php/Restic) のバックアップスクリプトを参考にしました。
- [`forget` の引数](https://restic.readthedocs.io/en/latest/060_forget.html) は後日調整したいです。
- `--exclude-file` は外してしまいましたが、後日調整したいです。
- `--exclude-caches` は [CACHEDIR.TAG](https://bford.info/cachedir/) をみてくれるようになるオプションです。
- `--one-file-system` は `rsync` の同名のオプションと同じで `/proc` などを無視するためにつけています。
- `Nice=` は `nice` コマンドを経由したときのデフォルトが 10 なので、その中間の 5 にしました。
- `IOSchedulingPriority=` は `IOSchedulingClass=best-effort` でのデフォルトが 4 のようなので、それより優先度を 1 だけ低くして 5 にしました。 (<https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#IOSchedulingPriority=>)
- timer はシステム起動から 15 分間待って、後は90分から150分間隔で実行するようにしました。(<https://speakerdeck.com/moriwaka/systemd-intro?slide=87>)

```console
% sudo EDITOR=vi systemctl edit --force --full restic-backup.service
% sudo EDITOR=vi systemctl edit --force --full restic-backup.timer
% systemctl cat restic-backup.service
# /etc/systemd/system/restic-backup.service
[Unit]
Description=Restic Backup

[Service]
Type=oneshot
User=backup-operator
Group=backup-operator
AmbientCapabilities=CAP_DAC_READ_SEARCH
Environment=RESTIC_PASSWORD_FILE=/home/backup-operator/.config/rclone/InfiniCLOUD.restic.password RESTIC_REPOSITORY=rclone:InfiniCLOUD-restic:
ExecStart=/usr/local/bin/restic unlock
ExecStart=/usr/local/bin/restic backup --exclude-caches --one-file-system --tag scheduled /
ExecStart=/usr/local/bin/restic backup --exclude-caches --one-file-system --tag scheduled /boot
ExecStart=/usr/local/bin/restic check --with-cache --read-data-subset=5G
ExecStart=/usr/local/bin/restic forget --prune --keep-hourly 24 --keep-daily 30 --keep-monthly 6 --keep-weekly 4 --keep-yearly 3
Nice=5
IOSchedulingClass=best-effort
IOSchedulingPriority=5
% systemctl cat restic-backup.timer
# /etc/systemd/system/restic-backup.timer
[Unit]
Description=Restic Backup

[Timer]
OnBootSec=15min
OnUnitActiveSec=90min
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
% sudo systemctl enable --now restic-backup.timer
Created symlink /etc/systemd/system/timers.target.wants/restic-backup.timer → /etc/systemd/system/restic-backup.timer.
% systemctl list-timers
```

## 全体的な感想や今後の予定など

以前に試したときは [rclone の crypt](https://rclone.org/crypt/) を重ねていましたが、
`restic` 自体が (今回の設定例では `RESTIC_PASSWORD_FILE` で指定している) パスワードで暗号化しているので、
不要そうでした。

`restic` は [Deduplication に対応](https://restic.readthedocs.io/en/latest/100_references.html#backups-and-deduplication)していて、
[Preparing a new repository](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#preparing-a-new-repository)
の表にあるように `restic` 0.14.0 以上で対応している Repository version 2 では、圧縮も対応していて、
実際のバックアップは元のディスクより小さくなっていて良い感じでした。

リストアも
[第766回 高度なことが簡単にできる多機能バックアップツール、Restic［後編］](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0766)
で紹介されている `restic mount` で、
普通のファイル操作を使えて楽そうでした。

`--exclude-file` は `restic.sh snapshots --no-lock` と `restic.sh diff --no-lock ID1 ID2` などで変化しているファイルをみて、
データベースのバイナリは除外して `ExecStartPre=` でダンプをした方が良さそう、とか調整したいと思っています。

timer での実行間隔や `restic forget` の保存期間の指定も検討が必要だと思っています。

3-2-1 バックアップルールのため、
`restic copy` を使うか、
`restic backup` を直接別の repository にも実行するか、
なども検討していきたいです。
