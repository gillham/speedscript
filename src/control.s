;
; SpeedScript control key handling.
;

.include    "c64.inc"
.include    "speedscript.inc"

; This needs to be on the zeropage.
.exportzp     CONTROL

; Each segment is positioned precisely
; to match the original binary.
.segment    "CONTROL"

; CONTROL looks up a keyboard com-
; mand in the list of control codes at
; CTBL. The first byte of CTBL is the ac-
; tual number of commands. Once the
; position is found, this position is dou-
; bled as an index to the two-byte ad-
; dress table at VECT. The address of
; MAIN-1 is put on the stack, simulat-
; ing the return address; then the address
; of the command routine taken from
; VECT is pushed. We then perform an
; RTS. RTS pulls the bytes off the stack
; as if they were put there by a JSR. This
; powerful technique is used to simulate
; ON-GOTO in machine language.
CONTROL:    TXA
            LDX     CTBL
SRCH:       CMP     CTBL,X
            BEQ     FOUND
            DEX
            BNE     SRCH
            JMP     MAIN
FOUND:      DEX
            TXA
            ASL     A
            TAX
; A bug in the original printed source code was fixed below.
; The original source had 'LDA #>MAIN-1' which didn't
; generate correct code matching the original binary.
; Parentheses were added for explicit precedence.
            LDA     #>(MAIN-1)
            PHA
            LDA     #<MAIN-1
            PHA
            LDA     VECT+1,X
            PHA
            LDA     VECT,X
            PHA
            RTS
CTBL:       .BYT    39
            .BYT    29,157,137,133,2,12,138,134,20,148
            .BYT    4,19,9,147,135,139,5,136,140
            .BYT    22,145,17,159,18,24,26,16
            .BYT    28,30,6,1,11,8,31,3,131
            .BYT    10,141,7
VECT:       .WORD   RIGHT-1,LEFT-1,WLEFT-1,WRIGHT-1,BORDER-1,LETTERS-1
            .WORD   SLEFT-1,SRIGHT-1,DELCHAR-1,INSCHAR-1,DELETE-1
            .WORD   HOME-1,INSTGL-1,CLEAR-1,PARIGHT-1,PARLEFT-1
            .WORD   ERAS-1,TLOAD-1,TSAVE-1,VERIFY-1
.ifdef EASYCURSOR
            .WORD   ECLINEUP,ECLINEDOWN,CATALOG-1,INSBUFFER-1,SWITCH-1
.else
            .WORD   SLEFT-1,SRIGHT-1,CATALOG-1,INSBUFFER-1,SWITCH-1
.endif
            .WORD   ENDTEX-1,PRINT-1,FORMAT-1,DCMND-1
            .WORD   DELIN-1,ALPHA-1,KILLBUFF-1,HUNT-1,FREEMEM-1,TAB-1
            .WORD   LOTTASPACES-1,REPSTART-1,ENDPAR-1,SANDR-1

