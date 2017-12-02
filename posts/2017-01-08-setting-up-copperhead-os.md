---
title: "Nexus 9にCopperhead OSを導入"
date: "2017-01-08"
tags:
---

[Copperhead OS](https://copperhead.co/android/)はAndroidをベースにした
セキュリティ・プライバシーを意識したスマートフォンOSです。

- exploit mitigationの強化
- MACアドレス・ホスト名のランダム化、
- プライバシーを重視した初期設定

等[^1]が導入されています。Google Playへの依存が解消され、代わりに
F-Droidアプリストアが採用されています。最近ですとTor Projectによる
[TorをAndroidに組み込むプロジェクトMission Improbable](https://blog.torproject.org/blog/mission-improbable-hardening-android-security-and-privacy)
で採用され話題になりましたね。

さて、電子書籍や論文を読む端末がほしかったのでCopperhead OSがサポートしている
Nexus 9を購入し、Arch Linuxマシンに繋いでインストールしてみました。
入れる手順としては基本的に[公式ドキュメント](https://copperhead.co/android/docs/install)
に書いてある通りです。ハマりどころはfastboot周りがsudo権限でしか
Nexus 9を認識しないのと、タブレットにつなぐマシンのメモリが少ない[^2]場合
flash-all.shが途中でコケるってところぐらいです。

```
$ yaourt -Syy
$ yaourt -S jre8-openjdk #java-runtime-commonだとデフォルトでjava7が入るので注意
```

```
$ mkdir ~/sdk
$ cd ~/sdk
$ wget https://dl.google.com/android/repository/tools_r25.2.3-linux.zip
$ unzip tools_r25.2.3-linux.zip
$ tools/bin/sdkmanager --update
$ tools/bin/sdkmanager 'build-tools;25.0.2'
$ export PATH="$PATH:$HOME/sdk/tools:$HOME/sdk/tools/bin:$HOME/sdk/platform-tools:$HOME/sdk/build-tools/25.0.2"
$ export ANDROID_HOME="$HOME/sdk"
$ sdkmanager --update
```

[ダウンロードページ](https://copperhead.co/android/downloads)
から最新版のFactory imageを入手します。

```
$ gpg --recv-keys 65EEFE022108E2B708CBFCF7F9E712E59AF5F22A
$ gpg --verify flounder-factory-2017.01.04.05.44.59.tar.xz{.sig,}
```

Nexusでデベロッパモードを有効にし、OEMアンロックを有効にした上でパソコンに
接続します。

```
$ adb reboot bootloader
$ sudo fastboot oem unlock
$ tar xvf flounder-factory-2017.01.04.05.44.59.tar.xz
$ cd flounder-n4f26j/
$ mkdir tmp
$ TMPDIR=$PWD/tmp sudo ./flash-all.sh
$ sudo fastboot oem lock
```

以上です。とりあえずF-Droidから次のアプリを入れました：

- Amaze
- LeafPic
- MuPDF
- NewPipe
- Open Camera
- OsmAnd~
- Termux
- VLC

引き続きいじっていきます。

![](images/2017-01-08-nexus.png)

[^1]: [https://copperhead.co/android/docs/technical_overview](https://copperhead.co/android/docs/technical_overview)

[^2]: メモリを2GBから4GBに増やしたらうまくいきました。

