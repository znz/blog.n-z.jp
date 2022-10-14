---
layout: post
title: "gpg-agentをsshでforwardingする設定を改善した"
date: 2022-10-14 11:10 +0900
comments: true
category: blog
tags: debian ubuntu linux gpg
---
[前回の記事]({% post_url 2022-10-05-gpg-agent-forwarding %})の続きです。
たまに gpg-agent forwarding が切れるようで、それ自体はまだ原因がわかっていません。
使えなくなったときに ssh を再接続しても直らないことがあったので、
ssh を再接続すれば確実に直る状態まで改善できました。

<!--more-->

## 動作確認バージョン

前回と同じです。

ローカル側:

- macOS Monterey 12.6
- Homebrew でインストールした gpg (GnuPG) 2.3.7
- OpenSSH_8.6p1, LibreSSL 3.3.6

リモート側:

- Ubuntu 22.04.1 LTS (jammy)
- gnupg 2.2.27-3ubuntu2.1
- openssh-server 1:8.9p1-3

## ownertrust

前回の記事に書き忘れていたので追記したのですが、
`ownertrust` の情報もコピーしておかないと
信用していない鍵の確認が毎回出てきてしまいます。

```console
% gpg --export-ownertrust | ssh $REMOTE gpg --import-ownertrust
```

以下のように `gpg --edit-key` で `trust` しても大丈夫です。

```console
ubuntu@outgoing-cat:~$ gpg --edit-key 262ED8DBB4222F7A
gpg (GnuPG) 2.2.27; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


pub  rsa4096/262ED8DBB4222F7A
	 created: 2010-06-27  expires: 2040-08-10  usage: SC
	 trust: unknown       validity: unknown
sub  rsa4096/7515B686FAFB96B8
	 created: 2010-06-27  expires: 2040-08-10  usage: E
[ unknown] (1). Kazuhiro NISHIYAMA <z...m>
[ unknown] (2)  Kazuhiro NISHIYAMA (ZnZ) <z...m>
[ revoked] (3)  Kazuhiro NISHIYAMA <n...p>
[ unknown] (4)  Kazuhiro NISHIYAMA (znz) <k...m>

gpg> trust
pub  rsa4096/262ED8DBB4222F7A
	 created: 2010-06-27  expires: 2040-08-10  usage: SC
	 trust: unknown       validity: unknown
sub  rsa4096/7515B686FAFB96B8
	 created: 2010-06-27  expires: 2040-08-10  usage: E
[ unknown] (1). Kazuhiro NISHIYAMA <z...m>
[ unknown] (2)  Kazuhiro NISHIYAMA (ZnZ) <z...m>
[ revoked] (3)  Kazuhiro NISHIYAMA <n...p>
[ unknown] (4)  Kazuhiro NISHIYAMA (znz) <k...m>

Please decide how far you trust this user to correctly verify other users' keys
(by looking at passports, checking fingerprints from different sources, etc.)

  1 = I don't know or won't say
  2 = I do NOT trust
  3 = I trust marginally
  4 = I trust fully
  5 = I trust ultimately
  m = back to the main menu

Your decision? 5
Do you really want to set this key to ultimate trust? (y/N) y

pub  rsa4096/262ED8DBB4222F7A
	 created: 2010-06-27  expires: 2040-08-10  usage: SC
	 trust: ultimate      validity: unknown
sub  rsa4096/7515B686FAFB96B8
	 created: 2010-06-27  expires: 2040-08-10  usage: E
[ unknown] (1). Kazuhiro NISHIYAMA <z...m>
[ unknown] (2)  Kazuhiro NISHIYAMA (ZnZ) <z...m>
[ revoked] (3)  Kazuhiro NISHIYAMA <n...p>
[ unknown] (4)  Kazuhiro NISHIYAMA (znz) <k...m>
Please note that the shown key validity is not necessarily correct
unless you restart the program.

gpg> q
```

## 使えなくなる原因

`gpg` コマンドを実行したときに、
`gpg-agent` につながらないと、
`gpg` コマンドが自動で `gpg-agent` を起動してしまいます。

すると forwarding された `gpg-agent` には接続できずに、
起動した `gpg-agent` につながるようになってしまって、
手元の秘密鍵が使えない、という状況になるようでした。

