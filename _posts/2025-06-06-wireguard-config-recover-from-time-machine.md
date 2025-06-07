---
layout: post
title: "突然消えてしまったWireGuardの設定をTime Machineバックアップから復元した"
date: 2025-06-06 19:25 +0900
comments: true
category: blog
tags: macos wireguard
---
手元の MacBook Pro を再起動すると WireGuard のトンネル設定が消えていて困ったので、
Time Machine バックアップから復元した話です。

<!--more-->

## 経緯

通知の消去が出ないパターンがおきていたり Launchpad での文字入力が検索に表示されなくなっていたり、たまに起きるなんか macOS が変な状態になっていたので、
手元の MacBook Pro を再起動したところ、なぜか WireGuard のトンネル設定が消えていました。

ログを確認すると、こんな感じで keychain から読めないというメッセージが続いた後、トンネルが消されていました。

    2025-06-05 08:41:43.572 [NET] App version: 1.0.16 (27)
    2025-06-05 08:41:43.572 [NET] Starting tunnel from the OS directly, rather than the app
    2025-06-05 08:41:43.635 [NET] Unable to open config from keychain: -25300
    2025-06-05 08:41:43.777 [NET] App version: 1.0.16 (27)
    2025-06-05 08:41:43.777 [NET] Starting tunnel from the OS directly, rather than the app
    2025-06-05 08:41:43.803 [NET] Unable to open config from keychain: -25300
    2025-06-05 08:41:44.808 [APP] App version: 1.0.16 (27)
    2025-06-05 08:41:45.119 [APP] Removing orphaned tunnel with non-verifying keychain entry: wg2022

`wg2022` は 2022 年に最初に設定した WireGuard のトンネルの名前です。

## 復旧

Peer の設定は他のマシンからコピーしてくれば復旧できるかもしれませんが、
PrivateKey は明示的なバックアップがないので困ったので、
復旧方法を調べてみると Keychain のバックアップから復元すれば良さそうとわかりました。

<https://www.aaron.cc/restoring-the-wireguard-configuration-from-a-backup/>
や
<https://maximerousseau.com/recovering-wireguard-config-mac/>
を参考にして、
`open ~/Library/Keychains`
で Keychains のフォルダを開いて、
画面全体の右上の Time Machine のアイコンから「Time Machineバックアップをブラウズ」で過去の `login.keychain-db` をコピーしてきて、
Finder で別途開いておいた `/tmp` にペーストして Finder から過去の `login.keychain-db` を開きました。

開いた「キーチェーンアクセス」の右上の検索の入力欄に「wireguard」と入れて検索しましたが、
数日前の「login.keychain-db」だと何もみつからなかったので、Time Machineバックアップを一気に年末年始ぐらいまでさかのぼってコピーしてきました。
すると「WireGuard Tunnel: wg2022」がみつかりました。

みつかった項目をダブルクリックか右クリックメニューから「情報を見る」で開いて、「パスワードを表示」のチェックを入れます。

ログインパスワードを2回入力すると「[Interface]」という最初の行だけ見えるので、「Command+A Command+C」で全体をコピーします。

WireGuard の「トンネルの管理」に戻って、左下の「+」から「設定が空のトンネルを追加...」でペーストして「名前」やオンデマンドを設定しなおして保存すればリカバリできました。

## その後

記事を書くために「キーチェーンアクセス」を確認すると、古いトンネルの項目も復活していて、何が起きたのかよくわかりませんでしたが、
項目が二重になってしまったので、今度同じことが起きたら Time Machine バックアップを漁らなくても古い項目の方から復旧できるのかもしれません。
