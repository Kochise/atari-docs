*	Programme d'exemple d'utilisation d'un module ex‚cutable
*	du YM-Tracker.
*			Assembleur 68000
*----------------------------------------------------------------

	pea	bonjour(pc)		;message d'entr‚e
	move.w	#9,-(a7)		;print
	trap	#1
	addq.l	#6,a7
	
	move.w	#7,-(a7)		;attente d'une touche au clavier
	trap	#1
	addq.l	#2,a7
	
	
	bsr	module+$2c		;d‚marrer la musique


	pea	au_revoir(pc)		;message de fin
	move.w	#9,-(a7)		;print
	trap	#1
	addq.l	#6,a7
	
	move.w	#7,-(a7)		;attente d'une touche au clavier
	trap	#1
	addq.l	#2,a7
	
	
	bsr	module+$2e		;arreter la musique

*	Note : on peut faire repartir la musique du point ou on l'a arret‚e
*	par un saut … module+$2c, ou du point de d‚part par un saut …
*	module+$30...

	clr.w	-(a7)			;pterm
	trap	#1

*---------------------------------------

bonjour	dc.b	$1b,'EPress a key to begin the song ...',0

au_revoir
	dc.b	$d,$a,'Press a key to stop the song ...',0

	even

*---------------------------------------

module	incbin a:\programs\facile.tos

	end
