---
layout: post
title: "macOSがsudo_localに対応してpam_tid.so設定が永続化できるようになっていた"
date: 2024-12-16 11:30 +0900
comments: true
category: blog
tags: osx
---
macOS のどのバージョンからなのか確認していませんが、
`sudo_local` に対応して `pam_tid.so` (Touch ID 対応) 設定が永続化できるようになっていたのに最近気付きました。

<!--more-->

## 確認バージョン

- macOS Sequoia 15.2
- macOS Sonoma 14.7.1

## 設定方法

`.template` がついているファイルをコピーして、
`sudo -e` (他環境の `sudoedit` と同じ意味だが macOS には `sudoedit` がない)
などでコメントアウトされている `pam_tid.so` の行の行頭の `#` を削除して有効にします。

```bash
sudo cp /etc/pam.d/sudo_local{.template,}
sudo -e /etc/pam.d/sudo_local
```

## 気付いたきっかけ

Sequoia 15.2 に上がったタイミングでいつものように内容が元に戻っている `/etc/pam.d/sudo` を編集しようと思ったときに、いつもより内容をちゃんとみてみると、
`auth include sudo_local`
の行に気付きました。

そして `sudo_local.template` というファイルの存在にも気付いて、
内容を確認すると `pam_tid.so` の設定の永続化を想定しているようでした。

```console
% cat /etc/pam.d/sudo
# sudo: auth account password session
auth       include        sudo_local
auth       sufficient     pam_smartcard.so
auth       required       pam_opendirectory.so
account    required       pam_permit.so
password   required       pam_deny.so
session    required       pam_permit.so
% cat /etc/pam.d/sudo_local.template
# sudo_local: local config file which survives system update and is included for sudo
# uncomment following line to enable Touch ID for sudo
#auth       sufficient     pam_tid.so
```

## その他の macOS での対応状況

ひとつ前の Sonoma でも対応しているのは確認できて、
ちょっと検索した感じだともっと前のバージョンから対応していそうな可能性がありました。

## まとめ

`sudo_local` で `pam_tid.so` の設定が macOS の更新をしても残せそうということがわかりました。
(この設定後の更新がまだないので確認はできていない。)

`sudo` の設定変更はミスすると `sudo` が使えなくなって非常に困るので、
その設定を毎回しなくてよくなるというのは非常に良さそうでした。

[ruby-jp Slack](https://ruby-jp.github.io/) の `#apple_followers` でちょっと発言してみたところ、
`sudo_local` のことだけじゃなくて、そもそも `pam_tid.so` を知らなかったという話もあったので、
`sudo` のときのパスワード入力が面倒だと思っていた人は設定してみてください。
