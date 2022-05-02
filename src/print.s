;
; SpeedScript print handling.
;
.include "c64.inc"
.include "speedscript.inc"


; Each segment is positioned precisely
; to match the original binary.
.segment    "PRINT1"

; The start of the printer routines. This
; part could logically be called a separate
; program, but many variables are com-
; mon to the above code.
; Table of default settings for left margin,
; right margin, page length, top margin,
; bottom margin, etc. See the table start-
; ing at LMARGIN at the end of this
; source code.
DEFTAB:     .BYT    5,75,66,5,58,1,1,1,0,1,0,80

; Table of default printer codes.
PRCODES:    .BYT    27,14,15,18

; Another advantage of modular coding
; is that you can change the behavior of
; a lot of code by just changing one
; small, common routine. This is a sub-
; stitute for the Kernal CHROUT, al-
; though it calls CHROUT. It checks to
; see if the current page number equals
; the page number specified by the user
; for printing to start. It also checks for
; the RUN/STOP key to abort the print-
; int and permits print to be paused
; with the SHIFT key.
PCHROUT:    STA     PCR
            TXA
            PHA
            TYA
            PHA
            SEC
            LDA     PAGENUM
            SBC     STARTNUM
            LDA     PAGENUM+1
            SBC     STARTNUM+1
            BCC     SKIPOUT
            LDA     PCR
            JSR     CHROUT
SHIFTFREEZE:LDA     653
            AND     #1
            STA     53280
            BNE     SHIFTFREEZE
            LDA     $91
            CMP     #$7F
            BNE     SKIPOUT
            INC     53280
            NOP
            NOP
            NOP
            JMP     PEXIT
SKIPOUT:    PLA
            TAY
            PLA
            TAX
            LDA     PCR
            RTS

; Displays "Printing..."
PRIN:       JSR     TOPCLR
            LDA     #<PRINMSG
            LDY     #>PRINMSG
            JMP     PRMSG
PBORT:      JMP     PEXIT

; Called by CTRL-P. If SHIFT is not held
; down with CTRL-P, we choose a de-
; vice number of 4, a secondary address
; of 7 (lowercase mode), and no file-
; name. If SHIFT is held down, we ask
; "Print to: Screen, Disk, Printer?" If
; Screen is selected, we use a device
; number of 3. If Disk is slected, we get
; a filename and use a device number
; and secondary address of 8. For Printer,
; we ask for the device number and
; secondary address. SETLFS is called
; after all these decisions are made, then
; OPEN. No matter how the file is
; OPENed, we reference it by file num-
; ber 1.
PRINT:      LDA     SCRCOL
            STA     SAVCOL
            LDA     #0
            STA     WINDCOLR
            STA     53280
            STA     SCRCOL
            JSR     SETNAM
            LDA     #4
            STA     DEVNO
            LDY     #7
            LDA     653
            AND     #1
            BNE     ASKQUES
            JMP     OVERQUES
ASKQUES:    JSR     TOPCLR
            LDA     #<CHOOSEMSG
            LDY     #>CHOOSEMSG
            JSR     PRMSG
            JSR     GETAKEY
            AND     #127
            LDX     #3
            STX     DEVNO
            CMP     #'s'
            BEQ     PRCONT
NOTSCREEN:  LDX     #8
            STX     DEVNO
            CMP     #'d'
            BEQ     DOFN
            CMP     #'p'
            BNE     PBORT
            JSR     TOPCLR
            LDA     #<DEVMSG
            LDY     #>DEVMSG
            JSR     PRMSG
            JSR     GETAKEY
            SEC
            SBC     #48
            CMP     #4
            BCC     PBORT
            CMP     #80
            BCS     PBORT
            STA     DEVNO
            JMP     PRCONT

; Ask for a print filename, if appropriate,
; and add ",S,W" for a sequential write
; file.
DOFN:       JSR     TOPCLR
            LDA     #<FNMSG
            LDY     #>FNMSG
            JSR     PRMSG
            JSR     INPUT
            BEQ     PBORT
            LDY     INLEN
            LDA     #','
            STA     INBUFF,Y
            INY
            LDA     #'w'
            STA     INBUFF,Y
            INY
            STY     INLEN
            LDA     INLEN
            LDX     #<INBUFF
            LDY     #>INBUFF
            JSR     SETNAM
