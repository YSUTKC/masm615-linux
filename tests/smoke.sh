#!/usr/bin/env bash
# End-to-end smoke test. Requires the user-provided MASM/LINK/DEBUG tools.
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
BIN="$ROOT/bin"

if ! "$ROOT/scripts/check-env.sh" >/tmp/masm615-check.log 2>&1; then
    cat /tmp/masm615-check.log
    echo
    echo "环境不完整，跳过冒烟测试。"
    exit 1
fi

cleanup() {
    find "$ROOT/examples" -maxdepth 1 -type f \
        \( -iname '*.obj' -o -iname '*.exe' -o -iname '*.com' \
           -o -iname '*.lst' -o -iname '*.map' \
           -o -iname '_RUN.TXT' -o -iname '_IN.TXT' -o -iname '_RUN.ERR' \
           -o -iname '_GUI.ERR' -o -iname 'DBGFIFO.TXT' \
           -o -iname 'DBGLIVE.TXT' -o -iname 'DBGLIVE.ERR' \) \
        -delete 2>/dev/null || true
    rm -rf "$ROOT/tmp-test" "$ROOT/测试目录" 2>/dev/null || true
}
trap cleanup EXIT

echo "== hello =="
out="$("$BIN/dosbuild" -r "$ROOT/examples/hello.asm")"
grep -q 'Hello DOS!' <<<"$out"

echo "== sort =="
out="$("$BIN/dosbuild" -r "$ROOT/examples/sort.asm")"
grep -q 'After:.*-8 -3 0 1 2 5 7 9' <<<"$out"

echo "== fact =="
out="$("$BIN/dosbuild" -r "$ROOT/examples/fact.asm")"
grep -q '12! = 479001600' <<<"$out"

echo "== debug =="
out="$("$BIN/dosdbg" "$ROOT/examples/HELLO.EXE" r q)"
grep -q 'AX=' <<<"$out"

echo "== readch =="
"$BIN/dosbuild" "$ROOT/examples/readch.asm" >/dev/null
out="$(printf 'A' | "$BIN/dosrun" "$ROOT/examples/READCH.EXE")"
grep -q '^A' <<<"$out"

echo "== timeout hint =="
set +e
out="$("$BIN/dosrun" -t 1 "$ROOT/examples/READCH.EXE" </dev/null 2>&1)"
rc=$?
set -e
[[ "$rc" -eq 124 ]]
grep -q '等待键盘' <<<"$out"

echo "== auto .COM =="
rm -rf "$ROOT/tmp-test"; mkdir -p "$ROOT/tmp-test"
cat > "$ROOT/tmp-test/tinydemo.asm" <<'EOF'
        .model  tiny
        .code
        .startup
        mov     dx, offset msg
        mov     ah, 9
        int     21h
        .exit
msg     db      'COM OK', 13, 10, '$'
        end
EOF
out="$(cd "$ROOT/tmp-test" && "$BIN/dosbuild" -r tinydemo.asm)"
grep -q 'COM OK' <<<"$out"
find "$ROOT/tmp-test" -maxdepth 1 -iname '*.com' | grep -q .

echo "== non-ASCII path =="
rm -rf "$ROOT/测试目录"; mkdir -p "$ROOT/测试目录"
cp "$ROOT/examples/hello.asm" "$ROOT/测试目录/hello.asm"
out="$(cd "$ROOT/测试目录" && "$BIN/dosbuild" -r hello.asm)"
grep -q 'Hello DOS!' <<<"$out"

if [[ -x "$ROOT/tools/uasm" ]]; then
    echo "== uasm =="
    "$BIN/dosasm" --uasm "$ROOT/examples/hello.asm" >/dev/null
    "$BIN/doslink" "$ROOT/examples/hello.obj" >/dev/null
    out="$("$BIN/dosrun" "$ROOT/examples/HELLO.EXE")"
    grep -q 'Hello DOS!' <<<"$out"
fi

echo
echo "PASS: 编译、连接、运行、DEBUG 全部通过。"
