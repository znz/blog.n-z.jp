---
layout: post
title: "iTerm2のAutomatic Profile Switchingでリモート作業を区別する"
date: 2019-03-23 00:00 +0900
comments: true
category: blog
tags: macos osx iterm2
---
[iTerm2](https://iterm2.com/) には [Automatic Profile Switching](https://iterm2.com/documentation-automatic-profile-switching.html) という機能があり、ユーザーやホストなどによって自動で Profile を切り替えることができて、たとえば root の時は背景色を変えて注意を促す、ということができます。

日本語の情報<!-- https://qiita.com/yuku_t/items/a6f13ed6d4a039ee6a2f https://dev.classmethod.jp/etc/do-ssh-and-change-bg-color-iterm2/ -->では Shell Integration が必須なので現実的ではないという情報しかなかったのですが、英語だと [Triggers](https://iterm2.com/documentation-triggers.html) と組み合わせれば良いと書いてあったので、試してみました。

<!--more-->

## 動作確認バージョン

- macOS Mojave 10.14.3
- iTerm2 Build 3.2.7

## 確認用の Badge 設定

まず最初に Profile の General タブの Badge に

```
\(session.username)@\(session.hostname):\(session.path)
```

と設定して、 iTerm2 が認識しているユーザー名とホスト名とカレントディレクトリがわかるようにしました。

Badge は便利だと思えば残せばいいし、見にくくて邪魔だと思ったら、確認後に消せば良いと思います。

## Triggers 設定

Profile の Advanced タブの Triggers の Edit でダイアログを開いて、下の `+` を押して追加していきます。
間違えたり不要になったりしたら `-` で削除できます。

Regular Expression (正規表現) に

```
^(\w+)@([\w\-]+):([^ ]*) ?[$#] $
```

を設定して、 Action は `Report User & Host` を選び、 Parameters は `\1@\2` と設定します。

Instant (改行を待たずにパターンにマッチしたらすぐにトリガーを実行) にチェックも入れておきます。
Instant のチェックは以下同様です。

Instant のチェックは、プロンプトが表示される前に入力をした場合などに違いが出るので、実際にオンオフ両方で使ってみて好みの方にするのでも良いかもしれません。
正規表現の末尾の `$` を削って、行全体ではなく、行頭からの一致だけみるようにして Instant のチェックはオフにしておく、というのも良さそうです。

正規表現をコピーして Action は `Report Directory` にして Parameters は `\3` と設定します。

Automatic Profile Switching には不要ですが、さらに正規表現をコピーして `Prompt Detected` も設定しておくと便利かもしれません。

## Automatic Profile Switching 設定

Profile の一覧の下側の `Other Actions...` から `Duplicate Profile` で Profile を複製して、複製した方の Profile の Name を適当にわかりやすいものに変更して、 Advanced タブの下の方にある Automatic Profile Switching で `root@` という設定を追加します。

Badge を変更するなり、 Colors タブで別の Preset を選ぶなりして、切り替わったことをわかりやすくしておくと良いでしょう。

## 動作確認

docker を使って `docker run -it --rm ubuntu /bin/bash` で動作確認しています。

マッチするはずのパターンを `echo` して確かめることもできますが、 Shell Integration を入れているとすぐに戻ってしまうので、 `sleep` と組み合わせるなどの工夫が必要です。

## その他の Triggers 設定

### centos 対応

例えば centos にも対応するなら、正規表現として

```
^\[(\w+)@([\w\-]+) ([^ ]*)\][$#] $
```

を使って同様に設定すると対応できます。

`docker run -it --rm centos:7 /bin/bash` で動作確認しています。

### その他の Prompt Detected

Automatic Profile Switching には関係ないですが、

```
^\[\d+\] pry\([^ ]+\)> $
```

で `Prompt Detected` を設定するなど、普段使っている REPL のプロンプトも設定しておくと便利かもしれません。

## 設定変更反映

Triggers の設定を変更したら、
Profile の一覧の下側の `Other Actions...` から `Bulk Copy from Selected Profile...` で Advanced だけコピーして、 Automatic Profile Switching 設定を設定し直しています。

Triggers だけコピーは今のところはできないようなので、 Automatic Profile Switching で切り替える Profile は元の Profile とほぼ同じ設定にしておく、ということでしのいでいます。

## Triggers 設定例

今のところの Triggers の設定を例としてスクリーンショットで載せておきます。
`irb -r irb/completion --simple-prompt` 用の `^>> $` で `Prompt Detected` も入っています。

![Triggers 設定例]({{ "/assets/images/2019-03-23-triggers.png" | relative_url }})

## 参考サイト

[Using iTerm Automatic Profile Switching to Make Fewer Mistakes In Production](http://www.panozzaj.com/blog/2016/08/21/using-iterm2-to-make-fewer-mistakes-in-production/) を参考にしました。
Rails の起動時のバナーを使ってダミーのホスト名を設定して使う、という方法も紹介されているので、プロンプトから抜き出す以外の方法も考える時に参考になります。

## 色の選択

root は赤い背景色がよさそうと思って、 <https://iterm2colorschemes.com/> から Red Alert を選びました。
<https://github.com/mbadolato/iTerm2-Color-Schemes> を git clone して、 Profile の Colors タブの `Color Presets...` の `Import...` で  schemes の中の itermcolors ファイルを指定すれば選べるようになります。
試してみて、やっぱり使わないなと思ったら、 `Color Presets...` の `Delete Preset...` から消せます。
