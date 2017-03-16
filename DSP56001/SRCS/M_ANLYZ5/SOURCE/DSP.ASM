;                   Music Analyzer
;               by Roel van de Kraats
;                       1995
;                   DSP Program

;tabsize=8

I_SSIRD 	equ	$000C
I_SSIRDE	equ	$000E

M_BCR		equ	$FFFE
M_PBC		equ	$FFE0
M_PCC		equ	$FFE1
HCR		equ	$FFE8
HSR		equ	$FFE9
HRX		equ	$FFEB
HTX		equ	$FFEB

M_RX		equ	$FFEF
M_CRA		equ	$FFEC
M_CRB		equ	$FFED
M_SR		equ	$FFEE
M_IPR		equ	$FFFF
M_UU		equ	$FFEA	;unused memory

VMAIN		equ	$0040
POINTS		equ	1024

maxncoef	equ	80

		ORG	Y:0

;Lowpass Filter, top 2200 Hz.
;Sample frequency: 32780 Hz.
;57 coefficients
;Using Hamming Windowing
n_lp2200	equ	57
c_lp2200
		dc $fffc55,$000db2,$001f0b,$002c26,$002e04,$001cf3,$fff522,$ffbbe1,$ff825a,$ff6310,$ff792d
		dc $ffd3b3,$00695d,$01130c,$01918c,$019fa5,$010c84,$ffd63b,$fe3a13,$fcb22c,$fbdd3d,$fc54a2
		dc $fe7bca,$0257ea,$077e2a,$0d2070,$123812,$15c403,$170969,$15c403,$123812,$0d2070,$077e2a
		dc $0257ea,$fe7bca,$fc54a2,$fbdd3d,$fcb22c,$fe3a13,$ffd63b,$010c84,$019fa5,$01918c,$01130c
		dc $00695d,$ffd3b3,$ff792d,$ff6310,$ff825a,$ffbbe1,$fff522,$001cf3,$002e04,$002c26,$001f0b
		dc $000db2,$fffc55
;Lowpass Filter, top 528 Hz.
;Sample frequency: 8195 Hz.
;59 coefficients
;Using Hamming Windowing
n_lp528		equ	59
c_lp528
		dc $000373,$0012d5,$00209d,$002935,$00271d,$0014c6,$fff010,$ffbe0d,$ff8ccd,$ff7169,$ff81b5
		dc $ffcae8,$004870,$00dedd,$015e68,$018e52,$013f42,$005fc5,$ff0c1a,$fd92d1,$fc6a3f,$fc1738
		dc $fd0a4f,$ff7ca8,$0356b4,$082974,$0d3e1e,$11b9f3,$14cdf2,$15e671,$14cdf2,$11b9f3,$0d3e1e
		dc $082974,$0356b4,$ff7ca8,$fd0a4f,$fc1738,$fc6a3f,$fd92d1,$ff0c1a,$005fc5,$013f42,$018e52
		dc $015e68,$00dedd,$004870,$ffcae8,$ff81b5,$ff7169,$ff8ccd,$ffbe0d,$fff010,$0014c6,$00271d
		dc $002935,$00209d,$0012d5,$000373

;Highpass Filter, top 15000 Hz.
;Sample frequency: 32780 Hz.
;15 coefficients
;Using Hamming Windowing
n_15000		equ	15
c_15000
		dc $ffcae4,$ff9704,$020d40,$fd15d4,$fdd585,$0fc914,$e01075,$27425a,$e01075,$0fc914,$fdd585
		dc $fd15d4,$020d40,$ff9704,$ffcae4
;Bandpass Filter, top 9300 Hz.
;Sample frequency: 32780 Hz.
;31 coefficients
;Using Hamming Windowing
n_9300		equ	31
c_9300
		dc $0030d6,$0029f3,$ffc0b2,$ff8317,$004efa,$013d7a,$fff948,$fdc3e8,$ff48b2,$020bfc,$074680
		dc $f90092,$ef3fdd,$18d0b4,$0a2c67,$db1b73,$0a2c67,$18d0b4,$ef3fdd,$f90092,$074680,$020bfc
		dc $ff48b2,$fdc3e8,$ffa032,$013d7a,$004efa,$ff8317,$ffc0b2,$0029f3,$0030d6
;Bandpass Filter, top 5800 Hz.
;Sample frequency: 32780 Hz.
;49 coefficients
;Using Hamming Windowing
n_5800		equ	49
c_5800
		dc $001fd6,$002234,$000b26,$ffded1,$ffb664,$ffbc08,$000a3f,$0081cb,$00c3ea,$006f33,$ff44a0
		dc $fea8b3,$ff07b2,$ffbc32,$0091fc,$02b6e0,$04adc0,$00e4bf,$f75a17,$f45da2,$01886c,$11fe5d
		dc $0e4f15,$f709fc,$e9247c,$f709fc,$0e4f15,$11fe5d,$01886c,$f45da2,$f75a17,$00e4bf,$04adc0
		dc $02b6e0,$0091fc,$ffbc32,$ff07b2,$fea8b3,$ff44a0,$0051e5,$00c3ea,$0081cb,$000a3f,$ffbc08
		dc $ffb664,$ffded1,$000b26,$002234,$001fd6