## gpg に gpg-agent を起動させない

`gpg --no-autostart` で自動起動しなくなるので、たとえば
[Pass: The Standard Unix Password Manager](https://www.passwordstore.org/)
なら
`export PASSWORD_STORE_GPG_OPTS=--no-autostart`
で設定できます。

しかし、この方法だと動作確認のための `gpg -K` などもすべて `gpg --no-autostart -K` などにしないといけなくて大変です。

そこで `~/.gnupg/gpg.conf` に以下のように `no-autostart` を設定しました。

```console
ubuntu@outgoing-cat:~$ cat ~/.gnupg/gpg.conf
no-autostart
```

## systemd からも gpg-agent を起動させない

`$XDG_RUNTIME_DIR/gnupg/S.gpg-agent` などのソケットは `systemd` で待ち受けしているので、
そこ経由で起動してしまう可能性もあります。
これで起動した場合は `ps x` などで確認すると `gpg-agent --supervised` という引数になっています。

これを止めるために `systemctl mask` でマスクしておきます。

```console
ubuntu@outgoing-cat:~$ systemctl --user mask gpg-agent.service gpg-agent.socket gpg-agent-ssh.socket gpg-agent-extra.socket gpg-agent-browser.socket
Created symlink /home/ubuntu/.config/systemd/user/gpg-agent.service → /dev/null.
Created symlink /home/ubuntu/.config/systemd/user/gpg-agent.socket → /dev/null.
Created symlink /home/ubuntu/.config/systemd/user/gpg-agent-ssh.socket → /dev/null.
Created symlink /home/ubuntu/.config/systemd/user/gpg-agent-extra.socket → /dev/null.
Created symlink /home/ubuntu/.config/systemd/user/gpg-agent-browser.socket → /dev/null.
```

## 動作確認

`gpg-agent` の設定の再読み込みは (今回は無関係ですが) `gpg-connect-agent reloadagent /bye` や `gpgconf --reload gpg-agent` でできるように、
停止は `pkill gpg-agent` などで `kill` しても良いですが `gpgconf --kill gpg-agent` でできます。

agent forwarding ありでの正しい実行結果例は以下のようになります。

```console
ubuntu@outgoing-cat:~$ gpg -K
/home/ubuntu/.gnupg/pubring.kbx
-------------------------------
sec   rsa4096 2010-06-27 [SC] [expires: 2040-08-10]
      B863D6DCC2B957B852386CE0262ED8DBB4222F7A
uid           [ultimate] Kazuhiro NISHIYAMA <z...m>
uid           [ultimate] Kazuhiro NISHIYAMA (ZnZ) <z...m>
uid           [ultimate] Kazuhiro NISHIYAMA (znz) <k...m>
ssb   rsa4096 2010-06-27 [E] [expires: 2040-08-10]
```

agent forwarding なしでの正しい実行結果は以下のようになります。

```
ubuntu@outgoing-cat:~$ gpg -K
gpg: no gpg-agent running in this session
```

## 失敗例

`gpg -K` で何も出力されなくて `gpg-agent` が起動してしまっているときは、
`$XDG_RUNTIME_DIR/gnupg/S.gpg-agent` が forwarding したものではなく、
`gpg-agent` のものになってしまっています。

```
ubuntu@outgoing-cat:~$ gpg -K
ubuntu@outgoing-cat:~$ pgrep gpg-agent
3464
ubuntu@outgoing-cat:~$ ls -1 $XDG_RUNTIME_DIR/gnupg
S.dirmngr
S.gpg-agent
S.gpg-agent.browser
S.gpg-agent.extra
S.gpg-agent.ssh
```

この状態で復号が必要な処理を実行すると
`gpg: decryption failed: No secret key`
になります。

## まとめ

`gpg-agent` の起動を止めることで、確実に forwarding した `gpg-agent` への接続を試してくれるようになりました。

forwarding が切れる原因は調べきれていないのですが、複数同時接続しているので、
後から接続した方が `StreamLocalBindUnlink yes` でソケットを上書きして、
そちらが切れると forwarding 自体も切れるのかなという可能性を考えているので、
`ControlMaster` などで解決できるのかもしれません。
