;
; SpeedScript interrupt handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "IRQ"

; This enables the raster interupt. The
; raster interrupt allows separate back-
; ground colors for the command line
; and the rest of the screen. It lets us
; change the color of the top line to flag
; insert mode or to warn the user with a
; red color that he/she should be careful.
; Since it is an interrupt, it is always run-
; ning in the background. Interrupt
; routines must always be careful not to
; corrupt the main program.
HIGHLIGHT:  SEI
            LDA     #0
            STA     $DC0E
            LDA     #27
            STA     $D011
            LDA     #<IRQ
            STA     $314
            LDA     #>IRQ
            STA     $315
            LDA     #1
            STA     $D01A
            STA     $D012
            CLI
            RTS
IRQ:        LDA     #58
            LDY     WINDCOLR
            CMP     $D012
            BNE     MID
            LDA     #1
            LDY     SCRCOL
MID:        STY     $D021
            STA     $D012
SKIP:       CMP     #1
            BEQ     DEFALT
            LDA     #1
            STA     $D019
            JMP     $FEBC
DEFALT:     LDA     #1
            STA     $D019
            JMP     $EA31

