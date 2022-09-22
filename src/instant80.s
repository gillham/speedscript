;
; SpeedScript "Instant-80" software 80 column preview.
; from Compute's Gazette December 1987 (page 76)
;
; Reverse engineered by disassembly with jc64dis.
; Many variable names need work after I have a better
; understanding of what they are doing.
;
.include    "c64.inc"
.include    "speedscript.inc"

;
; Temporary kernal function definitions.
; (should these go through jump table properly?)
; 
KCHROUT     =   $F1CA
KOPEN       =   $F34A
KCLOSE      =   $F291

;
; Some SpeedScript proper locations that get patched.
;
LOCLDEND    =   $09A8 ; Where the high byte of END is loaded.
LOCTEXEND   =   $09B0 ; Where the value is that is stored to TEXEND+1.
LOCOPENCL   =   $1778 ; Where the 'JSR OPEN' call is in SpeedScript proper.
LOCCLOSECL  =   $187F ; Where the 'JSR CLOSE' call is in SpeedScript proper.

; Each segment is positioned precisely
; to match the original binary.
.segment    "INSTPAD"
            .RES    1271

; Each segment is positioned precisely
; to match the original binary.
.segment    "INST80"

; Be explicit about the starting position
; here so this ends up in the correct spot
; in the binary.
            .ORG    $2500

INIT80:
      sei                               
      lda  #$CC                         
      sta  LOCTEXEND+1                  
.ifdef EASYCURSOR
      lda  #$28
.else
      lda  #$27
.endif
      sta  LOCLDEND+1                   
      lda  #$2D                         
      sta  LOCOPENCL+1                  
      lda  #$25                         
      sta  LOCOPENCL+2                  
      lda  #$79                         
      sta  LOCCLOSECL+1                 
      lda  #$25                         
      sta  LOCCLOSECL+2                 
      lda  #$97                         
      sta  $0326                        ; KERNAL CHROUT routine vector
      lda  #$25                         
      sta  $0327                        ; KERNAL CHROUT routine vector
      cli                               
      jmp  INIT                         

OPEN80:
      pha                               
      lda  $BA                          ; Current device number
      cmp  #$03                         
      bne  CLKOPEN80                    
      lda  #$3B                         
      sta  $D011                        ; VIC control register
      lda  #$38                         
      sta  $D018                        ; VIC memory control register
      lda  #$94                         
      sta  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      sta  VICBANK80                    
      lda  #$E0                         
      sta  BLNKLOOP80+2                 
      lda  #$00                         
      tax                               
BLNKLOOP80:
      sta  $E000,x                      
      inx                               
      bne  BLNKLOOP80                   
      inc  BLNKLOOP80+2                 
      bne  BLNKLOOP80                   
      lda  #$9F                         
BLNKSTRD80:
      sta  $CC00,x                      
      sta  $CD00,x                      
      sta  $CE00,x                      
      sta  $CF00,x                      
      inx                               
      bne  BLNKSTRD80                   
      stx  REMAINS80                    
      stx  SOMEVAR180                   
      lda  #$FE                         
      sta  SOMEVAR280                   
CLKOPEN80:
      pla                               
      jmp  KOPEN                        ; Routine OPEN of KERNAL

CLOSE80:
      pha                               
      lda  VICBANK80                    
      beq  CLVICSKP80                   
      lda  #$17                         
      sta  $D018                        ; VIC memory control register
      lda  #$1B                         
      sta  $D011                        ; VIC control register
      lda  #$97                         
      sta  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      lda  #$00                         
      sta  VICBANK80                    
CLVICSKP80:
      pla                               
      jmp  KCLOSE                       ; Routine CLOSE of KERNAL

CHROUT80:
      pha                               
      lda  VICBANK80                    
      bne  OUTPUT80                     
      pla                               
      jmp  KCHROUT                      ; Routine CHROUT of KERNAL

OUTPUT80:
      sei                               
      pla                               
      pha                               
      sta  CHARARG80                    
      lda  $01                          ; 6510 I/O register
      pha                               
      txa                               
      pha                               
      tya                               
      pha                               
      lda  CHARARG80                    
      cmp  #$0D                         
      bne  NOTCRLF80                    
      jmp  SCROLL80                     

NOTCRLF80:
      and  #$E0                         
      beq  NOTUNPRT80                   
      cmp  #$80                         
      bne  DOOUTPUT80                   
NOTUNPRT80:
      jmp  FNSHOUT80                    

