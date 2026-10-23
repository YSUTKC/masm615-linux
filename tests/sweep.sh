#!/usr/bin/env bash
# Sweep every .asm in a directory: assemble + link, then run with a timeout.
# This is a diagnostic tool for course/example directories, not a strict test:
# interactive programs are expected to time out.
#
# Usage: tests/sweep.sh [目录] [超时秒数]
set -uo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
source "$ROOT/bin/_dos_common.sh"
set +e

dir="${1:-$ROOT/examples}"
tmo="${2:-4}"
[[ -d "$dir" ]] || die "找不到目录: $dir"
dir="$(cd "$dir" && pwd)"

total=0
ok=0
build_fail=0
run_fail=0
timed_out=0
skipped=0

printf '目录: %s（超时 %ss）\n\n' "$dir" "$tmo"
printf '%-18s %-12s %s\n' '文件' '状态' '说明'
printf '%-18s %-12s %s\n' '----' '----' '----'

for src in "$dir"/*.asm; do
    [[ -f "$src" ]] || continue
    base="$(basename "$src")"
    stem="${base%.*}"
    total=$((total + 1))

    if is_win32_source "$src"; then
        printf '%-18s %-12s %s\n' "$base" 'SKIP' 'Win32/32 位示例'
        skipped=$((skipped + 1))
        continue
    fi
    # Include-only modules have no .model; library modules have no startup
    # code and no named entry point.
    if ! grep -aqiE '^[[:space:]]*\.model' "$src"; then
        printf '%-18s %-12s %s\n' "$base" 'SKIP' '子程序/include 模块'
        skipped=$((skipped + 1))
        continue
    fi
    if ! grep -aqiE '\.startup' "$src" && ! grep -aqiE '^[[:space:]]*end[[:space:]]+[A-Za-z_]' "$src"; then
        printf '%-18s %-12s %s\n' "$base" 'SKIP' '无入口点的库模块'
        skipped=$((skipped + 1))
        continue
    fi

    build_out="$(cd "$dir" && "$ROOT/bin/dosbuild" "$base" 2>&1)"
    build_rc=$?
    if (( build_rc != 0 )); then
        reason="$(grep -aE 'error A[0-9]+|error L[0-9]+|fatal error|错误:' <<<"$build_out" | head -1 | cut -c1-100)"
        if grep -qa 'unresolved external' <<<"$build_out"; then
            reason="${reason}（多模块？把子模块一起传给 dosbuild）"
        fi
        printf '%-18s %-12s %s\n' "$base" 'BUILD_FAIL' "${reason:-汇编或连接失败}"
        build_fail=$((build_fail + 1))
        continue
    fi

    prog="$(find_ci "$dir" "$stem.exe")"
    [[ -n "$prog" ]] || prog="$(find_ci "$dir" "$stem.com")"
    if [[ -z "$prog" ]]; then
        printf '%-18s %-12s %s\n' "$base" 'BUILD_FAIL' '没有生成 .exe/.com'
        build_fail=$((build_fail + 1))
        continue
    fi

    run_out="$(cd "$dir" && "$ROOT/bin/dosrun" -t "$tmo" "$(basename "$prog")" </dev/null 2>&1)"
    run_rc=$?

    if (( run_rc == 124 )); then
        printf '%-18s %-12s %s\n' "$base" 'TIMEOUT' '交互程序或死循环（用 --gui / -i / dosdbg）'
        timed_out=$((timed_out + 1))
    elif (( run_rc != 0 )); then
        printf '%-18s %-12s %s\n' "$base" 'RUN_FAIL' "退出码 $run_rc"
        run_fail=$((run_fail + 1))
    else
        first="$(sed 's/\r$//' <<<"$run_out" | grep -avE '^(提示:|错误:|$)' | head -1 | cut -c1-100)"
        printf '%-18s %-12s %s\n' "$base" 'OK' "${first:-（无标准输出，正常）}"
        ok=$((ok + 1))
    fi
done

echo
printf '合计: %d  正常: %d  汇编/连接失败: %d  运行失败: %d  超时: %d  跳过: %d\n' \
    "$total" "$ok" "$build_fail" "$run_fail" "$timed_out" "$skipped"

# Interactive timeouts are expected in a course directory, so they do not make
# the sweep fail. Build failures do.
(( build_fail == 0 ))
