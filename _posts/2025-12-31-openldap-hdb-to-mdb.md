---
layout: post
title: "OpenLDAPのバックエンドをhdbからmdbへ移行した"
date: 2025-12-31 18:36 +0900
comments: true
category: blog
tags: debian ubuntu linux
---
VPS で動かしている Ubuntu や Debian のバージョンアップのブロッカーになっていた
OpenLDAP (slapd) のバックエンドデータベースをやっと hdb から mdb に移行しました。

<!--more-->

## 対象環境

- Ubuntu 20.04.6 LTS (focal)
  - slapd 2.4.49+dfsg-2ubuntu1.10
- Debian GNU/Linux 11 (bullseye)
  - slapd 2.4.57+dfsg-3+deb11u1

## 移行手順の概要

まず `slapcat` で LDAP データベースのバックアップをとって、
hdb のデータベースは削除します。

そして <https://github.com/DSI-Universite-Rennes2/openldap-migrate-backend> を参考にして、
`/etc/ldap/slapd.d/` の `# AUTO-GENERATED FILE - DO NOT EDIT!! Use ldapmodify.` と書いてあるファイルの内容を直接書き換えて、
`CRC32` がずれるのは <https://gogs.zionetrix.net/bn8/check_slapdd_crc32> で修正します。

`slapadd` で mdb としてデータベースを復元して動作確認ができれば終了です。

## バックアップ

まず `slapcat` を使って適当なファイル名でバックアップをとっておきます。

0 は `cn=config` なので、
`/etc/ldap/slapd.d` を直接バックアップした方が良さそうです。
`etckeeper` を使っているので、そこのバックアップはしていません。

1 がメインのデータベースなので、後で使います。

2 は accesslog で使う設定にしていますが、設定がちゃんとできていなかったらしく、
トップレベルの `dn: cn=accesslog` だけで他に何もデータが入っていませんでした。

普通は 1 だけとっておけばいいと思います。

```bash
sudo slapcat -n 0 -l slapcat.0.$(date -I).ldif
sudo slapcat -n 1 -l slapcat.1.$(date -I).ldif
sudo slapcat -n 2 -l slapcat.2.$(date -I).ldif
sudo chmod 640 slapcat.*.ldif
```

## 移行対象を停止

syncrepl で 2 台体制で動かしているので、1台止めて移行します。

止めても `getent passwd` などがちゃんと動くのを確認しておきます。

```bash
sudo systemctl stop slapd.service
getent passwd
```

## olcDbDirectory

olcDbDirectory を確認して削除して空ディレクトリを作りなおしておきます。
`sudo slapadd` で root 所有のファイルができるので、後でまとめて `chown` するので、
空ディレクトリは root 所有のままにしました。

ディレクトリがないと `sudo slaptest -u -F /etc/ldap/slapd.d` でエラーになります。

空ディレクトリの作成は普通は `sudo mkdir -p /var/lib/ldap` でいいと思います。

```console
$ cd /etc/ldap
$ sudo grep -r olcDbDirectory
slapd.d/cn=config/olcDatabase={1}hdb.ldif:olcDbDirectory: /var/lib/ldap
slapd.d/cn=config/olcDatabase={2}hdb.ldif:olcDbDirectory: /var/lib/ldap/accesslog
$ ls -al /var/lib/ldap/
合計 11212
drwxr-xr-x  3 openldap openldap     4096 12月 31 18:06 .
drwxr-xr-x 56 root     root         4096 11月 20  2024 ..
-rw-r--r--  1 openldap openldap       96  8月  2  2014 DB_CONFIG
-rw-------  1 openldap openldap   532479 12月 31 18:06 __db.001
-rw-------  1 openldap openldap   139263 12月 31 18:06 __db.002
-rw-------  1 openldap openldap   286719 12月 31 18:06 __db.003
drwxr-xr-x  2 openldap openldap     4096 12月 31 18:06 accesslog
-rw-r--r--  1 openldap openldap     4096 12月 31 18:06 alock
-rw-------  1 openldap openldap    28672  3月 21  2016 cn.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 displayName.bdb
-rw-------  1 openldap openldap    24576  3月 21  2016 dn2id.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 entryCSN.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 entryUUID.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 gidNumber.bdb
-rw-------  1 openldap openldap    16384  3月 21  2016 givenName.bdb
-rw-------  1 openldap openldap    81920  3月 21  2016 id2entry.bdb
-rw-------  1 openldap openldap 10485759 12月 31 17:59 log.0000000001
-rw-------  1 openldap openldap     8192  3月 21  2016 loginShell.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 member.bdb
-rw-------  1 openldap openldap    16384  3月 21  2016 memberUid.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 objectClass.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 ou.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 sambaDomainName.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 sambaGroupType.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 sambaPrimaryGroupSID.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 sambaSID.bdb
-rw-------  1 openldap openldap    16384  3月 21  2016 sn.bdb
-rw-------  1 openldap openldap    16384  3月 21  2016 uid.bdb
-rw-------  1 openldap openldap     8192  3月 21  2016 uidNumber.bdb
$ ls -al /var/lib/ldap/accesslog/
合計 10828
drwxr-xr-x 2 openldap openldap     4096 12月 31 18:06 .
drwxr-xr-x 3 openldap openldap     4096 12月 31 18:06 ..
-rw-r--r-- 1 openldap openldap       96  8月  2  2014 DB_CONFIG
-rw------- 1 openldap openldap   532479 12月 31 18:06 __db.001
-rw------- 1 openldap openldap   139263 12月 31 18:06 __db.002
-rw------- 1 openldap openldap   114687 12月 31 18:06 __db.003
-rw-r--r-- 1 openldap openldap     4096 12月 31 18:06 alock
-rw------- 1 openldap openldap     8192  3月 21  2016 dn2id.bdb
-rw------- 1 openldap openldap     8192  3月 21  2016 entryCSN.bdb
-rw------- 1 openldap openldap    32768  3月 21  2016 id2entry.bdb
-rw------- 1 openldap openldap 10485759 12月 31 17:59 log.0000000001
-rw------- 1 openldap openldap     8192  3月 21  2016 objectClass.bdb
-rw------- 1 openldap openldap     8192  3月 21  2016 reqStart.bdb
$  sudo rm -rf /var/lib/ldap/
$  sudo mkdir -p /var/lib/ldap/accesslog
```

