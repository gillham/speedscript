;
; SpeedScript defines
;

;
; Locations used by high-speed memory
; move routines:
FROML       =       $26
FROMH       =       $27
DESTL       =       $9E
DESTH       =       $9F
LLEN        =       $B4
HLEN        =       $B5

; CURR: Position of cursor within text
; memory. SCR: used by the REFRESH
; routine.
CURR        =       $39
SCR         =       $C3

; TEX: An alternate location used in tan-
; dem with CURR. COLR is used by RE-
; FRESH. TEMP is used throughout as a
; reusable scratchpad pointer. INDIR is
; also a reusable indirect pointer.
; UNDERCURS stores the value of the
; character highlighted by the cursor.
TEX         =       $FB
COLR        =       $14
TEMP        =       $3B
INDIR       =       $FD
UNDERCURS   =       $02

; WINDCOLR: Color of command line
; window supported by REFRESH. MAP
; is the 6510's built-in I/O port, used for
; mapping in and out ROMs from the
; address space. RETCHAR is the screen-
; code value of the return mark (a left-
; pointing arrow).
WINDCOLR    =       $0C
MAP         =       $01
RETCHAR     =       31


;
; Global definitions to avoid needing to
; .export / .import everywhere.
;

;
; SpeedScript functions
;
.global ADYCURR
.global ALPHA
.global ASCHEX
.global ASTOIN
.global BORDER
.global BUFPRT
.global CATALOG
.global CHECK
.global CLEAR
.global DCMND
.global DELC
.global DELCHAR
.global DELETE
.global DELIN
.global DELITE
.global DIRNAME
.global DMOVE
.global DVN
.global ENDPAR
.global ENDTEX
.global ERAS
.global ERASE
.global FINE
.global FORMAT
.global FREEMEM
.global GETAKEY
.global HIGHLIGHT
.global HOME
.global HUNT
.global INIT
.global INIT2
.global INPUT
.global INSBLOCK
.global INSBUFFER
.global INSCHAR
.global INSTGL
.global INTOAS
.global KILLBUFF
.global LBUFF
.global LEFT
.global LETTERS
.global LOTTASPACES
.global MAIN
.global PARIGHT
.global PARLEFT
.global PRINT
.global PRMSG
.global PUTCHR
.global READERR
.global REFRESH
.global REPSTART
.global RIGHT
.global SANDR
.global SCRCOL
.global SLEFT
.global SRIGHT
.global SWITCH
.global SYSMSG
.global TAB
.global TEXCOLR
.global TLOAD
.global TOPCLR
.global TSAVE
.global UMOVE
.global VERIFY
.global WLEFT
.global WRIGHT
.global YORN
; mark zeropage
.globalzp CONTROL

;
; SpeedScript text strings
;
.global MSG1
.global MSG2
.global KILLMSG
.global BUFERR
.global DELMSG
.global YMSG
.global CLRMSG
.global ERASMSG
.global FORMSG
.global SAVMSG
.global FNF
.global BRMSG
.global VERERR
.global OKMSG
.global TDMSG
.global LOADMSG
.global VERMSG
.global DIRMSG
.global DCMSG
.global DIRNAME
.global INSERR
.global INSMSG
.global CHOOSEMSG
.global DEVMSG
.global SADRMSG
.global FNMSG
.global PRINMSG
.global WAITMSG
.global SRCHMSG
.global NFMSG
.global REPMSG
.global XITMSG

;
; SpeedScript global variables
;
.global TEXSTART
.global TEXEND
.global TEXBUF
.global BUFEND
.global LENTABLE
.global TOPLIN
.global MSGFLG
.global INSMODE
.global ENDPOS
.global FINPOS
.global LASTLINE
.global LIMIT
.global INLEN
.global BOTSCR
.global LBUFF
.global INBUFF
.global FILENAME
.global FNLEN
.global SAVCURR
.global BCD
.global HEX
.global TPTR
.global BUFLEN
.global GOBLEN
.global FROMSAV
.global DESTSAV
.global HDLEN
.global FTLEN
.global LMARGIN
.global RMARGIN
.global PAGELENGTH
.global TOPMARG
.global BOTMARG
.global SPACING
.global CONTINUOUS
.global PAGENUM
.global STARTNUM
.global PAGEWIDTH
.global NOMARG
.global POS
.global LINE
.global YSAVE
.global SAVCHAR
.global INSLEN
.global DEVNO
.global NEEDASC
.global UNDERLINE
.global FPOS
.global PCR
.global HUNTLEN
.global HUNTBUFF
.global REPLEN
.global REPBUFF
.global CODEBUFFER
.global PRBUFF
.global HDBUFF
.global FIRSTRUN
.global FTBUFF
.global SAVCOL
.global LINEFEED
.global BLINKFLAG

;
; Optional features
;
.ifdef INSTANT80
.global INIT80
.endif
.ifdef EASYCURSOR
.global ECLINEUP
.global ECLINEDOWN
.global ECSAVE
.endif

;
; end-of-file
;
