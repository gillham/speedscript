;
; SpeedScript insert handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "INSERT1"

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


; Each segment is positioned precisely
; to match the original binary.
.segment    "INSERT2"

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

