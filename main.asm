.RAMSECTION "MAINRAM" SLOT SLOT_WRAM
  ScrollX    db
  ShiftMode  db
  PalIndex   db
  ShiftDelay db
.ENDS

.SECTION "VBLANK"

VBlank:
  ld D, >OAMTABLE
  jp OAMDMA
  ;ret ; not needed here

.ENDS

.SECTION "MAIN"

WaitVBlank:
  halt
  geth STAT
  and 3
  xor 1
  jr NZ, WaitVBlank
  ret

Main:
  ; Load Vappy's tileset
  ld HL, VapTiles
  ld DE, $8800
  ld BC, $0010
- ldi A, (HL)
  ld (DE), A
  inc DE
  dec C
  jr NZ, -
  ld C, 16
  dec B
  jr NZ, -

  ; Load Vappy's tilemaps
  ld HL, VapTilemap
  ld DE, $9800
  ld BC, $1320
- ldi A, (HL)
  ld (DE), A
  inc DE
  dec C
  jr NZ, -
  ld C, 32
  dec B
  jr NZ, -

  ld DE, $9C00
  ld BC, $1220
- ldi A, (HL)
  ld (DE), A
  inc DE
  dec C
  jr NZ, -
  ld C, 32
  dec B
  jr NZ, -

  ; Load Vappy's palette
  geth SYSTEM_FLAGS
  and 3
  call NZ, LoadPalettes

  ld A, $04
  ld (ShiftDelay), A

  seth STAT, $40 ; Enable LY=LYC interrupt
  seth SCY, 4    ; BG Y offset
  seth SCX, -28  ; BG X offset
  seth WY, 0     ; Window Y offset
  seth WX, 7     ; Window X offset
  seth LYC, 134  ; Line split at 134px (for scrolling text)
  seth BGP, $E4  ; Set DMG palettes (useless on GBC but w/e)
  seth OBP0      ;   Light, Medium, Dark, Black
  seth LCDC, $83 ; Enable BG+OAM display
  seth IER, $03  ; Enable VBlank+LCD interrupts
  ei

  ld HL, VapPasta
  ld DE, $9A54

Loop:
  call WaitVBlank

  seth SCY, $04
  seth SCX, $E4
  seth LYC, 132
  seth LCDC, $83

  push HL
  push DE
  call ReadInput
  bit JPB_SELECT, A
  jr Z, +
  call ShowStats
  pop DE
  pop HL
  jp Loop

+ bit JPB_A, A
  jr Z, +
  ld A, (ShiftMode)
  xor 1
  ld (ShiftMode), A
+ call ShiftPalette
  pop DE
  pop HL

  ld A, (ScrollX)
  and 7
  jr NZ, @ScrollLine

  ldi A, (HL)
  bit 7, A ; Cue to change Vappy's colors
  jr Z, +

  ld B, A
  ld A, (ShiftMode)
  xor 1
  ld (ShiftMode), A
  ld A, B
  inc HL

+ and A
  jr NZ, +
  ld HL, VapPasta
  ld A, $20
+ ld (DE), A
  ld A, E
  inc A
  and 31
  or $40
  ld E, A

@ScrollLine:
  ld A, (ScrollX)
  inc A
  ld (ScrollX), A
  jp Loop

ShiftPalette:
  push AF
  push HL

  ld HL, ShiftDelay
  dec (HL)
  jp NZ, @retn

  ld A, $04
  ld (HL), A

  ld HL, PalIndex
  ld A, (HL)
  ld B, A

  ld A, (ShiftMode)
  bit 0, A ; check shifting mode
  ld A, B
  jr Z, + ; Decrease

  ; Increase
  cp 5
  jr Z, @applyColor ; don't increase
  inc (HL)
  jp @applyColor

+ and A
  jp Z, @applyColor ; don't decrease
  dec (HL)

@applyColor:
  ; Apply color according to system
  geth SYSTEM_FLAGS
  and 3
  jr Z, @dmgpal

@cgbpal:
  ld HL, VapCGBPalette
  ld A, B
  sla A
  sla A
  add L
  ld L, A
  jr NC, +
  inc H
+ seth BGPI, $82
  ld B, 4
- ldi A, (HL)
  seth BGPD
  dec B
  jr NZ, -

