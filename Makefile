#
# Simple Makefile using the ca65 assembler from CC65.
#


AS=cl65

all:
	$(AS) --cpu 6502x -o speedscript31r2.prg -t c64 -C c64-asm.cfg src/speedscript31r2.s  
	@md5sum speedscript31r2.prg
	@grep ss31r2 tests/official.md5sum.txt
	$(AS) --cpu 6502x -o speedscript32r1.prg -t c64 -C c64-asm.cfg src/speedscript32r1.s
	@md5sum speedscript32r1.prg
	@grep ss32r1 tests/official.md5sum.txt
	$(AS) --cpu 6502x -o speedscript32r2.prg -t c64 -C c64-asm.cfg src/speedscript32r2.s
	@md5sum speedscript32r2.prg
	@grep ss32r2 tests/official.md5sum.txt