DOOUTPUT80:
      lsr                               
      lsr                               
      lsr                               
      lsr                               
      lsr                               
      tax                               
      lda  CHRBNKTBL80,x                
      clc                               
      adc  CHARARG80                    
      ldx  $C7                          ; Flag: Write inverse chars: 1=yes 0=not used
      beq  NOTINVRS80                   
      ora  #$80                         
NOTINVRS80:
      ldx  $FE                          ; Free 0 page for user program
      stx  SAVEZPFE80                   
      ldx  $FF                          ; Transient data area of BASIC
      stx  SAVEZPFF80                   
      ldx  #$1B                         
      stx  $FF                          ; Transient data area of BASIC
      asl                               
      rol  $FF                          ; Transient data area of BASIC
      asl                               
      rol  $FF                          ; Transient data area of BASIC
      asl                               
      rol  $FF                          ; Transient data area of BASIC
      sta  $FE                          ; Free 0 page for user program
      lda  #$33                         
      sta  $01                          ; 6510 I/O register
      ldy  #$07                         
      ldx  #$07                         
DRAWLOOP80:
      lda  #$00                         
      sta  DRAWBUF80,y                  
      lda  ($FE),y                      ; Free 0 page for user program
      lsr                               
W25FF:
      ror  DRAWBUF80,x                  
      lsr                               
      lsr                               
      ror  DRAWBUF80,x                  
      lsr                               
      lsr                               
      ror  DRAWBUF80,x                  
      lsr                               
      lsr                               
      ror  DRAWBUF80,x                  
      dex                               
      dey                               
      bpl  DRAWLOOP80                   
      lda  REMAINS80                    
      beq  DRWCHRDN80                   
      ldx  #$07                         
DRWLOOP280:
      lda  DRAWBUF80,x                  
      lsr                               
      lsr                               
      lsr                               
      lsr                               
      sta  DRAWBUF80,x                  
      dex                               
      bpl  DRWLOOP280                   
DRWCHRDN80:
      lda  #$34                         
      sta  $01                          ; 6510 I/O register
      lda  SOMEVAR180                   
      sta  $FE                          ; Free 0 page for user program
      lda  SOMEVAR280                   
      sta  $FF                          ; Transient data area of BASIC
      beq  FNSHOUT80                    
      ldy  #$07                         
DRWLOOP380:
      lda  DRAWBUF80,y                  
      ora  ($FE),y                      ; Free 0 page for user program
      sta  ($FE),y                      ; Free 0 page for user program
      dey                               
      bpl  DRWLOOP380                   
      lda  REMAINS80                    
      eor  #$01                         
      sta  REMAINS80                    
      bne  FNSHOUT80                    
      lda  SOMEVAR180                   
      clc                               
      adc  #$08                         
      sta  SOMEVAR180                   
      bcc  FNSHOUT80                    
      inc  SOMEVAR280                   
FNSHOUT80:
      lda  SAVEZPFE80                   
      sta  $FE                          ; Free 0 page for user program
      lda  SAVEZPFF80                   
      sta  $FF                          ; Transient data area of BASIC
      pla                               
      tay                               
      pla                               
      tax                               
      pla                               
      sta  $01                          ; 6510 I/O register
      cli                               
      pla                               
      jmp  KCHROUT                      ; Routine CHROUT of KERNAL

SCROLL80:
      lda  #$34                         
      sta  $01                          ; 6510 I/O register
      ldx  #$E0                         
      stx  LINECPYD80+2                 
      inx                               
      stx  LINECPYS80+2                 
      ldx  #$00                         
LINECPYS80:
      lda  $E040,x                      
LINECPYD80:
      sta  $E000,x                      
      inx                               
      bne  LINECPYS80                   
      inc  LINECPYD80+2                 
      inc  LINECPYS80+2                 
      bne  LINECPYS80                   
      stx  SOMEVAR180                   
      lda  #$FE                         
      sta  SOMEVAR280                   
      txa                               
DRWLOOP480:
      sta  $FE00,x                      ; Routine SETLFS of KERNAL
      sta  $FE40,x                      
      inx                               
      bne  DRWLOOP480                   
      sta  REMAINS80                    
      beq  FNSHOUT80                    
CHRBNKTBL80:
      .byte $00, $00, $C0, $E0, $00, $C0, $80, $80 
SOMEVAR180:
      .byte $00
SOMEVAR280:
      .byte $00
VICBANK80:
      .byte $00
CHARARG80:
      .byte $00
SAVEZPFE80:
      .byte $00
SAVEZPFF80:
      .byte $00
REMAINS80:
      .byte $00
DRAWBUF80:
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $20                         

