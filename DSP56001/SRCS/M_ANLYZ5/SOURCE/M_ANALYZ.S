;                   Music Analyzer
;               by Roel van de Kraats
;                       1995
;                   Main Program

;tabsize=8


len_of_scr	equ	153600
len_scopebuf	equ	128*256/8*4
len_vubuf	equ	44*80/8*4
len_iconsbuf	equ	32/8*4*32*22
len_helpdiag	equ	256/8*4*350
len_hdiagsave	equ	(256+16)/8*4*(350+8)
len_lrbuf	equ	80*(80/8*4+2*8/8*4)
len_rotfalc	equ	48/16*8*25*16
b_line		equ	320
points		equ	1024
buflen		equ	(points+2)/3
x		equ	13000		;dsp x and y memory size
y		equ	2000
_frclock	equ	$466
_hz_200		equ	$4ba

test_on		equ	0	;<>0 : press ESC to show speed, press S to save screen as 'm_an_scr.img'
min_hz200	equ	8	;max. program speed = 200/min_hz200 Hz.


		text

start:		lea.l	start-256,a1		; Start of Basepage
		move.l	12(a1),d1		; Size of Text
		add.l	20(a1),d1		; Size of Data
		add.l	28(a1),d1		; Size of BSS
		add.l	#256,d1			; Size of Basepage

		move.l	d1,-(sp)
		move.l	a1,-(sp)		; Startaddress
		clr	-(sp)			; dummy
		move	#74,-(sp)		; Mshrink
		trap	#1			; Gemdos

		add.l	a1,d1			; new stack
		and.b	#$fc,d1
		move.l	d1,sp			; Stack in BSS

clear_keys:			;clear input buffer (to prevent accidentally entering a command right at program start)
		; Cconis()
		move	#11,-(sp)
		trap	#1
		addq.l	#2, sp
		cmp.w	#-1,d0
		bne	no_more_keys

		; Cconin()
		move	#1,-(sp)
		trap	#1
		addq.l	#2,sp
		bra	clear_keys
no_more_keys:

		; Kbshift(-1)
		move.w	#-1,-(sp)
		move.w	#11,-(sp)
		trap	#13
		addq.l	#4,sp

		lsr.w	#4,d0
		and.w	#1,d0
		move.w	d0,old_capslock		;save for restore later

		bset	#4,d0			;capslock on

		; Kbshift()
		move.w	d0,-(sp)
		move.w	#11,-(sp)
		trap	#13
		addq.l	#4,sp

		bsr	appl_init		;init gem (for alerts)

		pea	check_cookies
		move.w	#$26,-(sp)
		trap	#14			;Supexec()
		addq.l	#6,sp

		tst.w	d0
		beq	wrong_machine		;not a falcon or compatible!

		move.w	#$59,-(sp)		;VgetMonitor()
		trap	#14
		addq.l	#2,sp
		move.w	d0,monitor		;for later use
		cmp.w	#0,d0
		beq	wrong_scr		;monochrome monitor

		move.l	#len_of_scr,-(sp)
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,scr1
		beq	outofmem
		move.l	d0,scr

		move.l	#len_of_scr,-(sp)
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,scr2
		beq	outofmem

		move.l	#len_scopebuf,-(sp)
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,scopebuf
		beq	outofmem

		move.l	#len_vubuf,-(sp)
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,vubuf
		beq	outofmem

		move.l	#len_iconsbuf,-(sp)
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,icons
		beq	outofmem

		move.l	#len_lrbuf,-(sp)
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,lrbuf
		beq	outofmem

		move.l	#len_helpdiag,-(sp)
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,helpdiag
		beq	outofmem

		move.l	#len_hdiagsave,-(sp)	;for help dialog save background
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,hdiagsave
		beq	outofmem

		move.l	#len_rotfalc,-(sp)
		move.w	#72,-(sp)
		trap	#1			;Malloc
		addq.l	#6,sp
		move.l	d0,rotfalc
		beq	outofmem

		bsr	install_sound

		bsr	decode_imgs		;XIMG -> raw data


		move.w	#256,d0
		bsr	graf_mouse		;(vdi) mouse off

		;Super()
		move.l	#0,-(sp)
		move.w	#$20,-(sp)
		trap	#1
		addq.l	#6,sp
		move.l	d0,old_superstack


		bsr	key_click_off		;else problem with SAM

		;0-1000 -> 0-255
		lea	mainscrdat+22,a0	;start of palette in img-file
		lea	palet,a1
		move.w	#15,d0
loop_sp:	clr.b	(a1)+
		clr.l	d1
		move.w	(a0)+,d1
		mulu.w	#255,d1
		divu	#1000,d1
		move.b	d1,(a1)+
		clr.l	d1
		move.w	(a0)+,d1
		mulu.w	#255,d1
		divu	#1000,d1
		move.b	d1,(a1)+
		clr.l	d1
		move.w	(a0)+,d1
		mulu.w	#255,d1
		divu	#1000,d1
		move.b	d1,(a1)+
		dbra	d0,loop_sp


		;clear screen
		move.l	#len_of_scr/4,d0
		move.l	scr1,a1
loop_clrscr:	clr.l	(a1)+
		subq.l	#1,d0
		bne	loop_clrscr


		bsr	init_video

		;copy ms texts (scope range)
		move.l	scr2,a0
		adda.l	#b_line*388+(144/8*4),a0
		move.l	scr2,a1		
		adda.l	#b_line*388+(432/8*4),a1
		lea	mstext1,a2
		lea	mstext2,a3
		move.w	#11,d0
loop_cptxt:	move.l	(a0),(a2)+
		move.l	4(a0),(a2)+
		move.l	8(a0),(a2)+
		move.l	12(a0),(a2)+
		move.l	16(a0),(a2)+
		move.l	20(a0),(a2)+
		move.l	24(a0),(a2)+
		move.l	28(a0),(a2)+
		move.l	(a1),(a3)+
		move.l	4(a1),(a3)+
		move.l	8(a1),(a3)+
		move.l	12(a1),(a3)+
		move.l	16(a1),(a3)+
		move.l	20(a1),(a3)+
		move.l	24(a1),(a3)+
		move.l	28(a1),(a3)+
		add.l	#b_line,a0
		add.l	#b_line,a1
		dbra	d0,loop_cptxt

		clr.w	mstxtwhich		;31.2 ms standard

		;copy scope
		move.l	scr2,a0
		adda.l	#b_line*331+(48/8*4),a0
		move.l	scopebuf,a1
		move.w	#127,d0
loop_cpsc:	move.w	#31,d1
loop_cpsc2:	move.l	(a0)+,(a1)+
		dbra	d1,loop_cpsc2
		adda.w	#b_line-128,a0
		dbra	d0,loop_cpsc

		;copy vu
		move.l	scr2,a0
		adda.l	#b_line*45+(48/8*4),a0
		move.l	vubuf,a1
		move.w	#43,d0
loop_cpvu:	move.w	#9,d1
loop_cpvu2:	move.l	(a0)+,(a1)+
		dbra	d1,loop_cpvu2
		adda.l	#b_line-40,a0
		dbra	d0,loop_cpvu

		;copy left-right window
		move.l	scr2,a0
		adda.l	#b_line*44+(272/8*4),a0
		move.l	lrbuf,a1
		move.w	#79,d0
loop_cplr:	move.w	#11,d1
loop_cplr2:	move.l	(a0)+,(a1)+
		dbra	d1,loop_cplr2
		adda.l	#b_line-48,a0
		dbra	d0,loop_cplr


		;copy clipping-texts
		move.l	scr2,a0
		move.l	a0,a2
		adda.l	#b_line*124+(96/8*4),a0
		adda.l	#b_line*124+(512/8*4),a2
		lea	clipbuf_off,a1
		lea	clipbuf_on,a3
		move.w	#9-1,d0
loop_cpclip:	move.l	(a0),(a1)+
		move.l	(a2),(a3)+
		move.l	4(a0),(a1)+
		move.l	4(a2),(a3)+
		move.l	8(a0),(a1)+
		move.l	8(a2),(a3)+
		move.l	12(a0),(a1)+
		move.l	12(a2),(a3)+
		adda.l	#b_line,a0
		adda.l	#b_line,a2
		dbra	d0,loop_cpclip



		;copy screen
		move.l	#len_of_scr/4,d0
		move.l	scr2,a0
		move.l	scr1,a1
loop_cpyscr:	move.l	(a0)+,(a1)+
		subq.l	#1,d0
		bne	loop_cpyscr


		move.l	scr2,scr		;1st screen
		move.w	#11,d0
		move.w	#40,d1
		move.w	lgain,d2
		bsr	put_icon
		move.w	#27,d0
		move.w	#40,d1
		move.w	rgain,d2
		bsr	put_icon
		move.w	#17,d1
		sub.w	speaker,d1
		move.w	d1,d2
		move.w	#10,d0
		move.w	#86,d1
		bsr	put_icon

		move.l	scr1,scr
		move.w	#11,d0			;put icons on 2nd screen too
		move.w	#40,d1
		move.w	lgain,d2
		bsr	put_icon
		move.w	#27,d0
		move.w	#40,d1
		move.w	rgain,d2
		bsr	put_icon
		move.w	#17,d1
		sub.w	speaker,d1
		move.w	d1,d2
		move.w	#10,d0
		move.w	#86,d1
		bsr	put_icon

		move.w	#-1,icon1x		;no icons to put
		move.w	#-1,icon2x

		clr.w	leftvu
		clr.w	rightvu



		move.w	#14*2-1,d0
		lea	left_bars,a0
loop_clrbars:	clr.w	(a0)+
		dbra	d0,loop_clrbars

		cmp.w	#2,monitor
		bne	b_no_vga
		move.l	#$00003ffc,bar_patt1
		move.l	#$00000000,bar_patt1+4
		move.l	#$3ffc3ffc,bar_patt2
		move.l	#$3ffc0000,bar_patt2+4
		bra	b_vga
b_no_vga:
		move.l	#$3ffc3ffc,bar_patt1
		move.l	#$00000000,bar_patt1+4
		move.l	#$3ffc3ffc,bar_patt2
		move.l	#$00000000,bar_patt2+4
b_vga:

		move.l	$ffff9800+9*4,link_color	;color for link buttons
		clr.l	link_col		;no new color to set
		move.w	#1,old_link

		bsr	init_mouse		;own mouse routines

		movec	cacr,d0			;get CACR
		move.w	d0,save_cacr		;save
		move.w	#$3111,d0		;I- and D-Cache on + Burstmode
		movec	d0,cacr			;set cache

		clr.w	freeze			;freeze off
		clr.w	helpdiag_on		;help dialog not shown
		clr.w	restdiag_count		;no restore help dialog background (2: both screens, 1: one screen to go)
		clr.l	old_hz200		;for speed control
		move.w	#0,leftrightwhich	;0=dots, 1=lines

	IF	test_on!=0
		bsr	init_test
	ENDIF


;------------------------------------------------------------------------------

main_loop:

	IF	test_on!=0
		addq.l	#1,testcnt
	ENDIF

		move.w	#-1,new_scr		;new screen address has to be set in vertical blank interrupt

		move.l	#$123456,sendbuf	;magic number

		tst.w	freeze
		bne	freeze1			;don't use data from dsp

		move.l	#2+buflen*2,-(sp)	;vu data + scope left+right
		pea	buf
		move.l	#1,-(sp)
		pea	sendbuf+1		;send lower 3 bytes of long
		move.w	#97,-(sp)		;Dsp_BlkHandShake()
		trap	#14
		lea	18(sp),sp

		bra	no_freeze1
freeze1:

		move.l	#2+buflen*2,-(sp)	;vu data + scope left+right
		pea	dummybuf
		move.l	#1,-(sp)
		pea	sendbuf+1		;send lower 3 bytes of long
		move.w	#97,-(sp)		;Dsp_BlkHandShake()
		trap	#14
		lea	18(sp),sp
no_freeze1:


		;calculate vu's already (during vbl)
		lea	log,a0
		move.w	buf,d0
		lsr.w	#5,d0
		move.b	(a0,d0),d1
		lsl.w	#8,d1

		move.w	leftvu,d2

		tst.w	freeze
		bne	freeze5

		cmp.w	d1,d2
		bgt	contlvu			;smaller than before
		sub.w	d2,d1
		asr.w	#1,d1			;slow it down a little to
		add.w	d1,d2			;make it look more real
		bra	contlvu2
contlvu:
		sub.w	#$500,d2		;constant speed backwards
		bpl	contlvu2
		clr.w	d2
