;
; SpeedScript "Easy Cursor" up/down arrow handling and
; file overwrite (@:<filename) bug avoidance.
; (by scratching the file before saving it)
;
.include    "c64.inc"
.include    "speedscript.inc"

;
; If Easy Cursor is used without Instant 80 we need
; to pad / patch as it is at a different location.
; $2501 When used with just SpeedScript
; $2801 (when Instant 80 is at $2500)
;
.ifndef INSTANT80
.segment    "INSTPAD"
            .RES    697
.endif

; Each segment is positioned precisely
; to match the original binary.
.segment    "EZPAD"
            .RES    319

; Each segment is positioned precisely
; to match the original binary.
.segment    "EZCURS"

.ifdef INSTANT80
      .org $2801
.else
      .org $2501
.endif

ECLINEUP:
      nop                               
      ldx  #$24                         
      ldy  #$00                         
      jsr  MOVECURRUPEC                 
LINEUPLOOPEC:
      jsr  MOVECURRUPEC                 
      cmp  #$1F                         
      beq  EXITTOCHECKEC                
      dex                               
      bne  LINEUPLOOPEC                 
EXITTOCHECKEC:
      ldx  #$01                         
      jmp  CHECK                        

MOVECURRUPEC:
      lda  a:$0039                        ; BASIC current line number
      bne  MOVECURRUP1EC                
      dec  $3A                          ; BASIC current line number
MOVECURRUP1EC:
      dec  $39                          ; BASIC current line number
      lda  ($39),y                      ; BASIC current line number
      rts                               

ECLINEDOWN:
      nop                               
      txa                               
      pha                               
      ldx  #$26                         
      ldy  #$00                         
ECDOWNSTARTMOVE:
      lda  ($39),y                      ; BASIC current line number
      cmp  #$1F                         
      bne  ECDOWNKEEPMOVE               
      ldx  #$01                         
ECDOWNKEEPMOVE:
      inc  $39                          ; BASIC current line number
      bne  ECDOWNEXITCHECK              
      inc  $3A                          ; BASIC current line number
ECDOWNEXITCHECK:
      dex                               
      bne  ECDOWNSTARTMOVE              
      pla                               
      tax                               
      jmp  CHECK                        

ECSAVE:
      pha                               
      txa                               
      pha                               
      tya                               
      pha                               
      ldy  #$00                         
      lda  INBUFF                       
      cmp  #$40                         
      bne  ECDOSAVE                     
ECFINDCOLON:
      iny                               
      lda  INBUFF,y                     
      cmp  #$3A                         
      bne  ECFINDCOLON                  
      iny                               
      tya                               
      tax                               
ECSTARTSCRATCH:
      inc  $BB                          ; Pointer: current file name
      dec  $B7                          ; Length of current file name
      dex                               
      bne  ECSTARTSCRATCH               
      lda  $9A                          ; Output device (CMD=3)
      pha                               
      lda  $B7                          ; Length of current file name
      pha                               
      lda  $BB                          ; Pointer: current file name
      pha                               
      lda  $BC                          ; Pointer: current file name
      pha                               
      tya                               
      pha                               
      lda  #$00                         
      jsr  SETNAM                       ; Routine: Set file name
      lda  #$0F                         
      ldx  #$08                         
      ldy  #$0F                         
      jsr  SETLFS                       ; Routine: Set primary, secondary and logical addresses
      jsr  OPEN                         ; Routine: Open a logical file
      ldx  #$0F                         
      jsr  CHKOUT                       ; Routine: Open an output canal
      lda  #$53                         
      jsr  CHROUT                       ; Routine: Send a char in the channel
      lda  #$3A                         
      jsr  CHROUT                       ; Routine: Send a char in the channel
      pla                               
      tay                               
ECSENDFILENAME:
      lda  INBUFF,y                     
      beq  ECDOSCRATCH                  
      jsr  CHROUT                       ; Routine: Send a char in the channel
      iny                               
      bne  ECSENDFILENAME               
ECDOSCRATCH:
      lda  #$0D                         
      jsr  CHROUT                       ; Routine: Send a char in the channel
      jsr  CLRCHN                       ; Routine: Close the input and output channel
      lda  #$0F                         
      jsr  CLOSE                        ; Routine: Close a specified logical file
      pla                               
      sta  $BC                          ; Pointer: current file name
      pla                               
      sta  $BB                          ; Pointer: current file name
      pla                               
      sta  $B7                          ; Length of current file name
      pla                               
      jsr  CHKOUT                       ; Routine: Open an output canal
