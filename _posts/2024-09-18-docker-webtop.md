---
layout: post
title: "docker-webtop を使って VPS 上でブラウザーを動かす"
date: 2024-09-18 18:00 +0900
comments: true
category: blog
tags: linux webtop
---
[linuxserver/docker-webtop](https://github.com/linuxserver/docker-webtop)
を使って VPS 上でブラウザーを開きっぱなしにする環境ができたので、そのメモです。

<!--more-->

## やりたかったこと

VPS 上でブラウザーを動かして、Cookie Clicker のように開きっぱなしにして放置しておくと良いものに使いたい、と思っていました。

## 失敗案

`libvirt` で VNC を有効にして WireGuard 経由で接続するという案もあって、
環境構築はうまくいったのですが、
ConoHa VPS の環境で KVM が有効にできなくて遅すぎて実用になりませんでした。

方法としては `virsh edit` で `<video>` の上に以下のように追記するか、
`virt-xml $name --add-device --graphics "vnc,port=5900,listen=$(ip -br addr show dev wg0 | awk '{sub("/.*","");print $3}'),keymap=ja,passwd=1234"`
のように `virt-xml` で追加すればうまくいきました。

```xml
  <graphics type='vnc' port='5900' autoport='no' listen='2001:db8:a987:6543::c0' keymap='ja' passwd='1234'>
    <listen type='address' address='2001:db8:a987:6543::c0'/>
  </graphics>
```

変更しなくても動くかもしれませんが、なんとなく遅そうな気がしたので、
`<model type='cirrus' vram='16384' heads='1' primary='yes'/>`
は適当に
`<model type='virtio' vram='65536' heads='1' primary='yes'/>`
に変更しました。
`qxl` は指定する属性が違っているようで単純な置き換えは難しそうだったので、
`virtio` を試しました。

前述のように KVM が使えなくて遅すぎたので、この変更の影響がどのくらいあったのかはわかりませんでした。

## webtop とは?

[GUIと日本語環境が使えるお手軽Docker環境の使い方](https://zenn.dev/mkj/articles/292a70b4f4e5e8)
で GUI 環境を Docker で簡単に使う方法として紹介されていました。

[linuxserver/docker-webtop: Ubuntu, Alpine, Arch, and Fedora based Webtop images, Linux in a web browser supporting popular desktop environments.](https://github.com/linuxserver/docker-webtop)
を見るとわかるように、いくつかのディストリビューションとデスクトップ環境が用意されています。

その中で KasmVNC のサーバーも一緒に動いていて、それをブラウザーで開いてリモートから使える、という仕組みになっているようです。

検索するときに webtop だけだと他のものもひっかかるので、「docker webtop」や「linuxserver webtop」で検索すると良さそうです。

## 最終的な compose.yaml の例

最終的にはこのような `compose.yaml` で動かしています。
初回起動の処理は時間がかかるのと、失敗することがあるようなので、接続してみてうまく初期設定されていないようなら、
`./data` も含めて消して作りなおすのが良さそうです。

```yaml
---
services:
  webtop:
    image: lscr.io/linuxserver/webtop:ubuntu-kde
    container_name: webtop
    security_opt:
      - seccomp:unconfined #optional
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Tokyo
      - SUBFOLDER=/ #optional
      - TITLE=Webtop #optional
      - DOCKER_MODS=linuxserver/mods:universal-package-install
      - INSTALL_PACKAGES=etckeeper|fonts-takao|bash-completion
      - LC_ALL=ja_JP.UTF-8
    volumes:
      - ./data:/config
      - /var/run/docker.sock:/var/run/docker.sock #optional
    ports:
      - "[2001:db8:a987:6543::c0]:3000:3000"
#      - 3001:3001
#    devices:
#      - /dev/dri:/dev/dri #optional
    shm_size: "1gb" #optional
    restart: unless-stopped
```

### 日本語化

参考にしたサイトでは [Dockerfile](https://github.com/karaage0703/docker-webtop/blob/c05f865d3ec17272efd68261b636ccd90048b6d8/container-ubuntu/Dockerfile) で `apt-get` を使ってインストールしていましたが、
`DOCKER_MODS=linuxserver/mods:universal-package-install` という公式の方法でインストールできました。
`INSTALL_PACKAGES` の指定は `|` 区切りで複数パッケージのインストールができました。

公式サイトの例にある latest は alpine なので `font-noto-cjk` ですが、
Debian や Ubuntu だと `fonts-noto-cjk` と `fonts` の `s` がつくので、
`image:` だけ変えても ubuntu だとフォントがインストールされなくて、
しばらく悩んでいました。

```yaml
---
services:
  webtop:
    image: lscr.io/linuxserver/webtop:latest
    container_name: webtop
    security_opt:
      - seccomp:unconfined #optional
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Tokyo
      - SUBFOLDER=/ #optional
      - TITLE=Webtop #optional
      - DOCKER_MODS=linuxserver/mods:universal-package-install
      - INSTALL_PACKAGES=font-noto-cjk|font-ipa
      - LC_ALL=ja_JP.UTF-8
    volumes:
      - ./data:/config
      - /var/run/docker.sock:/var/run/docker.sock #optional
    ports:
      - "[2001:db8:a987:6543::c0]:3000:3000"
#      - 3001:3001
#    devices:
#      - /dev/dri:/dev/dri #optional
    shm_size: "1gb" #optional
    restart: unless-stopped
```

### volumes

volumes で共有している `./data` にホームディレクトリの内容があるので、適当にホスト側との共有に使えそうです。

### ports

例のまま `3000:3000` だけで起動してしまうと VPS の外からも丸見えになってしまったので、
WireGuard で使っている IPv6 アドレスに制限しています。

ブラウザーで開くのは
`open -na "Google Chrome" --args --user-data-dir="$HOME/tmp/chrome-user-data" --window-size=1280,1024 'http://[2001:db8:a987:6543::c0]:3000'`
のように普段のブラウザーとは分離しています。

再接続でリサイズすると落ちることがあったので、念のためにサイズも固定しています。

`3001` の `https` 接続の方はまだ試していません。

## KasmVNC での操作

左にメニューが隠れていて、それを開いてクリップボードの操作などができました。

メニューを開いているときに上にスピーカーの共有などのスイッチもあったので、
それをオンにしてリモートで YouTube などで音声を再生すると、ちゃんと聞こえました。

ブラウザーを閉じる前にメニューから切断をしておくと、今のところ再接続で落ちていません。

## 仕組みをちょっと深堀り

複数ディストリビューション共通で systemd ではなく
[s6](https://www.skarnet.org/software/s6/index.html)
を使っているようでした。

例にあった `DOCKER_MODS` の指定は
[linuxserver/docker-mods](https://github.com/linuxserver/docker-mods)
が関係しているようで、
`linuxserver/mods:universal-package-install` は
[universal-package-install ブランチ](https://github.com/linuxserver/docker-mods/tree/universal-package-install)
にありました。

`INSTALL_PIP_PACKAGES` にも対応しているようなので、
それでインストールできる環境の構築は `compose.yaml` だけで完結できそうです。

他の `DOCKER_MODS` も
[linuxserver/docker-mods](https://github.com/linuxserver/docker-mods)
などから探すと便利そうです。

`DOCKER_MODS` の複数指定は `INSTALL_PACKAGES` と同じように `|` 区切りのようです。

## まとめ

`docker-webtop` でリモートでのブラウザーの開きっぱなしが実現できました。

[Webtop 2.0 - The year of the Linux desktop](https://www.linuxserver.io/blog/webtop-2-0-the-year-of-the-linux-desktop)
によると
[docker-vscodium](https://github.com/linuxserver/docker-vscodium)
などの他のアプリ用のイメージも用意されているようなので、
用途にあうものがあれば簡単に使えそうです。
