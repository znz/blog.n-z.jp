---
layout: post
title: "第 134 回 関西 Debian 勉強会に参加しました"
date: 2018-04-22 14:00 +0900
---
[第 134 回 関西 Debian 勉強会](https://wiki.debian.org/KansaiDebianMeeting/20180422) に参加しました。
パッケージビルドの話でした。

<!--more-->

## 会場

港区民センターでした。

## オープニングや自己紹介など

- 事前課題 ([sbuild](https://wiki.debian.org/sbuild), [LXC](https://wiki.debian.org/LXC))
- 台湾の DebConf18 とか

## 事前準備

- git-buildpackage
- sbuild
- lintian piuparts
- autopkgtest debci

## モダンなパッケージ作成環境構築について

- [ruby-fastimage requires internet access during the build](https://bugs.debian.org/895610) をライブで修正してアップロード (予定)
- alioth (アリオス?) (fusionforge) から salsa (サルサ) (gitlab) になった
- git-buildpackage の話
- ブランチ
  - master ブランチが debian パッケージ管理
  - upstream が upstream そのまま
  - prinstine-tar はバイナリー差分 (タイムスタンプや圧縮率の違いなどによる差を吸収するため)
  - git diff upstream master は debian ディレクトリだけがでてくる (はず)
- tmux で罫線を ASCII 文字にするパッチをあてている
- gbp buildpackage コマンド オプションはお好みで
- debian/patches は quilt で管理されている
  - series ファイルにパッチを当てる順番でファイル名が書いてある
  - パッチは -p1 であたるようなものなら良い
  - gbp pq import でパッチがあたったブランチ pactch-queue/master ができる
  - upstream の変更でうまくあたらなかった場合は頑張りましょう
  - git checkout master で戻って gbp pq export でパッチが更新される
  - 作業が済んだら pactch-queue/master ブランチは消して良い
  - コミットメッセージの末尾に「Gbp-pq: Name ファイル名」でファイル名が入っている
- [Debian パッケージングチュートリアル](https://www.debian.org/doc/manuals/packaging-tutorial/packaging-tutorial.ja.pdf)
  - 今は version 0.21 2017-08-15
  - [packaging-tutorial パッケージ](https://packages.debian.org/packaging-tutorial) もあって複数言語の PDF が入っている
- `gbp buildpackage --git-ignore-new --git-builder='debuild -rfakeroot -i.git -I.git -sa -k$GPG_KEY_ID'` を `git-b` という alias にしている
- `ARCH=amd64` `DIST=unstable` or `DIST=stable` or `DIST=testing` で `gbp buildpackage --git-ignore-new --git-builder="sbuild --arch=${ARCH} -d ${DIST}"` を `git-bs` という function にしている
  - `DIST=stretch` などは置き換える必要あり
- sbuild: パッケージのクリーンルームビルド環境
  - 同様のソフトウェア: pbuilder, cowbuilder, qemubuilder
  - whalebuilder というのもあるらしい
  - `/etc/schroot/sbuild` にも設定がある
  - overlay fs にして `/dev/shm` を使うと速いが libreoffice のようなディスクを10G以上も使うようなものをビルドすると大変なことになる
  - sbuild-debian-developer-setup というのもあるらしい
  - sbuild-update でベース環境を更新
  - `~/.sbuildrc` に設定を書く (perl)
  - lintian や piuparts や autopkgtest も動かすことができる
  - [パッケージ作成環境](https://uwabami.github.io/cc-env/DebianPackaging.html) 参照
- HOME が存在しないとか LANG が親の環境を引き継ぐが locale ファイルがないのでこけることがある
- piuparts はコマンドラインオプションの順番が違うと動作が変わったりとかあるらしい
- rdepends の autopkgtest
  - apt-cache rdepends で依存しているパッケージも確認してテストしたい
  - sbuild は apt の cache を bind マウントで共有していると同時実行で piuparts で問題が起きたので debci を使った
  - debci の詳細は <https://ci.debian.net/> 参照
  - [パッケージ作成環境](https://uwabami.github.io/cc-env/DebianPackaging.html) 参照
  - 重要な部分は `autopkgtest --user debci $1 -- lxc --sudo autopkgtest-$ad`
- ruby-fastimage のライブバグ修正
  - upstream で追加されたネットワークが必要なテストをコメントアウト
  - gbp dch とか
  - git tag とか git push --all とか git push --tags とか
  - dput changesファイル
    - 今は dput-ng
    - upload 後に tweet する hook を入れている
    - <https://twitter.com/uwabami/status/987957533665935362>
- ビルド時にネットワークにつないではいけないが、テスト時にも同じ制限になっているのはビルド時とテスト時を区別できていないから
  - 分けた方が良いのでは、という話はある
  - loopback には接続しても良い

## 感想

実際の日常的なパッケージ作成がどんな感じか見ることができたので、参考になりました。
