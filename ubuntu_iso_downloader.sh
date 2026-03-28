#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SELF_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")"

DEFAULT_DOWNLOAD_DIR="/data/iso"
DEFAULT_DELETE_AFTER_DOWNLOAD="y"
DEFAULT_TIME="02:00:00"
DEFAULT_WEEK_DAYS="1,3"

ISO_FILE="ubuntu-24.04.2-live-server-amd64.iso"
ISO_PATH="24.04.2/${ISO_FILE}"

CN_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases"
GLOBAL_BASE_URL="https://releases.ubuntu.com"

LOG_DIR="/var/log/ubuntu_iso_downloader"
mkdir -p "$LOG_DIR"

CRON_TAG="UBUNTU_ISO_DOWNLOAD_JOB"

info()  { echo -e "\033[32m[INFO]\033[0m $*"; }
warn()  { echo -e "\033[33m[WARN]\033[0m $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*" >&2; }

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

normalize_yes_no() {
    local v
    v="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]' | xargs)"
    case "$v" in
        y|yes|1|true) echo "y" ;;
        n|no|0|false) echo "n" ;;
        *) echo "" ;;
    esac
}

validate_time() {
    local t="$1"
    [[ "$t" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$ ]]
}

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        info "目录不存在，已自动创建：$dir"
    fi
}

detect_country_code() {
    local country=""
    for url in \
        "https://ipinfo.io/country" \
        "https://ifconfig.co/country-iso" \
        "https://ipapi.co/country/"
    do
        country="$(curl -4 -fsSL --connect-timeout 5 --max-time 8 "$url" 2>/dev/null | tr -d '\r\n' || true)"
        country="$(trim "$country")"
        if [[ -n "$country" ]]; then
            echo "$country"
            return 0
        fi
    done
    echo "UNKNOWN"
}

detect_default_source() {
    local cc
    cc="$(detect_country_code)"
    if [[ "$cc" == "CN" ]]; then
        echo "cn"
    else
        echo "global"
    fi
}

build_cron_expr() {
    local mode="$1"
    local hh="$2"
    local mm="$3"
    local week_days="${4:-}"

    case "$mode" in
        daily)
            echo "$mm $hh * * *"
            ;;
        weekly)
            echo "$mm $hh * * $week_days"
            ;;
        monthly)
            echo "$mm $hh 1 * *"
            ;;
        *)
            return 1
            ;;
    esac
}

download_iso() {
    local source_mode="$1"
    local download_dir="$2"
    local delete_after="$3"

    local base_url url target_file tmp_file sha_url sha_file

    if [[ "$source_mode" == "cn" ]]; then
        base_url="$CN_BASE_URL"
    else
        base_url="$GLOBAL_BASE_URL"
    fi

    url="${base_url}/${ISO_PATH}"
    target_file="${download_dir}/${ISO_FILE}"
    tmp_file="${target_file}.part"
    sha_url="${base_url}/${ISO_PATH}.sha256"
    sha_file="${target_file}.sha256"

    ensure_dir "$download_dir"

    info "开始下载 Ubuntu ISO"
    info "下载源类型：$([[ "$source_mode" == "cn" ]] && echo '国内源' || echo '国外源')"
    info "下载地址：$url"
    info "保存路径：$target_file"

    if command -v wget >/dev/null 2>&1; then
        wget -c --show-progress -O "$tmp_file" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L --fail --retry 3 -C - -o "$tmp_file" "$url"
    else
        error "未找到 wget 或 curl，请先安装。"
        exit 1
    fi

    mv -f "$tmp_file" "$target_file"
    info "下载完成：$target_file"

    if curl -fsSL "$sha_url" -o "$sha_file" 2>/dev/null; then
        (
            cd "$download_dir"
            if sha256sum -c "$(basename "$sha_file")" --ignore-missing; then
                info "SHA256 校验通过"
            else
                warn "SHA256 校验失败，请人工确认"
            fi
        )
    else
        warn "未获取到 SHA256 文件，跳过校验"
    fi

    if [[ "$delete_after" == "y" ]]; then
        rm -f "$target_file" "$sha_file"
        info "根据策略，下载完成后已删除文件"
    else
        info "根据策略，已保留下载文件"
    fi
}