@retn
  pop HL
  pop AF
  ret

@dmgpal:
  ld HL, VapDMGPalette
  ld A, B
  add L
  ld L, A
  ld A, (HL)
  seth BGP
  jp @retn

LoadPalettes:
  ld HL, VapPalette
  seth BGPI, $80
  seth OBPI

  ; BG palettes
  ld B, 4
- ldi A, (HL)
  seth BGPD
  ldi A, (HL)
  seth BGPD
  dec B
  jr NZ, -

  ; OAM palettes
  ld HL, VapPalette
  ld B, 8
- ldi A, (HL)
  seth OBPD
  ldi A, (HL)
  seth OBPD
  dec B
  jr NZ, -

LoadVapFinSprites:
  ld HL, VapSprites
  ld DE, OAMTABLE
  ld B, 32
- ldi A, (HL) ; Y
  sub 4
  ld (DE), A
  inc DE
  ldi A, (HL) ; X
  add 28
  ld (DE), A
  inc DE
  ldi A, (HL) ; Tile
  ld (DE), A
  inc DE
  ld A, $01 ; Attributes
  ld (DE), A
  inc DE
  dec B
  jr NZ, -
  ret

ShowStats:
  push AF
  push BC
  push DE
  push HL

  call WaitVBlank

  ; Fill in random mood
  call GetRandom
  ld H, >VapMoods
  and 7
  ld C, A
  sla A
  sla A
  sla A
  add <VapMoods
  ld L, A
  jr NC, +
  inc H
+ ld DE, $9E0B
  ld B, 8
  call PutLine

  ld HL, VapStatus
  bit 2, C
  jr Z, +
  call GetRandom
  and 3
  sla A
  sla A
  add L
  ld L, A
  jr NC, +
  inc H
+ ld DE, $9CD0
  ld B, 3
  call PutLine

  seth LCDC, $F7 ; Set display mode
  seth IER, $01  ; VBlank ints only

  ; Load smol Vappy sprites
  ld HL, VapSmolSprite
  ld DE, OAMTABLE
  ld B, 8
- ldi A, (HL) ; Y
  ld (DE), A
  inc DE
  ldi A, (HL) ; X
  ld (DE), A
  inc DE
  ldi A, (HL) ; Index
  ld (DE), A
  inc DE
  xor A ; Attributes
  ld (DE), A
  inc DE
  dec B
  jr NZ, -

  ; Clear all other sprites
  push DE
  pop HL
  xor A
  ld B, 32
- ldi (HL), A ; Y
  ldi (HL), A ; X
  ldi (HL), A ; T
  ldi (HL), A ; A
  dec B
  jr NZ, -

StatsLoop:
  call WaitVBlank
  call ReadInput
  bit JPB_B, A
  jr NZ, ExitStats
  jp StatsLoop

ExitStats:
  ; Move OAMs away
  ld HL, OAMTABLE
  xor A
  ld B, 32
- ldi (HL), A ; Y
  ldi (HL), A ; X
  ldi (HL), A ; T
  ldi (HL), A ; A
  dec B
  jr NZ, -

  ; Set Vappy's fin sprites (if not running in a DMG)
  geth SYSTEM_FLAGS
  and 3
  call NZ, LoadVapFinSprites

  seth IER, $03 ; Enable VBlank+LCD interrupts
  pop HL
  pop DE
  pop BC
  pop AF
  ret

PutLine:
  ldi A, (HL)
  ld (DE), A
  dec B
  ret Z
  inc DE
  jr PutLine

.ENDS

.ORG $0048 ; LCD interrupt vector
  seth $FE          ; save A
  ld A, (ScrollX)   ; Get current scroll value
  seth SCX          ; Send it to BG X offset
  seth SCY, $0A     ; Shift vertically
  seth LCDC, $93    ; Set tileset base address
  geth $FE          ; restore A
  reti

.SECTION "VAPDATA" SUPERFREE

VapTilemap:
  .INCBIN "vap-tilemap.bin"

VapTiles:
  .INCBIN "vap-tiles.bin"

