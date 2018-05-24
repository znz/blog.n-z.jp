---
layout: post
title: "Google Home に任意のテキストを喋らせる"
date: 2018-05-24 21:57 +0900
comments: true
category: blog
tags: googlehome
---
Google Home Mini をとりあえず普通に使ってみていたのですが、
カスタマイズの第一歩ということで、
[google-home-notifier](https://github.com/noelportugal/google-home-notifier)
で任意のテキストを喋らせてみました。

<!--more-->

## 環境

- Google Home Mini
- Raspbian GNU/Linux 9.4 (stretch)
- node v8.11.2
- google-home-notifier 1.2.0

## node.js のバージョンアップ

まず最初に `update-nodejs-and-nodered` というコマンドで Node-RED も含めて node.js のバージョンアップをしておきました。

## libavahi-compat-libdnssd-dev

以下のエラーになるので、
`sudo apt install libavahi-compat-libdnssd-dev`
でインストールしておきます。

```
make: ディレクトリ '/home/pi/googlehome/node_modules/mdns/build'　に入ります
  CXX(target) Release/obj.target/dns_sd_bindings/src/dns_sd.o
In file included from ../src/dns_sd.cpp:1:0:
../src/mdns.hpp:32:20: fatal error: dns_sd.h: そのようなファイルやディレクトリはありません
 #include <dns_sd.h>
                    ^
compilation terminated.
dns_sd_bindings.target.mk:150: ターゲット 'Release/obj.target/dns_sd_bindings/src/dns_sd.o' のレシピで失敗しました
make: *** [Release/obj.target/dns_sd_bindings/src/dns_sd.o] エラー 1
```

## 作業ディレクトリ作成

以下のように作成しておきます。

```
mkdir googlehome
cd googlehome
npm init -y
```

## npm install

`npm install google-home-notifier` でインストールします。

## vi node_modules/mdns/lib/browser.js

[After "npm install"](https://github.com/noelportugal/google-home-notifier#after-npm-install)
に書いてある変更を適用しておきます。

改行が入って多少変わっていましたが、
README と同様に
`rst.getaddrinfo()`
を
`rst.getaddrinfo({families:[4]})`
にするとうまくいきました。

## hello.js

Web でよく見つかる例をそのまま使いました。

```javascript
const googlehome = require('google-home-notifier')
const language = 'ja';

googlehome.device('Google-Home', language);

googlehome.notify('こんにちは。私はグーグルホームです。', function(res) {
  console.log(res);
});
```

## トラブルシューティング

### ECONNREFUSED

WARNING は無視して良さそうなので、無視するとして、
最初は ECONNREFUSED で繋がりませんでした。

```
$ node hello.js
*** WARNING *** The program 'node' uses the Apple Bonjour compatibility layer of Avahi.
*** WARNING *** Please fix your application to use the native API of Avahi!
*** WARNING *** For more information see <http://0pointer.de/avahi-compat?s=libdns_sd&e=node>
*** WARNING *** The program 'node' called 'DNSServiceRegister()' which is not supported (or only supported partially) in the Apple Bonjour compatibility layer of Avahi.
*** WARNING *** Please fix your application to use the native API of Avahi!
*** WARNING *** For more information see <http://0pointer.de/avahi-compat?s=libdns_sd&e=node&f=DNSServiceRegister>
Device "Google-Home-Mini-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" at 192.168.xxx.xxx:8009
Error: connect ECONNREFUSED 192.168.xxx.xxx:8009
error
```

`dmesg` をみると
`[UFW BLOCK] IN= OUT=wlan0 SRC=192.168.xxx.xxx DST=192.168.xxx.xxx LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=51779 DF PROTO=TCP SPT=42062 DPT=8009 WINDOW=29200 RES=0x00 SYN URGP=0`
のように出ていて、原因は ufw で out も制限しているからでした。

`sudo ufw allow out 8009/tcp` で解決しました。

### player.load が undefined

```
$ node hello.js
*** WARNING *** The program 'node' uses the Apple Bonjour compatibility layer of Avahi.
*** WARNING *** Please fix your application to use the native API of Avahi!
*** WARNING *** For more information see <http://0pointer.de/avahi-compat?s=libdns_sd&e=node>
*** WARNING *** The program 'node' called 'DNSServiceRegister()' which is not supported (or only supported partially) in the Apple Bonjour compatibility layer of Avahi.
*** WARNING *** Please fix your application to use the native API of Avahi!
*** WARNING *** For more information see <http://0pointer.de/avahi-compat?s=libdns_sd&e=node&f=DNSServiceRegister>
Device "Google-Home-Mini-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" at 192.168.xxx.xxx:8009
/home/pi/googlehome/node_modules/google-home-notifier/google-home-notifier.js:92
      player.load(media, { autoplay: true }, function(err, status) {
             ^

TypeError: Cannot read property 'load' of undefined
    at /home/pi/googlehome/node_modules/google-home-notifier/google-home-notifier.js:92:14
    at /home/pi/googlehome/node_modules/castv2-client/lib/senders/platform.js:95:20
    at /home/pi/googlehome/node_modules/castv2-client/lib/controllers/receiver.js:51:14
    at fn.onmessage (/home/pi/googlehome/node_modules/castv2-client/lib/controllers/request-response.js:27:7)
    at emitTwo (events.js:131:20)
    at fn.emit (events.js:214:7)
    at Channel.onmessage (/home/pi/googlehome/node_modules/castv2-client/lib/controllers/controller.js:16:10)
    at emitTwo (events.js:126:13)
    at Channel.emit (events.js:214:7)
    at Client.onmessage (/home/pi/googlehome/node_modules/castv2/lib/channel.js:23:10)
```

`function(err, status)` で err が渡ってきているのに無視してるのが、
エラーメッセージがわかりにくい原因でしたが、直前に
`if (err) console.log(err);`
を入れて見たら
`Error: Launch failed. Reason: NOT_FOUND`
と出てきたので、辿ってみると
`deviceAddress = service.addresses[0];`
でアドレスが取れていないようだったので、
普通に使おうと OK, Google といってみても Google Home アプリから設定が必要と言われて、
使えませんでした。

結局設定し直したら google-home-notifier からも問題なく使えました。
Google Home Mini 自体には何もしていなくて、心当たりは Chromecast を一度別のネットワークに繋いで試していたぐらいなのですが、
とりあえず設定し直せば大丈夫でした。

## 正常動作のログ

正常動作時は Device notified と出ました。

```
$ node hello.js
*** WARNING *** The program 'node' uses the Apple Bonjour compatibility layer of Avahi.
*** WARNING *** Please fix your application to use the native API of Avahi!
*** WARNING *** For more information see <http://0pointer.de/avahi-compat?s=libdns_sd&e=node>
*** WARNING *** The program 'node' called 'DNSServiceRegister()' which is not supported (or only supported partially) in the Apple Bonjour compatibility layer of Avahi.
*** WARNING *** Please fix your application to use the native API of Avahi!
*** WARNING *** For more information see <http://0pointer.de/avahi-compat?s=libdns_sd&e=node&f=DNSServiceRegister>
Device "Google-Home-Mini-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" at 192.168.xxx.xxx:8009
Device notified
```

## example.js

google-home-notifier の example.js から ngrok を外して以下のようにしました。

```
const express = require('express');
const googlehome = require('google-home-notifier')
const language = 'ja';
const bodyParser = require('body-parser');
const app = express();
const serverPort = 8080;

var deviceName = 'Google Home';
googlehome.device(deviceName, language);

var urlencodedParser = bodyParser.urlencoded({ extended: false });

app.post('/google-home-notifier', urlencodedParser, function (req, res) {
  if (!req.body) return res.sendStatus(400)
  console.log(req.body);
  var text = req.body.text;
  if (text){
    try {
      googlehome.notify(text, function(notifyRes) {
        console.log(notifyRes);
        res.send(deviceName + ' will say: ' + text + '\n');
      });
    } catch(err) {
      console.log(err);
      res.sendStatus(500);
      res.send(err);
    }
  }else{
    res.send('Please POST "text=Hello Google Home"');
  }

})

app.listen(serverPort, function () {
  console.log('POST "text=Hello Google Home" to:');
  console.log('    http://localhost:' + serverPort + '/google-home-notifier');
  console.log('example:');
  console.log('curl -X POST -d "text=Hello Google Home" http://localhost:' + serverPort + '/google-home-notifier');
})
```

## 動作例

バックグラウンドで起動して curl で POST してみたところ、ちゃんと喋ってくれることを確認できました。

```
$ node example.js &
[1] 8308
$ *** WARNING *** The program 'node' uses the Apple Bonjour compatibility layer of Avahi.
*** WARNING *** Please fix your application to use the native API of Avahi!
*** WARNING *** For more information see <http://0pointer.de/avahi-compat?s=libdns_sd&e=node>
*** WARNING *** The program 'node' called 'DNSServiceRegister()' which is not supported (or only supported partially) in the Apple Bonjour compatibility layer of Avahi.
*** WARNING *** Please fix your application to use the native API of Avahi!
*** WARNING *** For more information see <http://0pointer.de/avahi-compat?s=libdns_sd&e=node&f=DNSServiceRegister>
POST "text=Hello Google Home" to:
    http://localhost:8080/google-home-notifier
example:
curl -X POST -d "text=Hello Google Home" http://localhost:8080/google-home-notifier

$ curl -X POST -d "text=$(date +%Y/%m/%d)" http://localhost:8080/google-home-notifier
{ text: '2018/05/24' }
Device "Chromecast-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" at 192.168.xxx.xxx:8009
Device "Google-Home-Mini-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" at 192.168.xxx.xxx:8009
Device notified
Google Home will say: 2018/05/24
$ curl -X POST -d "text=ねぇ、グーグル" http://localhost:8080/google-home-notifier
{ text: 'ねぇ、グーグル' }
Device notified
Google Home will say: ねぇ、グーグル
$ curl -X POST -d "text=こんばんは" http://localhost:8080/google-home-notifier
{ text: 'こんばんは' }
Device notified
Google Home will say: こんばんは
```

## まとめ

Google Home Mini に喋らせる単機能の部品ができたので、
Unix 的に他のものと組み合わせていろいろできそうです。

最初の mDNS での IP アドレス検出などで少し時間がかかるようなので、
hello.js のような単機能のコマンドを毎回呼ぶよりも、
example.js のように常駐させた方が都合が良さそうでした。