;Bandpass Filter, top 3600 Hz.
;Sample frequency: 32780 Hz.
;77 coefficients
;Using Hamming Windowing
n_3600		equ	77
c_3600
		dc $0015e6,$0012d9,$000a51,$fffcec,$ffeca4,$ffdd49,$ffd452,$ffd780,$ffeaa3,$000d0a,$0037e0
		dc $005e70,$007101,$0061da,$002b34,$ffd3de,$ff5614,$ff2862,$ff3a7b,$ff8172,$ffd965,$002b84
		dc $008fd1,$01374f,$02194c,$02aaed,$020512,$ff94ee,$fbebec,$f8f0d6,$f8fb1d,$fd307a,$043eac
		dc $0a907e,$0c359e,$076ffb,$fe2d1f,$f53c82,$f1904e,$f53c82,$fe2d1f,$076ffb,$0c359e,$0a907e
		dc $043eac,$fd307a,$f8fb1d,$f8f0d6,$fbebec,$ff94ee,$020512,$02aaed,$02194c,$01374f,$008fd1
		dc $002b84,$ffd965,$ff8172,$ff3a7b,$ff2862,$ff5614,$ffaf9f,$002b34,$0061da,$007101,$005e70
		dc $0037e0,$000d0a,$ffeaa3,$ffd780,$ffd452,$ffdd49,$ffeca4,$fffcec,$000a51,$0012d9,$0015e6
;Highpass Filter, top 2200 Hz.
;Sample frequency: 8195 Hz.
;33 coefficients
;Using Hamming Windowing
n_2200		equ	33
c_2200
		dc $ffde63,$ffc8a8,$0012b7,$007e5d,$002fff,$ff1355,$feffee,$012278,$029550,$ff98e7,$fb2dc2
		dc $fda79d,$0738fa,$096a6e,$f6eaed,$d8c670,$49c89e,$d8c670,$f6eaed,$096a6e,$0738fa,$fda79d
		dc $fb2dc2,$ff98e7,$029550,$012278,$feffee,$ff1355,$002fff,$007e5d,$0012b7,$ffc8a8,$ffde63

;Lowpass Filter, top 126 Hz.
;Sample frequency: 2049 Hz.
;63 coefficients
;Using Hamming Windowing
n_lp126		equ	63
c_lp126
		dc $fffca1,$000ac2,$00191c,$002527,$002a9c,$00242d,$000da3,$ffe6d3,$ffb61c,$ff8905,$ff71f8
		dc $ff82f3,$ffc663,$003860,$00c2fd,$013fef,$018074,$015a6a,$00b794,$ffa2a7,$fe4d99,$fd0df1
		dc $fc4e36,$fc76d0,$fdd34d,$007ac4,$0441ef,$08bba1,$0d48ec,$113628,$13debe,$14cf67,$13debe
		dc $113628,$0d48ec,$08bba1,$0441ef,$007ac4,$fdd34d,$fc76d0,$fc4e36,$fd0df1,$fe4d99,$ffa2a7
		dc $00b794,$015a6a,$018074,$013fef,$00c2fd,$003860,$ffc663,$ff82f3,$ff71f8,$ff8905,$ffb61c
		dc $ffe6d3,$000da3,$00242d,$002a9c,$002527,$00191c,$000ac2,$fffca1

;Bandpass Filter, top 1400 Hz.
;Sample frequency: 8195 Hz.
;49 coefficients
;Using Hamming Windowing
n_1400		equ	49
c_1400
		dc $001f13,$000a4f,$ffe804,$ffc7d2,$ffc52b,$fff75d,$005409,$009f81,$0087d8,$ffaa66,$fef2a2
		dc $fef880,$ff78ae,$ffe9c9,$011d73,$03a318,$04265e,$fe45bf,$f5bafa,$f67802,$04c774,$120e2c
		dc $0c002a,$f67aeb,$ea60ac,$f67aeb,$0c002a,$120e2c,$04c774,$f67802,$f5bafa,$fe45bf,$04265e
		dc $03a318,$011d73,$ffe9c9,$ff78ae,$fef880,$fef2a2,$ffaa66,$007da9,$009f81,$005409,$fff75d
		dc $ffc52b,$ffc7d2,$ffe804,$000a4f,$001f13
;Bandpass Filter, top 852 Hz.
;Sample frequency: 8195 Hz.
;61 coefficients
;Using Hamming Windowing
n_852		equ	61
c_852
		dc $00152f,$001d07,$002033,$001c2e,$000e0f,$fff463,$ffd16c,$ffacaa,$ff9298,$ff91ee,$ffb6c6
		dc $0004c8,$00726f,$00c225,$00fa11,$011c72,$012bd9,$00fe1b,$0028de,$fe53a8,$fbd423,$fa0357
		dc $fab71b,$feebae,$058094,$0b32ff,$0c483f,$070b9d,$fd63be,$f42763,$f05e06,$f42763,$fd63be
		dc $070b9d,$0c483f,$0b32ff,$058094,$feebae,$fab71b,$fa0357,$fbd423,$fe53a8,$0028de,$00fe1b
		dc $012bd9,$011c72,$00fa11,$00c225,$00773c,$0004c8,$ffb6c6,$ff91ee,$ff9298,$ffacaa,$ffd16c
		dc $fff463,$000e0f,$001c2e,$002033,$001d07,$00152f


		ORG	Y:$200

