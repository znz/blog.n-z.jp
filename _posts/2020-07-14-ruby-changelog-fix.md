---
layout: post
title: "rubyのChangeLogとnotes log-fix"
date: 2020-07-14 22:45 +0900
comments: true
category: blog
tags: ruby
---
現在の ruby では `ChangeLog` ファイルはバージョン管理対象には入れず、
tarball 生成時に `make ChangeLog` (相当) で作成するようになっています。
その時に[git-notes](https://git-scm.com/docs/git-notes)を使って多少の修正が
できる仕組みが入っています。

<!--more-->

## ChangeLog 生成部分

[`git log --format=medium --notes=commits --notes=log-fix --topo-order --no-merges --date=iso-local` のような感じで notes 込みで `git log` を参照](https://github.com/ruby/ruby/blob/e60cd14d85b35c9e60485e640c08eebf539c1cfc/tool/lib/vcs.rb#L565)して、
`ChangeLog` を生成しています。

このとき、 `log-fix` に

```
31s/fileter/filter/
33s/infomation/information/
```

のように `行番号s/置換前/置換後/` と書いておけば置換が実行されます。

## log-fix への commit

`make ChangeLog` から typo などをみつけたなら、
その上の `commit 8655c2e69041cc812d30c2e951a8ac9ea7a60c47` の行をみたり、
コミットログをみつけてみつけたりしたら、
`git show 8655c2e69041cc812d30c2e951a8ac9ea7a60c47` などで対象のコミットかどうか確認します。

対象のコミットが確認できたら、たとえば
`git notes --ref=log-fix edit 8655c2e69041cc812d30c2e951a8ac9ea7a60c47`
で置換を記入します。

## 変更確認

`make ChangeLog` で反映されているのを確認します。

手元だけの変更があるときは、以下のように `git fetch` で `[rejected]` と出るのが正常です。

```
% make ChangeLog
Generating ChangeLog
From git.ruby-lang.org:ruby
 ! [rejected]              refs/notes/log-fix -> refs/notes/log-fix  (non-fast-forward)
```

`make ChangeLog` で反映されているのを確認して、
うまくいっていなかったら、
`git notes --ref=log-fix edit 8655c2e69041cc812d30c2e951a8ac9ea7a60c47`
で置換を修正します。

## commit の squash

このまま push しても問題はないのですが、
試行錯誤の途中は不要なので、
最終結果だけ残します。

慣れないブランチで壊してしまうと面倒なので、
ここではシンプルにコミットし直しで squash します。

最終結果だけ別の場所にコピーして残しておいて、

```
git fetch origin +refs/notes/log-fix:refs/notes/log-fix
```

でいったん `refs/notes/log-fix` ブランチを元に戻します。
`+` をつけているのは force push のように現在の変更を無視して上書きするという意味です。

`git notes --ref=log-fix edit 8655c2e69041cc812d30c2e951a8ac9ea7a60c47`
で最終的な置換を設定し直して、
また `make ChangeLog` で確認します。

## git push

最後に `git push` して完了です。

```
% git push origin refs/notes/log-fix:refs/notes/log-fix
Enumerating objects: 14, done.
Counting objects: 100% (14/14), done.
Delta compression using up to 8 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (4/4), 401 bytes | 401.00 KiB/s, done.
Total 4 (delta 1), reused 0 (delta 0), pack-reused 0
remote: To git@github.com:ruby/ruby.git
remote:    550d488..7457a63  7457a630f3a6fc08d2ada667349f06fe91156961 -> refs/notes/log-fix
To git.ruby-lang.org:ruby.git
   550d488713..7457a630f3  refs/notes/log-fix -> refs/notes/log-fix
```

## まとめ

ruby の `ChangeLog` 生成に入っている log-fix の仕組みを紹介しました。

git-notes は一時期 GitHub の Web 上でも表示されていたのに、
表示されなくなってしまったので、
使いどころが難しそうですが、
ruby では他に pull request をマージしたときに元の pull request の URL を記録するのにも使っていたりします。

特殊なブランチなので、
pull request などを受け付けるのも難しそうなので、
コミッター以外からの contribution を受け付けたいと思ったら、
どうすればいいのかはよくわかりませんでした。