contlvu2:	move.w	d2,leftvu
freeze5:
		;and right channel

		move.w	buf+3,d0
		lsr.w	#5,d0
		move.b	(a0,d0),d1
		lsl.w	#8,d1
		move.w	rightvu,d2

		tst.w	freeze
		bne	freeze6

		cmp.w	d1,d2
		bgt	contrvu
		sub.w	d2,d1
		asr.w	#1,d1
		add.w	d1,d2
		bra	contrvu2
contrvu:
		sub.w	#$500,d2
		bpl	contrvu2
		clr.w	d2
contrvu2:	move.w	d2,rightvu
freeze6:


		;calculate lr-coordinates already
		lea	leftbuf,a2
		lea	rightbuf,a3
		tst.w	leftrightwhich
		beq	dots3
		add.w	#points/2,a2
		add.w	#points/2,a3
		bra	no_dots3
dots3:		add.w	#points/3,a2
		add.w	#points/3,a3
no_dots3:
		lea	lr_coor,a6
		move.w	leftrightwhich,(a6)+
		moveq	#0,d7			;for loop
		clr.w	d0			;1st left point
		clr.w	d1			;1st right point
loop_lr:	move.b	(a2)+,d2		;left data
		ext.w	d2
		move.w	d2,d6
		asr.w	#2,d6
		sub.w	d6,d2			;a little smaller
		asr.w	#2,d6
		sub.w	d6,d2
		asl.w	#6,d2			;avoid rounding failures

		tst.w	leftrightwhich
		bne	no_dots1

		move.w	d2,d0
		move.b	(a3)+,d2		;right data
		ext.w	d2
		move.w	d2,d6
		asr.w	#2,d6
		sub.w	d6,d2			;a little smaller
		asr.w	#2,d6
		sub.w	d6,d2
		asl.w	#6,d2
		move.w	d2,d1

		bra	dots1
no_dots1:
		sub.w	d0,d2
		asr.w	#2,d2			;kind of a low-pass filter
		add.w	d2,d0
		move.b	(a3)+,d2		;right data
		ext.w	d2
		move.w	d2,d6
		asr.w	#2,d6
		sub.w	d6,d2			;a little smaller
		asr.w	#2,d6
		sub.w	d6,d2
		asl.w	#6,d2
		sub.w	d1,d2
		asr.w	#2,d2
		add.w	d2,d1

		move.w	d7,d2
		and.w	#1,d2			;not every time (too much and too slow)
		bne	no_draw_line

dots1:
		move.w	d0,d3
		move.w	d1,d4

		asr.w	#6,d3
		asr.w	#6,d4

		cmp.w	#39,d3			;inside window?
		blt	cont_lr1
		move.w	#39,d3			;limit
cont_lr1:
		cmp.w	#-40,d3
		bgt	cont_lr2
		move.w	#-40,d3
cont_lr2:
		cmp.w	#39,d4
		blt	cont_lr3
		move.w	#39,d4
cont_lr3:
		cmp.w	#-40,d4
		bgt	cont_lr4
		move.w	#-40,d4
cont_lr4:
		add.w	#320,d3			;center of window
		neg.w	d4
		add.w	#83,d4

		tst.w	leftrightwhich
		beq	dots2
		cmp.w	#40,d7			;skip first points (because of filter)
		ble	no_draw_line

		move.w	d3,(a6)+
		move.w	d4,(a6)+
no_draw_line:
		addq.w	#1,d7
		cmp.w	#points/2,d7
		blt	loop_lr
		bra	no_dots2
dots2:
		move.w	d3,(a6)+
		move.w	d4,(a6)+
		addq.w	#1,d7
		cmp.w	#points-points/3,d7
		blt	loop_lr
no_dots2:
		move.w	#-1,(a6)		;no more data


wait_vbl1:
		tst.w	new_scr
		bne	wait_vbl1


	IF	test_on=0
		bsr	wait_forhz200		;not too fast on faster computers
	ENDIF


		tst.w	restdiag_count
		beq	no_restorediag

		;restore help dialog background on this screen
		move.l	hdiagsave,a0
		move.l	scr,a1
		add.l	#65*b_line+b_line/2-(128/2+8)+8*4,a1
		move.w	#358-1,d0
loop_restdiag:
		movem.l	(a0)+,d1-d7/a2
		movem.l	d1-d7/a2,-(a1)
		adda.w	#8*4*2,a1

		movem.l	(a0)+,d1-d7/a2
		movem.l	d1-d7/a2,-(a1)
		adda.w	#8*4*2,a1

		movem.l	(a0)+,d1-d7/a2
		movem.l	d1-d7/a2,-(a1)
		adda.w	#8*4+10*4,a1

		movem.l	(a0)+,d1-d7/a2-a4
		movem.l	d1-d7/a2-a4,-(a1)
		adda.w	#10*4+8*4+b_line-(128+8),a1

		dbra	d0,loop_restdiag
		subq.w	#1,restdiag_count	;this screen done
no_restorediag:

		cmp.w	#-1,icon1x		;icon to put on this screen?
		beq	no_icon1
		move.w	icon1x,d0
		move.w	icon1y,d1
		move.w	icon1n,d2
		bsr	put_icon
		move.w	#-1,icon1x
no_icon1:
		cmp.w	#-1,icon2x		;icon to put on this screen?
		beq	no_icon2
		move.w	icon2x,d0
		move.w	icon2y,d1
		move.w	icon2n,d2
		bsr	put_icon
		move.w	#-1,icon2x
no_icon2:



		;clear vu background
		move.l	vubuf,a0
		move.l	scr,a1
		adda.l	#b_line*45+(48/8*4)+40,a1
		move.w	#43,d0
loop_clrvu:
		movem.l (a0)+,d1-d7/a2-a4
		movem.l d1-d7/a2-a4,-(a1)
		adda.w	#232+40,a1
		movem.l d1-d7/a2-a4,-(a1)
		adda.w	#b_line-232+40,a1
		dbra	d0,loop_clrvu

		;draw vu-meters
		move.w	#88,d0
		move.w	leftvu,d1
		lsr.w	#8,d1
		bsr	put_vu
		move.w	#552,d0
		move.w	rightvu,d1
		lsr.w	#8,d1
		bsr	put_vu


		;clear scope background
		move.l	scopebuf,a0
		move.l	scr,a1
		adda.l	#b_line*331+(48/8*4)+48,a1
		move.w	#127,d0
loop_clrsc:
		movem.l (a0)+,d1-d7/a2-a6
		movem.l d1-d7/a2-a6,-(a1)
		adda.w	#144+48,a1
		movem.l d1-d7/a2-a6,-(a1)
		movem.l (a0)+,d1-d7/a2-a6
		suba.w	#144-(48*2),a1
		movem.l d1-d7/a2-a6,-(a1)
		adda.w	#144+48,a1
		movem.l d1-d7/a2-a6,-(a1)
		movem.l (a0)+,d1-d7/a2
		suba.w	#144-(48+32),a1
		movem.l d1-d7/a2,-(a1)
		adda.w	#144+32,a1
		movem.l d1-d7/a2,-(a1)
		adda.w	#b_line+32-144-128+48,a1
		dbra	d0,loop_clrsc

		move.w	#1,bufstepsize
		tst.w	mstxtwhich		;which data to put
		bne	no_full_buf
		move.w	#4,bufstepsize
no_full_buf:

		move.w	#49,d0
		lea	leftbuf,a0
		bsr	put_scope

		move.w	#337,d0
		lea	rightbuf,a0
		bsr	put_scope


		;clear left-right window
		move.l	scr,a0
		adda.l	#b_line*44+(272/8*4)+48,a0
		move.l	lrbuf,a1
		move.w	#80/5-1,d0
loop_clrlr:
		REPT	5
		movem.l	(a1)+,d1-d7/a2-a6
		movem.l	d1-d7/a2-a6,-(a0)
		adda.l	#b_line+48,a0
		ENDM
		dbra	d0,loop_clrlr

		bsr	draw_leftright


		;clear spectrum analyzer bars
		moveq	#0,d1
		move.l	d1,d2
		move.l	d1,d3
		move.l	d1,d4
		move.l	d1,d5
		move.l	d1,d6
		move.l	d1,a2
		move.l	d1,a3
		move.l	d1,a4
		move.l	d1,a5
		move.w	#108,d0

		tst.w	helpdiag_on
		bne	clrspec_diag_off

		move.l	scr,a0
		adda.l	#b_line*164+4*8+112,a0
		move.l	a0,a1
		adda.w	#18*8,a1
		move.w	#b_line+112,d7
loop_clrsp:	movem.l d1-d6/a2-a4,-(a0)
		movem.l d1-d6/a2-a4,-(a0)
		movem.l d1-d6/a2-a5,-(a0)
		movem.l d1-d6/a2-a4,-(a1)
		movem.l d1-d6/a2-a4,-(a1)
		movem.l d1-d6/a2-a5,-(a1)
		adda.w	d7,a0
		adda.w	d7,a1
		dbra	d0,loop_clrsp
		bra	clrspec_diag_on
clrspec_diag_off:

		move.l	scr,a0
		adda.l	#b_line*164+4*8+64,a0
		move.l	a0,a1
		adda.w	#24*8,a1
		move.w	#b_line+64,d7
loop_clrsp2:	movem.l d1-d6/a2-a3,-(a0)
		movem.l d1-d6/a2-a3,-(a0)
		movem.l d1-d6/a2-a3,-(a1)
		movem.l d1-d6/a2-a3,-(a1)
		adda.w	d7,a0
		adda.w	d7,a1
		dbra	d0,loop_clrsp2
clrspec_diag_on:

		tst.w	freeze
		bne	freeze2			;don't use data from dsp

		move.l	#14*2+2,-(sp)
		pea	leftclip
		move.l	#1,-(sp)
		pea	sendbuf+1
		move.w	#97,-(sp)
		trap	#14			;Dsp_BlkHandShake
		lea	18(sp),sp

		;put spectrum analyzer bars
		move.w	#13,d2
		lea	buf2,a1
		lea	left_bars,a3
		lea	log2,a2
		move.w	#4,d3
loop_putlbars:
		move.w	(a1)+,d1
		addq.l	#1,a1
		and.w	#$7ff,d1
		move.b	(a2,d1),d1
		and.w	#$ff,d1
		move.w	(a3),d4
		sub.w	d4,d1
		bpl	putlbar_up		;faster up than down
		asr.w	#1,d1
putlbar_up:	asr	#1,d1
		move	d1,d0
		asr	#1,d0
		add	d0,d1
		add.w	d4,d1
		move.w	d1,(a3)+

		move	d3,d0
		bsr	draw_bar
		addq.w	#1,d3
		dbra	d2,loop_putlbars


		move.w	#13,d2
		;lea	buf2+14*3,a1
		lea	right_bars,a3
		;lea	log2,a2
		move.w	#22,d3
loop_putrbars:
		move.w	(a1)+,d1
		addq.l	#1,a1
		and.w	#$7ff,d1
		move.b	(a2,d1),d1
		and.w	#$ff,d1
		move.w	(a3),d4
		sub.w	d4,d1
		bpl	putrbar_up
		asr.w	#1,d1
putrbar_up:	asr	#1,d1
		move	d1,d0
		asr	#1,d0
		add	d0,d1
		add.w	d4,d1
		move.w	d1,(a3)+

		move	d3,d0
		bsr	draw_bar
		addq.w	#1,d3
		dbra	d2,loop_putrbars

		bra	no_freeze

freeze2:
		move.l	#14*2+2,-(sp)
		pea	dummybuf
		move.l	#1,-(sp)
		pea	sendbuf+1
		move.w	#97,-(sp)
		trap	#14			;Dsp_BlkHandShake
		lea	18(sp),sp


		;put spectrum analyzer bars
		move.w	#13,d2
		lea	left_bars,a3
		move.w	#4,d3
loop_putlbars2:
		move.w	(a3)+,d1
		move	d3,d0
		bsr	draw_bar
		addq.w	#1,d3
		dbra	d2,loop_putlbars2

		move.w	#13,d2
		lea	right_bars,a3
		move.w	#22,d3
loop_putrbars2:
		move.w	(a3)+,d1
		move	d3,d0
		bsr	draw_bar
		addq.w	#1,d3
		dbra	d2,loop_putrbars2

no_freeze:


		move.w	leftclip+1,d0
		move.w	#0,d1
		bsr	put_clip
		move.w	rightclip+1,d0
		move.w	#1,d1
		bsr	put_clip




		tst.w	helpdiag_on
		beq	no_helpdiag

		bsr	put_helpdiag
no_helpdiag:


		tst.w	mbut
		bne	mb_pressed
		clr.w	mouse_but
		bra	mb_not_pressed
mb_pressed:
		addq.w	#1,mouse_but		;don't repeat too fast
