;
; Updated to SpeedScript 3.2r1
; by Andrew Gillham (gillham@roadsign.com)
;
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

; Locations used by high-speed memory
; move routines:
FROML       =       $26
FROMH       =       $27
DESTL       =       $9E
DESTH       =       $9F
LLEN        =       $B4
HLEN        =       $B5

; CURR: Position of cursor within text
; memory. SCR: used by the REFRESH
; routine.
CURR        =       $39
SCR         =       $C3

; TEX: An alternate location used in tan-
; dem with CURR. COLR is used by RE-
; FRESH. TEMP is used throughout as a
; reusable scratchpad pointer. INDIR is
; also a reusable indirect pointer.
; UNDERCURS stores the value of the
; character highlighted by the cursor.
TEX         =       $FB
COLR        =       $14
TEMP        =       $3B
INDIR       =       $FD
UNDERCURS   =       $02

; WINDCOLR: Color of command line
; window supported by REFERSH. MAP
; is the 6510's built-in I/O port, used for
; mapping in and out ROMs from the
; address space. RETCHAR is the screen-
; code value of the return mark (a left-
; pointing arrow).
WINDCOLR    =       $0C
MAP         =       $01
RETCHAR     =       31

; Kernal Routines (refer to the Com-
; modore 64 Programmer's Reference
; Guide):
CHROUT      =       $FFD2
STOP        =       $FFE1
SETLFS      =       $FFBA
SETNAM      =       $FFBD
CLALL       =       $FFE7
OPEN        =       $FFC0
CHRIN       =       $FFCF
CHKIN       =       $FFC6
CHKOUT      =       $FFC9
GETIN       =       $FFE4
CLRCHN      =       $FFCC
CLOSE       =       $FFC3
LOAD        =       $FFD5
SAVE        =       $FFD8
IOINIT      =       $FF84

; Mark code segment
            .CODE
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

; UMOVE is a high-speed memory move
; routine. It gets its speed from self-
; modifying code (the $0000's at
; MOVLOOP are replaced by actual ad-
; dresses when UMOVE is called). Some
; assemblers may assemble this as a
; zero-page mode, so you may want to
; change the $0000's to $FFFF's. UMOVE
; is used to move an overlapping range
; of memory upward, so it is used to de-
; lete. Set FROML/FROMH to point to
; the source area of memory,
; DESTL/DESTH to point to the destina-
; tion, and LLEN/HLEN to hold the
; length of the area being moved.
UMOVE:      LDA     FROML
            STA     MOVLOOP+1
            LDA     FROMH
            STA     MOVLOOP+2
            LDA     DESTL
            STA     MOVLOOP+4
            LDA     DESTH
            STA     MOVLOOP+5
            LDX     HLEN
            BEQ     SKIPMOV
MOV1:       LDA     #0
MOV2:       STA     ENDPOS
            LDY     #0
MOVLOOP:    LDA     $0000,Y
            STA     $0000,Y
            INY
            CPY     ENDPOS
            BNE     MOVLOOP
            INC     MOVLOOP+2
            INC     MOVLOOP+5
            CPX     #0
            BEQ     OUT
            DEX
            BNE     MOV1
SKIPMOV:    LDA     LLEN
            BNE     MOV2
OUT:        RTS

; DMOVE uses the same variables as
; UMOVE, but is used to move an
; overlapping block of memory down-
; ward, so it is used to insert. If the block
; of memory to be moved does not over-
; lap the destination area, then either
; routine can be used.
DMOVE:      LDA     HLEN
            TAX
            ORA     LLEN
            BNE     NOTNULL
            RTS
NOTNULL:    CLC
            TXA
            ADC     FROMH
            STA     DMOVLOOP+2
            LDA     FROML
            STA     DMOVLOOP+1
            CLC
            TXA
            ADC     DESTH
            STA     DMOVLOOP+5
            LDA     DESTL
            STA     DMOVLOOP+4
            INX
            LDY     LLEN
            BNE     DMOVLOOP
            BEQ     SKIPDMOV
DMOV1:      LDY     #255
;
; SpeedScript 3.2r1 patch
; TODO: decide if this should be a
; new variable.  It is pointing
; into the FTBUFF it appears.
;
DMOVLOOP:   LDA     $2452,Y
            STA     $2457,Y
            DEY
            CPY     #255
            BNE     DMOVLOOP
SKIPDMOV:   DEC     DMOVLOOP+2
            DEC     DMOVLOOP+5
            DEX
            BNE     DMOV1
            RTS

; REFRESH copies a screenful of text
; from the area of memory pointed to by
; TOPLIN. It works like a printer routine,
; fitting a line of text between the screen
; margins, wrapping words, and restarts
; at the left margin after printing a car-
; riage return. SpeedScript constantly calls
; this routine while the cursor is blink-
; ing, so it has to be very fast. To elimi-
; nate flicker, it also clears out the end of
; each line instead of first clearing the
; screen. It stores the length of the first
; screen line for the sake of the CHECK
; routine (which scrolls up by adding
; that length to TOPLIN), the last text
; location referenced (so CHECK can see
; if the cursor has moved off the visible
; screen).
REFRESH:    LDA     #40
            STA     SCR
            STA     COLR
            LDA     #4
            STA     SCR+1
            LDA     #$D8
            STA     COLR+1
            LDA     TOPLIN
            STA     TEX
            LDA     TOPLIN+1
            STA     TEX+1
            LDX     #1
            LDA     INSMODE
            STA     WINDCOLR
            LDA     SCRCOL
            STA     53280
PPAGE:      LDY     #0
PLINE:      LDA     TEXCOLR
            STA     (COLR),Y
            LDA     (TEX),Y
            STA     LBUFF,Y
            INY
            AND     #127
            CMP     #RETCHAR
            BEQ     BREAK
            CPY     #40
            BNE     PLINE
            DEY
SLOOP:      LDA     (TEX),Y
            AND     #127
NXCUR:      CMP     #32
            BEQ     SBRK
            DEY
            BNE     SLOOP
            LDY     #39
SBRK:       INY
BREAK:      STY     TEMP
            DEY
COPY:       LDA     LBUFF,Y
            STA     (SCR),Y
            DEY
            BPL     COPY
            LDY     TEMP
            CLC
            TYA
            ADC     TEX
            STA     TEX
            LDA     TEX+1
            ADC     #0
            STA     TEX+1
            CPX     #1
            BNE     CLRLN
            STY     LENTABLE
CLRLN:      CPY     #40
            BEQ     CLEARED
            LDA     #32
            STA     (SCR),Y
            INY
            JMP     CLRLN
CLEARED:    CLC
            LDA     SCR
            ADC     #40
            STA     SCR
            STA     COLR
            BCC     INCNOT
            INC     SCR+1
            INC     COLR+1
INCNOT:     INX
            CPX     #25
            BEQ     PDONE
            JMP     PPAGE
PDONE:      LDA     TEX
            STA     BOTSCR
            LDA     TEX+1
            STA     BOTSCR+1
            RTS

; The following routine fills the entire
; text area with space charactes (screen
; code 32), effectively erasing all text. It
; is called when the program is first run,
; and when an Erase All is performed.
ERASE:      LDA     TEXSTART
            STA     TEX
            STA     TOPLIN
            STA     LASTLINE
            STA     CURR
            LDA     TEXSTART+1
            STA     TEX+1
            STA     TOPLIN+1
            STA     LASTLINE+1
            STA     CURR+1
            SEC
            LDA     TEXEND+1
            SBC     TEXSTART+1
            TAX
            LDA     #32
CLRLOOP:    LDY     #255
            DEC     TEX+1
            STA     (TEX),Y
            INY
            INC     TEX+1
CLR2:       STA     (TEX),Y
            INY
            BNE     CLR2
            INC     TEX+1
            DEX
            BNE     CLR2
            STA     (TEX),Y
            RTS

; PRMSG is used anytime we need to
; print something at the top of the screen
; (the command line). Pass it the address
; of the message to be printed by storing
; the low byte of the address in the accu-
; mulator, and the high byte in the Y
; register. The message in memory must
; end with a zero byte. The routine does
; not add a carriage return
PRMSG:      STA     TEMP
            STY     TEMP+1
            LDY     #0
PRLOOP:     LDA     (TEMP),Y
            BEQ     PREXIT
            JSR     CHROUT
            INY
            BNE     PRLOOP
PREXIT:     RTS
GETAKEY:    JSR     GETIN
            BEQ     GETAKEY
            RTS

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
; SpeedScript 3.2r1 patch
; TODO: figure out what this was doing.
;
            LDA     ($0B), Y

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
; The INSMODE flag is check to see if
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

; CONTROL looks up a keyboard com-
; mand in the list of control codes at
; CTBL. The first byte of CTBL is the ac-
; tual number of commands. Once the
; position is found, this position is dou-
; bled as an index to the two-byte ad-
; dress table at VECT. The address of
; MAIN-1 is put on the stack, simulat-
; ing the return address; then the address
; of the command routine taken from
; VECT is pushed. We then perform an
; RTS. RTS pulls the bytes off the stack
; as if they were put there by a JSR. This
; powerful technique is used to simulate
; ON-GOTO in machine language.
CONTROL:    TXA
            LDX     CTBL
SRCH:       CMP     CTBL,X
            BEQ     FOUND
            DEX
            BNE     SRCH
            JMP     MAIN
FOUND:      DEX
            TXA
            ASL     A
            TAX
; A bug in the original printed source code was fixed below.
; The original source had 'LDA #>MAIN-1' which didn't
; generate correct code matching the original binary.
; Parentheses were added for explicit precedence.
            LDA     #>(MAIN-1)
            PHA
            LDA     #<MAIN-1
            PHA
            LDA     VECT+1,X
            PHA
            LDA     VECT,X
            PHA
            RTS
CTBL:       .BYT    39
            .BYT    29,157,137,133,2,12,138,134,20,148
            .BYT    4,19,9,147,135,139,5,136,140
            .BYT    22,145,17,159,18,24,26,16
            .BYT    28,30,6,1,11,8,31,3,131
            .BYT    10,141,7
VECT:       .WORD   RIGHT-1,LEFT-1,WLEFT-1,WRIGHT-1,BORDER-1,LETTERS-1
            .WORD   SLEFT-1,SRIGHT-1,DELCHAR-1,INSCHAR-1,DELETE-1
            .WORD   HOME-1,INSTGL-1,CLEAR-1,PARIGHT-1,PARLEFT-1
            .WORD   ERAS-1,TLOAD-1,TSAVE-1,VERIFY-1
            .WORD   SLEFT-1,SRIGHT-1,CATALOG-1,INSBUFFER-1,SWITCH-1
            .WORD   ENDTEX-1,PRINT-1,FORMAT-1,DCMND-1
            .WORD   DELIN-1,ALPHA-1,KILLBUFF-1,HUNT-1,FREEMEM-1,TAB-1
            .WORD   LOTTASPACES-1,REPSTART-1,ENDPAR-1,SANDR-1

