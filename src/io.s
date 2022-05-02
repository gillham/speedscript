;
; SpeedScript I/O handling.
;
.include    "c64.inc"
.include    "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "IO1"

; Here is where most of the input/output
; routines start. TSAVE saves the entire
; document area using the Kernal SAVE
; routine. TOPEN is called by both
; TSAVE and TLOAD to get the filename
; and open the file for either tape or
; disk.
TSAVE:      JSR     TOPCLR
            LDA     #<SAVMSG
            LDY     #>SAVMSG
            JSR     PRMSG
            JSR     TOPEN
            BCS     ERROR
            LDA     TEXSTART
            STA     TEX
            LDA     TEXSTART+1
            STA     TEX+1
            LDX     LASTLINE
            LDY     LASTLINE+1
            LDA     #TEX
            JSR     SAVE
            BCS     ERROR

; Location $90 is the value of the
; Kernal's STatus flag. It's shorter to use
; LDA $90 than JSR READST.
            LDA     $90
            AND     #191
            BNE     ERROR
            JMP     FINE

; The ERROR message routine. May this
; routine never be called when you use
; SpeedScript, but that's too much to ask
; for. The error code from the Kernal
; routine is 0 if the error was Break
; Abort. If the device number (DVN) is 8
; for disk, we read the disk error chan-
; nel; otherwise, we just print a generic
; error message.
ERROR:      BEQ     STOPPED
            LDA     DVN
            CMP     #8
            BCC     TAPERR
            JSR     READERR
            JMP     ERXIT
TAPERR:     LDA     DVN
            CMP     #1
            BEQ     TAPERR
            JSR     TOPCLR
            LDA     #<FNF
            LDY     #>FNF
            JSR     PRMSG
ERXIT:      JSR     HIGHLIGHT
            LDA     #1
            STA     MSGFLG
            RTS
STOPPED:    JSR     TOPCLR
            LDA     #<BRMSG
            LDY     #>BRMSG
            JSR     PRMSG
            JMP     ERXIT
;
; SpeedScript 3.2r2 patch
; TODO: update comment explaining this
; change. It appears to set default device
; number to 8.
DVN:        .BYT    8

; TOPEN gets the filename, asks for tape
; or disk, then calls SETLFS and
; SETNAM, readying for LOAD or
; SAVE. If RETURN is pressed without
; any filename, the return address of the
; calling routine is pulled off so that we
; can jump straight back to the MAIN
; loop.
TOPEN:      JSR     INPUT
            BEQ     OPABORT
OP2:        LDA     #<TDMSG
            LDY     #>TDMSG
            JSR     PRMSG
            JSR     GETAKEY
            LDX     #8
            CMP     #'d'
            BEQ     OPCONT
            LDX     #1
            CMP     #'t'
            BEQ     OPCONT
OPABORT:    JSR     SYSMSG
            PLA
            PLA
            RTS
OPCONT:     STX     DVN
            LDA     #1
            LDY     #0
            JSR     SETLFS
            LDY     #0
            CPX     #1
            BEQ     SKIPDISK
            LDA     INBUFF,Y
            CMP     #'@'
            NOP
            NOP
            LDA     INBUFF+1,Y
            CMP     #':'
            BEQ     SKIPDISK
            LDA     INBUFF+2,Y
            CMP     #':'
            BEQ     SKIPDISK

; If 0:, 1:, @0:, or xx: did not precede the
; filename, we add 0:. Some think this
; makes disk writes more reliable. The
; NOPs above null out the comparison
; with the @ sign. Originally written as
; BNE SKIPDISK, this prevented the use
; of the prefix 1: for owners of dual-drive
; disks drives.
ADDZERO:    LDA     #'0'
            STA     FILENAME
            LDA     #':'
            STA     FILENAME+1
COPY1:      LDA     INBUFF,Y
            STA     FILENAME+2,Y
            INY
            CPY     INLEN
            BCC     COPY1
            BEQ     COPY1
            INY
            JMP     SETNAME
SKIPDISK:   LDA     INBUFF,Y
            STA     FILENAME,Y
            INY
            CPY     INLEN
            BNE     SKIPDISK
SETNAME:    STY     FNLEN
            JSR     TOPCLR
            LDA     #<INBUFF
            LDY     #>INBUFF
            JSR     PRMSG
            LDA     FNLEN
            LDX     #<FILENAME
            LDY     #>FILENAME
            JSR     SETNAM
            LDA     #13
            JSR     CHROUT
            JMP     DELITE


; Each segment is positioned precisely
; to match the original binary.
.segment    "IO2"

; The Load routine checks the cursor po-
; sition. If the cursor is at the top of text,
; we call the ERASE routine to wipe out
; memory before the Load. Otherwise,
; the Load starts at the cursor position,
; performing an append.
TLOAD:      SEC
            LDA     CURR
            SBC     TEXSTART
            STA     TEMP
            LDA     CURR+1
            SBC     TEXSTART+1
            ORA     TEMP
            BEQ     LOAD2
            LDA     #5
            STA     WINDCOLR
LOAD2:      JSR     TOPCLR
            LDA     #<LOADMSG
            LDY     #>LOADMSG
            JSR     PRMSG
            JSR     TOPEN
            LDA     WINDCOLR
            CMP     #5
            BEQ     NOER
            JSR     ERASE
NOER:       LDA     #0
            LDX     CURR
            LDY     CURR+1
LDVER:      JSR     LOAD
            BCC     LOD
            JMP     ERROR
LOD:        STX     LASTLINE
            STY     LASTLINE+1
