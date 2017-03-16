PBC	equ	$ffe0
PCC	equ	$ffe1
SSITX	equ	$ffef
SSISR	equ	$ffee
CRA	equ	$ffec
CRB	equ	$ffed
BCR	equ	$fffe
HTX	equ	$ffeb
IPR	equ	$ffff

	ORG	P:0
	jmp	Main

	ORG	P:$10
	movep	Y:(r0)+,X:<<SSITX

	ORG	P:$40
Main	ori	#3,mr
	movep	#0,X:<<BCR
	movep	#$3000,X:<<IPR
	move	#$100,r0
	movec	#$ff,m0
	andi	#$fe,mr
	movep	#$1f8,X:<<PCC
	movep	#$4100,X:<<CRA
	movep	#$f800,X:<<CRB
	btst	#4,X:<<SSISR
	movep	Y:(r0)+,X:<<SSITX
Loop	jmp	Loop
	END
