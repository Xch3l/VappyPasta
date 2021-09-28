; [DMG]  Featrue available on/affects standard GameBoy only
; [CGB]  Featrue available on/affects GameBoy Color only

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Joypad
.DEFINE JOYP     $FF00
;  xxBD1234
;  xx         C0  Unused; set to 11
;    B        20  0 = Select button keys
;     D       10  0 = Select DPAD
;      1234   0F  B = 1     D = 1    (read only; active low)
;      1      08  Start     Down
;       2     04  Select    Up
;        3    02  B         Left
;         4   01  A         Right

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Serial port
.DEFINE SP_DATA  $FF01 ; Byte to transmit / received
.DEFINE SP_CTRL  $FF02 ; Transfer control
;  T.....SC
;  T         80  Start transfer (=1)
;        S   02  [GBC] Speed (0 = Normal; 1 = Fast)
;         C  01  Clock source (system role)
;                  0 = External (slave)
;                  1 = Internal (master)

; Serial port flags
.DEFINE SP_TRANSFER 7
.DEFINE SP_FAST     1
.DEFINE SP_MASTER   0

; Serial port byte masks
.DEFINE SPB_TRANSFER 1<<SP_TRANSFER
.DEFINE SPB_FAST     1<<SP_FAST
.DEFINE SPB_MASTER   1<<SP_MASTER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Timer
.DEFINE TDIV    $FF04 ; Divider
.DEFINE TCNT    $FF05 ; Counter
.DEFINE TRES    $FF06 ; Reload value
.DEFINE TCTL    $FF07 ; Control
;  .....SCC
;       S    Start timer
;        CC  Clock source
;              0 = 4096Hz
;              1 = 262144Hz
;              2 = 65536Hz
;              3 = 16384Hz

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Audio
; *SO1 = Right channel
; *SO2 = Left channel
; *ExtAud = Vin input from cartridge

.DEFINE MSTRVOL  $FF24 ; Channel volume / External Audio enable
;  RVVVLvvv
;  R         Output ExtAud to SO2
;   VVV      SO2 output volume (0-7)
;      L     Output ExtAud to SO1
;       vvv  SO1 output volume (0-7)

.DEFINE SNDOUT   $FF25 ; Sound output selector
;  Bit 7 - Output Tone1 to SO2
;  Bit 6 - Output Tone2 to SO2
;  Bit 5 - Output Wave to SO2
;  Bit 4 - Output Noise to SO2
;  Bit 3 - Output Tone1 to SO1
;  Bit 2 - Output Tone2 to SO1
;  Bit 1 - Output Wave to SO1
;  Bit 0 - Output Noise to SO1

.DEFINE SNDCTRL  $FF26 ; Sound control
;  E...4321
;  E         Sound circuits enabled
;      4321  Sound channel active (read only)
;      4     Tone1
;       3    Tone2
;        2   Wave
;         1  Noise

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display
.DEFINE LCDC     $FF40 ; LCD Control
;  7:80  LCD enable
;  6:40  Window tilemap base (0=9800-9BFF; 1=9C00-9FFF)
;  5:20  Window enable
;  4:10  BG/WIN tileset base (0=8800-97FF; 1=8000-8FFF)
;  3:08  BG tilemap base     (0=9800-9BFF; 1=9C00-9FFF)
;  2:04  OBJ size            (0=8x8; 1=8x16)
;  1:02  OBJ enable
;  0:01  BG enable

; LCDC Flags
.DEFINE LCDC_LCDEN   7
.DEFINE LCDC_WINHIGH 6
.DEFINE LCDC_WINEN   5
.DEFINE LCDC_CHRLOW  4
.DEFINE LCDC_BGHIGH  3
.DEFINE LCDC_TALLOBJ 2
.DEFINE LCDC_OBJEN   1
.DEFINE LCDC_BGEN    0

