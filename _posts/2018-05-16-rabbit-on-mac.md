---
layout: post
title: "Rabbit が macOS の Homebrew で動かない問題の回避策"
date: 2018-05-16 22:36 +0900
comments: true
category: blog
tags: rabbit
---
[Rabbit](https://rabbit-shocker.org/ja/) が macOS の Homebrew の poppler が原因で動かない問題の回避策を実行しました。

<!--more-->

## 確認バージョン

- macOS High Sierra 10.13.4
- ruby 2.5.1
- rabbit 2.2.1
- poppler 0.64.0 (2018-05-22 追記: 0.65.0 でも同様)

## 回避策

[oss-gate/general](https://gitter.im/oss-gate/general?at=5acfc7186d7e07082bea6a78) で教えてもらった
[Formula/poppler.rb](https://github.com/ruby-gnome2/ruby-gnome2/issues/1124#issuecomment-359323077) のパッチを使いました。

## 適用方法

`brew edit poppler` でパッチの内容を適用します。
具体的には `+` で始まる行が追加行なので、該当する部分に (行頭の `+` を削って) 追加します。

そして bottle ではなくパッチを当てたビルド処理が使われるように `--build-from-source` (or `-s`) つきで再インストールします。

最後に brew の更新でひっかからないように変更を戻しておきます。

```console
$ brew edit poppler
$ brew reinstall poppler --build-from-source
$ (cd /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula && git checkout poppler.rb)
```

## まとめ

色々とすんなり対処が進まない原因があるようですが、根本的な対処がされるまでは、自前でパッチをあてれば macOS でも rabbit が動くようになったという話を
poppler が 0.64.0\_1 に上がって [`brew upgrade --cleanup`]({% post_url 2017-04-27-homebrew-upgrade-cleanup %}) 直後だと動かなくなったタイミングで記事にしてみました。
