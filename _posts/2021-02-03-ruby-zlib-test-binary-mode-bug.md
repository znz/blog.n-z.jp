---
layout: post
title: "ruby/zlibのテストが何もしていないのに失敗するようになった話"
date: 2021-02-03 18:00 +0900
comments: true
category: blog
tags: ruby
---
ruby/zlib のテストでの失敗がたまに起きていたのが、連続して発生するようになって、その原因が判明した話です。

<!--more-->

## 失敗の内容

たとえば <https://ci.appveyor.com/project/ruby/ruby/builds/37582820> のログによると

```text
  1) Error:
TestZlibGzipFile#test_gzip_reader_zcat:
Errno::EACCES: Permission denied @ apply2files - C:/Users/appveyor/AppData/Local/Temp/1/test_zlib_gzip_file_to_io20210203-1504-1h6r8z
    C:/projects/ruby/lib/tempfile.rb:368:in `unlink'
    C:/projects/ruby/lib/tempfile.rb:368:in `ensure in create'
    C:/projects/ruby/lib/tempfile.rb:367:in `create'
    C:/projects/ruby/test/zlib/test_zlib.rb:509:in `test_gzip_reader_zcat'
```

のような失敗が起きるようになっていました。

## バグの特定と修正

[なかださん](https://github.com/nobu)と[ささださん](https://github.com/ko1)が調査して、
[Open gzip file in binary mode](https://github.com/ruby/ruby/commit/d05a268adc402e0a9a5eac0ce291cfd34e68f29a)
のようにバイナリモードで開いていなかったから、ということがわかりました。
しかし、なぜ今まで動いていたのか、という疑問が残りました。

## バグの状況調査

とりあえず二人の再現スクリプトを元にして、ファイルを作成しました。

```ruby
require 'zlib'
f = File.open("/tmp/a.gz", "ab")
gz = Zlib::GzipWriter.new(f)
gz.print "foo"
gz.close
f.close
```

そしてファイルを眺めてみました。

```console
$ hexdump -C /tmp/a.gz
00000000  1f 8b 08 00 1b 5e 1a 60  00 03 4b cb cf 07 00 21  |.....^.`..K....!|
00000010  65 73 8c 03 00 00 00                              |es.....|
00000017
$ file /tmp/a.gz
/tmp/a.gz: gzip compressed data, last modified: Wed Feb  3 08:26:03 2021, from Unix, original size modulo 2^32 3
```

バイナリモードの影響を受ける文字として、まず改行コードが思い浮かびますが、この中にはなさそうです。
もう少し眺めつつ考えると `0x1A` を発見できました。

<http://openlab.ring.gr.jp/tsuneo/soft/tar32_2/tar32_2/sdk/TAR_FMT.TXT>
から GZIP 形式の部分を引用すると以下の通りです。

```text
3)GZIP形式
  GZIP形式は以下のような構造になっています。数値はリトル・エンディアン(大きい桁が左)であらわされます。
	1:マジックナンバー	2byte
		0x1f, 0x8b(\037, \213)
	2:圧縮法		1byte
		deflate:	8(0x08)
		他は予約
	3:フラグ		1byte
		bit0:	テキストファイル
		bit1:	マルチパートgzipファイルの2つめ以降
		bit2:	特別な領域が存在
		bit3:	ファイル名が存在
		bit4:	コメントが存在
		bit5:	ファイルは暗号化されている
	4:最終更新日時		4byte
		Unix形式。ファイルでない場合は圧縮した時刻。
	5:拡張フラグ		1byte
	6:ファイルを作成したOSの種類	1byte
		MSDOS:	0x00
		OS/2:	0x06
		Win32:	0x0b
		VAX/VMS:0x02
		AMIGA:	0x01
		ATARI:	0x05
		MACOS:	0x07
		Prime/PRIMOS: 0x0F
		TOPS20:	0x0a
		UNIX:	0x03
	7:オプションによるパート番号(2番目のパートが1である)	2byte又はなし
		フラグのbit1がセットされているときのみ存在する。
	8:オプションによる特別な領域の長さ			2byte又はなし
		フラグのbit2がセットされているときのみ存在する。
	9:オプションによる特別な領域				?byte又はなし
		「8:オプションによる特別な領域の長さ」だけ存在する。
	10:オプションによる元のファイル名			?byte又はなし
		フラグのbit3がセットされているときのみ存在する。
		NULL文字(0x00)で終わっている。
	11:オプションによる元のファイル名のコメント		?byte又はなし
		フラグのbit4がセットされているときのみ存在する。
		NULL文字(0x00)で終わっている。
	12:オプションによる暗号化ヘッダ				12byte又はなし
		フラグのbit5がセットされているときのみ存在する。
	13:圧縮データ						?byte
	14:32ビットCRC						4byte
	15:ファイルサイズ					4byte
		2^32以上のときは2^32で割ったあまり。
```

これと先程の hexdump を見比べると、 `0x1A` はタイムスタンプ部分に入っていることがわかって、
変化する周期が長いバイトが `0x1A` になったので、連続して失敗するようになったとわかりました。

## 発生頻度

[mameさん](https://github.com/mame)の計算によると、以下のような感じで3バイト目が問題の起きる値のままなのは明日未明までで、次回は8月16日からだったようです。
それまででも1バイト目や2バイト目には出てくる可能性はあります。

```ruby
[Time.now.to_i].pack("V")
#=> "\v_\x1A`"
Time.at([255,255,26,96].pack("C*").unpack1("V"))
#=> 2021-02-04 04:56:47 +0900
Time.at([0,0,26,97].pack("C*").unpack1("V"))
#=> 2021-08-16 15:04:48 +0900
```

## 感想

テスト実行時の時計に依存して失敗するテストのデバッグは難しいです。

今回の件とは関係ないですが、以前作っていたもので、日付の変わり目に関係する処理が日本時間の 0 時 〜 9 時の間だとテストが失敗するけど、テストを実行することがある業務時間は 9 時以降なので気がつかなかったということもありました。