;Program memory here (Y memory overlaps P memory)
		ds	$300


;Highpass Filter, top 528 Hz.
;Sample frequency: 2049 Hz.
;25 coefficients
;Using Hamming Windowing
n_528		equ	25
c_528
		dc $ffc677,$ffb6c6,$002a06,$00f87d,$009c7c,$fe310c,$fcc281,$00c59b,$07b050,$060f4d,$f3e402
		dc $da3b2c,$4df9ac,$da3b2c,$f3e402,$060f4d,$07b050,$00c59b,$fcc281,$fe310c,$009c7c,$00f87d
		dc $002a06,$ffb6c6,$ffc677
;Bandpass Filter, top 328 Hz.
;Sample frequency: 2049 Hz.
;41 coefficients
;Using Hamming Windowing
n_328		equ	41
c_328
		dc $001491,$002cfc,$003520,$001b2c,$ffd425,$ff7667,$ff4410,$ff8c58,$006941,$0136cd,$01ba10
		dc $01fa33,$00c87f,$fc3139,$f6ef5a,$f9af7c,$075588,$12b1b0,$0b25ba,$f4eb47,$e89f64,$f4eb47
		dc $0b25ba,$12b1b0,$075588,$f9af7c,$f6ef5a,$fc3139,$00c87f,$01fa33,$01ba10,$0136cd,$007d52
		dc $ff8c58,$ff4410,$ff7667,$ffd425,$001b2c,$003520,$002cfc,$001491
;Bandpass Filter, top 202 Hz.
;Sample frequency: 2049 Hz.
;65 coefficients
;Using Hamming Windowing
n_202		equ	65
c_202
		dc $000fbc,$0018e1,$001ee2,$001fb1,$001897,$000746,$ffeb86,$ffc8c6,$ffa6d5,$ff9118,$ff93f9
		dc $ffb8f7,$000250,$006799,$00af9e,$00ec4a,$011823,$01325b,$011c6a,$00871f,$ff1f90,$fcf877
		dc $fae17c,$fa4373,$fc5caf,$013ab9,$072c49,$0b4383,$0ad931,$053f62,$fc85dc,$f4a980,$f183bf
		dc $f4a980,$fc85dc,$053f62,$0ad931,$0b4383,$072c49,$013ab9,$fc5caf,$fa4373,$fae17c,$fcf877
		dc $ff1f90,$00871f,$011c6a,$01325b,$011823,$00ec4a,$00af9e,$00671d,$000250,$ffb8f7,$ff93f9
		dc $ff9118,$ffa6d5,$ffc8c6,$ffeb86,$000746,$001897,$001fb1,$001ee2,$0018e1,$000fbc,$000000
;Highpass Filter, top 126 Hz.
;Sample frequency: 512 Hz.
;27 coefficients
;Using Hamming Windowing
n_126		equ	27
c_126
		dc $ffe163,$ffaf39,$ffda4d,$009b71,$0120b0,$ffe070,$fd5679,$fd482e,$026746,$082869,$0453ca
		dc $f222ed,$dafc58,$5053ce,$dafc58,$f222ed,$0453ca,$082869,$026746,$fd482e,$fd5679,$ffe070
		dc $0120b0,$009b71,$ffda4d,$ffaf39,$ffe163
;Bandpass Filter, top 78 Hz.
;Sample frequency: 512 Hz.
;43 coefficients
;Using Hamming Windowing
n_78		equ	43
c_78
		dc $001469,$002a4c,$00327f,$001ead,$ffe438,$ff9017,$ff5236,$ff6d6a,$000a5b,$01053e,$0183c1
		dc $01cdff,$01811b,$ff542a,$fa8d97,$f7356c,$fc5da3,$09a484,$120c95,$0905f7,$f47a09,$e9a066
		dc $f47a09,$0905f7,$120c95,$09a484,$fc5da3,$f7356c,$fa8d97,$ff542a,$01811b,$01cdff,$0183c1
		dc $00e6f4,$000a5b,$ff6d6a,$ff5236,$ff9017,$ffe438,$001ead,$00327f,$002a4c,$001469,$000000
;Bandpass Filter, top 48 Hz.
;Sample frequency: 512 Hz.
;69 coefficients
;Using Hamming Windowing
n_48		equ	69
c_48
		dc $000b6e,$0014cd,$001c1c,$001fbf,$001d6b,$0012bd,$fffe5f,$ffe153,$ffbfe9,$ffa1e1,$ff9155
		dc $ff9876,$ffbe6b,$000417,$0061c5,$00a57b,$00ded9,$0108ec,$01245c,$011f62,$00c195,$ffbfc8
		dc $fe01cc,$fbf238,$fa8fc9,$fb0d03,$fe14f4,$031d66,$084839,$0b14e1,$09a436,$03e26b,$fbdce9
		dc $f4f334,$f23b53,$f4f334,$fbdce9,$03e26b,$09a436,$0b14e1,$084839,$031d66,$fe14f4,$fb0d03
		dc $fa8fc9,$fbf238,$fe01cc,$ffbfc8,$00c195,$011f62,$01245c,$0108ec,$00ded9,$00a57b,$006200
		dc $000417,$ffbe6b,$ff9876,$ff9155,$ffa1e1,$ffbfe9,$ffe153,$fffe5f,$0012bd,$001d6b,$001fbf
		dc $001c1c,$0014cd,$000b6e
