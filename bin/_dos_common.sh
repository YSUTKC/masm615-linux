#!/usr/bin/env bash
# Shared configuration and helpers for the masm615-linux wrappers.
set -euo pipefail

BIN_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ROOT="$(cd "$BIN_DIR/.." && pwd)"
TOOLS="${MASM615_LINUX_TOOLS:-$ROOT/tools}"

# User-provided Microsoft tools (never committed to the repository).
MASM615="${MASM615_DIR:-$TOOLS/masm615}"
DOSBIN="${DOSBIN_DIR:-$TOOLS/dos}"
ML="$MASM615/ML.EXE"
MLERR="$MASM615/ML.ERR"
LINK="$MASM615/LINK.EXE"
DEBUG="$DOSBIN/DEBUG.EXE"

# Open-source helper binaries fetched by scripts/fetch-tools.sh.
WIBO="$TOOLS/wibo"
UASM="$TOOLS/uasm"

# These names appear inside the DOSBox X: mount and must stay 8.3.
MASM615_DOS_NAME="${MASM615_DOS_NAME:-masm615}"
DOSBIN_DOS_NAME="${DOSBIN_DOS_NAME:-dos}"
LINK_DOS="x:\\${MASM615_DOS_NAME}\\LINK.EXE"
DEBUG_DOS="x:\\${DOSBIN_DOS_NAME}\\DEBUG.EXE"

# DOSBox Staging auto-detection. Override with DOSBOX=/path/to/binary.
if [[ -z "${DOSBOX:-}" ]]; then
    if [[ -x /snap/bin/dosbox-staging ]]; then
        DOSBOX=/snap/bin/dosbox-staging
    elif command -v dosbox-staging >/dev/null 2>&1; then
        DOSBOX="$(command -v dosbox-staging)"
    fi
fi
DOSBOX="${DOSBOX:-dosbox-staging}"
SNAP_NAME="${SNAP_NAME:-dosbox-staging}"

die()  { printf '错误: %s\n' "$*" >&2; exit 1; }
warn() { printf '提示: %s\n' "$*" >&2; }

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

require_dosbox() {
    if [[ "$DOSBOX" == */* ]]; then
        [[ -x "$DOSBOX" ]] || die "找不到 DOSBox：$DOSBOX。请安装 dosbox-staging，或设置 DOSBOX=/path/to/dosbox-staging。"
    else
        have_cmd "$DOSBOX" || die "找不到 DOSBox Staging（$DOSBOX）。请安装 dosbox-staging，或设置 DOSBOX=/path/to/dosbox-staging。"
    fi
}

require_wibo() {
    [[ -x "$WIBO" ]] || die "找不到 wibo：$WIBO。请先运行 ./scripts/fetch-tools.sh。"
}

require_ml() {
    require_wibo
    local hit
    if [[ ! -f "$ML" ]]; then
        hit="$(find_ci "$MASM615" "ML.EXE")"
        [[ -n "$hit" ]] && ML="$hit"
    fi
    if [[ ! -f "$MLERR" ]]; then
        hit="$(find_ci "$MASM615" "ML.ERR")"
        [[ -n "$hit" ]] && MLERR="$hit"
    fi
    [[ -f "$ML" ]] || die "找不到 MASM 6.15 的 ML.EXE：$ML。请把你的合法副本放到 $MASM615，或运行 ./scripts/check-env.sh 查看缺失项。"
    [[ -f "$MLERR" ]] || die "找不到 ML.ERR：$MLERR。它必须与 ML.EXE 放在同一目录。"
}

require_uasm() {
    [[ -x "$UASM" ]] || die "找不到 UASM：$UASM。请先运行 ./scripts/fetch-tools.sh。"
}

require_link() {
    local hit
    if [[ ! -f "$LINK" ]]; then
        hit="$(find_ci "$MASM615" "LINK.EXE")"
        [[ -n "$hit" ]] && LINK="$hit"
    fi
    [[ -f "$LINK" ]] || die "找不到 LINK.EXE：$LINK。请把 LINK 5.31 放到 $MASM615，或运行 ./scripts/check-env.sh。"
}

require_debug() {
    local hit
    if [[ ! -f "$DEBUG" ]]; then
        hit="$(find_ci "$DOSBIN" "DEBUG.EXE")"
        [[ -n "$hit" ]] && DEBUG="$hit"
    fi
    [[ -f "$DEBUG" ]] || die "找不到 DEBUG.EXE：$DEBUG。请把 MS-DOS DEBUG（或 FreeDOS DEBUG）放到 $DOSBIN，或运行 ./scripts/check-env.sh。"
}

# 16-bit DOS addressing cannot use CX as an index register; this helper also
# keeps filenames inside the classic 8.3 limit expected by DOS tools.
is_dos83() {
    local name="$1" stem ext
    stem="${name%.*}"
    ext="${name##*.}"
    [[ "$name" == *.* ]] || ext=""
    ((${#stem} <= 8 && ${#ext} <= 3))
}

check_dos83() {
    local name="$1"
    is_dos83 "$name" && return 0
    die "DOS 8.3 文件名限制: '$name' 不符合（主名≤8字符，扩展名≤3字符）。请改成短文件名，例如 comtest.asm。"
}

resolve_program() {
    local p="$1" dir base hit e
    if [[ -f "$p" ]]; then
        readlink -f "$p"
        return 0
    fi

    if [[ "$p" == */* ]]; then
        dir="$(dirname "$p")"
        base="$(basename "$p")"
    else
        dir="."
        base="$p"
    fi

    if [[ "$base" == *.* ]]; then
        hit="$(find_ci "$dir" "$base")"
        [[ -n "$hit" ]] && { readlink -f "$hit"; return 0; }
    else
        for e in exe com; do
            hit="$(find_ci "$dir" "$base.$e")"
            [[ -n "$hit" ]] && { readlink -f "$hit"; return 0; }
        done
    fi
    return 1
}

