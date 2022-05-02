;
; SpeedScript move handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "MOVE"

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
; SpeedScript 3.2r2 patch
; TODO: explain this further.
; 0x2600 should be close to TEXSTART?
MOVLOOP:    LDA     $2601,Y
            STA     $2600,Y
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
; SpeedScript 3.2r2 patch
; TODO: decide if this should be a
; new variable.  It is pointing
; into the FTBUFF it appears.
;
DMOVLOOP:   LDA     $244f,Y
            STA     $2450,Y
            DEY
            CPY     #255
            BNE     DMOVLOOP
SKIPDMOV:   DEC     DMOVLOOP+2
            DEC     DMOVLOOP+5
            DEX
            BNE     DMOV1
            RTS