;Bandpass Filter, top 30 Hz.
;Sample frequency: 512 Hz.
;67 coefficients
;Using Hamming Windowing
n_30		equ	67
c_30
		dc $fff43b,$00045b,$0011f7,$001f16,$002893,$002a02,$001edd,$00179d,$fff8f8,$ffd6b6,$ffbdc9
		dc $ffbd7d,$ffe2fd,$0033cc,$00a8e8,$012c4f,$019a7d,$01c85d,$018d26,$00ce19,$ff894b,$fddc58
		dc $fc0470,$fa5698,$f930d3,$f8e6d7,$f9ae6c,$fb9006,$fe5fb3,$01c0aa,$05339e,$082d3a,$0a305a
		dc $0ae65f,$0a305a,$082d3a,$05339e,$01c0aa,$fe5fb3,$fb9006,$f9ae6c,$f8e6d7,$f930d3,$fa5698
		dc $fc0470,$fddc58,$ff894b,$00ce19,$018d26,$01c85d,$019a7d,$012c4f,$00a8e8,$0033cc,$ffe2fd
		dc $ffbd7d,$ffbdc9,$ffd6b6,$fff8f8,$00179d,$002aa2,$002a02,$002893,$001f16,$0011f7,$00045b
		dc $fff7fe

leftspec	ds	14
rightspec	ds	14
LeftClip	ds	1
RightClip	ds	1


		ORG	X:0
states		dsm	maxncoef
l_states1addr	ds	1
r_states1addr	ds	1
l_states4addr	ds	1
r_states4addr	ds	1
l_states16addr	ds	1
r_states16addr	ds	1
LeftAddr4	ds	1
RightAddr4	ds	1
LeftAddr16	ds	1
RightAddr16	ds	1
LeftAddr64	ds	1
RightAddr64	ds	1
CountL1		ds	1
CountL4		ds	1
CountL16	ds	1
CountR1		ds	1
CountR4		ds	1
CountR16	ds	1
OldLeftAddr	ds	1
OldRightAddr	ds	1
buf		ds	3
l_states1	dsm	n_lp2200
r_states1	dsm	n_lp2200
LeftInput64	dsm	POINTS/8
RightInput64	dsm	POINTS/8
LeftInput16	dsm	POINTS/4
RightInput16	dsm	POINTS/4
LeftInput4	dsm	POINTS/2
RightInput4	dsm	POINTS/2
LeftInput	dsm	POINTS*4
RightInput	dsm	POINTS*4
l_states4	dsm	n_lp528
r_states4	dsm	n_lp528
l_states16	dsm	n_lp126
r_states16	dsm	n_lp126
LastXMem


		ORG	P:0
		jmp	VMAIN

		ORG	P:I_SSIRD
		jsr	Receive

		ORG	P:I_SSIRDE
		jsr	RecErr

		ORG	P:VMAIN
		jmp	DoMain

RecErr		movep	x:M_SR,x:M_UU
		rti
Receive
		jclr	#3,X:M_SR,RecRight
		movep	x:M_RX,x:(r0)+
		rti
RecRight
		movep	x:M_RX,x:(r1)+
		rti


;#ncoef-1 in n5
;input in r2
;#buffer size-1 in m2
;coef in r4
;#calc size in n3
;returns maximum value in b
do_spec:
		move	n5,n2
		move	#states,r3
		move	x:(r2)-n2,x0	;substract n2 from r2 (using m2) : startup for filter
		move	n3,n2
		move	n5,m3
		move	x:(r2)-n2,x0	;substract n2 from r2 (using m2) : number of points to calculate

		do	n5,LoopSpec1
		move	x:(r2)+,x0
		move	x0,x:(r3)-	;initialize states buffer
LoopSpec1

		move	r4,r5
		move	r7,b		;clear maximum value

		do	n3,LoopSpec2
		move	r5,r4
		move	x:(r2)+,x0
		clr	a		x0,x:(r3)+	y:(r4)+,y0	
		;rep	n5	;using the repeat instruction gives
				;problems with the SSI interrupt,
				;because the rep instruction is not
				;interruptable. this is a little slower,
				;but at least it works
		do	n5,rep_spec
		mac	x0,y0,a 	x:(r3)+,x0	y:(r4)+,y0
rep_spec	macr	x0,y0,a 	(r3)-

		move	a,x0
		cmpm	x0,b		;|x0| > |b| ?
		tlt	x0,b		;then x0 -> b
LoopSpec2

		move	#0.35,x0
		move	n5,y0
		mpy	x0,y0,a

		do	a,LoopSpec3	;calculate some more points (for time shift)
		move	r5,r4
		move	r7,x0		;use 0 as input
		clr	a		x0,x:(r3)+	y:(r4)+,y0	
		;rep	n5
		do	n5,rep_spec_2
		mac	x0,y0,a 	x:(r3)+,x0	y:(r4)+,y0
