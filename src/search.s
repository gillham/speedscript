;
; SpeedScript search (hunt) / replace handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "SEARCH"

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

