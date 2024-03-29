# Source code for *SpeedScript* by Charles Brannon

## Intro

This repository has the source code for the *SpeedScript* word processor by Charles Brannon for the Commodore 64.

The "original" source as shown in the book in is the `original` directory.  Also in the `original` directory are monolithic versions converted to `ca65` format. The code in `src` has been split up into different modules, but by using segments it generates the exact same matching binary as originally released for *SpeedScript* 3.2r2. It is a bit clumsy right now, but is my first attempt and should get cleaned up a bit over time.

More work is needed to add patches and use conditional assembly.  This will allow us to build the original binaries as well as versions with certain patches.  For example, building *SpeedScript-80* should be fairly straight-forward, while building *SpeedScript 128* would be more involved.  Short patches are more readily reverse engineered and integrated. I'm not aware of any source for *SpeedScript-80*, *SpeedScript 128*, or *SpeedScript 128 Plus* so it will have to be reverse engineered from a disassembly.

Note that *SpeedScript-80* is a set of patches for 80 column mode on a C128 in C64 mode.  There is a *Instant 80* patch for the C64 that provides a software based 80 column preview with the print to screen feature. 

## SpeedScript Overview

The *SpeedScript* word processor was very popular as it was made freely available as a "type-in" program in COMPUTE! Magazine and COMPUTE! Gazette.  It was available for the Commodore 64/128, VIC-20, Atari 800, and Apple II.

This repository has the source code as published by COMPUTE! Magazine in a book made up of several articles from the magazines.  The source code was not made available in the magazines.  Primarily due to its length I would assume and the fact that most end users wouldn't be able to use it.  They were interested in using the word processor directly and wouldn't have the PAL Assembler.

The book is available here: https://archive.org/details/Computes_Speedscript

I could not find this source code anywhere on the Internet (other than the scans at archive.org) so I went ahead and typed it all in as close to the original printed form as possible.  Look in the 'original' directory.

After proofreading it several times (and regularly catching my typing errors) I converted it to CA65 format. CA65 is the assembler portion of the CC65 cross compiler.  This is the same tool used for the reverse engineered GEOS source code. I hope to improve upon my work here and modularize the source code and add the ability to conditionally assemble additional features.  Many additional features were released as patches and I would like to incorporate them here as assembler source code.

## Building

You can build *SpeedScript* by running make:
```bash
$ make
```

You can also just run the tool directly on monolithic sources:
```bash
$ cl65 --cpu 6502x -o speedscript32r2.prg -t c64 -C c64-asm.cfg original/speedscript32r2.s
```
Running make also builds `speedscript-i80.prg` which integrates the *Instant 80* patch that provides a software 80 column (or soft-80) preview to screen.  It also builds `speedscript-ec.prg` which integrates the *Easy Cursor* patch.  The `speedscript-i80-ec.prg` file combines both *Instant 80* and *Easy Cursor* in one program.

Please submit a pull request, open an issue, or otherwise contact me for improvements to the build process.

## Usage

Transfer the `speedscript.prg` or `speedscript-80.prg` file to your Commodore 64 or emulator and load it. 
```
READY.
LOAD"SPEEDSCRIPT",8

SEARCHING FOR SPEEDSCRIPT
LOADING
READY.
RUN
```

Here is a quick reference table of *SpeedScript* keystrokes.

| Keystroke  | Function |
| ------------- | ------------- |
| CTRL A | Change case (of letter under cursor) |
| CTRL B | Change border color  |
| CTRL D | Delete (Sentence, Word, Paragraph) (to the left) |
| CTRL E | Erase (Sentence, Word, Paragraph) (to the right) |
| CTRL G | Global search and replace |
| CTRL H | Hunt for phrase <br> with SHIFT: Select hunt phrase |
| CTRL I | Enter/exit insert mode |
| CTRL J | Replace <br> with SHIFT: Select replace phrase |
| CTRL K | Kill buffer |
| CTRL L | Change text character color |
| CTRL P | Print |
| CTRL R | Restore buffer |
| CTRL V | Verify |
| CTRL X | Transpose characters |
| CTRL Z | Go to end of text |
| CTRL = | Display amount of free memory |
| CTRL ⇧ | Send disk command or read error channel |
| CTRL 4 | Display disk directory |
| CTRL £ | Enter format (printer) commands |
| CTRL 3 | Commodore 64 only: Same as CTRL-£ |
| SHIFT CTRL P | Print to (Screen, Disk, Printer) with options |
| CLR/HOME | Press once to go to top of screen <br> Hold down to go to top of text <br> with SHIFT: Erase all text |
| CRSR (left/right) | Move the cursor left one character <br> with SHIFT: Move the cursor right one character |
| CRSR (up/down) | Go to next sentence <br> with SHIFT: Go to previous sentence |
| RUN/STOP | Indent 5 spaces <br> with SHIFT: Insert 255 spaces |
| RESTORE | Exit *SpeedScript* (Commodore 64) <br> with RUN/STOP: Exit *SpeedScript* (VIC-20) |
| ⇦ | Backspace <br> with CTRL: Delete character under cursor and close up text <br> with SHIFT and CTRL: Delete all spaces from cursor to next character |
| RETURN | Return mark <br> with SHIFT: End paragraph, add an extra return mark, and indent next paragraph |
| INST/DEL | Delete character <br> with SHIFT: Insert space |
| F1 | Next Word |
| F2 | Previous Word |
| F3 | Next Sentence |
| F4 | Previous Sentence |
| F5 | Next Paragraph |
| F6 | Previous Paragraph |
| F7 | Load |
| F8 | Save|


## Patches

I would like to add other versions as well as various patches. I'm not that familiar with the patches, but now that I have the base code working I can investigate. ~~The 80 column preview mode and cursor handling seem like fairly desirable patches.~~ *Instant 80* and *Easy Cursor* have been integrated.  I'm still looking for other official (published in magazines) and unofficial patches.

Potential patches:
 - 80 column mode for C128
 - ~~80 column preview for C64  (screen "printing" in 80 columns)~~
 - ~~Cursor improvements (Easy Cursor patch for 3.2)~~
 - SpeedScript 128 (major rewrite)
 - SpeedScript 128 Plus
 - Your favorite patch...


Please submit a pull request, open an issue, or otherwise contact me if you have source code for a patch.




## Copyright / License information

The information below is an excerpt from the original printed book.

<pre>
The following articles were originally published in COMPUTE! magazine, copyright 
1985, COMPUTE! Publications, Inc.: "SpeedScript 3.0: All Machine Language Word 
Processor For Commodore 64" (March), "SpeedScript 3.0: All Machine Language 
Word Processor For Expanded VIC-20" (April), and "ScriptSave" (May). 

Copyright 1985, COMPUTE! Publications, Inc. All rights reserved 

Reproduction or translation of any part of this work beyond that permitted by Sec- 
tions 107 and 108 of the United States Copyright Act without the permission of the 
copyright owner is unlawful. 

Printed in the United States of America 

10 987654321 

ISBN 0-942386-94-9 

COMPUTE! Publications, Inc., Post Office Box 5406, Greensboro, NC 27403, (919) 
275-9809, is one of the ABC Publishing Companies and is not associated with any 
manufacturer of personal computers. Commodore 64 and VIC-20 are trademarks of 
Commodore Electronics Limited. 
</pre>

# Author's introduction and explanation of source code.
Below is the type-in introduction offered in the book by the original author.
He explains important details about the design of the editor and the layout of
the source code.


## Source Code Introduction from Charles Brannon
<hr>
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
