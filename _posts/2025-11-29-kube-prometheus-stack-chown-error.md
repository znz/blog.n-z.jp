---
layout: post
title: "kube-prometheus-stackでinit-chown-dataがエラーになっていたのを対処した"
date: 2025-11-29 13:00 +0900
comments: true
category: blog
tags: kubernetes grafana
---
kube-prometheus-stack helm chart でインストールしている grafana で init-chown-data がエラーになっていたので、
対処する設定を追加しました。

<!--more-->

## 確認バージョン

- <https://prometheus-community.github.io/helm-charts> の kube-prometheus-stack 79.1.1

## エラー内容

正常起動する前のログなので、k9s では確認できなかったのですが、
後で loki で確認できたログによると <https://github.com/grafana/helm-charts/pull/3698> と同じで、

```text
chown: /var/lib/grafana/csv: Permission denied
chown: /var/lib/grafana/png: Permission denied
chown: /var/lib/grafana/pdf: Permission denied
```

というエラーが出ていました。

## 仮対応

最初は init-chown-data が失敗しているという情報しかなく、
local-path-provisioner を使っていたので、
PV の場所を確認して、
何かできることはないかと思って、とりあえず空ディレクトリの削除を

```bash
sudo rmdir -v /opt/local-path-provisioner/pvc-*_monitoring_kube-prometheus-stack-grafana/{csv,pdf,png}
```

で試したら起動するようになったので、その対応を繰り返していました。

## 設定

<https://github.com/grafana/helm-charts/pull/3698>
に `readOnlyRootFilesystem: true` と `capabilities` に `DAC_READ_SEARCH` を追加する、
という pull request があったので、その設定を追加しました。

grafana は kube-prometheus-stack の helm subchart なのでの設定方法に悩みましたが、
`initChownData.securityContext` が `grafana.initChownData.securityContext` になるようにするだけでした。

```yaml
## Using default values from https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
##
grafana:

  # Fix init-chown-data error
  # pick from https://github.com/grafana/helm-charts/pull/3698
  initChownData:
    securityContext:
      readOnlyRootFilesystem: true
      capabilities:
        add:
        - CHOWN
        - DAC_READ_SEARCH
        drop:
        - ALL
```

## 別の方法

pull request がマージされない原因のコメントのように細かいセキュリティを気にするなら、
`initChownData.enabled` を `false` にして `init-chown-data` 自体を実行しない、
という方法もあるようです。

## 原因

問題のディレクトリが `drwx------` で owner 472 なので、
root ユーザーには `chown -R` をするときにパーミッションによるディレクトリの中のファイル一覧を読む許可がなくて、
通常の root 権限はパーミッションを無視して読めるのも `DAC_READ_SEARCH` という capabilities を drop していると無理、
というのが原因だったようです。

capabilities の `DAC_READ_SEARCH` を add してしまうと root 権限でなくてもパーミッションを無視してディレクトリの中のファイル一覧を読めてしまう、
というのが pull request でセキュリティを気にする人がコメントしている内容だと思うので、
root 権限にだけ `DAC_READ_SEARCH` を残せれば良さそうなのですが、できるのかどうかわかりませんでした。

## まとめ

`kube-prometheus-stack` helm chart の value.yaml に `grafana.initChownData.securityContext` で許可を追加するか、
`grafana.initChownData.enabled` を `false` にすればエラーは解消されそうです。

```yaml
## Using default values from https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
##
grafana:

  # Fix init-chown-data error
  # pick from https://github.com/grafana/helm-charts/pull/3698
  initChownData:
    securityContext:
      readOnlyRootFilesystem: true
      capabilities:
        add:
        - CHOWN
        - DAC_READ_SEARCH
        drop:
        - ALL
```
