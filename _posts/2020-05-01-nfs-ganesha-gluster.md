---
layout: post
title: "nfs-ganesha-glusterを設定してみた"
date: 2020-05-01 23:00 +0900
comments: true
category: blog
tags: gluster debian linux
---
glusterfs に他のサーバーから書き込むのに、
NFS 経由の方が gluster のバージョンに悩む必要がなくて良いかと思って、
nfs-ganesha-gluster を設定してみました。
設定例が少ないので簡単かと思いきや、意外とハマりどころがありました。

<!--more-->

## 動作確認環境 (サーバー側)

- Raspbian 10 (buster)

## インストール

`sudo apt install nfs-ganesha-gluster` で依存している `nfs-ganesha` なども含めて入ります。

インストール途中で起動に失敗しますが、設定前なので気にしなくても大丈夫そうです。

```
Setting up nfs-ganesha (2.7.1-2) ...
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-ganesha.service → /lib/systemd/system/nfs-ganesha.service.
Created symlink /etc/systemd/system/nfs-server.service.wants/nfs-ganesha-lock.service → /lib/systemd/system/nfs-ganesha-lock.service.
nfs-ganesha-config.service is a disabled or a static unit, not starting it.
Job for nfs-ganesha.service failed because the control process exited with error code.
See "systemctl status nfs-ganesha.service" and "journalctl -xe" for details.
```

## 設定ファイルは /etc/ganesha/ganesha.conf のみ

`/etc/ganesha/gluster.conf` が存在するので、
`/etc/ganesha/*.conf` 全部が読み込まれているのかと勘違いして、
かなり悩んでしまったのですが、
デフォルトでは `/etc/ganesha/ganesha.conf` だけしか使われていませんでした。

`/etc/ganesha/gluster.conf` を元に `/etc/ganesha/ganesha.conf` に設定をしました。

バージョンアップ時の処理を考慮して conffile をあまり変更したくないなら、
`/etc/default/nfs-ganesha` の
`OPTIONS="-L /var/log/ganesha/ganesha.log -f /etc/ganesha/ganesha.conf -N NIV_EVENT"`
のファイル指定を変更しても良さそうです。

## 設定

`/etc/ganesha/ganesha.conf` は以下のような設定にしました。

firewall の設定に困るので
<https://github.com/nfs-ganesha/nfs-ganesha/blob/next/src/doc/man/ganesha-core-config.rst>
を参考にして `MNT_Port` と `NLM_Port` は固定にしました。
ポート番号は何でも良さそうだったので <https://github.com/nfs-ganesha/nfs-ganesha/wiki/Ganesha-config> からとってきました。

```
EXPORT
{
	# Export Id (mandatory, each EXPORT must have a unique Export_Id)
	Export_Id = 42;

	# Exported path (mandatory)
	Path = "/mydata";

	# Pseudo Path (required for NFS v4)
	Pseudo = "/mydata";

	# Required for access (default is None)
	# Could use CLIENT blocks instead
	Access_Type = RW;

	# Allow root access
	Squash = No_Root_Squash;

	# Security flavor supported
	SecType = "sys";

	# Exporting FSAL
	FSAL {
		Name = "GLUSTER";
		Hostname = "10.42.42.1";
		Volume = "mydata";
		Up_poll_usec = 10; # Upcall poll interval in microseconds
		Transport = tcp; # tcp or rdma
	}
}

NFS_Core_Param
{
	MNT_Port = 32767;
	NLM_Port = 32769;
}
```

## firewall の許可

111,875,2049,32767,32769 番ポートを tcp と udp の両方で許可しておきます。

## tcp wrapper の許可

`/etc/hosts.allow` で `rpcbind` を許可しました。

`mountd` などは `nfs-ganesha` が提供していて、
tcp wrapper は使っていないようなので、
ここでの許可は不要でした。

設定例としては以下のような感じです。

```
rpcbind: 127.0.0.1 [::1]
rpcbind: 10.
rpcbind: 192.168.0.0/24
rpcbind: [fe80::%eth0]/10
rpcbind: [fe80::%wlan0]/10
rpcbind: [fdcb:a987:6543:2100::]/64
```

## マウントテスト

`mkdir -p /tmp/test; sudo mount localhost:/mydata /tmp/test` のように nfs でマウントできて、
読み書きもできることを確認します。

大丈夫そうなら、
`/etc/fstab` に追加するなど、
普通に使えます。

## トラブルシューティング

### 起動しない

`systemctl status nfs-ganesha` や `/var/log/ganesha/` のログをみて調べました。

### ポートがわからない

`sudo rpcinfo -p | grep mountd` や `sudo ss -lntp` で調べました。

### export されているかどうかわからない

`showmount` コマンドを使って、動作確認しました。

- `sudo /sbin/showmount -e localhost`
- `sudo /sbin/showmount -e 127.0.0.1`
- `sudo /sbin/showmount -e`
- `sudo /sbin/showmount -e 192.168.0.42`

`clnt_create: RPC: Program not registered` は `nfs-ganesha` の起動に失敗しているようなので、
設定やログを確認します。

`rpc mount export: RPC: Unable to send; errno = Operation not permitted`
は firewall で塞がれていないか確認します。

`clnt_create: RPC: Authentication error` は tcp wrapper の設定を確認します。

`Export list for localhost:` のような行だけだと何も export されていません。

`/mydata (everyone)` のような行が続いていれば、それをマウントできます。

### owner, group が変?

Debian 9 (stretch) のホストからマウントして使ってみると、
`drwxr-xr-x  2 nobody 4294967294 4096  4月 26 17:27 .`
のように owner と group がすべて nobody 4294967294 (-2) に見えているという現象が出ていたのですが、
rsync でのバックアップとして使った感じだと、
ちゃんと書き込めていて、
他のマシンからみると問題なく owner や group が見えていて、
rsync を実行し直しても変化していて書き込み直しにもならない、
ということがおきていました。

stretch は oldstable でバックアップを取り終わったら止める予定だったので、
深く追求することはしませんでした。

## 感想

wireguard 経由で自宅サーバーの USB HDD を VPS から nfs でマウントしたので、
速度的にはそれなりなので、直接の作業場所として使うのには向いていませんが、
バックアップ先としては問題なく使えそうでした。

nfs-ganesha の層でキャッシュもあるので、
gluster のサーバー群とは離れたサーバーからは
gluster 直接よりも良さそうに感じました。
