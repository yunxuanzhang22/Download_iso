Ubuntu ISO Downloader

适用于 Debian / Ubuntu 系列系统 的 Ubuntu 镜像定时下载脚本。
脚本支持根据公网 IP 自动判断使用 国内源 或 国外源，并通过交互方式安装或卸载 crontab 定时任务。

仓库地址

https://github.com/yunxuanzhang22/Download_iso

───

功能特点

• 支持国内源 / 国外源下载
• 默认根据公网 IP 自动判断下载源
• 中国 IP：默认使用国内源
• 非中国 IP：默认使用国外源
• 国内源默认使用 清华大学开源软件镜像站
• 国外源默认使用 Ubuntu 官方发布站
• 默认下载目录为 /data/iso
• 下载目录不存在时自动创建
• 支持下载完成后自动删除文件
• 支持通过交互方式安装定时任务
• 支持通过交互方式卸载定时任务
• 支持每日 / 每周 / 每月执行
• 适用于 Debian / Ubuntu 系统
• 支持手动执行一次下载任务

───

默认镜像

脚本默认下载的 Ubuntu ISO 镜像为：

ubuntu-24.04.2-live-server-amd64.iso

对应脚本中的默认参数为：

ISO_FILE="ubuntu-24.04.2-live-server-amd64.iso"
ISO_PATH="24.04.2/${ISO_FILE}"

───

修改镜像方法

如需修改下载的 Ubuntu 镜像版本、架构或类型，只需要修改脚本中的以下两个变量：

ISO_FILE="ubuntu-24.04.2-live-server-amd64.iso"
ISO_PATH="24.04.2/${ISO_FILE}"

示例 1：修改为 Ubuntu 22.04.5 Server 版本

ISO_FILE="ubuntu-22.04.5-live-server-amd64.iso"
ISO_PATH="22.04.5/${ISO_FILE}"

示例 2：修改为 Ubuntu Desktop 版本

ISO_FILE="ubuntu-24.04.2-desktop-amd64.iso"
ISO_PATH="24.04.2/${ISO_FILE}"

修改完成后，重新执行脚本即可。

───

快速开始

方式一：下载后直接执行交互菜单

apt update && apt install -y git bash curl wget && \
git clone https://github.com/yunxuanzhang22/Download_iso.git && \
cd Download_iso && \
chmod +x ubuntu_iso_downloader.sh && \
bash ubuntu_iso_downloader.sh

方式二：如果仓库已经存在，先更新再执行

cd Download_iso && \
git pull && \
chmod +x ubuntu_iso_downloader.sh && \
bash ubuntu_iso_downloader.sh

方式三：手动执行一次下载任务

使用国外源，下载到 /data/iso，下载完成后自动删除

git clone https://github.com/yunxuanzhang22/Download_iso.git && \
cd Download_iso && \
chmod +x ubuntu_iso_downloader.sh && \
bash ubuntu_iso_downloader.sh --run --source global --dir /data/iso --delete-after y

使用国内源，下载到 /data/iso，下载完成后保留文件

git clone https://github.com/yunxuanzhang22/Download_iso.git && \
cd Download_iso && \
chmod +x ubuntu_iso_downloader.sh && \
bash ubuntu_iso_downloader.sh --run --source cn --dir /data/iso --delete-after n

如果仓库已经存在，也可以直接执行一次下载

cd Download_iso && \
chmod +x ubuntu_iso_downloader.sh && \
bash ubuntu_iso_downloader.sh --run --source global --dir /data/iso --delete-after y

───

使用说明

交互执行

请使用 bash 执行，不要使用 sh：

bash ubuntu_iso_downloader.sh

如需调试：

bash -x ubuntu_iso_downloader.sh

为什么不要用 sh

错误示例：

sh ubuntu_iso_downloader.sh

在 Debian / Ubuntu 中，/bin/sh 通常指向的是 dash，而不是 bash。
dash 不支持脚本中的一些 Bash 特性，例如：

set -o pipefail

因此可能会报错：

set: Illegal option -o pipefail

正确方式：

bash ubuntu_iso_downloader.sh

或者：

chmod +x ubuntu_iso_downloader.sh
./ubuntu_iso_downloader.sh

───

交互菜单

执行脚本后会显示主菜单：

==============================================
Ubuntu 镜像定时下载脚本
==============================================
1. 安装定时任务
2. 卸载定时任务
0. 退出

安装定时任务时会依次提示：

请选择下载源 [cn=国内源 / global=国外源]（默认：自动判断）:
请输入下载目录（默认：/data/iso）:
下载完成后是否自动删除文件？[Y/n]（默认：是）:

请选择执行周期：
1. 每天执行
2. 每周执行
3. 每月执行
请输入选项（默认：2）:

几点下载（默认：02:00:00）:

如果选择每周执行，还会继续提示：

每周几执行（例如：1,3；默认：1,3）:

───

Cron 示例

每天凌晨 2 点执行

0 2 * * * /bin/bash /root/ubuntu_iso_downloader.sh --run --source global --dir "/data/iso" --delete-after y >> /var/log/ubuntu_iso_downloader/download.log 2>&1

每周一、周三凌晨 2 点执行

0 2 * * 1,3 /bin/bash /root/
[2026-03-29 0:16] adrian_clawbot: ubuntu_iso_downloader.sh --run --source global --dir "/data/iso" --delete-after y >> /var/log/ubuntu_iso_downloader/download.log 2>&1

每周日凌晨 2 点执行

0 2 * * 0 /bin/bash /root/ubuntu_iso_downloader.sh --run --source global --dir "/data/iso" --delete-after y >> /var/log/ubuntu_iso_downloader/download.log 2>&1

每月 1 号凌晨 2 点执行

0 2 1 * * /bin/bash /root/ubuntu_iso_downloader.sh --run --source global --dir "/data/iso" --delete-after y >> /var/log/ubuntu_iso_downloader/download.log 2>&1

───

默认行为说明

脚本默认逻辑如下：

• 自动识别公网 IP 所属国家
• 中国 IP 默认使用国内源
• 非中国 IP 默认使用国外源
• 默认下载目录：/data/iso
• 默认下载完成后删除：是
• 默认执行时间：02:00:00
• 默认执行周期：每周
• 默认每周执行日期：1,3

───

日志目录

默认日志目录：

/var/log/ubuntu_iso_downloader

下载日志：

/var/log/ubuntu_iso_downloader/download.log

───

适用系统

• Debian
• Ubuntu
