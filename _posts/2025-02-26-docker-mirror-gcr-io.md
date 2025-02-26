---
layout: post
title: "Docker Hubのミラーのmirror.gcr.ioを使う"
date: 2025-02-26 13:00 +0900
comments: true
category: blog
tags: linux docker colima
---
[Docker Hub は rate limit がさらに厳しくなるらしい](https://x.com/matsuu/status/1893609848144593061)
という話があって、
`mirror.gcr.io` を使うと良いという話があったので、その設定をしました。

<!--more-->

## 参考

- [Docker Hub のレート制限を受けないように mirror.gcr.io を使う \| blog.monophile.net](https://blog.monophile.net/posts/20201101_docker_mirror_gcr_io.html)
- colima の [How to customize Docker config (e.g., adding insecure registries or registry mirrors)?](https://github.com/abiosoft/colima/blob/e79883bde6581b8ab0db8d0c63103cf4b1e89f8a/docs/FAQ.md#how-to-customize-docker-config-eg-adding-insecure-registries-or-registry-mirrors)
- [キャッシュに保存された Docker Hub イメージの pull](https://cloud.google.com/artifact-registry/docs/pull-cached-dockerhub-images?hl=ja)

## 動作確認バージョン

- colima version 0.8.1
- docker client: v28.0.0
- docker server: v27.4.0

## colima で設定確認

まず `etc/docker/daemon.json` を編集して `docker.service` を `restart` して反映しました。

```bash
json=$(colima ssh cat /etc/docker/daemon.json | jq '.["registry-mirrors"] |= (.+["https://mirror.gcr.io"] | unique)') sh -c 'echo "$json" | colima ssh sudo tee /etc/docker/daemon.json'
colima ssh sudo systemctl restart docker
```

参考にしたブログに書いてあった方法で動作確認しました。

`colima ssh` で入って以下のように `tcpdump` を開いた状態で、
他の端末から `docker pull` などをして通信が発生しているのを確認しました。

```bash
sudo apt update
sudo apt install tcpdump
tcpdump -nni eth0 host ${ホスト側で ping -c1 mirror.gcr.io で調べたIPアドレス}
```

Google Cloud のドキュメントにある `docker system info` の確認方法でも以下の内容を確認できました。

```text
 Registry Mirrors:
  https://mirror.gcr.io/
```

## colima の設定保存

`colima stop` して `colima start` しなおすと元に戻っていたので調べてみると、
FAQ に書いてあるように `colima start --edit` または `colima template` で `docker:` に設定を書く必要があったので、
以下のように変更しました。

```diff
- docker: {}
+ docker:
+   registry-mirrors:
+     - https://mirror.gcr.io
```

`colima start --edit` は編集が終わったらすぐに起動しました。
変更した内容は `~/.config/colima/default/colima.yaml` に残っていました。
`XDG_CONFIG_HOME` を設定していなければ、デフォルトの `~/.colima/default/colima.yaml` に残るはずです。

`colima template` はデフォルトのテンプレートの変更のようで、
変更を保存すると `~/.config/colima/_templates/default.yaml` が作成されました。
これがあると `colima delete` した後などの新規作成時にも反映されるようになりました。

## 他の環境に設定

VPS などの他の環境は `/etc/docker/daemon.json` があったりなかったりしたので、
手で設定していきました。

## まとめ

Docker Hub の Rate Limit の対策として `mirror.gcr.io` の設定をしました。

colima のように自動的に設定が戻ってしまう環境もあるようなので、
再起動しても反映されたままかの確認までしておいた方が良さそうです。