mb_not_pressed:

		tst.w	helpdiag_on
		beq	no_help_on
		tst.w	mouse_but
		bgt	restore_diag

		; Cconis()
		move	#11, -(sp)
		trap	#1
		addq.l	#2, sp
		cmp.w	#-1,d0
		bne	main_loop

		; Crawcin()
		move	#7, -(sp)
		trap	#1
		addq.l	#2, sp
		swap	d0

	IF	test_on!=0
		cmp.w	#1,d0		;escape
		bne	no_esc2

		bsr	test
		bra	main_loop
no_esc2:

		cmp.w	#31,d0		;'S'
		bne	no_s2

		bsr	scr_dump
		bra	main_loop
no_s2:

	ENDIF

restore_diag:
		clr.w	helpdiag_on
		move.w	#2,restdiag_count	;clear on both screens (later)
		move.w	#-8,mouse_but
		bra	main_loop
no_help_on:

		move.w	#$1234,d7		;'magic number' (means: no command)

		tst.w	mouse_but
		ble	no_mousebut

		move.w	#-3,mouse_but		;don't repeat too fast

		move.w	#145,d0
		move.w	#52,d1
		move.w	#190,d2
		move.w	#78,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box1
		move.w	#2,d7			;scancode 2 -> key '1' (left channel volume down)
		bra	no_mousebut		;simulate keyboard
not_in_box1:

		move.w	#192,d0
		move.w	#52,d1
		move.w	#240,d2
		move.w	#78,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box2
		move.w	#3,d7			;left channel up
		bra	no_mousebut
not_in_box2:

		move.w	#155,d0
		move.w	#85,d1
		move.w	#198,d2
		move.w	#135,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box3
		move.w	#6,d7			;speaker
		bra	no_mousebut
not_in_box3:

		move.w	#203,d0
		move.w	#85,d1
		move.w	#245,d2
		move.w	#135,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box4
		move.w	#7,d7			;freeze
		bra	no_mousebut
not_in_box4:

		move.w	#395,d0
		move.w	#85,d1
		move.w	#440,d2			;time scale icon
		move.w	#135,d3
		bsr	test_mouse_in_box
		tst.w	d0
		bne	in_box5
		move.w	#47,d0
		move.w	#329,d1
		move.w	#305,d2			;left scope
		move.w	#459,d3
		bsr	test_mouse_in_box
		tst.w	d0
		bne	in_box5
		move.w	#335,d0
		move.w	#329,d1
		move.w	#593,d2			;right scope
		move.w	#459,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box5
in_box5:
		move.w	#9,d7			;time scale
		bra	no_mousebut
not_in_box5:

		move.w	#445,d0
		move.w	#85,d1
		move.w	#495,d2
		move.w	#135,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box6
		move.w	#10,d7			;quit
		bra	no_mousebut
not_in_box6:

		move.w	#400,d0
		move.w	#52,d1
		move.w	#446,d2
		move.w	#78,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box7
		move.w	#4,d7			;right channel down
		bra	no_mousebut
not_in_box7:

		move.w	#448,d0
		move.w	#52,d1
		move.w	#495,d2
		move.w	#78,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box8
		move.w	#5,d7			;right channel up
		bra	no_mousebut
not_in_box8:

		move.w	#440,d0
		move.w	#2,d1
		move.w	#615,d2
		move.w	#20,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box9
		move.w	#98,d7			;help
		bra	no_mousebut
not_in_box9:

		move.w	#222,d0
		move.w	#35,d1
		move.w	#258,d2
		move.w	#50,d3
		bsr	test_mouse_in_box
		tst.w	d0
		bne	in_box10
		move.w	#380,d0
		move.w	#35,d1
		move.w	#418,d2
		move.w	#50,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box10
in_box10:					;link button(s)
		; Kbshift(-1)
		move.w	#-1,-(sp)
		move.w	#11,-(sp)
		trap	#13
		addq.l	#4,sp
		bchg	#4,d0			;swap capslock
		; Kbshift()
		move.w	d0,-(sp)
		move.w	#11,-(sp)
		trap	#13
		addq.l	#4,sp

		bra	no_mousebut
not_in_box10:
		move.w	#250,d0
		move.w	#76,d1
		move.w	#267,d2
		move.w	#91,d3
		bsr	test_mouse_in_box
		tst.w	d0
		bne	in_box11
		move.w	#279,d0
		move.w	#43,d1
		move.w	#360,d2
		move.w	#124,d3
		bsr	test_mouse_in_box
		tst.w	d0
		beq	not_in_box11
in_box11:	move.w	#8,d7			;left vs right: dots/lines
		bra	no_mousebut
not_in_box11:

no_mousebut:
		; Cconis()
		move	#11, -(sp)
		trap	#1
		addq.l	#2, sp
		cmp.w	#-1,d0
		bne	no_key

		; Crawcin()
		move	#7, -(sp)
		trap	#1
		addq.l	#2, sp
		swap	d0
		move.w	d0,d7
no_key:

		; Kbshift(-1)
		move.w	#-1,-(sp)
		move.w	#11,-(sp)
		trap	#13
		addq.l	#4,sp

		move.b	d0,d1
		and.b	#%11,d0		;shift keys
		tst.b	d0
		sne	d0
		eor	d1,d0		;xor with capslock
		lsr.b	#4,d0
		and.w	#1,d0		;1 if shift or capslock pressed, 0 if shift and capslock pressed or no key pressed
		move.w	d0,shift

		cmp.w	old_link,d0
		beq	same_linkcol
		tst.w	d0
		beq	link_col1
		move.l	link_color,link_col
		bra	link_col2
link_col1:	move.l	$ffff9800+3*4,link_col
link_col2:	move.w	d0,old_link
same_linkcol:


		cmp.w	#$1234,d7		;no command
		beq	main_loop


		move.w	d7,d0

		cmp.b	#2,d0		; 1
		beq	lgainleft
		cmp.b	#109,d0		; 1 on numeric keypad
		bne	no_lgainleft
lgainleft:
		tst.w	lgain
		beq	cont_lgl
		subq.w	#1,lgain
		move.w	lgain,d0
		lsl.w	#4,d0

		move.w	d0,-(sp)
		move.w	#2,-(sp)
		move.w	#130,-(sp)	;soundcmd()
		trap	#14
		addq.l	#6,sp

		move.w	#11,d0
		move.w	#40,d1
		move.w	lgain,d2
		move.w	d0,icon1x
		move.w	d1,icon1y	;draw icon on 2nd screen later
		move.w	d2,icon1n
		bsr	put_icon
cont_lgl:	tst.w	shift
		beq	main_loop	;no shift pressed
		clr.w	shift		;no repeat forever (l->r->l->r->...)
		bra	rgainleft
no_lgainleft:

		cmp.b	#3,d0		; 2
		beq	lgainright
		cmp.b	#110,d0
		bne	no_lgainright
lgainright:
		move.w	lgain,d0
		cmp.w	#15,d0
		beq	cont_lgr
		addq.w	#1,lgain
		move.w	lgain,d0
		lsl.w	#4,d0

		move.w	d0,-(sp)
		move.w	#2,-(sp)
		move.w	#130,-(sp)	;soundcmd()
		trap	#14
		addq.l	#6,sp

		move.w	#11,d0
		move.w	#40,d1
		move.w	lgain,d2
		move.w	d0,icon1x
		move.w	d1,icon1y
		move.w	d2,icon1n
		bsr	put_icon
cont_lgr:	tst.w	shift
		beq	main_loop
		clr.w	shift
		bra	rgainright
no_lgainright:

		cmp.b	#4,d0		; 3
		beq	rgainleft
		cmp.b	#111,d0
		bne	no_rgainleft
rgainleft:
		tst.w	rgain
		beq	cont_rgl
		subq.w	#1,rgain
		move.w	rgain,d0
		lsl.w	#4,d0

		move.w	d0,-(sp)
		move.w	#3,-(sp)
		move.w	#130,-(sp)	;soundcmd()
		trap	#14
		addq.l	#6,sp

		move.w	#27,d0
		move.w	#40,d1
		move.w	rgain,d2
		move.w	d0,icon2x
		move.w	d1,icon2y
		move.w	d2,icon2n
		bsr	put_icon
cont_rgl:	tst.w	shift
		beq	main_loop
		clr.w	shift
		bra	lgainleft
no_rgainleft:

		cmp.b	#5,d0		; 4
		beq	rgainright
		cmp.b	#106,d0
		bne	no_rgainright
rgainright:
		move.w	rgain,d0
		cmp.w	#15,d0
		beq	cont_rgr
		addq.w	#1,rgain
		move.w	rgain,d0
		lsl.w	#4,d0

		move.w	d0,-(sp)
		move.w	#3,-(sp)
		move.w	#130,-(sp)	;soundcmd()
		trap	#14
		addq.l	#6,sp

		move.w	#27,d0
		move.w	#40,d1
		move.w	rgain,d2
		move.w	d0,icon2x
		move.w	d1,icon2y
		move.w	d2,icon2n
		bsr	put_icon
cont_rgr:	tst.w	shift
		beq	main_loop
		clr.w	shift
		bra	lgainright
no_rgainright:

		cmp.b	#6,d0		; 5
		beq	do_speaker
		cmp.b	#107,d0
		bne	no_speaker
do_speaker:
		bchg.b	#0,speaker+1
		bsr	set_speaker
		move.w	#17,d1
		sub.w	speaker,d1
		move.w	d1,d2
		move.w	#10,d0
		move.w	#86,d1
		move.w	d0,icon1x
		move.w	d1,icon1y
		move.w	d2,icon1n
		bsr	put_icon
		bra	main_loop
no_speaker:

		cmp.b	#7,d0		; 6
		beq	do_freeze
		cmp.b	#108,d0
		bne	no_freeze2
do_freeze:
		bchg.b	#0,freeze+1
		move.w	freeze,d0

		move.w	#18,d2
		add.w	d0,d2
		move.w	#13,d0
		move.w	#86,d1
		move.w	d0,icon1x
		move.w	d1,icon1y
		move.w	d2,icon1n
		bsr	put_icon
		bra	main_loop
no_freeze2:

		cmp.b	#9,d0		; 8
		beq	scopezoom
		cmp.b	#104,d0
		bne	no_scopezoom
scopezoom:
		bchg.b	#0,mstxtwhich+1
		lea	mstext1,a0
		tst.w	mstxtwhich
		beq	no_mstext2
		lea	mstext2,a0
no_mstext2:

		move.l	scopebuf,a1
		add.l	#57*(256/8*4)+(96/8*4),a1

		move.w	#11,d0
loop_cptxt2:	move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		add.l	#256/8*4-32,a1
		dbra	d0,loop_cptxt2

		move.w	#20,d2
		add.w	mstxtwhich,d2
		move.w	#25,d0
		move.w	#86,d1
		move.w	d0,icon1x
		move.w	d1,icon1y
		move.w	d2,icon1n
		bsr	put_icon

		bra	main_loop
no_scopezoom:

		cmp.b	#8,d0		; 7
		beq	dotslines
		cmp.b	#103,d0
		bne	no_dotslines
dotslines:
		bchg.b	#0,leftrightwhich+1
		bra	main_loop
no_dotslines:


	IF	test_on!=0
		cmp.w	#1,d0		;escape
		bne	no_esc

		bsr	test
		bra	main_loop
no_esc:

		cmp.w	#31,d0		;'S'
		bne	no_s

		bsr	scr_dump
		bra	main_loop
no_s:

	ENDIF

		cmp.b	#98,d0		;help
		bne	no_help

		move.w	#-1,helpdiag_on
		clr.w	rotfalccnt
		move.w	#2,helpdiag_cnt

		;save dialog background
		move.l	hdiagsave,a0
		add.w	#12*4,a0
		move.l	scr,a1
		add.l	#65*b_line+b_line/2-(128/2+8),a1
		move.w	#358-1,d0
loop_savediag:
		movem.l	(a1)+,d1-d7/a2-a6
		movem.l	d1-d7/a2-a6,-(a0)
		adda.w	#12*4*2,a0

		movem.l	(a1)+,d1-d7/a2-a6
		movem.l	d1-d7/a2-a6,-(a0)
		adda.w	#12*4+10*4,a0

		movem.l	(a1)+,d1-d7/a2-a4
		movem.l	d1-d7/a2-a4,-(a0)
		adda.w	#10*4+12*4,a0

		adda.w	#b_line-(128+8),a1

		dbra	d0,loop_savediag

		bra	main_loop
no_help:

		cmp.b	#10,d0		; 9
		beq	the_end
		cmp.b	#105,d0
		bne	main_loop