PRCONT:     LDA     DEVNO
            TAY
            CMP     #4
            BCC     OVERQUES
            CMP     #8
            BCS     OVERQUES
NOTD2:      JSR     TOPCLR
            LDA     #<SADRMSG
            LDY     #>SADRMSG
            JSR     PRMSG
            JSR     GETAKEY
            SEC
            SBC     #48
            TAY
            BPL     OVERQUES
            JMP     PBORT
OVERQUES:   LDA     #1
            LDX     DEVNO
            JSR     SETLFS
            JSR     PRIN
            LDA     #1
            JSR     CLOSE
            JSR     OPEN
            LDX     #1
            JSR     CHKOUT
            BCC     PROK
            JMP     PEXIT

; Reset several flags (footer length,
; header length, true ASCII, underline
; mode, and linefeed mode).
PROK:       LDX     #0
            STX     FTLEN
            STX     HDLEN
            STX     NEEDASC
            STX     UNDERLINE
            STX     LINEFEED

; Copy definition tables and default
; printer codes.
COPYDEF:    LDA     DEFTAB,X
            STA     LMARGIN,X
            INX
            CPX     #12
            BNE     COPYDEF
            LDA     #$FF
            STA     LINE
            STA     NOMARG
            LDX     #4
COPYDEFS:   LDA     PRCODES-1,X
            STA     CODEBUFFER+48,X
            DEX
            BNE     COPYDEFS

; Reentry point for print after linked
; files.
RETEX:      LDA     TEXSTART
            STA     TEX
            LDA     TEXSTART+1
            STA     TEX+1

; Main printing loop. We print the left
; margin, grab a line of text, scan back-
; ward until we find a space or a carriage
; return, then break the line there. If
; printer codes are encountered, they're
; passed on to the SPECIAL routine.
; Otherwise, we end up calling BUFPRT
; to print the line and process some other
; control codes.
PLOOP:      LDY     #0
            STY     POS
            CPY     NOMARG
            BEQ     PLOOP1
            LDA     LMARGIN
            STA     POS
PLOOP1:     LDA     (TEX),Y
            BPL     NOTSP
            JMP     SPECIAL
NOTSP:      CMP     #RETCHAR
            BEQ     FOUNDSPACE
NOTRET:     STA     PRBUFF,Y
            INY
            INC     POS
            LDA     POS
            CMP     RMARGIN
            BCC     PLOOP1
            STY     FINPOS
FINDSPACE:  LDA     (TEX),Y
            CMP     #32
            BEQ     FOUNDSPACE
            DEC     POS
            DEY
            BNE     FINDSPACE
            LDY     FINPOS
            JMP     OVERSTOR
FSPACE:     INY
            LDA     (TEX),Y
            CMP     #32
            BEQ     FOUNDSPACE
            DEY
; A bug/typo in the original printed source code was fixed below.
; The book had this label as 'FOUNDSPAC' (missing 'E') here.
; Possibly the original assembler didn't notice due to to a label
; size limitation.
FOUNDSPACE: STY     FINPOS
OVERSTOR:   TYA
            SEC
            ADC     TEX
            STA     TEX
            LDA     TEX+1
            ADC     #0
            STA     TEX+1
            LDY     #0

; If this is the first page, we need to print
; the header, if any, with JSR TOP.
DOBUFF:     LDA     LINE
            CMP     #$FF
            BNE     DOBUF2
            JSR     TOP
DOBUF2:     LDA     NOMARG
            BEQ     OVERMARG
            JSR     LMARG
OVERMARG:   SEC
            ROL     NOMARG
            LDA     FINPOS
            STA     ENDPOS
            LDA     #<PRBUFF
            STA     INDIR
            LDA     #>PRBUFF
            STA     INDIR+1
            JSR     BUFPRT

