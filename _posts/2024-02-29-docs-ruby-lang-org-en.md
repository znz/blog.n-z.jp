---
layout: post
title: "docs.ruby-lang.org/en/master/ の生成が止まっていたので生成方法を変えた"
date: 2024-02-29 12:50 +0900
comments: true
category: blog
tags: ruby
---
docs.ruby-lang.org で生成していた rdoc の HTML のうち、
master に対応するものがなぜか生成できなくなって、
色々試しても解決できなくて、他の環境での再現もできなくて原因不明だったので、
別の方法に変えて解決しました。

<!--more-->

## 前の方法

[rdoc-static-all](https://github.com/ruby/docs.ruby-lang.org/blob/bea61f164a044d0677f9568bf433d03c56dec9af/system/rdoc-static-all)
で
[Rakefile](https://github.com/ruby/docs.ruby-lang.org/blob/3aab1688dd96b9a2d3e27454a1ae4e596cfb0577/Rakefile)
を使って生成した HTML を rsync で反映していましたが、
BASERUBY に要求される ruby のバージョンが上がったあたりからなのか、
生成に失敗するようになって、
snap ruby を試したり、作業ディレクトリを消してクリーンな状態にして試したりしましたが、
結局エラーが変わるだけで解決しませんでした。

他の環境で同じように試しても、同じエラーがでないこともあって、他の方法を検討しました。

## GitHub Actions で生成

こういう定期作業は [ruby/actions](https://github.com/ruby/actions) を使うのが良さそうということで、
個人レポジトリである程度動作確認した後、
[Make HTML for docs.r-l.o/en/](https://github.com/ruby/actions/blob/d8f05dfe43e04aa24a2cdc85ea5093be54bcdfcf/.github/workflows/docs.yml)
を追加して、
<https://cache.ruby-lang.org/pub/ruby/doc/> に `ruby-docs-en-*.tar.xz` を置くようにしました。

GitHub Actions から docs.ruby-lang.org を直接操作するのは、
ssh で入れるようにして rsync などの操作をするにしても、
GitHub Actions の runner を設置するにしても、
管理が大変になってしまうので、
CDN 経由でファイルをやりとりするようにしました。

## docs 側の更新方法変更

[rdoc-static-all](https://github.com/ruby/docs.ruby-lang.org/blob/3aab1688dd96b9a2d3e27454a1ae4e596cfb0577/system/rdoc-static-all)
のように `ruby-docs-en-#{version}.tar.xz` をダウンロードして、
今まで通り `rsync` で置き換えるようにしました。

## 感想

2024-02-16(金)から更新が止まっていて、ちょっと試行錯誤したぐらいだと直らなくて、
先週は旅行などで忙しくて時間が取れなくて、
今週になって別案を考えて、
今日実行してみたら割とすんなりうまくいきました。

今回は `en` の 3.0 以降という現在メンテナンス対象のバージョンのみですが、
古いバージョンのファイル や `ja` も含めて `pub/ruby/doc/` に置いて、
docs のバックエンドの EC2 はもっと軽い感じにしたいのですが、
るりまサーチがあるので、GitHub Pages のような完全な static なホスティングにはできないし、
`ja` は今は「Global Site Tag (gtag.js) - Google Analytics」が入っているので、
それをどうにかしないと `pub/ruby/doc/` には置けなさそう、
という点が気になっています。
