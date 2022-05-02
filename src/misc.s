;
; SpeedScript miscellaneous handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "YORN"

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


; Each segment is positioned precisely
; to match the original binary.
.segment    "PRMSG"
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

