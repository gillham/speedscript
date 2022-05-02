;
; SpeedScript cursor handling
;

.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "CURSOR"

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
; pointer would point to an area already
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


.segment    "PARA"

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

