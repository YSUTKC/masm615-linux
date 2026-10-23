# Tutorial: MASM 6.15 on Linux from the terminal

This tutorial starts from a clean Linux account and ends with a working
`dosasm -> doslink -> dosrun -> dosdbg` workflow for 16-bit DOS assembly.

The short version is:

```bash
git clone https://github.com/YSUTKC/masm615-linux.git
cd masm615-linux
./scripts/fetch-tools.sh
# put your licensed MASM/LINK/DEBUG files under tools/
./scripts/check-env.sh
./scripts/setup.sh
dosbuild -r examples/hello.asm
```

The rest of this document explains each step.

## 1. What problem does this solve?

MASM 6.15 is often used with DOSBox in a Windows environment. That works
because on Windows, `ML.EXE` is a native Win32 program while `LINK.EXE` and
`DEBUG.EXE` are DOS programs.

On Linux the same split still exists:

- `ML.EXE` is a **Win32 PE**. DOSBox cannot execute PE files.
- `LINK.EXE` and `DEBUG.EXE` are **16-bit DOS MZ** programs. Linux cannot
  execute real-mode DOS programs directly.
- The programs you write are also 16-bit real-mode DOS programs using
  `INT 21h`/`INT 10h` and segment registers.

This project uses:

- **wibo** (MIT) to run the Win32 `ML.EXE` natively on Linux;
- **DOSBox Staging** for `LINK.EXE`, `DEBUG.EXE`, and your DOS programs.

Assembly is fast and native. Only link/run/debug go through DOSBox.

## 2. Requirements

- Linux on x86_64 (wibo is an x86_64 ELF binary).
- `bash`, `git`, `curl`, `timeout`, `find`, `sed`, `awk`, `pkill`,
  `sha256sum`.
- **DOSBox Staging** (`dosbox-staging`). The wrappers also work with a
  compatible DOSBox build if you set `DOSBOX` manually.
- A legally licensed copy of **MASM 6.15**:
  - `ML.EXE`
  - `ML.ERR`
  - `LINK.EXE` (LINK 5.31)
  - `LIB.EXE` (optional, only if you use libraries)
- A DOS `DEBUG.EXE` (MS-DOS DEBUG or FreeDOS DEBUG).

MASM/LINK/DEBUG are **not** distributed by this repository.

## 3. Install DOSBox Staging

On Ubuntu, the snap is the simplest option:

```bash
sudo snap install dosbox-staging
```

If you use a distro package, make sure the binary is named
`dosbox-staging` and is on `PATH`. Otherwise set:

```bash
export DOSBOX=/path/to/dosbox-staging
```

The wrappers use `--noprimaryconf --nolocalconf --noautoexec --exit` and
`--set`, which are DOSBox Staging options.

## 4. Clone and fetch helper tools

```bash
git clone https://github.com/YSUTKC/masm615-linux.git
cd masm615-linux
./scripts/fetch-tools.sh
```

This downloads:

- `tools/wibo` — MIT, x86_64 Win32 loader.
- `tools/uasm` — optional native assembler (Sybase Open Watcom Public
  License).

The script verifies SHA-256 checksums. See `tools/README.md` for the expected
layout.

## 5. Add your MASM/LINK/DEBUG files

Put the Microsoft tools under `tools/`:

```text
tools/masm615/ML.EXE
tools/masm615/ML.ERR
tools/masm615/LINK.EXE
tools/masm615/LIB.EXE     # optional
tools/dos/DEBUG.EXE
```

`ML.ERR` must be next to `ML.EXE`. The DOS directory names are deliberate:
they are mounted inside DOSBox as `X:\masm615` and `X:\dos`.

Check the environment:

```bash
./scripts/check-env.sh
```

Expected output includes `[ok]` for DOSBox, wibo, ML.EXE, ML.ERR, LINK.EXE,
and DEBUG.EXE. Missing optional items (UASM, LIB.EXE) are reported separately.

## 6. Install the commands

```bash
./scripts/setup.sh
```

This creates symlinks in `~/.local/bin`:

```text
dosasm  doslink  dosrun  dosdbg  dosbuild
```

If `~/.local/bin` is not on `PATH`, the script prints the line to add to your
shell profile:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

You can also run commands directly as `./bin/dosbuild`.

## 7. First program

Create `hello.asm`:

```asm
        .model  small
        .stack  100h

        .data
msg     db      'Hello DOS!$'

        .code
main    proc
        mov     ax, @data
        mov     ds, ax
        mov     dx, offset msg
        mov     ah, 9
        int     21h
        mov     ah, 4ch
        int     21h
main    endp

        end     main
```

Build and run:

```bash
dosbuild -r hello.asm
```

Expected output:

```text
==> /path/to/hello.asm
 Assembling: hello.asm
    目标文件: /path/to/hello.obj
...
生成: /path/to/HELLO.EXE
Hello DOS!
```

Step by step:

```bash
dosasm hello.asm      # -> hello.obj
doslink hello.obj     # -> HELLO.EXE
dosrun HELLO.EXE      # -> Hello DOS!
```

`dosrun` mounts the program's directory as `C:`, runs
`HELLO.EXE > _RUN.TXT`, and prints `_RUN.TXT`.

## 8. Debug

Scripted DEBUG:

```bash
dosdbg HELLO.EXE r u q
```

This runs `DEBUG.EXE` with a CRLF command script and prints:

- `r` — registers;
- `u` — disassembly;
- `q` — quit.

Interactive DEBUG:

