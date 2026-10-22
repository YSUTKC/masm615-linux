# Third-party notices

This repository contains only original scripts, documentation, and example
source code. It does **not** redistribute any Microsoft binaries.

## Microsoft MASM 6.15, LINK, LIB, DEBUG

`ML.EXE`, `ML.ERR`, `LINK.EXE`, `LIB.EXE`, and `DEBUG.EXE` are proprietary
Microsoft tools. They are not included in this repository. Users must obtain
them through a legally licensed copy and place them under `tools/` locally.
The MIT license of this repository applies only to the original code and
documentation, not to those Microsoft tools.

## wibo

- Project: <https://github.com/decompals/wibo>
- License: MIT
- Role: runs the 32-bit Windows `ML.EXE` natively on Linux.
- Distribution: downloaded by `scripts/fetch-tools.sh`; not committed.

## UASM

- Project: <https://github.com/Terraspace/UASM>
- License: Sybase Open Watcom Public License (see the upstream repository).
- Role: optional MASM-compatible native Linux assembler (`dosasm --uasm`).
- Distribution: downloaded by `scripts/fetch-tools.sh`; not committed.

## DOSBox Staging

- Project: <https://github.com/dosbox-staging/dosbox-staging>
- License: GPL-2.0-or-later.
- Role: runs `LINK.EXE`, `DEBUG.EXE`, and the 16-bit DOS programs.
- Distribution: expected to be installed by the user (snap or distro package);
  not committed.

## Microsoft DEBUG / FreeDOS DEBUG

The wrappers expect a DOS `DEBUG.EXE`. You can use the DEBUG shipped with your
licensed DOS/Windows toolchain, or an open-source FreeDOS DEBUG build. The
latter is distributed under its own license; check the upstream project before
redistributing it.

## Examples and documentation

The example assembly programs and documentation in this repository are
original work and are covered by the repository's MIT license.
