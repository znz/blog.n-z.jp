---
layout: post
title: argocd-autopilotで環境ごとに適用するprojectをわける
date: 2025-06-23 12:20 +0900
comments: true
category: blog
tags: kubernetes argocd
---
{% raw %}
argocd-autopilot を使って作成した manifests の構成で、
開発環境と検証環境で1台構成と3台構成という違いがでてきて、
開発環境では kube-prometheus-stack などは省きたい、
と思ったので、
projects を使って分離しました。

<!--more-->

## 動作確認環境

- argocd-autopilot v0.4.19
- argocd v3.0.6

## 普通に生成される project

argocd-autopilot で単純に project を生成すると
`projects/testing.yaml` は以下のような内容になっています。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  annotations:
    argocd-autopilot.argoproj-labs.io/default-dest-server: https://kubernetes.default.svc
    argocd.argoproj.io/sync-options: PruneLast=true
    argocd.argoproj.io/sync-wave: "-2"
  creationTimestamp: null
  name: testing
  namespace: argocd
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  description: testing project
  destinations:
  - namespace: '*'
    server: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
  sourceRepos:
  - '*'
status: {}

---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
  creationTimestamp: null
  name: testing
  namespace: argocd
spec:
  generators:
  - git:
      files:
      - path: apps/**/testing/config.json
      repoURL: https://github.com/(my-org)/(my-manifests-repo).git
      requeueAfterSeconds: 20
      revision: ""
      template:
        metadata: {}
        spec:
          destination: {}
          project: ""
  - git:
      files:
      - path: apps/**/testing/config_dir.json
      repoURL: https://github.com/(my-org)/(my-manifests-repo).git
      requeueAfterSeconds: 20
      revision: ""
      template:
        metadata: {}
        spec:
          destination: {}
          project: ""
          source:
            directory:
              exclude: '{{ exclude }}'
              include: '{{ include }}'
              jsonnet: {}
              recurse: true
            repoURL: ""
  syncPolicy: {}
  template:
    metadata:
      labels:
        app.kubernetes.io/managed-by: argocd-autopilot
        app.kubernetes.io/name: '{{ appName }}'
      name: testing-{{ userGivenName }}
      namespace: argocd
    spec:
      destination:
        namespace: '{{ destNamespace }}'
        server: '{{ destServer }}'
      ignoreDifferences:
      - group: argoproj.io
        jsonPointers:
        - /status
        kind: Application
      project: testing
      source:
        path: '{{ srcPath }}'
        repoURL: '{{ srcRepoURL }}'
        targetRevision: '{{ srcTargetRevision }}'
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
          selfHeal: true
status: {}
```

## git generator

project に生成される ApplicationSet では、
git generator が使われています。

git generator で参照される `config.json` や `config_dir.json` の中に書くキーと値の意味がどこで定義されているのかがなかなかわからなかったのですが、
ApplicationSet の template の中で使われるものだったようです。

## k8s クラスタごとの project

`argocd cluster set in-cluster --label environment=testing`
や
`kubectl label secret -n argocd cluster-対象のクラスタ environment=testing`
などでクラスタのラベルを設定しておきます。

`in-cluster` に対応する secret ではデフォルトでは存在しないので、
最初は `argocd` CLI を使うか Web UI での設定が楽です。

`ApplicationSet` の clusters generator を使うとクラスタごとに Application を生成できますが、
argocd-autopilot の git generator のやり方から外れるとわかりにくくなりそうだったので、
matrix generator で両者を組み合わせて、
generators を以下のようにしました。

```yaml
  generators:
    - matrix:
        generators:
          - clusters:
              selector:
                matchLabels:
                  environment: testing
          - git:
              files:
              - path: apps/**/testing/config.json
              repoURL: https://github.com/(my-org)/(my-manifests-repo).git
              requeueAfterSeconds: 20
              revision: ""
              template:
                metadata: {}
                spec:
                  destination: {}
                  project: ""
    - matrix:
        generators:
          - clusters:
              selector:
                matchLabels:
                  environment: testing
          - git:
              files:
              - path: apps/**/testing/config_dir.json
              repoURL: https://github.com/(my-org)/(my-manifests-repo).git
              requeueAfterSeconds: 20
              revision: ""
              template:
                metadata: {}
                spec:
                  destination: {}
                  project: ""
                  source:
                    directory:
                      exclude: '{{ exclude }}'
                      include: '{{ include }}'
                      jsonnet: {}
                      recurse: true
                    repoURL: ""
```

## apps 定義

後は普通に argocd-autopilot のディレクトリ構成で `apps/アプリ/overlays/testing/config.json` や `apps/アプリ/testing/config_dir.json` などを作成すれば、
`environment=testing` を設定したクラスタだけに反映されました。

## 他環境対応

testing の他に dev などの environment も作成して、
開発環境だけに適応される project も作成できました。

## まとめ

cluster に対応する secret リソースを clusters generator で絞り込んで、
特定の project だけの設定を反映するようにできました。

とりあえず今回の開発環境はアプリごとに environment を作成しましたが、
selector を工夫すれば複数の環境で共通の project を用意することもできそうです。

{% endraw %}
