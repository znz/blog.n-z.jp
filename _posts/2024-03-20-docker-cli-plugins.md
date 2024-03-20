---
layout: post
title: "docker cli-plugins の設定方法が変わったので対応した"
date: 2024-03-20 16:00 +0900
comments: true
category: blog
tags: docker
---
homebrew で入れている docker-compose の Caveats でのメッセージが変わっていたので対応しました。

<!--more-->

## 確認バージョン

* Apple M1 Pro の MacBook Pro 14インチ 2021
* macOS Sonoma 14.4
* docker 25.0.4
* docker-compose 2.25.0
* docker-buildx 0.13.1

実際に対応したのは今月上旬なので、
もうちょっと前のバージョンから変わってそうです。

## Caveats

以下のメッセージに変わっていました。

```text
==> Caveats
==> docker-compose
Compose is a Docker plugin. For Docker to find the plugin, add "cliPluginsExtraDirs" to ~/.docker/config.json:
  "cliPluginsExtraDirs": [
      "/opt/homebrew/lib/docker/cli-plugins"
  ]
```

履歴を確認したところ、
<https://github.com/Homebrew/homebrew-core/commit/df801e24f5e537b53f287c0831fbd56591d8f753>
で変わっていて、古いメッセージは以下の内容でした。

```text
Compose is now a Docker plugin. For Docker to find this plugin, symlink it:
  mkdir -p ~/.docker/cli-plugins
  ln -sfn #{opt_bin}/docker-compose ~/.docker/cli-plugins/docker-compose
```

## 書き換え

直接書き換えても良いけれど、
`jq` を使って、
以下のように編集してみました。
Homebrew のインストール先によって `/opt/homebrew` の部分は変わるので、
Intel Mac などの他の環境では変わりそうです。

```bash
jq '.["cliPluginsExtraDirs"] |= (.+["/opt/homebrew/lib/docker/cli-plugins"] | unique)' ~/.docker/config.json > tmp.json
cat tmp.json
mv tmp.json ~/.docker/config.json
rm ~/.docker/cli-plugins/docker-compose
rmdir ~/.docker/cli-plugins
```

使ってなかったのですが docker-buildx も入っていたので、
`rm ~/.docker/cli-plugins/docker-buildx`
も必要でした。

書き換え後の内容は以下になりました。

```json
{
  "auths": {},
  "currentContext": "colima",
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
```

## まとめ

末尾の `,` の問題が面倒なので `jq` を使ったり、複数回実行しても大丈夫なように `jq` の式を工夫したりしましたが、
普通は直接 `config.json` を編集してしまえばいいと思います。

docker の cli-plugins をインストールする予定はあまりないですが、
個別に symlink を追加する必要がなくなって、
何か追加や削除したくなったときには楽になってそうです。