; The check routine first prevents the
; cursor from disappearing past the
; beginning or end-of-text memory, and
; prevents us from cursoring past the
; end-of-text pointer. It also checks to see
; if the cursor has left the visible screen,
; scrolling with REFRESH to make the
; cursor visible. The double-byte SBCs
; are used as a 16-bit CMP macro, setting
; the Z and C flags just like CMP does.
CHECK:      JSR     CHECK2
            SEC
            LDA     CURR
            SBC     TOPLIN
            LDA     CURR+1
            SBC     TOPLIN+1
            BCS     OK1
            SEC
            LDA     TOPLIN
            SBC     TEXSTART
            STA     TEMP
            LDA     TOPLIN+1
            SBC     TEXSTART+1
            ORA     TEMP
            BEQ     OK1
            LDA     CURR
            STA     TOPLIN
            LDA     CURR+1
            STA     TOPLIN+1
            JSR     REFRESH
OK1:        SEC
            LDA     BOTSCR
            SBC     CURR
            STA     TEX
            LDA     BOTSCR+1
            SBC     CURR+1
            STA     TEX+1
            ORA     TEX
            BEQ     EQA
            BCS     OK2
EQA:        CLC
            LDA     TOPLIN
            ADC     LENTABLE
            STA     TOPLIN
            LDA     TOPLIN+1
            ADC     #0
            STA     TOPLIN+1
REF:        JSR     REFRESH
            JMP     OK1
OK2:        RTS
CHECK2:     SEC
            LDA     LASTLINE
            SBC     TEXEND
            STA     TEMP
            LDA     LASTLINE+1
            SBC     TEXEND+1
            ORA     TEMP
            BCC     CK3
            LDA     TEXEND
            STA     LASTLINE
            LDA     TEXEND+1
            STA     LASTLINE+1
CK3:        SEC
            LDA     CURR
            SBC     TEXSTART
            STA     TEMP
            LDA     CURR+1
            SBC     TEXSTART+1
            ORA     TEMP
            BCS     INRANGE
            LDA     TEXSTART
            STA     CURR
            LDA     TEXSTART+1
            STA     CURR+1
            RTS
INRANGE:    SEC
            LDA     CURR
            SBC     LASTLINE
            STA     TEMP
            LDA     CURR+1
            SBC     LASTLINE+1
            ORA     TEMP
            BCS     OUTRANGE
            RTS
OUTRANGE:   LDA     LASTLINE
            STA     CURR
            LDA     LASTLINE+1
            STA     CURR+1
            RTS

; Move cursor right.
RIGHT:      INC     CURR
            BNE     NOINCR
            INC     CURR+1
NOINCR:     JMP     CHECK

; Cursor left.
LEFT:       LDA     CURR
            BNE     NODEC
            DEC     CURR+1
NODEC:      DEC     CURR
            JMP     CHECK

; Word left. We look backward for a space.
WLEFT:      LDA     CURR
            STA     TEX
            LDA     CURR+1
            STA     TEX+1
            DEC     TEX+1
            LDY     #$FF
STRIP:      LDA     (TEX),Y
            CMP     #32
            BEQ     STRLOOP
            CMP     #RETCHAR
            BNE     WLOOP
STRLOOP:    DEY
            BNE     STRIP
WLOOP:      LDA     (TEX),Y
            CMP     #32
            BEQ     WROUT
            CMP     #RETCHAR
            BEQ     WROUT
            DEY
            BNE     WLOOP
            RTS
WROUT:      SEC
            TYA
            ADC     TEX
            STA     CURR
            LDA     TEX+1
            ADC     #0
            STA     CURR+1
            JMP     CHECK

; Word right. We scan forward for a
; space. OIDS is not a meaningful label.
WRIGHT:     LDY     #0
RLOOP:      LDA     (CURR),Y
            CMP     #32
            BEQ     ROUT
            CMP     #RETCHAR
            BEQ     ROUT
            INY
            BNE     RLOOP
            RTS
ROUT:       INY
            BNE     OIDS
            INC     CURR+1
            LDA     CURR+1
            CMP     LASTLINE+1
            BCC     OIDS
            BNE     LASTWORD
OIDS:       LDA     (CURR),Y
            CMP     #32
            BEQ     ROUT
            CMP     #RETCHAR
            BEQ     ROUT

; Add the Y register to the CURRent
; cursor position to move the cursor.
; CHECK prevents illegal cursor move-
; ment. LASTWORD is called if the end
; of the word cannot be found with 255
; characters.
ADYCURR:    CLC
            TYA
            ADC     CURR
            STA     CURR
            LDA     CURR+1
            ADC     #0
            STA     CURR+1
WRTN:       JMP     CHECK
LASTWORD:   LDA     LASTLINE
            STA     CURR
            LDA     LASTLINE+1
            STA     CURR+1
            JMP     CHECK

; ENDTEX is tricky. If the end-of-text
; pinter would point to an area already
; visible on the screen, we just move the
; cursor there and call REFRESH. Other-
; wise, we step back 1K from the end-of-
; text and then scroll to the end. This is
; necessary since in worst case only 24
; characters of return marks would fill
; the screen.
ENDTEX:     LDA     #0
            STA     TOPLIN
            LDA     LASTLINE+1
            SEC
            SBC     #4
            CMP     TEXSTART+1
            BCS     SAFE
            LDA     TEXSTART+1
SAFE:       STA     TOPLIN+1
            JSR     REFRESH
            JMP     LASTWORD

; The raster interupt automatically
; places SCRCOL into 53281 when
; appropriate. The AND keeps SCRCOL
; within a legal range (I know that's not
; really necessary).
BORDER:     INC     SCRCOL
            LDA     SCRCOL
            AND     #15
            STA     SCRCOL
            RTS
SCRCOL:     .BYTE   12

; TEXCOLR (text color) is used in the
; REFERSH routine and stored into color
; memory. Both SCRCOL and TEXCOLR
; are stored wihin the SpeedScript code
; so that after they're changed, you can
; resave SpeedScript and it will come up
; with your color choice in the future.
LETTERS:    INC     TEXCOLR
            LDA     TEXCOLR
            AND     #15
            STA     TEXCOLR
            JMP     REFRESH
TEXCOLR:    .BYTE   11

; Sentence left. We look backward ofr
; ending punctuation or a return mark,
; then go forward until we run out of
; spaces.
SLEFT:      LDA     CURR
            STA     TEX
            LDA     CURR+1
            STA     TEX+1
            DEC     TEX+1
            LDY     #$FF
PMANY:      LDA     (TEX),Y
            CMP     #'.'
            BEQ     PSRCH
            CMP     #'!'
            BEQ     PSRCH
            CMP     #'?'
            BEQ     PSRCH
            CMP     #RETCHAR
            BNE     PSLOOP
PSRCH:      DEY
            BNE     PMANY
            RTS
PSLOOP:     LDA     (TEX),Y
            CMP     #'.'
            BEQ     PUNCT
            CMP     #'!'
            BEQ     PUNCT
            CMP     #'?'
            BEQ     PUNCT
            CMP     #RETCHAR
            BEQ     PUNCT
            DEY
            BNE     PSLOOP
            DEC     TEX+1
            LDA     TEX+1
            CMP     TEXSTART
            BCS     PSLOOP
            JMP     FIRSTWORD
PUNCT:      STY     TEMP
            DEC     TEMP
SKIPSPC:    INY
            BEQ     REPEAT
            LDA     (TEX),Y
            CMP     #32
            BEQ     SKIPSPC
            DEY
            JMP     WROUT
REPEAT:     LDY     TEMP
            JMP     PSLOOP
FIRSTWORD:  LDA     TEXSTART
            STA     CURR
            LDA     TEXSTART+1
            STA     CURR+1
            JMP     CHECK

; Sentence right. We look forward for
; ending punctuation, then skip forward
; until we run out of spaces.
SRIGHT:     LDY     #0
SRLP:       LDA     (CURR),Y
            CMP     #'.'
            BEQ     PUNCT2
            CMP     #'!'
            BEQ     PUNCT2
            CMP     #'?'
            BEQ     PUNCT2
            CMP     #RETCHAR
            BEQ     PUNCT2
            INY
            BNE     SRLP
            INC     CURR+1
            LDA     CURR+1
            CMP     LASTLINE+1
            BEQ     SRLP
            BCC     SRLP
SREXIT:     JMP     LASTWORD
PUNCT2:     INY
            BNE     NOFIXCURR
            INC     CURR+1
            LDA     CURR+1
            CMP     LASTLINE+1
            BCC     NOFIXCURR
            BEQ     NOFIXCURR
            JMP     LASTWORD
NOFIXCURR:  LDA     (CURR),Y
            CMP     #32
            BEQ     PUNCT2
            CMP     #'.'
            BEQ     PUNCT2
            CMP     #'!'
            BEQ     PUNCT2
            CMP     #'?'
            BEQ     PUNCT2
            CMP     #RETCHAR
            BEQ     PUNCT2
            JMP     ADYCURR

; The text buffer starts at a fixed location,
; but the end of the buffer is changed as
; text is added to it. To clear the buffer,
; we just set the end of the buffer to the
; value of the start of the buffer. No text
; is actually erased.
KILLBUFF:   LDA     TEXBUF
            STA     TPTR
            LDA     TEXBUF+1
            STA     TPTR+1
            JSR     TOPCLR
            LDA     #<KILLMSG
            LDY     #>KILLMSG
            JSR     PRMSG
            LDA     #1
            STA     MSGFLG
            RTS

; This is the second level of the general-
; purpose delete routines. UMOVE is the
; primitive core of deleting. For CTRL-D,
; the current cursor position is the
; source, then a cursor command is
; called to update the cursor pointer. This
; becomes the destination. For CTRL-E,
; the current cursor position is the
; destination, a cursor routine is called,
; and this becomes the source. UMOVE
; is then called. We actually move more
; than the length from the source to the
; end-of-text. some extra text is moved
; from past the end-of-text. Since every-
; thing past the end-of-text is spaces, this
; neatly erases everything past the new
; end-of-text position. Naturally, the end-
; of-text pointer is updated. Before the
; actual delete is performed, the text to
; be deleted is stored in the buffer so
; that it can be recalled in case of error.
; The buffer doubles as a fail-safe device
; and for moving and copying text.
; Checks are made to make sure that the
; buffer does not overflow.
DEL1:       SEC
            LDA     CURR
            SBC     TEXSTART
            STA     TEMP
            LDA     CURR+1
            SBC     TEXSTART+1
            ORA     TEMP
            BNE     DEL1A
DELABORT:   PLA
            PLA
            RTS
DEL1A:      LDA     CURR
            STA     FROML
            LDA     CURR+1
            STA     FROMH
            RTS
DEL2:       SEC
            LDA     CURR
            STA     DESTL
            EOR     #$FF
            ADC     FROML
            STA     GOBLEN
            LDA     CURR+1
            STA     DESTH
            EOR     #$FF
            ADC     FROMH
            STA     GOBLEN+1
