		EXPORT	regs_vga, regs_tv50, regs_tv60

		DATA

;vga, 640*480 16 colors
;Vsetmode(-1) = $003A (%0000000000111010)
regs_vga:
		dc.b	'FVD2'	; magic word
		dc.b	$96	; $FFFF8006 monitor type
		dc.b	$02	; $FFFF820A sync mode
		dc.w	$0000	; $FFFF820E offset to next line
		dc.w	$00A0	; $FFFF8210 linewidth in words
		dc.w	$0000	; $FFFF8266 bitplanes and sync
		dc.w	$00C6	; $FFFF8282 horizontal hold timer
		dc.w	$008D	; $FFFF8284 horizontal border begin
		dc.w	$0015	; $FFFF8286 horizontal border end
		dc.w	$02A3	; $FFFF8288 horizontal display begin
		dc.w	$007C	; $FFFF828A horizontal display end
		dc.w	$0096	; $FFFF828C HSS
		dc.w	$0000	; $FFFF828E HFS
		dc.w	$0000	; $FFFF8290 HEE
		dc.w	$0419	; $FFFF82A2 vertical frequency timer
		dc.w	$03FF	; $FFFF82A4 vertical border begin
		dc.w	$003F	; $FFFF82A6 vertical border end (half lines)
		dc.w	$003F	; $FFFF82A8 vertical display begin
		dc.w	$03FF	; $FFFF82AA vertical display end
		dc.w	$0415	; $FFFF82AC VSS
		dc.w	$0008	; $FFFF82C2 video control
		dc.w	$0186	; $FFFF82C0 video clock
		dc.b	$00	; $FFFF8260 shifter resolution
		dc.b	$02	; $FFFF820A sync mode

;tv pal, 640*480 (changed from 640*400) 16 colors
;Vsetmode(-1) = $012A (%0000000100101010)
regs_tv50:
		dc.b	'FVD2'	; magic word
		dc.b	$96	; $FFFF8006 monitor type
		dc.b	$02	; $FFFF820A sync mode
		dc.w	$0000	; $FFFF820E offset to next line
		dc.w	$00A0	; $FFFF8210 linewidth in words
		dc.w	$0000	; $FFFF8266 bitplanes and sync
		dc.w	$01FE	; $FFFF8282 horizontal hold timer
		dc.w	$0199	; $FFFF8284 horizontal border begin
		dc.w	$0050	; $FFFF8286 horizontal border end
		dc.w	$004D	; $FFFF8288 horizontal display begin
		dc.w	$00FE	; $FFFF828A horizontal display end
		dc.w	$01B2	; $FFFF828C HSS
		dc.w	$0000	; $FFFF828E HFS
		dc.w	$0000	; $FFFF8290 HEE
		dc.w	$0270	; $FFFF82A2 vertical frequency timer
		dc.w	$0265	; $FFFF82A4 vertical border begin
		dc.w	$002F	; $FFFF82A6 vertical border end (half lines)
		dc.w	$56   ;$007E	; $FFFF82A8 vertical display begin
		dc.w	$236  ;$020E	; $FFFF82AA vertical display end
		dc.w	$026B	; $FFFF82AC VSS
		dc.w	$0006	; $FFFF82C2 video control
		dc.w	$0181	; $FFFF82C0 video clock
		dc.b	$00	; $FFFF8260 shifter resolution
		dc.b	$02	; $FFFF820A sync mode

;tv ntsc, 640*480 (changed from 640*400) 16 colors
;Vsetmode(-1) = $010A (%0000000100001010)
regs_tv60:
		dc.b	'FVD2'	; magic word
		dc.b	$96	; $FFFF8006 monitor type
		dc.b	$00	; $FFFF820A sync mode
		dc.w	$0000	; $FFFF820E offset to next line
		dc.w	$00A0	; $FFFF8210 linewidth in words
		dc.w	$0000	; $FFFF8266 bitplanes and sync
		dc.w	$01FF	; $FFFF8282 horizontal hold timer
		dc.w	$0197	; $FFFF8284 horizontal border begin
		dc.w	$0050	; $FFFF8286 horizontal border end
		dc.w	$004D	; $FFFF8288 horizontal display begin
		dc.w	$00FD	; $FFFF828A horizontal display end
		dc.w	$01B4	; $FFFF828C HSS
		dc.w	$0000	; $FFFF828E HFS
		dc.w	$0000	; $FFFF8290 HEE
		dc.w	$020C	; $FFFF82A2 vertical frequency timer
		dc.w	$0201	; $FFFF82A4 vertical border begin
		dc.w	$0016	; $FFFF82A6 vertical border end (half lines)
		dc.w	$24   ;$004C	; $FFFF82A8 vertical display begin
		dc.w	$204  ;$01DC	; $FFFF82AA vertical display end
		dc.w	$0207	; $FFFF82AC VSS
		dc.w	$0006	; $FFFF82C2 video control
		dc.w	$0181	; $FFFF82C0 video clock
		dc.b	$00	; $FFFF8260 shifter resolution
		dc.b	$00	; $FFFF820A sync mode

