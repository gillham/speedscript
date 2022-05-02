;
; SpeedScript erase handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "ERASE"
; The following routine fills the entire
; text area with space characters (screen
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


; Each segment is positioned precisely
; to match the original binary.
.segment    "CLEAR"

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


; Each segment is positioned precisely
; to match the original binary.
.segment    "ERAS"
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