DELC:       LDA     FROML
            STA     FROMSAV
            LDA     FROMH
            STA     FROMSAV+1
            LDA     DESTL
            STA     DESTSAV
            STA     FROML
            LDA     DESTH
            STA     DESTSAV+1
            STA     FROMH
            SEC
            LDA     GOBLEN+1
            ADC     TPTR+1
            CMP     BUFEND+1
            BCC     GOSAV
            JSR     TOPCLR
            LDA     #<BUFERR
            LDY     #>BUFERR
            JSR     PRMSG
            LDA     #1
            STA     MSGFLG
            LDA     #0
            STA     198
            RTS
GOSAV:      LDA     TPTR
            STA     DESTL
            LDA     TPTR+1
            STA     DESTH
            LDA     GOBLEN
            STA     LLEN
            CLC
            ADC     TPTR
            STA     TPTR
            LDA     GOBLEN+1
            STA     HLEN
            ADC     TPTR+1
            STA     TPTR+1
            LDA     #0
            STA     $D01A
            LDA     #52
            STA     MAP
            JSR     UMOVE
            LDA     #54
            STA     MAP
            LDA     #1
            STA     $D01A
            LDA     FROMSAV
            STA     FROML
            LDA     FROMSAV+1
            STA     FROMH
            LDA     DESTSAV
            STA     DESTL
            LDA     DESTSAV+1
            STA     DESTH
            SEC
            LDA     LASTLINE
            SBC     DESTL
            STA     LLEN
            LDA     LASTLINE+1
            SBC     DESTH
            STA     HLEN
            JSR     UMOVE
            SEC
            LDA     LASTLINE
            SBC     GOBLEN
            STA     LASTLINE
            LDA     LASTLINE+1
            SBC     GOBLEN+1
            STA     LASTLINE+1
            RTS

; Most delete commands end up calling
; the above routines. The single-character
; deletes must subtract 1 from the buffer
; pointer so that single characters are not
; added to the buffer. But note how short
; these routines are.
DELCHAR:    JSR     DEL1
            JSR     LEFT
            JSR     DEL2
FIXTP:      SEC
            LDA     TPTR
            SBC     #1
            STA     TPTR
            LDA     TPTR+1
            SBC     #0
            STA     TPTR+1
            RTS

; This is called from CTRL-back arrow.
; We first check to see if SHIFT is also
; held down. If so we go to another rou-
; tine that "eats" spaces.
DELIN:      LDA     653
            CMP     #5
            BNE     DODELIN
            JMP     EATSPACE
DODELIN:    JSR     RIGHT
            JSR     DEL1
            JSR     LEFT
            JSR     DEL2
            JMP     FIXTP

; Called by CTRL-D. As mentioned, it
; stores CURR into FROML/FROMH,
; moves the cursor either by sentence,
; word, or paragraph, then stores the
; new position of CURR into DESTL and
; DESTH. The above routines perform
; the actual delete. CTRL-D always dis-
; cards the previous contents of the
; buffer, for reasons that are obvious
; once you think about what would hap-
; pen to the buffer if we didn't clear it.
; Notice how we change the color of the
; command window to red (color 2) to
; warn the user of the inpending
; deletion
DELETE:     JSR     KILLBUFF
            LDA     #2
            STA     WINDCOLR
            JSR     TOPCLR
            LDA     #<DELMSG
            LDY     #>DELMSG
            JSR     PRMSG
            JSR     GETAKEY
            PHA
            JSR     SYSMSG
            PLA
            AND     #191
            CMP     #23
            BNE     NOTWORD
DELWORD:    JSR     DEL1
            JSR     WLEFT
            JMP     DEL2
NOTWORD:    CMP     #19
            BNE     NOTSENT
DELSENT:    JSR     DEL1
            JSR     SLEFT
            JMP     DEL2
NOTSENT:    CMP     #16
            BNE     NOTPAR
            JSR     DEL1
            JSR     PARLEFT
            JMP     DEL2
NOTPAR:     RTS

; Home the cursor. If the cursor is al-
; ready home, move the cursor to the top
; of text.
HOME:       SEC
            LDA     CURR
            SBC     TOPLIN
            STA     TEMP
            LDA     CURR+1
            SBC     TOPLIN+1
            ORA     TEMP
            BEQ     TOPHOME
            LDA     TOPLIN
            STA     CURR
            LDA     TOPLIN+1
            STA     CURR+1
            RTS
TOPHOME:    LDA     TEXSTART
            STA     CURR
            LDA     TEXSTART+1
            STA     CURR+1
            JMP     CHECK

; This deletes all spaces between the
; cursor and following nonspace text.
; Sometimes inventing labels can be fun.
EATSPACE:   LDA     CURR
            STA     TEX
            STA     DESTL
            LDA     CURR+1
            STA     TEX+1
            STA     DESTH
            LDY     #0
SPCSRCH:    LDA     (TEX),Y
            CMP     #32
            BNE     OUTSPACE
            INY
            BNE     SPCSRCH
            LDA     TEX+1
            CMP     LASTLINE+1
            BCC     GOINC
            LDA     LASTLINE
            STA     TEX
            LDA     LASTLINE+1
            STA     TEX+1
            LDY     #0
            JMP     OUTSPACE
GOINC:      INC     TEX+1
            JMP     SPCSRCH
OUTSPACE:   CLC
            TYA
            ADC     TEX
            STA     FROML
            LDA     #0
            ADC     TEX+1
            STA     FROMH
            SEC
            LDA     LASTLINE
            SBC     DESTL
            STA     LLEN
            LDA     LASTLINE+1
            SBC     DESTH
            STA     HLEN
            SEC
            LDA     FROML
            SBC     DESTL
            STA     GOBLEN
            LDA     FROMH
            SBC     DESTH
            STA     GOBLEN+1
            JSR     UMOVE
            SEC
            LDA     LASTLINE
            SBC     GOBLEN
            STA     LASTLINE
            LDA     LASTLINE+1
            SBC     GOBLEN+1
            STA     LASTLINE+1
            RTS

; Inserts 255 spaces. Notice how it and
; other insert routines use TAB2.
LOTTASPACES:LDA     #255
            STA     INSLEN
            JMP     TAB2
TAB:        LDA     #5
            STA     INSLEN
            JSR     TAB2
            LDA     (CURR),Y
            CMP     #32
            BNE     NOINCY
            INY
NOINCY:     JMP     ADYCURR
TAB2:       LDA     #0
            STA     INSLEN+1
            JSR     INSBLOCK
            LDA     #32
            LDX     INSLEN
            LDY     #0
FILLSP:     STA     (CURR),Y
            INY
            DEX
            BNE     FILLSP
            RTS

; SHIFT-RETURN calls this. It inserts
; two spaces, fills them with return
; marks, then calls TAB for a margin in-
; dent, Not much code for a useful
; routine.
ENDPAR:     JSR     INSCHAR
            JSR     INSCHAR
            LDA     #RETCHAR
            LDY     #0
            STA     (CURR),Y
            INY
            STA     (CURR),Y
            JSR     REFRESH
            JSR     RIGHT
            JSR     RIGHT
            JMP     TAB

; Insert a single space.
INSCHAR:    LDA     #1
            STA     INSLEN
            LDA     #0
            STA     INSLEN+1
            JSR     INSBLOCK
            LDA     #32
            LDY     #0
            STA     (CURR),Y
            JMP     CHECK

; A general routine to insert as many
; spaces as are specified by INSLEN.
INSBLOCK:   CLC
            LDA     LASTLINE
            ADC     INSLEN
            LDA     LASTLINE+1
            ADC     INSLEN+1
            CMP     TEXEND+1
            BCC     OKINS
            PLA
            PLA
            JMP     INOUT
OKINS:      CLC
            LDA     CURR
            STA     FROML
            ADC     INSLEN
            STA     DESTL
            LDA     CURR+1
            STA     FROMH
            ADC     INSLEN+1
            STA     DESTH
            SEC
            LDA     LASTLINE
            SBC     FROML
            STA     LLEN
            LDA     LASTLINE+1
            SBC     FROMH
            STA     HLEN
            JSR     DMOVE
            CLC
            LDA     LASTLINE
            ADC     INSLEN
            STA     LASTLINE
            LDA     LASTLINE+1
            ADC     INSLEN+1
            STA     LASTLINE+1
INOUT:      RTS

; Toggle insert mode. The INSMODE
; flag doubles as the color of the com-
; mand line.
INSTGL:     LDA     INSMODE
            EOR     #14
            STA     INSMODE
            RTS

; Another example of modular code. This
; is called anytime a yes/no resonse is
; called for. It prints "Are you sure?
; (Y/N)", then returns with the zero flag
; set to true if Y was pressed, ready for
; the calling routine to use BEQ or BNE
; as a branch for yes or no.
YORN:       LDA     #<YMSG
            LDY     #>YMSG
            JSR     PRMSG
YORNKEY:    JSR     $FF9F
            JSR     GETIN
            BEQ     YORNKEY
            CMP     #147
            BEQ     YORNKEY
            AND     #127
            CMP     #'y'
            RTS

; Erase all text. Calls YORN to affirm the
; deadly deed, then calls ERASE to erase
; all text, INIT2 to reset some flags, then
; jumps back to the main loop. LDX
; #$FA:TXS is used to clean up the stack.
; If you would prefer to have the buffer
; contents preserved after an Erase All,
; change the JSR INIT2 in the following
; routine to JSR INIT2+3.
CLEAR:      LDA     #2
            STA     WINDCOLR
            JSR     TOPCLR
            LDA     #<CLRMSG
            LDY     #>CLRMSG
            JSR     PRMSG
            JSR     YORN
            BEQ     DOIT
            JMP     SYSMSG
DOIT:       LDX     #$FA
            TXS
            JSR     ERASE
            JSR     INIT2+3
            JMP     MAIN

; Paragraph right. What's this routine do-
; ing here instead of with the other
; cursor routines?  You don't always write
; your routines in the order of a flow-
; chart. I didn't originally plan to have a
; paragraph movement function, so I
; added it where there was room for it
; between line numbers.
PARIGHT:    LDY     #0
PARLP:      LDA     (CURR),Y
            CMP     #RETCHAR
            BEQ     RETFOUND
            INY
            BNE     PARLP
            INC     CURR+1
            LDA     CURR+1
            CMP     LASTLINE+1
            BCC     PARLP
            BEQ     PARLP
            JMP     LASTWORD
RETFOUND:   INY
            BNE     GOADY
            INC     CURR+1
GOADY:      JMP     ADYCURR

; Paragraph left. Notice the trick of
; decrementing the high byte of the
; pointer, then starting the index at 255
; in order to search backward.
PARLEFT:    LDA     CURR
            STA     TEX
            LDA     CURR+1
            STA     TEX+1
            DEC     TEX+1
            LDY     #$FF
PARLOOP:    LDA     (TEX),Y
            CMP     #RETCHAR
            BEQ     RETF2
