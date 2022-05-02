;
; SpeedScript delete handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "DELETE"

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

