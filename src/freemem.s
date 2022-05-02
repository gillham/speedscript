;
; SpeedScript freemem handling
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "FREEMEM"

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

