---
layout: post
title: "rubocopの新しいcopsを無効にする設定をURLつきで生成した"
date: 2023-03-07 12:00 +0900
comments: true
category: blog
tags: ruby
---
`rubocop` のバージョンアップがしばらく放置されていて、一気に上げると offences が大量に出てしまいます。
offences に対応してから `rubocop` を上げようとすると、offences に対応中に対応済みの offences にひっかかるコードが追加される可能性があるということで、
先にひっかかる cop は無効にしておいて `rubocop` を上げる方が良さそうということで、
ひっかかる cop を `.rubocop_todo_yml` に追加するスクリプトを動かして対応しました。

<!--more-->

## 動作確認環境

- ruby 2.7.x
- rubocop 1.46.0
- その他 rubocop-rspec など

## rubocop 更新

以下のような感じで `rubocop` 関連の gem と依存する gem を更新しました。

```console
$ bundle update rubocop rubocop-ast rubocop-inflector rubocop-performance rubocop-rails rubocop-rspec json parallel parser rainbow regexp_parser rexml ruby-progressbar unicode-display_width --conservative
```

## rubocop で JSON 作成

`rubocop` の `--format` で `json` を指定してファイルに保存しました。
使わない情報も大量に保存されるので、ファイルが必要以上に大きくなりますが、
処理のしやすさを考えて JSON にしました。

```console
$ bundle exec rubocop -fj > tmp/r.json
```

## YAML に追記

以下のスクリプトで `.rubocop.yml` や `.rubocop_todo_yml` に設定がない cop だけ `Enabled: false` にする設定を `.rubocop_todo_yml` に追記しました。
後で対処するときに cop の説明を開きやすくしておくと便利かなと思って、
説明へのリンクの URL をコメントにつけています。

汎用的なものにする必要はなかったので、別 gem にわかれていない cop のドキュメントの `rubocop/1.46` のところはバージョンを直接埋め込んでいます。

```ruby
require 'json'
require 'yaml'

output = JSON.load_file('tmp/r.json')
rubocop_yml = YAML.load_file('.rubocop.yml')
rubocop_todo_yml = YAML.load_file('.rubocop_todo.yml')

cop_names = Hash.new(0)
output['files'].each do |h|
  h['offenses']&.each do |cop|
    cop_names[cop['cop_name']] += 1
  end
end

def cop_to_url(cop)
  case cop
  when /\A(RSpec|Rails|Capybara|Performance)\//
    gem = "rubocop-#{$1.downcase}"
    *dep, name = cop.downcase.split('/')
    "https://docs.rubocop.org/#{gem}/cops_#{dep.join('_')}.html\##{dep.join('')}#{name}"
  when /\A(?:Bundler|Gemspec|Layout|Lint|Metrics|Migration|Naming|Security|Style)\//
    dep, name = cop.downcase.split('/', 2)
    "https://docs.rubocop.org/rubocop/1.46/cops_#{dep}.html##{dep}#{name}"
  else
    raise cop
  end
end

pp cop_names.sort_by{[_2, _1]}
pp(
  'cop_names & .rubocop.yml' => cop_names.keys & rubocop_yml.keys,
  'cop_names & .rubocop_todo.yml' => cop_names.keys & rubocop_todo_yml.keys,
)

File.open('.rubocop_todo.yml', 'a') do |f|
  (cop_names.keys - rubocop_yml.keys - rubocop_todo_yml.keys).sort.each do |cop|
    url = cop_to_url(cop)
    f.puts <<~YAML

      # #{url}
      #{cop}:
        Enabled: false
    YAML
  end
end
```

## その後、個別対応

その後、 `Enabled: false` の設定を消しつつ、対応する pull request を別に作成していきました。