ECDOSAVE:
      pla                               
      tay                               
      pla                               
      tax                               
      pla                               
      jsr  SAVE                         ; Routine: Save the Ram to a device
      rts                               

;
; Some .ifdef for certain chunks of code so
; the resulting binary matches "official"
; binaries created by following the instructions
; in the magazine articles.
;
.ifdef INSTANT80
;
; Some SpeedScript proper locations that get patched.
; These labels are only needed by the install code.
;
LOCJSRINITHIGH         =    $080F ; The high byte of the "JSR INIT" (or "JSR INIT80")
LOCLDEND               =    $09A9 ; Where the high byte of END is loaded. (the operand, not LDA)
PATCHSLEFTECL          =    $0B8B ; SLEFT-1 low-byte in VECT: table   (loaded with $01)
PATCHSLEFTECH          =    $0B8C ; SLEFT-1 high-byte in VECT: table  (loaded with $28 for $2801)
PATCHSRIGHTECL         =    $0B8D ; SRIGHT-1 low-byte in VECT: table  (loaded with $24)
PATCHSRIGHTECH         =    $0B8E ; SRIGHT-1 high-byte in VECT: table (loaded with $28 for $2824)
PATCHTSAVEECL          =    $12D8 ; TSAVE: JSR SAVE call low-byte  (loaded with $41)
PATCHTSAVEECH          =    $12D9 ; TSAVE: JSR SAVE call high-byte (loaded with $28 for $2841)
LOCLDENDEC80           =    $2507 ; Where the Instant 80 patch stores end (which it uses to patch?)
RELOCFIXUP1            =    $2508 ; JSR destination high byte fix after moving. $28 becomes $25
RELOCFIXUP2            =    $250B ; JSR destination high byte fix after moving. $28 becomes $25

INSTALLEC:
      lda  LOCJSRINITHIGH               
      cmp  #$25                         
.ifdef INSTANT80
      beq  INSTALLEC80                  
.else
      .byte $F0, $52                    ; FIX: hack to deal with self-relocating
.endif
      lda  #$25                         
      sta  LOCLDEND                     
      lda  #$01                         
      sta  $2D                          ; Pointer: BASIC starting variables
      lda  #$26                         
      sta  $2E                          ; Pointer: BASIC starting variables
      lda  #$01                         
      sta  PATCHSLEFTECL                
      lda  #$25                         
      sta  PATCHSLEFTECH                
      lda  #$24                         
      sta  PATCHSRIGHTECL               
      lda  #$25                         
      sta  PATCHSRIGHTECH               
      lda  #$41                         
      sta  PATCHTSAVEECL                
      lda  #$25                         
      sta  PATCHTSAVEECH                
      lda  #$01                         
      sta  $FC                          
      sta  $FE                          ; Free 0 page for user program
      lda  #$28                         
      sta  $FD                          
      lda  #$25                         
      sta  $FF                          ; Transient data area of BASIC
      ldy  #$00                         
.else
;
; The official binary has some zero padding so we
; add that back here so checksums match.
      .res 66
.endif

;
; The ifdef should always be true so the code afterwards
; is ignored.  This makes it match the official binary.
;
.ifdef EASYCURSOR
INSTALLEC80                  =    $2918 ; Fake this as official binary is truncated. 
.else
RELOCECLOOP:
      lda  ($FC),y                      
      sta  ($FE),y                      ; Free 0 page for user program
      inc  $FC                          
      inc  $FE                          ; Free 0 page for user program
      lda  #$BF                         
      cmp  $FC                          
      bne  RELOCECLOOP                  
      lda  #$25                         
      sta  RELOCFIXUP1                  
      sta  RELOCFIXUP2                  
      rts                               

INSTALLEC80:
      lda  #$28                         
      sta  LOCLDENDEC80                 
      lda  #$01                         
      sta  $2D                          ; Pointer: BASIC starting variables
      lda  #$29                         
      sta  $2E                          ; Pointer: BASIC starting variables
      lda  #$01                         
      sta  PATCHSLEFTECL                
      lda  #$28                         
      sta  PATCHSLEFTECH                
      lda  #$24                         
      sta  PATCHSRIGHTECL               
      lda  #$28                         
      sta  PATCHSRIGHTECH               
      lda  #$41                         
      sta  PATCHTSAVEECL                
      lda  #$28                         
      sta  PATCHTSAVEECH                
      rts                               

      ora  $0000                        
      brk                               
      brk                               
.endif
