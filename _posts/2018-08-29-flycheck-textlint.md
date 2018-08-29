---
layout: post
title: "flycheck で textlint を使う設定をした"
date: 2018-08-29 23:38 +0900
comments: true
category: blog
tags: emacs textlint
---
以前から使おうと思っていて、
flycheck との組み合わせ方が難しくて後回しになっていた
textlint を、
[textlint 11リリース](https://efcl.info/2018/07/23/textlint-11/)
という記事を見たのをきっかけに使い始めました。

<!--more-->

## 確認バージョン

- macOS 10.13.6
- GNU Emacs 26.1
- anyenv, nodenv
- node v10.9.0
- textlint v11.0.0
- textlint-rule-preset-ja-technical-writing 3.1.0
- textlint-rule-preset-ja-spacing 2.0.1

## node のインストール

nodenv の使い方は rbenv とほぼ同じなので以下の手順で現状の最新版を入れました。

```
nodenv install 10.9.0
nodenv global 10.9.0
```

## textlint のインストールと動作確認

そして
[textlint の公式サイトの Getting Started with textlint](https://textlint.github.io/docs/getting-started.html)
の手順に従って、
使いたいレポジトリ (今回は znz/blog.n-z.jp) のトップで
以下のように初期設定しました。

```
npm init -y
npm install --save-dev textlint
npm install --save-dev textlint-rule-no-todo
npx textlint --init
```

そして、以下のファイルを `file.md` として保存して、
`npx textlint file.md` で動作確認しました。

```markdown
# file.md

- [ ] Write usage instructions

`- [ ]` is a code and not error.
```

ここで入れた `textlint-rule-no-todo` は最終的には使っていないので、
消し方を探してみたところ、
`npm uninstall --save-dev textlint-rule-no-todo`
で `package.json` と `package-lock.json` から消せました。

## preset

どの preset を使えば良いのかがわからなかったのも、
textlint をまだ使っていなかった理由だったのですが、
リリース記事にあった
[textlint-rule-preset-ja-technical-writing](https://github.com/textlint-ja/textlint-rule-preset-ja-technical-writing)
が厳しめで、
ちゃんと動いているかどうか見えてほしい使い始めに良さそうと思って、
使ってみることにしました。

緩めで始めたいのなら、
[textlint-rule-preset-japanese](https://github.com/textlint-ja/textlint-rule-preset-japanese)
が良さそうでした。

preset を探してみると
[textlint-rule-preset-ja-spacing](https://github.com/textlint-ja/textlint-rule-spacing)
というのもあったので使ってみることにしました。

## .textlintrc

インラインマークアップの都合で「、」の直後に半角文字がくる時もスペースを入れるようにしているので、
`exceptPunctuation` は `false` にしました。

コードの前後にも空白があった方が良いので、 `ja-space-around-code` は両方 `true` にしました。

```json
{
  "rules": {
    "preset-ja-technical-writing": true,
    "preset-ja-spacing": {
      "ja-space-between-half-and-full-width": {
        "space": "always",
        "exceptPunctuation": false
      },
      "ja-space-around-code": {
        "before": true,
        "after": true
      }
    }
  }
}
```

とりあえずこの設定で使い始めて様子をみて変えていくつもりです。

## flycheck の設定

ネット上でみつけた設定のうち、
引数でルールを直接指定した部分は `.textlintrc` を使うなら不要と思って、
外したものを設定しました。

```elisp
(flycheck-define-checker textlint
  "A linter for prose."
  :command ("textlint" "--format" "unix"
             ;; "--rule" "no-mix-dearu-desumasu" "--rule" "max-ten" "--rule" "spellcheck-tech-word"
             source-inplace)
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ": "
     (id (one-or-more (not (any " "))))
     (message (one-or-more not-newline)
       (zero-or-more "\n" (any " ") (one-or-more not-newline)))
     line-end))
  :modes (text-mode markdown-mode gfm-mode))
(add-to-list 'flycheck-checkers 'textlint)
```

## パス設定

[Enable npx with eslint](https://github.com/flycheck/flycheck/issues/1428)
にあるように `npx` を使うという手もありそうですが、
`eslint` を試そうとしていたときにうまくいった
[add-node-modules-path](https://melpa.org/#/add-node-modules-path) を使って、
以下のようにパスを通すようにしています。

```elisp
(with-eval-after-load 'markdown-mode
  (add-hook 'gfm-mode-hook #'add-node-modules-path)
  (add-hook 'markdown-mode-hook #'add-node-modules-path))
```

`anyenv` には、以下のようにしてパスを通しています。

```elisp
(defun my-add-to-path (path)
  (when (file-directory-p path)
    (setenv "PATH" (concat path ":" (getenv "PATH")))
    (add-to-list 'exec-path path)))

;; anyenv
(my-add-to-path (expand-file-name "~/.anyenv/bin"))
(mapc #'my-add-to-path
  (mapcar #'expand-file-name
    (file-expand-wildcards "~/.anyenv/envs/*/bin")
    ))
(mapc #'my-add-to-path
  (mapcar #'expand-file-name
    (file-expand-wildcards "~/.anyenv/envs/*/shims")
    ))
```

## まとめ

とりあえずこれで flycheck で textlint が動くようになったので、
使い続けてみたいと思っています。
