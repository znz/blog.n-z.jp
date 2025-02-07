---
layout: post
title: "CloudNativePGでインポートを試した"
date: 2025-02-07 12:00 +0900
comments: true
category: blog
tags: kubernetes minikube postgresql
---
Kubernetes で PostgreSQL を動かす方法を色々調べていると、
最近は
[CloudNativePG](https://cloudnative-pg.io/)
という Operator が良さそうだったので、
試し始めていて、
今回は別のデータベースからのインポートの話です。

<!--more-->

## 動作確認環境

- macOS Sequoia 15.3
- `colima` 0.8.1 で動かしている docker 環境
- `minikube` v1.35.0
- `cloudnative-pg` 1.25.0

## 直接 pg_restore

`pg_dump` したファイルをどこかに置いて直接インポートできれば一番楽だったのですが、
[MisskeyをDockerからおうちKubernetesに移行する](https://qiita.com/arila/items/3c453b7e802639eebdea)
に書いてあるように pg_dump したファイルからの import や recovery には対応していないと思っていました。

しかし、この記事を書きながら確認していると、
[Emergency backup](https://cloudnative-pg.io/documentation/1.25/troubleshooting/#emergency-backup)
に
`kubectl exec -i new-cluster-example-1 -c postgres -- pg_restore --no-owner --role=app -d app --verbose < app.dump`
という例がありました。

この方法を最低限の YAML で空のデータベースの Cluster を作成して試しました。
(ここの Cluster はデータベースのクラスタで kubernetes クラスタなどの他のクラスタとは無関係です。)

`bootstrap.initdb.database` は省略すると `app` になって、
`bootstrap.initdb.owner` は省略すると `bootstrap.initdb.database` と同じ名前になります。

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: new-cluster-example
spec:
  instances: 3

  bootstrap:
    initdb:
      database: test_app_production
      owner: test_app

  storage:
    size: 1Gi
```

```bash
kubectl exec -i new-cluster-example-1 -c postgres -- pg_restore --no-owner --role=test_app -d test_app_production --verbose < test.dump
```

でリストアしました。

途中で

```text
pg_restore: error: could not execute query: ERROR:  must be owner of extension plpgsql
Command was: COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
```

というエラーが出ていましたが、最終的に

```text
pg_restore: warning: errors ignored on restore: 1
command terminated with exit code 1
```

で終わっていたので、何か問題があれば別の方法を使った方が良さそうです。

とりあえず `-ro` の方に接続して、
`\dt` や `SELECT` などで問題なくアクセスできるのを確認しました。

```bash
kubectl run psql -it --rm --restart=Never --image=postgres:17.2 --env=PGPASSWORD="$(kubectl get secret new-cluster-example-app -o go-template='{{ "{{" }}.data.password|base64decode}}')" -- psql -h new-cluster-example-ro -U test_app -d test_app_production
```

## 一時的な pod を作成してインポート

まず
[Importing Postgres databases](https://cloudnative-pg.io/documentation/1.25/database_import/)
の microservice type を試しました。

### 一時的な postgres コンテナ作成

インポート元の一時的な postgres コンテナの pod を作成します。

後で使うので、先に basic-auth type の secret を作成しておきます。
一時的なものなので、固定パスワードでもいいのですが、シェルの特殊な変数の `$RANDOM` を使って簡易的なランダムパスワードにしました。

```bash
kubectl create secret generic tmp-postgres-superuser --type kubernetes.io/basic-auth --from-literal username=postgres --from-literal password="${RANDOM}password${RANDOM}"
```

パスワード確認のため、
よくある `jsonpath` を使うと base64 のデコードは別コマンドが必要になるので、
`kubectl` で完結させるには `go-template` で `base64decode` を組み合わせるのが良さそうでした。
(`jsonpath` は `jq` とは違っていたり、 `go-template` とは `{}` と `{{ "{{" }}}}` の違いがあったりして難しいです。

```bash
kubectl get secret tmp-postgres-superuser -o jsonpath='{.data.password}' | base64 -d ; echo
kubectl get secret tmp-postgres-superuser -o go-template='{{ "{{" }}.data.password|base64decode}}' ; echo
```

次に一時的な postgres コンテナの pod を作成しました。

image のバージョンは CloudNativePG で使うものに合わせた方が良さそうです。
(違うバージョンにする場合でも CloudNativePG 側の方が新しい方が良さそうです。)

```bash
kubectl run tmp-postgres --restart=Never --image=postgres:17.2 --port=5432 --env=POSTGRES_PASSWORD="$(kubectl get secret tmp-postgres-superuser -o go-template='{{ "{{" }}.data.password|base64decode}}')"
```

postgres コンテナに `kubectl exec` で入ると root 権限になっているので、
`runuser -u postgres --` で postgres ユーザー権限にして現状を確認しました。

記事を書いているときに気付いたのですが、
`-U postgres` でも良いようです。

```bash
kubectl exec -it tmp-postgres -- runuser -u postgres -- psql -l
kubectl exec -it tmp-postgres -- psql -U postgres -l
```

`pg_restore` でリストアして、
`psql -l` で確認しました。

`pg_restore` はリダイレクトでダンプファイルを入力するので、
`-t` は外します。

```bash
kubectl exec -i tmp-postgres -- runuser -u postgres -- pg_restore -O -C -c --if-exist -d postgres < test.dump
kubectl exec -it tmp-postgres -- runuser -u postgres -- psql -l
```

他にも何か調べるなら、忘れずに `-t` もつけて bash で入ると調査できます。

```bash
kubectl exec -it tmp-postgres -- runuser -u postgres -- /bin/bash
```

### ClusterIP 作成

DNS 名でアクセスできるようにするため、
ClusterIP の service を作成しました。

```bash
kubectl expose pod tmp-postgres
```

### インポートするデータベースクラスタ作成

`type: microservice` の `bootstrap.initdb.import` と `externalClusters` を含む
以下のような設定で作成しました。

`import` なしのときと同じように `initdb.database` の名前の `initdb.owner` がオーナーになったデータベースが作成されて、
`tmp-postgres` の `old_database_name` という名前のデータベースの内容がインポートされました。

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: test-app-db
spec:
  instances: 3

  bootstrap:
    initdb:
      database: test_app_production
      owner: test_app
      import:
        type: microservice
        databases:
          - old_database_name
        source:
          externalCluster: tmp-postgres-cluster

  storage:
    size: 1Gi

  externalClusters:
    - name: tmp-postgres-cluster
      connectionParameters:
        host: tmp-postgres
        user: postgres
        dbname: postgres
      password:
        name: tmp-postgres-superuser
        key: password
```

インポートされたクラスタが作成するのを待って確認すると、
`initdb.database` で指定したデータベースが作成されていて、
内容もインポートされているのを確認できました。

[How to wait for a particular condition](https://cloudnative-pg.io/documentation/1.25/troubleshooting/#how-to-wait-for-a-particular-condition)
に書いてある `kubectl wait` で待つと作成完了にすぐに気付けそうです。

```bash
kubectl apply -f import.yaml
kubectl wait --for=condition=Ready cluster/test-app-db --timeout=300s
kubectl exec -it test-app-db-1 -c postgres -- psql -l
kubectl run psql -it --rm --restart=Never --image=postgres:17.2 --env=PGPASSWORD="$(kubectl get secret test-app-db-app -o go-template='{{ "{{" }}.data.password|base64decode}}')" -- psql -h test-app-db-ro -U test_app -d test_app_production
```

動作確認用だったので、
`kubectl delete -f import.yaml`
で削除しましたが、そのまま使うなら残しておきます。

### 一時的に作成したリソースの削除

このあたりはインポートが終われば不要なので削除しました。

```bash
kubectl delete service tmp-postgres
kubectl delete pod tmp-postgres
kubectl delete secret tmp-postgres-superuser
```

## monolith type のインポート

CloudNativePG はデータベースクラスタ1個にデータベース1個が推奨されていて、
おすすめはされてなさそうですが、
[Importing Postgres databases](https://cloudnative-pg.io/documentation/1.25/database_import/)
の monolith type も試してみました。

事前に `tmp-postgres` に2個のデータベースをリストアしておきました。
リストアした時点でオーナーが `postgres` ユーザーになってしまっているので、
`roles` は指定せずに試しました。

`monolith` だと `initdb.database` と `initdb.owner` は `bootstrap.import` とは無関係に空のデータベースが作成されて、
インポートした `databases` のオーナーは、
`postgres` ユーザーになっていました。

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-monolith
spec:
  instances: 3

  storage:
    size: 1Gi

  bootstrap:
    initdb:
      database: test_app_production
      owner: test_app

      import:
        type: monolith
        databases:
          - foo_db
          - bar_db
        source:
          externalCluster: tmp-postgres-cluster

  externalClusters:
    - name: tmp-postgres-cluster
      connectionParameters:
        host: tmp-postgres
        user: postgres
        dbname: postgres
      password:
        name: tmp-postgres-superuser
        key: password
```

1データベースクラスタに複数データベースは推奨されていないようなので、
これ以上の深追いは止めておきました。

## バックアップの種類

CloudNativePG の
[Backup](https://cloudnative-pg.io/documentation/1.25/backup/)
などのドキュメントをみていると Physical backups を重視していて、
`pg_dump` のような Logical backups は今のところ対応していないようでした。

CloudNativePG で直接対応しているバックアップやリストアも、
プラグインで対応しているという Barman というのも、
`pg_basebackup` を使った physical backups のようです。

## まとめ

Logical backup からのインポートやリストアの説明はわかりやすいところには書いていなくて、
動いている PostgreSQL からのインポートが無難そうでした。

その方法の一例として Kubernetes クラスタの中でインポート元の postgres を動かす方法を紹介しました。