; A line has been printed. We check to
; see if we've hit the bottom margin and,
; if so, go to PAGE, which goes to the
; end of the page, prints the footer (if
; any), and feeds to the next page.
ZBUFF:      JSR     CRLF
            LDA     LINE
            CMP     BOTMARG
            BCC     NOTPAGE
            JSR     PAGE

; Have we reached the end of text?
NOTPAGE:    SEC
            LDA     TEX
            SBC     LASTLINE
            STA     TEMP
            LDA     TEX+1
            SBC     LASTLINE+1
            ORA     TEMP
            BEQ     DORPT
            BCC     DORPT

; If so, we check for a footer. If there is
; one, we set HDLEN and TOPMARG to
; zero (so that the printhead will end up
; at the right place on the last page) and
; call PAGE, which prints the footer. If
; there is no footer, we leave the
; printhead on the same page so that pa-
; per isn't wasted.
            LDA     FTLEN
            BEQ     PXIT
            LDA     #0
            STA     HDLEN
            STA     TOPMARG
            JSR     PAGE

; Exit routines. If screen output was se-
; lected, we wait for a keystroke before
; going back to editing mode. Since the
; RUN/STOP key is used to abort print-
; ing and to insert a margin indent in
; editing mode, we wait for the user to
; let go of RUN/STOP before we return
; to editing mode.
PXIT:       LDA     DEVNO
            CMP     #3
            BNE     PEXIT
            JSR     GETAKEY
PEXIT:      JSR     STOP
            BEQ     PEXIT
            LDA     #1
            JSR     CLOSE
            JSR     CLALL
            LDA     SAVCOL
            STA     SCRCOL
            LDX     #$FA
            TXS
            JSR     SYSMSG
            JMP     MAIN
DORPT:      JMP     PLOOP

; Paging routines. We skip
; (PAGELENGTH-LINE)-two blank
; lines to get to the bottom of the page,
; print a footer (if there is one) or a blank
; line (if not), then page to the beginning
; of the next page, skipping over the pa-
; per perforation. If the wait mode is en-
; abled, we wait for the user to insert a
; new sheet of paper.
PAGE:       SEC
            LDA     PAGELENGTH
            SBC     LINE
            TAY
            DEY
            DEY
            BEQ     NOSK
            BMI     NOSK
NEXPAGE:    JSR     CR
            DEY
            BNE     NEXPAGE
NOSK:       LDA     FTLEN
            BEQ     SKIPFT
            STA     ENDPOS
            LDA     #<FTBUFF
            STA     INDIR
            LDA     #>FTBUFF
            STA     INDIR+1
            JSR     LMARG
            JSR     BUFPRT
SKIPFT:     JSR     CR
            JSR     CR
            JSR     CR

; Increment the page number.
            INC     PAGENUM
            BNE     NOIPN
            INC     PAGENUM+1

; The page wait mode is inappropriate
; when printing to the screen or to disk,
; or when skipping over pages with the ?
; format command.
NOIPN:      LDA     CONTINUOUS
            BNE     TOP
            LDA     DEVNO
            CMP     #3
            BEQ     TOP
            CMP     #8
            BEQ     TOP
            SEC
            LDA     PAGENUM
            SBC     STARTNUM
            LDA     PAGENUM+1
            SBC     STARTNUM+1
            BCC     TOP
            JSR     CLRCHN
            JSR     TOPCLR
            LDA     #<WAITMSG
            LDY     #>WAITMSG
            JSR     PRMSG
            JSR     GETAKEY
            JSR     PRIN
            LDX     #1
            JSR     CHKOUT

; Print the header, skip to the top
; margin.
TOP:        LDA     HDLEN
            BEQ     NOHEADER
            STA     ENDPOS
            LDA     #<HDBUFF
            STA     INDIR
            LDA     #>HDBUFF
            STA     INDIR+1
            JSR     LMARG
            JSR     BUFPRT
NOHEADER:   LDY     TOPMARG
            STY     LINE
            DEY
            BEQ     SKIPTOP
            BMI     SKIPTOP
