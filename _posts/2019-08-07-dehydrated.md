---
layout: post
title: "certbotからdehydratedへのアカウントの移行"
date: 2019-08-07 18:45 +0900
comments: true
category: blog
tags: linux letsencrypt dehydrated
---
3 ヶ月前に Let's Encrypt の証明書の更新を依存関係の多い certbot から dehydrated に移行した時に、アカウントも移行したので、その手順を残しておきます。

<!--more-->

## 確認環境

- Ubuntu 18.04.2 LTS (bionic)
- letsencrypt-auto (certbot-auto) 0.35.1
- dehydrated 0.6.1-2

## 移行元のアカウント

`/etc/letsencrypt/accounts/accounts/acme-v01.api.letsencrypt.org/directory/ハッシュ値(?)` の中に `private_key.json`, `regr.json`, `meta.json` があります。
秘密鍵などがあるので、ほとんどのところを伏せていますが、内容の構造は以下のような感じです。

```
  % sudo jq . accounts/acme-staging.api.letsencrypt.org/directory/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/private_key.json
  {
    "e": "AQAB",
    "d": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "n": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "q": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "p": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "kty": "RSA",
    "qi": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "dp": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    "dq": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  }
  % sudo jq . accounts/acme-staging.api.letsencrypt.org/directory/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/regr.json
  {
    "body": {
      "contact": [
        "mailto:root@example.com"
      ],
      "agreement": "https://letsencrypt.org/documents/LE-SA-v1.0.1-July-27-2015.pdf",
      "key": {
        "e": "AQAB",
        "kty": "RSA",
        "n": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
      }
    },
    "uri": "https://acme-staging.api.letsencrypt.org/acme/reg/142119",
    "new_authzr_uri": "https://acme-staging.api.letsencrypt.org/acme/new-authz",
    "terms_of_service": "https://letsencrypt.org/documents/LE-SA-v1.0.1-July-27-2015.pdf"
  }
  % sudo jq . accounts/acme-staging.api.letsencrypt.org/directory/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/meta.json
  {
    "creation_host": "host.example.jp",
    "creation_dt": "2016-03-06T06:36:36Z"
  }
```

## dehydrated の accounts ディレクトリ作成

`/var/lib/dehydrated/accounts/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` が作成されます。
ディレクトリ名のハッシュ値のような部分は伏字にしています。

```
  % dehydrated --env
  # dehydrated configuration
  # INFO: Using main config file /etc/dehydrated/config
  mkdir: ディレクトリ `/var/lib/dehydrated/accounts' を作成できません: 許可がありません
  zsh: exit 1     dehydrated --env
  % sudo dehydrated --env
  # dehydrated configuration
  # INFO: Using main config file /etc/dehydrated/config
  declare -- CA="https://acme-v02.api.letsencrypt.org/directory"
  declare -- CERTDIR="/var/lib/dehydrated/certs"
  declare -- CHALLENGETYPE="http-01"
  declare -- DOMAINS_D=""
  declare -- DOMAINS_TXT="/etc/dehydrated/domains.txt"
  declare -- HOOK=""
  declare -- HOOK_CHAIN="no"
  declare -- RENEW_DAYS="30"
  declare -- ACCOUNT_KEY="/var/lib/dehydrated/accounts/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/account_key.pem"
  declare -- ACCOUNT_KEY_JSON="/var/lib/dehydrated/accounts/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/registration_info.json"
  declare -- KEYSIZE="4096"
  declare -- WELLKNOWN="/var/lib/dehydrated/acme-challenges"
  declare -- PRIVATE_KEY_RENEW="yes"
  declare -- OPENSSL_CNF="/usr/lib/ssl/openssl.cnf"
  declare -- CONTACT_EMAIL=""
  declare -- LOCKFILE="/var/lib/dehydrated/lock"
```

## インポート失敗

[Import account key](https://github.com/lukas2511/dehydrated/wiki/Import-from-official-letsencrypt-client#import-account-key)
にある Perl スクリプトは必要なモジュールが入っていなかったので、以下のように動きませんでした。

```
  Can't locate File/Slurp.pm in @INC (you may need to install the File::Slurp module) (@INC contains: /etc/perl /usr/local/lib/x86_64-linux-gnu/perl/5.26.1 /usr/local/share/perl/5.26.1 /usr/lib/x86_64-linux-gnu/perl5/5.26 /usr/share/perl5 /usr/lib/x86_64-linux-gnu/perl/5.26 /usr/share/perl/5.26 /usr/local/lib/site_perl /usr/lib/x86_64-linux-gnu/perl-base) at /tmp/import-account-key.pl line 8.
  BEGIN failed--compilation aborted at /tmp/import-account-key.pl line 8.
```

## ruby で変換

以下のスクリプトを `private_key.json` の場所で実行するか、
`File.read` している部分を書き換えて変換します。

試してから時間がたってしまって、具体的なバージョンをメモしていなくて確認できないのですが、
ruby が古すぎると Ruby/OpenSSL が古くてメソッド不足でエラーになった覚えがあるので、
その場合は `private_key.json` から `account_key.pem` への変換だけ新しい ruby が入っている環境を使ってみてください。

```ruby
  require 'json'
  require 'openssl'
  require 'base64'

  json_content = File.read('private_key.json')
  json_content.tr!('-_', '+/')
  json = JSON.parse(json_content)
  rsa = OpenSSL::PKey::RSA.new
  # 2 is from binary
  n = OpenSSL::BN.new(Base64.decode64(json['n']), 2)
  e = OpenSSL::BN.new(Base64.decode64(json['e']), 2)
  d = OpenSSL::BN.new(Base64.decode64(json['d']), 2)
  p = OpenSSL::BN.new(Base64.decode64(json['p']), 2)
  q = OpenSSL::BN.new(Base64.decode64(json['q']), 2)
  qi = OpenSSL::BN.new(Base64.decode64(json['qi']), 2)
  dp = OpenSSL::BN.new(Base64.decode64(json['dp']), 2)
  dq = OpenSSL::BN.new(Base64.decode64(json['dq']), 2)
  rsa.set_factors(p, q)
  rsa.set_key(n, e, d)
  rsa.set_crt_params(dp, dq, qi)
  puts rsa.to_pem
```

表示された pem を
`/var/lib/dehydrated/accounts/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/account_key.pem`
に書き込んでパーミッションを 600 にして移行完了です。

## 動作確認

`dehydrated --cron --domain foo.example.jp --hook /etc/dehydrated/hook.sh --challenge dns-01` などの普通の実行方法で更新されることを確認します。

accounts ディレクトリの中に
`/var/lib/dehydrated/accounts/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/registration_info.pem`
が自動で作成されていました。

## まとめ

certbot から dehydrated に移行した時にアカウントも移行したのに、
移行方法を公開し忘れていたので公開しました。
