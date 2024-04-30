---
layout: post
title: "Ubuntu 24.04のriscv64版をqemuで動かした"
date: 2024-04-30 09:30 +0900
comments: true
category: blog
tags: linux ubuntu qemu
---
Ubuntu の riscv64 版を qemu で動かす方法を、リリースされたばかりの Ubuntu 24.04 で確認しなおしました。

[LILO&東海道らぐオフラインミーティング 2024-04-27](https://lilo.connpass.com/event/316818/) で発表したものをブログ記事の形式に変更したものです。

<!--more-->

## 動作確認環境

### ホスト1

- Debian GNU/Linux 12 (bookworm)
- qemu-system* 1:7.2+dfsg-7+deb12u5
- libvirt-daemon 9.0.0-4
- u-boot-qemu 2023.01+dfsg-2
- cloud-image-utils 0.33-1

### ホスト2

- macOS Sonoma 14.4.1
- qemu 9.0.0

### ゲスト

- riscv64 の Ubuntu 24.04 LTS (noble)

riscv64 の Ubuntu 22.04.4 LTS (jammy)
で確認した内容も含まれています。

## ゲストイメージファイル

VM で動かすためのイメージは <https://cloud-images.ubuntu.com> からダウンロードできます。
`/${codename}/current/${codename}-server-cloudimg-${arch}.img` でデイリービルド版を使うと初回の `apt upgrade` の時間が短縮できるのでオススメです。

<https://cloud-images.ubuntu.com/releases/> にリリース版もあるので、基本デイリービルドでたまたま問題があるビルドだったらリリース版を選ぶぐらいでいいかと思います。

実機用のイメージは <https://cdimage.ubuntu.com/releases/> にあって、
`ubuntu-22.04.4-preinstalled-server-riscv64+unmatched.img.xz`
のような `unmatched` のイメージも同じように使えるようですが、
カーネルが `linux-virtual` と `linux-generic` で違っていたり、仮想環境では不要な無線 LAN 関係のパッケージが入っているなどの違いがあるようなので、
普通は cloud-images を使う方が良さそうでした。

## イメージをいい感じにする

`${codename}-server-cloudimg-${arch}.img` は qcow2 形式のファイルなので、
実運用に使うなら、
速度のため `qemu-img convert -f qcow2 -O raw "$orig" "$img"` のように raw に変換すると良さそうです。

ダウンロード直後はギリギリのディスクサイズなのでリサイズしないと、ちょっと `apt install` しただけであふれてしまうので、
ちょっと試すだけでも +5G ぐらい増やしておく必要がありそうです。
もっと使うなら `qemu-img resize "$img" 16G` で 16G とか 20G とかの必要な容量に増やしておく必要があります。

```
img=noble-server-cloudimg-riscv64.img
wget https://cloud-images.ubuntu.com/noble/current/$img
qemu-img resize "$img" +5G
```

## 最低限の起動確認

以下のようなコマンドで最低限の起動確認ができますが、ログインなどはできません。
GUI ありなら view から monitor (`compat_monitor0`) を選んで quit できますが、
`-nographic` なら Control-a c で monitor の `(qemu)` というプロンプトがでてくる状態に切り替えて `quit` で強制終了できます。

```
qemu-system-riscv64 -nographic -M virt -m 1G \
 -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
 -drive "if=virtio,format=qcow2,file=$img" -snapshot
```

- `-machine` (`-M`) は `virt` で良さそうです。
- `-m` は適当に増やしておきます。デフォルトの 128 だと、自動で進む linux カーネルの選択肢がでなくて起動できませんでした。
- `-kernel` は `u-boot` の `qemu-riscv64_smode` で起動できました。コマンドラインの例を探すと `-bios` に opensbi の `fw_jump.elf` を指定していることがありますが、なくても起動できたので不要そうです。
- 何もできない状態で書き込みが発生しても無駄なので、 `-snapshot` で書き込みは止めて起動だけの動作確認をしました。

## cloud-init でログイン準備

- 最低限の起動確認の方法だと、起動できるが root もパスワードがなくてログインできません。
- cloud-init で設定するため ISO ファイルを作成します。ISO ファイル名は何でも良いですが、ボリュームラベルは `cidata` か `CIDATA` にする必要があります。
- `-drive "if=virtio,format=raw,file=seed.iso"` のようにドライブを追加して起動すると初回起動の処理が実行されます。

```
mkdir config
echo "instance-id: $(uuidgen || echo i-abcdefg)" > config/meta-data
vi config/user-data
cloud-localds "seed.iso" config/user-data config/meta-data
```

### config/meta-data

cloud-init のドキュメントでは `instance-id` と `local-hostname` を指定していますが、
ホスト名は `user-data` の `hostname` の方が設定されるようなので、
`local-hostname` はなくても良さそうです。

`instance-id` は cloud-init の初回起動の処理を実行済みかどうかに使われるようなので、
何でも良さそうです。

### config/user-data

`user-data` についての詳細は cloud-init のドキュメントを参照してください。
<https://cloudinit.readthedocs.io/en/latest/reference/examples.html>
に例があるので、そこからコピーしてきて使うのが便利そうです。

shebang のようにファイルの先頭の `#cloud-config` は必須で、後は YAML ファイルになっています。

Ubuntu 環境なので自動作成されるデフォルトのユーザー名は `ubuntu` になっていて、
Debian 環境なら `debian` になります。

最低限パスワードの設定をしておけば、とりあえずログインして使えるようになります。
`ssh_import_id` まで入れておくと、パスワードなしで入れて楽です。

この例には入れていませんが、
`user-data` でパッケージのインストールなどの設定も入れていると、
シリアルコンソールでログインプロンプトがでてもすぐにはログインできなくて、
cloud-init の処理を待つ必要があります。

```yaml
#cloud-config

hostname: noble-riscv64

# user: ubuntu のパスワード設定
password: ubuntu
chpasswd: { expire: False }
ssh_pwauth: true

# 各種設定
timezone: Asia/Tokyo
locale: ja_JP.utf8

# 自分のssh鍵を設定
ssh_import_id:
  - gh:znz
```

## 起動

実際の起動は以下のようになります。

```
qemu-system-riscv64 -nographic -M virt -m 2G -smp 4 \
 -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
 -drive "if=virtio,format=qcow2,file=$img" \
 -drive "if=virtio,format=raw,file=seed.iso" \
 -device "virtio-net-device,netdev=net0" \
 -netdev "user,id=net0,hostfwd=tcp::2222-:22" \
 -device virtio-rng-pci \
 -snapshot
```

- 速度のため、メモリや CPU も増やしています。
- ssh で入ったり apt を使ったりするために、ネット接続も追加しています。「`ssh -o "StrictHostKeyChecking no" -p 2222 ubuntu@localhost`」でログイン可能です。
- RNG デバイスも指定することが多いので追加しています。

## macOS での起動

`uboot.elf` を適当なところからコピーしてきて、
`hdiutil makehybrid` で ISO ファイルを作成すれば同じように起動できます。
ISO ファイル作成方法の例に `-hfs` がついていることがありましたが、
認識されなかったときの cloud-init のログを確認すると、
`hblkid` で `TYPE="hfsplus"` に見えていると認識されないようなので、
`-hfs` はつけない方が良さそうです。

```
hdiutil makehybrid -o seed.iso -joliet -iso -default-volume-name cidata config/

qemu-system-riscv64 -M virt -m 2G -smp 4 \
 -kernel uboot.elf -drive "if=virtio,format=qcow2,file=$img" \
 -drive "if=virtio,format=raw,file=seed.iso" \
 -device "virtio-net-device,netdev=net0" \
 -netdev "user,id=net0,hostfwd=tcp::2222-:22" \
 -device virtio-rng-pci \
 -snapshot
```

## qemu-guest-agent 対応

<https://wiki.qemu.org/Features/GuestAgent> にあるように起動オプションに以下を追加して、
ゲスト側で `qemu-guest-agent` を入れると使えるようになります。

```
 -chardev "socket,path=/tmp/qga.sock,server=on,wait=off,id=qga0"
 -device virtio-serial
 -device "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"
```

cloud-init の user-data で自動インストールするなら、以下の設定を追加します。

```
package_update: true
package_upgrade: true

packages:
  - qemu-guest-agent
```

対応していると外から shutdown の指示などができるようになるので、
後述の `libvirt` 管理にするときには `qemu-guest-agent` パッケージのインストールはほぼ必須になりそうです。

## 9psetup でホストとのファイル共有

<https://wiki.qemu.org/Documentation/9psetup> でホストとのファイル共有の設定もしました。

qemu の起動オプションに以下のように追加しました。

```
 -virtfs "local,path=./shared,mount_tag=test_mount,security_model=mapped-xattr"
```

コマンドでのマウント確認は
`mount -t 9p -o trans=virtio test_mount /tmp/shared/ -oversion=9p2000.L,posixacl,msize=512000`
のようにしました。

大きい値を指定すると
`9pnet: Limiting 'msize' to 512000 as this is the maximum supported by transport virtio`
と言われるので、
`msize` は 512000 までにすると良さそうです。

user-data に以下のように追加しました。

```
mounts:
  - [ test_mount, /mnt/shared, "9p", "trans=virtio,version=9p2000.L,posixacl,msize=512000,nofail", "0", "0" ]
```

## その他の設定

コンソールのサイズが小さいままと認識されるので、
`user-data` で以前作成した `rsz` というシェル関数を追加するようにしています。

```
runcmd:
  - |
    if ! grep -q rsz /home/ubuntu/.bashrc; then
      cat >> /home/ubuntu/.bashrc <<'EOF'

    rsz () if [[ -t 0 ]]; then local escape r c prompt=$(printf '\e7\e[r\e[999;999H\e[6n\e8'); IFS='[;' read -sd R -p "$prompt" escape r c; stty cols $c rows $r; fi
    rsz
    EOF
    fi
```

## 自動起動のため libvirt 管理下に移行

実行したコマンドを抜き出すと以下のような感じで `libvirt` 管理下に入れて自動起動するようにしました。

基本的には qemu 直接と同じですが、以下のような点が違います。

- `virsh pool-list` が増えてしまうので、ディスクイメージを置く場所はまとめた。
- owner などはできるだけ `libvirt-qemu` を使うようにした。
- ネットワークは libvirt の default の `virbr0` を使うようにした。
- osinfo に bookworm より後にリリースされた ubuntu24.04 はないので ubuntu22.04 を使った。
- shared の owner は初期ユーザーの ubuntu から使いやすいように 1000 にした。

```
sudo apt install libvirt-daemon-system virtinst libvirt-clients

storage_dir=/srv/libvirt-qemu-images
base=noble-server-cloudimg-riscv64.img
name=noble-riscv64

sudo install -m 755 -o libvirt-qemu -g libvirt-qemu -d "$storage_dir"
img="$storage_dir/$name.img"
if [ ! -f "$img" ]; then
    sudo qemu-img convert -f qcow2 -O raw "$base" "$img"
    sudo qemu-img resize "$img" 16G
    sudo chown libvirt-qemu:libvirt-qemu "$img"
fi

sudo virsh net-start default

cidata="$storage_dir/$name.iso"
sudo cloud-localds "$cidata" "$name/user-data" "$name/meta-data"

sudo install -m 1775 -o 1000 -g libvirt-qemu -d "shared"

sudo virt-install \
 --virt-type qemu \
 --machine virt \
 --arch "riscv64" \
 --boot "kernel=/usr/lib/u-boot/qemu-riscv64_smode/uboot.elf" \
\
 --name "$name" \
 --ram "2048" \
 --vcpu "2" \
 --osinfo "ubuntu22.04" \
\
 --import \
 --disk "path=$img,format=raw" \
 --disk "path=$cidata,device=cdrom" \
\
 --network "network=default" \
 --graphics none \
\
 --filesystem "type=mount,accessmode=mapped,source=$PWD/shared,target=test_mount"

sudo virsh net-autostart default
sudo virsh autostart "$name"
```

## snapd の削除

`snapd` は riscv64 だとあまり使えるパッケージもなくて、無駄にリソースを使うだけなので、削除しました。

Ubuntu 22.04.4 (jammy) だと `snap list` で出てきたパッケージをエラーにならない順番で削除してから `snapd` の apt パッケージを削除する必要がありましたが、
Ubuntu 24.04 (noble) だと何も入っていなかったので、いきなり `apt autoremove --purge -y snapd` で削除できました。

```
snap list
sudo snap remove lxd
sudo snap remove core20
sudo snap remove snapd
snap list
apt autoremove --purge -y snapd
```

## まとめ

Ubuntu の riscv64 版は qemu で簡単に試せます。

qemu は色々な機能があるので、必要に応じて調べて使うと便利そうです。

cloud-images.ubuntu.com にある amd64, arm64, armhf, ppc64el, riscv64, s390x はどれも同じように使えるはずです。
最低限の起動までは arch ごとに調査が必要ですが、起動できれば後は普通の Ubuntu として使えそうです。

起動前のディスクイメージの中をみると、root にもパスワードが設定されていなくて、ubuntu ユーザーも存在しないので、
cloud-init でログインできるように設定することが必須のようです。

cloud-init は試行錯誤しにくくて、
ansible などは試行錯誤しやくくて、他の環境での知識の流用がしやすいので、
ログインできるところまで cloud-init を使って、
他の設定はできるだけシェルスクリプトや ansible などの使い慣れた provisioner を使う方が楽かもしれません。
