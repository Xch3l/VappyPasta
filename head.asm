.EMPTYFILL $FF

; Declare two ROM banks (second bank is unused)
.ROMBANKMAP
  BANKSTOTAL 2
  BANKSIZE $4000
  BANKS 2
.ENDRO

; Names for slot indices
.DEFINE SLOT_ROM   0
.DEFINE SLOT_VRAM  1
.DEFINE SLOT_SRAM  2
.DEFINE SLOT_WRAM  3
.DEFINE SLOT_WRAMH 4
.DEFINE SLOT_HRAM  5

; GameBoy memory layout
.MEMORYMAP
  DEFAULTSLOT 0
  SLOT SLOT_ROM   $0000 $4000 ; 16KB    Higher ROM / Bank switchable
  SLOT SLOT_VRAM  $8000 $2000 ;  8KB    VRAM
  SLOT SLOT_SRAM  $A000 $2000 ;  8KB    External RAM (SRAM)
  SLOT SLOT_WRAM  $C000 $1000 ;  4KB    WRAM
  SLOT SLOT_WRAMH $D000 $1000 ;  4KB    WRAM high (banks 1-7 in CGB Mode)
  SLOT SLOT_HRAM  $FF80 $007E ; 127B    HI RAM
.ENDME

; GameBoy memory addresses
.DEFINE VRAM   $8000 ; Lower VRAM. Tile data
.DEFINE VRAMH  $8800 ; Higher VRAM (GBC only)
.DEFINE BGMAP  $9800 ; Background layer data
.DEFINE BGMAPH $9C00 ; BG Layer page 2 (GBC only)
.DEFINE SRAM   $A000 ; External memory (or SRAM)
.DEFINE WRAM   $C000 ; Main memory
.DEFINE OAM    $FE00 ; Sprite memory
.DEFINE IO     $FF00 ; I/O Registers
.DEFINE HRAM   $FF80 ; High RAM. Only segment accessible during OAM DMA

; Registers
.INCLUDE "regs.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Macros to read from and write to I/O and HRAM

.MACRO seth
  .IF NARGS == 2
  ld A, \2
  .ENDIF
  ldh (\1&255), A
.ENDM

.MACRO geth
  ldh A, (\1&255)
.ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.RAMSECTION "HRAM" SLOT SLOT_HRAM
  SYSTEM_FLAGS    db ; VR....GG
  RNGVALUE        dw ; Random number
  JP_DOWN         db ; Buttons held down
  JP_PRESS        db ; Buttons pressed this frame
.ENDS

.DEFINE OAMTABLE $CF00

; SYSTEM_FLAGS        V... ..GG
.DEFINE SF_VBLANK 7 ; V          VBlank flag
.DEFINE SF_READY  6 ;  R         Ready for VBlank
.DEFINE SF_DMG    0 ;        00  GameBoy
.DEFINE SF_CGB    1 ;        01  GameBoy Color
.DEFINE SF_AGB    2 ;        10  GameBoy Advance

; Button bits
.DEFINE JPB_RIGHT  0
.DEFINE JPB_LEFT   1
.DEFINE JPB_UP     2
.DEFINE JPB_DOWN   3
.DEFINE JPB_A      4
.DEFINE JPB_B      5
.DEFINE JPB_SELECT 6
.DEFINE JPB_START  7

; Button bytes
.DEFINE JPK_RIGHT  1<<JPB_RIGHT 
.DEFINE JPK_LEFT   1<<JPB_LEFT  
.DEFINE JPK_UP     1<<JPB_UP    
.DEFINE JPK_DOWN   1<<JPB_DOWN  
.DEFINE JPK_A      1<<JPB_A     
.DEFINE JPK_B      1<<JPB_B     
.DEFINE JPK_SELECT 1<<JPB_SELECT
.DEFINE JPK_START  1<<JPB_START 

.BANK 0 SLOT SLOT_ROM
.ORG $0000
jp Reset

.ORG $0038
  di             ; F3
  xor A          ; AF
  seth IER       ; E0 FF
  seth IFR       ; E0 0F
  stop           ; 10

.ORG $0040
  push AF
  push BC
  push DE
  push HL
  xor A
  jp VBlankHandler

.ORG $0100
  jp Reset
  nop

