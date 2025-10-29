---
layout: post
title: "limaでNFSサーバーを用意した"
date: 2025-10-29 16:30 +0900
comments: true
category: blog
tags: osx lima linux
---
k8s からの NFS のテスト用に NFS サーバーがほしくなったので、
lima で試してみました。

<!--more-->

## 動作確認バージョン

- macOS Sequoia 15.7.1
- limactl version 1.2.1
- Ubuntu 24.04.2 LTS

## 最初の動作確認

最初は以下のように同じネットワークに接続して動作確認しました。

```bash
limactl start template://ubuntu-lts --name nfs-server --containerd none --vm-type vz --network=lima:user-v2 --tty=false
limactl start template://ubuntu-lts --name nfs-client --containerd none --vm-type vz --network=lima:user-v2 --tty=false
```

## NFS サーバー側設定

最初は以下の設定で試しました。

```bash
sudo apt update
sudo apt install nfs-kernel-server
sudo mkdir /exports
sudoedit /etc/exports
```

`/etc/exports` には以下の設定をしました。

```text
/exports *(rw,fsid=0,sync,no_subtree_check,no_root_squash)
```

## NFS クライアント側

最初は以下のコマンドで試しました。

```bash
sudo apt update
sudo apt install nfs-common
mkdir /tmp/nfs
sudo mount -t nfs -o port=2049,rw,nfsvers=4,soft lima-nfs-server.internal:/ /tmp/nfs
```

実際には soft 以外のオプションはデフォルトなので不要でした。
`-t nfs` も明示する必要はありませんでした。

## NFSv4 のみに変更

[Ubuntu 22.04 に NFSv4 サーバ構築（NFSv3 無効化）](https://it-notebox.com/archives/181)
を参考にして以下のように設定変更しました。

```bash
sudo systemctl mask --now rpc-statd.service rpcbind.socket rpcbind.service
sudoedit /etc/nfs.conf
sudo ufw allow 22/tcp
sudo ufw allow 2049/tcp
sudo ufw enable
```

`/etc/nfs.conf` は `vers3=y` がコメントアウトされていた `[nfsd]` セクションに以下の設定を追加しました。
`vers2=` の行はありませんでしたが、一緒に追加しないとエラーになるようでした。

```text
vers2=n
vers3=n
```

この状態でもマウントできたので、ポートは 2049/tcp しか使われていないのが確認できました。

## 外部からの接続確認

minikube などの他の仮想マシンから接続するには、ホスト側の IP アドレスで接続できる必要があります。

確認用に `--network=lima:user-v2` なしで VM を作りなおしました。

```bash
limactl start template://ubuntu-lts --name nfs-client --containerd none --vm-type vz
limactl start template://ubuntu-lts --name nfs-server --containerd none --vm-type vz
```

## port forwarding の設定変更

ホスト側で `nc -v localhost 2049` はつながるのに、
`nc -v 192.168.253.154 2049` でつながりませんでした。
(`192.168.253.154` は macOS の IP アドレス)

server 側の lima.yaml で

```yaml
portForwards:
 - guestPort: 2049
   hostIP: "0.0.0.0"
```

として localhost 限定じゃなくす必要がありました。

## NAT 経由の問題対応

client 側から TCP 接続がつながるようになっても、
`Operation not permitted` でつながりませんでした。

```console
$ sudo mount -t nfs -o port=2049,rw,nfsvers=4,soft 192.168.253.154:/ /tmp/nfs
mount.nfs: Operation not permitted for 192.168.253.154:/ on /tmp/nfs
```

エラーメッセージで原因がわかりにくいですが、
[VirtualBoxのNAT環境でNFSクライアントとしてマウントする](https://tkjzblog.com/2021/03/20/virtualbox%E3%81%AEnat%E7%92%B0%E5%A2%83%E3%81%A7nfs%E3%82%AF%E3%83%A9%E3%82%A4%E3%82%A2%E3%83%B3%E3%83%88%E3%81%A8%E3%81%97%E3%81%A6%E3%83%9E%E3%82%A6%E3%83%B3%E3%83%88%E3%81%99%E3%82%8B/)
に書いてあるように、
NAT 経由だと /etc/exports に

```text
/exports *(rw,fsid=0,sync,no_subtree_check,no_root_squash,insecure)
```

という感じで insecure も必要でした。

分離されたネットワークにいるマシンなので insecure にしてしまいましたが、
共有のネットワークにいるマシンなら他の方法の方が良いかもしれません。

## まとめ

いくつかひっかかる点がありましたが、簡単な NFS サーバーを用意して、
クライアントからのマウントまで試せました。

最後に設定例をまとめておきます。

### サーバー側

lima.yaml に追加:

```yaml
portForwards:
 - guestPort: 2049
   hostIP: "0.0.0.0"
```

設定コマンド:

```bash
sudo apt update
sudo apt install nfs-kernel-server
sudo mkdir /exports
sudoedit /etc/exports
sudo systemctl mask --now rpc-statd.service rpcbind.socket rpcbind.service
sudoedit /etc/nfs.conf
sudo ufw allow 22/tcp
sudo ufw allow 2049/tcp
sudo ufw enable
```

`/etc/exports` に追加:

```text
/exports *(rw,fsid=0,sync,no_subtree_check,no_root_squash,insecure)
```

`/etc/nfs.conf` の `[nfsd]` セクションに設定:

```text
vers2=n
vers3=n
```

### クライアント側

```bash
sudo apt update
sudo apt install nfs-common
mkdir /tmp/nfs
sudo mount -o soft ${NFS_SERVER}:/ /tmp/nfs
```
