---
layout: post
title: "ferrum gemで手動ログインした後スクレイピングを試す"
date: 2022-07-30 10:30 +0900
comments: true
category: blog
tags: ruby
---
ruby-jp slack でログイン情報を持ちたくないので、ユーザーに手動でログインしてもらって、ログイン後にアプリでスクレイピングしたい、という質問があったので、headless じゃない browser を開いてログインしてもらって、cookie をコピーすればできそう、と思って試してみました。


<!--more-->

## 動作確認環境

- macOS Monterey 12.4
- ruby 3.0.3p157 (2021-11-24 revision 3fb7d2cadc) [arm64-darwin21]
- ferrum (0.11)
- Google Chrome 103.0.5060.134（Official Build） （arm64）

browser が表示される関係で手元の環境だけで試しましたが、OS にはあまり依存しないと思います。

## プログラム例

こんな感じで `headless: false` な browser を開いてログインしてもらって、headless browser に cookie をコピーして続ければできそうと思いました。
見えていてもいいなら `headless: false` な browser で続けても良さそうです。

```ruby
before_login_url = "http://192.168.xxx.1" # 無線ルータのログイン画面で試した
target_pattern = /;/

require "ferrum"
visible_browser = Ferrum::Browser.new headless: false
visible_browser.go_to before_login_url
begin
  sleep 1 # 適当に待つ
end until target_pattern =~ visible_browser.current_url

browser = Ferrum::Browser.new
visible_browser.cookies.all.each_value do |cookie|
  # browser.cookies.set(cookie) # unreleased (ferrum 0.11 does not supported)
  browser.cookies.set(**cookie.instance_variable_get(:@attributes).transform_keys(&:to_sym))
end
current_url = visible_browser.current_url
visible_browser.quit
visible_browser = nil
browser.go_to current_url

browser.screenshot(path: "screenshot.jpg")
browser.quit
```

## 待ち方

手動操作の待ちなので、 `sleep` による待ちの間隔は1秒という長さでもすぐ動いているように見えました。

今回試した画面でのログイン後の URL 見分け方で一番簡単そうだったのが URL に `;` が含まれるかどうかだったので、そういうチェックにしています。
ログイン後の固定 URL があるなら、それをチェックした方が確実そうです。

## cookies のコピー方法

https://github.com/rubycdp/ferrum#cookies には `browser.cookies.set(cookie)` で `Ferrum::Cookies::Cookie` がセットできると書いてあったのですが、
[ferrum 0.11 (March 11, 2021)](https://rubygems.org/gems/ferrum/versions/0.11) では対応していませんでした。

そのため、まだリリースされていない main ブランチでのやり方を参考にしてコピーするようにしました。

## browser.quit のタイミング

`visible_browser.quit` してから `browser.go_to visible_browser.current_url` という順番だと動かないので、閉じるタイミングはちょっと気をつける必要がありました。

## エラー処理

ログインせずに閉じられてしまった場合ぐらいは対応した方がいいのかなと思って試してみたら、
`Browser is dead or given window is closed (Ferrum::DeadBrowserError)`
で終了したので、とりあえず止まるならいいかと思いました。

## まとめ

ちょっと試したことしかなかった ferrum gem で cookies をコピーすればログイン情報を引き継げることを確認できました。