TOPLP:      JSR     CR
            DEY
            BNE     TOPLP
SKIPTOP:    RTS

; Left margin routine. This routine is not
; called if NOMARG is selected (margin
; release).
LMARG:      LDA     #32
            LDY     LMARGIN
            STY     POS
            BEQ     LMEXIT
LMLOOP:     JSR     PCHROUT
            DEY
            BNE     LMLOOP
LMEXIT:     RTS

; CRLF is called at the end of most
; printed lines. It increments the LINE
; count and takes into account the cur-
; rent line spacing mode set by the s for-
; mat command.
CRLF:       LDY     SPACING
            CLC
            TYA
            ADC     LINE
            STA     LINE
CRLOOP:     JSR     CR
            DEY
            BNE     CRLOOP
            RTS

; CR just prints a single carriage return
; and linefeed (if specified).
CR:         LDA     #13
            JSR     PCHROUT
            LDA     LINEFEED
            BEQ     NOLF
            JSR     PCHROUT
NOLF:       RTS

; Handle special printer codes like left
; margin. This looks up the printer code
; using a routine similar to CONTROL.
SPECIAL:    STA     SAVCHAR
            AND     #127
            JSR     INTOAS
            LDX     SPTAB
SRCHSP:     CMP     SPTAB,X
            BEQ     FSP
            DEX
            BNE     SRCHSP
            DEC     POS
            JMP     DEFINE
FSP:        DEX
            TXA
            ASL
            TAX
            STY     YSAVE
            LDA     #>SPCONT
            PHA
            LDA     #<SPCONT-1
            PHA
            LDA     SPVECT+1,X
            PHA
            LDA     SPVECT,X
            PHA
            RTS

; After the format code is processed, we
; must skip over the format command
; and its parameter so that it's not
; printed.
SPCONT:     SEC
            LDA     YSAVE
            ADC     TEX
            STA     TEX
            LDA     TEX+1
            ADC     #0
            STA     TEX+1
            JMP     PLOOP

; If the format command ends with a re-
; turn mark, we must skip over the re-
; turn mark as well.
SPCEXIT:    LDA     (TEX),Y
            CMP     #RETCHAR
            BEQ     NOAD
            DEY
NOAD:       STY     YSAVE
            RTS

; Special format code table. It starts with
; the number of format commands, then
; the characters for each format
; command.
SPTAB:      .BYT    18
            .BYTE   "walrtbsnhf@p?xmigj"

; The address-1 of each format routine.
SPVECT:     .WORD   PW-1,AS-1,LM-1,RM-1,TP-1
            .WORD   BT-1,SP-1,NX-1,HD-1,FT-1
            .WORD   PN-1,PL-1,SPAGE-1,ACROSS-1
            .WORD   MRELEASE-1,COMMENT-1,LINK-1
            .WORD   LFSET-1

; m Margin release. INY is used to skip
; over the format character.
MRELEASE:   INY
            LDA     #0
            STA     NOMARG
            JMP     SPCEXIT

; x Columns across, used by centering.
ACROSS:     INY
            JSR     ASCHEX
            STA     PAGEWIDTH
            JMP     SPCEXIT

; ? Start print at specified page.
SPAGE:      INY
            JSR     ASCHEX
            STA     STARTNUM
            LDA     HEX+1
            STA     STARTNUM+1
            JMP     SPCEXIT

; @ Set starting default page number.
PN:         INY
            JSR     ASCHEX
            STA     PAGENUM
            LDA     HEX+1
            STA     PAGENUM+1
            JMP     SPCEXIT

; p Page length.
PL:         INY
            JSR     ASCHEX
            STA     PAGELENGTH
            JMP     SPCEXIT

; w Set page wait mode.
PW:         LDA     #0
            STA     CONTINUOUS
            INY
            JMP     SPCEXIT

; j Set linefeed mode.
LFSET:      LDA     #10
            STA     LINEFEED
            INY
            JMP     SPCEXIT

