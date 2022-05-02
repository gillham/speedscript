;
; Updated to SpeedScript 3.2r2
; by Andrew Gillham (gillham@roadsign.com)
;
; Split into modules, but creates an identical
; binary.

.include "c64.inc"
.include "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment "START"

;
; SpeedScript starts at BASIC's normal
; LOAD address, $0801. These lines
; simulate the BASIC line 10 SYS 2061 so
; that Speedscript can be run like any
; BASIC program
            .ORG    2049
            .BYT    $0B,$08,$0A,$00,158
            .BYTE   "2061"
            .BYT    0,0,0

; Called only when run from BASIC. It is
; assumed that the author's initials (that
; conveniently work out in hex) are not
; normally present in memory. If they
; are, we know that SpeedScript has been
; run before, so we avoid the ERASE
; routine to preserve the text in memory.
BEGIN:      JSR     INIT
            LDA     #$CB
            CMP     FIRSTRUN
            STA     FIRSTRUN
            BEQ     SKIPERAS
            JSR     ERASE
SKIPERAS:   JSR     INIT2
            JMP     MAIN


; Each segment is positioned precisely
; to match the original binary.
.segment "MAIN"

; Be explicit about the starting position
; here so this ends up in the correct spot
; in the binary.
            .ORG    2440

; The initialization routine sets up the
; memory map, clears out certain flags,
; and enables the raster interrupt.
INIT:       LDA     #147
            JSR     CHROUT
            LDA     #54
            STA     MAP
            LDA     #0
            STA     INSMODE
            STA     TEXSTART
            STA     TEXEND
            STA     TEXBUF
            STA     BUFEND
            STA     HUNTLEN
            STA     REPLEN
            LDA     #>END
            CLC
            ADC     #1
            STA     TEXSTART+1
            LDA     #$CF
            STA     TEXEND+1
            LDA     #$D0
            STA     TEXBUF+1
            LDA     #$FF
            STA     BUFEND+1
            STA     FPOS+1
            JMP     IOINIT
INIT2:      JSR     KILLBUFF
            LDA     #128
            STA     650
            STA     $9D
            JSR     HIGHLIGHT
            LDA     #<MYNMI
            STA     $318
            LDA     #>MYNMI
            STA     $319
            LDA     TEXSTART
            STA     CURR
            LDA     TEXSTART+1
            STA     CURR+1
            JSR     SYSMSG
            LDA     #<MSG2
            LDY     #>MSG2
            JSR     PRMSG
            INC     MSGFLG
            RTS

; The NOPS are here because I replaced
; a three-byte JSR CHECK with RTS. I
; did not want the size of the code or the
; location of any routines to change. JSR
; CHECK was originally inserted to fix a
; bug, but caused a bug itself.
;
; SpeedScript 3.2r2 patch
; TODO: add an explanation.
; This reverts the 3.2r1 change back to
; 3.1r2 with NOPs.
            NOP
            NOP

; SYSMSG displays "SpeedScript 3.2".
; The message flag (MSGFLAG) is set
; when a message is to be left on the
; screen only until the next keystroke.
; After that keystroke, SYSMSG is called.
; The INIT routine also prints the credit
; line with the MSGFLG set so that you
; won't have to stare at the author's
; name while you're writing -- a modesty
; feature.
SYSMSG:     JSR     TOPCLR
            LDA     #<MSG1
            LDY     #>MSG1
            JSR     PRMSG
            LDA     #0
            STA     MSGFLG
            RTS

; This routine traps the RESTORE key. It
; reproduces some of the ROM code so
; that RS-232 is still supported (although
; SpeedScript does not directly support
; RS-232 output).
MYNMI:      PHA
            TXA
            PHA
            TYA
            PHA
            LDA     #$7F
            STA     $DD0D
            LDY     $DD0D
            BPL     NOTRS
            JMP     $FE72

; If RESTORE is pressed, we have to fix
; the cursor in case it was lit.
NOTRS:      LDA     BLINKFLAG
            BEQ     NOTCURSOR
            LDA     UNDERCURS
            LDY     #0
            STA     (CURR),Y
NOTCURSOR:  LDA     #2
            STA     WINDCOLR
            JSR     CLRCHN
            JSR     TOPCLR
            LDA     #<XITMSG
            LDY     #>XITMSG
            JSR     PRMSG
            JSR     YORN
            BNE     REBOOT
            JSR     DELITE
            SEI
            LDA     #$7F
            JMP     $FE66
REBOOT:     JSR     DELITE
            LDX     #$FA
            TXS
            JSR     INIT2
            JMP     MAIN

; TOPCLR keeps the command line
; clean. It is called before most messages.
; It's like a one-line clear-screen
TOPCLR:     LDX     #39
            LDA     #32
TOPLOOP:    STA     1024,X
            DEX
            BPL     TOPLOOP
            LDA     #19
            JMP     CHROUT

; Converts Commodore ASCII to screen
; codes.
ASTOIN:     PHA
            AND     #128
            LSR
            STA     TEMP
            PLA
            AND     #63
            ORA     TEMP
            RTS

            .ORG    2665
