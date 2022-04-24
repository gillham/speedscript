<p align="center">
Commodore 64<br>
Source Code
<hr>
</p>

The source code for *SpeedScript* was originally developed on
the PAL assembler (Pro-Line) and -- except for the .ASC and
.WORD pseudo-op -- is compatible with the LADS assembler
from *The Second Book of Machine Language* (COMPUTE! Books,
1984). Line numbers are omitted. Most pseudo-ops are in stan-
dard MOS 6502 notation: *= updates the program counter
(some assemblers use .ORG, .DB, or .DW instead); .BYT or
.BYTE assembles a list of numbers; .WOR or .WORD assem-
bles a list of addresses into low byte/high byte format; .ASC
is used to assemble an ASCII character string (many assem-
blers -- including LADS -- use .BYTE for this also); < extracts
the low byte of a 16-bit expression; > extracts the high byte of
a 16-bit expression (some assemblers reverse the use of < and
\>; others use &255 and /256 to achieve the same effect); and
= is used to assign an express to a label (some assemblers
use .EQU).

Beginners should make sure the undersand *indirect ,y*
addressing, as in LDA ($FB),Y or LDA (CURR),Y. This mode is
used extensively in *SpeedScript*.

Notice that a small portion of *SpeedScript* is listed in
lowercase. This is how it would actually appear on your
screen. It doesn't really matter which mode you're in when
typing in the rest of *SpeedScript* -- just don't SHIFT to get
uppercase.

The VIC version of *SpeedScript* was translated from the 64
source code and developed on the 64. There isn't room to in-
clude it here, but it is very similar. Address $BDCD on the 64
becomes $DDCD on the VIC. References to location 1 (which
maps in and out ROM in the 64) would be omitted for the
VIC. The REFRESH routine, TOPCLR, and a few other rou-
tines were changed. The WINDCOLR variable was changed to
a subroutine, and the HIGHLIGHT and DELITE routines
(which turn on or off the raster interrupt that highlights
the command line) were removed. But about 95 percent of the
source code did not need to be changed. In fact, the transla-
tion only took a single day to get running, and about a week
to test and debug.

*SpeedScript* is written in small modules. Some people
think that subroutines are useful only when a routine is called
more than once. I strongly believe in breaking up a problem
into a number of discrete tasks. These tasks can be written as
subroutines, then tested individually. Once all the modules are
working, just link them together with JSRs and you have a
working program.

I've also tried to use meaningful labels, but sometimes
one just runs out of imagination. Comments are added below
as signposts to guide you through the source code (you
needn't type them in -- if you do, precede each comment with
a semicolon for the sake of your assembler). Modules are also
set apart with blank lines. Notice that some modules are used
in rather creative ways. For example, word left/word right is
used both for moving the cursor and in delimiting a word to
be erased in the erase mode. Also, note that memory locations
are sometimes used instead of meaningful labels. In order to
fit the complete source code in memory at once, I sometimes
had to compromise readability for the sake of brevity.

Crucial to the understanding of *SpeedScript* is the RE-
FRESH routine. Study it carefully. REFRESH is the only time
*SpeedScript* writes directly to the screen (Kernal ROM routine
$FFD2 is used to print on the command line). It automatically
takes care of word-wrap and carriage returns, and provides
useful pointers so that the CHECK routine can easily scroll the
screen. This frees the rest of *SpeedScript* to just move and
modify contiguous memory. Carriage returns are not padded
out in memory with spaces to fill the rest of a line; the RE-
FRESH routine takes care of this transparently.

Also, for the sake of compact code, Kernal and BASIC
routines are used heavily for routines like Save and Load and
for printing numbers.

You'll see some references to location 1, used for mapping
the ROMs in and out of the address space. *SpeedScript* stores
the main text from the end of the program all the way up to
the beginning of I/O space ($CF00). One page of memory is
used as a boundary between text areas (the text buffer starts at
$D000). This may seem superstitious, but it provides for a
margin of error. BASIC is mapped back in when *SpeedScript*
needs to call $BDCD to print a number, and then mapped
back out. The Kernal ROM is left mapped in, since it is con-
stantly called, but it's mapped out when the program needs to
write to or read from the buffer, which is stored beneath the
I/O area and the Kernal. Refer to the memory map shown on
page 126.

##*SpeedScript 3.1* Source code for Commodore 64
... source code follows (in another file) ...

