---
layout: post
title: "Dokkuを動かしているUbuntuを20.04から22.04に更新した"
date: 2025-12-27 14:36 +0900
comments: true
category: blog
tags: ubuntu linux docker dokku
---
年末で時間がとれるようになったので、
Dokku を動かしている VPS のサーバーを Ubuntu 20.04 (focal) から Ubuntu 22.04 (jammy) に更新しました。

<!--more-->

## データベースなどのバックアップ

まず、いつもの `dokku postgres:export` でデータベースのバックアップをとったり、その他のバックアップをとりました。

## do-release-upgrade

<https://wiki.ubuntu.com/JammyJellyfish/ReleaseNotes/Ja>
を参照して大きな影響がなさそうなのを確認した後、
`sudo do-release-upgrade` で更新しました。

## etc のファイル確認

前回の do-release-upgrade のときから残っているファイルが混ざっているかもしれませんが、
`/etc` で `git clean -ndx` を実行して、
`etckeeper` で無視されている `*.dpkg-*` や `*.ucf-*` などを確認しました。

## `sshd_config`

追加変更していた設定は `/etc/ssh/sshd_config.d` に分割しまし。

## 50unattended-upgrades

3項目だけ変更して `50unattended-upgrades.ucf-dist` をマージしました。

```text
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
```

## zabbix-agent2

<https://www.zabbix.com/download?zabbix=7.4&os_distribution=ubuntu&os_version=22.04&components=agent_2&db=&ws=>
から `zabbix-release_latest_7.4+ubuntu22.04_all.deb` を入れて、
`zabbix-agent2` を更新しました。

`sudo apt update` で

```text
N: Skipping acquire of configured file 'main/binary-i386/Packages' as repository 'https://repo.zabbix.com/zabbix/7.4/stable/ubuntu jammy InRelease' doesn't support architecture 'i386'
```

というメッセージが出るので、
`/etc/apt/sources.list.d/zabbix.list` の `deb` の行に `[arch=amd64]` を追加しました。

## dokku と docker

Dokku は
<https://dokku.com/docs/getting-started/installation/>
から `bootstrap.sh` をダウンロードして参照して apt の設定を更新しました。

```bash
wget -qO- https://packagecloud.io/dokku/dokku/gpgkey | sudo tee /etc/apt/trusted.gpg.d/dokku.asc
```

で gpg 鍵を更新して `/etc/apt/sources.list.d/dokku.list は

```text
deb https://packagecloud.io/dokku/dokku/ubuntu jammy main
```

にしました。

`/etc/apt/sources.list.d/dokku.list.*` や `/etc/apt/sources.list.d/download_docker_com_linux_ubuntu.list*` は削除しました。



<https://get.docker.com/> をダウンロードして参照して apt の設定を更新しました。


```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list
```

`sudo apt full-upgrade -V` で更新対象を事前確認しました。

```text
The following packages will be upgraded:
   containerd.io (1.7.27-1 => 2.2.1-1~ubuntu.22.04~jammy)
   docker-buildx-plugin (0.23.0-1~ubuntu.20.04~focal => 0.30.1-1~ubuntu.22.04~jammy)
   docker-ce (5:28.1.1-1~ubuntu.20.04~focal => 5:29.1.3-1~ubuntu.22.04~jammy)
   docker-ce-cli (5:28.1.1-1~ubuntu.20.04~focal => 5:29.1.3-1~ubuntu.22.04~jammy)
   docker-ce-rootless-extras (5:28.1.1-1~ubuntu.20.04~focal => 5:29.1.3-1~ubuntu.22.04~jammy)
   docker-compose-plugin (2.35.1-1~ubuntu.20.04~focal => 5.0.0-1~ubuntu.22.04~jammy)
   docker-container-healthchecker (0.14.0 => 0.14.1)
   docker-image-labeler (0.8.1 => 0.9.0)
   dokku (0.35.20 => 0.37.3)
   dokku-event-listener (0.17.2 => 0.18.0)
   dokku-update (0.9.6 => 0.9.7)
   gliderlabs-sigil (0.11.4 => 0.11.5)
   herokuish (0.11.3 => 0.11.8)
   lambda-builder (0.9.1 => 0.9.2)
   netrc (0.10.2 => 0.10.3)
   plugn (0.16.0 => 0.16.1)
   procfile-util (0.20.3 => 0.20.4)
   sshcommand (0.20.0 => 0.20.1)
18 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
```

<https://dokku.com/docs/appendices/0.36.0-migration-guide/> と
<https://dokku.com/docs/appendices/0.37.0-migration-guide/> を確認して、

```bash
sudo dokku-update run -s
```

で更新しました。

0.36.0 で Ubuntu 20.04 がサポート対象外になっていたようです。

## その他のファイル

`ca-certificates.conf.dpkg-old` や `cron.daily/bsdmainutils.dpkg-remove` は単純に削除しました。
他のファイルも変更をマージして削除しました。

## まとめ

Dokku のドキュメントには OS の更新についての記述がないので、大丈夫なのかわからず、なかなか上げられずにいましたが、
Dokku 専用環境だからか OS 更新でひっかかるようなものはなくて、すんなり更新できました。

しばらく様子をみて、問題なさそうなら早めに 24.04 まで上げてしまうと良さそうだと思いました。
