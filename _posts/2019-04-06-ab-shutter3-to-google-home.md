---
layout: post
title: "AB Shutter3(BTボタン)を押すとGoogle Homeでしゃべるようにしてみた"
date: 2019-04-06 23:36 +0900
comments: true
category: blog
tags: linux raspberrypi googlehome iot
---
ダイソーで 300 円で売っている AB Shutter3 という Bluetooth 接続できるボタンを Raspberry Pi 3B と繋いで、 Google Home Mini に喋らせるなどの任意のプログラムを実行できるようにしてみました。

<!--more-->

## 確認環境

- AB Shutter3 (ダイソーで 300 円 + 税で買ったもの)
- Raspberry Pi 3B 上の Raspbian GNU/Linux 9.8 (stretch)
- Google Home Mini

## AB Shutter3 とのペアリング

`bluetoothctl` で接続します。
どの権限が影響しているのかは調べていませんが `sudo` なしの一般ユーザーでいけました。

[raspberry pi と AB Shutter3(bluetoothボタン) の連携 - フクロウ好きなエンジニアのブログ](https://miya15.hatenablog.com/entry/2018/11/04/145905) のように、
`scan on` で出てくる中の `[NEW] Device XX:XX:XX:XX:XX:XX AB Shutter3` の MAC アドレスを使います。
接続には `pair` でペアリング、 `trust` で PIN がないデバイスを手動で信頼、 `connect` で接続あたりを使います。
Ctrl+C や `quit` で終了できます。

```
[bluetooth]# scan on
Discovery started
[bluetooth]# pair XX:XX:XX:XX:XX:XX
Attempting to pair with XX:XX:XX:XX:XX:XX
[CHG] Device XX:XX:XX:XX:XX:XX Connected: yes
[AB Shutter3       ]# trust XX:XX:XX:XX:XX:XX
[CHG] Device XX:XX:XX:XX:XX:XX Trusted: yes
Changing XX:XX:XX:XX:XX:XX trust succeeded
[AB Shutter3       ]# quit
```

`sudo apt install evtest` でインストールして `evtest` コマンドで反応があるかどうか試します。

反応がなかったので、しばらく試行錯誤していたのですが、
[クラゲのIoTテクノロジー](http://jellyware.jp/kurage/raspi/daiso_btshutter.html)
に書いてあるように `disconnect`, `remove`, `power off`, `power on` などを試していると反応するようになりました。

## bluebutton

- iOS ボタンと Android ボタンの使い分けに対応している fork の <https://github.com/miya15/bluebutton> を使いました。

```
git clone https://github.com/miya15/bluebutton
cd bluebutton
gem build *.gemspec
gem i *.gem --user-install
```

でインストールしました。

`=` の入ったコマンドが実行できないという問題があるので、以下のようにすると良いかもしれません。
設定ファイルの扱いが `keydown` を含む行、 `keyup` を含む行、などになっていて、コメントアウトができない、コマンド側にマッチすると誤認識する、などの問題もあるので、ひっかかるようなら対応した方が良いかもしれません。
(後述するように別途シェルスクリプトなどを用意して実行する方が良いと思いますが。)

```
diff --git a/bin/bluebutton b/bin/bluebutton
index 4825959..c2d49ab 100755
--- a/bin/bluebutton
+++ b/bin/bluebutton
@@ -24,17 +24,17 @@ actions = {}
 if opts[:config]
   File.readlines(opts[:config]).each do |line|
     if line['keydown']
-      actions[:keydown]  = ->{system(line.split('=')[1].strip)}
+      actions[:keydown]  = ->{system(line.split('=',2)[1].strip)}
     elsif line['keyup']
-      actions[:keyup]    = ->{system(line.split('=')[1].strip)}
+      actions[:keyup]    = ->{system(line.split('=',2)[1].strip)}
     elsif line['longdown']
-      actions[:longdown] = ->{system(line.split('=')[1].strip)}
+      actions[:longdown] = ->{system(line.split('=',2)[1].strip)}
     elsif line['longup']
-      actions[:longup]   = ->{system(line.split('=')[1].strip)}
+      actions[:longup]   = ->{system(line.split('=',2)[1].strip)}
     elsif line['pushandroid']
-      actions[:pushandroid] = ->{system(line.split('=')[1].strip)}
+      actions[:pushandroid] = ->{system(line.split('=',2)[1].strip)}
     elsif line['pushios']
-      actions[:pushios]     = ->{system(line.split('=')[1].strip)}
+      actions[:pushios]     = ->{system(line.split('=',2)[1].strip)}
     end
   end
 end
```

設定ファイルは以下のようにしました。
最初は `curl` のコマンドラインを設定ファイルに直接書いていたので上の対応をしましたが、別ファイルに分けたので必須ではなくなりました。

```
$ cat ~/bluebutton.config
keyup=echo UP
keydown=echo DOWN
longup=echo LONG UP
longdown=echo LONG DOWN
pushandroid=echo PUSH android
pushios=echo PUSH ios
pushandroid=~/pushandroid.sh
pushios=~/pushios.sh
$ cat ~/pushandroid.sh
#!/bin/sh
set -eu
curl -X POST -d "text=Androidボタンが押されました。" http://localhost:8080/google-home-notifier &
ruby ~/memo.rb "Androidボタンが押されました。" &
$ cat ~/pushios.sh
#!/bin/sh
set -eu
curl -X POST -d "text=iOSボタンが押されました。" http://localhost:8080/google-home-notifier &
ruby ~/memo.rb "iOSボタンが押されました。" &
```

## google-home-notifier

以前に試したものが動かなくなっていたので、 `node_modules` を消すなどして途中からやり直してみました。

<https://github.com/noelportugal/google-home-notifier#after-npm-install> に書いてあるように `npm install google-home-notifier` のあとで `{families:[4]}` を追加する他に、
`Error: get key failed from google` 対策として、[google-home-notifierが「Error: get key failed from google」を吐いたので対策してみた - Qiita](https://qiita.com/ezmscrap/items/24b3a9a8548da0ab9ff5) からリンクされている [update TKK key setting after Google Translate changes](https://github.com/zlargon/google-tts/pull/14/commits/b5d1b8561fc1a34fac1e66bb280cd153d1a31044) からさらに変わっているので、最新の <https://github.com/zlargon/google-tts/blob/master/lib/key.js> から Raw をダウンロードして `node_modules/google-tts-api/lib/key.js` を差し替えるのが良さそうです。

### example.js

bluebutton から接続しているサーバーは、参考にしたサーバーほぼそのままで以下の通りです。

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

### hello.js

動作確認用の単独コマンドは以下の通りです。

```
const googlehome = require('google-home-notifier')
const language = 'ja';

googlehome.device('Google-Home', language);

googlehome.notify('こんにちは。私はグーグルホームです。', function(res) {
  console.log(res);
});
```
