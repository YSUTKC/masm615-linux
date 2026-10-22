# Contributing

Issues and pull requests are welcome.

## Issues

Please include:

- the command you ran;
- the full output (redact paths if needed);
- the output of `./scripts/check-env.sh`;
- your Linux distribution, DOSBox version, and whether you use the snap build.

Do **not** paste Microsoft binaries, license keys, or copyrighted textbook
content into an issue.

## Pull requests

- Keep scripts POSIX-ish bash and run `bash -n` on them.
- Do not commit `.EXE`, `.OBJ`, `.LIB`, `wibo`, or `uasm` binaries.
- Keep example filenames DOS 8.3-compatible.
- Add or update documentation for user-visible changes.
- Run `make test` before submitting. It requires your local MASM/LINK/DEBUG
  and DOSBox installation.

By contributing, you agree that your changes are licensed under the
repository's MIT license.
