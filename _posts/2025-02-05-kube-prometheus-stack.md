---
layout: post
title: "minikubeでkube-prometheus-stackを動かす"
date: 2025-02-05 12:00 +0900
comments: true
category: blog
tags: kubernetes minikube prometheus grafana
---
`minikube` 環境で何度か `prometheus-community/kube-prometheus-stack` を入れてみて、最低限の動かし方がわかったので、
そのメモです。

<!--more-->

## 動作確認環境

- macOS Sequoia 15.3
- `colima` 0.8.1 で動かしている docker 環境
- `minikube` v1.35.0
- `helm` v3.17.0
  - `helm version` と `brew info helm` で確認
- `prometheus-community/kube-prometheus-stack` version: 68.4.5
  - `helm show chart prometheus-community/kube-prometheus-stack` で確認

`minikube` と `helm` は Homebrew でインストールしました。

## minikube と helm の初期設定

`minikube start` で kubernetes 環境を用意して、
`helm` の `repo` に `prometheus-community` を追加しておきます。

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## 設定なしで動作確認

あらかじめ `kubectl create namespace monitoring` しておいたり、
`helm install` を使ったりする手順もありましたが、
`--create-namespace` や `helm upgrade --install` を使うと、
初回かどうかに関わらず同じコマンドラインを使い回せて便利でした。

```bash
helm upgrade --install kube-prometheus-stack --namespace monitoring --create-namespace prometheus-community/kube-prometheus-stack
```

コマンドを実行したときに以下のメッセージが出ていました。

```text
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
kubectl --namespace monitoring get pods -l "release=kube-prometheus-stack"

Get Grafana 'admin' user password by running:

kubectl --namespace monitoring get secrets prom-grafana -ojsonpath="{.data.admin-password}" | base64 -d ; echo

Access Grafana local instance:

export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kube-prometheus-stack" -oname)
kubectl --namespace monitoring port-forward $POD_NAME 3000

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

`secrets` の名前が違うので、そこを直して確認すると `prom-operator` になっているのを確認できます。

```bash
kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -ojsonpath="{.data.admin-password}" | base64 -d ; echo
```

`Grafana` は以下のように一度 `POD_NAME` に設定している部分をまとめて `port-forward` を実行して、
`http://localhost:3000` を開いても確認できますが、
次の `services` を使った `port-forward` の方が簡単です。

```bash
kubectl --namespace monitoring port-forward $(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kube-prometheus-stack" -oname) 3000
```

## port-forward

以下のように `port-forward` すると、
`http://localhost:9090` で `Prometheus`、
`http://localhost:8080` で `Grafana`、
`http://localhost:9093` で `Alertmanager`
が確認できます。

```bash
kubectl port-forward -n monitoring services/kube-prometheus-stack-prometheus 9090:9090
kubectl port-forward -n monitoring services/kube-prometheus-stack-grafana 8080:80
kubectl port-forward -n monitoring services/kube-prometheus-stack-alertmanager 9093:9093
```

`Prometheus` は `process_cpu_seconds_total` や `process_resident_memory_bytes` を入力して `Execute` して `Graph` をみると、
データを収集できている様子が確認できました。

`Grafana` は、
Email or username: `admin`、
Password: `prom-operator`
でログインできます。
Dashboards の Node Exporter / Nodes のあたりをみると動作しているのがわかります。

`Alertmanager` はまだ使い方がわかっていないのですが、
ちゃんと開けることが確認できます。

## kube-prometheus-stack の削除

削除して完全に元に戻すには `helm uninstall kube-prometheus-stack --namespace monitoring` だけでは CRD が残るので、
<https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md>
に書いてあるように `monitoring.coreos.com` で終わる CRD を消す必要があるようです。

## PV (Persistent Volumes) 確認

デフォルトの設定で作成された Persistent Volumes を `kubectl describe pv` などで確認すると `Path` が `/tmp/hostpath-provisioner/monitoring/pvc-name` のようになっています。
`/tmp` 以下なので、このままだと再起動すると消えてしまいます。

## PV 作成

デフォルトのパスを変更した `StorageClass` が作れれば楽そうだったのですが、
`provisioner: k8s.io/minikube-hostpath` では明示的に `path` を指定しなかったときは、
`/tmp/hostpath-provisioner/` 以下に作成されるようになっていて、デフォルトのパスは変更できないようでした。

