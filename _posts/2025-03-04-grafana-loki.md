---
layout: post
title: "Grafana Lokiを試した"
date: 2025-03-04 12:00 +0900
comments: true
category: blog
tags: linux docker kubernetes grafana loki
---
Kubernetes の `kubectl logs` だとクラッシュによるリスタートやオートスケールなどで終了してしまった pod のログが確認できなくて不便だったので、
Grafana Loki を試してみました。

<!--more-->

## 動作確認バージョン

- grafana/loki Chart version: 6.27.0
- Loki version: 3.4.2

## はまった点1: マルチテナントモード

[Install the monolithic Helm chart](https://grafana.com/docs/loki/latest/setup/install/helm/install-monolithic/)
の手順で入れると、
Grafana で Add new connection から追加しようとしたときに URL だけ入れても
`Unable to connect with Loki. Please check the server logs for more details.`
で失敗します。

helm でインストールしたときのメッセージの最後に以下のメッセージが出ていると、
マルチテナントモードになっていて、
HTTP headers で `X-Scope-OrgID` を追加する必要があります。

value を `foo` にして、
Explore から Label filters に `service_name = test` を指定すると、
このメッセージの前に出ていた curl コマンドで記録したログが確認できました。

Data source の編集か追加で value を `self-monitoring` にして、
Explore から Label filters に `stream = stdout` を指定すると内部的なログを確認できました。

```text
***********************************************************************
Multi-tenancy
***********************************************************************

Loki is configured with auth enabled (multi-tenancy) and expects tenant headers (`X-Scope-OrgID`) to be set for all API calls.

You must configure Grafana's Loki datasource using the `HTTP Headers` section with the `X-Scope-OrgID` to target a specific tenant.
For each tenant, you can create a different datasource.

The agent of your choice must also be configured to propagate this header.
For example, when using Promtail you can use the `tenant` stage. https://grafana.com/docs/loki/latest/send-data/promtail/stages/tenant/

When not provided with the `X-Scope-OrgID` while auth is enabled, Loki will reject reads and writes with a 404 status code `no org id`.

You can also use a reverse proxy, to automatically add the `X-Scope-OrgID` header as suggested by https://grafana.com/docs/loki/latest/operations/authentication/

For more information, read our documentation about multi-tenancy: https://grafana.com/docs/loki/latest/operations/multi-tenancy/

> When using curl you can pass `X-Scope-OrgId` header using `-H X-Scope-OrgId:foo` option, where foo can be replaced with the tenant of your choice.
```

マルチテナントモードについては
[Manage tenant isolation](https://grafana.com/docs/loki/latest/operations/multi-tenancy/)
に書いてあって、
とりあえず試すための小規模な環境でマルチテナントは不要なので、
`loki.auth_enabled` を `false` にしてシングルテナントモードで使うことにしました。

後でみつけた別の設定例の
[Kubernetes Monitoring Helm tutorial](https://grafana.com/docs/loki/latest/send-data/k8s-monitoring-helm/)
だと `loki.auth_enabled` は `false` になっていました。

こちらを使って、以下のようにしました。

```bash
helm repo add grafana https://grafana.github.io/helm-charts
git clone https://github.com/grafana/alloy-scenarios
cd alloy-scenarios/k8s/logs
time helm upgrade --install --create-namespace --namespace logging --values loki-values.yml loki grafana/loki
```

Loki のインストールには1分以上時間がかかるので、ゆっくり待つ必要がありました。

## はまった点2: Grafana Alloy の情報が少ない

日本語で Loki との組み合わせでよく紹介されている `promtail` は deprecated になっていて、
Grafana Alloy に移行するように書いてあるのですが、まだ日本語での情報はあまりありませんでした。

Grafana Alloy は Grafana Agent の後継で、
`promtail` などの機能も統合したもののようです。

Pod のログを収集するのは、
<https://github.com/grafana/alloy-scenarios/tree/main/k8s/logs> (<https://github.com/grafana/alloy-scenarios/tree/0417f9f34a61d7ec8da76f6f0ccd746ba5b85a74/k8s/logs>)
の
`k8s-monitoring-values.yml`
を使うとうまくいきました。

```bash
helm upgrade --install --create-namespace --namespace logging --values k8s-monitoring-values.yml k8s grafana/k8s-monitoring
```

実際には Loki の namespace を変更していたのと、
namespaces の制限が不要だったので、
`url` と `namespaces` を以下のように変更しました。

```yaml
cluster:
  name: logging-cluster
destinations:
  - name: loki
    type: loki
    url: http://loki-gateway.logging.svc.cluster.local/loki/api/v1/push
clusterEvents:
  enabled: true
  collector: alloy-logs
  namespaces: [] # all
nodeLogs:
  enabled: false
podLogs:
  enabled: true
  gatherMethod: kubernetesApi
  collector: alloy-logs
  labelsToKeep: ["app_kubernetes_io_name","container","instance","job","level","namespace","service_name","service_namespace","deployment_environment","deployment_environment_name"]
  structuredMetadata:
    pod: pod  # Set structured metadata "pod" from label "pod"
  namespaces: [] # all
# Collectors
alloy-singleton:
  enabled: false
alloy-metrics:
  enabled: false
alloy-logs:
  enabled: true
  alloy:
    mounts:
      varlog: false
    clustering:
      enabled: true
alloy-profiles:
  enabled: false
alloy-receiver:
  enabled: false
```

## Grafana に追加

Grafana は以前入れた `kube-prometheus-stack-grafana` のものをそのまま使いました。

```bash
kubectl port-forward --namespace monitoring services/kube-prometheus-stack-grafana 8080:80
```

追加は以下のようにしました。

- 左上の3本線 - Connections - Loki を検索して選択 <http://localhost:8080/connections/datasources/loki>
- 右上の Add new data source
- URLに <http://loki-gateway.logging.svc.cluster.local:80>
- Save & Test で保存

削除や編集は、以下からできました。

- 左上の3本線 - Connections の中の Data sources

ログの確認は以下からできました。

- 左上の3本線 - Explore の中の Logs

## はまった点3: minikube の pv 設定

`minikube` のデフォルトの pv は `/tmp` 以下で再起動すると消えてしまうので、
`/data` 以下の pv を用意しました。

`storage-loki-0` は 10Gi で
`export-0-loki-minio-0` と
`export-1-loki-minio-0` は 5Gi を要求していたので、
作っておきました。

しかし、
`kubectl delete` で pvc の削除や pod の削除をすると `/data` を指定した pv が使われるようになりましたが、書き込みに失敗していたので、
`minikube ssh` で入って、変更する必要がありました。

```bash
docker@minikube:~$ sudo chmod 777 /data/pv-10a
docker@minikube:~$ sudo chmod 777 /data/pv5a
docker@minikube:~$ sudo chmod 777 /data/pv5b
```

それでも `loki-0` のログをみると以下のような `NoSuchBucket` のエラーで失敗していました。

```text
level=error ts=2025-03-04T00:28:21.398770338Z caller=table.go:370 table-name=loki_index_20151 org_id=fake traceID=2d0ba8b6c8bd44b5 msg="index set fake has some problem, cleaning it up" err="NoSuchBucket: The specified bucket does not exist\n\tstatus code: 404, request id: 1829720614AC23F6, host id: 3f5faf5235fea6fb0f941c4385fb93e388ab891fa6004dd49fe7fcb235ca51ad"
```

いろいろ調べた結果、
`helm template --values loki-values.yml loki grafana/loki -n meta | less` で確認すると、
初期 bucket は loki-minio-post-job で作成されていたので、
`kubectl delete -n logging loki-minio` で再起動ではなく、
`time helm upgrade --install --create-namespace --namespace logging --values loki-values.yml loki grafana/loki`
の再実行が必要とわかったので、再実行すると、バケットが作成されてエラーが解決しました。

手元の `kind` で試したときは、こういう点でははまらなかったので、
minikube 特有の困りごとになっています。

`/tmp` 以下に自動作成されるディレクトリは `drwxrwxrwx` になっているので、
pv を作成したときにディレクトリも `sudo install -m 777 -d /data/pvdir` のように手で作成しておくのが良いのかもしれない、
と思いました。

### pv-10.yaml

参考として 10Gi の pv の YAML をのせておきます。

```yaml
apiVersion: v1
kind: List
items:
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-10a
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 10Gi
    hostPath:
      path: /data/pv-10a
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-10b
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 10Gi
    hostPath:
      path: /data/pv-10b
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-10c
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 10Gi
    hostPath:
      path: /data/pv-10c
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
```

### pv5.yaml

5Gi の方ものせておきます。

```yaml
apiVersion: v1
kind: List
items:
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv5a
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 5Gi
    hostPath:
      path: /data/pv5a
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv5b
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 5Gi
    hostPath:
      path: /data/pv5b
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv5c
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 5Gi
    hostPath:
      path: /data/pv5c
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
```

## はまった点4: kind のデフォルトのクラスタで Pod が起動しない

`minikube` で試す前に `kind` で試していたのですが、
`kind` のデフォルトの 1 ノードのクラスタだと、
`loki-0` の Pod が `READY` `0/2` で起動しないままだったので、
`kubectl describe -n logging pod loki-0`
で調べてみると、

```text
0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory. preemption: 0/1 nodes are available: 1 No preemption victims found for incoming pod.
```

となっていて、
cpu や memory 不足だったので、

```bash
kind create cluster --config kind.yml
```

で 3 ノードのクラスタで作りなおすと動作確認できました。

`loki-values.yml` の `requests` を `cpu: 1` と `memory: 100Mi` にしても起動できたので、
とりあえず起動を確認するだけなら、
これでも良さそうです。

## まとめ

Grafana Loki と Grafana Alloy と Grafana で Kubernetes のログを集約できるようになりました。

はまりどころが多くて、動かしてある程度のログを確認するところまででも大変でした。

保存するログの選択や活用方法の検討などは今後考えていきたいです。
