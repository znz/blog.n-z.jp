---
layout: post
title: "シリアルコンソールのターミナルのサイズ変更"
date: 2022-01-30 19:30 +0900
comments: true
category: blog
tags: linux qemu
---
qemu で `-nographic` や `-serial mon:stdio` などでシリアルコンソールからログインすると、端末サイズが 80x24 扱いになって、表示が崩れることがあって不便なので、[Arch Linux の Wiki](https://wiki.archlinux.org/title/working_with_the_serial_console#Resizing_a_terminal) を参考にして対処しました。

<!--more-->

## 最終結果

`.bashrc` に以下の内容を追加しました。

```bash
rsz () if [[ -t 0 ]]; then local escape r c prompt=$(printf '\e7\e[r\e[999;999H\e[6n\e8'); IFS='[;' read -sd R -p "$prompt" escape r c; stty cols $c rows $r; fi
rsz
```

`zsh` でも同じものが使える予定だったのですが、 `read -p` を使ってしまったので、共通で使えるものは、後述するように、たまに `^[[80;200R` のような表示が出てしまうことがありますが、以下になります。

```bash
rsz () if [[ -t 0 ]]; then local escape r c; printf '\e7\e[r\e[999;999H\e[6n\e8'; IFS='[;' read -sd R escape r c; stty cols $c rows $r; fi
```


## 参考

[Resizing a terminal](https://wiki.archlinux.org/title/working_with_the_serial_console#Resizing_a_terminal) や [ターミナルのサイズ変更](https://wiki.archlinux.jp/index.php/%E3%82%B7%E3%83%AA%E3%82%A2%E3%83%AB%E3%82%B3%E3%83%B3%E3%82%BD%E3%83%BC%E3%83%AB#%E3%82%BF%E3%83%BC%E3%83%9F%E3%83%8A%E3%83%AB%E3%81%AE%E3%82%B5%E3%82%A4%E3%82%BA%E5%A4%89%E6%9B%B4) の以下の実装を参考にしました。

```zsh
rsz() {
	if [[ -t 0 && $# -eq 0 ]];then
		local IFS='[;' escape geometry x y
		print -n '\e7\e[r\e[999;999H\e[6n\e8'
		read -sd R escape geometry
		x=${geometry##*;} y=${geometry%%;*}
		if [[ ${COLUMNS} -eq ${x} && ${LINES} -eq ${y} ]];then
			print "${TERM} ${x}x${y}"
		else
			print "${COLUMNS}x${LINES} -> ${x}x${y}"
			stty cols ${x} rows ${y}
		fi
	else
		[[ -n ${commands[repo-elephant]} ]] && repo-elephant || print 'Usage: rsz'  ## Easter egg here :)
	fi
}
```

Wiki の説明にあるように、 `xterm` パッケージをインストールしても良いなら、 `resize` コマンドを使う方が簡単です。

## 動作確認のために最低限の実装に変更

Easter egg などは不要で、 `if` での条件分岐も削って以下のような実装で確認しました。
zsh 依存をなくすため、 `print` も `printf` に変更しました。

```bash
rsz() {
	local IFS='[;' escape geometry x y
	printf '\e7\e[r\e[999;999H\e[6n\e8'
	read -sd R escape geometry
	x=${geometry##*;} y=${geometry%%;*}
	stty cols ${x} rows ${y}
}
```

## printf の内容

[対応制御シーケンス](https://ttssh2.osdn.jp/manual/4/ja/about/ctrlseq.html)を参考にして内容を読みとくと、以下のようになりました。

- `\e7` = `ESC 7` = カーソル位置を保存する
- `\e[r` = `CSI r` = DECSTBM = 上下マージン(スクロールリージョン)を設定する。引数を省略しているので 1 から画面下端。
- `\e[999;999H` = `CSI Ps1 ; Ps2 H` = CUP = カーソルを Ps1 行目の Ps2 桁目に移動する。(大きい値を指定することで右下に移動している。1000 以上のサイズの端末なら誤動作しそう。)
- `\e[6n` = `CSI Ps n` = DSR = 端末の状態を報告する。 Ps = 6 なので「カーソルの位置を報告する。(CPR)」で、応答: `CSI r ; c R`
- `\e8` = `ESC 8` = DECRC = 保存したカーソル位置を復元する (`ESC 7` で保存した元のカーソル位置に戻す)

「左右マージン(スクロールリージョン)を設定する。DECLRMM がセットされている時のみ有効。」という機能もあるようですが、滅多に設定されていないのに対応状況の調査が必要になって複雑になるからか、対応していないようです。

## read の引数修正

[bash の man](https://linuxjm.osdn.jp/html/GNU_bash/man1/bash.1.html) の説明によると、「[余った単語とそれらの間の区切り文字は、最後の name に代入されます。](https://linuxjm.osdn.jp/html/GNU_bash/man1/bash.1.html#:~:text=%E4%BD%99%E3%81%A3%E3%81%9F%E5%8D%98%E8%AA%9E%E3%81%A8%E3%81%9D%E3%82%8C%E3%82%89%E3%81%AE%E9%96%93%E3%81%AE%E5%8C%BA%E5%88%87%E3%82%8A%E6%96%87%E5%AD%97%E3%81%AF%E3%80%81%E6%9C%80%E5%BE%8C%E3%81%AE%20name%20%E3%81%AB%E4%BB%A3%E5%85%A5%E3%81%95%E3%82%8C%E3%81%BE%E3%81%99%E3%80%82)」ということなので、 `IFS` に `;` も入れているのに `read` で分割されていないのは引数に渡している変数名不足が原因とわかりました。
そこで、引数を増やして Parameter Expansion で取り出している処理を削りました。

```bash
rsz() {
	local IFS='[;' escape r c
	printf '\e7\e[r\e[999;999H\e[6n\e8'
	read -sd R escape r c
	stty cols $c rows $r
}
```

## IFS の位置変更

`IFS` の変更が必要なのは `read` だけなので、 `read` だけに影響する位置に変更しました。

```bash
rsz() {
	local escape r c
	printf '\e7\e[r\e[999;999H\e[6n\e8'
	IFS='[;' read -sd R escape r c
	stty cols $c rows $r
}
```

## if を再度追加

関数の本体は複合コマンド (Compound Commands) であれば `{ list; }` の代わりに `if list; then list; fi` でも良いので、 `{}` を `if ... fi` に置き換えました。
わかりにくいし、他の文を追加するときにバグが入りやすくなるので、普通は `{}` でくくる方が良いでしょう。

条件の `$# -eq 0` は不要だったので削りました。

そしてコピペしやすいように 1 行にしました。

```bash
rsz () if [[ -t 0 ]]; then local escape r c; printf '\e7\e[r\e[999;999H\e[6n\e8'; IFS='[;' read -sd R escape r c; stty cols $c rows $r; fi
```

## たまに応答が表示されてしまうのを修正

`printf` してから `read` の `-s` オプションで非表示にするまでの間に応答が来てしまうと、たまに `^[[80;200R` のような表示が出てしまうことがあります。
`printf` の前に `stty -echo` で止められるのですが、 `stty -g` を保存しておいて復元が必要になって複雑になってしまうので、避けました。
代わりに `bash` 依存の `read` の `-p` を使うことにしました。

```bash
rsz () if [[ -t 0 ]]; then local escape r c prompt=$(printf '\e7\e[r\e[999;999H\e[6n\e8'); IFS='[;' read -sd R -p "$prompt" escape r c; stty cols $c rows $r; fi
```

この状態で `.bashrc` に追加しました。

## まとめ

簡単な処理だと思っていたら、良い感じにしようとしたら意外と面倒でしたが、それなりにシンプルな感じにできました。