rep_spec_2	macr	x0,y0,a 	(r3)-

		move	a,x0
		cmpm	x0,b
		tlt	x0,b
LoopSpec3

		abs	b		;maximum value

		rts





MakeLowerFreqs
		move	r1,x:buf+3	;save current right channel buffer pointer for later use

		;left channel

		move	m0,m2
		move	r0,b
		move	x:OldLeftAddr,r2	;here I stopped last time

		move	#>1,x1
		move	#>4,y1

		move	#n_lp2200-1,m3		;number of coefficients for first low-pass filter
		move	x:l_states1addr,r3	;here I stopped last time in states buffer

		move	#c_lp2200,r4		;address of coefficients
LoopLowerFreqL
		move	x:(r2)+,x0		;data point

		;32780 Hz -> 8195 Hz

		move	x:CountL1,a
		sub	x1,a
		move	a,x:CountL1
		jeq	LowFreqL4

		move	x0,x:(r3)-		;this is what the FIR filter routine does when output is not used

		jmp	EndLowFreqL
LowFreqL4

		clr	a		x0,x:(r3)+	y:(r4)+,y0
		do	#n_lp2200-1,loop_lfl1
		;rep	#n_lp2200-1
		mac	x0,y0,a 	x:(r3)+,x0	y:(r4)+,y0
loop_lfl1	mac	x0,y0,a 	(r3)-

		move	r3,x:l_states1addr


		move	#POINTS/2-1,m3
		move	x:LeftAddr4,r3
		move	y1,x:CountL1
		move	a,x:(r3)+
		move	r3,x:LeftAddr4


		;8195 -> 2049 Hz

		move	#n_lp528-1,m3
		move	x:l_states4addr,r3

		move	#c_lp528,r4
		move	a,x0

		move	x:CountL4,a
		sub	x1,a
		move	a,x:CountL4
		jeq	LowFreqL16

		move	x0,x:(r3)-
		move	r3,x:l_states4addr

		jmp	EndLowFreqL2
LowFreqL16

		clr	a		x0,x:(r3)+	y:(r4)+,y0
		do	#n_lp528-1,loop_lfl2
		;rep	#n_lp528-1
		mac	x0,y0,a 	x:(r3)+,x0	y:(r4)+,y0
loop_lfl2	mac	x0,y0,a 	(r3)-

		move	r3,x:l_states4addr


		move	#POINTS/4-1,m3
		move	x:LeftAddr16,r3
		move	y1,x:CountL4
		move	a,x:(r3)+
		move	r3,x:LeftAddr16


		;2049 -> 512 Hz

		move	#n_lp126-1,m3
		move	x:l_states16addr,r3

		move	#c_lp126,r4
		move	a,x0

		move	x:CountL16,a
		sub	x1,a
		move	a,x:CountL16
		jeq	LowFreqL64

		move	x0,x:(r3)-
		move	r3,x:l_states16addr

		jmp	EndLowFreqL2
LowFreqL64

		clr	a		x0,x:(r3)+	y:(r4)+,y0
		do	#n_lp126-1,loop_lfl3
		;rep	#n_lp126-1
		mac	x0,y0,a 	x:(r3)+,x0	y:(r4)+,y0
loop_lfl3	mac	x0,y0,a 	(r3)-

		move	r3,x:l_states16addr


		move	#POINTS/8-1,m3
		move	x:LeftAddr64,r3
		move	y1,x:CountL16
		move	a,x:(r3)+
		move	r3,x:LeftAddr64


EndLowFreqL2
		move	#n_lp2200-1,m3
		move	x:l_states1addr,r3
		move	#c_lp2200,r4

EndLowFreqL
		move	r2,x0
		cmp	x0,b
		jne	LoopLowerFreqL

		move	r3,x:l_states1addr
		move	b,x:OldLeftAddr


		;right channel


		move	x:buf+3,b
		move	x:OldRightAddr,r2

		move	#n_lp2200-1,m3
		move	x:r_states1addr,r3

		move	#c_lp2200,r4
LoopLowerFreqR
		move	x:(r2)+,x0

		;32780 Hz -> 8195 Hz

		move	x:CountR1,a
		sub	x1,a
		move	a,x:CountR1
		jeq	LowFreqR4

		move	x0,x:(r3)-

		jmp	EndLowFreqR
LowFreqR4

		clr	a		x0,x:(r3)+	y:(r4)+,y0
		do	#n_lp2200-1,loop_lfr1
		;rep	#n_lp2200-1
		mac	x0,y0,a 	x:(r3)+,x0	y:(r4)+,y0
loop_lfr1	mac	x0,y0,a 	(r3)-

		move	r3,x:r_states1addr


		move	#POINTS/2-1,m3
		move	x:RightAddr4,r3
		move	y1,x:CountR1
		move	a,x:(r3)+
		move	r3,x:RightAddr4


		;8195 -> 2049 Hz

		move	#n_lp528-1,m3
		move	x:r_states4addr,r3

		move	#c_lp528,r4
		move	a,x0

		move	x:CountR4,a
		sub	x1,a
		move	a,x:CountR4
		jeq	LowFreqR16

		move	x0,x:(r3)-
		move	r3,x:r_states4addr

		jmp	EndLowFreqR2