; OAM attributes ommited because they're all the same,
; so they're set on the routine that places these OAMs.
VapSprites:
  .DB $45, $35, $81 ; right eye
  .DB $41, $49, $82 ; left eye
  .DB $4E, $41, $83 ; tongue
  .DB $20, $60, $84 ; fins
  .DB $20, $68, $85
  .DB $28, $50, $86
  .DB $28, $58, $87
  .DB $28, $60, $88
  .DB $28, $68, $89
  .DB $30, $50, $8A
  .DB $30, $58, $8B
  .DB $30, $60, $8C
  .DB $38, $08, $8D
  .DB $38, $10, $8E
  .DB $38, $18, $8F
  .DB $38, $20, $90
  .DB $38, $28, $91
  .DB $38, $50, $92
  .DB $38, $58, $93
  .DB $38, $60, $94
  .DB $40, $10, $95
  .DB $40, $18, $96
  .DB $40, $20, $97
  .DB $40, $28, $98
  .DB $40, $50, $99
  .DB $40, $58, $9A
  .DB $40, $60, $9B
  .DB $48, $18, $9C
  .DB $48, $20, $9D
  .DB $48, $28, $9E
  .DB $48, $30, $9F
  .DB $50, $20, $A0

VapSmolSprite:
  .DB $28, $28, $A2
  .DB $28, $30, $A4
  .DB $28, $38, $A6
  .DB $38, $18, $A8
  .DB $38, $20, $AA
  .DB $38, $28, $AC
  .DB $38, $30, $AE
  .DB $38, $38, $B0

VapPalette:
  .DW $7FFF, $732F, $45A6, $0000
  .DW $7FFF, $639D, $7B9B, $3D91

VapCGBPalette:
  .DW $732F, $45A6
  .DW $7B71, $4DE8
  .DW $7FB3, $562A
  .DW $7FF5, $5E6C
  .DW $7FF7, $66AE
  .DW $7FF9, $6EF0

VapDMGPalette:
  .DB $E4, $E4, $D4, $D0, $C0, $C0

VapPasta:
  .DB "Hey guys, did you know that in terms of male human and female Pokemon "
  .DB "breeding, Vaporeon is the most compatible Pokemon for humans? Not only "
  .DB "are they in the field egg group, which is mostly comprised of mammals, "
  .DB "Vaporeon are an average of 3\"03' tall and 63.9 pounds, this means "
  .DB "they're large enough to be able to handle human dicks, and with their "
  .DB "impressive Base Stats for HP and access to Acid Armor, you can be "
  .DB "rough with one. Due to their mostly water based biology, there's no "
  .DB "doubt in my mind that an aroused Vaporeon would be incredibly wet, so "
  .DB "wet that you could easily have sex with one for hours without getting "
  .DB "sore. They can also learn the moves Attract, Baby-Doll Eyes, Captivate, "
  .DB "Charm, and Tail Whip, along with not having fur to hide nipples, so "
  .DB "it'd be incredibly easy for one to get you in the mood. With their "
  .DB "abilities Water Absorb and Hydration, they can easily recover from "
  .DB "fatigue with enough water. No other Pokemon comes close to this level of"
  .DB " compatibility. Also, fun fact, if you pull out enough, you can make "
  .DB "your Vaporeon ",$80,"turn white. Vaporeon",$80," is literally built for"
  .DB " human dick. Ungodly defense stat+high HP pool+Acid Armor means it can"
  .DB " take cock all day, all shapes and sizes and still come for more."
  .DB "                    ",0 ; one screenful of padding between loops

VapMoods:
  .DB "   Happy"
  .DB "   Tired"
  .DB "   Bored"
  .DB "  Sleepy"
  .DB " Playful"
  .DB "  Hungry"
  .DB "   Horny"
  .DB "     Wet"

VapStatus:
  .DB "OK  "
  .DB $1D, $1E, $20, $20 ; hand pointing right + OK hand
  .DB $7F, $1F, $1C, $20 ; tongue + eggplant + drips
  .DB $20, $1B, $20, $20 ; heart

.ENDS

.ORG $0080
  .DB "Nothing to see here. Look at $3F00 instead.                     "

.ORG $3F00
  .DB "The vaporeon featured here is "
  .DB "Vappy. Please take good care o"
  .DB "f her. She is a really nice gi"
  .DB "rl and an even better companio"
  .DB "n! I guarantee she will take G"
  .DB "OOD care of you as well!"

.ORG $3FF0 ; Last build date
  .DB "210928-0600A MST"
