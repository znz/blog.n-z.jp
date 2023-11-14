---
layout: post
title: homebrewで入れていたansibleが壊れていたので再インストールで直した
date: 2023-11-14 14:13 +0900
comments: true
category: blog
tags: ansible osx homebrew
---
`homebrew` で入れている `ansible` が動かなくなっていたので、
`homebrew-core` の issues で同じ問題を探して解決したので、
その方法のメモです。

<!--more-->

## 環境

- macOS Ventura 13.6.2
- Homebrew 4.1.20-11-g6de29c2
- Homebrew/homebrew-core (git revision 8885719c7e7; last commit 2023-10-31)
- Homebrew/homebrew-cask (git revision 7e620eb67d; last commit 2023-02-05)
- ansible 8.6.1

## 現象

`ansible-playbook` を実行すると `markupsafe` モジュールのエラーで動かなくなっていました。

```console
$ ansible-playbook -i hosts playbook/update.yml -b --forks 20
ERROR: No module named 'markupsafe'
```

## 調査

特別なことは何もしていないので `homebrew-core` で issues を開いて ansible 関連を目視で探してみたところ、
すぐにみつかった
<https://github.com/Homebrew/homebrew-core/issues/153763>
に同じ問題がありました。

## 解決

<https://github.com/Homebrew/homebrew-core/issues/153763#issuecomment-1805418409>
の `brew uninstall python-markupsafe ansible && brew install ansible` で解決しました。

```console
% brew uninstall python-markupsafe ansible
Uninstalling /opt/homebrew/Cellar/python-markupsafe/2.1.3... (48 files, 256.8KB)
Uninstalling /opt/homebrew/Cellar/ansible/8.6.1... (30,260 files, 444.9MB)
% brew install ansible
Already downloaded: /Users/kazu/Library/Caches/Homebrew/downloads/c806c4477ec68fd4de54aa31212b2d835eb3ecfa53ae468799ec5889e6d51a83--ansible-8.6.1.bottle_manifest.json
==> Fetching dependencies for ansible: pycparser, cffi, python-certifi, python-markupsafe, python-packaging, python-pytz, pyyaml and six
(略)
==> Installing ansible
==> Pouring ansible--8.6.1.arm64_ventura.bottle.tar.gz
🍺  /opt/homebrew/Cellar/ansible/8.6.1: 30,247 files, 444.8MB
==> Running `brew cleanup ansible`...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).
```

issue にリンクしている pull request があるので、
`homebrew-core` の更新を待っていても解決しそうです。