PARCONT:    DEY
            CPY     #255
            BNE     PARLOOP
            DEC     TEX+1
            LDA     TEX+1
            CMP     TEXSTART+1
            BCS     PARLOOP
            JMP     FIRSTWORD
RETF2:      SEC
            TYA
            ADC     TEX
            STA     TEX
            LDA     #0
            ADC     TEX+1
            STA     TEX+1
            SEC
            LDA     TEX
            SBC     CURR
            STA     TEMP
            LDA     TEX+1
            SBC     CURR+1
            ORA     TEMP
            BNE     TEXTOCURR
            STY     TEMP
            CLC
            LDA     TEX
            SBC     TEMP
            STA     TEX
            LDA     TEX+1
            SBC     #0
            STA     TEX+1
            JMP     PARCONT
TEXTOCURR:  LDA     TEX
            STA     CURR
            LDA     TEX+1
            STA     CURR+1
            JMP     CHECK

; This enables the raster interupt. The
; raster interrupt allows separate back-
; ground colors for the command line
; and the rest of the screen. It lets us
; change the color of the top line to flag
; insert mode or to warn the user with a
; red color that he/she should be careful.
; Since it is an interrupt, it is always run-
; ning in the background. Interrupt
; routines must always be careful not to
; corrupt the main program.
HIGHLIGHT:  SEI
            LDA     #0
            STA     $DC0E
            LDA     #27
            STA     $D011
            LDA     #<IRQ
            STA     $314
            LDA     #>IRQ
            STA     $315
            LDA     #1
            STA     $D01A
            STA     $D012
            CLI
            RTS
IRQ:        LDA     #58
            LDY     WINDCOLR
            CMP     $D012
            BNE     MID
            LDA     #1
            LDY     SCRCOL
MID:        STY     $D021
            STA     $D012
SKIP:       CMP     #1
            BEQ     DEFALT
            LDA     #1
            STA     $D019
            JMP     $FEBC
DEFALT:     LDA     #1
            STA     $D019
            JMP     $EA31

; ERAS is called by CTRL-E. It works
; much like CTRL-D. Notice that the
; ORA #64 allows users to press either S,
; W, P, or CTRL-S, CTRL-W, CTRL-P, in
; case they have a habit of leaving the
; control key held down. It must call RE-
; FRESH after each move and adjust the
; new position of the cursor. If SHIFT is
; held down with CTRL-E, we don't
; erase the previous contents of the
; buffer, letting the user chain non-
; contiguous sections into the buffer for
; later recall.
ERAS:       LDA     653
            AND     #1
            BNE     ERAS1
            JSR     KILLBUFF
ERAS1:      JSR     TOPCLR
            LDA     #<ERASMSG
            LDY     #>ERASMSG
            JSR     PRMSG
ERASAGAIN:  LDY     #0
            LDA     (CURR),Y
            EOR     #$80
            STA     (CURR),Y
            JSR     REFRESH
            LDY     #0
            LDA     (CURR),Y
            EOR     #$80
            STA     (CURR),Y
            LDA     #2
            STA     WINDCOLR
            JSR     GETAKEY
            ORA     #64
            CMP     #'w'
            BNE     NOWORD
ERASWORD:   JSR     ERA1
            JSR     WRIGHT
            JMP     ERA2
NOWORD:     CMP     #'s'
            BNE     UNSENT
ERASENT:    JSR     ERA1
            JSR     SRIGHT
            JMP     ERA2
UNSENT:     CMP     #'p'
            BNE     NOPAR
            JSR     ERA1
            JSR     PARIGHT
            JMP     ERA2
NOPAR:      JSR     CHECK
            JMP     SYSMSG
ERA1:       LDA     CURR
            STA     DESTL
            STA     SAVCURR
            LDA     CURR+1
            STA     DESTH
            STA     SAVCURR+1
            RTS
ERA2:       SEC
            LDA     CURR
            STA     FROML
            SBC     SAVCURR
            STA     GOBLEN
            LDA     CURR+1
            STA     FROMH
            SBC     SAVCURR+1
            STA     GOBLEN+1
            JSR     DELC
            LDA     SAVCURR
            STA     CURR
            LDA     SAVCURR+1
            STA     CURR+1
            JSR     REFRESH
            JMP     ERASAGAIN

; The INPUT routine is used to get re-
; sponses from the command line. It re-
; turns the complete line in INBUFF.
; INLEN is the length of the input. A
; zero byte is stored at INBUFF+INLEN
; after the user presses RETURN. This
; routine is foolproof (I know...), since no
; control keys other than DEL are al-
; lowed. It also prevents the user from
; typing past the end of the command
; line. If the limit of typing length must
; be set arbitrarily, LIMIT is preset and
; INPUT is called at INP1. CURSIN is
; the main loop.
INPUT:      LDA     #39
            SBC     211
            STA     LIMIT
INP1:       LDY     #0
CURSIN:     LDA     #153
            JSR     CHROUT
            LDA     #18
            JSR     CHROUT
            LDA     #' '
            JSR     CHROUT
            LDA     #157
            JSR     CHROUT
            STY     INLEN
            JSR     GETAKEY
            LDY     INLEN
            STA     TEMP
            LDA     #146
            JSR     CHROUT
            LDA     #32
            JSR     CHROUT
            LDA     #157
            JSR     CHROUT
            LDA     #155
            JSR     CHROUT
            LDA     TEMP
            CMP     #13
            BEQ     INEXIT
            CMP     #20
            BNE     NOBACK
            DEY
            BPL     NOTZERO
            INY
            JMP     CURSIN
NOTZERO:    LDA     #157
            JSR     CHROUT
            JMP     CURSIN
NOBACK:     LDA     TEMP
            AND     #127
            CMP     #32
            BCC     CURSIN
            CPY     LIMIT
            BEQ     CURSIN
            LDA     TEMP
            STA     INBUFF,Y
            JSR     CHROUT
            LDA     #0
            STA     212
            STA     216
            INY
            JMP     CURSIN
INEXIT:     JSR     CHROUT
            LDA     #0
            STA     INBUFF,Y
            TYA
            RTS

; Here is where most of the input/output
; routines start. TSAVE saves the entire
; document area using the Kernal SAVE
; routine. TOPEN is called by both
; TSAVE and TLOAD to get the filename
; and open the file for either tape or
; disk.
TSAVE:      JSR     TOPCLR
            LDA     #<SAVMSG
            LDY     #>SAVMSG
            JSR     PRMSG
            JSR     TOPEN
            BCS     ERROR
            LDA     TEXSTART
            STA     TEX
            LDA     TEXSTART+1
            STA     TEX+1
            LDX     LASTLINE
            LDY     LASTLINE+1
            LDA     #TEX
            JSR     SAVE
            BCS     ERROR

; Location $90 is the value of the
; Kernal's STatus flag. It's shorter to use
; LDA $90 than JSR READST.
            LDA     $90
            AND     #191
            BNE     ERROR
            JMP     FINE

; The ERROR message routine. May this
; routine never be called when you use
; SpeedScript, but that's too much to ask
; for. The error code from the Kernal
; routine is 0 if the error was Break
; Abort. If the device number (DVN) is 8
; for disk, we read the disk error chan-
; nel; otherwise, we just print a generic
; error message.
ERROR:      BEQ     STOPPED
            LDA     DVN
            CMP     #8
            BCC     TAPERR
            JSR     READERR
            JMP     ERXIT
TAPERR:     LDA     DVN
            CMP     #1
            BEQ     TAPERR
            JSR     TOPCLR
            LDA     #<FNF
            LDY     #>FNF
            JSR     PRMSG
ERXIT:      JSR     HIGHLIGHT
            LDA     #1
            STA     MSGFLG
            RTS
STOPPED:    JSR     TOPCLR
            LDA     #<BRMSG
            LDY     #>BRMSG
            JSR     PRMSG
            JMP     ERXIT
DVN:        .BYT    0

; TOPEN gets the filename, asks for tape
; or disk, then calls SETLFS and
; SETNAM, readying for LOAD or
; SAVE. If RETURN is pressed without
; any filename, the return address of the
; calling routine is pulled off so that we
; can jump straight back to the MAIN
; loop.
TOPEN:      JSR     INPUT
            BEQ     OPABORT
OP2:        LDA     #<TDMSG
            LDY     #>TDMSG
            JSR     PRMSG
            JSR     GETAKEY
            LDX     #8
            CMP     #'d'
            BEQ     OPCONT
            LDX     #1
            CMP     #'t'
            BEQ     OPCONT
OPABORT:    JSR     SYSMSG
            PLA
            PLA
            RTS
OPCONT:     STX     DVN
            LDA     #1
            LDY     #0
            JSR     SETLFS
            LDY     #0
            CPX     #1
            BEQ     SKIPDISK
            LDA     INBUFF,Y
            CMP     #'@'
            NOP
            NOP
            LDA     INBUFF+1,Y
            CMP     #':'
            BEQ     SKIPDISK
            LDA     INBUFF+2,Y
            CMP     #':'
            BEQ     SKIPDISK

; If 0:, 1:, @0:, or xx: did not precede the
; filename, we add 0:. Some think this
; makes disk writes more reliable. The
; NOPs above null out the comparison
; with the @ sign. Originally written as
; BNE SKIPDISK, this prevented the use
; of the prefix 1: for owners of dual-drive
; disks drives.
ADDZERO:    LDA     #'0'
            STA     FILENAME
            LDA     #':'
            STA     FILENAME+1
COPY1:      LDA     INBUFF,Y
            STA     FILENAME+2,Y
            INY
            CPY     INLEN
            BCC     COPY1
            BEQ     COPY1
            INY
            JMP     SETNAME
SKIPDISK:   LDA     INBUFF,Y
            STA     FILENAME,Y
            INY
            CPY     INLEN
            BNE     SKIPDISK
SETNAME:    STY     FNLEN
            JSR     TOPCLR
            LDA     #<INBUFF
            LDY     #>INBUFF
            JSR     PRMSG
            LDA     FNLEN
            LDX     #<FILENAME
            LDY     #>FILENAME
            JSR     SETNAM
            LDA     #13
            JSR     CHROUT
            JMP     DELITE

; Called by Ctrl-£ to enter a format
; code. It checks insert mode and inserts
; if necessary.
FORMAT:     JSR     TOPCLR
            LDA     #<FORMSG
            LDY     #>FORMSG
            JSR     PRMSG
            JSR     GETAKEY
            JSR     ASTOIN
            ORA     #$80
            PHA
            LDA     INSMODE
            BEQ     NOINS
            JSR     INSCHAR
NOINS:      JSR     SYSMSG
            PLA
            JMP     PUTCHR

; The Load routine checks the cursor po-
; sition. If the cursor is at the top of text,
; we call the ERASE routine to wipe out
; memory before the Load. Otherwise,
; the Load starts at the cursor position,
; performing an append.
TLOAD:      SEC
            LDA     CURR
            SBC     TEXSTART
            STA     TEMP
            LDA     CURR+1
            SBC     TEXSTART+1
            ORA     TEMP
            BEQ     LOAD2
            LDA     #5
            STA     WINDCOLR