```bash
dosdbg -i HELLO.EXE
```

You get a `(dbg)` prompt. Commands are sent through a FIFO to one persistent
DEBUG session, so `t`, `p`, `u`, `d`, `g` behave normally:

```text
(dbg) r
(dbg) u
(dbg) t 3
(dbg) g
(dbg) q
```

For the native DOSBox DEBUG window:

```bash
dosdbg --gui HELLO.EXE
```

## 9. 32-bit instructions (chapter 6)

Put `.386` or `.686` **after** `.model`:

```asm
        .model  small
        .686
        .stack  100h

        .data
buffer  db      'The processor is ', 12 dup(0), '$'
bufsize =       sizeof buffer

        .code
main    proc
        mov     eax, 0
        cpuid
        mov     dword ptr buffer + bufsize - 13, ebx
        mov     dword ptr buffer + bufsize - 9,  edx
        mov     dword ptr buffer + bufsize - 5,  ecx
        mov     dx, offset buffer
        mov     ah, 9
        int     21h
        mov     ah, 4ch
        int     21h
main    endp

        end     main
```

If `.686` is placed **before** `.model`, MASM resets the CPU to 8086 and
32-bit registers are assembled incorrectly.

`dosrun` uses `cputype=pentium`, so CPUID and 486/Pentium instructions work.
`CMOVcc` is a Pentium Pro instruction and is not executed by DOSBox Staging's
CPU core; the textbook only introduces it, so no runnable example is included.

## 10. Multi-module programs

`dosbuild` accepts several sources:

```bash
dosbuild -r main.asm subr.asm
```

`main.asm`:

```asm
        .model  small
        .stack  100h
        .code
        extern  subr:near

main    proc
        call    subr
        mov     ah, 4ch
        int     21h
main    endp

        end     main
```

`subr.asm`:

```asm
        .model  small
        .code
        public  subr

subr    proc    near
        mov     dl, 'M'
        mov     ah, 2
        int     21h
        ret
subr    endp

        end
```

`doslink` receives both objects and invokes:

```text
X:\masm615\LINK.EXE MAIN.OBJ+SUBR.OBJ;
```

If a source contains `include io.inc`, `dosbuild` automatically appends the
`io.lib` found in the same directory, so this also works without extra flags:

```bash
dosbuild -r ioprog.asm
```

## 11. .COM files

```bash
dosbuild -c -r tiny.asm
```

`-c` adds `LINK /TINY`. The output is a `.COM` file. If the source starts with
`.model tiny`, `dosbuild` selects `/TINY` automatically:

```bash
dosbuild -r tiny.asm      # also produces TINY.COM
```

## 12. Input and GUI programs

Pipe standard input:

```bash
printf 'A' | dosrun examples/READCH.EXE
dosrun -i input.txt examples/READCH.EXE
```

`-i` converts LF to CRLF by default, which suits line-oriented DOS input.
For fixed-width input (for example `readbw` reading sixteen binary digits at a
time), use `--raw` so no extra CR/LF is inserted:

```bash
dosrun --raw -i bits.txt readbw.exe
```

Programs using `INT 10h`, direct video memory, or `INT 16h` keyboard input
must use the DOSBox window:

```bash
dosrun --gui game.exe
```

In headless mode, `dosrun` can only capture standard output written through
`INT 21h`. A program that only changes registers or memory prints nothing;
that is normal. `dosrun` inspects the matching `.asm` and distinguishes
"prints nothing by design", "waiting for input", and "probably an infinite
loop" in its message.

## 13. How it works internally

- `dosasm` runs `wibo ML.EXE /c ...` in the source directory. `wibo` is a
  Linux ELF process; no Wine and no DOSBox.
- `doslink` starts DOSBox with the source directory as `C:` and `tools/` as
  `X:`. It calls `X:\masm615\LINK.EXE`.
- `dosdbg` uses the same mounts and calls `X:\dos\DEBUG.EXE`.
- `dosrun` mounts the program directory as `C:` and redirects stdout to
  `_RUN.TXT`.
- Timeouts run a watchdog. With the snap build of DOSBox, the watchdog sends
  the kill from inside the snap because AppArmor rejects external signals.

See [architecture.md](architecture.md) for the diagram.

## 14. Common pitfalls

- **8.3 filenames**: `.asm`, `.obj`, `.exe`, `.com` stems must be ≤8
  characters and extensions ≤3. The wrappers check and suggest a rename.
- **CRLF for DEBUG**: command files must use CRLF; the wrapper converts them.
- **`.686` placement**: after `.model`.
- **snap timeout**: handled by the wrapper; manual `kill` from outside the
  snap may be denied.
- **No output**: the program may legitimately print nothing, wait for input,
  or use `INT 10h`/direct video memory; `dosrun` reports which case it
  detected.
- **Non-ASCII directory**: DOSBox's `mount` may fail. The wrappers create an
  ASCII symlink under `~/masm615-mounts/` and mount that instead.
- **Win32 example**: `.model flat`, `includelib bin32\...`, or MASM32
  `windows.inc` means a 32-bit Windows program, which this DOS toolchain does
  not support.

More: [troubleshooting.md](troubleshooting.md).

## 15. License and third-party tools

The scripts, examples, and documentation are MIT-licensed. Microsoft
MASM/LINK/DEBUG are proprietary and are not included. wibo is MIT; UASM uses
the Sybase Open Watcom Public License; DOSBox Staging is GPL-2.0-or-later.
See [NOTICE.md](../NOTICE.md).