`minikube` で再起動しても消えない pv を作るには、
[Persistent Volumes](https://minikube.sigs.k8s.io/docs/handbook/persistent_volumes/)
に書いてあるパスのうち、
`/data` を使うと良さそうだったので、そこに作成しました。

最初に試したときは用途がわかる `metadata.name` をつけていたのですが、
自動作成でも問題がない他の環境でも後述の `values.yaml` を使い回せるように、
`capacity.storage` だけ合わせて名前は連番にしてしまいました。

```bash
kubectl apply -f pv.yaml
```

```yaml
apiVersion: v1
kind: List
items:
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv0001
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 1Gi
    hostPath:
      path: /data/pv0001
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv0002
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 1Gi
    hostPath:
      path: /data/pv0002
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv0003
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 1Gi
    hostPath:
      path: /data/pv0003
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv0004
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 1Gi
    hostPath:
      path: /data/pv0004
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv0005
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 1Gi
    hostPath:
      path: /data/pv0005
      type: DirectoryOrCreate
    persistentVolumeReclaimPolicy: Delete
    storageClassName: standard
    volumeMode: Filesystem
```

試行錯誤するときに pv を delete しても中身があると残ってしまうようだったので、
`minikube ssh` で入って `sudo rm -rf /data/pv0001` のように削除する必要がありました。

## values.yaml

`helm show values prometheus-community/kube-prometheus-stack > values.yaml` で設定できる項目とそのデフォルトが確認できます。

それを元に以下のような内容を作成して、
`helm upgrade --install kube-prometheus-stack --namespace monitoring --create-namespace prometheus-community/kube-prometheus-stack -f values.yaml`
で反映しました。

前述の pv の `metadata.name` を `prometheus-pv` や `alertmanager-pv` にして `volumeClaimTemplate.volumeName` に設定すると、
明示的にその pv を使えましたが、コメントアウトしてデフォルトの動作に任せるようにしています。

`grafana` は chart が別だからか、
storage の設定方法が違っていて、
特定の pv を使うためには pvc も自分で作っておいて、
`existingClaim` に設定する必要がありました。

以下の yaml ではどれも `1Gi` を要求して、
すでに作成した pv のどれかが選ばれるようにしています。

`podMonitorSelectorNilUsesHelmValues: false` のあたりの設定は、
別記事を作成予定の [CloudNativePG](https://cloudnative-pg.io/) などで必要だったので、
あらかじめ追加しています。

```yaml
## Configuration for alertmanager
## ref: https://prometheus.io/docs/alerting/alertmanager/
##
alertmanager:

  ## Settings affecting alertmanagerSpec
  ## ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#alertmanagerspec
  ##
  alertmanagerSpec:
    ## Storage is the definition of how storage will be used by the Alertmanager instances.
    ## ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md
    ##
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: standard
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 1Gi
          # volumeName: alertmanager-pv

## Using default values from https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
##
grafana:

  ## Timezone for the default dashboards
  ## Other options are: browser or a specific timezone, i.e. Europe/Luxembourg
  ##
  defaultDashboardsTimezone: Asia/Tokyo

  adminPassword: prom-operator

  persistence:
    enabled: true
    type: pvc
    storageClassName: "standard"
    accessModes:
      - ReadWriteOnce
    size: 1Gi
    finalizers:
      - kubernetes.io/pvc-protection
    # existingClaim: kube-prometheus-stack-grafana

## Deploy a Prometheus instance
##
prometheus:

  ## Settings affecting prometheusSpec
  ## ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#prometheusspec
  ##
  prometheusSpec:

    # https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/kube-stack-config.yaml
    podMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    probeSelectorNilUsesHelmValues: false

    ## Prometheus StorageSpec for persistent data
    ## ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md
    ##
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: standard
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 1Gi
          # volumeName: prometheus-pv
```

ランダムに選ばれた pv が pvc に使われています。

```console
% kubectl get pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                                                                                             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv0001   1Gi        RWO            Delete           Bound       monitoring/kube-prometheus-stack-grafana                                                                          standard       <unset>                          30s
pv0002   1Gi        RWO            Delete           Bound       monitoring/prometheus-kube-prometheus-stack-prometheus-db-prometheus-kube-prometheus-stack-prometheus-0           standard       <unset>                          30s
pv0003   1Gi        RWO            Delete           Available                                                                                                                     standard       <unset>                          30s
pv0004   1Gi        RWO            Delete           Available                                                                                                                     standard       <unset>                          30s
pv0005   1Gi        RWO            Delete           Bound       monitoring/alertmanager-kube-prometheus-stack-alertmanager-db-alertmanager-kube-prometheus-stack-alertmanager-0   standard       <unset>                          30s
```

## pv のトラブル対応

なぜか権限の変更に失敗して `prometheus` が動いていないことがあるようなので、その対応をしました。

`kubectl get -n monitoring pod` で `prometheus-kube-prometheus-stack-prometheus-0` が `CrashLoopBackOff` などになっていて、
`kubectl describe -n monitoring pod prometheus-kube-prometheus-stack-prometheus-0`
で
`level=ERROR source=query_logger.go:113 msg="Error opening query log file" component=activeQueryTracker file=/prometheus/queries.active err="open /prometheus/queries.active: permission denied"`
のようなエラーがでていたら、正常に動いていた環境と比較してみるとパーミッションがおかしいようなので、
`minikube ssh` で入って、以下のようにパーミッションを直して、
しばらく待つか `helm` を実行しなおすと直っていました。

```console
docker@minikube:~$ sudo chmod 777 /data/pv*/prometheus-db
docker@minikube:~$ sudo chmod 777 /data/pv*/alertmanager-db
```

## まとめ

`kube-prometheus-stack` を使って、
最低限の `Prometheus` と `Grafana` の環境を用意できました。

必要に応じて `helm show values prometheus-community/kube-prometheus-stack` の出力を参考にして、
さらに設定していくと良さそうです。
