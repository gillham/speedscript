;
; SpeedScript input handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "INPUT"
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

