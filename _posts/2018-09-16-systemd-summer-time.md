---
layout: post
title: "systemd の timer のサマータイム時の動き"
date: 2018-09-16 13:33 +0900
comments: true
category: blog
tags: linux ubuntu systemd
---
systemd の timer がサマータイムで時間が戻った時や飛んだ時にどういう動きになるのか確認してみました。

<!--more-->

## 確認環境

- Ubuntu 18.04 LTS

具体的には VirtualBox + vagrant で
box は bento/ubuntu-18.04 を使いました。

## 時間変更方法

`systemd-timesyncd` を止めないと `timedatectl set-time` が使えず、
さらに時刻の同期を止めるために `vboxadd-service` を停止する必要がありました。

サマータイムがあるタイムゾーンにするために `America/New_York` に設定しました。
(CloudAtCost ではこのタイムゾーンがデフォルトだったので)

```
sudo timedatectl set-timezone America/New_York
sudo systemctl disable --now systemd-timesyncd.service
zdump -v America/New_York | grep 2018
sudo systemctl disable --now vboxadd-service
sudo reboot
sudo timedatectl set-time "2018-11-04 01:59"
```

"2018-11-04 01:59 EDT" から1分待つと
"2018-11-04 01:00 EST" になっていました。

## ログ確認

`/var/log/auth.log` などの rsyslog で記録されるログは rsyslog のタイムゾーンで記録されているらしく、
reboot などで反映していないと UTC のままでした。

`journalctl --since="2018-11-04 01:00"` は EDT (戻る前の夏時間の方) と同じでした。

```
tail /var/log/auth.log
journalctl --since="2018-11-04 01:00"
journalctl --since="2018-11-04 01:00 EST"
journalctl --since="2018-11-04 01:00 EDT"
```

## 定期実行の timer の挙動

1 分間隔のタイマー設定をしました。

```console
$ sudoedit /etc/systemd/system/hello.service
$ cat /etc/systemd/system/hello.service
[Service]
Type=oneshot
ExecStart=/bin/echo hello
$ sudoedit /etc/systemd/system/hello.timer
$ cat /etc/systemd/system/hello.timer
[Timer]
OnBootSec=1min
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target
$ sudo systemctl enable hello.timer
Created symlink /etc/systemd/system/timers.target.wants/hello.timer → /etc/systemd/system/hello.timer.
$ sudo systemctl start hello.timer
$ systemctl list-timers
NEXT                         LEFT           LAST                         PASSED             UNIT
Sat 2018-09-15 04:24:28 EDT  59s left       Sat 2018-09-15 04:23:28 EDT  14ms ago           hello.timer
Sat 2018-09-15 04:33:08 EDT  9min left      n/a                          n/a                systemd-tmpfiles-clean.timer
Mon 2018-09-17 00:00:00 EDT  1 day 19h left n/a                          n/a                fstrim.timer
n/a                          n/a            Fri 2018-08-24 05:04:47 EDT  3 weeks 0 days ago motd-news.timer

4 timers listed.
Pass --all to see loaded but inactive timers, too.
```

なぜか 2 分間隔で動いていますが、
タイムゾーンの切り替えで戻った時も問題なく同じ間隔で動いていました。