; a Set true ASCII mode.
AS:         INY
            LDA     #1
            STA     NEEDASC
            JMP     SPCEXIT

; l Left margin.
LM:         INY
            JSR     ASCHEX
            STA     LMARGIN
            JMP     SPCEXIT

; r Right margin.
RM:         INY
            JSR     ASCHEX
            STA     RMARGIN
            JMP     SPCEXIT

; t Top margin.
TP:         INY
            JSR     ASCHEX
            STA     TOPMARG
            JMP     SPCEXIT

; b Bottom margin.
BT:         INY
            JSR     ASCHEX
            STA     BOTMARG
            JMP     SPCEXIT

; s Set line spacing.
SP:         INY
            JSR     ASCHEX
            STA     SPACING
            JMP     SPCEXIT

; n Jump to next page.
NX:         LDY     YSAVE
            INY
            TYA
            PHA
            JSR     PAGE
            PLA
            TAY
            STY     YSAVE
            RTS

; h Define header. Copy header into
; header buffer.
HD:         JSR     PASTRET
            DEY
            STY     HDLEN
            LDY     #1
HDCOPY:     LDA     (TEX),Y
            STA     HDBUFF-1,Y
            INY
            CPY     HDLEN
            BCC     HDCOPY
            BEQ     HDCOPY
            INY
            JMP     SPCEXIT

; Skip just past the return mark.
PASTRET:    INY
            LDA     (TEX),Y
            CMP     #RETCHAR
            BNE     PASTRET
            RTS

; f Define footer.
FT:         JSR     PASTRET
            DEY
            STY     FTLEN
            LDY     #1
FTCOPY:     LDA     (TEX),Y
            STA     FTBUFF-1,Y
            INY
            CPY     FTLEN
            BCC     FTCOPY
            BEQ     FTCOPY
            JMP     SPCEXIT

; i Ignore a line of information
COMMENT:    JSR     PASTRET
            JMP     SPCEXIT

; Define programmable printkeys. We
; check for =. If not found, this is not an
; assignment, so we just skip past the
; code. Otherwise, we use the screen
; code value as the index into the
; CODEBUFFER and put the value there,
; ready to be called during print by
; BUFPRT.
DEFINE:     INY
            LDA     (TEX),Y
            CMP     #'='
            BEQ     DODEFINE
            DEY
            LDA     SAVCHAR
            JMP     NOTRET
DODEFINE:   INY
            JSR     ASCHEX
            PHA
            LDA     SAVCHAR
            AND     #127
            TAX
            PLA
            STA     CODEBUFFER,X
            JSR     SPCEXIT
            JMP     SPCONT

; Link to next file. The filename is called
; from text; we check for T or D to get
; the proper device number, erase the
; text in memory, then call the Kernal
; Load routine. After the load, we check
; for a load error, then jump to RETEX to
; continue printing.
LINK:       INY
            LDX     #8
            LDA     (TEX),Y
            AND     #63
            CMP     #'d'-64
            BEQ     LINK2
            LDX     #1
            CMP     #'t'-64
            BEQ     LINK2
            JMP     PBORT
LINK2:      STX     DVN
            INY
            LDA     (TEX),Y
            CMP     #':'
            BEQ     LINKLOOP
            JMP     PBORT
LINKLOOP:   INY
            LDA     (TEX),Y
            CMP     #RETCHAR
            BEQ     OUTNAM
            JSR     INTOAS
            STA     FILENAME-3,Y
            JMP     LINKLOOP
OUTNAM:     TYA
            SEC
            SBC     #3
            LDX     #<FILENAME
            LDY     #>FILENAME
            JSR     SETNAM
            JSR     CLRCHN
            LDA     #2
            JSR     CLOSE
            LDA     #2
            LDX     DVN
            LDY     #0
            JSR     SETLFS
            JSR     ERASE
            LDA     #0
            LDX     CURR
            LDY     CURR+1
            JSR     LOAD
            BCC     OKLOD
            JMP     PBORT
OKLOD:      STX     LASTLINE
            STY     LASTLINE+1
            PLA
            PLA
            LDX     #1
            JSR     CHKOUT
            JMP     RETEX


