#
# Simple Makefile using the ca65 assembler from CC65.
#

AS := ca65
CC := cl65
LD := ld65

ASFLAGS := --cpu 6502x -t c64 -I inc -I .

SPEEDSCRIPT_SOURCES= \
	src/main.s \
	src/refresh.s \
	src/move.s \
	src/vars.s \
	src/freemem.s \
	src/print.s \
	src/search.s \
	src/io.s \
	src/insert.s \
	src/input.s \
	src/erase.s \
	src/interrupt.s \
	src/cursor.s \
	src/misc.s \
	src/delete.s \
	src/control.s

SPEEDSCRIPT_OBJS=$(SPEEDSCRIPT_SOURCES:.s=.o)

all: speedscript31r2.prg speedscript32r1.prg speedscript32r2.prg speedscriptmodular.prg cksum

%.prg: original/%.s
	@echo Building $@ ...
	$(CC) --cpu 6502x -t c64 -C c64-asm.cfg -l $@.lst -m $@.map -o $@ $<
	@echo ""

speedscript31r2.prg: original/speedscript31r2.s
speedscript32r1.prg: original/speedscript32r1.s
speedscript32r2.prg: original/speedscript32r2.s

%.o: %.s
	@echo Building $@ ...
	@echo DEBUG src/%.o pass.
	$(AS) $(ASFLAGS) -l $@.lst -o $@ $<
	@echo ""

speedscriptmodular.prg: $(SPEEDSCRIPT_OBJS) speedscript.cfg
	@echo Building $@ ...
	$(LD) -C speedscript.cfg $(SPEEDSCRIPT_OBJS) c64.lib -m $@.map -o $@ 
	@echo ""


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
	@md5sum speedscriptmodular.prg
	@grep ss32r2 tests/official.md5sum.txt
	@echo ""

clean:
	rm -f *.prg *.lst *.map src/*.o src/*.lst