LowFreqR16

		clr	a		x0,x:(r3)+	y:(r4)+,y0
		do	#n_lp528-1,loop_lfr2
		;rep	#n_lp528-1
		mac	x0,y0,a 	x:(r3)+,x0	y:(r4)+,y0
loop_lfr2	mac	x0,y0,a 	(r3)-

		move	r3,x:r_states4addr


		move	#POINTS/4-1,m3
		move	x:RightAddr16,r3
		move	y1,x:CountR4
		move	a,x:(r3)+
		move	r3,x:RightAddr16


		;2049 -> 512 Hz

		move	#n_lp126-1,m3
		move	x:r_states16addr,r3

		move	#c_lp126,r4
		move	a,x0

		move	x:CountR16,a
		sub	x1,a
		move	a,x:CountR16
		jeq	LowFreqR64

		move	x0,x:(r3)-
		move	r3,x:r_states16addr

		jmp	EndLowFreqR2
LowFreqR64

		clr	a		x0,x:(r3)+	y:(r4)+,y0
		do	#n_lp126-1,loop_lfr3
		;rep	#n_lp126-1
		mac	x0,y0,a 	x:(r3)+,x0	y:(r4)+,y0
loop_lfr3	mac	x0,y0,a 	(r3)-

		move	r3,x:r_states16addr


		move	#POINTS/8-1,m3
		move	x:RightAddr64,r3
		move	y1,x:CountR16
		move	a,x:(r3)+
		move	r3,x:RightAddr64


EndLowFreqR2
		move	#n_lp2200-1,m3
		move	x:r_states1addr,r3
		move	#c_lp2200,r4

EndLowFreqR
		move	r2,x0
		cmp	x0,b
		jne	LoopLowerFreqR

		move	r3,x:r_states1addr
		move	b,x:OldRightAddr


		rts





DoMain
		jsr	init

MainLoop
		;get values for vu-meters

		;Calculate while waiting for command and keep updated
		;(worst timing case is host request when somewhere at the beginning of the wait loop)
		move	r0,r2
		move	r1,r3
		move	#POINTS,n2
		move	n2,n3
		move	x:(r2)-n2,x0		;substract n2 from r2
		move	x:(r3)-n3,x0

		move	r7,y0
		move	y0,b
		move	#$80000,y1
		move	x:(r2)+,a
		do	#POINTS,LoopMaxL
		sub	y0,a
		move	a,x0
		mpy	y1,x0,a			; * 1/16  ->  kind of a lowpass filter (new=old+(new-old)/16)
		add	y0,a
		move	a,y0
		cmpm	y0,b	x:(r2)+,a
		tlt	y0,b
LoopMaxL
		abs	b
		move	b,x:buf

		move	r7,y0
		move	y0,b
		move	x:(r3)+,a
		do	#POINTS,LoopMaxR
		sub	y0,a
		move	a,x0
		mpy	y1,x0,a
		add	y0,a
		move	a,y0
		cmpm	y0,b	x:(r3)+,a
		tlt	y0,b
LoopMaxR
		abs	b
		move	b,x:buf+1


		jclr	#0,x:<<HSR,MainLoop	;wait for command
		movep	x:<<HRX,a

		move	#$123456,x0		;'magic word' (necessary at program start)
		cmp	x0,a
		jne	MainLoop


		;send vu data
		jclr	#1,x:<<HSR,*
		movep	x:buf,x:<<HTX
		jclr	#1,x:<<HSR,*
		movep	x:buf+1,x:<<HTX


		;synchronize left and right channel
		move	r1,a
loop_synchr	move	r1,x0
		cmp	x0,a
		jeq	loop_synchr


		;send data for scope

		move	m0,m2
		move	m1,m3
		move	r0,r2
		move	#POINTS,n2
		move	n2,n3
		move	r1,r3
		move	x:(r2)-n2,x0		;substract n2 from r2
		move	x:(r3)-n3,x0



		move	#>$40,y0
		move	x:(r2)+,y1			;1st data point for first loop
		do	#(POINTS+2)/3,LoopSendScL
		mpy	y0,y1,a		x:(r2)+,b	;2nd data point
		asr	b
		move	b1,a0
		rep	#7
		asl	a
		asl	a		x:(r2)+,b	;3rd data point
		asr	b		x:(r2)+,y1	;1st data point for next loop
		move	b1,a0
		rep	#8
		asl	a
		jclr	#1,x:<<HSR,*
		movep	a1,x:<<HTX			;3 data points in a1
LoopSendScL
		move	x:(r3)+,y1
		do	#(POINTS+2)/3,LoopSendScR
		mpy	y0,y1,a		x:(r3)+,b
		asr	b
		move	b1,a0
		rep	#7
		asl	a
		asl	a		x:(r3)+,b
		asr	b		x:(r3)+,y1
		move	b1,a0
		rep	#8
		asl	a
		jclr	#1,x:<<HSR,*
		movep	a1,x:<<HTX
