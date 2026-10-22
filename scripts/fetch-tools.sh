#!/usr/bin/env bash
# Download the open-source helper binaries (wibo and UASM) into tools/.
# Microsoft MASM/LINK/DEBUG are intentionally NOT downloaded.
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
TOOLS="$ROOT/tools"
mkdir -p "$TOOLS"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

WIBO_URL="https://github.com/decompals/wibo/releases/download/1.2.0/wibo-x86_64"
WIBO_SHA="13f86a2d618f0dbe67179d349625345eabf9b46450295cb4c904e49f6aff85af"
UASM_URL="https://github.com/Terraspace/UASM/releases/download/v2.57r/uasm257_linux64.zip"
UASM_SHA="e5518c3d20f7d0c99f834c80ff9a7d18795232bbf0e25b7c66e861ec8bd445ae"

fetch() {
    local url="$1" dest="$2"
    echo "下载: $url"
    curl -fL --http1.1 --retry 3 --connect-timeout 20 --max-time 300 "$url" -o "$dest"
}

verify() {
    local file="$1" sha="$2"
    echo "$sha  $file" | sha256sum -c - >/dev/null 2>&1
}

# ------------------------------------------------------------
# wibo (MIT) — required for running ML.EXE on Linux
# ------------------------------------------------------------
if [[ -f "$TOOLS/wibo" ]] && verify "$TOOLS/wibo" "$WIBO_SHA"; then
    echo "wibo: 已存在且校验通过"
else
    fetch "$WIBO_URL" "$TMP/wibo"
    verify "$TMP/wibo" "$WIBO_SHA" || { echo "错误: wibo 校验失败" >&2; exit 1; }
    install -m 0755 "$TMP/wibo" "$TOOLS/wibo"
    echo "wibo: 已安装到 $TOOLS/wibo"
fi

# ------------------------------------------------------------
# UASM (Sybase Open Watcom Public License) — optional alternative assembler
# ------------------------------------------------------------
if [[ -f "$TOOLS/uasm" ]] && verify "$TOOLS/uasm" "$UASM_SHA"; then
    echo "uasm: 已存在且校验通过"
else
    fetch "$UASM_URL" "$TMP/uasm.zip"
    if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$TMP/uasm.zip" -d "$TMP/uasm"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m zipfile -e "$TMP/uasm.zip" "$TMP/uasm"
    else
        echo "错误: 需要 unzip 或 python3 来解压 UASM" >&2
        exit 1
    fi
    uasm_bin="$(find "$TMP/uasm" -type f -name uasm -print -quit)"
    [[ -n "$uasm_bin" ]] || { echo "错误: UASM 压缩包里找不到 uasm" >&2; exit 1; }
    verify "$uasm_bin" "$UASM_SHA" || { echo "错误: UASM 校验失败" >&2; exit 1; }
    install -m 0755 "$uasm_bin" "$TOOLS/uasm"
    echo "uasm: 已安装到 $TOOLS/uasm"
fi

echo
echo "下一步："
echo "  1. 把你的合法 MASM 6.15 副本放到 $TOOLS/masm615/"
echo "     需要：ML.EXE  ML.ERR  LINK.EXE  LIB.EXE"
echo "  2. 把 DEBUG.EXE 放到 $TOOLS/dos/"
echo "  3. 运行：./scripts/check-env.sh"
echo "  4. 运行：./scripts/setup.sh"
echo
echo "本仓库不分发 Microsoft MASM/LINK/DEBUG；请使用你已获授权的副本。"
