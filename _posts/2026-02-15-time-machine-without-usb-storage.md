---
layout: post
title: "外部ドライブなしでTime Machineバックアップを設定する"
date: 2026-02-15 23:00 +0900
comments: true
category: blog
tags: ruby macos
---
macOS の Time Machine バックアップはネットワークストレージだとバックアップも復元も遅いという問題があったり、
外部ドライブ (USB HDD) だと接続が切れることがあるので MacBook Pro を物理的に動かしにくくなったりする問題があったりして、
他の手段を検討した結果、ローカルに sparse bundle を作成して使う方法があるとわかったので、設定してみました。

<!--more-->

## 確認環境

- MacBook Pro 14 インチ, 11月 2024
- macOS Tahoe 26.3

## sparse bundle 作成

[Time Machine With Wasabi via a Mountable Drive and Rclone](https://docs.wasabi.com/docs/how-to-back-up-macos-using-time-machine-to-a-mountable-drive-and-sync-to-wasabi-via-rclone)
や
[Time Machine With Wasabi via Cyberduck](https://docs.wasabi.com/docs/how-to-back-up-macos-using-time-machine-to-cyberduck)
を参考にしました。

まず容量と暗号化するかどうか決めて以下のように作成します。
暗号化する場合の違いは後で説明します。

```bash
hdiutil create -size 500g -type SPARSEBUNDLE -fs HFS+J -volname "TimeMachineDisk" ~/TimeMachineDisk.sparsebundle
```

- `-size 500g` はマウント後の `df -h` で確認すると 500Gi になっています。
- `-type SPARSEBUNDLE` は sparse bundle を明示していますが、拡張子があれば省略可能と hdiutil の manpage に書いてありました。
- `-fs HFS+J` は hdiutil の manpage をみてもはっきりとした説明はなかったのですが、ジャーナリングの HFS+ だと思います。
- `-volname` は `/Volumes` の中に出てくるディレクトリ名になったり、Finder で見える名前になったりしていました。

## バックアップ設定

フルディスクアクセス権限が必要な操作があったはずなので、普段使いの端末ソフトに権限をつけたくないなら、
他の端末ソフトを用意するなどの準備が必要です。

以下のようにバックアップ設定します。

```bash
tmutil addexclusion ~/TimeMachineDisk.sparsebundle
hdiutil attach ~/TimeMachineDisk.sparsebundle
sudo tmutil setdestination /Volumes/TimeMachineDisk
tmutil destinationinfo
```

`/Volumes/TimeMachineDisk` は自動で Time Machine バックアップから除外されますが、
`TimeMachineDisk.sparsebundle` 自体は除外されなさそうなので、
`tmutil addexclusion` で明示的に除外属性をつけておきます。

`hdiutil attach` でマウントした後、
`sudo tmutil setdestination` で Time Machine バックアップ先に設定します。
(追加する場合は `tmutil setdestination -a` です。)

最後に `tmutil destinationinfo` で確認しています。

## バックアップ作成

GUI からスタートするか、コマンドで以下のような感じでバックアップ開始します。

```bash
tmutil startbackup --auto --block
```

## バックアップ設定削除

Time Machine の設定で確認すると暗号化されていなかったので、
一度削除して作りなおしました。

Time Machine のバックアップ先からは `tmutil removedestination` でも削除できますが、GUI から削除しました。

eject して sparse bundle も削除すれば元通りです。

```bash
hdiutil eject /Volumes/TimeMachineDisk
rm -rf ~/TimeMachineDisk.sparsebundle
```

## 暗号化ありで sparse bundle 作成

まず、
[Mac で Google Drive 等への暗号化バックアップを行う方法 - WebOS Goodies](http://webos-goodies.jp/archives/use_google_drive_as_encrypted_backup_solution_on_mac.html)
を参考にして暗号化用の証明書を作成しました。

まず、「キーチェーンアクセス」アプリを開きます。「パスワード」アプリとの選択肢が出てきても「キーチェーンアクセス」を開きます。
メニューの「キーチェーンアクセス」の「証明書アシスタント」の「証明書を作成…」で

- 名前: CloudBackup
- 固有名のタイプ: 自己署名ルート のまま
- 証明書のタイプ: S/MIME のまま

で証明書を作成しました。

作成された証明書は「デフォルトキーチェーン」の「iCloud」ではなく「ログイン」の方に入っているので、「種類」が「証明書」の行をデスクトップにドラッグアンドドロップで保存します。

以下のように保存した証明書を `-certificate` に指定して sparse bundle を作成します。

```bash
hdiutil create -size 500g -type SPARSEBUNDLE -fs HFS+J -volname "TimeMachineDisk" -encryption AES-256 -certificate ~/Desktop/CloudBackup.cer ~/TimeMachineDisk.sparsebundle
```

hdiutil の manpage によると `-encryption` は `AES-128` か `AES-256` しか指定できないので、
`AES-256` にしておけば良さそうです。

## 証明書のバックアップ

「種類」が「証明書」の行を右クリックなどでコンテキストメニューを開いて、「"CloudBackup"を書き出す…」から「個人情報交換(.p12)」で保存します。
名前は「CloudBackup」にして「CloudBackup.p12」として保存しました。
そのとき、秘密鍵を保護するパスワードとその確認、キーチェーンのパスワード(ログインパスワード) を要求されました。

sparse bundle のマウントに必要になるので、「CloudBackup.p12」は別途安全な場所に保管しておきます。

旧 MacBook Pro がまだあるので、そちらに CloudBackup.p12 も持っていって sparse bundle が開けることを確認しています。
(秘密鍵の行から書き出したファイルを持っていっても sparse bundle を開けませんでした。)

再確認できていませんが、インポートはキーチェーンアクセスへのドロップではできなくて、p12 ファイルを開いて読み込みした気がします。

## バックアップ設定

暗号化なしと同様にバックアップ設定します。
`hdiutil attach` でキーチェーンのパスワード (ログインパスワード) を要求されました。

```bash
tmutil addexclusion ~/TimeMachineDisk.sparsebundle
hdiutil attach ~/TimeMachineDisk.sparsebundle
sudo tmutil setdestination /Volumes/TimeMachineDisk
tmutil destinationinfo
```

Time Machine の設定で「空き 536.08 GB、暗号化」となっていて「暗号化」がついているのが確認できました。

## 除外設定

以下のように `tmutil addexclusion` で追加するか、
GUI で Time Machine 設定のオプションから除外設定を追加します。

```bash
tmutil addexclusion ~/.colima
tmutil addexclusion ~/.config/colima
tmutil addexclusion ~/.lima
tmutil addexclusion ~/.pcloud
```

`tmutil addexclusion` は拡張属性の設定なので、
GUI の設定と同期していませんが、
`tmutil addexclusion -p` が GUI の設定と同期しているようなので、
フルディスクアクセス権限があれば `-p` ありの方が便利そうです。

他には
[Biscuitの環境を他のパソコンに移す方法](https://note.com/biscuit_browser/n/n4e51af034f90)
で Chromium ベースのアプリ全般で cache とつくディレクトリは消しても大丈夫そうかなと思ったので、
以下のように除外設定を追加しています。
(以下にない他の Chromium ベースのアプリも含めて設定しています。)

```bash
find ~/Library/Application\ Support/biscuit -iname '*cache*' -print0 -prune | xargs -0 --verbose tmutil addexclusion
find ~/Library/Application\ Support/Google -iname '*cache*' -print0 -prune | xargs -0 --verbose tmutil addexclusion
```

他にも `du -sh .??* * | sort -h` などでみつけた容量の大きいバックアップが不要そうなものは除外しました。

## sparse bundle のバックアップ

マウント確認のために rsync で旧 MacBook Pro に転送してみたり、
pCloud Drive に入れて戻して実行パーミッションなどが消えても大丈夫か試してみたりしました。

大丈夫そうなので、今後は rclone か何かで定期的にバックアップするようにしようと思っています。

## まとめ

ローカルのみで Time Machine バックアップを有効にできることが確認できました。

外部へバックアップしなくても、Time Machine バックアップをブラウズで履歴が見えるようになるだけでも便利そうなので、
外部ディスクやクラウドストレージを用意できない環境でも試してみる価値がありそうだと思いました。
