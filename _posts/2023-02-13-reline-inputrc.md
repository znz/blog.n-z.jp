---
layout: post
title: "Relineの.inputrc設定を試した"
date: 2023-02-13 19:52 +0900
comments: true
category: blog
tags: ruby
---
[ruby-jp Slack](https://ruby-jp.github.io/)の`#support`で、[`Reline.readmultiline`](https://github.com/ruby/reline#multi-line-editing-mode)で Ctrl+D (EOF) で入力完成させたいという話が30日ぐらい前にあって、
そのスレッドに追加のコメントがあって目についたので、ちょっと調べてみました。

<!--more-->

## 動作確認バージョン

調べた範囲の内容はバージョンによる違いはほとんどないと思って、1個のバージョンでしか確認していません。
ソースコードへのリンクは ruby/reline のこの記事を執筆した時点の最新版を参照しています。

- ruby 3.1.3
- reline 0.3.1

## .inputrc での分岐

[reline/config.rbの238行目あたり](https://github.com/ruby/reline/blob/afa6833e20df63b74fc53fed10a7ba3fa56237e3/lib/reline/config.rb#L238-L240)にあるように、
`$if Ruby` や `$if Reline` と `$endif` でくくると Bash などの Readline を使った他のプログラムに影響せずに設定を書けます。

```text
$if Ruby
# RubyやRelineだけで使う設定
$endif
```

## Ctrl-D の設定変更

[EmacsモードのEnterと同じ挙動](https://github.com/ruby/reline/blob/afa6833e20df63b74fc53fed10a7ba3fa56237e3/lib/reline/key_actor/emacs.rb#L29-L30)にしたいなら、
`ed_newline` にすれば良いようなので、以下のように設定すれば Ctrl+D で Enter などと同じように入力を完了できました。(入力途中なら継続行になりました。)

```text
$if Ruby
"\C-d": ed_newline
$endif
```

「Reline を vi モードで動かすと Ctrl-D で入力完了になります。」という ima1zumi さんのコメントがあったので、
[viのコマンドモードのCtrl+D](https://github.com/ruby/reline/blob/afa6833e20df63b74fc53fed10a7ba3fa56237e3/lib/reline/key_actor/vi_command.rb#L11-L12)の
`vi_end_of_transmission` や
[viのインサートモードのCtrl+D](https://github.com/ruby/reline/blob/afa6833e20df63b74fc53fed10a7ba3fa56237e3/lib/reline/key_actor/vi_insert.rb#L11-L12)の
`vi_list_or_eof` の設定も試してみました。

```text
$if Ruby
"\C-d": vi_end_of_transmission
#"\C-d": vi_list_or_eof
$endif
```

[`reline/line_editor.rb`](https://github.com/ruby/reline/blob/afa6833e20df63b74fc53fed10a7ba3fa56237e3/lib/reline/line_editor.rb#L3085)をみると
`vi_end_of_transmission` と `vi_list_or_eof` は `alias_method` で実体は同じようでした。

irb 上でいろいろ試してみると、
`ed_newline` は完全に Enter と同じ挙動ですが、
`vi_list_or_eof` は入力がないときには irb が終了するという挙動になりました。

## まとめ

デフォルトのemacsモードの Ctrl+D は末尾以外ならカーソル位置の文字を削除で、末尾だと何もしません。
`vi_list_or_eof` だと入力が空なら EOF で、入力があれば Enter と同じなので、この挙動の方が便利だと思ったら、以下の設定を `~/.inputrc` に入れておくと良さそうです。

```text
$if Ruby
"\C-d": vi_list_or_eof
$endif
```