the_end:
		move.w	save_cacr,d0
		movec	d0,cacr				;restore CACR

		bsr	exit_mouse

		bsr	restore_video

		bsr	key_click_old

		;Super()
		move.l	old_superstack,-(sp)
		move.w	#$20,-(sp)
		trap	#1
		addq.l	#6,sp

		bsr	restore_sound

		move.w	#257,d0
		bsr	graf_mouse		;vdi mouse on

		move.w	monitor,d0
		cmp.w	#2,d0
		beq	vga

		move.w	#$11,-(sp)		;Random()
		trap	#14
		addq.l	#2,sp

		and.w	#7,d0
		bne	vga			;don't show alert always

		bsr	better_buy_vga		;put alert
vga:
		bra	exit


;-----------------------------------------------------------------------------

	IF	test_on!=0

init_test:
		move.l	#0,testcnt
		move.l	_hz_200,tstold200
		rts
test:
		move.l	_hz_200,d0
		sub.l	tstold200,d0
		move.l	testcnt,d1
		mulu.l	#200*10,d1
		divu.l	d0,d1
		move.l	d1,d0

		move.l	#4,d1
		lea	tstbuf1,a0
		bsr	l_to_a

		lea	tstbuf1,a0
		move.b	3(a0),4(a0)
		move.b	#'.',3(a0)

		pea	tstbuf
		move.w	#9,-(sp)
		trap	#1
		addq.l	#6,sp

		clr.l	testcnt
		move.l	_hz_200,tstold200
		rts

;---long to ascii---
;value in d0.l
;field length in d1.l
;return address in a0.l
l_to_a:		move.l	a0,a2
		move.l	#10,d2
		sub.l	d1,d2
		bmi	bindasc5
		lsl.l	#2,d2
		move.l	#numbers,a1
		add.l	d2,a1
		move.b	#'0',d2
bindasc1:	sub.l	(a1),d0
		bcs	bindasc2
		add.w	#1,d2
		bra	bindasc1
bindasc2:	add.l	(a1)+,d0
		tst.l	(a1)
		beq	bindasc4
		move.b	d2,(a0)+
		lsl	#8,d2
		move.b	#'0',d2
		bra	bindasc1
bindasc4:	move.b	d2,(a0)+
		move.b	#' ',(a0)+
bindasc5:	cmp.b	#'0',(a2)+
		bne	bindasc6
		move.b	#' ',-1(a2)
		bra	bindasc5
bindasc6:	rts

		data

numbers:	dc.l	1000000000,100000000,10000000,1000000
		dc.l	100000,10000,1000,100,10,1,0
tstbuf:		dc.b	27,'H'
tstbuf1:	dc.b	'000.0 Hz',0

		bss

testcnt:	ds.l	1
tstold200:	ds.l	1

		text

;save screen as .img (uncompressed)
scr_dump:
		move.l	#return,$70		;no vbl

		move.w	#0,-(sp)
		pea	save_fname
		move.w	#$3c,-(sp)		;Fcreate
		trap	#1
		addq.l	#8,sp
		move.w	d0,handle
		bmi	wr_error

		lea	mainscrdat,a0		;use this header and palette
		move.l	a0,-(sp)
		move.w	2(a0),d0		;header length
		add.w	d0,d0
		ext.l	d0
		move.l	d0,-(sp)
		move.w	handle,-(sp)
		move.w	#$40,-(sp)		;Fwrite
		trap	#1
		lea	$c(sp),sp

		move.l	scr2,a6			;source data

		move.w	#480-1,d7		;height-1
sd_loop_y:
		clr.w	d6
		move.w	#4-1,d5			;planes-1
loop_planes:
		lea	linedata,a1
		move.b	#$80,(a1)+		;raw data
		move.b	#80,(a1)+		;bytes per bitplane per line
		move.l	a6,a3			;data
		add.w	d6,a3			;start of bitplane
		addq.w	#2,d6			;next plane
		move.w	#40-1,d1		;words per bitplane per line -1
sd_loop_x:
		move.w	(a3),(a1)+		;copy data
		add.w	#8,a3			;next word in bitplane in source

		dbra	d1,sd_loop_x

		pea	linedata
		move.l	#2+80,-(sp)
		move.w	handle,-(sp)
		move.w	#$40,-(sp)		;Fwrite
		trap	#1
		lea	$c(sp),sp
		tst.l	d0
		bmi	wr_error

		dbra	d5,loop_planes
		add.l	#4*80,a6		;bytes per line in source

		dbra	d7,sd_loop_y

		move.w	handle,-(sp)
		move.w	#$3e,-(sp)		;Fclose
		trap	#1
		addq.l	#4,sp
wr_error:
		move.l	#vbl_interrupt,$70
		rts

return:		rte

		data

save_fname:	dc.b	'M_AN_SCR.IMG',0

		bss

handle:		ds.w	1
linedata:	ds.b	2+80

		text

	ENDIF


;x1 in d0, y1 in d1, x2 in d2, y2 in d3
;ret d0: in=1, out=0
test_mouse_in_box:
		move.w	mouse_x,d4
		move.w	mouse_y,d5
		cmp.w	d4,d0
		bgt	not_in_box
		cmp.w	d5,d1
		bgt	not_in_box
		cmp.w	d4,d2
		blt	not_in_box
		cmp.w	d5,d3
		blt	not_in_box
		move.w	#1,d0
		rts
not_in_box:
		clr.w	d0
		rts

wait_forvbl:
		move.l	_frclock,d1
wait_vbl:	cmp.l	_frclock,d1
		beq	wait_vbl
		rts


wait_forhz200:
		move.l	old_hz200,d0
		add.l	#min_hz200,d0			;max 200/min_hz200 times a second
wait_hz200:	cmp.l	_hz_200,d0
		bgt	wait_hz200
		move.l	_hz_200,old_hz200
		rts


;video

;addr in a0
;palette data in 'VgetRGB' format
set_palet:
		lea	$ffff9800,a1
		move.w	#15,d0
loop_setp:
		move.b	(a0)+,d1
		move.b	(a0)+,d1
		lsl.l	#8,d1
		move.b	(a0)+,d1
		lsl.l	#8,d1
		lsl.l	#8,d1
		move.b	(a0)+,d1
		move.l	d1,(a1)+
		dbra	d0,loop_setp
		rts


;a0=buf (24 words)
setfv:
		addq.l	#6,a0
		
		move.l	(a0)+,$ff820e	;offset & vwrap
		move.w	(a0)+,$ff8266	;spshift
		move.l	#$ff8282,a1	;horizontal control registers
loop1:		move	(a0)+,(a1)+
		cmp.l	#$ff8292,a1
		bne	loop1
		move.l	#$ff82a2,a1	;vertical control registers
loop2:		move	(a0)+,(a1)+
		cmp.l	#$ff82ae,a1
		bne	loop2
		move	(a0)+,$ff82c2	;video control
		move	(a0)+,$ff82c0	;video clock
		addq.l	#1,a0
		move.b	(a0)+,$ff820a	;video sync mode
		rts


;a0=buf (24 words)
savefv:		move.l	a0,a1
		move.l	#'FVD2',(a1)+	;4 bytes header
		move.b	$ff8006,(a1)+	;monitor type
		move.b	$ff820a,(a1)+	;sync
		move.l	$ff820e,(a1)+	;offset & vwrap
		move.w	$ff8266,(a1)+	;spshift
		move.l	#$ff8282,a0	;horizontal control registers
loop3:		move	(a0)+,(a1)+
		cmp.l	#$ff8292,a0
		bne	loop3
		move.l	#$ff82a2,a0	;vertical control registers
loop4:		move	(a0)+,(a1)+
		cmp.l	#$ff82ae,a0
		bne	loop4
		move	$ff82c2,(a1)+	;video control
		move	$ff82c0,(a1)+	;video clock
		move.b	$ff8260,(a1)+	;shifter resolution
		move.b	$ff820a,(a1)+	;video sync mode
		rts
		
save_palette:
		lea	$ffff8240,a0
		move.w	#15,d0
		lea	old_stpalet,a1
loop_savestp:	move.w	(a0)+,(a1)+
		dbra	d0,loop_savestp
		lea	$ffff9800,a0
		move.w	#255,d0
		lea	old_palet,a1
loop_savep:	move.l	(a0)+,(a1)+
		dbra	d0,loop_savep
		rts

rest_palette:
		lea	$ffff8240,a0
		move.w	#15,d0
		lea	old_stpalet,a1
loop_reststp:	move.w	(a1)+,(a0)+
		dbra	d0,loop_reststp
		lea	$ffff9800,a0
		move.w	#255,d0
		lea	old_palet,a1
loop_restp:	move.l	(a1)+,(a0)+
		dbra	d0,loop_restp
		rts

init_video:
		bsr	save_palette

		move.w	#2,-(sp)
		trap	#14			;Physbase()
		addq.l	#2,sp
		move.l	d0,old_physscr

		move.w	#3,-(sp)
		trap	#14			;Logbase()
		addq.l	#2,sp
		move.l	d0,old_logscr

		move.w	#-1,-(sp)
		move.w	#$58,-(sp)		;VsetMode()
		trap	#14
		addq.l	#4,sp
		move.w	d0,old_mode

		move.w	d0,d1
		and.w	#$20,d1			;PAL bit
		lsr.w	#5,d1
		move.w	d1,pal

		move.w	d0,-(sp)
		move.w	#$5b,-(sp)		;VgetSize()
		trap	#14
		addq.l	#4,sp
		move.l	d0,old_scrlen

		cmp.l	#len_of_scr,d0
		bgt	cont_vid1

		move.w	#-1,-(sp)
		move.l	scr1,-(sp)
		move.l	scr1,-(sp)
		move.w	#5,-(sp)		;Setscreen
		trap	#14
		lea	$c(sp),sp
cont_vid1:
		bsr	wait_forvbl

		move.l	#old_regs,a0
		bsr	savefv

		lea.l	regs_vga,a0
		move.w	monitor,d0
		cmp.w	#2,d0
		beq	set_vid
		lea.l	regs_tv60,a0
		tst.w	pal
		beq	set_vid
		lea.l	regs_tv50,a0
set_vid:
		bsr	setfv

		move.l	old_scrlen,d0
		cmp.l	#len_of_scr,d0
		ble	cont_vid2

		move.w	#-1,-(sp)
		move.l	scr1,-(sp)
		move.l	scr1,-(sp)
		move.w	#5,-(sp)		;Setscreen
		trap	#14
		lea	$c(sp),sp
cont_vid2:

		lea	palet,a0
		bsr	set_palet

		rts


restore_video:
		move.l	old_scrlen,d0
		cmp.l	#len_of_scr,d0
		ble	cont_vid3

		move.w	#-1,-(sp)
		move.l	old_physscr,-(sp)
		move.l	old_logscr,-(sp)
		move.w	#5,-(sp)		;Setscreen
		trap	#14
		lea	$c(sp),sp
cont_vid3:

;restore video hardware registers
;necessary for Screenblaster (BlowUp, etc ?) because VsetMode()
;doesn't work when SB installed (except when in st compatible mode).
;VsetMode() does it somewhat like this too

		bsr	wait_forvbl

		lea.l	old_regs,a0
		move.b	5(a0),$ffff820a
		move.l	12(a0),$ffff8282
		move.l	16(a0),$ffff8286
		move.l	20(a0),$ffff828a
		move.l	24(a0),$ffff828e
		move.l	28(a0),$ffff82a2
		move.l	32(a0),$ffff82a6
		move.l	36(a0),$ffff82aa
		move.w	6(a0),$ffff820e
		move.w	8(a0),$ffff8210
		move.w	40(a0),$ffff82c2
		move.w	42(a0),$ffff82c0
		clr.w	$ffff8266
		move.w	old_mode,d0
		and.w	#7,d0
		tst.w	d0
		bne	no_1plane
		move.w	10(a0),$ffff8266
		bra	restore_done
no_1plane:	cmp.w	#1,d0
		bne	no_2planes
		move.b	#1,$ffff8260
		move.w	8(a0),$ffff8210
		move.w	40(a0),$ffff82c2
		bra	restore_done
no_2planes:	cmp.w	#2,d0
		bne	no_4planes
		move.w	old_mode,d1
		btst	#7,d1
		beq	restore_done
		move.b	#0,$ffff8260
		move.w	40(a0),$ffff82c2
		bra	restore_done
no_4planes:	move.w	10(a0),$ffff8266
restore_done:


		move.l	old_scrlen,d0
		cmp.l	#len_of_scr,d0
		bgt	cont_vid4

		move.w	#-1,-(sp)
		move.l	old_physscr,-(sp)
		move.l	old_logscr,-(sp)
		move.w	#5,-(sp)		;Setscreen()
		trap	#14
		lea	$c(sp),sp
cont_vid4:
		bsr	rest_palette

		rts




key_click_off:
		move.b	$484,oldconterm
		move.b	#2,$484			;conterm: repeat=on
		rts

key_click_old:
		move.b	oldconterm,$484
		rts