## `check_slapdd_crc32` を用意

CRC32 修正用のコマンドを用意しておきます。

```console
$ git clone https://gogs.zionetrix.net/bn8/check_slapdd_crc32
Cloning into 'check_slapdd_crc32'...
warning: redirecting to https://gitea.zionetrix.net/bn8/check_slapdd_crc32/
remote: Enumerating objects: 61, done.
remote: Counting objects: 100% (61/61), done.
remote: Compressing objects: 100% (51/51), done.
remote: Total 61 (delta 22), reused 0 (delta 0), pack-reused 0
Receiving objects: 100% (61/61), 12.16 KiB | 47.00 KiB/s, done.
Resolving deltas: 100% (22/22), done.
```

## 書き換え

<https://github.com/DSI-Universite-Rennes2/openldap-migrate-backend> の手順を参考にして手で書き換えました。
シェルスクリプトの内容を確認して、直接実行でも良いと思います。

```console
$ sudo grep -ri hdb
slapd.d/cn=config/olcDatabase={1}hdb.ldif:dn: olcDatabase={1}hdb
slapd.d/cn=config/olcDatabase={1}hdb.ldif:objectClass: olcHdbConfig
slapd.d/cn=config/olcDatabase={1}hdb.ldif:olcDatabase: {1}hdb
slapd.d/cn=config/olcDatabase={1}hdb.ldif:structuralObjectClass: olcHdbConfig
slapd.d/cn=config/cn=module{0}.ldif:olcModuleLoad: {0}back_hdb
slapd.d/cn=config/olcBackend={0}hdb.ldif:dn: olcBackend={0}hdb
slapd.d/cn=config/olcBackend={0}hdb.ldif:olcBackend: {0}hdb
slapd.d/cn=config/olcDatabase={2}hdb.ldif:dn: olcDatabase={2}hdb
slapd.d/cn=config/olcDatabase={2}hdb.ldif:objectClass: olcHdbConfig
slapd.d/cn=config/olcDatabase={2}hdb.ldif:olcDatabase: {2}hdb
slapd.d/cn=config/olcDatabase={2}hdb.ldif:structuralObjectClass: olcHdbConfig
$  sudo mv -vi slapd.d/cn\=config/olcBackend\=\{0\}hdb.ldif slapd.d/cn\=config/olcBackend\=\{0\}mdb.ldif
renamed 'slapd.d/cn=config/olcBackend={0}hdb.ldif' -> 'slapd.d/cn=config/olcBackend={0}mdb.ldif'
$  sudo mv -vi slapd.d/cn\=config/olcDatabase\=\{1\}hdb.ldif slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif
renamed 'slapd.d/cn=config/olcDatabase={1}hdb.ldif' -> 'slapd.d/cn=config/olcDatabase={1}mdb.ldif'
$  sudo mv -vi slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif slapd.d/cn\=config/olcDatabase\=\{2\}mdb.ldif
renamed 'slapd.d/cn=config/olcDatabase={2}hdb.ldif' -> 'slapd.d/cn=config/olcDatabase={2}mdb.ldif'
$  sudo mv -vi slapd.d/cn\=config/olcDatabase\=\{1\}hdb slapd.d/cn\=config/olcDatabase\=\{1\}mdb
renamed 'slapd.d/cn=config/olcDatabase={1}hdb' -> 'slapd.d/cn=config/olcDatabase={1}mdb'
$  sudo mv -vi slapd.d/cn\=config/olcDatabase\=\{2\}hdb slapd.d/cn\=config/olcDatabase\=\{2\}mdb
renamed 'slapd.d/cn=config/olcDatabase={2}hdb' -> 'slapd.d/cn=config/olcDatabase={2}mdb'
$  sudo sed -i 's/back_hdb/back_mdb/' slapd.d/cn=config/cn\=module\{0\}.ldif
$  sudo sed -i 's/hdb/mdb/' slapd.d/cn\=config/olcBackend\=\{0\}mdb.ldif slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif slapd.d/cn\=config/olcDatabase\=\{2\}mdb.ldif
$  sudo sed -i 's/Hdb/Mdb/' slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif slapd.d/cn\=config/olcDatabase\=\{2\}mdb.ldif
$  for attr in olcDbCacheFree olcDbCacheSize olcDbChecksum olcDbConfig olcDbCryptFile olcDbCryptKey olcDbDNcacheSize olcDbDirtyRead olcDbIDLcacheSize olcDbLinearIndex olcDbLockDetect olcDbPageSize olcDbShmKey; do sudo sed -i "/^$attr:/d" slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif; done
$  sudo sed -i '/^olcAccess: {0}/i olcDbMaxSize: 1000000000' slapd.d/cn\=config/olcDatabase\=\{1\}mdb.ldif
$  sudo ~/check_slapdd_crc32/check_slapdd_crc32 --fix
2025-12-31 18:11:21,901 - check_slapdd_crc32 - WARNING - /etc/ldap/slapd.d/cn=config/olcDatabase={0}config.ldif: no CRC32 value found. Correct CRC32 value is "47dba06d".
2025-12-31 18:11:21,902 - check_slapdd_crc32 - WARNING - /etc/ldap/slapd.d/cn=config/olcBackend={0}mdb.ldif: invalid CRC32 value found (f6ccc16c != 1918d801)
2025-12-31 18:11:21,902 - check_slapdd_crc32 - WARNING - /etc/ldap/slapd.d/cn=config/cn=module{0}.ldif: invalid CRC32 value found (bc225411 != f86810e2)
2025-12-31 18:11:21,902 - check_slapdd_crc32 - WARNING - /etc/ldap/slapd.d/cn=config/olcDatabase={1}mdb.ldif: invalid CRC32 value found (4b81209f != 7623f07e)
2025-12-31 18:11:21,903 - check_slapdd_crc32 - WARNING - /etc/ldap/slapd.d/cn=config/olcDatabase={2}mdb.ldif: invalid CRC32 value found (09c73f52 != 6c208dd4)
$  sudo slaptest -u -F /etc/ldap/slapd.d
config file testing succeeded
$  sudo slapschema -F /etc/ldap/slapd.d -b 'cn=config'
$
```

