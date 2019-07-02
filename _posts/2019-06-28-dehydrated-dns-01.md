---
layout: post
title: "dehydratedでletsencryptの証明書をdns-01で更新した"
date: 2019-06-28 08:45 +0900
comments: true
category: blog
tags: linux letsencrypt dehydrated
---
Let's Encrypt の証明書の更新を依存関係の多い certbot から dehydrated に移行して、 DNS-01 でのドメイン確認を使うようにしてみました。

<!--more-->

## 環境

- Ubuntu 18.04.2 LTS (bionic)
- certbot-auto 0.34.2
- dehydrated 0.6.1-2
- bind9 1:9.11.3+dfsg-1ubuntu1.8

## 参考

[Examples for DNS 01 hooks](https://github.com/lukas2511/dehydrated/wiki/Examples-for-DNS-01-hooks) の [example dns 01 nsupdate script](https://github.com/lukas2511/dehydrated/wiki/example-dns-01-nsupdate-script) を参考にしました。

## 例示環境

bind9 を動かしている `ns.example.jp` に `example.jp` のマスターがあって、
`target.example.jp` と `ns.example.jp` に証明書を発行したい、とします。

## bind9 設定

### NS の委譲設定

親ゾーンに `_acme-challenge.target.example.jp` の NS の委譲設定を追加します。
一時的に TXT レコードを追加するだけのゾーンなので、
slave サーバーは追加しない方が問題が起きにくくて良いと思います。

```
_acme-challenge.target IN NS ns.example.jp.
_acme-challenge.ns IN NS ns.example.jp.
```

### dynamic zone 設定

`_acme-challenge` 用のゾーンファイルの雛形として以下のような `_acme-challenge.zone` を用意します。

```
$TTL 10m
@       IN      SOA     ns.example.jp. hostmaster.example.jp. (
                1               ; Serial
                1h              ; Refresh
                15m             ; Retry
                1w              ; Expire
                2h              ; Nagative Cache TTL
);

        IN      NS      ns.example.jp.

;; first zone file of dynamic DNS
;; see /var/cache/bind/*.zone
```

```
sudo install -o bind -g bind -m 644 zone/_acme-challenge.zone /var/cache/bind/_acme-challenge.target.example.jp.zone
sudo install -o bind -g bind -m 644 zone/_acme-challenge.zone /var/cache/bind/_acme-challenge.ns.example.jp.zone
```

のように Dynamic DNS 用のディレクトリに設置します。
この後は `nsupdate` 経由で扱うため、直接は触りません。
`nsupdate` での変更はジャーナルファイル (`*.zone.jnl`) に先に記録されるため、 `dig` で見える最新の情報が `*.zone` ファイルにあるとは限らないようです。

### nsupdate 用の鍵作成

`dnssec-keygen -r /dev/urandom -a hmac-sha512 -b 128 -n HOST <keyname>` で作成するということなので、
以下のように作成します。
この例だと `Kdehydrated-example.+165+33269.key` と `Kdehydrated-example.+165+33269.private` ができています。

```
% dnssec-keygen -r /dev/urandom -a hmac-sha512 -b 128 -n HOST dehydrated-example
Kdehydrated-example.+165+33269
% cat Kdehydrated-example.+165+33269.key
dehydrated-example. IN KEY 512 3 165 8PvYT0pDeQs0kuCBiOVRvA==
% cat Kdehydrated-example.+165+33269.private
Private-key-format: v1.3
Algorithm: 165 (HMAC_SHA512)
Key: 8PvYT0pDeQs0kuCBiOVRvA==
Bits: AAA=
Created: 20190628004245
Publish: 20190628004245
Activate: 20190628004245
```

### 鍵ファイル作成

`bind9` と `nsupdate` で共通で使うため、
`/etc/bind/conf/_acme-challenge.key.conf`
を作成します。

`key` は `dnssec-keygen` の `<keyname>` と合わせる必要はなく、あとで指定する許可設定で使います。
`secret` は key ファイルの最後のところか、 private ファイルの `Key:` の行からコピーします。
このファイルを作れば `dnssec-keygen` で作成したファイルは不要なので消してしまって構いません。

```
% sudo cat /etc/bind/conf/_acme-challenge.key.conf
key "dehydrated-example" {
  algorithm hmac-sha512;
  secret "8PvYT0pDeQs0kuCBiOVRvA==";
};
```

鍵が含まれるので、パーミッション: 640, owner: root, group: bind などにして、アクセス制限をしておいた方が良いです。

### ゾーン作成

`/etc/bind/conf/named.conf._acme-challenge.conf` として以下のように zone を作成して、
TXT レコードの変更だけ許可しました。

```
zone "_acme-challenge.target.example.jp" {
    type master;
    file "/var/cache/bind/_acme-challenge.target.example.jp.zone";
    allow-query { any; };
    update-policy {
        grant dehydrated-example name _acme-challenge.target.example.jp TXT;
    };
};

zone "_acme-challenge.ns.example.jp" {
    type master;
    file "/var/cache/bind/_acme-challenge.ns.example.jp.zone";
    allow-query { any; };
    update-policy {
        grant dehydrated-example name _acme-challenge.ns.example.jp TXT;
    };
};
```

## テスト

以下のようにエラーが出てこなければ正常です。

```
% printf "server %s\nupdate add _acme-challenge.%s. %d in TXT \"%s\"\nsend\n" 127.0.0.1 target.example.jp 300 "test" | sudo nsupdate -k /etc/bind/conf/_acme-challenge.key.conf
% dig +short @127.0.0.1 _acme-challenge.target.example.jp txt
"test"
% printf "server %s\nupdate delete _acme-challenge.%s. %d in TXT \"%s\"\nsend\n" 127.0.0.1 target.example.jp 300 "test" | sudo nsupdate -k /etc/bind/conf/_acme-challenge.key.conf
```

bind9 の設定がちゃんとできていないと `response to SOA query was unsuccessful` と出てきて失敗しました。
dehydrated コマンドで `update failed: REFUSED` と出てきたこともあったので、これも `nsupdate` の失敗メッセージかもしれません。

## dehydrated 設定

### domains.txt

対象のドメインを並べて書いておきます。
1行1証明書で、 SANs で複数入れたい場合は横に並べるようです。

```
% cat /etc/dehydrated/domains.txt
target.example.jp
ns.example.jp
```

### hook

`/etc/dehydrated/hook.sh` として以下の内容の hook を作成しました。

```
#!/bin/bash
set -euo pipefail

NSUPDATE="nsupdate -k /etc/bind/conf/_acme-challenge.key.conf"
DNSSERVER="127.0.0.1"
TTL=300

ruby -e 'printf "%s %p\n", Time.now.strftime("%Y-%m-%d %H:%M:%S"), ARGV' -- "$@" >>/var/log/dehydrated-hook.log

case "$1" in
    "deploy_challenge")
        printf "server %s\nupdate add _acme-challenge.%s. %d in TXT \"%s\"\nsend\n" "${DNSSERVER}" "${2}" "${TTL}" "${4}" | $NSUPDATE
        ;;
    "clean_challenge")
        printf "server %s\nupdate delete _acme-challenge.%s. %d in TXT \"%s\"\nsend\n" "${DNSSERVER}" "${2}" "${TTL}" "${4}" | $NSUPDATE
        ;;
    "deploy_cert")
        shift
        /etc/dehydrated/deploy_cert.sh "$@"
        ;;
    "unchanged_cert")
        # do nothing for now
        ;;
    "startup_hook")
        # do nothing for now
        ;;
    "exit_hook")
        # do nothing for now
        ;;
esac

exit 0
```

### deploy_cert.sh

hook.sh から呼び出している `/etc/dehydrated/deploy_cert.sh` は以下のような内容にしました。

HTTP-01 を使っているときは常に apache2 にも証明書を設定していたので、
apache2 の reload は必ず実行していて、
DNS-01 を使うようになって不要なドメインもありますが、
restart に比べて reload はそんなに重くないので、
必要なドメインで reload を忘れた時の影響の方が大きいかと思い、
入れたままにしています。

今回の例には入っていませんが、
mx や ldap のドメインでの reload の例も入れています。

```
#!/bin/bash
DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"

install -v -o root -g root -m 600 "${KEYFILE}" "/etc/ssl/private/${DOMAIN}.key"
install -v -o root -g root -m 644 "${FULLCHAINFILE}" "/etc/ssl/certs/${DOMAIN}.crt"

systemctl reload apache2.service
case "${DOMAIN}" in
  mx*)
    systemctl reload postfix.service
    systemctl reload dovecot.service
    ;;
  ldap*)
    install -v -o root -g openldap -m 640 "${KEYFILE}" /etc/ssl/private/slapd.pem
    install -v -o root -g root -m 644 "${FULLCHAINFILE}" /etc/ssl/certs/slapd.crt
    systemctl restart slapd.service
    ;;
esac
```

## 最後に

自前の DNS サーバーで権威サーバーを運用している場合の DNS-01 を使った dehydrated での letsencrypt の証明書の発行方法を紹介しました。

API に対応している他の DNS サービスで DNS-01 を使う場合は、 dehydrated の wiki から各種 hook へのリンクがあるので、参考にすれば良さそうです。

ワイルドカード証明書を発行したかったり、外から HTTP(S) アクセスできないサーバーに証明書を入れたかったりする場合に HTTP-01 ではなく DNS-01 が必須になってくるので、そういうものもそのうち試してみたいと思っています。