```console
$ journalctl -u hello.timer
-- Logs begin at Fri 2018-09-14 04:49:19 EDT, end at Sun 2018-11-04 01:03:00 EST. --
Sep 15 04:21:58 vagrant systemd[1]: Started hello.timer.
$ journalctl -u hello
-- Logs begin at Fri 2018-09-14 04:49:19 EDT, end at Sun 2018-11-04 01:03:00 EST. --
Sep 15 04:21:58 vagrant systemd[1]: Starting hello.service...
Sep 15 04:21:58 vagrant echo[12623]: hello
Sep 15 04:21:58 vagrant systemd[1]: Started hello.service.
Sep 15 04:23:28 vagrant systemd[1]: Starting hello.service...
Sep 15 04:23:28 vagrant echo[12650]: hello
Sep 15 04:23:28 vagrant systemd[1]: Started hello.service.
$ sudo timedatectl set-time "2018-11-04 01:50"
$ systemctl list-timers
NEXT                         LEFT      LAST                         PASSED               UNIT                         AC
Sun 2018-11-04 01:51:13 EDT  59s left  Sun 2018-11-04 01:50:13 EDT  14ms ago             hello.timer                  he
Sun 2018-11-04 01:58:48 EDT  8min left n/a                          n/a                  systemd-tmpfiles-clean.timer sy
Mon 2018-11-05 00:00:00 EST  23h left  n/a                          n/a                  fstrim.timer                 fs
n/a                          n/a       Fri 2018-08-24 05:04:47 EDT  2 months 10 days ago motd-news.timer              mo

4 timers listed.
Pass --all to see loaded but inactive timers, too.
$ journalctl -u hello
-- Logs begin at Fri 2018-09-14 04:49:19 EDT, end at Sun 2018-11-04 01:07:36 EST. --
Sep 15 04:21:58 vagrant systemd[1]: Starting hello.service...
Sep 15 04:21:58 vagrant echo[12623]: hello
Sep 15 04:21:58 vagrant systemd[1]: Started hello.service.
Sep 15 04:23:28 vagrant systemd[1]: Starting hello.service...
Sep 15 04:23:28 vagrant echo[12650]: hello
Sep 15 04:23:28 vagrant systemd[1]: Started hello.service.
Nov 04 01:50:13 vagrant systemd[1]: Starting hello.service...
Nov 04 01:50:13 vagrant systemd[1]: Started hello.service.
Nov 04 01:50:13 vagrant echo[12682]: hello
Nov 04 01:51:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:51:36 vagrant echo[12706]: hello
Nov 04 01:51:36 vagrant systemd[1]: Started hello.service.
Nov 04 01:53:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:53:36 vagrant echo[12717]: hello
Nov 04 01:53:36 vagrant systemd[1]: Started hello.service.
Nov 04 01:55:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:55:36 vagrant echo[12744]: hello
Nov 04 01:55:36 vagrant systemd[1]: Started hello.service.
Nov 04 01:57:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:57:36 vagrant echo[12755]: hello
Nov 04 01:57:36 vagrant systemd[1]: Started hello.service.
Nov 04 01:59:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:59:36 vagrant echo[12778]: hello
Nov 04 01:59:36 vagrant systemd[1]: Started hello.service.
Nov 04 01:01:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:01:36 vagrant echo[12800]: hello
Nov 04 01:01:36 vagrant systemd[1]: Started hello.service.
Nov 04 01:03:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:03:36 vagrant echo[12821]: hello
Nov 04 01:03:36 vagrant systemd[1]: Started hello.service.
Nov 04 01:05:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:05:36 vagrant echo[12843]: hello
Nov 04 01:05:36 vagrant systemd[1]: Started hello.service.
Nov 04 01:07:36 vagrant systemd[1]: Starting hello.service...
Nov 04 01:07:36 vagrant echo[12865]: hello
Nov 04 01:07:36 vagrant systemd[1]: Started hello.service.
```

## OnCalendar で時間が戻る時

同じ表記の時刻が 2 度出てくる場合として 1:30 を試してみました。

"Sun 2018-11-04 01:30:00 EDT" の次が
"Mon 2018-11-05 01:30:00 EST" になっていました。
この場合は 25 時間後になってしまうようです。

```console
$ cat /etc/systemd/system/hello.timer
[Timer]
OnCalendar=*-*-* 01:30:00

[Install]
WantedBy=timers.target
$ sudo systemctl daemon-reload
$ sudo timedatectl set-time "2018-11-04 01:20"
$ systemctl list-timers
NEXT                         LEFT       LAST                         PASSED               UNIT                         A
Sun 2018-11-04 01:30:00 EDT  9min left  Sun 2018-11-04 01:20:00 EDT  2s ago               hello.timer                  h
Sun 2018-11-04 01:31:55 EDT  11min left n/a                          n/a                  systemd-tmpfiles-clean.timer s
Mon 2018-11-05 00:00:00 EST  23h left   n/a                          n/a                  fstrim.timer                 f
n/a                          n/a        Fri 2018-08-24 05:04:47 EDT  2 months 10 days ago motd-news.timer              m

4 timers listed.
Pass --all to see loaded but inactive timers, too.
$ systemctl list-timers
NEXT                         LEFT     LAST                         PASSED               UNIT                         ACT
Mon 2018-11-05 00:00:00 EST  23h left n/a                          n/a                  fstrim.timer                 fst
Mon 2018-11-05 00:32:21 EST  23h left Sun 2018-11-04 01:32:21 EDT  4min 18s ago         systemd-tmpfiles-clean.timer sys
Mon 2018-11-05 01:30:00 EST  24h left Sun 2018-11-04 01:30:21 EDT  6min ago             hello.timer                  hel
n/a                          n/a      Fri 2018-08-24 05:04:47 EDT  2 months 10 days ago motd-news.timer              mot

4 timers listed.
Pass --all to see loaded but inactive timers, too.
```

