---
layout: post
title: "Debian GNU/Linux 12 (bookworm)のカーネル更新でシステムがフリーズしていた"
date: 2026-11-17 10:00 +0900
comments: true
category: blog
tags: debian linux
---
Debian GNU/Linux 12 (bookworm) の環境で昨日のカーネル更新後、再起動からしばらくして割り込み不能で止まるプロセスが多発する、という現象でほぼ止まってしまう現象が発生するようになりました。
[#1154101](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1154101) が原因だったらしく、今朝のカーネルに更新できれば解決しました。

<!--more-->

## 環境

- さくらのVPS、ConoHa VPS
- Debian GNU/Linux 12 (bookworm)
- linux-image-6.1.0-54-amd64 は正常
- linux-image-6.1.0-55-amd64 で発生
- linux-image-6.1.0-56-amd64 で解決

## 原因

先に原因を書いておきます。

`/usr/share/doc/linux-image-amd64/changelog.gz` によると
「ext4: fix NULL folio dereference in mballoc (Closes: [#1154101](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1154101))」
が原因だったようで、
ext4 を使っている環境に影響があったようです。

## 現象

最初は、いつの間にか VPS で動かしている [nadoka](https://github.com/nadoka/nadoka) や `zabbix-agent2` の反応がなくなっていることに気付きました。
最初は外部からのリクエストで DoS がおきているのかと思って、今は使っていなくてアーカイブ的に残していた `trac` や `mod_svn` を止めたり `apache2` を止めたりしましたが効果がなく、
反応がなくなって VPS のコントロールパネルから強制再起動を何度かやっていました。

`ssh` で入って `top` をみていると PID 1 の `systemd` まで D (割り込み不能) で止まっていて、
`systemctl` での操作もできない状態になっていました。

`inspircd` は問題なく動いていましたが、原因がわかってから考えると、動作中にディスク I/O がないものは影響がなかったようです。

色々試していても解決しないまま夜になってしまったので、諦めて `top` を開いておいたまま寝ました。

## 原因判明

今朝になって確認してみると、やはり止まっていて、ふとカーネルの問題かもしれないと気付いて、
`/var/log/apt/history.log` を確認すると、問題発生の時間の前にカーネルの更新がありました。

そこで `bugs.debian.org/linux-image-6.1.0-55-amd64` を開いてみましたが、
無関係な [#1154123](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1154123) しかなかったのですが、
そこのコメントで `linux-image-6.1.0.56-amd64` がでているとわかったので更新することにしました。

更新前に `apt-listchanges` で出てくる changelog で
「ext4: fix NULL folio dereference in mballoc (Closes: [#1154101](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1154101))」
があったので、解決しそうだと思いました。

## 更新方法

更新の書き込み中に止まると復旧困難な壊れ方になってしまうので、
VPS のコントロールパネルのシリアルコンソールに接続した状態で強制再起動して、
GRUB のメニューから `Advanced options for Debian GNU/Linux` を選んで、その中の `(recovery mode)` がついていない方の `Debian GNU/Linux, with Linux 6.1.0-54-amd64` を選んで起動しました。

その状態でいつものように `sudo apt update` と `sudo apt full-upgrade -V` と `sudo apt autoremove --purge` をして再起動しました。

GRUB のメニューからの古いカーネルでの起動は、まず さくらのVPS でシリアルコンソールでうまくいって、ConoHa VPS の方でも同じくシリアルコンソールでうまくいきました。

## まとめ

完全に止まるわけではなく、問題の発生も再起動してしばらくしてから、という時間差があったので原因の特定に時間がかかりましたが、
自分が完全に管理している環境では解決できました。

root 権限はあっても、自分ではコントロールパネルやコンソールに入れない環境はこの記事を伝えて対応してもらう予定です。