## DB 移行

mdb にバックアップしておいたデータベースを取り込んで、ファイルのオーナーなどを修正します。

```console
$  sudo slapadd -n 1 -l ~/slapcat.1.2025-12-31.ldif
_#################### 100.00% eta   none elapsed            none fast!
Closing DB...
$  sudo slapadd -n 2 -l ~/slapcat.2.2025-12-31.ldif
_#################### 100.00% eta   none elapsed            none fast!
Closing DB...
$  sudo chown -R openldap:openldap /var/lib/ldap
$
```

## 作業対象サーバーの入れ替え

同時に起動すると syncrepl で問題が起きそうなので、
残っていた1台を `sudo systemctl stop slapd.service` で止めて、
一瞬 LDAP サーバーがなくなった状態になった後、
移行した方を `sudo systemctl start slapd.service` で起動しました。

`getent passwd` などで問題がないことを確認して、次のサーバーも同様に作業しました。

## もう1台も移行

もう1台の方も `sudo systemctl start slapd.service` で起動して、
syncrepl などの状態を確認できたら移行完了です。

## 最後に

以前に移行作業しようとしたときは、全然具体的な情報がなくて諦めていましたが、
さすがに Debian で hdb 対応が消えた bookworm が oldstable になっていたり、
Ubuntu でも hdb が消えた jammy (22.04) の次の LTS の noble (24.04) が出ていたりするので、
具体的な移行方法もみつけられました。

focal も bullseye もまだ完全な EOL ではないものの、
いろんなツールなどの対応が終わってきているので、
slapd の hdb が原因でまだ上げられていない人がいれば参考にしてみてください。