;ret d0:0=error
check_cookies:
		move.l	#'_CPU',d0
		bsr	get_cookie
		tst.w	d0
		beq	ret_check_c0

		cmp.l	#30,d1
		blt	ret_check_c0

		move.l	#'_SND',d0
		bsr	get_cookie
		tst.w	d0
		beq	ret_check_c0

		and.l	#$1c,d1
		cmp.l	#$1c,d1
		blt	ret_check_c0

		move.w	#-1,d0
		rts

ret_check_c0:	clr.w	d0
		rts


;d0:cookie
;ret d1:value
;ret d0:found (1) or not (0)
get_cookie:
		move.l	$5a0,a0
		beq	ret_getcookie0		;no cookie jar installed
loop_getcookie:
		cmp.l	(a0)+,d0
		bne	wrong_cookie
		move.l	(a0),d1
		move.w	#1,d0
		rts
wrong_cookie:	addq.l	#4,a0
		tst.l	-8(a0)
		bne	loop_getcookie

ret_getcookie0: clr.w	d0
		rts



;draw bar for spectrum analyzer
;d0=x, d1=h
draw_bar:
		tst.w	helpdiag_on
		beq	db_do_draw

		cmp.w	#12,d0
		blt	db_do_draw
		cmp.w	#28,d0
		blt	ret_db		;don't draw all bars when help dialog is on screen
db_do_draw:
		move.l	scr,a0
		adda.l	#272*b_line,a0
		lsl.w	#3,d0
		adda.w	d0,a0

		move.l	bar_patt1,d4
		move.l	bar_patt1+4,d5
		move.l	bar_patt2,d6
		move.l	bar_patt2+4,d7
		move.w	#b_line*2+4,d0
		move.l	d4,(a0)
		move.l	d5,4(a0)
		sub.w	#b_line,a0
		subq.w	#1,d1
		bge	loop_db
		rts
loop_db:
		move.l	d6,(a0)+
		move.l	d7,(a0)
		move.l	d4,-b_line-4(a0)
		move.l	d5,-b_line(a0)
		sub.w	d0,a0
		dbra	d1,loop_db
ret_db:
		rts



;put help dialog

loop_put_help:
		movem.l	(a0)+,d1-d7/a2-a5
		movem.l	d1-d7/a2-a5,-(a1)
		adda.w	#11*4*2,a1
		movem.l	(a0)+,d1-d7/a2-a5
		movem.l	d1-d7/a2-a5,-(a1)
		adda.w	#10*4+11*4,a1
		movem.l	(a0)+,d1-d7/a2-a4
		movem.l	d1-d7/a2-a4,-(a1)
		adda.w	#11*4+10*4+b_line-(256/8*4),a1
		dbra	d0,loop_put_help
		rts

put_helpdiag:
		move.l	helpdiag,a0
		move.l	scr,a1
		add.l	#65*b_line+b_line/2-(256/8*4)/2+11*4,a1

		tst.w	helpdiag_cnt
		beq	help_not_all
		move.w	#349,d0
		subq.w	#1,helpdiag_cnt
		bsr	loop_put_help		;draw complete help dialog

		;draw left shadow, odd lines
		move.l	scr,a1
		add.l	#73*b_line+b_line/2-(256/8*4)/2-7,a1
		move.b	#$55,d1
		move.b	#$aa,d2
		move.w	#350/2-1,d0
loop_put_help2:
		and.b	d1,(a1)
		and.b	d1,2(a1)
		or.b	d2,4(a1)
		and.b	d1,6(a1)
		adda.w	#b_line*2,a1
		dbra	d0,loop_put_help2

		rol.b	#1,d1
		rol.b	#1,d2

		;even lines
		move.l	scr,a1
		add.l	#74*b_line+b_line/2-(256/8*4)/2-7,a1
		move.w	#350/2-1,d0
loop_put_help5:
		and.b	d1,(a1)
		and.b	d1,2(a1)
		or.b	d2,4(a1)
		and.b	d1,6(a1)
		adda.w	#b_line*2,a1
		dbra	d0,loop_put_help5

		bra	help_all


help_not_all:
		move.w	#123-65,d0
		bsr	loop_put_help		;part on left-right scope
		add.l	#(331-124)*b_line,a1
		add.l	#(331-124)*(256/8*4),a0
		move.w	#65+350-331-1,d0
		bsr	loop_put_help		;part on scopes

		;draw left shadow, odd lines
		move.l	scr,a1
		add.l	#331*b_line+b_line/2-(256/8*4)/2-7,a1
		move.b	#$55,d1
		move.b	#$aa,d2
		move.w	#92/2-1,d0
loop_put_help6:
		and.b	d1,(a1)
		and.b	d1,2(a1)
		or.b	d2,4(a1)
		and.b	d1,6(a1)
		adda.w	#b_line*2,a1
		dbra	d0,loop_put_help6

		move.l	scr,a1
		add.l	#165*b_line+b_line/2-(256/8*4)/2-7,a1
		move.w	#110/2-1,d0
loop_put_help8:
		and.b	d1,(a1)
		and.b	d1,2(a1)
		or.b	d2,4(a1)
		and.b	d1,6(a1)
		adda.w	#b_line*2,a1
		dbra	d0,loop_put_help8


		rol.b	#1,d1
		rol.b	#1,d2

		;even lines
		move.l	scr,a1
		add.l	#332*b_line+b_line/2-(256/8*4)/2-7,a1
		move.w	#92/2-1,d0
loop_put_help7:
		and.b	d1,(a1)
		and.b	d1,2(a1)
		or.b	d2,4(a1)
		and.b	d1,6(a1)
		adda.w	#b_line*2,a1
		dbra	d0,loop_put_help7

		move.l	scr,a1
		add.l	#164*b_line+b_line/2-(256/8*4)/2-7,a1
		move.w	#110/2-1,d0
loop_put_help9:
		and.b	d1,(a1)
		and.b	d1,2(a1)
		or.b	d2,4(a1)
		and.b	d1,6(a1)
		adda.w	#b_line*2,a1
		dbra	d0,loop_put_help9

help_all:

		;draw lower shadow
		move.l	scr,a1
		add.l	#415*b_line+b_line/2-(256/8*4)/2,a1
		move.w	#$5555,d1
		move.w	#$aaaa,d2
		move.w	#7,d0
loop_put_help4:
		move.w	#14,d3
loop_put_help3:
		and.w	d1,(a1)+
		and.w	d1,(a1)+
		or.w	d2,(a1)+
		and.w	d1,(a1)+

		dbra	d3,loop_put_help3

		and.b	d1,(a1)
		and.b	d1,2(a1)
		or.b	d2,4(a1)
		and.b	d1,6(a1)
		rol.w	#1,d1
		rol.w	#1,d2
		adda.w	#b_line-128+8,a1

		dbra	d0,loop_put_help4

		move.l	rotfalc,a0
		move.w	rotfalccnt,d0
		lsr.w	#1,d0
		mulu.w	#48/16*8*25,d0
		add.l	d0,a0

		move.l	scr,a1
		add.l	#(65+310)*b_line+b_line/2-(256/8*4)/2+(176/8*4)+6*4,a1

		move.w	#24,d0
loop_put_rotfalc:
		movem.l	(a0)+,d1-d6
		movem.l	d1-d6,-(a1)
		add.w	#b_line+6*4,a1
		dbra	d0,loop_put_rotfalc

		move.w	rotfalccnt,d0
		addq.w	#1,d0
		cmp.w	#32,d0
		bne	rotfalc_nolimit
		clr.w	d0
rotfalc_nolimit:
		move.w	d0,rotfalccnt

		rts

;not documented!
get_speaker:
		move.w	#14,-(sp)
		move.l	#$1c0000,-(sp)
		trap	#14
		addq.l	#6,sp
		clr.w	speaker
		btst	#6,d0
		bne	ret_gs
		move.w	#1,speaker
ret_gs: 	rts

;not documented!
set_speaker:
		move.w	speaker,d6
		lsl.w	#6,d6
		bchg	#6,d6
		move.w	#14,-(sp)
		move.l	#$1c0000,-(sp)
		trap	#14
		addq.l	#6,sp
		bclr	#6,d0
		or.w	d6,d0
		move.w	#$8e,-(sp)
		move.w	d0,-(sp)
		move.w	#$1c,-(sp)
		trap	#14
		addq.l	#6,sp
		rts

;d0=x/16, d1=y, d2=num
put_icon:
		move.l	scr,a1
		mulu.w	#b_line,d1
		adda.l	d1,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		move.l	icons,a2
		lsl.w	#1,d2
		lsl.w	#8,d2
		adda.w	d2,a2
		move.w	#31,d0
loop_pi:	move.l	(a2)+,(a1)+
		move.l	(a2)+,(a1)+
		move.l	(a2)+,(a1)+
		move.l	(a2)+,(a1)+
		adda.w	#b_line-16,a1
		dbra	d0,loop_pi
		rts


;draw scope
;don't try too hard understanding this routine!
;(it's optimized a little and doesn't have a lot of comments added)

;d0=start x, a0=buf
put_scope:
		move.l	scr,a2
		add.l	#b_line*394+6,a2	;zero level; '+6' because only one bitplane is used

		move.w	d0,d1
		and.b	#$f0,d1
		lsr.w	#1,d1
		add.w	d1,a2
		move.w	d0,d1
		and.w	#$f,d1
		neg.w	d1
		add.w	#15,d1
		moveq	#0,d4
		bset	d1,d4

		move.w	#253,d1
		move.b	(a0),d7			;first data point
		ext.w	d7

		move.w	bufstepsize,d5
		ext.l	d5
loop_ps:
		add.l	d5,a0
		move.b	(a0),d2			;get next data point
		ext.w	d2

		move.l	#b_line,d6
		move.w	d7,d3
		sub.w	d2,d7
		bpl	cont_ps
		neg.l	d6
		neg.w	d7
cont_ps:	move.l	a2,a1

		muls.w	#b_line,d3
		sub.l	d3,a1

		move.w	d7,d0
		beq	cont_ps4
		subq.w	#1,d7
		move.w	d7,d0
cont_ps4:
		lsr.w	#1,d7

		sub.w	d7,d0
loop_ps2:
		or.w	d4,(a1)
		adda.l	d6,a1
		dbra	d0,loop_ps2

		ror.w	#1,d4
		bpl	cont_ps2
		addq.w	#8,a2
		addq.w	#8,a1
cont_ps2:
		move.w	d7,d0
		beq	cont_ps3
loop_ps3:
		or.w	d4,(a1)
		adda.l	d6,a1
		dbra	d0,loop_ps3
cont_ps3:

		move.w	d2,d7
		dbra	d1,loop_ps


		add.l	d5,a0
		move.b	(a0),d2		;get last data point
		ext.w	d2

		move.l	#b_line,d6
		move.w	d7,d3
		sub.w	d2,d7
		bpl	cont_ps5
		neg.l	d6
		neg.w	d7
cont_ps5:	move.l	a2,a1

		muls.w	#b_line,d3
		sub.l	d3,a1

		move.w	d7,d0
		beq	cont_ps6
		subq.w	#1,d7
		move.w	d7,d0
cont_ps6:
		lsr.w	#1,d7

		sub.w	d7,d0
loop_ps4:
		or.w	d4,(a1)
		adda.l	d6,a1
		dbra	d0,loop_ps4

		rts


;d0=x, d1=angle
put_vu:
		lea	vu_x,a0
		ext.w	d1
		move.w	(a0,d1*2),d2	;x
		move.w	d2,d5		;dx
		add.w	d0,d2
		lea	vu_y,a0
		move.w	(a0,d1*2),d3	;y
		move.w	d3,d4		;dy
		add.w	#96,d3

		ext.l	d5
		lsl.l	#8,d5		;dx*256
		divs	d4,d5		;dx*256/dy
		ext.l	d5
		ext.l	d2
		lsl.l	#8,d2		;x*256

		move.l	scr,a0
		move.w	d3,d0
		mulu.w	#b_line,d0
		add.l	d0,a0		;addr of 1st line

loop_pvu:
		cmp.w	#89-2,d3	;shadow still in range?
		bge	cont_pvu	;no

		move.l	a0,a1
		move.l	d2,d0
		sub.l	#256*2,d0
		lsr.l	#8,d0
		move.w	d0,d1
		lsr.w	#4,d0
		lsl.w	#3,d0
		add.w	d0,a1
		and.w	#$f,d1
		moveq	#0,d7
		neg.w	d1
		add.w	#15,d1
		bset	d1,d7

		;move.w	d7,d6
		;not.w	d6

		move.w	(b_line*2,a1),d0
		or.w	(b_line*2+2,a1),d0
		or.w	(b_line*2+4,a1),d0
		or.w	(b_line*2+6,a1),d0
		and.w	d7,d0
		bne	cont_pvu		;only on white background

		;and.w	d6,(b_line*2,a1)
		or.w	d7,(b_line*2+2,a1)
		or.w	d7,(b_line*2+4,a1)
		or.w	d7,(b_line*2+6,a1)
