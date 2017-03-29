
; essai1.s
  	DATA	


	CODE
boucle:
	move.l  #12   ,d3
	;;  dépassement de capacité:	65538 > 2^16
	move.l	#65538,d3 
	move.l  d3, d4
	bra boucle2
        bra boucle
boucle2:rts
