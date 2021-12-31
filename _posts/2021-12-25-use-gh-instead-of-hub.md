---
layout: post
title: "hubコマンドの代わりにghコマンドを使い始めた"
date: 2021-12-25 12:00 +0900
comments: true
category: blog
tags: github
---
以前の環境では主に `hub` コマンドを使っていて、一部だけ `gh` コマンドを使っていたのですが、環境を作りなおしているときに `hub` コマンドの最初の認証で Not Found になったのをきっかけに、 `gh` コマンドだけに移行することにしました。

<!--more-->

## 動作確認環境

- macOS Monterey 12.1
- git version 2.32.0 (Apple Git-132)
- hub version refs/heads/master
- gh version 2.4.0 (2021-12-21)

## gh の初期設定

`hub fork` の代わりに `gh repo fork` を使おうとすると、 `gh auth login` を実行するように説明がでてきたので、実行するとブラウザーでログインして OAuth の許可をすると `gh` が使えるようになりました。



```console
$ gh repo fork
Welcome to GitHub CLI!

To authenticate, please run `gh auth login`.
$ gh auth login
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations? HTTPS
? Authenticate Git with your GitHub credentials? Yes
? How would you like to authenticate GitHub CLI? Login with a web browser

! First copy your one-time code: 472B-8640
- Press Enter to open github.com in your browser...
✓ Authentication complete. Press Enter to continue...

- gh config set -h github.com git_protocol https
✓ Configured git protocol
✓ Logged in as znz
```

## fork

`gh repo fork` を実行すると、 `hub fork` と同様に自分のアカウントに `fork` がなければ作成されて、 `remote` に設定されました。
しかし、 `hub fork` では `origin` は `fork` 元のままで、自分のアカウントが `remote` の名前になった `remote` が追加されて、私の場合だと `remote` が `origin` と `znz` になっていたのですが、 `gh repo fork` だと元が `upstream` に改名されて、自分の `fork` が `origin` に設定されました。

```console
$ gh repo fork
! znz/stdgems already exists
? Would you like to add a remote for the fork? Yes
✓ Added remote origin
$ git remote -v
origin	git@github.com:znz/stdgems.git (fetch)
origin	git@github.com:znz/stdgems.git (push)
upstream	https://github.com/janlelis/stdgems (fetch)
upstream	git@github.com:janlelis/stdgems (push)
```

## pull request 作成

通常の `git` の操作でブランチを作成して `push` した後、 `gh pr create` で pull request を作成しました。
fix typo だけで、コミットログと同じ内容で pull request を作成すれば良さそうだったので、 `--fill` を使いました。

```console
$ git switch -c fix-typo
Switched to a new branch 'fix-typo'
$ find . -type f | xargs ~/go/bin/misspell
./default_gems.json:1796:22: "Explicitely" is a misspelling of "Explicitly"
$ sd -s Explicitely Explicitly default_gems.json
$ git diff
diff --git a/default_gems.json b/default_gems.json
index bd125e7..a82282c 100644
--- a/default_gems.json
+++ b/default_gems.json
@@ -1793,7 +1793,7 @@
	   "gem": "weakref",
	   "native": false,
	   "autoRequire": false,
-      "description": "Explicitely allow objects to be garbage collected",
+      "description": "Explicitly allow objects to be garbage collected",
	   "mriSourcePath": "lib/weakref.rb",
	   "sourceRepository": "https://github.com/ruby/weakref",
	   "rubygemsLink": "https://rubygems.org/gems/weakref",
$ git log
$ git commit -m "Fix a typo" default_gems.json
[fix-typo b1bcaaa] Fix a typo
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git push
fatal: The current branch fix-typo has no upstream branch.
To push the current branch and set the remote as upstream, use

	git push --set-upstream origin fix-typo

$ git push --set-upstream origin fix-typo
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 10 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 957 bytes | 957.00 KiB/s, done.
Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
remote:
remote: Create a pull request for 'fix-typo' on GitHub by visiting:
remote:      https://github.com/znz/stdgems/pull/new/fix-typo
remote:
To github.com:znz/stdgems.git
 * [new branch]      fix-typo -> fix-typo
Branch 'fix-typo' set up to track remote branch 'fix-typo' from 'origin'.
$ gh pr create --fill

Creating pull request for znz:fix-typo into main in janlelis/stdgems

https://github.com/janlelis/stdgems/pull/11
```

## gh pr create のヘルプ

`gh pr create` の使い方は以下のようにヘルプをたどって確認しました。

