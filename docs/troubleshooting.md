# Troubleshooting

## `wibo` not found

```text
错误: 找不到 wibo: .../tools/wibo
```

Run:

```bash
./scripts/fetch-tools.sh
```

`wibo` is an x86_64 Linux binary. On ARM or non-x86_64 hosts this toolchain
will not work as-is.

## `ML.EXE` / `ML.ERR` not found

Place your licensed MASM 6.15 files here:

```text
tools/masm615/ML.EXE
tools/masm615/ML.ERR
tools/masm615/LINK.EXE
```

`ML.ERR` must be in the same directory as `ML.EXE`.

## `LINK.EXE` not found / `Illegal command: link`

The wrappers mount `tools/` as `X:` and call:

```text
X:\masm615\LINK.EXE
X:\dos\DEBUG.EXE
```

Make sure the files are under `tools/masm615/LINK.EXE` and
`tools/dos/DEBUG.EXE`, and that the directory names stay 8.3-compatible. If
you rename them, set:

```bash
export MASM615_DOS_NAME=yourdir
export DOSBIN_DOS_NAME=yourdir
```

The names must be ≤8 characters.

## `LINK : fatal error L1093: object file not found`

Almost always an 8.3 filename problem. DOSBox exposes a long Linux filename as
a `~1` alias, while the wrapper passes the original name.

Rename:

```text
hello_com.asm  ->  comtest.asm
```

Rule: stem ≤8 characters, extension ≤3.

Directories can have long names because the wrapper mounts the directory
itself as `C:`.

## DEBUG prints `^ Error` after a command

DEBUG expects CRLF line endings. The wrappers convert command files and
interactive input for you. If you run DEBUG manually with a command file, use
CRLF:

```bash
sed 's/$/\r/' commands.txt > commands-crlf.txt
```

## `dosrun` prints nothing

`dosrun` only captures DOS standard output written through `INT 21h`
(`AH=09h`, `AH=02h`, etc.).

Programs that use:

- `INT 10h` for display,
- direct writes to `B800:0000`,
- `INT 16h` for keyboard input,
- a full-screen/graphics mode,

must be run with:

```bash
dosrun --gui program.exe
```

If the program legitimately prints nothing (for example it only stores values
in registers or memory), the empty output is normal. Newer versions of
`dosrun` inspect the matching `.asm` and print one of three messages:

- "程序已正常结束，但没有标准输出" — the example only changes state;
- "使用了 INT 10h/INT 16h" — run it with `--gui`;
- a timeout message that says whether it is waiting for input or likely
  looping forever.

## `dosrun` hangs

A headless program may be waiting for keyboard input (`INT 16h` or `INT 21h`
`AH=01h`) or looping forever. Use:

```bash
dosrun -t 2 program.exe
```

The timeout returns `124` and cleans up the DOSBox process. For interactive
programs:

```bash
dosrun --gui program.exe
dosrun -i input.txt program.exe
dosrun --raw -i bits.txt program.exe   # fixed-width input
```

If the source has no input calls and no `INT 16h`, the timeout message says
the program is probably looping; use `dosdbg` to inspect the jump or loop.

## `MOUNT: Can't create drive from file`

DOSBox's `mount` cannot reliably handle non-ASCII directory names. The
wrappers detect such paths and mount an ASCII symlink under
`~/masm615-mounts/` instead. Requirements:

- the symlink directory must not be hidden (not `~/.cache`), because snap's
  home interface cannot see hidden paths;
- the target directory must be under a path the DOSBox process can read.

If it still fails, move the project to an ASCII path (for example
`~/dos_workspace/project`) or mount it manually.

## Win32/32-bit example fails immediately

`dosasm`/`dosbuild` reject sources containing:

- `.model flat`;
- `includelib bin32\...` or `includelib lib\...`;
- MASM32 `include include\windows.inc`;
- compiler-generated `include listing.inc`.

These are 32-bit Windows programs. This toolchain only assembles and runs
16-bit DOS code. Use a Windows toolchain (MASM32/Visual Studio) for them.

## `io.lib` / unresolved external

If a source contains `include io.inc`, `dosbuild` automatically links the
`io.lib` in the same directory. With `doslink`, list the library explicitly:

```bash
doslink program.obj io.lib
```

If the symbol is still unresolved, check that the name exists in `io.lib`
(for example `dispuiw`, not `dispuid`).

## `CMOV` behaves incorrectly

`CMOVcc` is a Pentium Pro instruction. DOSBox Staging's CPU core emulates up
to Pentium MMX and does not execute CMOV correctly. The textbook only
introduces CMOV; if you need to run it, use DOSBox-X, a real DOS machine, or a
Windows 98-era VM.

## Chapter 6 32-bit code assembles as 16-bit

Put `.386`/`.686` **after** `.model`:

```asm
.model small
.686
```

If the directive comes first, `.model` resets the CPU to 8086 and instructions
such as `mov eax, 1` are assembled with the wrong operand size.

## `LINK : warning L4021: no stack segment`

This is harmless for simple programs that do not need a stack. Add:

```asm
.stack 100h
```

to remove the warning.

## `error A2086: Data emitted with no segment`

You are using data directives without a segment. Use the simplified MASM
6.x model:

```asm
.model small
.data
...
.code
...
end main
```

or declare explicit `DATA SEGMENT ... DATA ENDS`.

## Unresolved external in a multi-module program

- The subroutine must be declared `PUBLIC` in its own module.
- The caller must declare it `EXTERN`.
- Pass all object files to `doslink` / `dosbuild`.

Example:

```bash
dosbuild -r main.asm subr.asm
```

If the missing symbol comes from `io.lib`, see the `io.lib` section above;
`dosbuild` adds it automatically when the source includes `io.inc`.

## `dosbox-staging` not found

Install it:

```bash
sudo snap install dosbox-staging
```

or set an explicit binary:

```bash
export DOSBOX=/path/to/dosbox-staging
```

The wrappers rely on DOSBox Staging command-line options. A different DOSBox
fork may need different flags.

## snap DOSBox does not die on timeout

The snap's AppArmor profile rejects signals from outside the snap. The
wrapper detects a snap path and sends the kill from a shell inside the snap:

```bash
printf 'kill -9 <pid>\nexit\n' | snap run --shell dosbox-staging
```

`dosrun -t` and the other timeouts already do this. If you manually started a
stuck DOSBox, use the command above with the PID from `pgrep`.

## `Permission denied` when running `./bin/dosasm`

```bash
chmod +x bin/dos* tools/wibo tools/uasm
```

`./scripts/setup.sh` also does this.

## Command not found after `setup.sh`

Add the prefix to `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Put that line in `~/.bashrc` or `~/.zshrc` to make it permanent.

## `LIB.EXE` missing

Only needed if your program links against libraries. Simple DOS programs using
`INT 21h` do not need it.

## Still stuck?

Open an issue with:

- the exact command,
- the full output,
- `./scripts/check-env.sh` output,
- your Linux distribution and DOSBox version.

Do not paste proprietary binaries or license keys into an issue.