; $0104-$0133 NINTENDO logo
.DB $CE, $ED, $66, $66, $CC, $0D, $00, $0B, $03, $73, $00, $83, $00, $0C, $00, $0D
.DB $00, $08, $11, $1F, $88, $89, $00, $0E, $DC, $CC, $6E, $E6, $DD, $DD, $D9, $99
.DB $BB, $BB, $67, $63, $6E, $0E, $EC, $CC, $DD, $DC, $99, $9F, $BB, $B9, $33, $3E

.DB "VAPPY COPYPASTA"     ; $0134-$0142 ROM Title
.DB $80                   ; $0143       Dual mode (DMG+CGB)
.DB "IX"                  ; $0144-$0145 New Licensee code
.DB $00                   ; $0146       SGB Flag ($00 DMG/CGB Mode; $03 SGB Mode)
.DB $00                   ; $0147       Cart type (No MBC)
.DB $00                   ; $0148       ROM Size ($00 32KB; $xx 32 << xx KB)
.DB $00                   ; $0149       RAM Size ($00 None; $01 2KB; $02 8KB; $03 32KB)
.DB $01                   ; $014A       Destination code
.DB $33                   ; $014B       Old licensee code
.DB $00                   ; $014C       ROM Version
.COMPUTEGBCOMPLEMENTCHECK ; $014D       Header checksum
.COMPUTEGBCHECKSUM

.ORG $0150
RST38:
  pop AF         ; F1
  ld B, B        ; xx
- halt           ; 76
  jr -           ; 18 xx
  ret

Reset:
  ; Detect GameBoy type (0 DMG; 1 CGB; 2 AGB)
  cp $11
  jp Z, @CGBA
  xor A
  jp @DoneDetect

@CGBA:
  ld A, SF_CGB
  cp B
  jp NZ, @DoneDetect

@IsGBA:
  ld A, SF_AGB

@DoneDetect:
  seth SYSTEM_FLAGS

  ; Clear WRAM
  xor A
  seth SVBK ; WRAM Bank 0
  ld HL, WRAM
- ldi (HL), A
  bit 5, H
  jp Z, -

  ; Clear HRAM
  ld HL, RNGVALUE+2
  ld B, $7C
- ldi (HL), A
  dec B
  jr NZ, -

  ; Relocate Stack Pointer
  ld SP, $CFFF

  ; Fade out Nintendo logo (DMG only)
  geth SYSTEM_FLAGS
  and A
  call Z, FadeLogo

  ; Wait for VBlank to disable LCD
- geth STAT
  and $03
  xor $01
  jp NZ, -

  ; (A = 0 at this point)
  seth IFR     ; Clear interrupt flags
  seth IER     ; Disable interrupts
  seth SNDCTRL ; Turn off audio
  seth LCDC    ; Turn off display

  ; Clear BG Map
  ld HL, BGMAP
- ldi (HL), A
  bit 5, H
  jp Z, -

  ; Clear OAM
  ld HL, OAM
  ld B, 40    ; OAMs
- ld A, $C0
  ldi (HL), A ; Y
  ldi (HL), A ; X
  ldi (HL), A ; Tile index
  ldi (HL), A ; Attributes
  dec B
  jp NZ, -

  ; Clear attribute table
  geth SYSTEM_FLAGS
  and $03
  jp Z, + ; ...if not a DMG

  seth VBK, $01 ; select BANK 1 of VRAM
  ld HL, $9800
  ld BC, $0400
  xor A
- ldi (HL), A
  dec C
  jp NZ, -
  dec B
  jp NZ, -
  seth VBK ; Reset VBank

+ ; Load debug font
  ld HL, VRAM+$0100
  ld DE, Font
  ld BC, $7008
- ld A, (DE)
  ldi (HL), A  ; write twice
  ldi (HL), A  ;   for 2bpp
  inc DE
  dec C
  jr NZ, -
  ld C, 8
  dec B
  jr NZ, -

  ; Copy OAM DMA routine to HRAM
  ld HL, OAMDMAh
  ld DE, $FFF0
  ld B, _sizeof_OAMDMAh
- ldi A, (HL)
  ld (DE), A
  inc DE
  dec B
  jr NZ, -

  call InitRandom
  jp Main

