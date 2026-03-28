# Ubuntu ISO Downloader

适用于 Debian / Ubuntu 系列系统的 Ubuntu 镜像定时下载脚本。

脚本支持根据公网 IP 自动判断使用国内源或国外源，并通过交互方式安装或卸载 crontab 定时任务。

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
- 支持通过交互方式安装、卸载定时任务
- 支持每日 / 每周 / 每月执行
- 支持手动执行一次下载任务

## 使用说明

```bash
wget https://raw.githubusercontent.com/yunxuanzhang22/Download_iso/main/ubuntu_iso_downloader.sh && chmod +x ubuntu_iso_downloader.sh && ./ubuntu_iso_downloader.sh
```

## 日志目录

```bash
/var/log/ubuntu_iso_downloader
/var/log/ubuntu_iso_downloader/download.log
```

## 适用系统

- Debian
- Ubuntu