LOAD2:      JSR     TOPCLR
            LDA     #<LOADMSG
            LDY     #>LOADMSG
            JSR     PRMSG
            JSR     TOPEN
            LDA     WINDCOLR
            CMP     #5
            BEQ     NOER
            JSR     ERASE
NOER:       LDA     #0
            LDX     CURR
            LDY     CURR+1
LDVER:      JSR     LOAD
            BCC     LOD
            JMP     ERROR
LOD:        STX     LASTLINE
            STY     LASTLINE+1
FINE:       JSR     CLALL
            JSR     TOPCLR
            LDA     #<OKMSG
            LDY     #>OKMSG
            JSR     PRMSG
            JMP     ERXIT

; Verify takes advantage of the Kernal
; routine, so it is very similar to the Load
; routine.
VERIFY:     JSR     TOPCLR
            LDA     #<VERMSG
            LDY     #>VERMSG
            JSR     PRMSG
            JSR     TOPEN
            LDA     #1
            LDX     TEXSTART
            LDY     TEXSTART+1
            JSR     LOAD
            LDA     $90
            AND     #191
            BEQ     FINE
            JSR     TOPCLR
            LDA     #<VERERR
            LDY     #>VERERR
            JSR     PRMSG
            JMP     ERXIT

; DELITE turns off the raster interrupt.
; You must turn off raster interrupts (and
; sprites where appropriate) before tape
; operations. It also restores the default
; interrupts and fixes the screen colors.
DELITE:     SEI
            LDA     #0
            STA     $D01A
            STA     53280
            STA     53281
            LDA     #$31
            STA     $314
            LDA     #$EA
            STA     $315
            LDA     #1
            STA     $DC0E
            CLI
            RTS

; Disk directory routine. It opens "$" as
; a program file, throws away the link
; bytes, prints the line number bytes as
; the blocks used, then prints all follow-
; ing text until the end-of-line zero byte.
; It's similar to how programs are LISTed
; in BASIC, except that nothing is
; untokenized. The system is so sensitive
; to read errors that we call DCHRIN
; (which constantly checks for errors) in-
; stead of directly calling the Kernal
; CHRIN routine. DCHRIN can abort the
; main loop of the DIR routine.
CATALOG:    LDA     #147
            JSR     CHROUT
            LDA     #13
            JSR     CHROUT
            JSR     DELITE
            JSR     DIR
            LDA     #13
            JSR     CHROUT
            LDA     #<DIRMSG
            LDY     #>DIRMSG
            JSR     PRMSG
WAITKEY:    JSR     GETIN
            CMP     #13
            BNE     WAITKEY
            JSR     HIGHLIGHT
            JMP     SYSMSG
ENDIR:      JSR     CLRCHN
            LDA     #1
            JSR     CLOSE
            RTS
DIR:        JSR     CLALL
            LDA     #1
            LDX     #8
            LDY     #0
            JSR     SETLFS
            LDA     #1
            LDX     #<DIRNAME
            LDY     #>DIRNAME
            JSR     SETNAM
            JSR     OPEN
            BCS     ENDIR
            LDX     #1
            JSR     CHKIN
            JSR     DCHRIN
            JSR     DCHRIN
DIRLOOP:    JSR     DCHRIN
            JSR     DCHRIN
            BEQ     ENDIR
PAUSE:      JSR     CLRCHN
            JSR     GETIN
            CMP     #32
            BNE     NOPAUSE
            JSR     GETAKEY
NOPAUSE:    LDX     #1
            JSR     CHKIN
            JSR     DCHRIN
            PHA
            JSR     DCHRIN
            TAY
            PLA
            TAX
            TYA
            LDY     #55
            STY     MAP
            JSR     $BDCD
            LDY     #54
            STY     MAP
            LDA     #32
            JSR     CHROUT
INLOOP:     JSR     DCHRIN
            BEQ     DLINE
            JSR     CHROUT
            JMP     INLOOP
DLINE:      LDA     #13
            JSR     CHROUT
            JMP     DIRLOOP
DCHRIN:     JSR     CHRIN
            PHA
            LDA     $90
            AND     #191
            BEQ     NOSTERR
            PLA
            PLA
            PLA
            JMP     ENDIR
NOSTERR:    PLA
            RTS

; A rather short routine that converts a
; string of ASCII digits into a number in
; hex and the accumulator. It takes
; advantage of decimal mode. In decimal
; mode, the accumulator is adjusted after
; additions and subtractions so that it
; acts like a two-digit decimal counter.
; We shift BCD over a nybble and add in
; the left nybble of the ASCII number
; until we reach the end of the ASCII
; number. We then subtract 1 from BCD
; and increment X (which doesn't con-
; form to decimal mode) until BCD is
; down to zero. The X register magically
; holds the converted number. Naturally,
; decimal mode is cleared before this
; routine exits, or it would wreak major
; havoc. ASCHEX is used to covnert the
; parameters of printer commands like
; left margin.
ASCHEX:     LDX     #0
            STX     BCD
            STX     BCD+1
            STX     HEX
            STX     HEX+1
DIGIT:      SEC
            LDA     (TEX),Y
            SBC     #48
            BCC     NONUM
            CMP     #10
            BCS     NONUM
            ASL     BCD
            ROL     BCD+1
            ASL     BCD
            ROL     BCD+1
            ASL     BCD
            ROL     BCD+1
            ASL     BCD
            ROL     BCD+1
            ORA     BCD
            STA     BCD
            INY
            BNE     DIGIT
            INC     TEX+1
            JMP     DIGIT
NONUM:      SED
DECHEX:     LDA     BCD
            ORA     BCD+1
            BEQ     DONENUM
            SEC
            LDA     BCD
            SBC     #1
            STA     BCD
            LDA     BCD+1
            SBC     #0
            STA     BCD+1
            INC     HEX
            BNE     NOHEXINC
            INC     HEX+1
NOHEXINC:   JMP     DECHEX
DONENUM:    LDA     HEX
            CLD
            RTS

; Insert the buffer. This is the recall rou-
; tine called by CTRL-R. It must not
; allow an insertion that would overfill
; memory. It calls DMOVE to open a
; space in memory, then UMOVE (which
; is a little faster than DMOVE) to copy
; the buffer to the empty space.
INSBUFFER:  SEC
            LDA     TPTR
            SBC     TEXBUF
            STA     BUFLEN
            LDA     TPTR+1
            SBC     TEXBUF+1
            STA     BUFLEN+1
            ORA     BUFLEN
            BNE     OKBUFF
            JSR     TOPCLR
            LDA     #<INSMSG
            LDY     #>INSMSG
            JSR     PRMSG
            LDA     #1
            STA     MSGFLG
            RTS
OKBUFF:     CLC
            LDA     CURR
            STA     FROML
            ADC     BUFLEN
            STA     DESTL
            LDA     CURR+1
            STA     FROMH
            ADC     BUFLEN+1
            STA     DESTH
            SEC
            LDA     LASTLINE
            SBC     FROML
            STA     LLEN
            LDA     LASTLINE+1
            SBC     FROMH
            STA     HLEN
            CLC
            ADC     DESTH
            CMP     TEXEND+1
            BCC     OKMOV
            JSR     TOPCLR
            LDA     #<INSERR
            LDY     #>INSERR
            JSR     PRMSG
            LDA     #1
            STA     MSGFLG
            RTS
OKMOV:      JSR     DMOVE
            CLC
            LDA     BUFLEN
            STA     LLEN
            ADC     LASTLINE
            STA     LASTLINE
            LDA     BUFLEN+1
            STA     HLEN
            ADC     LASTLINE+1
            STA     LASTLINE+1
            LDA     CURR
            STA     DESTL
            LDA     CURR+1
            STA     DESTH
            LDA     TEXBUF
            STA     FROML
            LDA     TEXBUF+1
            STA     FROMH
            LDA     #0
            STA     $D01A
            LDA     #52
            STA     MAP
            JSR     UMOVE
            LDA     #54
            STA     MAP
            LDA     #1
            STA     $D01A
            JMP     CHECK

; Exchange the character highlighted by
; the cursor with the character to the
; right of it. Not a vital command, but it
; was included due to the brevity of the
; code.
SWITCH:     LDY     #0
            LDA     (CURR),Y
            TAX
            INY
            LDA     (CURR),Y
            DEY
            STA     (CURR),Y
            INY
            TXA
            STA     (CURR),Y
            RTS

; Changes the case of the character high-
; lighted by the cursor
ALPHA:      LDY     #0
            LDA     (CURR),Y
            AND     #63
            BEQ     NOTALPHA
            CMP     #27
            BCS     NOTALPHA
            LDA     (CURR),Y
            EOR     #64
            STA     (CURR),Y
NOTALPHA:   JMP     RIGHT

; Converts internal (screen code) format
; to Commodore ASCII. Used to convert
; the screen-code format of SpeedScript
; documents to ASCII for the sake of
; printing.
INTOAS:     STA     TEMP
            AND     #$3F
            ASL     TEMP
            BIT     TEMP
            BPL     ISK1
            ORA     #$80
ISK1:       BVS     ISK2
            ORA     #$40
ISK2:       STA     TEMP
            RTS

; The start of the printer routines. This
; part could logically be called a separate
; program, but many variables are com-
; mon to the above code.
; Table of default settings for left margin,
; right margin, page length, top margin,
; bottom margin, etc. See the table start-
; ing at LMARGIN at the end of this
; source code.
DEFTAB:     .BYT    5,75,66,5,58,1,1,1,0,1,0,80

; Table of default printer codes.
PRCODES:    .BYT    27,14,15,18

; Another advantage of modular coding
; is that you can change the behavior of
; a lot of code by just changing one
; small, common routine. This is a sub-
; stitute for the Kernal CHROUT, al-
; though it calls CHROUT. It checks to
; see if the current page number equals
; the page number specified by the user
; for printing to start. It also checks for
; the RUN/STOP key to abort the print-
; int and permits print to be paused
; with the SHIFT key.
PCHROUT:    STA     PCR
            TXA
            PHA
            TYA
            PHA
            SEC
            LDA     PAGENUM
            SBC     STARTNUM
            LDA     PAGENUM+1
            SBC     STARTNUM+1
            BCC     SKIPOUT
            LDA     PCR
            JSR     CHROUT
SHIFTFREEZE:LDA     653
            AND     #1
            STA     53280
            BNE     SHIFTFREEZE
            LDA     $91
            CMP     #$7F
            BNE     SKIPOUT
            INC     53280
;
; SpeedScript 3.2r1 patch
; TODO: perhaps add an explanation
; for removing the JSR CR.
;
            NOP
            NOP
            NOP
            JMP     PEXIT
SKIPOUT:    PLA
            TAY
            PLA
            TAX
            LDA     PCR
            RTS

; Displays "Printing..."
PRIN:       JSR     TOPCLR
            LDA     #<PRINMSG
            LDY     #>PRINMSG
            JMP     PRMSG
PBORT:      JMP     PEXIT