; Each segment is positioned precisely
; to match the original binary.
.segment    "PRINT2"

; Suddenly we're back to a PRINT sub-
; routine. This examples the buffer as it's
; being printed, checking for printkeys
; and Stage 2 commands like centering.
BUFPRT:     LDY     #0
BUFLP:      CPY     ENDPOS
            BEQ     ENDBUFF
            LDA     (INDIR),Y
            BMI     SPEC2
            JSR     INTOAS
            JSR     CONVASC
            JSR     PCHROUT

; In underline mode, after we print the
; character, we backspace the printhead
; and print an underline character.
            LDA     UNDERLINE
            BEQ     NOBRK
            LDA     #8
            JSR     PCHROUT
            LDA     #95
            JSR     PCHROUT
NOBRK:      INY
            JMP     BUFLP
ENDBUFF:    RTS

; Stage 2 format commands.
SPEC2:      STY     YSAVE
            AND     #127
            STA     SAVCHAR
            JSR     INTOAS

; Centering looks at the length of the
; line, then sends out extra spaces (the
; left margin has already been printed) to
; move the printhead to the right place.
OTHER:      CMP     #'c'
            BNE     NOTCENTER
            SEC
            LDA     PAGEWIDTH
            SBC     ENDPOS
            LSR
            SEC
            SBC     LMARGIN
            TAY
            LDA     #32
CLOOP:      JSR     PCHROUT
            DEY
            BNE     CLOOP
            LDY     YSAVE
            JMP     NOBRK

; Edge right. This subtracts the length of
; the line from the right-margin position
; and moves the printhead to this po-
; sition. The BUFPRT loops finishes the
; line.
NOTCENTER:  CMP     #'e'
            BNE     NOTEDGE
EDGE:       SEC
            LDA     RMARGIN
            SBC     ENDPOS
            SEC
            SBC     LMARGIN
            TAY
            LDA     #32
            JMP     CLOOP

; Toggle underline mode.
NOTEDGE:    CMP     #'u'
            BNE     NOTOG
            LDA     UNDERLINE
            EOR     #1
            STA     UNDERLINE
            JMP     NOBRK

; Substitute the current page number for
; the # symbol.
NOTOG:      CMP     #'#'
            BNE     DOCODES
DOPGN:      LDX     PAGENUM
            LDA     PAGENUM+1
            LDY     #55
            STY     MAP
            JSR     $BDCD
            LDY     #54
            STY     MAP
            LDY     YSAVE
            JMP     NOBRK

; Do special format codes. This just uses
; the screen-code value of the character
; as an index into the CODEBUFFER,
; then sends out the code. SpeedScript
; makes no judgement on the code being
; sent out.
DOCODES:    LDX     SAVCHAR
            LDA     CODEBUFFER,X
            JSR     PCHROUT
            JMP     NOBRK

; This checks for true ASCII mode and, if
; enabled, exchanges uppercase and
; lowercase. Used for certain non-
; Commodore printers and interfaces.
CONVASC:    LDX     NEEDASC
            BEQ     SKIPASC
            STA     TEMP
            AND     #127
            CMP     #'a'
            BCC     SKIPASC
            CMP     #'z'+1
            BCS     SKIPASC
            TAX
            LDA     TEMP
            AND     #128
            EOR     #128
            LSR
            LSR
            STA     TEMP
            TXA
            ORA     TEMP
SKIPASC:    RTS


; Each segment is positioned precisely
; to match the original binary.
.segment    "FORMAT"
; Called by Ctrl-£ to enter a format
; code. It checks insert mode and inserts
; if necessary.
FORMAT:     JSR     TOPCLR
            LDA     #<FORMSG
            LDY     #>FORMSG
            JSR     PRMSG
            JSR     GETAKEY
            JSR     ASTOIN
            ORA     #$80
            PHA
            LDA     INSMODE
            BEQ     NOINS
            JSR     INSCHAR
NOINS:      JSR     SYSMSG
            PLA
            JMP     PUTCHR