install_cron_job() {
    local cron_expr="$1"
    local cron_cmd="$2"

    local tmpfile
    tmpfile="$(mktemp)"

    crontab -l 2>/dev/null | grep -vF "# ${CRON_TAG}" | grep -vF "$SELF_PATH --run" > "$tmpfile" || true
    {
        echo "# ${CRON_TAG}"
        echo "${cron_expr} ${cron_cmd}"
    } >> "$tmpfile"

    crontab "$tmpfile"
    rm -f "$tmpfile"
}

uninstall_cron_job() {
    local tmpfile
    tmpfile="$(mktemp)"
    crontab -l 2>/dev/null | grep -vF "# ${CRON_TAG}" | grep -vF "$SELF_PATH --run" > "$tmpfile" || true
    crontab "$tmpfile"
    rm -f "$tmpfile"
    info "定时任务已卸载"
}

show_summary() {
    local source_mode="$1"
    local download_dir="$2"
    local delete_after="$3"
    local exec_time="$4"
    local mode="$5"
    local week_days="$6"

    echo
    echo "========== 下载任务配置 =========="
    echo "镜像文件      : $ISO_FILE"
    echo "下载源类型    : $([[ "$source_mode" == "cn" ]] && echo '国内源' || echo '国外源')"
    echo "下载目录      : $download_dir"
    echo "完成后删除    : $([[ "$delete_after" == "y" ]] && echo '是' || echo '否')"
    echo "执行时间      : $exec_time"
    case "$mode" in
        daily)   echo "执行周期      : 每天" ;;
        weekly)  echo "执行周期      : 每周 ${week_days}" ;;
        monthly) echo "执行周期      : 每月 1 号" ;;
    esac
    echo "================================="
    echo
}

# 供 cron 调用
if [[ "${1:-}" == "--run" ]]; then
    shift

    SOURCE_MODE=""
    DOWNLOAD_DIR="$DEFAULT_DOWNLOAD_DIR"
    DELETE_AFTER="$DEFAULT_DELETE_AFTER_DOWNLOAD"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --source)
                SOURCE_MODE="${2:-}"
                shift 2
                ;;
            --dir)
                DOWNLOAD_DIR="${2:-}"
                shift 2
                ;;
            --delete-after)
                DELETE_AFTER="${2:-}"
                shift 2
                ;;
            *)
                error "未知参数：$1"
                exit 1
                ;;
        esac
    done

    [[ -z "$SOURCE_MODE" ]] && SOURCE_MODE="$(detect_default_source)"
    DELETE_AFTER="$(normalize_yes_no "$DELETE_AFTER")"
    [[ -z "$DELETE_AFTER" ]] && DELETE_AFTER="$DEFAULT_DELETE_AFTER_DOWNLOAD"

    download_iso "$SOURCE_MODE" "$DOWNLOAD_DIR" "$DELETE_AFTER"
    exit 0
fi

# 主菜单
echo "=============================================="
echo " Ubuntu 镜像定时下载脚本"
echo "=============================================="
echo "1. 安装定时任务"
echo "2. 卸载定时任务"
echo "0. 退出"
read -r -p "请输入选项: " MENU_CHOICE
MENU_CHOICE="$(trim "${MENU_CHOICE:-}")"

case "$MENU_CHOICE" in
    1)
        ;;
    2)
        uninstall_cron_job
        exit 0
        ;;
    0)
        exit 0
        ;;
    *)
        warn "无效选项，程序退出"
        exit 1
        ;;
esac

DEFAULT_SOURCE_MODE="$(detect_default_source)"
DEFAULT_SOURCE_TEXT="$([[ "$DEFAULT_SOURCE_MODE" == "cn" ]] && echo "国内源" || echo "国外源")"

read -r -p "请选择下载源 [cn=国内源 / global=国外源]（默认：自动判断为 ${DEFAULT_SOURCE_TEXT}）: " SOURCE_MODE_INPUT
SOURCE_MODE_INPUT="$(trim "$SOURCE_MODE_INPUT")"

case "$SOURCE_MODE_INPUT" in
    "" ) SOURCE_MODE="$DEFAULT_SOURCE_MODE" ;;
    cn|CN ) SOURCE_MODE="cn" ;;
    global|GLOBAL|oversea|foreign ) SOURCE_MODE="global" ;;
    * )
        warn "输入无效，已自动使用默认判断结果：${DEFAULT_SOURCE_TEXT}"
        SOURCE_MODE="$DEFAULT_SOURCE_MODE"
        ;;