; Called by CTRL-P. If SHIFT is not held
; down with CTRL-P, we choose a de-
; vice number of 4, a secondary address
; of 7 (lowercase mode), and no file-
; name. If SHIFT is held down, we ask
; "Print to: Screen, Disk, Printer?" If
; Screen is selected, we use a device
; number of 3. If Disk is slected, we get
; a filename and use a device number
; and secondary address of 8. For Printer,
; we ask for the device number and
; secondary address. SETLFS is called
; after all these decisions are made, then
; OPEN. No matter how the file is
; OPENed, we reference it by file num-
; ber 1.
PRINT:      LDA     SCRCOL
            STA     SAVCOL
            LDA     #0
            STA     WINDCOLR
            STA     53280
            STA     SCRCOL
            JSR     SETNAM
            LDA     #4
            STA     DEVNO
            LDY     #7
            LDA     653
            AND     #1
            BNE     ASKQUES
            JMP     OVERQUES
ASKQUES:    JSR     TOPCLR
            LDA     #<CHOOSEMSG
            LDY     #>CHOOSEMSG
            JSR     PRMSG
            JSR     GETAKEY
            AND     #127
            LDX     #3
            STX     DEVNO
            CMP     #'s'
            BEQ     PRCONT
NOTSCREEN:  LDX     #8
            STX     DEVNO
            CMP     #'d'
            BEQ     DOFN
            CMP     #'p'
            BNE     PBORT
            JSR     TOPCLR
            LDA     #<DEVMSG
            LDY     #>DEVMSG
            JSR     PRMSG
            JSR     GETAKEY
            SEC
            SBC     #48
            CMP     #4
            BCC     PBORT
            CMP     #80
            BCS     PBORT
            STA     DEVNO
            JMP     PRCONT

; Ask for a print filename, if appropriate,
; and add ",S,W" for a sequential write
; file.
DOFN:       JSR     TOPCLR
            LDA     #<FNMSG
            LDY     #>FNMSG
            JSR     PRMSG
            JSR     INPUT
            BEQ     PBORT
            LDY     INLEN
            LDA     #','
            STA     INBUFF,Y
            INY
            LDA     #'w'
            STA     INBUFF,Y
            INY
            STY     INLEN
            LDA     INLEN
            LDX     #<INBUFF
            LDY     #>INBUFF
            JSR     SETNAM
PRCONT:     LDA     DEVNO
            TAY
            CMP     #4
            BCC     OVERQUES
            CMP     #8
            BCS     OVERQUES
NOTD2:      JSR     TOPCLR
            LDA     #<SADRMSG
            LDY     #>SADRMSG
            JSR     PRMSG
            JSR     GETAKEY
            SEC
            SBC     #48
            TAY
            BPL     OVERQUES
            JMP     PBORT
OVERQUES:   LDA     #1
            LDX     DEVNO
            JSR     SETLFS
            JSR     PRIN
            LDA     #1
            JSR     CLOSE
            JSR     OPEN
            LDX     #1
            JSR     CHKOUT
            BCC     PROK
            JMP     PEXIT

; Reset several flags (footer length,
; header length, true ASCII, underline
; mode, and linefeed mode).
PROK:       LDX     #0
            STX     FTLEN
            STX     HDLEN
            STX     NEEDASC
            STX     UNDERLINE
            STX     LINEFEED

; Copy definition tables and default
; printer codes.
COPYDEF:    LDA     DEFTAB,X
            STA     LMARGIN,X
            INX
            CPX     #12
            BNE     COPYDEF
            LDA     #$FF
            STA     LINE
            STA     NOMARG
            LDX     #4
COPYDEFS:   LDA     PRCODES-1,X
            STA     CODEBUFFER+48,X
            DEX
            BNE     COPYDEFS

; Reentry point for print after linked
; files.
RETEX:      LDA     TEXSTART
            STA     TEX
            LDA     TEXSTART+1
            STA     TEX+1

; Main printing loop. We print the left
; margin, grab a line of text, scan back-
; ward until we find a space or a carriage
; return, then break the line there. If
; printer codes are encountered, they're
; passed on to the SPECIAL routine.
; Otherwise, we end up calling BUFPRT
; to print the line and process some other
; control codes.
PLOOP:      LDY     #0
            STY     POS
            CPY     NOMARG
            BEQ     PLOOP1
            LDA     LMARGIN
            STA     POS
PLOOP1:     LDA     (TEX),Y
            BPL     NOTSP
            JMP     SPECIAL
NOTSP:      CMP     #RETCHAR
            BEQ     FOUNDSPACE
NOTRET:     STA     PRBUFF,Y
            INY
            INC     POS
            LDA     POS
            CMP     RMARGIN
            BCC     PLOOP1
            STY     FINPOS
FINDSPACE:  LDA     (TEX),Y
            CMP     #32
            BEQ     FOUNDSPACE
            DEC     POS
            DEY
            BNE     FINDSPACE
            LDY     FINPOS
            JMP     OVERSTOR
FSPACE:     INY
            LDA     (TEX),Y
            CMP     #32
            BEQ     FOUNDSPACE
            DEY
; A bug/typo in the original printed source code was fixed below.
; The book had this label as 'FOUNDSPAC' (missing 'E') here.
; Possibly the original assembler didn't notice due to to a label
; size limitation.
FOUNDSPACE: STY     FINPOS
OVERSTOR:   TYA
            SEC
            ADC     TEX
            STA     TEX
            LDA     TEX+1
            ADC     #0
            STA     TEX+1
            LDY     #0

; If this is the first page, we need to print
; the header, if any, with JSR TOP.
DOBUFF:     LDA     LINE
            CMP     #$FF
            BNE     DOBUF2
            JSR     TOP
DOBUF2:     LDA     NOMARG
            BEQ     OVERMARG
            JSR     LMARG
OVERMARG:   SEC
            ROL     NOMARG
            LDA     FINPOS
            STA     ENDPOS
            LDA     #<PRBUFF
            STA     INDIR
            LDA     #>PRBUFF
            STA     INDIR+1
            JSR     BUFPRT

; A line has been printed. We check to
; see if we've hit the bottom margin and,
; if so, go to PAGE, which goes to the
; end of the page, prints the footer (if
; any), and feeds to the next page.
ZBUFF:      JSR     CRLF
            LDA     LINE
            CMP     BOTMARG
            BCC     NOTPAGE
            JSR     PAGE

; Have we reached the end of text?
NOTPAGE:    SEC
            LDA     TEX
            SBC     LASTLINE
            STA     TEMP
            LDA     TEX+1
            SBC     LASTLINE+1
            ORA     TEMP
            BEQ     DORPT
            BCC     DORPT

; If so, we check for a footer. If there is
; one, we set HDLEN and TOPMARG to
; zero (so that the printhead will end up
; at the right place on the last page) and
; call PAGE, which prints the footer. If
; there is no footer, we leave the
; printhead on the same page so that pa-
; per isn't wasted.
            LDA     FTLEN
            BEQ     PXIT
            LDA     #0
            STA     HDLEN
            STA     TOPMARG
            JSR     PAGE

; Exit routines. If screen output was se-
; lected, we wait for a keystroke before
; going back to editing mode. Since the
; RUN/STOP key is used to abort print-
; ing and to insert a margin indent in
; editing mode, we wait for the user to
; let go of RUN/STOP before we return
; to editing mode.
PXIT:       LDA     DEVNO
            CMP     #3
            BNE     PEXIT
            JSR     GETAKEY
PEXIT:      JSR     STOP
            BEQ     PEXIT
            LDA     #1
            JSR     CLOSE
            JSR     CLALL
            LDA     SAVCOL
            STA     SCRCOL
            LDX     #$FA
            TXS
            JSR     SYSMSG
            JMP     MAIN
DORPT:      JMP     PLOOP

; Paging routines. We skip
; (PAGELENGTH-LINE)-two blank
; lines to get to the bottom of the page,
; print a footer (if there is one) or a blank
; line (if not), then page to the beginning
; of the next page, skipping over the pa-
; per perforation. If the wait mode is en-
; abled, we wait for the user to insert a
; new sheet of paper.
PAGE:       SEC
            LDA     PAGELENGTH
            SBC     LINE
            TAY
            DEY
            DEY
            BEQ     NOSK
            BMI     NOSK
NEXPAGE:    JSR     CR
            DEY
            BNE     NEXPAGE
NOSK:       LDA     FTLEN
            BEQ     SKIPFT
            STA     ENDPOS
            LDA     #<FTBUFF
            STA     INDIR
            LDA     #>FTBUFF
            STA     INDIR+1
            JSR     LMARG
            JSR     BUFPRT
SKIPFT:     JSR     CR
            JSR     CR
            JSR     CR

; Increment the page number.
            INC     PAGENUM
            BNE     NOIPN
            INC     PAGENUM+1

; The page wait mode is inappropriate
; when printing to the screen or to disk,
; or when skipping over pages with the ?
; format command.
NOIPN:      LDA     CONTINUOUS
            BNE     TOP
            LDA     DEVNO
            CMP     #3
            BEQ     TOP
            CMP     #8
            BEQ     TOP
            SEC
            LDA     PAGENUM
            SBC     STARTNUM
            LDA     PAGENUM+1
            SBC     STARTNUM+1
            BCC     TOP
            JSR     CLRCHN
            JSR     TOPCLR
            LDA     #<WAITMSG
            LDY     #>WAITMSG
            JSR     PRMSG
            JSR     GETAKEY
            JSR     PRIN
            LDX     #1
            JSR     CHKOUT

; Print the header, skip to the top
; margin.
TOP:        LDA     HDLEN
            BEQ     NOHEADER
            STA     ENDPOS
            LDA     #<HDBUFF
            STA     INDIR
            LDA     #>HDBUFF
            STA     INDIR+1
            JSR     LMARG
            JSR     BUFPRT
NOHEADER:   LDY     TOPMARG
            STY     LINE
            DEY
            BEQ     SKIPTOP
            BMI     SKIPTOP
TOPLP:      JSR     CR
            DEY
            BNE     TOPLP
SKIPTOP:    RTS

; Left margin routine. This routine is not
; called if NOMARG is selected (margin
; release).
LMARG:      LDA     #32
            LDY     LMARGIN
            STY     POS
            BEQ     LMEXIT
LMLOOP:     JSR     PCHROUT
            DEY
            BNE     LMLOOP
LMEXIT:     RTS

; CRLF is called at the end of most
; printed lines. It increments the LINE
; count and takes into account the cur-
; rent line spacing mode set by the s for-
; mat command.
CRLF:       LDY     SPACING
            CLC
            TYA
            ADC     LINE
            STA     LINE
CRLOOP:     JSR     CR
            DEY
            BNE     CRLOOP
            RTS

; CR just prints a single carriage return
; and linefeed (if specified).
CR:         LDA     #13
            JSR     PCHROUT
            LDA     LINEFEED
            BEQ     NOLF
            JSR     PCHROUT
NOLF:       RTS