```console
$ gh
Work seamlessly with GitHub from the command line.

USAGE
  gh <command> <subcommand> [flags]

CORE COMMANDS
  browse:     Open the repository in the browser
  codespace:  Connect to and manage your codespaces
  gist:       Manage gists
  issue:      Manage issues
  pr:         Manage pull requests
  release:    Manage GitHub releases
  repo:       Create, clone, fork, and view repositories

ACTIONS COMMANDS
  actions:    Learn about working with GitHub Actions
  run:        View details about workflow runs
  workflow:   View details about GitHub Actions workflows

ADDITIONAL COMMANDS
  alias:      Create command shortcuts
  api:        Make an authenticated GitHub API request
  auth:       Login, logout, and refresh your authentication
  completion: Generate shell completion scripts
  config:     Manage configuration for gh
  extension:  Manage gh extensions
  gpg-key:    Manage GPG keys
  help:       Help about any command
  secret:     Manage GitHub secrets
  ssh-key:    Manage SSH keys

FLAGS
  --help      Show help for command
  --version   Show gh version

EXAMPLES
  $ gh issue create
  $ gh repo clone cli/cli
  $ gh pr checkout 321

ENVIRONMENT VARIABLES
  See 'gh help environment' for the list of supported environment variables.

LEARN MORE
  Use 'gh <command> <subcommand> --help' for more information about a command.
  Read the manual at https://cli.github.com/manual

FEEDBACK
  Open an issue using 'gh issue create -R github.com/cli/cli'

$ gh pr
Work with GitHub pull requests

USAGE
  gh pr <command> [flags]

CORE COMMANDS
  checkout:   Check out a pull request in git
  checks:     Show CI status for a single pull request
  close:      Close a pull request
  comment:    Create a new pr comment
  create:     Create a pull request
  diff:       View changes in a pull request
  edit:       Edit a pull request
  list:       List and filter pull requests in this repository
  merge:      Merge a pull request
  ready:      Mark a pull request as ready for review
  reopen:     Reopen a pull request
  review:     Add a review to a pull request
  status:     Show status of relevant pull requests
  view:       View a pull request

FLAGS
  -R, --repo [HOST/]OWNER/REPO   Select another repository using the [HOST/]OWNER/REPO format

INHERITED FLAGS
  --help   Show help for command

ARGUMENTS
  A pull request can be supplied as argument in any of the following formats:
  - by number, e.g. "123";
  - by URL, e.g. "https://github.com/OWNER/REPO/pull/123"; or
  - by the name of its head branch, e.g. "patch-1" or "OWNER:patch-1".

EXAMPLES
  $ gh pr checkout 353
  $ gh pr create --fill
  $ gh pr view --web

LEARN MORE
  Use 'gh <command> <subcommand> --help' for more information about a command.
  Read the manual at https://cli.github.com/manual

$ gh pr create --help
Create a pull request on GitHub.

When the current branch isn't fully pushed to a git remote, a prompt will ask where
to push the branch and offer an option to fork the base repository. Use `--head` to
explicitly skip any forking or pushing behavior.

A prompt will also ask for the title and the body of the pull request. Use `--title`
and `--body` to skip this, or use `--fill` to autofill these values from git commits.

Link an issue to the pull request by referencing the issue in the body of the pull
request. If the body text mentions `Fixes #123` or `Closes #123`, the referenced issue
will automatically get closed when the pull request gets merged.

By default, users with write access to the base repository can push new commits to the
head branch of the pull request. Disable this with `--no-maintainer-edit`.


USAGE
  gh pr create [flags]

FLAGS
  -a, --assignee login       Assign people by their login. Use "@me" to self-assign.
  -B, --base branch          The branch into which you want your code merged
  -b, --body string          Body for the pull request
  -F, --body-file file       Read body text from file
  -d, --draft                Mark pull request as a draft
  -f, --fill                 Do not prompt for title/body and just use commit info
  -H, --head branch          The branch that contains commits for your pull request (default: current branch)
  -l, --label name           Add labels by name
  -m, --milestone name       Add the pull request to a milestone by name
	  --no-maintainer-edit   Disable maintainer's ability to modify pull request
  -p, --project name         Add the pull request to projects by name
	  --recover string       Recover input from a failed run of create
  -r, --reviewer handle      Request reviews from people or teams by their handle
  -t, --title string         Title for the pull request
  -w, --web                  Open the web browser to create a pull request

INHERITED FLAGS
	  --help                     Show help for command
  -R, --repo [HOST/]OWNER/REPO   Select another repository using the [HOST/]OWNER/REPO format

EXAMPLES
  $ gh pr create --title "The bug is fixed" --body "Everything works again"
  $ gh pr create --reviewer monalisa,hubot  --reviewer myorg/team-name
  $ gh pr create --project "Roadmap"
  $ gh pr create --base develop --head monalisa:feature

LEARN MORE
  Use 'gh <command> <subcommand> --help' for more information about a command.
  Read the manual at https://cli.github.com/manual
```

## 感想

`hub` は開発が終了していて、 `gh` コマンドへの乗り換えが推奨されてからかなり時間がたっていましたが、環境を変えたのをきっかけに乗り換えてみたところ、色々違いはありつつ、最低限の乗り換えはできました。

これからは `gh` コマンドの使い方を調べつつ、徐々に使っていこうと思っています。