esac

read -r -p "请输入下载目录（默认：${DEFAULT_DOWNLOAD_DIR}）: " DOWNLOAD_DIR
DOWNLOAD_DIR="$(trim "${DOWNLOAD_DIR:-}")"
[[ -z "$DOWNLOAD_DIR" ]] && DOWNLOAD_DIR="$DEFAULT_DOWNLOAD_DIR"
ensure_dir "$DOWNLOAD_DIR"

read -r -p "下载完成后是否自动删除文件？[Y/n]（默认：是）: " DELETE_AFTER
DELETE_AFTER="$(normalize_yes_no "$DELETE_AFTER")"
[[ -z "$DELETE_AFTER" ]] && DELETE_AFTER="$DEFAULT_DELETE_AFTER_DOWNLOAD"

echo
echo "请选择执行周期："
echo "1. 每天执行"
echo "2. 每周执行"
echo "3. 每月执行"
read -r -p "请输入选项（默认：2）: " CYCLE_CHOICE
CYCLE_CHOICE="$(trim "${CYCLE_CHOICE:-}")"
[[ -z "$CYCLE_CHOICE" ]] && CYCLE_CHOICE="2"

read -r -p "几点下载（默认：${DEFAULT_TIME}）: " EXEC_TIME
EXEC_TIME="$(trim "${EXEC_TIME:-}")"
[[ -z "$EXEC_TIME" ]] && EXEC_TIME="$DEFAULT_TIME"

if ! validate_time "$EXEC_TIME"; then
    warn "时间格式无效，已使用默认时间：${DEFAULT_TIME}"
    EXEC_TIME="$DEFAULT_TIME"
fi

WEEK_DAYS="$DEFAULT_WEEK_DAYS"

case "$CYCLE_CHOICE" in
    1)
        MODE="daily"
        ;;
    2)
        MODE="weekly"
        read -r -p "每周几执行（例如：1,3；默认：${DEFAULT_WEEK_DAYS}）: " WEEK_DAYS_INPUT
        WEEK_DAYS_INPUT="$(trim "${WEEK_DAYS_INPUT:-}")"
        [[ -n "$WEEK_DAYS_INPUT" ]] && WEEK_DAYS="$WEEK_DAYS_INPUT"
        ;;
    3)
        MODE="monthly"
        ;;
    *)
        warn "输入无效，已默认按每周执行"
        MODE="weekly"
        read -r -p "每周几执行（例如：1,3；默认：${DEFAULT_WEEK_DAYS}）: " WEEK_DAYS_INPUT
        WEEK_DAYS_INPUT="$(trim "${WEEK_DAYS_INPUT:-}")"
        [[ -n "$WEEK_DAYS_INPUT" ]] && WEEK_DAYS="$WEEK_DAYS_INPUT"
        ;;
esac

HH="${EXEC_TIME%%:*}"
REST="${EXEC_TIME#*:}"
MM="${REST%%:*}"

CRON_EXPR="$(build_cron_expr "$MODE" "$HH" "$MM" "$WEEK_DAYS")"

show_summary "$SOURCE_MODE" "$DOWNLOAD_DIR" "$DELETE_AFTER" "$EXEC_TIME" "$MODE" "$WEEK_DAYS"

read -r -p "是否写入当前用户 crontab？[Y/n]（默认：是）: " CONFIRM_CRON
CONFIRM_CRON="$(normalize_yes_no "$CONFIRM_CRON")"
[[ -z "$CONFIRM_CRON" ]] && CONFIRM_CRON="y"

if [[ "$CONFIRM_CRON" == "y" ]]; then
    CRON_CMD="${SELF_PATH} --run --source ${SOURCE_MODE} --dir \"${DOWNLOAD_DIR}\" --delete-after ${DELETE_AFTER} >> ${LOG_DIR}/download.log 2>&1"
    install_cron_job "$CRON_EXPR" "$CRON_CMD"
    info "定时任务已安装成功"
    info "当前定时规则：$CRON_EXPR"
else
    warn "未写入 crontab"
fi

echo
info "手动测试命令："
echo "bash \"$SELF_PATH\" --run --source $SOURCE_MODE --dir \"$DOWNLOAD_DIR\" --delete-after $DELETE_AFTER"