FINE:       JSR     CLALL
            JSR     TOPCLR
            LDA     #<OKMSG
            LDY     #>OKMSG
            JSR     PRMSG
            JMP     ERXIT

; Verify takes advantage of the Kernal
; routine, so it is very similar to the Load
; routine.
VERIFY:     JSR     TOPCLR
            LDA     #<VERMSG
            LDY     #>VERMSG
            JSR     PRMSG
            JSR     TOPEN
            LDA     #1
            LDX     TEXSTART
            LDY     TEXSTART+1
            JSR     LOAD
            LDA     $90
            AND     #191
            BEQ     FINE
            JSR     TOPCLR
            LDA     #<VERERR
            LDY     #>VERERR
            JSR     PRMSG
            JMP     ERXIT

; DELITE turns off the raster interrupt.
; You must turn off raster interrupts (and
; sprites where appropriate) before tape
; operations. It also restores the default
; interrupts and fixes the screen colors.
DELITE:     SEI
            LDA     #0
            STA     $D01A
            STA     53280
            STA     53281
            LDA     #$31
            STA     $314
            LDA     #$EA
            STA     $315
            LDA     #1
            STA     $DC0E
            CLI
            RTS

; Disk directory routine. It opens "$" as
; a program file, throws away the link
; bytes, prints the line number bytes as
; the blocks used, then prints all follow-
; ing text until the end-of-line zero byte.
; It's similar to how programs are LISTed
; in BASIC, except that nothing is
; untokenized. The system is so sensitive
; to read errors that we call DCHRIN
; (which constantly checks for errors) in-
; stead of directly calling the Kernal
; CHRIN routine. DCHRIN can abort the
; main loop of the DIR routine.
CATALOG:    LDA     #147
            JSR     CHROUT
            LDA     #13
            JSR     CHROUT
            JSR     DELITE
            JSR     DIR
            LDA     #13
            JSR     CHROUT
            LDA     #<DIRMSG
            LDY     #>DIRMSG
            JSR     PRMSG
WAITKEY:    JSR     GETIN
            CMP     #13
            BNE     WAITKEY
            JSR     HIGHLIGHT
            JMP     SYSMSG
ENDIR:      JSR     CLRCHN
            LDA     #1
            JSR     CLOSE
            RTS
DIR:        JSR     CLALL
            LDA     #1
            LDX     #8
            LDY     #0
            JSR     SETLFS
            LDA     #1
            LDX     #<DIRNAME
            LDY     #>DIRNAME
            JSR     SETNAM
            JSR     OPEN
            BCS     ENDIR
            LDX     #1
            JSR     CHKIN
            JSR     DCHRIN
            JSR     DCHRIN
DIRLOOP:    JSR     DCHRIN
            JSR     DCHRIN
            BEQ     ENDIR
PAUSE:      JSR     CLRCHN
            JSR     GETIN
            CMP     #32
            BNE     NOPAUSE
            JSR     GETAKEY
NOPAUSE:    LDX     #1
            JSR     CHKIN
            JSR     DCHRIN
            PHA
            JSR     DCHRIN
            TAY
            PLA
            TAX
            TYA
            LDY     #55
            STY     MAP
            JSR     $BDCD
            LDY     #54
            STY     MAP
            LDA     #32
            JSR     CHROUT
INLOOP:     JSR     DCHRIN
            BEQ     DLINE
            JSR     CHROUT
            JMP     INLOOP
DLINE:      LDA     #13
            JSR     CHROUT
            JMP     DIRLOOP
DCHRIN:     JSR     CHRIN
            PHA
            LDA     $90
            AND     #191
            BEQ     NOSTERR
            PLA
            PLA
            PLA
            JMP     ENDIR
NOSTERR:    PLA
            RTS


; Each segment is positioned precisely
; to match the original binary.
.segment    "DCMND"

; Not a printer command. DCMND calls
; INPUT for a disk command. If RE-
; TURN is pressed without a disk com-
; mand, we jump straight to displaying
; the disk error message. Otherwise, we
; send the command and fall through to
; checking the disk error message to let
; the user know the success of the
; command.
DCMND:      JSR     CLALL
            LDA     #0
            JSR     SETNAM
            LDA     #15
            LDX     #8
            LDY     #15
            JSR     SETLFS
            JSR     OPEN
            BCC     OKD
DCOUT:      LDA     #15
            JSR     CLOSE
            JSR     CLALL
            JMP     SYSMSG
OKD:        JSR     TOPCLR
            LDA     #<DCMSG
            LDY     #>DCMSG
            JSR     PRMSG
            JSR     INPUT
            BEQ     READERR
            LDX     #15
            JSR     CHKOUT
            BCS     DCOUT
            LDA     #<INBUFF
            LDY     #>INBUFF
            JSR     PRMSG
            LDA     #13
            JSR     CHROUT
            JSR     CLRCHN

; READERR is called by DCMND and
; the ERROR routine. It does a CHKIN,
; then calls INPUT, which automatically
; displays the message. CLRCHN cleans
; it up, and we're through.
READERR:    JSR     CLALL
            LDA     #0
            JSR     SETNAM
            LDA     #15
            LDX     #8
            LDY     #15
            JSR     SETLFS
            JSR     OPEN
            BCS     DCOUT
            JSR     TOPCLR
            LDX     #15
            JSR     CHKIN
            JSR     INPUT
            JSR     CLRCHN
            LDA     #15
            JSR     CLOSE
            JSR     CLALL
            LDA     #1
            STA     MSGFLG
            RTS

