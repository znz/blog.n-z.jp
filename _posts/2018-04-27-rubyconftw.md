---
layout: post
title: "Ruby X Elixir Conf Taiwan 2018の1日目に参加しました"
date: 2018-04-27 21:13 +0800
comments: true
category: blog
tags: event ruby taiwan
---
[Ruby X Elixir Conf Taiwan 2018](https://2018.rubyconf.tw/) の1日目に参加しました。
メインの部屋に電源がなくて、電源に不安があったので、メモはとっていません。

<!--more-->

## 感想

基本的にある程度知っている話のところを選んだので、英語を聞くのはそんなに大変ではありませんでした。
中国語のセッションは Program のページの下に同時通訳へのリンクがあって、ネットワーク経由で同時通訳が聞けるようになっていましたが、タイミングがずれるのと中国語で話している方も単語レベルでは英語そのままと同じでわかるものもあるので、混乱してしまって難しかったです。

LT で中国語のものがあって、スライドも中国語だけというページがあって、なかなか難しかったです。
(日本人なら漢字である程度意味は推測できるものがあるにはあるのですが。)

## 色々

[git.ruby-lang.org](https://git.ruby-lang.org/) と [snap パッケージ](https://github.com/ruby/snap.ruby)の話は公開の場所で正式に出たのは初めてなのかもと思いました。

github.com ではなく、独自なのは、色々理由があって大変そうです。

snap パッケージは candidate を試してみて、対応してもらったりしているので、ちゃんと実用段階までいけるのか気になっています。
(pull request の一部にあった [confinement: classic](https://github.com/ruby/snap.ruby/blob/255b209afac72636b395679acd2932247d731781/snap/snapcraft.yaml#L9) がないと `snap run ruby.ruby -e 'File.write("testfile","test")'` さえできないとか、 gem list が空だった (Rev 34 で修正済み) とか)

rdoc の話の後で [Convert links to local files in markdown](https://github.com/ruby/rdoc/issues/618) の話をつついて、スライドの準備などで忙しかったから rdoc の方に手が回っていなかったけど、次のリリースでは対応してもらえるという話ができてよかったです。

[Method JIT Compiler for MRI by Takashi Kokubun](https://speakerdeck.com/k0kubun/method-jit-compiler-for-mri) の話は実際の変更部分も確認しながらみるとわかりやすいのかもしれない、と思いました。

LT はメモをとらなかったので、思い出す手がかりが全くなさそうな感じです。

## Official Party

RubyKaigi などの時と同じく、特に開始の乾杯などはなく始まっていました。
タイムテーブルでは終了時間は書いていませんでした。
基本的に知っている人とゆっくり話をしていて、最終的に笹田さんと matz が帰るタイミングで一緒に出て帰りました。
