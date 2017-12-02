---
title: "Setting up a Windows VM"
date: "2017-02-12"
---

# Install Virtualbox Guest Additions and [VirtIO drivers](https://fedoraproject.org/wiki/Windows_Virtio_Drivers)

# [Install Chocolatey](https://chocolatey.org/install)

```
$ Set-ExecutionPolicy -ExecutionPolicy Unrestricted
$ iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
$ Set-ExecutionPolicy -ExecutionPolicy Restricted
```

# Install applications

```
$ cinst -y packages.config
```

packages.config
```
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="emet" />
  <package id="sysinternals" />
  <package id="git" />
  <package id="vlc" />
  <package id="sumatrapdf" />
  <package id="googlechrome" />
  <package id="7zip.install" />
  <package id="googlejapaneseinput" />
  <package id="linqpad" />
  <package id="VisualStudio2015Community" />
  <package id="unity" />
</packages>
```

# Enable automatic login

```
$ AutoLogon.exe
```

# Referenced

- [Chocolateyでパッケージ管理](http://qiita.com/basabasa/items/0c29df0f176e48f34812)

