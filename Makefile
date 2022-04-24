#
# Simple Makefile using the ca65 assembler from CC65.
#

CC := cl65

all: speedscript31r2.prg speedscript32r1.prg speedscript32r2.prg cksum

%.prg: src/%.s
	@echo Building $@ ...
	$(CC) --cpu 6502x -t c64 -C c64-asm.cfg -o $@ $<
	@echo ""

speedscript31r2.prg: src/speedscript31r2.s
speedscript32r1.prg: src/speedscript32r1.s
speedscript32r2.prg: src/speedscript32r2.s

cksum:
	@echo ""
	@echo "Verifying checksums.... (You should make sure each pair below matches)"
	@echo ""
	@md5sum speedscript31r2.prg
	@grep ss31r2 tests/official.md5sum.txt
	@echo ""
	@md5sum speedscript32r1.prg
	@grep ss32r1 tests/official.md5sum.txt
	@echo ""
	@md5sum speedscript32r2.prg
	@grep ss32r2 tests/official.md5sum.txt
	@echo ""

clean:
	rm -f *.prg src/*.o

