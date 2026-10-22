#!/usr/bin/env bash
# Check the local environment and the user-provided DOS toolchain.
set -uo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
TOOLS="${MASM615_LINUX_TOOLS:-$ROOT/tools}"
MASM615="${MASM615_DIR:-$TOOLS/masm615}"
DOSBIN="${DOSBIN_DIR:-$TOOLS/dos}"

if [[ -z "${DOSBOX:-}" ]]; then
    if [[ -x /snap/bin/dosbox-staging ]]; then
        DOSBOX=/snap/bin/dosbox-staging
    elif command -v dosbox-staging >/dev/null 2>&1; then
        DOSBOX="$(command -v dosbox-staging)"
    else
        DOSBOX=dosbox-staging
    fi
fi

fail=0
say_ok()   { printf '  [ok]      %s\n' "$*"; }
say_miss() { printf '  [missing] %s\n' "$*"; fail=1; }
say_opt()  { printf '  [optional] %s\n' "$*"; }

file_ci() {
    local dir="$1" name="$2"
    find "$dir" -maxdepth 1 -iname "$name" -print -quit 2>/dev/null || true
}

echo "仓库: $ROOT"
echo "宿主: $(uname -s) $(uname -m)"
echo

echo "基础命令:"
for c in bash git curl timeout find sed awk pkill mktemp sha256sum; do
    if command -v "$c" >/dev/null 2>&1; then
        say_ok "$c"
    else
        say_miss "$c"
    fi
done

echo
echo "DOSBox:"
if [[ "$DOSBOX" == */* ]]; then
    if [[ -x "$DOSBOX" ]]; then say_ok "$DOSBOX"; else say_miss "$DOSBOX"; fi
else
    if command -v "$DOSBOX" >/dev/null 2>&1; then
        say_ok "$(command -v "$DOSBOX")"
    else
        say_miss "dosbox-staging（或设置 DOSBOX=/path/to/dosbox-staging）"
    fi
fi
if [[ "$DOSBOX" == /snap/* || "$DOSBOX" == */snap/bin/* ]]; then
    if command -v snap >/dev/null 2>&1; then
        say_ok "snap（用于 AppArmor 下的超时清理）"
    else
        say_opt "snap 不可用；snap 版 DOSBox 超时清理可能失败"
    fi
fi

echo
echo "开源辅助工具:"
if [[ -x "$TOOLS/wibo" ]]; then say_ok "$TOOLS/wibo"; else say_miss "$TOOLS/wibo（运行 ./scripts/fetch-tools.sh）"; fi
if [[ -x "$TOOLS/uasm" ]]; then say_ok "$TOOLS/uasm"; else say_opt "$TOOLS/uasm（可选，运行 ./scripts/fetch-tools.sh）"; fi

echo
echo "MASM 6.15 / LINK / DEBUG（由你自备，不随仓库分发）:"
ml="$(file_ci "$MASM615" "ML.EXE")"
mlerr="$(file_ci "$MASM615" "ML.ERR")"
link="$(file_ci "$MASM615" "LINK.EXE")"
lib="$(file_ci "$MASM615" "LIB.EXE")"
dbg="$(file_ci "$DOSBIN" "DEBUG.EXE")"

[[ -n "$ml"    ]] && say_ok "$ml"    || say_miss "$MASM615/ML.EXE"
[[ -n "$mlerr" ]] && say_ok "$mlerr" || say_miss "$MASM615/ML.ERR（必须与 ML.EXE 同目录）"
[[ -n "$link"  ]] && say_ok "$link"  || say_miss "$MASM615/LINK.EXE"
[[ -n "$lib"   ]] && say_ok "$lib"   || say_opt "$MASM615/LIB.EXE（只有用到库时才需要）"
[[ -n "$dbg"   ]] && say_ok "$dbg"   || say_miss "$DOSBIN/DEBUG.EXE"

echo
if (( fail )); then
    cat <<'EOF'
有必需组件缺失。最小文件布局：

  tools/wibo                     <- ./scripts/fetch-tools.sh
  tools/uasm                     <- 可选，同上
  tools/masm615/ML.EXE
  tools/masm615/ML.ERR
  tools/masm615/LINK.EXE
  tools/masm615/LIB.EXE           <- 可选
  tools/dos/DEBUG.EXE

MASM/LINK/DEBUG 请使用你已获授权的副本；本仓库不提供下载。
EOF
    exit 1
fi

echo "环境检查通过。下一步：./scripts/setup.sh"
