SHELL := /bin/bash

.PHONY: check fetch install test sweep clean

check:
	./scripts/check-env.sh

fetch:
	./scripts/fetch-tools.sh

install:
	./scripts/setup.sh

test:
	./tests/smoke.sh

# Diagnostic sweep of a directory full of .asm files.
# Usage: make sweep DIR=/path/to/course/project
sweep:
	./tests/sweep.sh "$(DIR)"

clean:
	find examples -maxdepth 1 -type f \
		\( -iname '*.obj' -o -iname '*.exe' -o -iname '*.com' \
		   -o -iname '*.lst' -o -iname '*.map' \
		   -o -iname '_RUN.TXT' -o -iname '_IN.TXT' -o -iname '_RUN.ERR' \
		   -o -iname '_GUI.ERR' -o -iname 'DBGFIFO.TXT' \
		   -o -iname 'DBGLIVE.TXT' -o -iname 'DBGLIVE.ERR' \) \
		-delete 2>/dev/null || true
