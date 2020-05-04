---
layout: post
title: "wireguard-dkmsのモジュールをreloadするシェルスクリプを作った"
date: 2020-05-02 23:00 +0900
comments: true
category: blog
tags: wireguard debian linux
---
[Debian勉強会でのwireguardの発表]({% post_url 2020-04-18-debianjp-wireguard-jitsi %})で
wireguard-dkms のモジュールのリロードを手動で実行している話をしましたが、
ちゃんとシェルスクリプトにまとめ直しました。

<!--more-->

## 動作確認環境

- Debian 9 (stretch)
- Debian 10 (buster)
- Debian testing (bullseye)
- Raspbian 10 (buster)
- Ubuntu 18.04 LTS (bionic)
- Ubuntu 20.04 LTS (focal)

## 概要

wireguard のカーネルモジュールが Linux 5.6 から Linux 本体に同梱されることになって、
wireguard-dkms の postinst での自動再読み込みがなくなり、
`/run/reboot-required*` による再起動要求に変わりました。

次のシェルスクリプトでは、なくなる前の再読み込み処理を実行して、
`/run/reboot-required.pkgs` が `wireguard-dkms` だけだったら、
再起動要求を削除する、ということをしています。

## スクリプト本体

以下の内容のファイルを `/usr/local/bin/wg-reload.sh` としておいて実行属性をつけました。

<https://salsa.debian.org/debian/wireguard-linux-compat/-/commit/af9f90b13118cd259227773c2a81ccfa25cf3e5d>
を元にしているので、ライセンスはスクリプト全体としても GPLv2 として扱ってください。

```bash
#!/bin/bash
# LICENSE: GPLv2
set -euo pipefail
echo "Loaded version: $(cat /sys/module/wireguard/version)"
echo "Installed version: $(modinfo -F version wireguard)"
if [[ $(cat /sys/module/wireguard/version) != $(modinfo -F version wireguard) ]]; then
    if [ -d /run/systemd/system ]; then
        systemctl daemon-reload || true
        units="$(systemctl list-units --state=active --plain --no-legend 'wg-quick@*.service' | awk '{print $1}')"
        if [ -n "$units" ]; then
            echo "Stopping currently active wg-quick@ unit instances..." >&2
            systemctl stop $units || true
        fi
    fi
    if [ -n "$(wg show interfaces)" ]; then
        echo "Warning: Wireguard interfaces currently configured, not reloading module" >&2
    else
        echo "Reloading wireguard module..." >&2
        if ! rmmod wireguard ; then
            echo "Warning: failed to unload wireguard module" >&2
        else
            modprobe wireguard
        fi
    fi
    if [ -d /run/systemd/system ]; then
        if [ -n "$units" ]; then
            echo "Starting previously active wg-quick@ unit instances..." >&2
            systemctl start $units || true
        fi
    fi
fi
if [[ -f /run/reboot-required.pkgs ]]; then
    if [[ wireguard-dkms = $(</run/reboot-required.pkgs) ]]; then
        rm -f /run/reboot-required*
    fi
fi
```

## 感想

手動で現在のバージョンチェックをして、リロードして更新されているのを確認して、
再起動要求が `wireguard-dkms` だけなら削除、としていたのが、1コマンドだけでできるようになって楽になりました。

手動で実行していたリロード対象は `wg0` 固定だったのですが、
ちゃんと postinst にあったように `wg-quick@.service` 全てを対象にできるようになったのもよかったです。