LoopSendScR


		;check for clipping
		move	r0,r2
		move	r1,r3
		move	#POINTS,n2
		move	n2,n3
		move	x:(r2)-n2,x0		;substract n2 from r2
		move	x:(r3)-n3,x0

		move	#$7fff00,x0		;upper border
		move	#$800000,x1		;lower border
		move	#>1,y0

		move	r7,y:LeftClip
		move	x:(r2)+,a		;first data point
		do	#POINTS,LoopClipL
		cmp	x0,a
		jlt	NoClipUpL
		move	y0,y:LeftClip		;set clipping on
		enddo
		jmp	LoopClipL
NoClipUpL
		cmp	x1,a
		jne	NoClipLowL
		move	y0,y:LeftClip
		enddo
		jmp	LoopClipL
NoClipLowL
		move	x:(r2)+,a		;data point for next loop
LoopClipL

		move	r7,y:RightClip
		move	x:(r3)+,a
		do	#POINTS,LoopClipR
		cmp	x0,a
		jlt	NoClipUpR
		move	y0,y:RightClip
		enddo
		jmp	LoopClipR
NoClipUpR
		cmp	x1,a
		jne	NoClipLowR
		move	y0,y:RightClip
		enddo
		jmp	LoopClipR
NoClipLowR
		move	x:(r3)+,a
LoopClipR




		;calculate values for spectrum

		move	r0,x:buf		;current left pointer
		move	r1,x:buf+1		;current right pointer
		move	m0,m2			;buffer length

		move	#n_15000-1,n5		;#ncoef-1
		move	x:buf,r2		;input data
		move	#c_15000,r4		;coef
		move	#POINTS/4,n3		;#calc size
		jsr	do_spec
		move	b,y:leftspec+13		;save result

		move	#n_15000-1,n5
		move	x:buf+1,r2
		move	#c_15000,r4
		move	#POINTS/4,n3
		jsr	do_spec
		move	b,y:rightspec+13


		move	#n_9300-1,n5
		move	x:buf,r2
		move	#c_9300,r4
		move	#POINTS/4,n3
		jsr	do_spec
		move	b,y:leftspec+12

		move	#n_9300-1,n5
		move	x:buf+1,r2
		move	#c_9300,r4
		move	#POINTS/4,n3
		jsr	do_spec
		move	b,y:rightspec+12


		move	#n_5800-1,n5
		move	x:buf,r2
		move	#c_5800,r4
		move	#POINTS/4,n3
		jsr	do_spec
		move	b,y:leftspec+11

		move	#n_5800-1,n5
		move	x:buf+1,r2
		move	#c_5800,r4
		move	#POINTS/4,n3
		jsr	do_spec
		move	b,y:rightspec+11


		move	#n_3600-1,n5
		move	x:buf,r2
		move	#c_3600,r4
		move	#POINTS/4,n3
		jsr	do_spec
		move	b,y:leftspec+10

		move	#n_3600-1,n5
		move	x:buf+1,r2
		move	#c_3600,r4
		move	#POINTS/4,n3
		jsr	do_spec
		move	b,y:rightspec+10



		jsr	MakeLowerFreqs


		move	x:LeftAddr4,r2
		move	x:RightAddr4,r3
		move	r2,x:buf
		move	r3,x:buf+1
		move	#POINTS/2-1,m2


		move	#n_2200-1,n5
		move	x:buf,r2
		move	#c_2200,r4
		move	#POINTS/12,n3
		jsr	do_spec
		move	b,y:leftspec+9

		move	#n_2200-1,n5
		move	x:buf+1,r2
		move	#c_2200,r4
		move	#POINTS/12,n3
		jsr	do_spec
		move	b,y:rightspec+9


		move	#n_1400-1,n5
		move	x:buf,r2
		move	#c_1400,r4
		move	#POINTS/12,n3
		jsr	do_spec
		move	b,y:leftspec+8

		move	#n_1400-1,n5
		move	x:buf+1,r2
		move	#c_1400,r4
		move	#POINTS/12,n3
		jsr	do_spec
		move	b,y:rightspec+8


		move	#n_852-1,n5
		move	x:buf,r2
		move	#c_852,r4
		move	#POINTS/12,n3
		jsr	do_spec
		move	b,y:leftspec+7

		move	#n_852-1,n5
		move	x:buf+1,r2
		move	#c_852,r4
		move	#POINTS/12,n3
		jsr	do_spec
		move	b,y:rightspec+7


		move	x:LeftAddr16,r2
		move	x:RightAddr16,r3
		move	r2,x:buf
		move	r3,x:buf+1
		move	#POINTS/4-1,m2


		move	#n_528-1,n5
		move	x:buf,r2
		move	#c_528,r4
		move	#POINTS/32,n3
		jsr	do_spec
		move	b,y:leftspec+6

		move	#n_528-1,n5
		move	x:buf+1,r2
		move	#c_528,r4
		move	#POINTS/32,n3
		jsr	do_spec
		move	b,y:rightspec+6


		move	#n_328-1,n5
		move	x:buf,r2
		move	#c_328,r4
		move	#POINTS/32,n3
		jsr	do_spec
		move	b,y:leftspec+5

		move	#n_328-1,n5
		move	x:buf+1,r2
		move	#c_328,r4
		move	#POINTS/32,n3
		jsr	do_spec
		move	b,y:rightspec+5


		move	#n_202-1,n5
		move	x:buf,r2
		move	#c_202,r4
		move	#POINTS/32,n3
		jsr	do_spec
		move	b,y:leftspec+4

		move	#n_202-1,n5
		move	x:buf+1,r2
		move	#c_202,r4
		move	#POINTS/32,n3
		jsr	do_spec
		move	b,y:rightspec+4


		move	x:LeftAddr64,r2
		move	x:RightAddr64,r3
		move	r2,x:buf
		move	r3,x:buf+1
		move	#POINTS/8-1,m2


		move	#n_126-1,n5
		move	x:buf,r2
		move	#c_126,r4
		move	#16,n3
		jsr	do_spec
		move	b,y:leftspec+3

		move	#n_126-1,n5
		move	x:buf+1,r2
		move	#c_126,r4
		move	#16,n3
		jsr	do_spec
		move	b,y:rightspec+3


		move	#n_78-1,n5
		move	x:buf,r2
		move	#c_78,r4
		move	#16,n3
		jsr	do_spec
		move	b,y:leftspec+2

		move	#n_78-1,n5
		move	x:buf+1,r2
		move	#c_78,r4
		move	#16,n3
		jsr	do_spec
		move	b,y:rightspec+2


		move	#n_48-1,n5
		move	x:buf,r2
		move	#c_48,r4
		move	#1,n3
		jsr	do_spec
		move	b,y:leftspec+1

		move	#n_48-1,n5
		move	x:buf+1,r2
		move	#c_48,r4
		move	#1,n3
		jsr	do_spec
		move	b,y:rightspec+1


		move	#n_30-1,n5
		move	x:buf,r2
		move	#c_30,r4
		move	#1,n3
		jsr	do_spec
		move	b,x0
		move	#0.2,x1
		macr	x0,x1,b			;pump up this frequency a little because of the falcon hardware (high-pass filter)
		move	b,y:leftspec

		move	#n_30-1,n5
		move	x:buf+1,r2
		move	#c_30,r4
		move	#1,n3
		jsr	do_spec
		move	b,x0
		move	#0.2,x1
		macr	x0,x1,b
		move	b,y:rightspec




		;wait for command

		jclr	#0,x:<<HSR,*
		movep	x:<<HRX,x0


		;send clipping information

		jclr	#1,x:<<HSR,*
		movep	y:LeftClip,x:<<HTX
		jclr	#1,x:<<HSR,*
		movep	y:RightClip,x:<<HTX


		;send data for spectrum

		move	#leftspec,r5
		move	#$40000,y0
		do	#14,LoopSendBarsL
		move	y:(r5)+,y1
		mpy	y0,y1,a			; * 1/32 (32768 -> 1024)
		jclr	#1,x:<<HSR,*
		movep	a,x:<<HTX
