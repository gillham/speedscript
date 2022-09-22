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

INSTANT80_SOURCES= \
	$(SPEEDSCRIPT_SOURCES) \
	src/instant80.s

EASYCURSOR_SOURCES= \
	$(SPEEDSCRIPT_SOURCES) \
	src/easycursor.s

EASYCURSOR80_SOURCES= \
	$(INSTANT80_SOURCES) \
	src/easycursor.s

SPEEDSCRIPT_OBJS=$(SPEEDSCRIPT_SOURCES:.s=.o)

INSTANT80_OBJS=$(INSTANT80_SOURCES:%.s=build/instant80/%.o)
EASYCURSOR_OBJS=$(EASYCURSOR_SOURCES:%.s=build/easycursor/%.o)
EASYCURSOR80_OBJS=$(EASYCURSOR80_SOURCES:%.s=build/easycursor80/%.o)

all: speedscript31r2.prg speedscript32r1.prg speedscript32r2.prg speedscriptmodular.prg \
	speedscript-i80.prg speedscript-ec.prg speedscript-i80-ec.prg cksum

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

build/instant80/%.o: %.s
	@echo Building $@ ...
	@mkdir -p $(@D)
	$(AS) $(ASFLAGS) -l $@.lst -o $@ $<
	@echo ""

build/easycursor/%.o: %.s
	@echo Building $@ ...
	@mkdir -p $(@D)
	$(AS) $(ASFLAGS) -l $@.lst -o $@ $<
	@echo ""

build/easycursor80/%.o: %.s
	@echo Building $@ ...
	@mkdir -p $(@D)
	$(AS) $(ASFLAGS) -l $@.lst -o $@ $<
	@echo ""

speedscriptmodular.prg: $(SPEEDSCRIPT_OBJS) speedscript.cfg
	@echo Building $@ ...
	$(LD) -C speedscript.cfg $(SPEEDSCRIPT_OBJS) c64.lib -Ln $@.label -m $@.map -o $@ 
	@echo ""


speedscript-i80.prg: ASFLAGS += -DINSTANT80
speedscript-i80.prg: $(INSTANT80_OBJS) speedscript.cfg
	@echo Building $@ ...
	$(LD) -C speedscript.cfg $(INSTANT80_OBJS) c64.lib -Ln $@.label -m $@.map -o $@ 
	@echo ""

speedscript-ec.prg: ASFLAGS += -DEASYCURSOR
speedscript-ec.prg: $(EASYCURSOR_OBJS) speedscript.cfg
	@echo Building $@ ...
	$(LD) -C speedscript.cfg $(EASYCURSOR_OBJS) c64.lib -Ln $@.label -m $@.map -o $@ 
	@echo ""

speedscript-i80-ec.prg: ASFLAGS += -DEASYCURSOR -DINSTANT80
speedscript-i80-ec.prg: $(EASYCURSOR80_OBJS) speedscript.cfg
	@echo Building $@ ...
	$(LD) -C speedscript.cfg $(EASYCURSOR80_OBJS) c64.lib -Ln $@.label -m $@.map -o $@ 
	@echo ""


cksum:
	@echo ""
	@echo "Verifying checksums.... (You should make sure each pair below matches)"
	@echo ""
	@md5sum speedscript31r2.prg
	@grep ss31r2.c64 tests/official.md5sum.txt
	@echo ""
	@md5sum speedscript32r1.prg
	@grep ss32r1.c64 tests/official.md5sum.txt
	@echo ""
	@md5sum speedscript32r2.prg
	@grep ss32r2.c64 tests/official.md5sum.txt
	@echo ""
	@md5sum speedscriptmodular.prg
	@grep ss32r2.c64 tests/official.md5sum.txt
	@echo ""
	@md5sum speedscript-i80.prg
	@grep ss32r2-i80.c64 tests/official.md5sum.txt
	@echo ""
	@md5sum speedscript-ec.prg
	@grep ss32r2-ec.c64 tests/official.md5sum.txt
	@echo ""
	@md5sum speedscript-i80-ec.prg
	@grep ss32r2-i80-ec.c64 tests/official.md5sum.txt
	@echo ""

clean:
	rm -fr *.prg *.lst *.map *.label src/*.o src/*.lst build/

