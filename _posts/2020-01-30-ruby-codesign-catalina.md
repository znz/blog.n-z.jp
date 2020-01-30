---
layout: post
title: "macOS Catalina で codesign してネットワーク通信時のダイアログを抑制する"
date: 2020-01-30 19:00 +0900
comments: true
category: blog
tags: ruby
---
[macOS Sierra で codesign してネットワーク通信時のダイアログを抑制する術](https://www.hsbt.org/diary/20170201.html) を参考にして
同様にやってみたら Mojave でも Catalina でも同様だったので、全体をスクリーンショットを取りつつまとめてみました。

<!--more-->

[Mojave 版はこちら]({% post_url 2020-01-30-ruby-codesign-mojave %})です。

## 動作確認環境

- macOS Catalina 10.15.3

## 証明書作成

キーチェーンアクセスから「証明書を作成」を開きます。

![01]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_01.png" | relative_url }})

適当な名前を入力して、証明書のタイプを「コード署名」にします。
コード署名専用にするために「デフォルトを無効化」にチェックをいれておきます。
ここで入力した名前は後で `RUBY_CODESIGN` 環境変数に設定する名前になります。

![02]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_02.png" | relative_url }})

注意書きが出てくるので「続ける」をクリックします。

![03]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_03.png" | relative_url }})

有効期間がデフォルトでは 365 日なので、例えば 3650 などに伸ばしても良いようです。
medium の記事に書いてあるように最大は 7300 のようで、 Mojave でも同じでした。

![04]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_04.png" | relative_url }})

次の画面でメールアドレスが入っていても、消してしまっても構いません。
他はデフォルトのまま証明書の保管場所まで進んでいきます。

![05]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_05.png" | relative_url }})
![06]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_06.png" | relative_url }})
![07]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_07.png" | relative_url }})
![08]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_08.png" | relative_url }})
![09]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_09.png" | relative_url }})
![10]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_10.png" | relative_url }})

証明書の保管場所を「システム」に変更します。
作成をクリックすると、後ろに仕上げ中と出た状態で認証を要求されます。

![11]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_11.png" | relative_url }})

認証が通ると証明書が作成されます。

![12]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_12.png" | relative_url }})

完了を押すとまた認証を要求されます。

![13]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_13.png" | relative_url }})

システムキーチェーンの証明書に入っているのを確認して、「情報を見る」を開きます。

![14]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_14.png" | relative_url }})

「信頼」を開いて「コード署名」を「常に信頼」にします。
閉じる時に Touch ID で変更を許可します。

![15]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_15.png" | relative_url }})

証明書の横の三角形でツリーを開いて、下にある秘密鍵の「情報を見る」を開きます。

![16]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_16.png" | relative_url }})

「アクセス制御」で許可します。
閉じる時に Touch ID で許可しても、なぜかさらにパスワードを要求されるようです。

![17]({{ "/assets/images/2020-01-30/catalina/ruby_codesign_17.png" | relative_url }})

最後のアクセス制御はできれば ruby のビルドプロセスからのみにしたいところですが、
同様のコマンドを実行すれば使えてしまうので、意味のある制限は難しそうです。

## シェル側の設定

`.bashrc` に `export RUBY_CODESIGN=ruby-codesign-2020` を追加するなどの方法で環境変数を設定します。

`rm miniruby; make miniruby` などのビルド時に認証のダイアログが出なくて、
テスト実行中にネットワークの許可も出なければ設定完了です。