find_ci() {
    local dir="$1" name="$2"
    find "$dir" -maxdepth 1 -iname "$name" -print -quit 2>/dev/null || true
}

is_snap_dosbox() {
    [[ "$DOSBOX" == /snap/* || "$DOSBOX" == */snap/bin/* ]]
}

# snap's AppArmor profile rejects signals from outside the snap. Fall back to
# sending the signal from a shell running inside the snap.
kill_dosbox_pid() {
    local pid="$1"
    [[ -n "$pid" ]] || return 0
    if kill -9 "$pid" 2>/dev/null; then
        return 0
    fi
    if is_snap_dosbox && have_cmd snap; then
        printf 'kill -9 %s 2>/dev/null\nexit\n' "$pid" \
            | timeout 5 snap run --shell "$SNAP_NAME" >/dev/null 2>&1 || true
    fi
}

# Start DOSBox in the background with a watchdog. A timeout is reported as 124.
# Usage: dosbox_run_timed <seconds> <stderr-file> <command...>
dosbox_run_timed() {
    local tmo="$1" err="$2"
    shift 2

    set +m
    local flag
    flag="$(mktemp)"
    rm -f "$flag"

    SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy "$@" >/dev/null 2>"$err" &
    local box=$!
    local watcher=""
    if (( tmo > 0 )); then
        (
            sleep "$tmo"
            if kill -0 "$box" 2>/dev/null; then
                : > "$flag"
                kill_dosbox_pid "$box"
            fi
        ) >/dev/null 2>&1 &
        watcher=$!
    fi

    set +e
    wait "$box" 2>/dev/null
    local rc=$?
    set -e

    if [[ -n "$watcher" ]]; then
        kill -STOP "$watcher" 2>/dev/null || true
        pkill -P "$watcher" 2>/dev/null || true
        kill -KILL "$watcher" 2>/dev/null || true
        wait "$watcher" 2>/dev/null || true
    fi
    if kill -0 "$box" 2>/dev/null; then
        : > "$flag"
        kill_dosbox_pid "$box"
    fi
    [[ -e "$flag" ]] && rc=124
    rm -f "$flag"
    return "$rc"
}

# Run one DOS command with the source directory mounted as C:.
# Usage: dosbox_batch <dir> <dos-command> <timeout> <stderr-file>
dosbox_batch() {
    local dir="$1" cmd="$2" tmo="$3" err="$4"
    dosbox_run_timed "$tmo" "$err" "$DOSBOX" \
        --noprimaryconf --nolocalconf --noautoexec --exit \
        --set cputype=pentium --set memsize=16 \
        -c "mount c \"$dir\"" -c "c:" -c "$cmd"
}

# Same as dosbox_batch, but also mounts tools/ as X: so LINK and DEBUG can be
# called from any source subdirectory.
dosbox_batch_tools() {
    local dir="$1" cmd="$2" tmo="$3" err="$4"
    dosbox_run_timed "$tmo" "$err" "$DOSBOX" \
        --noprimaryconf --nolocalconf --noautoexec --exit \
        --set cputype=pentium --set memsize=16 \
        -c "mount c \"$dir\"" \
        -c "mount x \"$TOOLS\"" \
        -c "c:" -c "$cmd"
}