; LCDC byte masks
.DEFINE LCDCB_LCDEN   1<<LCDC_LCDEN
.DEFINE LCDCB_WINHIGH 1<<LCDC_WINHIGH
.DEFINE LCDCB_WINEN   1<<LCDC_WINEN
.DEFINE LCDCB_CHRLOW  1<<LCDC_CHRLOW
.DEFINE LCDCB_BGHIGH  1<<LCDC_BGHIGH
.DEFINE LCDCB_TALLOBJ 1<<LCDC_TALLOBJ
.DEFINE LCDCB_OBJEN   1<<LCDC_OBJEN
.DEFINE LCDCB_BGEN    1<<LCDC_BGEN

;
.DEFINE STAT     $FF41 ; LCD Status
;   6:40  LY=LYC interrupt enable
;   5:20  OAM (Mode2) interrupt enable
;   4:10  VBlank (Mode1) interrupt enable
;   3:08  HBlank (Mode0) interrupt enable
;   2:04  LY=LYC
; 1-0:03  LCD Controller mode

; STAT flags
.DEFINE STAT_LYCINT    6
.DEFINE STAT_OAMINT    5
.DEFINE STAT_VBLANKINT 4
.DEFINE STAT_HBLANKINT 3
.DEFINE STAT_LYC       2

.DEFINE SCY      $FF42 ; BG Scroll Y
.DEFINE SCX      $FF43 ; BG Scroll X
.DEFINE LY       $FF44 ; LCDC V line
.DEFINE LYC      $FF45 ; LCDC V compare
.DEFINE ODMA     $FF46 ; DMA OAM Transfer and start address
.DEFINE BGP      $FF47 ; [DMG] BG Palette data
.DEFINE OBP0     $FF48 ; [DMG] Object palette data 0
.DEFINE OBP1     $FF49 ; [DMG] Object palette data 1
.DEFINE WY       $FF4A ; Window Y position
.DEFINE WX       $FF4B ; Window X position
.DEFINE KEY1     $FF4D ; [CGB] Speed Switch
.DEFINE VBK      $FF4F ; [CGB] VRAM bank
.DEFINE DMAADH   $FF51 ; [CGB] DMA Source address Hi
.DEFINE DMAADL   $FF52 ; [CGB] DMA Source address Lo
.DEFINE DMASADH  $FF53 ; [CGB] DMA Dest address Hi
.DEFINE DMASADL  $FF54 ; [CGB] DMA Dest address Lo
.DEFINE DMACTL   $FF55 ; [CGB] DMA Length/Mode/Start
.DEFINE IRPORT   $FF56 ; [CGB] Infrared Comms Port
.DEFINE BGPI     $FF68 ; [CGB] BG palette index
.DEFINE BGPD     $FF69 ; [CGB] BG palette data
.DEFINE OBPI     $FF6A ; [CGB] Sprite palette index
.DEFINE OBPD     $FF6B ; [CGB] Sprite palette data
.DEFINE SVBK     $FF70 ; [CGB] WRAM Bank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupts
;  ...JSTLV
;     J      Joypad
;      S     Serial
;       T    Timer
;        L   LCD Event
;         V  VBlank

.DEFINE IFR      $FF0F ; Flags: A bit set means an interrupt occured
.DEFINE IER      $FFFF ; Enable: A bit set allows the interrupt to happen

; Interrupt flags
.DEFINE INTF_VBLANK 0
.DEFINE INTF_LCD    1
.DEFINE INTF_TIMER  2
.DEFINE INTF_SERIAL 3
.DEFINE INTF_JOYPAD 4

; Interrupt byte masks
.DEFINE INTB_VBLANK 1<<INTF_VBLANK
.DEFINE INTB_LCD    1<<INTF_LCD
.DEFINE INTB_TIMER  1<<INTF_TIMER
.DEFINE INTB_SERIAL 1<<INTF_SERIAL
.DEFINE INTB_JOYPAD 1<<INTF_JOYPAD