cont_pvu:
		move.l	a0,a1
		move.l	d2,d0
		lsr.l	#8,d0
		move.w	d0,d1
		lsr.w	#4,d0
		lsl.w	#3,d0
		add.w	d0,a1
		and.w	#$f,d1
		moveq	#0,d7
		neg.w	d1
		add.w	#15,d1
		bset	d1,d7

		or.w	d7,(a1)
		or.w	d7,2(a1)
		or.w	d7,4(a1)
		or.w	d7,6(a1)

		add.w	#b_line,a0
		add.l	d5,d2

		addq.w	#1,d3
		cmp.w	#89,d3
		bne	loop_pvu

		rts


;d0=0:off;<>0:on
;d1=0:left;1:right
put_clip:
		move.l	scr,a0
		tst.w	d1
		bne	pclip_right
		adda.l	#b_line*124+(96/8*4),a0
		bra	pclip_left
pclip_right:	adda.l	#b_line*124+(512/8*4),a0
pclip_left:
		lea	clipbuf_on,a1
		tst.w	d0
		bne	pclip_on
		lea	clipbuf_off,a1
pclip_on:

		move.w	#9-1,d0
loop_pclip:
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		adda.l	#b_line-16,a0
		dbra	d0,loop_pclip

		rts



install_sound:	move.w	#128,-(sp)
		trap	#14			;locksnd()
		addq.l	#2,sp
		tst.w	d0
		bmi	snd_locked
ignore_sndlocked:

		move.w	#104,-(sp)
		trap	#14			;Dsp_Lock()
		addq.l	#2,sp
		tst.w	d0
		bmi	dsp_locked
ignore_dsplocked:

		move.w	#113,-(sp)
		trap	#14			;Dsp_RequestUniqueAbility()
		addq.l	#2,sp
		move.w	d0,ability

		pea	ymem
		pea	xmem
		move.w	#106,-(sp)
		trap	#14			;Dsp_Available()
		lea	$a(sp),sp

		move.l	xmem,d0
		cmp.l	#x,d0
		bmi	Flush
		move.l	ymem,d0
		cmp.l	#y,d0
		bpl	NoFlush
Flush:		move.w	#115,-(sp)
		trap	#14			;Dsp_FlushSubroutines()
		addq.l	#2,sp
NoFlush:

		move.l	ymem,-(sp)
		move.l	xmem,-(sp)
		move.w	#107,-(sp)
		trap	#14			;Dsp_Reserve()
		lea	$a(sp),sp
		tst.w	d0
		bne	OutOfDspMem

		move.l	#end_of_dspbin,d0
		sub.l	#dsp_bin,d0
		divu	#3,d0			;length in dsp-words

		move.w	ability,-(sp)
		move.l	d0,-(sp)
		pea	dsp_bin
		move.w	#$6d,-(sp)
		trap	#14			;Dsp_ExecProg()
		lea	12(sp),sp


		clr.w	d4
		clr.w	d5
		lea	old_sndstate,a4
save_snd:	move.w	#-1,-(sp)
		move.w	d4,-(sp)
		move.w	#130,-(sp)		;soundcmd()
		trap	#14
		addq.l	#6,sp

		move.w	d0,(a4,d5)
		addq.w	#2,d5
		addq.w	#1,d4
		cmp.w	#7,d4
		bne	save_snd

		bsr	get_speaker
		move.w	speaker,old_speaker
		clr.w	speaker
		bsr	set_speaker

	;	move.w	#1,-(sp)
	;	move.w	#140,-(sp)		;sndstatus(1)  (reset sound system)
	;	trap	#14
	;	addq.l	#4,sp			;gives problems sometimes, so just leave it out

		move.w	(a4),-(sp)
		clr.w	-(sp)
		move.w	#130,-(sp)		;old left output level
		trap	#14			;soundcmd()
		addq.l	#6,sp

		move.w	2(a4),-(sp)
		move.w	#1,-(sp)
		move.w	#130,-(sp)		;old right output level
		trap	#14			;soundcmd()
		addq.l	#6,sp

		move.w	4(a4),d0
		lsr.w	#4,d0
		move.w	d0,lgain

		move.w	4(a4),-(sp)
		move.w	#2,-(sp)
		move.w	#130,-(sp)		;old left input level
		trap	#14			;soundcmd()
		addq.l	#6,sp

		move.w	6(a4),d0
		lsr.w	#4,d0
		move.w	d0,rgain

		move.w	6(a4),-(sp)
		move.w	#3,-(sp)
		move.w	#130,-(sp)		;old right input level
		trap	#14			;soundcmd()
		addq.l	#6,sp

		move.w	#1,-(sp)
		move.w	#4,-(sp)
		move.w	#130,-(sp)		;adder input from ADC
		trap	#14			;soundcmd()
		addq.l	#6,sp

		move.w	#0,-(sp)
		move.w	#5,-(sp)
		move.w	#130,-(sp)		;ADC input microphone
		trap	#14			;soundcmd()
		addq.l	#6,sp

		move.w	#1,-(sp)
		move.w	#1,-(sp)
		move.w	#137,-(sp)		;dsptristate(1,1);
		trap	#14
		addq.l	#6,sp

		move.w	#1,-(sp)
		move.w	#132,-(sp)
		trap	#14			;setmode(1);
		addq.l	#4,sp

		move.w	#1,-(sp)
		move.w	#2,-(sp)
		move.w	#0,-(sp)
		move.w	#0,-(sp)
		move.w	#0,-(sp)
		move.w	#139,-(sp)
		trap	#14			;devconnect(DMAPLAY, 0, CLK_25M, 2, 1)
		lea	$c(sp),sp		;32780 Hz. My 'Atari Developers Documentation' says 33880 Hz,
						;but I think that this is an error. (25175000 Hz/256/(2+1)=32780 Hz)

		move.w	#1,-(sp)
		move.w	#2,-(sp)
		move.w	#0,-(sp)
		move.w	#0,-(sp)
		move.w	#1,-(sp)
		move.w	#139,-(sp)
		trap	#14			;devconnect(DSPXMIT, 0, CLK_25M, 2, 1)
		lea	$c(sp),sp

		move.w	#1,-(sp)
		move.w	#2,-(sp)
		move.w	#0,-(sp)
		move.w	#0,-(sp)
		move.w	#2,-(sp)
		move.w	#139,-(sp)
		trap	#14			;devconnect(EXTINP, 0, CLK_25M, 2, 1)
		lea	$c(sp),sp

		move.w	#1,-(sp)
		move.w	#2,-(sp)
		move.w	#0,-(sp)
		move.w	#2,-(sp)
		move.w	#3,-(sp)
		move.w	#139,-(sp)
		trap	#14			;devconnect(ADC, DSPRECV, CLK_25M, 2, 1)
		lea	$c(sp),sp

		clr.w	-(sp)
		move.w	#136,-(sp)
		trap	#14			;buffoper(0);
		addq.l	#4,sp

		rts

restore_sound:

		move.w	old_speaker,speaker
		bsr	set_speaker

		;move.w #1,-(sp)
		;move.w #140,-(sp)		;sndstatus(1)
		;trap	#14
		;addq.l #4,sp

		move.w	#0,-(sp)
		move.w	#0,-(sp)
		move.w	#137,-(sp)		;dsptristate(0,0);
		trap	#14
		addq.l	#6,sp

		clr.w	d4
		clr.w	d5
		move.l	#old_sndstate,a4
get_snd:	move.w	(a4,d5),-(sp)
		move.w	d4,-(sp)
		move.w	#130,-(sp)		;soundcmd()
		trap	#14
		addq.l	#6,sp

		addq.w	#2,d5
		addq.w	#1,d4
		cmp.w	#7,d4
		bne	get_snd

		move.w	#105,-(sp)
		trap	#14			;Dsp_Unlock()
		addq.l	#2,sp

		move.w	#129,-(sp)
		trap	#14			;unlocksnd()
		addq.l	#2,sp

		rts

dsp_locked:
		move.w	#0,d0			;arrow
		bsr	graf_mouse
		lea	dsp_locked_txt,a0
		move.w	#1,d0
		bsr	form_alert
		cmp.w	#2,d0
		beq	ignore_dsplocked

		move.w	#129,-(sp)
		trap	#14			;unlocksnd()
		addq.l	#2,sp

		bra	exit

snd_locked:
		move.w	#0,d0			;arrow
		bsr	graf_mouse
		lea	snd_locked_txt,a0
		move.w	#1,d0
		bsr	form_alert
		cmp.w	#2,d0
		beq	ignore_sndlocked
		bra	exit

outofmem:
		lea	outofmem_txt,a0
		bra	error


OutOfDspMem:	move.w	#105,-(sp)
		trap	#14			;Dsp_Unlock()
		addq.l	#2,sp

		move.w	#129,-(sp)
		trap	#14			;unlocksnd()
		addq.l	#2,sp

		lea	outofmem_txt2,a0
		bra	error

wrong_machine:
		lea	wrong_mach_txt,a0
		bra	error

wrong_scr:
		lea	wrong_scr_txt,a0
		bra	error

better_buy_vga:
		move.w	#0,d0
		bsr	graf_mouse
		lea	better_vga_txt,a0
		move.w	#1,d0
		bsr	form_alert
		rts

exit:
		bsr	appl_exit

		; Kbshift(-1)
		move.w	#-1,-(sp)
		move.w	#11,-(sp)
		trap	#13
		addq.l	#4,sp

		move.w	old_capslock,d1
		lsl.w	#4,d1
		bclr	#4,d0
		or.w	d1,d0

		; Kbshift()
		move.w	d0,-(sp)
		move.w	#11,-(sp)
		trap	#13
		addq.l	#4,sp

		; Pterm0()
		clr.w	-(sp)
		trap	#1

;alert string in a0
error:
		move.l	a0,a6
		move.w	#0,d0			;arrow
		bsr	graf_mouse
		move.l	a6,a0
		move.w	#1,d0
		bsr	form_alert
		bra	exit


appl_init:	lea	contrl,a0
		move.w	#10,(a0)
		move.w	#0,2(a0)
		move.w	#1,4(a0)
		move.w	#0,6(a0)
		move.w	#0,8(a0)
		move.l	#aespb,d1
		move.w	#200,d0			;aes
		trap	#2			;gem
		move.w	int_out,d0
		rts

appl_exit:	lea	contrl,a0
		move.w	#19,(a0)
		move.w	#0,2(a0)
		move.w	#1,4(a0)
		move.w	#0,6(a0)
		move.w	#0,8(a0)
		move.l	#aespb,d1
		move.w	#200,d0
		trap	#2
		move.w	int_out,d0
		rts

;string in a0
;def_but in d0
form_alert:	lea	contrl,a1
		move.w	#52,(a1)
		move.w	#1,2(a1)
		move.w	#1,4(a1)
		move.w	#1,6(a1)
		move.w	#0,8(a1)
		move.l	a0,addr_in
		move.w	d0,int_in
		move.l	#aespb,d1
		move.w	#200,d0
		trap	#2
		move.w	int_out,d0
		rts

;mnumber in d0
graf_mouse:	lea	contrl,a0
		move.w	#78,(a0)
		move.w	#1,2(a0)
		move.w	#1,4(a0)
		move.w	#1,6(a0)
		move.w	#0,8(a0)
		move.w	d0,int_in
		move.l	#0,addr_in
		move.l	#aespb,d1
		move.w	#200,d0
		trap	#2
		move.w	int_out,d0
		rts



decode_imgs:
		lea	mainscrdat,a0
		move.l	scr2,dest
		bsr	dec_img
		lea	iconsdat,a0
		move.l	icons,dest
		bsr	dec_img
		lea	mousedat,a0
		move.l	#mousedata,dest
		bsr	dec_img
		lea	helpdat,a0
		move.l	helpdiag,dest
		bsr	dec_img
		lea	rotfalcdat,a0
		move.l	rotfalc,dest
		bsr	dec_img
		rts

dec_img:
		move.w	6(a0),patt_len
		moveq	#0,d0
		move.w	12(a0),d0
		lsr.l	#3,d0			;bytes per line per plane
		move.l	d0,bperlineplane
		lsl.l	#2,d0			;*planes
		move.l	d0,bytesperline
		move.w	14(a0),lines
		move.w	2(a0),d0		;header length in words
		add.w	d0,d0			;header length in bytes
		add.w	d0,a0

		move.w	#0,repeat
		move.w	lines,d7
		subq.w	#1,d7
