# Examples

All examples are 16-bit DOS programs written in MASM 6.x syntax. They write to
standard output through `INT 21h`, so `dosrun` can capture their output.

```bash
cd masm615-linux

dosbuild -r examples/hello.asm
dosbuild -r examples/sort.asm
dosbuild -r examples/prime.asm
dosbuild -r examples/fact.asm
dosbuild -r examples/matrix.asm
dosbuild -r examples/hanoi.asm
dosbuild -r examples/readch.asm
```

Or step by step:

```bash
dosasm examples/sort.asm
doslink examples/sort.obj
dosrun examples/SORT.EXE
```

Debug:

```bash
dosdbg -i examples/SORT.EXE
dosdbg examples/SORT.EXE r u q
```

## hello.asm

The smallest useful MASM 6.x DOS program. Output:

```text
Hello DOS!
```

## sort.asm — bubble sort

Arrays, nested loops, signed comparison, procedures, decimal output.

```text
Before: 9 -3 0 7 2 -8 5 1
After:  -8 -3 0 1 2 5 7 9
```

## prime.asm — sieve of Eratosthenes

Byte arrays, nested loops, `MUL`, indexed addressing, procedures.

```text
Primes up to 100:
2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97
Count: 25
```

## fact.asm — recursive factorial (32-bit)

`.386`, 32-bit registers, `IMUL`/`DIV`, recursion.

```text
12! = 479001600
```

`.386` / `.686` must appear **after** `.model`; otherwise `.model` resets the
CPU setting to 8086.

## matrix.asm — 2×2 matrix multiplication

Row-major 2D arrays, three nested loops, `IMUL`.

```text
A = [1 2; 3 4]
B = [5 6; 7 8]
A*B = [19 22; 43 50]
```

## hanoi.asm — recursive Tower of Hanoi

Recursion, saving state on the stack, character output.

```text
Hanoi(3):
A->C
A->B
C->B
A->C
B->A
B->C
A->C

Total moves: 7
```

## readch.asm — stdin echo

Reads one character with `INT 21h AH=01h`, echoes it with `AH=02h`.
Demonstrates `dosrun`'s stdin support:

```bash
printf 'A' | dosrun examples/READCH.EXE
```

Output:

```text
A
```

## Notes

- Filenames use DOS 8.3: stem ≤8 characters, extension ≤3.
- These programs have no keyboard input. Programs using `INT 16h` or
  `INT 10h` should be run with `dosrun --gui`.
- `hanoi.asm` uses `n equ 3`; `fact.asm` uses `n dd 12`. Values above 12
  overflow 32 bits.