LoopSendBarsL

		move	#rightspec,r5
		do	#14,LoopSendBarsR
		move	y:(r5)+,y1
		mpy	y0,y1,a
		jclr	#1,x:<<HSR,*
		movep	a,x:<<HTX
LoopSendBarsR

		move	m0,m2
		move	m0,m3

		jmp	MainLoop


init

		reset
		ori	#$03,MR
		move	#LeftInput,r0
		move	#RightInput,r1
		move	#POINTS*4-1,m0
		move	m0,m1
		move	#0,r7

		move	#0,r5
		move	#LastXMem,x0
		rep	x0
		move	r7,x:(r5)+		;clear x memory


		move	#l_states1,r5
		move	r5,x:l_states1addr
		move	#r_states1,r5
		move	r5,x:r_states1addr
		move	#l_states4,r5
		move	r5,x:l_states4addr
		move	#r_states4,r5
		move	r5,x:r_states4addr
		move	#l_states16,r5
		move	r5,x:l_states16addr
		move	#r_states16,r5
		move	r5,x:r_states16addr

		move	#LeftInput,r5
		move	r5,x:OldLeftAddr
		move	#RightInput,r5
		move	r5,x:OldRightAddr
		move	#LeftInput4,r5
		move	r5,x:LeftAddr4
		move	#RightInput4,r5
		move	r5,x:RightAddr4
		move	#LeftInput16,r5
		move	r5,x:LeftAddr16
		move	#RightInput16,r5
		move	r5,x:RightAddr16
		move	#LeftInput64,r5
		move	r5,x:LeftAddr64
		move	#RightInput64,r5
		move	r5,x:RightAddr64

		move	#>4,x0
		move	x0,x:CountL1
		move	x0,x:CountL4
		move	x0,x:CountL16
		move	x0,x:CountR1
		move	x0,x:CountR4
		move	x0,x:CountR16


		movep	#$1,x:M_PBC
		movep	#$3000,x:M_IPR
		movep	#$4100,x:M_CRA
		movep	#$A800,x:M_CRB
		movep	#$0000,x:M_PCC
		movep	#$01F8,x:M_PCC
		movep	x:M_SR,x:M_UU
		movep	x:M_RX,x:M_SR
		andi	#$FC,MR			;enable interrupts

		move	m0,m2
		move	m0,m3

		rts
