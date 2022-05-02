;
; SpeedScript refresh handling.
;
.include "c64.inc"
.include "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment "REFRESH"

;
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

