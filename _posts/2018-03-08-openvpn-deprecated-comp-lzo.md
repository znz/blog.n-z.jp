---
layout: post
title: "OpenVPNでcomp-lzoがdeprecatedになっていた"
date: 2018-03-08 21:35 +0900
comments: true
category: blog
tags: openvpn
---
Tunnelblick が 3.7.5 に上がって警告が出るようになって知ったのですが、
`comp-lzo` が deprecated になっていて、
`compress` に置き換える必要があるようです。

<!--more-->

## 対象バージョン

- サーバー側
  - Debian GNU/Linux 9.3 (stretch)
  - openvpn 2.4.0-6+deb9u2
- クライアント側
  - Tunnelblick 3.7.5
  - OpenVPN GUI 2.4.2 (2.4.5 が最新だったので後で更新しました)

## 結論

結論を先に書いておくと、
サーバー側から新しい設定を `push` するようにしてから、
クライアント側は徐々に `comp-lzo` を削っていけば良いようです。

## comp-lzo

[Openvpn24ManPage](https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage)
には、
「 **DEPRECATED** This option will be removed in a future OpenVPN release. Use the newer **--compress** instead.」
と書いてあって、
すぐに削除されるわけではなさそうですが、
Tunnelblick の警告を止めるためにも compress に置き換えた方が良さそうです。

## compress

OpenVPN 2.4 では `compress` のアルゴリズムとして

- `lzo` (`comp-lzo` 互換)
- `lz4`
- `lz4-v2`

が指定できるようです。

## クライアント側のみ変更 (失敗)

クライアント側のみ `comp-lzo` をコメントアウトしてみると繋がらなくなりました。

## comp-lzo のままサーバー側のみ変更

アルゴリズムを変更する時にクライアント側まで変更しなくて良いように、
`push` を使う方が普通のようなので、
サーバー側で

```
comp-lzo yes
push "comp-lzo yes"
```

に変更してみたところ、問題なく繋がりました。

さらにこの設定もコメントアウトしてみたところ、

```
WARNING: 'comp-lzo' is present in remote config but missing in local config, remote='comp-lzo'
```

とサーバー側のログに出つつ繋がりました。

## lz4-v2

クライアント側は `comp-lzo` の設定が残っているまま、
サーバー側で

```
compress lz4-v2
push "compress lz4-v2"
```

と設定して、
さらにログレベルを `verb 9` にしてみると、
`LZ4 decompress 77 -> 116`
というログがあったので、
lzo ではなく lz4 で繋がっているようでした。

## client-connect スクリプト

["comp-lzo no" and "compress" options not compatible](https://community.openvpn.net/openvpn/ticket/952)
に

```sh
#!/bin/sh
CONF=$1
# compression autoselect
if [ "$IV_LZ4v2" ] ; then
    cat <<EOF >>$CONF
compress lz4-v2
push "compress lz4-v2"
EOF
elif [ "$IV_LZ4" ] ; then
    cat <<EOF >>$CONF
compress lz4
push "compress lz4"
EOF
else
    echo "compress lzo" >>$CONF
fi

exit 0
```

という `client-connect` スクリプトがあって、
これを使えば対応している一番良い圧縮形式が使われるようです。

サーバー側の conf には `compress` を書かずに、
`client-connect` スクリプトを使う設定に変更してみたところ、
クライアント側に `comp-lzo` があってもなくても繋がるようになりました。

## 現状

すでに遠隔にある環境からも、設定をいじってもらわなくても繋がる、
という状況にできました。

## 今後

今後渡す ovpn ファイルには `comp-lzo` の設定を入れず、
徐々にサーバー側からの `push "compress algorithm"` だけに
移行していけるようになりました。
