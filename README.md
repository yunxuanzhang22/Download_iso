# Ubuntu ISO Downloader

适用于 Linux 服务器的 Ubuntu 镜像定时下载脚本。

仓库内现提供两个脚本版本：

- Ubuntu / Debian 使用
- RedHat / CentOS 使用

## 仓库地址

<https://github.com/yunxuanzhang22/Download_iso>

## 功能特点

- 支持国内源 / 国外源下载
- 默认根据公网 IP 自动判断下载源
- 中国 IP 默认使用国内源，非中国 IP 默认使用国外源
- 国内源默认使用清华大学开源软件镜像站
- 国外源默认使用 Ubuntu 官方发布站
- 默认下载目录为 `/data/iso`
- 下载目录不存在时自动创建
- 支持下载完成后自动删除文件
- 支持通过交互方式安装、卸载 crontab 定时任务
- 支持每日 / 每周 / 每月执行
- 支持手动执行一次下载任务

## 使用说明

### Ubuntu / Debian

#### 交互运行

```bash
wget https://raw.githubusercontent.com/yunxuanzhang22/Download_iso/main/ubuntu_debian_iso_downloader.sh && chmod +x ubuntu_debian_iso_downloader.sh && ./ubuntu_debian_iso_downloader.sh
```

#### 只执行一次下载

```bash
wget https://raw.githubusercontent.com/yunxuanzhang22/Download_iso/main/ubuntu_debian_iso_downloader.sh && chmod +x ubuntu_debian_iso_downloader.sh && ./ubuntu_debian_iso_downloader.sh --run --source global --dir /data/iso --delete-after y
```

### RedHat / CentOS

#### 交互运行

```bash
wget https://raw.githubusercontent.com/yunxuanzhang22/Download_iso/main/redhat_centos_iso_downloader.sh && chmod +x redhat_centos_iso_downloader.sh && ./redhat_centos_iso_downloader.sh
```

#### 只执行一次下载

```bash
wget https://raw.githubusercontent.com/yunxuanzhang22/Download_iso/main/redhat_centos_iso_downloader.sh && chmod +x redhat_centos_iso_downloader.sh && ./redhat_centos_iso_downloader.sh --run --source global --dir /data/iso --delete-after y
```

## 日志目录

```bash
/var/log/ubuntu_iso_downloader
/var/log/ubuntu_iso_downloader/download.log
```

## 适用系统

### Ubuntu / Debian 脚本
- Debian
- Ubuntu

### RedHat / CentOS 脚本
- CentOS
- RedHat
- Rocky Linux
- AlmaLinux
