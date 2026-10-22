# tools/

This directory is intentionally almost empty. It is where you put the tools
that cannot be redistributed with this repository.

Expected layout after setup:

```text
tools/
├── wibo                 # downloaded by scripts/fetch-tools.sh
├── uasm                 # optional, downloaded by scripts/fetch-tools.sh
├── masm615/
│   ├── ML.EXE           # your licensed MASM 6.15
│   ├── ML.ERR
│   ├── LINK.EXE         # LINK 5.31
│   └── LIB.EXE          # optional, only needed for libraries
└── dos/
    └── DEBUG.EXE        # MS-DOS DEBUG or FreeDOS DEBUG
```

`tools/wibo`, `tools/uasm`, and all `.EXE`/`.LIB` files are ignored by git.

## What each tool does

- **`ML.EXE` 6.15** is a 32-bit Windows PE. It cannot run inside DOSBox.
  `wibo` loads it directly on Linux, so assembly is native.
- **`LINK.EXE` 5.31** and **`DEBUG.EXE`** are 16-bit DOS programs. They run
  inside headless DOSBox, mounted as `X:\masm615` and `X:\dos`.
- **`LIB.EXE`** is only needed if your program uses libraries.
- **UASM** is an optional native Linux assembler. Use `dosasm --uasm`.

## Obtaining the Microsoft tools

This repository does not provide download links for Microsoft binaries.
Use a copy you are licensed to use (for example, an existing MASM 6.15
installation or an academic/retail package). Do not commit these files.

## Custom locations

The DOSBox `X:` mount is the whole `tools/` tree. By default the wrappers
look in `tools/masm615` and `tools/dos`.

To relocate the entire tree, use:

```bash
export MASM615_LINUX_TOOLS=/path/to/tools
```

The advanced overrides below must stay **inside** that mounted tree;
otherwise `X:\masm615\LINK.EXE` / `X:\dos\DEBUG.EXE` will not be visible:

```bash
export MASM615_DIR="$MASM615_LINUX_TOOLS/masm615"
export DOSBIN_DIR="$MASM615_LINUX_TOOLS/dos"
```

If you rename the subdirectories, set `MASM615_DOS_NAME` and
`DOSBIN_DOS_NAME` to matching 8.3 names.
