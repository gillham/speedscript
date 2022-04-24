#
# Simple Makefile using the ca65 assembler from CC65.
#


AS=cl65
speedscript.prg: src/speedscript.s
	$(AS) --cpu 6502x -o speedscript.prg -t c64 -C c64-asm.cfg src/speedscript.s  

