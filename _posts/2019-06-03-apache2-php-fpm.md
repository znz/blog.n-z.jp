---
layout: post
title: "libapache2-mod-fastcgi がなくなっていたので mod_proxy_fcgi に変更した"
date: 2019-06-03 00:00 +0900
comments: true
category: blog
tags: ubuntu debian linux
---
Ubuntu 16.04 から 18.04 にあげてから、 php の実行ユーザーを分離するために使っている php-fpm に繋ぐための libapache2-mod-fastcgi が消えてしまって動かなくなっていたので、 `mod_proxy_fcgi` を使うように変更しました。

<!--more-->

## 確認環境

- Ubuntu 18.04.2 LTS (bionic)
- apache2 2.4.29-1ubuntu4.6
- php-fpm 1:7.2+60ubuntu1

## libapache2-mod-fastcgi の調査

<https://tracker.debian.org/pkg/libapache-mod-fastcgi> から削除された理由を調べてみると、
<https://tracker.debian.org/news/805109/removed-2470910052141-12-from-unstable/> と
<https://tracker.debian.org/news/805110/removed-2470910052141-12-from-unstable/> の
なぜか 2 通ありましたが、どちらも

```
  ------------------- Reason -------------------
  dead upstream, quite old, orphaned, dfsg-free alternative (libapache-mod-fcgid)
  ----------------------------------------------
```

となっていました。

## libapache-mod-fcgid を試した

というわけで、 alternative としてあげられていた libapache-mod-fcgid を試してみましたが、要件を満たしませんでした。

<https://www.mail-archive.com/mod-fcgid-users@lists.sourceforge.net/msg00222.html> に書いてあるように

```
  > Is "FastCgiExternalServer" supported by mod_fcgid?

  mod_fastcgi and mod_fcgid are totally different modules and don't even
  share a common codebase. They have only the FastCGI protocol in common.
  Thus, Apache Directives are totally different. Besides, mod_fcgid has an
  adaptive-spawning design and does not support "Static" servers or
  External servers.

  I guess the short answer is : no, and not planned.
```

ということで、自前で FastCGI のプロセスを起動するようで、
php-fpm と繋ぐという用途には使えませんでした。

## `mod_proxy_fcgi` を使う

<https://cwiki.apache.org/confluence/display/HTTPD/PHP-FPM> に php-fpm を `mod_proxy_fcgi` と組み合わせるという話があったので、
試してみたところ、
`sudo a2enmod proxy_fcgi` と `sudo a2enconf php7.2-fpm` でうまくいきました。

php7.2-fpm の設定は以下のようになっていました。

```
  % cat /etc/apache2/conf-enabled/php7.2-fpm.conf
  # Redirect to local php-fpm if mod_php is not available
  <IfModule !mod_php7.c>
  <IfModule proxy_fcgi_module>
	  # Enable http authorization headers
	  <IfModule setenvif_module>
	  SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=$1
	  </IfModule>

	  <FilesMatch ".+\.ph(ar|p|tml)$">
		  SetHandler "proxy:unix:/run/php/php7.2-fpm.sock|fcgi://localhost"
	  </FilesMatch>
	  <FilesMatch ".+\.phps$">
		  # Deny access to raw php sources by default
		  # To re-enable it's recommended to enable access to the files
		  # only in specific virtual host or directory
		  Require all denied
	  </FilesMatch>
	  # Deny access to files without filename (e.g. '.php')
	  <FilesMatch "^\.ph(ar|p|ps|tml)$">
		  Require all denied
	  </FilesMatch>
  </IfModule>
  </IfModule>
```

### 最低限の設定

`php7.2-fpm.conf` の存在に気づく前に試した最低限の設定は以下の通りです。

```
  <IfModule proxy_fcgi_module>
	  <FilesMatch "\.php$">
		  SetHandler "proxy:unix:/run/php/php7.2-fpm.sock|fcgi://localhost/"
	  </FilesMatch>
  </IfModule>
```

## まとめ

libapache2-mod-fastcgi の削除理由の alternative に libapache-mod-fcgid があげられていますが、
使い方によっては apache2-bin に同梱されている `mod_proxy_fcgi` を使えばよかったようです。
