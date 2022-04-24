# *SpeedScript* 3.1 source code
The *SpeedScript_3.1_verbatim.asm* file is as close to exactl as it was printed
to assist with proofreading.  It needs some wrapping cleaned up.

The *SpeedScript_3.1.asm* file has a few modifications:
 A couple of LDAs subtracted 1 from the high-byte and the low-byte 
 Some wrapping / indenting in tables and other data was combined on a single line. 
 .BYTE/.byte was used consistently instead of mostly .BYT with a few .BYTE also.
 FOUNDSPAC (the label) was changed to FOUNDSPACE as that is how it was called.
 FOUNDSPACE was used in the "verbatim" file also. (yes, not exactly verbatim I know)

NOTE: This was not tested with the PAL assembler (it is missing line numbers)
and just had a couple of glaring issues fixed up.  You definitely should use
the CA65 version as it generates a binary that matches the official release.

The *SpeedScript_3.1_notes.md* file has the original author's introduction and
explanations.  It will probably be in a top level README, but leaving it here
with the original source as typed in.

Original source is from archive.org:
https://archive.org/details/Computes_Speedscript