OAMDMA:
  ; Why this? While the GameBoy has DMA hardware specifically for the
  ; sprites table (OAM), it doesn't stop the CPU while it runs and to
  ; make things worse, the CPU gets locked out of all memory but HRAM
  ; in the process so we're only able to run code from there.

  ld BC, $2846       ; B=Cycles to wait; C=OAM DMA register
  geth SYSTEM_FLAGS  ; Get detected system type
  and 3              ; System type bits
  jr Z, +            ; Skip if DMG (KEY1 is not available)
  geth KEY1          ; Get speed switch
  bit 7, A           ; Check DoubleSpeed bit
  jr Z, +            ; Skip next line if clear
  rr B               ; Half the time delay for DoubleSpeed mode
+ ld A, D            ; Load WRAM page
  jp $FFF0           ; Go to HRAM copy of code below

OAMDMAh:
  .DB $E2 ; ldh ($FF00+C), A
- dec B
  jr NZ, -
  nop
  ret

; Uses:
;  HL   Pointer to JOYP
;  B    Temp value
;  C    Input bitmask
;  D    Previous state
ReadInput:
  geth JP_DOWN
  ld D, A     ; remember last state
  ld C, $0F   ; button inputs bitmask
  ld HL, JOYP ; JP register address

  ld (HL), $E0 ; select DPAD
  ld A, (HL)   ; read state
  ld (HL), $F0 ; select NONE
  and C        ; cut off selector bits
  xor C        ; invert button states
  ld B, A      ; remember

  ld (HL), $D0 ; select Buttons
  ld A, (HL)   ; read state
  ld (HL), $F0 ; select NONE
  and C        ; cut off selector bits
  xor C        ; invert button states
  swap A       ; swap buttons to high 4 bits
  or B         ; combine
  seth JP_DOWN ; save reading

  ; do 'state change'
  ld B, A ; keep
  ld A, D
  xor B
  and B
  seth JP_PRESS ; save result

  ret

FadeLogo:
  ld B, 15  ; Frames to wait before fading out (~1/4 second)
  ld C, $54 ; Value to subtract from palette
  ld D, $04 ; Frames to wait between fades
  ld HL, IFR

  seth IER, $01 ; Enable VBlank interrupts
  geth BGP ; Read current BG Palette

  ; Wait for 'B' VBlanks
- ld (HL), $00 ; clear interrupt flags
  halt
  dec B
  jp NZ, -

  ; Subtract to BG palette
  sub C
  seth BGP
  ld B, D
  and A
  jp NZ, -

  ; Wait for another 'B' VBlanks
- ld (HL), $00 ; clear interrupt flags
  halt
  dec B
  jp NZ, -

  ret

RNGSEED:
  .DBRND 2, 0, 255

InitRandom:
  ld HL, RNGVALUE
  ld A, (RNGSEED)
  xor (HL)
  ldi (HL), A

  ld A, (RNGSEED+1)
  xor (HL)
  ld (HL), A
  ret

; RNG routine based from:
;   https://github.com/Zeda/Z80-Optimized-Routines/blob/master/math/rng/rng8_very_very_fast.z80
; - Native Z80 counter register (R) replaced with GameBoy's own counter (TCNT)
GetRandom:
  push HL
  ld A, (RNGVALUE)
  ld L, A
  ld A, (RNGVALUE+1)
  ld H, A
  add HL, HL

  sbc A
  and $2D
  xor L
  ld L, A

  geth TDIV
  add H

  ld (RNGVALUE+1), A
  seth $FD

  ld A, L
  ld (RNGVALUE), A

  geth $FD
  pop HL
  ret

VBlankHandler:
  seth IFR             ; Clear interrupt flags

  geth SYSTEM_FLAGS
  bit SF_VBLANK, A     ; Check VBlank flag
  jr NZ, @notReady     ;   return early if not ready for it
  set SF_VBLANK, A     ; Set VBlank flag (prevent reentrance)
  seth SYSTEM_FLAGS    ; Store flag

  call VBlank

  ; Clear VBlank flag
  geth SYSTEM_FLAGS
  res SF_VBLANK, A
  seth SYSTEM_FLAGS

@notReady
  pop HL
  pop DE
  pop BC
  pop AF
  reti

.SECTION "TILES" SUPERFREE

Font:
  .INCBIN "font.bin" READ $0380

.ENDS

.INCLUDE "main.asm"
