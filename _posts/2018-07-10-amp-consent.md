---
layout: post
title: "amp-consentを追加した"
date: 2018-07-10 23:34 +0900
comments: true
category: blog
tags: jekyll amp adsense
---
AdSenseの設定画面で<q>Google の更新版「EU ユーザーの同意ポリシー」にサイト運営者様が準拠できるようサポートするため、EU ユーザーの同意設定をご用意しました。</q>と出ていたので、同意取得の設定を入れてみました。

<!--more-->

## 前提

この blog は AMP を使っているので、
[Google のサイト運営者広告タグでの広告パーソナライズ設定 - AdSense ヘルプ](https://support.google.com/adsense/answer/7670312)
の「AMP ページ向けの広告のパーソナライズ設定」を参考にしました。

## script 追加

amp-geo と amp-consent を使うため、
`<script async custom-element="amp-ad" src="https://cdn.ampproject.org/v0/amp-ad-0.1.js"></script>`
の前に以下を追加しました。

```
    <script async custom-element="amp-geo" src="https://cdn.ampproject.org/v0/amp-geo-0.1.js"></script>
    <script async custom-element="amp-consent" src="https://cdn.ampproject.org/v0/amp-consent-0.1.js"></script>
```

## 同意に基づいてパーソナライズド広告とパーソナライズされていない広告の配信を切り替える (失敗)

以下を追加して、
`amp-ad` に `data-block-on-consent` を追加してみたところ、
`myConsentFlow` 周りでエラーになりました。

```
<!-- First we need to set up the amp-geo extension. We define a group: `eea` which includes all European Economic Area countries. You will need to keep this list up-to-date as membership in the EEA may change over time. -->
<amp-geo layout="nodisplay">
  <script type="application/json">
    {
      "ISOCountryGroups": {
        "eea": [ "at", "be", "bg", "cy", "cz", "de", "dk", "ee", "es", "fi", "fr",
        "gb", "gr", "hr", "hu", "ie", "is", "it", "li", "lt", "lu", "lv", "mt", "nl",
        "no", "pl", "pt", "ro", "se", "si", "sk"]
      }
    }
  </script>
</amp-geo>

<!-- Next we need to setup the consent for users in the “eea” country group -->
<amp-consent layout="nodisplay" id="consent-element">
  <script type="application/json">
    {
      "consents": {
        "my_consent": {
          "promptIfUnknownForGeoGroup": "eea",
          "promptUI": "myConsentFlow"
        }
      }
    }
  </script>
</amp-consent>
```

## amp-consent 修正

[amp-consent](https://github.com/ampproject/amphtml/blob/3cf0f5ad2a80b86b41aa634a03b9be27f8dea92d/extensions/amp-consent/amp-consent.md)
を参考にして、以下のように `consent-ui` に変更したところ、エラーは出なくなりました。

```
<!-- Next we need to setup the consent for users in the “eea” country group -->
<amp-consent layout="nodisplay" id="consent-element">
    <script type="application/json">
     {
         "consents": {
             "my_consent": {
                 "promptIfUnknownForGeoGroup": "eea",
                 "promptUI": "consent-ui"
             }
         }
     }
    </script>
    <div id="consent-ui">
        <button on="tap:consent-element.accept" role="button">Accept</button>
        <button on="tap:consent-element.reject" role="button">Reject</button>
        <button on="tap:consent-element.dismiss" role="button">Dismiss</button>
    </div>
</amp-consent>
```

## data-block-on-consent 追加

`amp-ad`, `amp-auto-ads`, `amp-analytics` に `data-block-on-consent` を追加しました。

## amp-auto-ads の設定

直接は関係ないのですが、メールで来ていた説明にしたがって、
「広告の設定」の「自動広告」の「AMP 自動広告」の「新しいフォーマットを自動的に取得する」に
チェックが入っていなかったのをチェックを入れました。

`amp-auto-ads` がきいていなかったのは、これできくようになりそうです。

## まとめ

AMP のページでも、ちょっと追加すれば簡単に GDPR 対応できるようです。

自動広告はタグの追加だけではなく、設定の確認も必要だったようです。