loop_y:
		move.w	repeat,d0
		bne	do_repeat

		bsr	plane
		add.l	#2,dest
		bsr	plane
		add.l	#2,dest
		bsr	plane
		add.l	#2,dest
		bsr	plane
		move.l	bytesperline,d0
		subq.l	#6,d0
		add.l	d0,dest

		bra	no_repeat
do_repeat:
		subq.w	#1,d0
		move.w	d0,repeat
		move.l	dest,a2
		move.l	a2,a3
		sub.l	bytesperline,a3
		move.l	bytesperline,d0
		lsr.l	#1,d0
		subq.w	#1,d0
loop_rep:
		move.w	(a3)+,(a2)+
		dbra	d0,loop_rep
		move.l	bytesperline,d0
		add.l	d0,dest
no_repeat:
		dbra	d7,loop_y

		rts
plane:
		lea	linebuf,a1
		bsr	read_line
		move.l	dest,a2
		lea	linebuf,a1
		move.l	bperlineplane,d0
		lsr.w	#1,d0
		subq.w	#1,d0
loop_x:		move.w	(a1)+,(a2)
		addq.l	#8,a2
		dbra	d0,loop_x
		rts

read_line:
		move.b	(a0)+,d0
		bne	no_null

		move.b	(a0)+,d0
		bne	pattern

		;replication
		move.b	(a0)+,d0

		moveq	#0,d0
		move.b	(a0)+,d0
		subq.w	#1,d0
		move.w	d0,repeat
		move.l	a1,d0
		bra	read_line
no_null:
		cmp.b	#$80,d0
		bne	solid_run

		;bit_string

		moveq	#0,d0
		move.b	(a0)+,d0
		subq.w	#1,d0
loop_bs:
		move.b	(a0)+,(a1)+
		dbra	d0,loop_bs
		bra	end_rout
solid_run:
		move.b	d0,d1
		and.b	#$80,d1
		sne	d1
		and.w	#$7f,d0
		subq.w	#1,d0
loop_sr:
		move.b	d1,(a1)+
		dbra	d0,loop_sr
		bra	end_rout
pattern:
		move.w	patt_len,d1
		subq.w	#1,d1
		and.w	#$ff,d0
		subq.w	#1,d0
loop_p1:
		move.l	a0,a2
		move.w	d1,d2
loop_p2:
		move.b	(a2)+,(a1)+
		dbra	d2,loop_p2
		dbra	d0,loop_p1

		addq.w	#1,d1
		add.w	d1,a0
end_rout:
		move.l	a1,d0
		sub.l	#linebuf,d0
		cmp.l	bperlineplane,d0
		blt	read_line
		rts



init_mouse:
		move.w	#320,mouse_x
		move.w	#240,mouse_y
		clr.w	mbut
		move.w	#-1,old_mouse_x			;no restore 1st time
		clr.w	new_scr				;no set screen
		clr.w	curr_mouse			;'full' mouse pointer

		lea	mousemask,a0
		lea	mousedata,a2
		move.w	#16*16-1,d0
loop_make_mask:
		move.w	(a2)+,d1
		or.w	(a2)+,d1
		or.w	(a2)+,d1
		or.w	(a2)+,d1
		move.w	d1,(a0)+
		dbra	d0,loop_make_mask

		move.w	#$22,-(sp)		;Kbdvbase()
		trap	#14
		addq.l	#2,sp
		move.l	d0,a0

		move.l	16(a0),old_mousevec
wait_drvstat:
		tst.w	36(a0)
		bne	wait_drvstat

		move.l	#mousevec,16(a0)

		move.l	$70,old_vbl_int
		move.l	#vbl_interrupt,$70

		rts

exit_mouse:
		move.l	old_vbl_int,$70

		move.w	#$22,-(sp)		;Kbdvbase()
		trap	#14
		addq.l	#2,sp
		move.l	d0,a0

wait_drvstat2:
		tst.w	36(a0)
		bne	wait_drvstat2

		move.l	old_mousevec,16(a0)

		rts

draw_mouse:
		move.w	mouse_x,d6
		move.w	mouse_y,d5
		move.w	d5,old_mouse_y
		move.w	d6,old_mouse_x

		lea	mousedata,a1
		move.w	curr_mouse,d0
		lsr.w	#1,d0
		lsl.w	#7,d0			;*16*(16/8*2)
		add.w	d0,a1
		move.l	a1,a2

		move.l	scr2,a0
		move.l	a0,old_mouse_scr
		move.w	d5,d0		;my
		move.w	d0,d2
		mulu.w	#b_line,d0
		add.l	d0,a0

		move.w	d6,d4		;mx
		move.w	d4,d0
		lsr.w	#4,d4		;in words
		lsl.w	#3,d4		;*planes *2

		add.w	d4,a0

		move.w	d0,d1
		and.b	#$f0,d1
		sub.w	d1,d0

		move.w	#15,d3
		add.w	#16-480,d2
		bmi	cont_m1
		sub.w	d2,d3
cont_m1:
		lea	mousemask,a2
		move.w	curr_mouse,d7
		lsr.w	#1,d7
		lsl.w	#5,d7
		add.w	d7,a2
		lea	mousesaved,a3

		tst.w	d0
		beq	loop_putm_noshift

		cmp.w	#b_line-8,d4
		bge	last_word1
loop_putm:
		REPT	4
		move.w	8(a0),d7
		swap	d7
		move.w	(a0)+,d7
		rol.l	d0,d7
		move.w	d7,(a3)+
		ENDM
		sub.w	#8,a0

		moveq	#0,d7
		move.w	(a2)+,d7
		ror.l	d0,d7
		not.l	d7
		and.w	d7,(a0)
		and.w	d7,2(a0)
		and.w	d7,4(a0)
		and.w	d7,6(a0)
		swap	d7
		and.w	d7,8(a0)
		and.w	d7,10(a0)
		and.w	d7,12(a0)
		and.w	d7,14(a0)

		REPT	4
		moveq	#0,d7
		move.w	(a1)+,d7
		ror.l	d0,d7
		or.w	d7,(a0)+
		swap	d7
		or.w	d7,6(a0)
		ENDM

		add.w	#b_line-8,a0
		dbra	d3,loop_putm

		bra	end_putm

last_word1:
loop_putm2:
		REPT	4
		moveq	#0,d7
		move.w	(a0)+,d7
		rol.l	d0,d7
		move.w	d7,(a3)+
		ENDM
		sub.w	#8,a0

		moveq	#0,d7
		move.w	(a2)+,d7
		ror.l	d0,d7
		not.l	d7
		and.w	d7,(a0)
		and.w	d7,2(a0)
		and.w	d7,4(a0)
		and.w	d7,6(a0)

		REPT	4
		moveq	#0,d7
		move.w	(a1)+,d7
		ror.l	d0,d7
		or.w	d7,(a0)+
		ENDM

		add.w	#b_line-8,a0
		dbra	d3,loop_putm2
		bra	end_putm
loop_putm_noshift:
		move.l	(a0),(a3)+
		move.l	4(a0),(a3)+

		move.w	(a2)+,d7
		not.w	d7
		and.w	d7,(a0)
		and.w	d7,2(a0)
		and.w	d7,4(a0)
		and.w	d7,6(a0)

		move.l	(a1)+,d7
		or.l	d7,(a0)+
		move.l	(a1)+,d7
		or.l	d7,(a0)+

		add.w	#b_line-8,a0
		dbra	d3,loop_putm_noshift

end_putm:
		rts

remove_mouse:
		move.w	old_mouse_x,d6
		move.w	old_mouse_y,d5
		cmp.w	#-1,d6
		beq	end_remm

		move.l	old_mouse_scr,a0
		move.w	d5,d0		;omy
		move.w	d0,d2
		mulu.w	#b_line,d0
		add.l	d0,a0

		move.w	d6,d4		;omx
		move.w	d4,d0
		lsr.w	#4,d4
		lsl.w	#2,d4		;*planes
		add.w	d4,d4		;in bytes

		add.w	d4,a0

		move.w	d0,d1
		and.b	#$f0,d1
		sub.w	d1,d0

		move.w	#15,d3
		add.w	#16-480,d2
		bmi	cont_rm1
		sub.w	d2,d3
cont_rm1:
		lea	mousesaved,a1
		tst.w	d0
		beq	loop_remm_noshift
		move.l	#$ffff0000,d7	;mask
		ror.l	d0,d7
loop_remm:
		and.w	d7,(a0)
		and.w	d7,2(a0)
		and.w	d7,4(a0)
		and.w	d7,6(a0)
		cmp.w	#b_line-8,d4
		bge	cont_rm3
		swap	d7
		and.w	d7,8(a0)
		and.w	d7,10(a0)
		and.w	d7,12(a0)
		and.w	d7,14(a0)
		swap	d7
cont_rm3:
		move.w	#3,d6
loop_remm2:
		moveq	#0,d5
		move.w	(a1)+,d5
		ror.l	d0,d5
		or.w	d5,(a0)+
		cmp.w	#b_line-8,d4
		bge	cont_rm2
		swap	d5
		or.w	d5,6(a0)
cont_rm2:
		dbra	d6,loop_remm2

		add.w	#b_line-8,a0
		dbra	d3,loop_remm

		bra	end_remm
loop_remm_noshift:
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+

		add.w	#b_line-8,a0
		dbra	d3,loop_remm_noshift
end_remm:

		rts

mousevec:
		move.w	d0,-(sp)
		move.b	1(a0),d0
		ext.w	d0
		add.w	mouse_x,d0
		bge	cont_mv1
		clr.w	d0
cont_mv1:	cmp.w	#639,d0
		ble	cont_mv2
		move.w	#639,d0
cont_mv2:	move.w	d0,mouse_x
		move.b	2(a0),d0
		ext.w	d0
		add.w	mouse_y,d0
		bge	cont_mv3
		clr.w	d0
cont_mv3:	cmp.w	#479,d0
		ble	cont_mv4
		move.w	#479,d0
cont_mv4:	move.w	d0,mouse_y
		move.b	(a0),d0
		and.w	#3,d0
		move.w	d0,mbut
		move.w	(sp)+,d0
		rts

vbl_interrupt:
		movem.l	d0-d7/a0-a3,-(sp)

		tst.l	link_col
		beq	no_newlinkcol
		move.l	link_col,$ffff9800+9*4
		clr.l	link_col
no_newlinkcol:

		move.w	mouse_x,d6
		move.w	mouse_y,d5

		tst.w	mbut			;mousebutton pressed?
		bne	m_not_same		;don't fade out

		cmp.w	old_mouse_x,d6		;
		bne	m_not_same		;
		cmp.w	old_mouse_y,d5		;mouse moved?
		bne	m_not_same		;don't fade out

		add.w	#1,mouse_count
		move.w	mouse_count,d0
		cmp.w	#100,d0			;100 vbl's
		ble	m_same
		move.w	curr_mouse,d0
		cmp.w	#30,d0
		beq	m_same
		add.w	#1,curr_mouse		;fade out

		bra	m_same
m_not_same:
		clr.w	mouse_count		;wait for 100 vbl's again
		clr.w	curr_mouse		;full pointer again
m_same:
		bsr	remove_mouse

		tst.w	new_scr
		beq	no_new_scr

		move.l	scr1,a0
		move.l	scr2,scr1
		move.l	a0,scr2			;swap pointers
		move.l	scr1,scr

		move.b	scr2+1,$ffff8201
		move.b	scr2+2,$ffff8203
		move.b	scr2+3,$ffff820d
		clr.l	new_scr			;not again
no_new_scr:

		bsr	draw_mouse

		movem.l	(sp)+,d0-d7/a0-a3
		add.l	#1,_frclock		;don't forget this!
		rte



;d0=x,d1=y,a6=scr
	MACRO	draw_point
		mulu.w	#b_line,d1
		move.w	d0,d2
		and.w	#$f,d2
		and.b	#$f0,d0
		lsr.w	#1,d0
		ext.l	d0
		add.l	d0,d1
		moveq	#0,d0
		neg.w	d2
		add.w	#15,d2
		bset	d2,d0
		;move.w	d0,d1
		;not.w	d1

		;color 10 : green

		;and.w	d1,(a6,d1.l)		;these bitplanes don't change
		or.w	d0,2(a6,d1.l)
		;and.w	d1,4(a6,d1.l)
		or.w	d0,6(a6,d1.l)
	ENDM

draw_leftright:
		move.l	scr,a6			;for draw_point
		lea	lr_coor,a4		;coordinates calculated before while waiting for vertical blank
		tst.w	(a4)+
		beq	draw_dots

		;put left-right lines
		clr.w	d5			;init for dotted line
loop_put_lr:
		move.w	(a4)+,d0
		move.w	(a4)+,d1
		move.w	(a4),d2
		bmi	end_put_lr		;-1:last point
		move.w	2(a4),d3
		bchg	#0,d5			;don't draw same pixel twice
		bsr	draw_line
		bra	loop_put_lr

