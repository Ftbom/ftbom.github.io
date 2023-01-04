# 在Termux中安装LANraragi


<p style="text-align: center;">
    <img src="/blog_images/Lanraragi_Termux.png" alt="Lanraragi_Termux.png">
</p>

[LANraragi](https://github.com/Difegue/LANraragi)是开源的漫画管理服务器，开发者提供了多种安装方式供选择。本文介绍如何在Termux中安装LANraragi，实现对Android手机内的漫画进行管理。

## 安装Termux及Ubuntu发行版

[Termux](https://termux.dev)是Android系统上的一个高级终端模拟器，可以运行很多Linux系统的软件，还可通过proot安装各种Linux系统发行版。推荐通过Github安装Termux软件。

{{< admonition warning >}}
第一次打开Termux若初始化失败，请使用代理
{{< /admonition >}}

安装完成后，首先使Termux获取储存权限：

```bash
termux-setup-storage
```

安装proot-distro：

```bash
pkg install proot-distro
```

然后安装Ubuntu

```
proot-distro install ubuntu
```

安装完成后，通过如下命令可进入Ubuntu

```bash
proot-distro login ubuntu
```

## 安装LANraragi

采用源码安装的方式安装LANraragi。

首先，进入Ubuntu并更新软件源：

```bash
proot-distro login ubuntu
apt update
```

首先安装LANraragi所需的依赖项：

```bash
apt install git curl build-essential make gnupg pkg-config cpanminus redis-server libarchive-dev imagemagick webp libssl-dev zlib1g-dev perlmagick ghostscript
```

然后安装npm和nodejs：

```bash
curl -sL install-node.vercel.app/lts | bash
```

安装redis：

```bash
apt install redis
```

克隆Git仓库：

```bash
git clone -b master http://github.com/Difegue/LANraragi /home/koyomi/lanraragi
```

打开目录并进行编译安装：

```bash
cd /home/koyomi/lanraragi && npm run lanraragi-installer install-full
```

编译需要30-60分钟。

若需要对LANraragi进行更新：

```bash
git clone -b master http://github.com/Difegue/LANraragi lanraragi
cp -fr lanraragi /home/koyomi/
npm run lanraragi-installer install-full
```

## 运行LANraragi

通过以下命令运行LANraragi：

```bash
redis-server /etc/redis/redis.conf
cd /home/koyomi/lanraragi && npm start
```

## 设置档案位置

若已通过以下命令使Termux获取储存权限：

```bash
termux-setup-storage
```

则在Ubuntu的`/sdcard`目录下可以看到Android系统的文件，在LANraragi的设置中设置成对应的漫画目录即可。
