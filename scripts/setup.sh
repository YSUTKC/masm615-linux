#!/usr/bin/env bash
# Install command symlinks into a user-owned bin directory.
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
PREFIX="${HOME}/.local/bin"

usage() {
    cat <<'EOF'
用法: ./scripts/setup.sh [--prefix 目录]
  把 dosasm/doslink/dosrun/dosdbg/dosbuild 软链到目录（默认 ~/.local/bin）。

示例:
  ./scripts/setup.sh
  ./scripts/setup.sh --prefix "$HOME/bin"
EOF
}

while (($#)); do
    case "$1" in
        --prefix) [[ $# -ge 2 ]] || { echo "--prefix 需要参数" >&2; exit 2; }; PREFIX="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage; exit 2 ;;
    esac
done

mkdir -p "$PREFIX"
chmod +x "$ROOT/bin/dosasm" "$ROOT/bin/doslink" "$ROOT/bin/dosrun" \
         "$ROOT/bin/dosdbg" "$ROOT/bin/dosbuild" "$ROOT/bin/_dos_common.sh"
[[ -f "$ROOT/tools/wibo" ]] && chmod +x "$ROOT/tools/wibo" || true
[[ -f "$ROOT/tools/uasm" ]] && chmod +x "$ROOT/tools/uasm" || true

for cmd in dosasm doslink dosrun dosdbg dosbuild; do
    ln -sf "$ROOT/bin/$cmd" "$PREFIX/$cmd"
    echo "已链接: $PREFIX/$cmd"
done

case ":$PATH:" in
    *":$PREFIX:"*) ;;
    *)
        echo
        echo "提示: $PREFIX 不在 PATH 中。把下面一行加到 ~/.bashrc 或 ~/.zshrc："
        echo "  export PATH=\"$PREFIX:\$PATH\""
        ;;
esac

echo
echo "下一步："
echo "  ./scripts/check-env.sh"
echo "  dosbuild -r examples/hello.asm"
