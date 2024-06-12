---
layout: post
title: "docs.ruby-lang.org/ja/ の生成方法を変えた"
date: 2024-06-12 18:00 +0900
comments: true
category: blog
tags: ruby
---
docs.ruby-lang.org の ja の HTML 生成に使っている ruby が
Debian GNU/Linux 11 (bullseye) の `/usr/bin/ruby` だと
`ruby 2.7.4p191 (2021-07-07 revision a21a3b7d23) [x86_64-linux-gnu]`
と古くて、 doctree にパターンマッチのドキュメントがマージされたときに
問題が起きていたので、
[rdoc のとき]({% post_url 2024-02-29-docs-ruby-lang-org-en %})
と同じように GitHub Actions での生成に変更しました。

<!--more-->

## 前の方法

[bc-setup-all](https://github.com/ruby/docs.ruby-lang.org/blob/bea61f164a044d0677f9568bf433d03c56dec9af/system/bc-setup-all)
で bitclust の `db-*` を生成、
[bc-static-all](https://github.com/ruby/docs.ruby-lang.org/blob/bea61f164a044d0677f9568bf433d03c56dec9af/system/bc-static-all)
で static html を生成、
[update-rurema-index](https://github.com/ruby/docs.ruby-lang.org/blob/bea61f164a044d0677f9568bf433d03c56dec9af/system/update-rurema-index)
で [rurema-search](https://github.com/ruby/rurema-search) のインデックスを更新、
という手順でした。

## 手元で作成環境を Docker 化

まず手元で bitclust と doctree から db と html を生成する部分を Docker 化しました。

生成された db と html を入れても `.git` は 140M ぐらいで
[GitHub のリポジトリサイズ制限](https://docs.github.com/ja/repositories/working-with-files/managing-large-files/about-large-files-on-github#repository-size-limits)
の「リポジトリは小さく保ち、理想としては 1GB 未満、および 5GB 未満にすることを強くお勧めします。」は満たせそうだったので、
生成したファイルもリポジトリに入れてしまうことにしました。

rurema-search のインデックス作成も Docker 化できて、
インデックスはバイナリで git 管理には向かなさそうで、毎回再生成すれば良さそうだったので、
リポジトリ管理にはしませんでした。

最終的には
[generated-documents](https://github.com/rurema/generated-documents)
として `docs.ruby-lang.org` で pull して使うことにしました。

## 古いドキュメントの保存

HTML ファイルは `ja/1.8.7` から残っていたので、
`generated-documents` に保存できたのですが、
`db-*` は EC2 を今の docs-2020 に移行したときに残していなかったので、
`db-2.4.0` 以降しか残っていませんでした。

今回の Docker 化の調査で知ったのですが、
rurema-search は `db-*` だけからインデックスを生成していました。

その結果、
<https://docs.ruby-lang.org/ja/search/>
は 2.4.0 からしかない、ということになっていました。

過去のドキュメントも検索結果に復活させたいという意欲があれば、
当時の ruby と bitclust と doctree を使って再生成すると良さそうです。

HTML についても Google Analytics の埋め込みなどをうまく分離して、
過去のバージョンについても再生成できると良さそうです。

## GitHub Actions で生成

`github.com/ruby` ではなく `github.com/rurema` に作ったので、
権限がなくて S3 へ置くことはできないということもあって、
リポジトリに置くことにしたので、
更新は
[生成して pull request を作成して自動マージする](https://github.com/rurema/generated-documents/blob/902da064105c1949907204d4bb5ca0ea40c83e17/.github/workflows/generate.yml)
という workflow にしました。

## docs 側の更新方法変更

[bc-setup-all](https://github.com/ruby/docs.ruby-lang.org/blob/c1f79e3a0ef9716a37e3c22064342a896814c4e0/system/bc-setup-all)
で generated-documents をとってきて `db-*` の symlink を作成するようにしました。

[bc-static-all](https://github.com/ruby/docs.ruby-lang.org/blob/c1f79e3a0ef9716a37e3c22064342a896814c4e0/system/bc-static-all)
では以前と同じように static html を `rsync` で反映するようにしました。

`update-rurema-index` は今まで通りです。

## 今後の予定

generated-documents に入れている bitclust で生成するファイルは埋め込まれているタグなどの関係で docs.ruby-lang.org 専用ですが、
直接 ssh で入れない人にも生成環境が見えやすくなって、何かあったときに助けてもらいやすくなったと思います。

docs.ruby-lang.org の環境軽量化は、HTML 生成部分はなんとかできましたが、
rurema-search は生成されるインデックスだけで 600M を越えていて、
heroku の slug の 500M 制限を越えるので、
heroku で動かすのは難しそうで、
静的ファイルのホスティング + Heroku への移行は無理そうでした。

```
$ du -sch groonga-database var
642M	groonga-database
48M	var
690M	total
```

現状の docs の EC2 インスタンスの内容は
<https://github.com/ruby/docs.ruby-lang.org>
にある ansible の playbook も現状と合わなくなっているので、
他に移行できないなら、
EC2 のインスタンスを作り直した方が良いのかもしれません。

## 最後に

RubyKaigi 2024 でるりま関連をまた頑張ろうと思っていたところで、
パターンマッチの問題で Docker 化の優先順位が上がって、
そちらの対応を優先して作業して、ほぼ完了しました。

残作業はまだまだたくさんありますが、手伝ってくれる人がいれば手伝ってもらいつつ、やっていきたいです。

## 残作業

- bitclust への型付けをしつつコードリーディングの続き
- kramdown への型付け (まだなければ)
- 開発環境の devcontainer 化 (bitclust 開発者向けと doctree 執筆者向け)
- bitclust に markdown 対応機能追加
- markdown 移行前に doctree の pull request 一掃
- doctree で markdown に一部書き換え
- doctree の書き換えでわかった bitclust で markdown 対応の問題点修正
- rurema-search の markdown 対応
- doctree で全面的に markdown 対応
- doctree の RDベース記法のドキュメント削除
- bitclust から RD 対応を削除

### その他のやりたいこと

- irb でのドキュメント表示対応
- ドキュメント内部での ruby.wasm での実行対応
- ドキュメント執筆補助ツール (bitclust の tools) の再整備

### docs.ruby-lang.org関連

- (済) rdoc 生成のコンテナ化
- 脆弱性のある古い js の対処(?) (古い jquery などが残っているかどうかなどの確認から)
- (済) ja html 生成のコンテナ化
- GA の削除? (共通 js ファイルにして docs.ruby-lang.org 以外だと空ファイルとかできると良さそう?)
- (済) 更新しない古いバージョンをアーカイブファイルでも保存・配布
- (済) 新しいバージョンも rurema-search で必要ならアーカイブでも配布
- 古いバージョンの `db-*` の再生成
- HTML 配信元を EC2 から S3 バックエンドか何かに移行(?)
- (途中まで済) rurema-search のコンテナ化かサーバーレス化か何か

### 直近

- (済) rurema-search で master が 3.4 のようにバージョンで出てきてリンク切れになる問題の対策
- <https://docs.ruby-lang.org/ja/> と <https://docs.ruby-lang.org/en/> のサポート終了バージョンの更新