## OnCalendar で時間が飛ぶ時

時刻が飛んでしまう例として 2:20 を試してみました。

時計を戻してしまったので、
LAST が未来になって timer が変になったので、
[systemctl list-timers の LAST が未来になっていてタイマーが実行されなかった]({% post_url 2018-05-14-systemd-timer %})
のように stamp ファイルを消す必要があるようだったので、
一度止めて再スタートすることで代用しました。

結果としては 1 日飛ばされてしまって、
1 日と 23 時間後になってしまうようです。

```console
$ cat /etc/systemd/system/hello.timer
[Timer]
OnCalendar=*-*-* 02:30:00

[Install]
WantedBy=timers.target
$ sudoedit /etc/systemd/system/hello.timer
$ sudo systemctl daemon-reload
$ sudo timedatectl set-time "2018-03-10 02:20"
$ sudo systemctl disable --now hello.timer
Removed /etc/systemd/system/timers.target.wants/hello.timer.
$ sudo systemctl enable --now hello.timer
Created symlink /etc/systemd/system/timers.target.wants/hello.timer → /etc/systemd/system/hello.timer.
$ systemctl list-timers
NEXT                         LEFT           LAST                         PASSED                UNIT
Sat 2018-03-10 02:30:00 EST  9min left      n/a                          n/a                   hello.timer
Sun 2018-03-11 03:01:53 EDT  23h left       Sun 2018-11-04 01:32:21 EDT  7 months 25 days left systemd-tmpfiles-clean.ti
Mon 2018-03-12 00:00:00 EDT  1 day 20h left n/a                          n/a                   fstrim.timer
n/a                          n/a            Fri 2018-08-24 05:04:47 EDT  5 months 14 days left motd-news.timer

4 timers listed.
Pass --all to see loaded but inactive timers, too.
$ systemctl list-timers
NEXT                         LEFT           LAST                         PASSED                UNIT
Sun 2018-03-11 03:01:53 EDT  23h left       Sun 2018-11-04 01:32:21 EDT  7 months 25 days left systemd-tmpfiles-clean.ti
Mon 2018-03-12 00:00:00 EDT  1 day 20h left n/a                          n/a                   fstrim.timer
n/a                          n/a            Sat 2018-03-10 02:30:19 EST  15ms ago              hello.timer
n/a                          n/a            Fri 2018-08-24 05:04:47 EDT  5 months 14 days left motd-news.timer

4 timers listed.
Pass --all to see loaded but inactive timers, too.
$ systemctl list-timers
NEXT                         LEFT           LAST                         PASSED                UNIT
Sun 2018-03-11 03:01:53 EDT  23h left       Sun 2018-11-04 01:32:21 EDT  7 months 25 days left systemd-tmpfiles-clean.ti
Mon 2018-03-12 00:00:00 EDT  1 day 20h left n/a                          n/a                   fstrim.timer
Mon 2018-03-12 02:30:00 EDT  1 day 22h left Sat 2018-03-10 02:30:19 EST  18s ago               hello.timer
n/a                          n/a            Fri 2018-08-24 05:04:47 EDT  5 months 14 days left motd-news.timer

4 timers listed.
Pass --all to see loaded but inactive timers, too.
```

## まとめ

時間が戻る時に 1 時間後に実行されないというところでサマータイムをちゃんと考慮していると感じました。

存在しない可能性のある時刻だと実行されない日が出てくるという点でバッチ処理の時刻を適当な夜中の時間に設定していると問題が起きる可能性がありそうだと感じました。

適当な夜中の時間からバッチ処理を開始するようにしている場合、ローカルタイムで指定していると 24 時間間隔にならないことがあって、
気にせずずれても良いと判断するにしても、時刻をずらして切り替えの時だけ 23 時間や 25 時間で許容するにしても、
UTC で指定するようにして 24 時間間隔を維持するにしても、
何らかの判断が必要でサマータイム対応は大変そうだと感じました。
