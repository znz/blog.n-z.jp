---
layout: post
title: "macOSのターミナルの「Control +V で非ASCII入力をエスケープ」の挙動を調べた"
date: 2025-07-04 09:25 +0900
comments: true
category: blog
tags: ruby macos
---
macOSのターミナル.appで「Control +V で非ASCII入力をエスケープ」を有効にしているとマルチバイト文字の入力が変になるという話を調べてみました。

<!--more-->

## 経緯

[Unable to type non-ASCII chars on Mac &lt;ffffffff&gt;](https://github.com/ohmyzsh/ohmyzsh/issues/7412)
ではまったという話をみて気になったので調べました。

## 調査

最初は雑に `system("stty raw -echo")` で調査したら、戻し忘れて変になったので、ちゃんと `STDIN.raw` を使って戻すようにして試しなおしました。

通常の「Control +V で非ASCII入力をエスケープ」が無効の状態では `a` でも `あ` でも問題なく入力できました。

```console
% ruby -r io/console -e 'p STDIN.raw{STDIN.sysread(80)}'
"a"
% ruby -r io/console -e 'p STDIN.raw{STDIN.sysread(80)}'
"\xE3\x81\x82"
```

設定から「Control +V で非ASCII入力をエスケープ」にチェックを入れて有効にした状態では `a` は問題なくて、`あ` の各バイトに Control-V (`\x16`) がついていました。

```console
% ruby -r io/console -e 'p STDIN.raw{STDIN.sysread(80)}'
"a"
% ruby -r io/console -e 'p STDIN.raw{STDIN.sysread(80)}'
"\x16\xE3\x16\x81\x16\x82"
```

## zsh での Control-V

`bindkey` の出力から Control-V の割り当てを確認します。
そして `zshzle` の manpage から `/quoted-insert` で検索しました。

```console
% bindkey | grep V
"^V" quoted-insert
"^X^V" vi-cmd-mode
% man zshzle
```

名前の通り、次の文字をそのまま入力する機能です。
個人的には `echo ^V^G` で BEL 文字を入力して visual bell になっているか試す、というような用途に使うことがあります。

```text

              quoted-insert
              vi-quoted-insert
                     Quote the character to insert into the minibuffer.
```

## まとめ

zsh で Control-V は quoted-insert なので、環境によってはマルチバイトの入力に必要なことがあるのかもしれませんが、
日本語環境では文字が壊れて困ることが多そうで変更しない方が良い設定だとわかりました。