; The MAIN loop blinks the cursor,
; checks for keystrokes, converts them
; from ASCII to screen codes, puts them
; in text at the CURRent position, and in-
; crements the CURRent position and
; LASTLINE. It also checks for special
; cases like the back arrow and the re-
; turn key, and passes control characters
; to the CONTROL routine. SHIFTed
; spaces are turned into unSHIFTed ones.
; The INSMODE flag is checked to see if
; we should insert a space before a
; character.
MAIN:       LDY     #0
            STY     BLINKFLAG
            LDA     (CURR),Y
            STA     UNDERCURS
MAIN2:      LDY     #0
            LDA     (CURR),Y
            EOR     #$80
            STA     (CURR),Y
            LDA     BLINKFLAG
            EOR     #1
            STA     BLINKFLAG
            JSR     REFRESH
WAIT:       JSR     GETIN
            BNE     KEYPRESS
            LDA     162
            AND     #16
            BEQ     WAIT
            LDA     #0
            STA     162
            JMP     MAIN2
KEYPRESS:   TAX
            LDY     #0
            LDA     UNDERCURS
            STA     (CURR),Y
            STY     BLINKFLAG
            CPX     #95
            BNE     NOTBKS
            JSR     LEFT
            LDA     #32
            LDY     #0
            STA     (CURR),Y
            JMP     MAIN
NOTBKS:     LDA     MSGFLG
            BEQ     NOMSG
            TXA
            PHA
            JSR     SYSMSG
            PLA
            TAX
NOMSG:      TXA
            CMP     #13
            BNE     NOTCR
            LDX     #RETCHAR+64
NOTCR:      TXA
            AND     #127
            CMP     #32
            BCC     CONTROL
            CPX     #160
            BNE     NESHIFT
            LDX     #32
NESHIFT:    TXA
            PHA
            LDY     #0
            LDA     (CURR),Y
            CMP     #RETCHAR
            BEQ     DOINS
            LDA     INSMODE
            BEQ     NOTINST
DOINS:      JSR     INSCHAR
NOTINST:    PLA
            JSR     ASTOIN
PUTCHR:     LDY     #0
            STA     (CURR),Y
            JSR     REFRESH
            SEC
            LDA     CURR
            SBC     LASTLINE
            STA     TEMP
            LDA     CURR+1
            SBC     LASTLINE+1
            ORA     TEMP
            BCC     INKURR
            LDA     CURR
            ADC     #0
            STA     LASTLINE
            LDA     CURR+1
            ADC     #0
            STA     LASTLINE+1
INKURR:     INC     CURR
            BNE     NOINC2
            INC     CURR+1
NOINC2:     JSR     CHECK
            JMP     MAIN



; Each segment is positioned precisely
; to match the original binary.
.segment    "DATA"
; 
; Be explicit about the starting position
; here so this ends up in the correct spot
; in the binary.
;

            .ORG    7698
; The message table should be typed in
; the lowercase mode
; (SHIFT-Commodore key).
MSG1:       .byt    8,14,155,146
            .asciiz "SpeedScript 3.2"
MSG2:       .asciiz " by Charles Brannon"
KILLMSG:    .asciiz "Buffer Cleared"
BUFERR:     .asciiz "Buffer Full"
DELMSG:     .asciiz "Delete (S,W,P)"
YMSG:       .asciiz ": Are you sure? (Y/N):"
CLRMSG:     .asciiz "ERASE ALL TEXT"
ERASMSG:    .byte   "Erase (S,W,P): "
            .byt    18
            .byte   "RETURN"
            .byt    146
            .asciiz " to exit"
FORMSG:     .asciiz "Press format key:"
SAVMSG:     .asciiz "Save:"
FNF:        .asciiz "Tape ERROR"
BRMSG:      .asciiz "Stopped"
VERERR:     .asciiz "Verify Error"
OKMSG:      .asciiz "No errors"
TDMSG:      .byt    147,32,18,212,146
            .byte   "ape or "
            .byt    18,196,146
            .asciiz "isk?"
LOADMSG:    .asciiz "Load:"
VERMSG:     .asciiz "Verify:"
DIRMSG:     .byte   "Press "
            .byt    18
            .byte   "RETURN"
            .byt    146,0
DCMSG:      .asciiz "Disk command:"
DIRNAME:    .byte   "$"
INSERR:     .asciiz "No Room"
INSMSG:     .asciiz "No text in buffer."
CHOOSEMSG:  .byt    147
            .byte   "Print to: "
            .byt    18,211,146
            .byte   "creen,"
            .byt    18,196,146
            .byte   "isk,"
            .byt    18,208,146
            .asciiz "rinter?"
DEVMSG:     .asciiz "Device number?"
SADRMSG:    .asciiz "Secondary Address #?"
FNMSG:      .asciiz "Print to filename:"
PRINMSG:    .byt    147
            .byte   "Printing..."
            .byt    13,13,0
WAITMSG:    .byte   "Insert next sheet, press "
            .byt    18
            .byte   "RETURN"
            .byt    146,0
SRCHMSG:    .asciiz "Hunt for:"
NFMSG:      .asciiz "Not Found"
REPMSG:     .asciiz "Replace with:"
XITMSG:     .asciiz "EXIT SpeedScript"

; Each segment is positioned precisely
; to match the original binary.
.segment    "ENDPAD"
; Be explicit about the starting position
; here so this ends up in the correct spot
; in the binary.
            .ORG    9330

;
; SpeedScript 3.2r2 patch
; TODO: Is there a better way to do this?
;
; Some padding to match the official release.
            .byte   00
END:        .END            ;+$100 is TEXSTART
