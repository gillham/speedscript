;
; SpeedScript variable definition.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment "VARS"

; Most variables are here at the end.
; They do not become part of the object
; code.
TEXSTART:   .word 0 *+2     ;Start of text area
TEXEND:     .word 0 *+2     ;End of text area
TEXBUF:     .word 0 *+2     ;Start of buffer
BUFEND:     .word 0 *+2     ;End of buffer area
LENTABLE:   .byte 0 *+1     ;Length of first screen line
TOPLIN:     .word 0 *+2     ;Home position in text
MSGFLG:     .byte 0 *+1     ;Message flag
INSMODE:    .byte 0 *+1     ;Insert mode
ENDPOS:     .byte 0 *+1     ;Used by delete routines
FINPOS:     .byte 0 *+1     ;" "
LASTLINE:   .word 0 *+2     ;End-of-text position
LIMIT:      .byte 0 *+1     ;Used by INPUT
INLEN:      .byte 0 *+1     ;" "
BOTSCR:     .word 0 *+2     ;Bottom of screen in text
LBUFF:      .res 40,0       ;Line buffer (REFRESH)
INBUFF:     .res 40,0       ;INPUT buffer
FILENAME:   .res 24,0       ;Stores filename
FNLEN:      .byte 0 *+1     ;Length of filename
SAVCURR:    .word 0 *+2     ;Used by delete routines
BCD:        .word 0 *+2     ;Used by ASCHEX
HEX:        .word 0 *+2     ;" "
TPTR:       .word 0 *+2     ;Last character in buffer
BUFLEN:     .word 0 *+2     ;Buffer length
GOBLEN:     .word 0 *+2     ;Size of deleted text
FROMSAV:    .word 0 *+2     ;Used by delete routines
DESTSAV:    .word 0 *+2     ;" "
HDLEN:      .byte 0 *+1     ;Header length
FTLEN:      .byte 0 *+1     ;Footer length
LMARGIN:    .byte 0 *+1     ;Holds left margin
RMARGIN:    .byte 0 *+1     ;Right margin
PAGELENGTH: .byte 0 *+1     ;Page length
TOPMARG:    .byte 0 *+1     ;Top margin
BOTMARG:    .byte 0 *+1     ;Bottom margin
SPACING:    .byte 0 *+1     ;Line spacing
CONTINUOUS: .byte 0 *+1     ;Page wait mode
PAGENUM:    .word 0 *+2     ;Page number
STARTNUM:   .word 0 *+2     ;Start printing at #
PAGEWIDTH:  .byte 0 *+1     ;Columns across
NOMARG:     .byte 0 *+1     ;Margin release flag
POS:        .byte 0 *+1     ;POSition within the line
LINE:       .byte 0 *+1     ;Line count
YSAVE:      .byte 0 *+1     ;Preserves Y register
SAVCHAR:    .byte 0 *+1     ;Preserves accumulator
INSLEN:     .byte 0 *+1     ;Length of an insertion
DEVNO:      .byte 0 *+1     ;Device number
NEEDASC:    .byte 0 *+1     ;True ASCII flag
UNDERLINE:  .byte 0 *+1     ;Underline mode flag
FPOS:       .word 0 *+2     ;Found position
PCR:        .byte 0 *+1     ;Used by PCHROUT
HUNTLEN:    .byte 0 *+1     ;Length of hunt phrase
HUNTBUFF:   .res 30, 0      ;Holds hunt phrase
REPLEN:     .byte 0 *+1     ;Length of replace phrase
REPBUFF:    .res 30, 0      ;Holds replace phrase
CODEBUFFER: .res 128, 0     ;Holds definable printkeys
PRBUFF:     .res 256, 0     ;Printer line buffer
HDBUFF:     .res 256, 0     ;Holds header
FIRSTRUN:   .byte 0 *+1     ;Has program been run before?
FTBUFF:     .res 256, 0     ;Holds footer
SAVCOL:     .byte 0 *+1     ;Save SCRCOL
LINEFEED:   .byte 0 *+1     ;Linefeed mode flag
BLINKFLAG:  .byte 0 *+1     ;Is cursor in blink phase?