; Handle special printer codes like left
; margin. This looks up the printer code
; using a routine similar to CONTROL.
SPECIAL:    STA     SAVCHAR
            AND     #127
            JSR     INTOAS
            LDX     SPTAB
SRCHSP:     CMP     SPTAB,X
            BEQ     FSP
            DEX
            BNE     SRCHSP
            DEC     POS
            JMP     DEFINE
FSP:        DEX
            TXA
            ASL
            TAX
            STY     YSAVE
            LDA     #>SPCONT
            PHA
            LDA     #<SPCONT-1
            PHA
            LDA     SPVECT+1,X
            PHA
            LDA     SPVECT,X
            PHA
            RTS

; After the format code is processed, we
; must skip over the format command
; and its parameter so that it's not
; printed.
SPCONT:     SEC
            LDA     YSAVE
            ADC     TEX
            STA     TEX
            LDA     TEX+1
            ADC     #0
            STA     TEX+1
            JMP     PLOOP

; If the format command ends with a re-
; turn mark, we must skip over the re-
; turn mark as well.
SPCEXIT:    LDA     (TEX),Y
            CMP     #RETCHAR
            BEQ     NOAD
            DEY
NOAD:       STY     YSAVE
            RTS

; Special format code table. It starts with
; the number of format commands, then
; the characters for each format
; command.
SPTAB:      .BYT    18
            .BYTE   "walrtbsnhf@p?xmigj"

; The address-1 of each format routine.
SPVECT:     .WORD   PW-1,AS-1,LM-1,RM-1,TP-1
            .WORD   BT-1,SP-1,NX-1,HD-1,FT-1
            .WORD   PN-1,PL-1,SPAGE-1,ACROSS-1
            .WORD   MRELEASE-1,COMMENT-1,LINK-1
            .WORD   LFSET-1

; m Margin release. INY is used to skip
; over the format character.
MRELEASE:   INY
            LDA     #0
            STA     NOMARG
            JMP     SPCEXIT

; x Columns across, used by centering.
ACROSS:     INY
            JSR     ASCHEX
            STA     PAGEWIDTH
            JMP     SPCEXIT

; ? Start print at specified page.
SPAGE:      INY
            JSR     ASCHEX
            STA     STARTNUM
            LDA     HEX+1
            STA     STARTNUM+1
            JMP     SPCEXIT

; @ Set starting default page number.
PN:         INY
            JSR     ASCHEX
            STA     PAGENUM
            LDA     HEX+1
            STA     PAGENUM+1
            JMP     SPCEXIT

; p Page length.
PL:         INY
            JSR     ASCHEX
            STA     PAGELENGTH
            JMP     SPCEXIT

; w Set page wait mode.
PW:         LDA     #0
            STA     CONTINUOUS
            INY
            JMP     SPCEXIT

; j Set linefeed mode.
LFSET:      LDA     #10
            STA     LINEFEED
            INY
            JMP     SPCEXIT

; a Set true ASCII mode.
AS:         INY
            LDA     #1
            STA     NEEDASC
            JMP     SPCEXIT

; l Left margin.
LM:         INY
            JSR     ASCHEX
            STA     LMARGIN
            JMP     SPCEXIT

; r Right margin.
RM:         INY
            JSR     ASCHEX
            STA     RMARGIN
            JMP     SPCEXIT

; t Top margin.
TP:         INY
            JSR     ASCHEX
            STA     TOPMARG
            JMP     SPCEXIT

; b Bottom margin.
BT:         INY
            JSR     ASCHEX
            STA     BOTMARG
            JMP     SPCEXIT

; s Set line spacing.
SP:         INY
            JSR     ASCHEX
            STA     SPACING
            JMP     SPCEXIT

; n Jump to next page.
NX:         LDY     YSAVE
            INY
            TYA
            PHA
            JSR     PAGE
            PLA
            TAY
            STY     YSAVE
            RTS

; h Define header. Copy header into
; header buffer.
HD:         JSR     PASTRET
            DEY
            STY     HDLEN
            LDY     #1
HDCOPY:     LDA     (TEX),Y
            STA     HDBUFF-1,Y
            INY
            CPY     HDLEN
            BCC     HDCOPY
            BEQ     HDCOPY
            INY
            JMP     SPCEXIT

; Skip just past the return mark.
PASTRET:    INY
            LDA     (TEX),Y
            CMP     #RETCHAR
            BNE     PASTRET
            RTS

; f Define footer.
FT:         JSR     PASTRET
            DEY
            STY     FTLEN
            LDY     #1
FTCOPY:     LDA     (TEX),Y
            STA     FTBUFF-1,Y
            INY
            CPY     FTLEN
            BCC     FTCOPY
            BEQ     FTCOPY
            JMP     SPCEXIT

; i Ignore a line of information
COMMENT:    JSR     PASTRET
            JMP     SPCEXIT

; Define programmable printkeys. We
; check for =. If not found, this is not an
; assignment, so we just skip past the
; code. Otherwise, we use the screen
; code value as the index into the
; CODEBUFFER and put the value there,
; ready to be called during print by
; BUFPRT.
DEFINE:     INY
            LDA     (TEX),Y
            CMP     #'='
            BEQ     DODEFINE
            DEY
            LDA     SAVCHAR
            JMP     NOTRET
DODEFINE:   INY
            JSR     ASCHEX
            PHA
            LDA     SAVCHAR
            AND     #127
            TAX
            PLA
            STA     CODEBUFFER,X
            JSR     SPCEXIT
            JMP     SPCONT

; Link to next file. The filename is called
; from text; we check for T or D to get
; the proper device number, erase the
; text in memory, then call the Kernal
; Load routine. After the load, we check
; for a load error, then jump to RETEX to
; continue printing.
LINK:       INY
            LDX     #8
            LDA     (TEX),Y
            AND     #63
            CMP     #'d'-64
            BEQ     LINK2
            LDX     #1
            CMP     #'t'-64
            BEQ     LINK2
            JMP     PBORT
LINK2:      STX     DVN
            INY
            LDA     (TEX),Y
            CMP     #':'
            BEQ     LINKLOOP
            JMP     PBORT
LINKLOOP:   INY
            LDA     (TEX),Y
            CMP     #RETCHAR
            BEQ     OUTNAM
            JSR     INTOAS
            STA     FILENAME-3,Y
            JMP     LINKLOOP
OUTNAM:     TYA
            SEC
            SBC     #3
            LDX     #<FILENAME
            LDY     #>FILENAME
            JSR     SETNAM
            JSR     CLRCHN
            LDA     #2
            JSR     CLOSE
            LDA     #2
            LDX     DVN
            LDY     #0
            JSR     SETLFS
            JSR     ERASE
            LDA     #0
            LDX     CURR
            LDY     CURR+1
            JSR     LOAD
            BCC     OKLOD
            JMP     PBORT
OKLOD:      STX     LASTLINE
            STY     LASTLINE+1
            PLA
            PLA
            LDX     #1
            JSR     CHKOUT
            JMP     RETEX

; Not a printer command. DCMND calls
; INPUT for a disk command. If RE-
; TURN is pressed without a disk com-
; mand, we jump straight to displaying
; the disk error message. Otherwise, we
; send the command and fall through to
; checking the disk error message to let
; the user know the success of the
; command.
DCMND:      JSR     CLALL
            LDA     #0
            JSR     SETNAM
            LDA     #15
            LDX     #8
            LDY     #15
            JSR     SETLFS
            JSR     OPEN
            BCC     OKD
DCOUT:      LDA     #15
            JSR     CLOSE
            JSR     CLALL
            JMP     SYSMSG
OKD:        JSR     TOPCLR
            LDA     #<DCMSG
            LDY     #>DCMSG
            JSR     PRMSG
            JSR     INPUT
            BEQ     READERR
            LDX     #15
            JSR     CHKOUT
            BCS     DCOUT
            LDA     #<INBUFF
            LDY     #>INBUFF
            JSR     PRMSG
            LDA     #13
            JSR     CHROUT
            JSR     CLRCHN

; READERR is called by DCMND and
; the ERROR routine. It does a CHKIN,
; then calls INPUT, which automatically
; displays the message. CLRCHN cleans
; it up, and we're through.
READERR:    JSR     CLALL
            LDA     #0
            JSR     SETNAM
            LDA     #15
            LDX     #8
            LDY     #15
            JSR     SETLFS
            JSR     OPEN
            BCS     DCOUT
            JSR     TOPCLR
            LDX     #15
            JSR     CHKIN
            JSR     INPUT
            JSR     CLRCHN
            LDA     #15
            JSR     CLOSE
            JSR     CLALL
            LDA     #1
            STA     MSGFLG
            RTS

; Global search and replace. This just
; links together the search-specify rou-
; tine, the replace-specify routine, then
; repeatedly calls Hunt and Replace, until
; Hunt returns "Not Found." (FPOS+1
; is $FF after a search failure.)
SANDR:      JSR     RESET
            LDA     HUNTLEN
            BEQ     NOSR
            JSR     ASKREP
SNR:        JSR     CONTSRCH
            LDA     FPOS+1
            CMP     #$FF
            BEQ     NOSR
            JSR     REPL
            JSR     REFRESH
            JMP     SNR
NOSR:       JMP     SYSMSG

; If SHIFT is held down, we ask for and
; store the hunt phrase. If SHIFT is not
; down, we perform the actual hunt. The
; line in the INBUFF is compare with
; characters in text. If at any point the
; search fails, we continue the compari-
; son with the first character of INBUFF.
; The search is a failure if we reach the
; end-of-text. If the entire length of
; INBUFF matches, the search succeeds,
; so we change the CURRent cursor po-
; sition to the found position, save the
; found position for the sake of the re-
; place routine, then call CHECK to scroll
; to the found position.
HUNT:       LDA     653
            CMP     #5
            BNE     CONTSRCH
RESET:      JSR     TOPCLR
            LDA     #<SRCHMSG
            LDY     #>SRCHMSG
            JSR     PRMSG
            JSR     INPUT
            STA     HUNTLEN
            BNE     OKSRCH
            JMP     SYSMSG
OKSRCH:     LDY     #0
TOBUFF:     LDA     INBUFF,Y
            STA     HUNTBUFF,Y
            INY
            CPY     INLEN
            BNE     TOBUFF
            JMP     SYSMSG
CONTSRCH:   LDA     CURR
            STA     TEX
            LDA     CURR+1
            STA     TEX+1
            LDA     #$FF
            STA     FPOS+1
            LDY     #1
            LDX     #0
            LDA     HUNTLEN
            BEQ     NOTFOUND
SRCH1:      LDA     HUNTBUFF,X
            JSR     ASTOIN
            CMP     (TEX),Y
            BEQ     CY
            LDX     #$FF
CY:         INY
            BNE     NOVFL
            INC     TEX+1
            LDA     TEX+1
            CMP     LASTLINE+1
            BEQ     NOVFL
            BCS     NOTFOUND