draw_dots:
loop_put_lr2:
		move.w	(a4)+,d0
		bmi	end_put_lr		;-1:last point
		move.w	(a4)+,d1
		draw_point
		bra	loop_put_lr2

end_put_lr:
		rts


;Draw line using Bresenham line plot algorithm:
;
;	..
;	..
;	e:=2*deltay-deltax;
;	for i:=0 to deltax do begin
;		Plot(x,y);
;		if e>0 then begin
;			y:=y+1;
;			e:=e+2*deltay-2*deltax;
;		end
;		else
;			e:=e+2*deltay;
;		x:=x+1;
;	end;
;	..
;	..
;

;draw dotted line (10101010...)
;d0=x1,d1=y1,d2=x2,d3=y2
;a6=screen address (used in macro draw_point)
draw_line:
		cmp.w	d2,d0		;x2,x1
		ble	cont_dl1	;x2>=x1
		move.w	d2,d7		;x2
		move.w	d0,d2
		move.w	d7,d0
		move.w	d3,d7		;y2
		move.w	d1,d3
		move.w	d7,d1
cont_dl1:
		move.w	d2,d6		;x2
		sub.w	d0,d6		;x2-x1=deltax
		move.w	d3,d7		;y2
		sub.w	d1,d7		;y2-y1=deltay

		cmp.w	d3,d1		;y2,y1
		ble	cont_dl2	;y2>=y1

		neg.w	d7		;deltay=-deltay
		cmp.w	d7,d6		;deltay,deltax
		bge	cont_dl3	;deltay<=deltax

		move.w	d0,a0		;x1
		move.w	d1,a1		;y1
		move.w	d6,d3		;e=deltax
		add.w	d3,d3		;*2
		sub.w	d7,d3		;-deltay
		move.w	d7,d4		;deltay

		add.w	d6,d6		;2*deltax
		add.w	d7,d7		;2*deltay
loop_dl1:
		bchg	#0,d5		;make dotted line
		beq	no_drawpoint1
		move.w	a0,d0		;x
		move.w	a1,d1		;y
		draw_point
no_drawpoint1:
		tst.w	d3		;e
		ble	cont_dl5	;e<=0
		addq.w	#1,a0		;x+=1
		add.w	d6,d3		;e=e+(2*deltax-2*deltay)
		sub.w	d7,d3
		bra	cont_dl6
cont_dl5:				;e<=0
		add.w	d6,d3		;e=e+2*deltax
cont_dl6:
		subq.w	#1,a1		;y-=1

		dbra	d4,loop_dl1

		rts


cont_dl3:				;deltay<=deltax

		move.w	d0,a0		;x1
		move.w	d1,a1		;y1
		move.w	d7,d3		;e=deltay
		add.w	d3,d3		;*2
		sub.w	d6,d3		;-deltax
		move.w	d6,d4		;deltax

		add.w	d6,d6		;2*deltax
		add.w	d7,d7		;2*deltay
loop_dl2:
		bchg	#0,d5		;make dotted line
		beq	no_drawpoint2
		move.w	a0,d0		;x
		move.w	a1,d1		;y
		draw_point
no_drawpoint2:
		tst.w	d3		;e
		ble	cont_dl7	;e<=0
		subq.w	#1,a1		;y-=1
		add.w	d7,d3		;e=e+(2*deltay-2*deltax)
		sub.w	d6,d3
		bra	cont_dl8
cont_dl7:				;e<=0
		add.w	d7,d3		;e=e+2*deltay
cont_dl8:
		addq.w	#1,a0		;x+=1

		dbra	d4,loop_dl2

		rts
cont_dl2:				;y2>=y1
		cmp.w	d7,d6		;deltay,deltax
		bge	cont_dl4	;deltay<=deltax


		move.w	d0,a0		;x1
		move.w	d1,a1		;y1
		move.w	d6,d3		;e=deltax
		add.w	d3,d3		;*2
		sub.w	d7,d3		;-deltay
		move.w	d7,d4		;deltay

		add.w	d6,d6		;2*deltax
		add.w	d7,d7		;2*deltay
loop_dl3:
		bchg	#0,d5		;make dotted line
		beq	no_drawpoint3
		move.w	a0,d0		;x
		move.w	a1,d1		;y
		draw_point
no_drawpoint3:
		tst.w	d3		;e
		ble	cont_dl9	;e<=0
		addq.w	#1,a0		;x+=1
		add.w	d6,d3		;e=e+(2*deltax-2*deltay)
		sub.w	d7,d3
		bra	cont_dl10
cont_dl9:				;e<=0
		add.w	d6,d3		;e=e+2*deltax
cont_dl10:
		addq.w	#1,a1		;y+=1

		dbra	d4,loop_dl3

		rts
cont_dl4:				;deltay<=deltax

		move.w	d0,a0		;x1
		move.w	d1,a1		;y1
		move.w	d7,d3		;e=deltay
		add.w	d3,d3		;*2
		sub.w	d6,d3		;-deltax
		move.w	d6,d4		;deltax

		add.w	d6,d6		;2*deltax
		add.w	d7,d7		;2*deltay
loop_dl4:
		bchg	#0,d5		;make dotted line
		beq	no_drawpoint4
		move.w	a0,d0		;x
		move.w	a1,d1		;y
		draw_point
no_drawpoint4:
		tst.w	d3		;e
		ble	cont_dl11	;e<=0
		addq.w	#1,a1		;y+=1
		add.w	d7,d3		;e=e+(2*deltay-2*deltax)
		sub.w	d6,d3
		bra	cont_dl12
cont_dl11:				;e<=0
		add.w	d7,d3		;e=e+2*deltay
cont_dl12:
		addq.w	#1,a0		;x+=1

		dbra	d4,loop_dl4

		rts


		data


wrong_scr_txt:	dc.b	'[3][Sorry...|Music Analyzer cannot|run on a monochrome monitor][Exit]',0
snd_locked_txt: dc.b	'[3][Sound System locked !][Exit|Ignore]',0
dsp_locked_txt: dc.b	'[3][DSP locked !][Exit|Ignore]',0
outofmem_txt:	dc.b	'[3][Out of memory !][Exit]',0
outofmem_txt2:	dc.b	'[3][Out of DSP memory !][Exit]',0
wrong_mach_txt: dc.b	'[3][Sorry...|Music Analyzer can only run|on an Atari 680x0 (x>=3)|machine with DSP, Codec and|Connection Matrix (a Falcon!)][Exit]',0
better_vga_txt:	dc.b	'[1][If you want this program|to look even better|(or just wanna read the|texts), buy yourself a|VGA monitor !][ ... ]',0

		even


		;Use the linker (see 'M_ANALYZ.PRJ')
		IMPORT	log, log2, dsp_bin, end_of_dspbin
		IMPORT	mainscrdat, iconsdat, mousedat, helpdat, rotfalcdat
		IMPORT	regs_vga, regs_tv50, regs_tv60

		;If you don't use a linker
;		even
;		include 'vid_regs.s'
;		even
;		include	'log_vu.s'
;		even
;		include	'log_spec.s'
;		even
;		include	'dsp_bin.s'
;		even
;mainscrdat:	incbin	'mainscr.img'
;		even
;helpdat:	incbin	'help.img'
;		even
;iconsdat:	incbin	'icons.img'
;		even
;mousedat:	incbin	'mouse.img'
;		even
;rotfalcdat:	incbin	'rotfalc.img'
;		even


;relative coordinates for vu-meters
;0 to 90 degrees
vu_x:		DC.W	-31,-31,-30,-29,-29,-28,-28,-27
		DC.W	-26,-26,-25,-25,-24,-23,-23,-22
		DC.W	-21,-21,-20,-19,-19,-18,-17,-16
		DC.W	-16,-15,-14,-14,-13,-12,-11,-11
		DC.W	-10,-9,-8,-8,-7,-6,-5,-5
		DC.W	-4,-3,-2,-2,-1, 0, 1, 2
		DC.W	 2, 3, 4, 5, 5, 6, 7, 8
		DC.W	 8, 9, 10, 11, 11, 12, 13, 14
		DC.W	 14, 15, 16, 16, 17, 18, 19, 19
		DC.W	 20, 21, 21, 22, 23, 23, 24, 25
		DC.W	 25, 26, 26, 27, 28, 28, 29, 29
		DC.W	 30, 31, 31
vu_y:		DC.W	-31,-32,-32,-33,-33,-34,-34,-35
		DC.W	-35,-36,-36,-36,-37,-37,-38,-38
		DC.W	-38,-39,-39,-40,-40,-40,-41,-41
		DC.W	-41,-41,-42,-42,-42,-42,-43,-43
		DC.W	-43,-43,-43,-43,-43,-44,-44,-44
		DC.W	-44,-44,-44,-44,-44,-44,-44,-44
		DC.W	-44,-44,-44,-44,-44,-44,-43,-43
		DC.W	-43,-43,-43,-43,-43,-42,-42,-42
		DC.W	-42,-41,-41,-41,-41,-40,-40,-40
		DC.W	-39,-39,-38,-38,-38,-37,-37,-36
		DC.W	-36,-36,-35,-35,-34,-34,-33,-33
		DC.W	-32,-32,-31


aespb:		dc.l	contrl,global,int_in,int_out,addr_in,addr_out

		bss

mouse_x:	ds.w	1
mouse_y:	ds.w	1
mouse_but:	ds.w	1
old_mouse_x:	ds.w	1
old_mouse_y:	ds.w	1
curr_mouse:	ds.w	1
mousedata:	ds.b	8*256
mousemask:	ds.w	16*16
mousesaved:	ds.w	16*4
new_scr:	ds.w	1
old_mouse_scr:	ds.l	1
mouse_count:	ds.w	1
mbut:		ds.w	1
old_mousevec:	ds.l	1
old_vbl_int:	ds.l	1
link_col:	ds.l	1
link_color:	ds.l	1
old_link:	ds.w	1

linebuf:	ds.b	80
dest:		ds.l	1
patt_len:	ds.w	1
repeat:		ds.w	1
bytesperline:	ds.l	1
bperlineplane:	ds.l	1
lines:		ds.w	1

int_in:		ds.w	16
int_out:	ds.w	7
contrl:		ds.w	5
global:		ds.w	15
addr_in:	ds.l	2
addr_out:	ds.l	1

icon1x:		ds.w	1
icon1y:		ds.w	1
icon1n:		ds.w	1
icon2x:		ds.w	1
icon2y:		ds.w	1
icon2n:		ds.w	1

scr1:		ds.l	1
scr2:		ds.l	1
scr:		ds.l	1
scopebuf:	ds.l	1
icons:		ds.l	1
rotfalc:	ds.l	1
rotfalccnt:	ds.w	1
vubuf:		ds.l	1
lrbuf:		ds.l	1
clipbuf_on:	ds.b	9*4*4
clipbuf_off:	ds.b	9*4*4
lr_coor:	ds.w	points*2+2
leftrightwhich:	ds.w	1
helpdiag:	ds.l	1
helpdiag_on:	ds.w	1
hdiagsave:	ds.l	1
helpdiag_cnt:	ds.w	1
restdiag_count:	ds.w	1
mstext1:	ds.b	12*64/8*4
mstext2:	ds.b	12*64/8*4
mstxtwhich:	ds.w	1
bufstepsize:	ds.w	1
freeze:		ds.w	1
buf:		ds.b	6
leftbuf:	ds.b	buflen*3
rightbuf:	ds.b	buflen*3
leftclip:	ds.b	3
rightclip:	ds.b	3
buf2:		ds.b	14*3*2
dummybuf:	ds.b	buflen*3*2+6
left_bars:	ds.w	14
right_bars:	ds.w	14
bar_patt1:	ds.l	2
bar_patt2:	ds.l	2
leftvu: 	ds.w	1
rightvu:	ds.w	1
old_sndstate:	ds.w	7
old_speaker:	ds.w	1
palet:		ds.l	16
old_palet:	ds.l	256
old_stpalet:	ds.w	16
ability:	ds.w	1
xmem:		ds.l	1
ymem:		ds.l	1
sendbuf:	ds.l	1
lgain:		ds.w	1
rgain:		ds.w	1
speaker:	ds.w	1
leftspect:	ds.w	14
rightspect:	ds.w	14
shift:		ds.w	1
old_mode:	ds.w	1
old_regs:	ds.w	24
old_scrlen:	ds.l	1
old_physscr: 	ds.l	1
old_logscr: 	ds.l	1
monitor:	ds.w	1
pal:		ds.w	1
old_hz200:	ds.l	1
oldconterm:	ds.w	1
old_superstack:	ds.l	1
old_capslock:	ds.w	1
save_cacr:	ds.w	1

		end
