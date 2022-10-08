---
layout: post
title: "gpg-agentをsshでforwardingする設定をした"
date: 2022-10-05 21:10 +0900
comments: true
category: blog
tags: debian ubuntu linux gpg
---
[AgentForwarding - GnuPG wiki](https://wiki.gnupg.org/AgentForwarding)を参考にして、
`gpg-agent` を `ssh` 先からも使えるようにしてみました。

<!--more-->

## 動作確認バージョン

ローカル側:

- macOS Monterey 12.6
- Homebrew でインストールした gpg (GnuPG) 2.3.7
- OpenSSH_8.6p1, LibreSSL 3.3.6

リモート側:

- Ubuntu 22.04.1 LTS (jammy)
- gnupg 2.2.27-3ubuntu2.1
- openssh-server 1:8.9p1-3

この後の例では、リモート側のマシン名を `$REMOTE` と表記しています。

## ローカル側の GnuPG 設定

`GnuPG (< 2.1.17)` だと
`extra-socket /home/<user>/.gnupg/S.gpg-agent.extra`
の設定が必要だそうですが、
2.3.7 なので、何も設定を追加しなくても、
`gpgconf --list-dir agent-extra-socket`
で出てくる
`/Users/$USER/.gnupg/S.gpg-agent.extra`
が存在していました。

### pinentry など

今回の設定とは関係なく、
`~/.gnupg/gpg-agent.conf`
には以前から以下のように `pinentry` などの設定をしています。

```text
pinentry-program /opt/homebrew/bin/pinentry-mac
default-cache-ttl 3600
max-cache-ttl 18000
```

このうち `pinentry-program` の設定が必要なので、
入っていなければ `brew install pinentry-mac` でインストールして、
`~/.gnupg/gpg-agent.conf` に設定しておきます。

`default-cache-ttl` と `max-cache-ttl` は好みで設定すれば良いと思います。

### Pinentry Mac の設定

「Save in Keychain」のチェックボックスをオフにしておくため、
`defaults` コマンドで以下の設定もしています。

```console
% defaults write org.gpgtools.common UseKeychain NO
```

### extra-socket とは

Pinentry Mac で普通にパスフレーズを要求されるときは
「OpenPGP の秘密鍵のロックを解除するためにパスフレーズを入力してください:」
と出ますが、
extra-socket からのリクエストのときは
「注意: リモートサイトからのリクエストです。」
と出て、
区別できるようになっています。

## 公開鍵のコピー

公開鍵はリモートにも入れておく必要があるようなので、
`--export` して `--import` しておきます。

```console
% gpg --export --armor $KEY_ID | ssh $REMOTE gpg --import
```

## コマンドライン指定での動作確認

サーバー側も `OpenSSH >= 6.7` なので、
`/etc/ssh/sshd_config` に `StreamLocalBindUnlink yes` を追加すれば良いのですが、
その前にコマンドライン指定だけで動作確認をしておきます。

`-R "$(ssh $REMOTE gpgconf --list-dir agent-socket):$(gpgconf --list-dir agent-extra-socket)"` でも同じですが、
後で `~/.ssh/config` に追加しやすいように `-o` で動作確認しています。

リモート側は鍵を信頼する設定をしていないので確認がでますが、
`y` でそのまま使います。

```console
% ssh $REMOTE rm '$(gpgconf --list-dir agent-socket)'
% ssh -o "RemoteForward $(ssh $REMOTE gpgconf --list-dir agent-socket) $(gpgconf --list-dir agent-extra-socket)" $REMOTE
$ echo test | gpg --encrypt -r $KEY_ID --armor -o test.asc
$ gpg --decrypt test.asc
```

最初はうまくいかなかったので、
`gpg-connect-agent reloadagent /bye`
とかリモートマシンの再起動を試しましたが、
`ControlMaster` を使っているなら、
ローカル側で
`ssh -O exit $REMOTE`
を試すと良さそうです。

## ローカル側の設定追加

```console
% echo "RemoteForward $(ssh $REMOTE gpgconf --list-dir agent-socket) $(gpgconf --list-dir agent-extra-socket)"
```

で表示した設定を `~/.ssh/config` の `Host $REMOTE` のとこに追加しておきます。

## リモート側の設定追加

`StreamLocalBindUnlink yes` の設定を `/etc/ssh/sshd_config` の適当なところに追加しておきます。
最近は `Include /etc/ssh/sshd_config.d/*.conf` があるので、
下の例では `/etc/ssh/sshd_config.d/StreamLocalBindUnlink.conf` を作成しました。
追加したら、 `reload` や再起動で反映させておきます。

```console
% ssh $REMOTE
$ echo StreamLocalBindUnlink yes | sudo tee /etc/ssh/sshd_config.d/StreamLocalBindUnlink.conf > /dev/null
$ sudo systemctl reload ssh
```

これで `ssh $REMOTE rm '$(gpgconf --list-dir agent-socket)'` をしなくても自動で作り直されて使えるようになります。

## まとめ

いくつかの設定をして、Unix Socket を `RemoteForward` で forwarding することで手元の `gpg-agent` (と `pinentry`) をリモートからも使えるようになりました。

これでリモートに秘密鍵を置かずに
[Pass: The Standard Unix Password Manager](https://www.passwordstore.org/)
などが使えそうです。

## 参考サイト

- [AgentForwarding - GnuPG wiki](https://wiki.gnupg.org/AgentForwarding)
- [GnuPG agent forwarding](https://gist.github.com/TimJDFletcher/85fafd023c81aabfad57454111c1564d)