NOVFL:      INX
            CPX     HUNTLEN
            BNE     SRCH1
            CLC
            TYA
            ADC     TEX
            STA     TEMP
            LDA     TEX+1
            ADC     #0
            STA     TEMP+1
            LDA     LASTLINE
            CMP     TEMP
            LDA     LASTLINE+1
            SBC     TEMP+1
            BCC     NOTFOUND
            SEC
            LDA     TEMP
            SBC     HUNTLEN
            STA     CURR
            STA     FPOS
            LDA     TEMP+1
            SBC     #0
            STA     CURR+1
            STA     FPOS+1
            JSR     CHECK
            RTS
NOTFOUND:   JSR     TOPCLR
            LDA     #<NFMSG
            LDY     #>NFMSG
            JSR     PRMSG
            LDA     #1
            STA     MSGFLG
            RTS

; The replace routine checks to see if
; SHIFT is held down. If it is, we ask for
; a replace phrase, and exit. If not, we
; check to see if the cursor is at the po-
; sition previously located by the search
; routine. If it is, we delete the found
; phrase, then insert the replace phrase.
; The cursor is moved past the replace
; phrase for the sake of the next search.
; This also prevents endless recursion, as
; in replacing in with winner.
REPSTART:   LDA     653
            CMP     #5
            BNE     REPL
ASKREP:     JSR     TOPCLR
            LDA     #<REPMSG
            LDY     #>REPMSG
            JSR     PRMSG
            JSR     INPUT
            STA     REPLEN
            BEQ     NOREP
            LDY     #0
REPMOV:     LDA     INBUFF,Y
            STA     REPBUFF,Y
            INY
            CPY     INLEN
            BNE     REPMOV
NOREP:      JMP     SYSMSG
REPL:       SEC
            LDA     CURR
            STA     DESTL
            SBC     FPOS
            STA     TEMP
            LDA     CURR+1
            STA     DESTH
            SBC     FPOS+1
            ORA     TEMP
            BNE     NOREPL
            LDA     #$FF
            STA     FPOS+1
            CLC
            LDA     HUNTLEN
            ADC     CURR
            STA     FROML
            LDA     #0
            ADC     CURR+1
            STA     FROMH
            SEC
            LDA     LASTLINE
            SBC     DESTL
            STA     LLEN
            LDA     LASTLINE+1
            SBC     DESTH
            STA     HLEN
            JSR     UMOVE
            SEC
            LDA     LASTLINE
            SBC     HUNTLEN
            STA     LASTLINE
            LDA     LASTLINE+1
            SBC     #0
            STA     LASTLINE+1
            LDA     REPLEN
            BEQ     NOREPL
            STA     INSLEN
            LDA     #0
            STA     INSLEN+1
            JSR     INSBLOCK
            LDY     #0
REPLOOP:    LDA     REPBUFF,Y
            JSR     ASTOIN
            STA     (CURR),Y
            INY
            CPY     REPLEN
            BNE     REPLOOP
            CLC
            LDA     CURR
            ADC     REPLEN
            STA     CURR
            LDA     CURR+1
            ADC     #0
            STA     CURR+1
NOREPL:     JMP     CHECK

; Suddenly we're back to a PRINT sub-
; routine. This examples the buffer as it's
; being printed, checking for printkeys
; and Stage 2 commands like centering.
BUFPRT:     LDY     #0
BUFLP:      CPY     ENDPOS
            BEQ     ENDBUFF
            LDA     (INDIR),Y
            BMI     SPEC2
            JSR     INTOAS
            JSR     CONVASC
            JSR     PCHROUT

; In underline mode, after we print the
; character, we backspace the printhead
; and print an underline character.
            LDA     UNDERLINE
            BEQ     NOBRK
            LDA     #8
            JSR     PCHROUT
            LDA     #95
            JSR     PCHROUT
NOBRK:      INY
            JMP     BUFLP
ENDBUFF:    RTS

; Stage 2 format commands.
SPEC2:      STY     YSAVE
            AND     #127
            STA     SAVCHAR
            JSR     INTOAS

; Centering looks at the length of the
; line, then sends out extra spaces (the
; left margin has already been printed) to
; move the printhead to the right place.
OTHER:      CMP     #'c'
            BNE     NOTCENTER
            SEC
            LDA     PAGEWIDTH
            SBC     ENDPOS
            LSR
            SEC
            SBC     LMARGIN
            TAY
            LDA     #32
CLOOP:      JSR     PCHROUT
            DEY
            BNE     CLOOP
            LDY     YSAVE
            JMP     NOBRK

; Edge right. This subtracts the length of
; the line from the right-margin position
; and moves the printhead to this po-
; sition. The BUFPRT loops finishes the
; line.
NOTCENTER:  CMP     #'e'
            BNE     NOTEDGE
EDGE:       SEC
            LDA     RMARGIN
            SBC     ENDPOS
            SEC
            SBC     LMARGIN
            TAY
            LDA     #32
            JMP     CLOOP

; Toggle underline mode.
NOTEDGE:    CMP     #'u'
            BNE     NOTOG
            LDA     UNDERLINE
            EOR     #1
            STA     UNDERLINE
;
; SpeedScript 3.2r1 patch
; TODO: Add some comments explaining
; this change.
;
            JMP     NOBRK

; Substitute the current page number for
; the # symbol.
NOTOG:      CMP     #'#'
            BNE     DOCODES
;
; SpeedScript 3.2r1 patch
; TODO: explain why STY YSAVE eliminated.
;
DOPGN:      LDX     PAGENUM
            LDA     PAGENUM+1
            LDY     #55
            STY     MAP
            JSR     $BDCD
            LDY     #54
            STY     MAP
            LDY     YSAVE
            JMP     NOBRK

; Do special format codes. This just uses
; the screen-code value of the character
; as an index into the CODEBUFFER,
; then sends out the code. SpeedScript
; makes no judgement on the code being
; sent out.
DOCODES:    LDX     SAVCHAR
            LDA     CODEBUFFER,X
            JSR     PCHROUT
            JMP     NOBRK

; This checks for true ASCII mode and, if
; enabled, exchanges uppercase and
; lowercase. Used for certain non-
; Commodore printers and interfaces.
CONVASC:    LDX     NEEDASC
            BEQ     SKIPASC
            STA     TEMP
            AND     #127
            CMP     #'a'
            BCC     SKIPASC
            CMP     #'z'+1
            BCS     SKIPASC
            TAX
            LDA     TEMP
            AND     #128
            EOR     #128
            LSR
            LSR
            STA     TEMP
            TXA
            ORA     TEMP
SKIPASC:    RTS

; Display free memory
FREEMEM:    JSR     TOPCLR
            SEC
            LDA     TEXEND
            SBC     LASTLINE
            TAX
            LDA     TEXEND+1
            SBC     LASTLINE+1
            LDY     #55
            STY     MAP
            JSR     $BDCD
            LDY     #54
            STY     MAP
            LDA     #1
            STA     MSGFLG
            RTS

; Mark as the DATA segment
            .DATA
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

; Mark as the BSS segment
            .BSS
; Most variables are here at the end.
; They do not become part of the object
; code.
TEXSTART:   .word 0 *+2     ;Start of text area
TEXEND:     .word 0 *+2     ;End of text area
TEXBUF:     .word 0 *+2     ;Start of buffer
BUFEND:     .word 0 *+2     ;End of buffer area
LENTABLE:   .byte 0 *+1     ;Length of first screen line
TOPLIN:     .word 0 *+2     ;Home position in text
MSGFLG:     .byte 0 *+1     ;Message flag
INSMODE:    .byte 0 *+1     ;Insert mode
ENDPOS:     .byte 0 *+1     ;Used by delete routines
FINPOS:     .byte 0 *+1     ;" "
LASTLINE:   .word 0 *+2     ;End-of-text position
LIMIT:      .byte 0 *+1     ;Used by INPUT
INLEN:      .byte 0 *+1     ;" "
BOTSCR:     .word 0 *+2     ;Bottom of screen in text
LBUFF:      .res 40,0       ;Line buffer (REFRESH)
INBUFF:     .res 40,0       ;INPUT buffer
FILENAME:   .res 24,0       ;Stores filename
FNLEN:      .byte 0 *+1     ;Length of filename
SAVCURR:    .word 0 *+2     ;Used by delete routines
BCD:        .word 0 *+2     ;Used by ASCHEX
HEX:        .word 0 *+2     ;" "
TPTR:       .word 0 *+2     ;Last character in buffer
BUFLEN:     .word 0 *+2     ;Buffer length
GOBLEN:     .word 0 *+2     ;Size of deleted text
FROMSAV:    .word 0 *+2     ;Used by delete routines
DESTSAV:    .word 0 *+2     ;" "
HDLEN:      .byte 0 *+1     ;Header length
FTLEN:      .byte 0 *+1     ;Footer length
LMARGIN:    .byte 0 *+1     ;Holds left margin
RMARGIN:    .byte 0 *+1     ;Right margin
PAGELENGTH: .byte 0 *+1     ;Page length
TOPMARG:    .byte 0 *+1     ;Top margin
BOTMARG:    .byte 0 *+1     ;Bottom margin
SPACING:    .byte 0 *+1     ;Line spacing
CONTINUOUS: .byte 0 *+1     ;Page wait mode
PAGENUM:    .word 0 *+2     ;Page number
STARTNUM:   .word 0 *+2     ;Start printing at #
PAGEWIDTH:  .byte 0 *+1     ;Columns across
NOMARG:     .byte 0 *+1     ;Margin release flag
POS:        .byte 0 *+1     ;POSition within the line
LINE:       .byte 0 *+1     ;Line count
YSAVE:      .byte 0 *+1     ;Preserves Y register
SAVCHAR:    .byte 0 *+1     ;Preserves accumulator
INSLEN:     .byte 0 *+1     ;Length of an insertion
DEVNO:      .byte 0 *+1     ;Device number
NEEDASC:    .byte 0 *+1     ;True ASCII flag
UNDERLINE:  .byte 0 *+1     ;Underline mode flag
FPOS:       .word 0 *+2     ;Found position
PCR:        .byte 0 *+1     ;Used by PCHROUT
HUNTLEN:    .byte 0 *+1     ;Length of hunt phrase
HUNTBUFF:   .res 30, 0      ;Holds hunt phrase
REPLEN:     .byte 0 *+1     ;Length of replace phrase
REPBUFF:    .res 30, 0      ;Holds replace phrase
CODEBUFFER: .res 128, 0     ;Holds definable printkeys
PRBUFF:     .res 256, 0     ;Printer line buffer
HDBUFF:     .res 256, 0     ;Holds header
FIRSTRUN:   .byte 0 *+1     ;Has program been run before?
FTBUFF:     .res 256, 0     ;Holds footer
SAVCOL:     .byte 0 *+1     ;Save SCRCOL
LINEFEED:   .byte 0 *+1     ;Linefeed mode flag
BLINKFLAG:  .byte 0 *+1     ;Is cursor in blink phase?

; Some padding to match the official release.
            .data
            .byte   13,13,13,13,13
END:        .END            ;+$100 is TEXSTART
