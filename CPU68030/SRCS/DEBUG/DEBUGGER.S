;*************************************************************************
;*                                                                       *
;*  Fichier:               DEBUGGER.S                                    *
;*  Objet  :               Debugger pour Falcon030/ecran VGA    	 *
;*                                                                       *
;* Vous etes libre de distribuer et modifier ce source dans le	 *
;* but de l'ameliorer ou de l'adapter a d'autres machines telles que	 *
;* l'Hades ou le Milan A LA CONDITION EXPRESSE de ne pas en tirer un	 *
;* profit pecunier et de TOUJOURS distribuer le source avec l'executable *
;*                                                                       *
;* N. B. La gestion du RVB est incluse dans ce source, ainsi que	 *
;* le changement de frequence de balyage 50/60 hz(non disponible en VGA) *
;*                                                                       *
;*************************************************************************

	OPT	D-
	
NON	EQU	0
OUI	EQU	1
RESIDENT	EQU	NON
NBLIG	EQU	14
NBLIGMEM	EQU	7
LGLAB	EQU	8

DEMO	EQU	NON

	IFNE	DEMO
	OUTPUT	"desad.prg"
	ENDC

ANG	EQU	NON

	IFNE	RESIDENT
	OUTPUT	"desares.prg"
	ENDC


	even

main	clr.b	prgprog	;pas de fichier prg en memoire

	movea.l	4(sp),a5	;4(sp) est le d‚but de la Basepage
	move.l	12(a5),d0	;Taille du code du programme
	add.l	20(a5),d0	;+ Longueur du segment Data
	add.l	28(a5),d0	;+ Longueur du segment BSS

	add.l	#$100,d0	;+ Basepage (256 octets)+ pile (4KB)

	move.l	#pileutil,sp

	move.l	d0,d1	;Longueur	plus
	add.l	a5,d1	;adresse
	andi.b	#$fe,d1	;(arrondie)

	move.l	d0,tailleres
	move.l	a5,debres
	move.l	d0,-(sp)	;Taille de la m‚moire requise
	move.l	a5,-(sp)	;Adresse de la zone
	clr	-(sp)	;Octet "dummy" (factice) sans signification
	move	#$4a,-(sp)	;Num‚ro de fonction mshrink
	trap	#1	;Trap pour GEMDOS
	lea	12(sp),sp

	clr.l	-(sp)
	move	#$20,-(sp)
	trap	#1
	addq.l	#6,sp
	move.l	d0,savessp	;pile superviseur

	move.l	$ffff8240.w,save2prem
	move.l	$ffff8244.w,save2der
	move.l	$ffff9800.w,save2premb
	move.l	$ffff9804.w,save2derb

	bsr	sauvepalette	;sauver palette debut

	move.l	$44e.w,slogbase	;adresse logique
	move.l	$44e.w,slogbase2	;adresse logique
	moveq	#0,d0
	move.b	$ffff8201.w,d0
	lsl.l	#8,d0
	move.b	$ffff8203.w,d0
	lsl.l	#8,d0
	move.b	$ffff820d.w,d0
	move.l	d0,sphysbase	;adresse physique
	move.l	d0,sphysbase2	;adresse physique

	move.l	#newadr,d0
	and.l	#$ffffff00,d0
	move.l	d0,adrecran	;nouvelle adresse physique

	lea	hardregs,a0
	bsr	getregsvideo	;recuperer registres video

;tester si haute resolution
;si oui pas de changement reso ni palette

	move	#89,-(sp)	;type moniteur
	trap	#14
	addq.l	#2,sp
	tst	d0	;moniteur haute rezo?
	bne.s	nohauts	;non si #0
	move.b	#1,haute	;mode 640*400

nohauts	move	#-1,-(sp)
	move	#88,-(sp)
	trap	#14
	addq.l	#4,sp

	move	d0,rezdeb

	move	d0,d1
	andi	#%111,d1
	cmp	#2,d1
	bne.s	no16co
	move.b	#1,coul16

no16co	cmp	#1,d1
	bne.s	no4co
	move.b	#1,coul4

no4co	move	d0,-(sp)

	move.b	#%11001,d0
*	bclr	#8,d0

*	move	#$f00,$ffff8240.w

	move	d0,-(sp)
	move	#88,-(sp)
	trap	#14
	addq.l	#4,sp

*	move	#3,-(sp)
*	move.l	#-1,-(sp)
*	move.l	adrecran,-(sp)
*	move	#5,-(sp)
*	trap	#14
*	lea	14(sp),sp

*	move	d0,-(sp)
*	move	#88,-(sp)
*	trap	#14
*	addq.l	#4,sp

;on recupere la resolution

*	move	#$0f0,$ffff8240.w

	lea	moy50,a0
	bsr	getregsvideo

	move	(sp),d0
	move.b	#%11001,d0
;	bclr	#8,d0

	move	d0,-(sp)
	move	#88,-(sp)
	trap	#14
	addq.l	#4,sp

*	move	#3,-(sp)
*	move.l	#-1,-(sp)
*	move.l	#-1,-(sp)
*	move	#5,-(sp)
*	trap	#14
*	lea	14(sp),sp

*	move	d0,-(sp)
*	move	#88,-(sp)
*	trap	#14
*	addq.l	#4,sp

	lea	moy60,a0
	bsr	getregsvideo

sauteit	;ici on est en resolution moyenne

	addq.l	#2,sp
	move.l	slogbase,$44e.w

	move.l	#moy60,moyenne

	move	rezdeb,-(sp)
	move	#3,-(sp)
	move.l	adrecran,-(sp)	;physique
	move.l	slogbase,-(sp)	;logique
	move	#5,-(sp)
	trap	#14
	lea	14(sp),sp

	bsr	restmoyenne

sauteit	movec	VBR,a6	;adresse base vecteurs
	move.l	#pileautre,a0
	movec	a0,MSP

	move.l	$436.w,limiteram	;limite memoire utilisateur
	move.l	$432.w,debutram
	move.l	$42e.w,limiteram2	;limite physique ram
	move.l	$4f2.w,system

	move.l	$502.w,ancimp
	move.l	#breakprg,$502.w
	move.l	$14(a6),ancdivzero
	move.l	#newdivzero,$14(a6)
	move.l	$10(a6),ancillegal
	move.l	#newillegal,$10(a6)
	move.l	$70(a6),ancvbl
	move.l	$70(a6),vbl+2
	move.b	#1,tracenow
	move.l	#newvbl,$70(a6)
	move.l	$8(a6),ancbuser
	move.l	$c(a6),ancadrer
	move.l	#buserror,$8(a6)
	move.l	#adrerror,$c(a6)

*	move	#$555,$ffff8240.w

	move.l	$84(a6),anctrap1
	move.l	$88(a6),anctrap2
	move.l	$b4(a6),anctrap13
	move.l	$b8(a6),anctrap14
*	move.l	newtrap1,$84(a6)
*	move.l	newtrap2,$88(a6)
*	move.l	newtrap13,$b4(a6)
*	move.l	newtrap14,$b8(a6)

*	move	#$f,$ffff8240.w

	move.l	#pilesuper,sp


*	move	#$555,$ffff8240.w


	move.l	$24.w,anctrace
	move.l	#debut2,$24.w	;routine trace
	movem.l	regdonnee,d0-d7
	movem.l	regadresse,a0-a6
	moveq	#-1,d3
	move.l	USP,a0
	move.l	a0,valpile
	movec	ISP,a0
	move.l	a0,valisp
	movec	MSP,a0
	move.l	a0,valmsp

	sub.l	a0,a0
	move.l	a0,dfenster	;adresse 1er ligne fenetre

	bsr	metcadres
	move.l	#$6660000,$ffff8244.w
	move.l	#$fff0444,$ffff8240.w
	move.l	#$6660000,$ffff9804.w
	move.l	#$fff0444,$ffff9800.w

*	moveq	#NBLIG-1,d7	;lire 11 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa	;afficher instructions

	IFNE	RESIDENT

	move	#1,-(sp)
	trap	#1
	addq.l	#2,sp
	move.l	#pilegal,pileilgal
	move.b	#1,prgprog
	clr.b	tracenow
	clr	-(sp)
	move.l	tailleres,-(sp)
	move	#$31,-(sp)
	trap	#1

	ENDC

bcclav0	;boucle sans fichier prg charg‚

	move.l	#bcclav0,retclav
	bsr	gettouche
	cmp.l	#$00110008,d0
	beq	zoomdzoom

	cmp.l	#$00620000,d0
	beq	pagehelp

	IFEQ	DEMO
	
	cmp.l	#$002e0000,d0	;"C" pour chercher
	beq	chercher
	
	ENDC

	cmp.l	#$00610000,d0
	beq	restoreenv
	cmp.l	#$00500006,d0
	beq	mempagedown
	cmp.l	#$00480006,d0
	beq	mempageup
	cmp.l	#$00100004,d0
	beq	adrmem
	cmp.l	#$00480004,d0
	beq	memorydown
	cmp.l	#$00500004,d0
	beq	memoryup
	cmp.l	#$004d0004,d0
	beq	memplus2
	cmp.l	#$004b0004,d0
	beq	memmoins2
	cmp.l	#$002e0004,d0	;CTRL+"C" pour sortir
	beq	finir
*	cmp.l	#$00010000,d0
*	beq	finir

	IFEQ	DEMO
	
	cmp.l	#$001f0008,d0	;ALT+"S"
	beq	savedon
	
	ENDC

	cmp.l	#$00210000,d0
	beq	swap50_60hz
	cmp.l	#$00260000,d0
	beq	chargerprg
	cmp.l	#$002F0000,d0
	beq	flipecrrez
	cmp.l	#$00500002,d0
	beq	pagebas
	cmp.l	#$00480002,d0
	beq	pagehaut
	cmp.l	#$00480000,d0
	beq	verslehaut
	cmp.l	#$00500000,d0
	beq	verslebas
	cmp.l	#$004b0000,d0
	beq	moins2
	cmp.l	#$004d0000,d0
	beq	plus2
	cmp.l	#$00100000,d0
	beq	getadr
	bra	bcclav0

pagehelp	movem.l	d0-a6,-(sp)
	bsr.s	metlapage
	bra	retforclav

metlapage	;effacer l'ecran puis afficher messages d'aide
	;puis remettre ecran normal apres appui touche

	move.l	adrecran,a0
	move.l	#$ffff,d6
	move	#32000/4-1,d7

mettreecrz	move.l	d6,(a0)+
	dbra	d7,mettreecrz
	moveq	#1,d0
	moveq	#8,d1
	lea	messhelp,a1

autligh	move.l	adrecran,a6
	bsr	afflalig
	addq	#8,d1	;ligne suivante

getfinlg	tst.b	(a1)+
	bne.s	getfinlg
	cmp.b	#-1,(a1)
	bne.s	autligh
	bsr	gettouche

	;remettre fenetre
	
	bsr	metcadres
	move.l	dfenster,a0
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa	;afficher instructions
	rts

waitvbl	move	#$25,-(sp)
	trap	#14
	addq.l	#2,sp
	rts

restoreenv	movem.l	d0-a6,-(sp)
	bsr	metcadres
	bra	retforclav

memplus2	movem.l	d0-a6,-(sp)
	bra	retforclav

memmoins2	movem.l	d0-a6,-(sp)
	bra	retforclav

buserror	tst.b	scanning	;en train de desassembler?
	bne	onlyflag	;oui

setbuser	ori	#$8000,(sp)	;trace on
	movem.l	d0-a6,-(sp)
	move.b	#1,court
	lea	busertxtc,a1	;erreur courte
	btst.b	#4,6+15*4(sp)
	beq.s	busmess
	clr.b	court
	btst.b	#5,$a+15*4(sp)
	beq.s	noetageC
	lea	busertxtlc,a1
	bra.s	busmess

noetageC	btst.b	#4,$a+15*4(sp)
	beq.s	noetageB
	lea	busertxtlb,a1
	bra.s	busmess

noetageB	lea	busertxtld,a1
	bra.s	busmess

adrerror	ori	#$8000,(sp)	;trace on
	movem.l	d0-a6,-(sp)
	lea	adrertxt,a1

busmess	move.b	#1,tracenow
	move.b	#1,swaprez
	moveq	#60,d0
	move	#3*8-2,d1
	move.l	adrecran,a6
	bsr	afflalig
	lea	cyclemod,a1
	btst.b	#7,$b+15*4(sp)
	bne.s	cyclelecr
	lea	cyclelec,a1
	btst.b	#6,$b+15*4(sp)
	bne.s	cyclelecr
	lea	cyclewri,a1

cyclelecr	moveq	#74,d0
	move	#3*8-2,d1
	move.l	adrecran,a6
	bsr	afflalig
	move.l	2+15*4(sp),d7
	lea	adrpctxt,a1
	bsr	transhexa2
	lea	adrpctxt2,a1
	moveq	#60,d0
	move	#8*8-2,d1
	move.l	adrecran,a6
	bsr	afflalig
	move.l	$10+15*4(sp),d7	;adresse fautive
	lea	adrfaltxt,a1
	bsr	transhexa2
	lea	adrfaute,a1
	moveq	#60,d0
	move	#4*8-2,d1
	move.l	adrecran,a6
	bsr	afflalig
	lea	fileinsctxt,a1
	moveq	#0,d7
	move	$c+15*4(sp),d7
	bsr	transhexa3
	lea	fileinsc,a1
	moveq	#60,d0
	move	#5*8-2,d1
	move.l	adrecran,a6
	bsr	afflalig
	lea	fileinsbtxt,a1
	moveq	#0,d7
	move	$e+15*4(sp),d7
	bsr	transhexa3
	lea	fileinsb,a1
	moveq	#60,d0
	move	#6*8-2,d1
	move.l	adrecran,a6
	bsr	afflalig
	lea	adretageb,a1
	move.l	$24+15*4(sp),d7
	bsr	transhexa2
	lea	adretgbtxt,a1
	moveq	#60,d0
	move	#7*8-2,d1
	move.l	adrecran,a6
	bsr	afflalig
	lea	etagecinv,a1
	btst.b	#7,$a+15*4(sp)
	bne.s	isbc

noisc	lea	etagebinv,a1
	btst.b	#6,$a+15*4(sp)
	beq.s	noisbc

isbc	moveq	#60,d0
	move	#9*8-2,d1
	move.l	adrecran,a6
	bsr	afflalig

noisbc	movem.l	(sp)+,d0-a6
	movem.l	d0-d7,regdonnee2	;regs de donnee
	movem.l	a0-a6,regadresse2	;regs d'adresse
	movem.l	a0/d0,-(sp)
	move	8(sp),d0	;sr sauv‚
	move	d0,savesr2
	move.l	USP,a0	;pile utilisateur
	move.l	a0,valpile2
	movec	ISP,a0	;pile superviseur
	lea	$5c+8(a0),a0
	move	a0,valisp2
	movec	MSP,a0	;pile master
	btst	#12,d0	;M=1 avant exception?
	beq.s	masteroff	;non alors MSP inchang‚
	lea	$5c+8(a0),a0

masteroff	move.l	a0,valmsp2
	move.l	8+2(sp),newpc
	movem.l	(sp)+,a0/d0
	tst.b	court
	bne.s	forcourt

	;sauvegarde contexte registres
	;pour reprise en instruction trace
	;format long

	move.b	#1,reprise	;flag reprise sur erreur
	bra.s	sorterr

forcourt	nop

sorterr	andi	#%0000111011111111,10(sp)
	rte

onlyflag	;on desassemble la memoire
	;si on arrive ici c'est qu'il n'existe pas de memoire en (a0)
	;donc le flag est mis pour mettre VIDE a la place d'une donnee

	andi	#%0000111011111111,10(sp)
	move.b	#1,outmemory
	rte

restpalette	tst.b	haute
	beq.s	restit
	rts

restit	movem.l	d0/a0-a1,-(sp)
	lea	$ffff8240.w,a0
	lea	savepal16,a1
	moveq	#16/2-1,d0

bcpal16r	move.l	(a1)+,(a0)+
	dbra	d0,bcpal16r
	lea	$ffff9800.w,a0
	lea	savepal256,a1
	moveq	#256/2-1,d0

bcpal256r	move.l	(a1)+,(a0)+
	dbra	d0,bcpal256r
	movem.l	(sp)+,d0/a0-a1
	rts

sauvepalette	movem.l	d0/a0-a1,-(sp)
	lea	$ffff8240.w,a0
	lea	savepal16,a1
	moveq	#16/2-1,d0

bcpal16	move.l	(a0)+,(a1)+
	dbra	d0,bcpal16
	lea	$ffff9800.w,a0
	lea	savepal256,a1
	moveq	#256/2-1,d0

bcpal256	move.l	(a0)+,(a1)+
	dbra	d0,bcpal256
	movem.l	(sp)+,d0/a0-a1
	rts

overmienne	;remettre ancienne palette

	tst.b	haute
	bne.s	noover
	move.l	save2prem,$ffff8240.w
	move.l	save2der,$ffff8244.w
	move.l	save2premb,$ffff9800.w
	move.l	save2derb,$ffff9804.w

noover	rts

metmienne	mettre palette debuggueur

	tst.b	haute
	bne.s	nomet
	move.l	#$6660000,$ffff8244.w
	move.l	#$fff0444,$ffff8240.w
	move.l	#$6660000,$ffff9804.w
	move.l	#$fff0444,$ffff9800.w

nomet	rts

restmoyenne	met la resolution moyenne

	tst.b	haute
	beq.s	setitm
	rts

setitm	movem.l	a0/a1,-(sp)
	move.l	moyenne,a1
	bsr.s	ent2rest
	move.b	#1,$ffff8260.w
	move.l	#$6660000,$ffff8244.w	;palette debugueur
	move.l	#$fff0444,$ffff8240.w
	move.l	#$6660000,$ffff9804.w	;palette debugueur
	move.l	#$fff0444,$ffff9800.w
	movem.l	(sp)+,a0/a1
	rts

restorevideo	;restore la video du lancement du programme
	;avant de lancer le programme charg‚ par exemple
	;si il y a 16 couleur alors fixer 260.w a 1 avant
	;si 4 couleurs alors fixer 266.w a 0 sans changer 260.w

	tst.b	haute
	bne.s	nosetiti
	movem.l	a0/a1,-(sp)
	tst.b	coul16
	beq.s	no16coul
	move.b	#1,$ffff8260.w
	bra.s	no4coul

no16coul	tst.b	coul4
	beq.s	no4coul
	clr.w	$ffff8266.w

no4coul	lea	hardregs,a1
	bsr.s	ent2rest
	movem.l	(sp)+,a0/a1

nosetiti	rts

ent2rest	tst.b	coul16
	bne.s	nomet60
	tst.b	coul4	;4 couleurs?
	beq.s	nomet60	;oui alors mettre 260.w
	move.b	40(a1),$ffff8260.w

nomet60	move	(a1)+,$ffff8264.w
	addq.l	#2,a1
	tst.b	coul4
	bne.s	noset66
	move	-2(a1),$ffff8266.w

noset66	lea	$ffff8282.w,a0
	REPT	8
	move	(a1)+,(a0)+
	ENDR
	lea	$ffff82a2.w,a0
	REPT	6
	move	(a1)+,(a0)+
	ENDR
	move	(a1)+,$ffff82c0.w
	move	(a1)+,$ffff82c2.w
	move	(a1)+,$ffff8210.w
	move.b	(a1)+,$ffff820e.w
	move.b	(a1)+,$ffff820a.w
	rts

getmemory	;remplir la fenetre voir memoire (en bas a droite)

	movem.l	d0-a6,-(sp)

	move.b	#1,scanning	;inhiber erreur bus lecture

	move.l	adrdebmem,a5
	lea	savememfen,a6	;sauvegarde  valeurs memoire
	moveq	#6,d6
	move	#16*8-2,d5

for4	bsr	afflamem	;afficher la ligne
	addq	#8,d5
	dbra	d6,for4
	clr.b	scanning
	movem.l	(sp)+,d0-a6
	rts

afflamem	;d5=position y
	;a5=adresse memoire
	;a6=adresse memoire de sauvegarde

	lea	texte,a1
	move.l	a5,d7
	bsr	transhexa2
	clr.b	(a1)
	lea	texte,a1
	move	d5,d1
	moveq	#1,d0
	btst.b	#0,zoom
	bne.s	nogetmemo
	move.l	a6,-(sp)
	move.l	adrecran,a6
	bsr	afflalig
	move.l	(sp)+,a6
	moveq	#11,d2
	move.l	a6,-(sp)
	bsr	nowlesval
	move.l	(sp)+,a6

nogetmemo	cmp.l	#0,a6
	beq.s	nosavitt
	move	d7,(a6)+	;sauvegarder valeur

nosavitt	addq.l	#8,a5
	rts

nowlesval	;a5=adresse memoire
	;d5=position y
	;d2=position x
	;a6=buffer de sauvegarde des valeurs
	
	move.l	a5,-(sp)
	move.b	#1,scanning
	lea	texte,a1	;zone 4*2 octets
;--------------------------------------------------------
;structure d'affichage:
;4 mots + 8 caracteres conformes aux valeurs de memoires corresp“ndantes
;le 0 est remplace par un espace
;on remplit la zone de espaces d'abord=4+1+4+1+4+1+4+1+8 valeur zero
;ce qui vaut 28 octets

	moveq	#28/4-1,d4
	move.l	a1,a2

clearzone	move.l	#$20202020,(a2)+
	dbra	d4,clearzone
	moveq	#3,d4
	lea	4+1+4+1+4+1+4+1(a1),a2	;1er caractere

for10	move.b	(a5)+,d7
	tst.b	outmemory
	beq.s	inmem
	move.b	#"?",d7
	clr.b	outmemory

inmem	ror	#8,d7
	move.b	(a5)+,d7
	tst.b	outmemory
	beq.s	inmem2
	move.b	#"?",d7
	clr.b	outmemory

inmem2	move	d7,d3
	tst.b	d3
	bne.s	nmetrieng
	move.b	#".",d3

nmetrieng	move.b	d3,1(a2)
	lsr	#8,d3
	tst.b	d3
	bne.s	nmetriend
	move.b	#".",d3

nmetriend	move.b	d3,(a2)
	addq.l	#2,a2
	bsr	transhexa3
	move.b	#" ",(a1)+
	dbra	d4,for10
	cmp	#60,d2
	bne.s	noen20
	lea	-9(a2),a2

noen20	clr.b	(a2)
	lea	texte,a1
	move	d5,d1
	move	d2,d0
	move.l	adrecran,a6
	bsr	afflalig
	move.l	(sp)+,a5
	rts

getregsvideo	;recuperer resolution courante au lancement du debuggueur

	move	$ffff8264.w,(a0)+
	move	$ffff8266.w,(a0)+
	lea	$ffff8282.w,a1
	REPT	8
	move	(a1)+,(a0)+
	ENDR
	lea	$ffff82a2.w,a1
	REPT	6
	move	(a1)+,(a0)+
	ENDR
	move	$ffff82c0.w,(a0)+
	move	$ffff82c2.w,(a0)+
	move	$ffff8210.w,(a0)+
	move.b	$ffff820e.w,(a0)+
	move.b	$ffff820a.w,(a0)+
	move.b	$ffff8260.w,(a0)+
	rts

debut2	IFNE	RESIDENT
	bsr	restmoyenne
	move.l	d0,-(sp)
	clr	$ffff8246.w
	move.l	adrecran,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w
	move.l	(sp)+,d0
	ENDC
	tst.b	reprise	;entree apres une exception?
	beq.s	noreprerr	;non
;*******************************************************************
;reprise d'exception
;on restaure les valeurs registres au moment de l'exception
;on modifie la pile en consequence (PC en autres)
;tous les registres sont affect‚s

	movem.l	regdonnee2,d0-d7
	movem.l	regadresse2,a0-a6
	bsr	regifchange
	movem.l	d0-d7,regdonnee
	movem.l	a0-a6,regadresse
	move	savesr2,(sp)
	move.l	newpc,2(sp)
	clr.b	reprise

noreprerr	move	(sp),savesrcmp
	bsr	regifchange
	move.b	#1,scanning
	bsr	memoifchange
	clr.b	scanning
	movem.l	d0-d7,regdonnee
	movem.l	a0-a6,regadresse
	bsr	metmienne
	move.l	a7,pilerte
	bsr	videlalig
;---------------------------------------------------------
;cas test si ALT+R lancer programme en mettant breakpoint
;si oui alors placer illegal a cette adresse
;et placer breakpoint

	tst.b	altrun
	beq.s	noaltrun
	move.l	libbreakadr,a0	;adresse libre breakpoint pour adresse
	move.l	libbreakins,a1	;meme chose pour instruction
	move.l	outmetbreak,a2
	clr.l	libbreakadr
	clr.l	libbreakins
	clr.l	outmetbreak
	move.l	a2,(a0)
	move	(a2),(a1)
	moveq	#0,d0
	movec	CACR,d1
	movec	d0,CACR
	move	#$4afc,(a2)	;placer illegal
	movec	d1,CACR
	move.b	#1,illegbrk
	andi	#$7fff,(sp)	;enlever trace
	clr.b	altrun
	bra	ahlala

noaltrun:
;---------------------------------------------------------
;cas trap alors placer illegal
;si avanttrace<>0 alors on a ete precedement sur un trap

	tst.b	avanttrace	;adresse instruction trac‚e
	beq.s	notrap
	move.l	2(sp),d0	;adresse courante apres trap
	cmp.l	anctrap1,d0
	beq.s	casoli
	cmp.l	anctrap2,d0
	beq.s	casoli
	cmp.l	anctrap13,d0
	beq.s	casoli
	cmp.l	anctrap14,d0
	beq.s	casoli
	bra.s	notrap

casoli	move.l	dfenster,d0
	cmp.l	juskbreak,d0
	beq.s	notrap
	lea	breaklist,a6
	moveq	#9,d6

aforlist	cmp.l	(a6)+,d0
	dbeq	d6,aforlist
	beq.s	notrap
;---------------------------------------------------------
;cas trap

	move.l	pileilgal,a1
	move.l	8(sp),(a1)+	;adresse trap
	clr.l	(a1)
	move.l	a1,pileilgal
	addq.l	#2,-4(a1)	;instruction suivante
	andi	#$7fff,(sp)	;enlever trace
	move.l	#illegalr,12+2(sp)	;nouvelle adresse de retour
	clr.b	illegdeb
	bra	ahlala

notrap:
;--------------------------------------------------------------
;verifier maintenant le cas bsr/jsr
;placer l'adresse de retour dans la pile
;on arrive ici a la premiere instruction du bsr/jsr

	tst.b	avantsr
	beq.s	nobjsr
	lea	12(sp),a0	;adresse retour cas super
	move	(sp),d0
	andi	#%0011000000000000,d0
	tst	d0	;mode USP?
	bne.s	usessp	;non
	movec	USP,a0

usessp	clr.b	avantsr
	move.l	pileilgal,a1
	move.l	(a0),(a1)+	;adresse retour
	clr.l	(a1)
	move.l	a1,pileilgal
	andi	#$7fff,(sp)	;enlever trace
	move.l	#illegalr,(a0)	;nouvelle adresse de retour
	clr.b	illegdeb
	bra	ahlala

nobjsr:
;***************************************************
;verifer si l'on se trouve dans une exception autre
;que trace ou trap
;cas d'une erreur
;alors relancer le processeur
;si on se trouve en rom et au debut d'une exception
;et que l'on a effectue un ctrl+T avant alors pointer retour sur jmp
;et mettre trace on

	move.l	d0,-(sp)
	move.l	2+4(sp),d0
	cmp.l	#newdivzero,d0
	beq.s	retret
	bra.s	noretret

retret	move.l	(sp)+,d0
	bra	ahlala

noretret
;---------------------------------------------------
;cherche tous les breakpoint et remet les bonnes valeurs

	move.l	(sp)+,d0
	tst.l	juskbreak
	beq.s	nojusk
	move.l	juskbreak,a2
	movec	CACR,d1
	moveq	#0,d0
	movec	d0,CACR
	move	juskval,(a2)	;remettre ancien mot
	movec	d1,CACR
	bra.s	roro

nojusk	lea	breaklist,a0
	lea	slistill,a1
	moveq	#9,d7
	movec	CACR,d1
	moveq	#0,d0
	movec	d0,CACR

alllisti	addq.l	#2,a1
	tst.l	(a0)+
	beq.s	noisadrbrk
	move.l	-4(a0),a2
	move	-2(a1),(a2)

noisadrbrk	dbra	d7,alllisti
	movec	d1,CACR
;---------------------------------------------------
roro	move.l	2(sp),a0	;adresse instruction suivante
	move.l	a0,adrpcprg
	move.l	a0,dfenster

nocha02
;----------------------------------------------------------
;reaffichage de la fenetre instruction

	tst.b	frombreak
	bne.s	no1ligbas
	cmp.l	pfenster,a0
	bne.s	no1ligbas
	bsr	execbas
	move	#6,d1
	move	lglabi,d0
	addi	#11,d0
	move.l	adrecran,a6
	lea	pcmark,a1
	bsr	afflalig
	bra.s	no10ligb

no1ligbas	clr.b	frombreak
*	moveq	#NBLIG-1,d7	;lire 11 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa

no10ligb:
;----------------------------------------------------------

	move.b	#1,tracenow
	tst.b	swaprez
	beq.s	bcclav
	bsr	restmoyenne
	clr	$ffff8246.w
	move.l	adrecran,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w

bcclav	move.l	#bcclav,retclav
	bsr	gettouche
	cmp.l	#$00110008,d0
	beq	zoomdzoom

	cmp.l	#$00620000,d0
	beq	pagehelp

	IFEQ	DEMO
	cmp.l	#$002e0000,d0	;"C" pour chercher
	beq	chercher
	cmp.l	#$00240000,d0	;"J" runner jusqu'a
	beq	runjusque
	cmp.l	#$001f0008,d0	;ALT+"S"
	beq	savedon
	ENDC

	cmp.l	#$00610000,d0
	beq	restoreenv
*	cmp.l	#$00660000,d0
*	beq	flipstcomp
	cmp.l	#$00500006,d0
	beq	mempagedown
	cmp.l	#$00480006,d0
	beq	mempageup
	cmp.l	#$00100004,d0
	beq	adrmem

	IFEQ	DEMO
	cmp.l	#$00300000,d0
	beq	setletbreak
	ENDC

	cmp.l	#$00130000,d0	; "R"
	beq	runprg
	IFEQ	RESIDENT
	cmp.l	#$00010000,d0	;ESC pour sortir
	beq	finirx
	ENDC
	cmp.l	#$00140000,d0
	beq	traceinto
	cmp.l	#$00480004,d0
	beq	memorydown
	cmp.l	#$00500004,d0
	beq	memoryup
	cmp.l	#$00150000,d0
	beq	suivre
*	cmp.l	#$00130000,d0	;touche "R" seule
*	beq	newreg
	cmp.l	#$001f0000,d0	;touche "S"
	beq	sauterins	;se placer a l'adresse debut fenetre
	cmp.l	#$00210000,d0
	beq	swap50_60hz

	IFEQ	DEMO
	cmp.l	#$00130008,d0	;touche ALT + "R"
	beq	runandbreak
	ENDC

	cmp.l	#$002F0000,d0
	beq	flipecrrez
	cmp.l	#$00500002,d0
	beq	pagebas
	cmp.l	#$00480002,d0
	beq	pagehaut
	cmp.l	#$00480000,d0
	beq	verslehaut
	cmp.l	#$00500000,d0
	beq	verslebas
	cmp.l	#$004b0000,d0
	beq	moins2
	cmp.l	#$004d0000,d0
	beq	plus2
	cmp.l	#$00100000,d0
	beq	getadr
	bra	bcclav

zoomdzoom	;zoom ou dezoom la fenetre instruction
	;de pleine page a normal

	movem.l	d0-a6,-(sp)
	bchg.b	#0,zoom
	btst.b	#0,zoom
	bne.s	nomettout
	move	#8,lglabi
	bsr	metcadres
	bra.s	sautesauf

nomettout	move	#22,lglabi
	bsr	toutcadres

sautesauf	move.l	dfenster,a0
*	moveq	#NBLIG-1,d7	;lire 11 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa	;afficher instructions
	bra	retforclav

	IFEQ	DEMO

chercher	movem.l	d0-a6,-(sp)
	lea	buffer,a1
	move.l	#"Cher",(a1)+
	move.l	#"cher",(a1)+
	move.l	#$203a207f,(a1)+
	clr.b	(a1)
	move	#24*8-4,d1	;pos y
	moveq	#1,d0	;pos x
	lea	buffer,a1
	move.l	adrecran,a6
	bsr	afflalig
	move.l	#buffer,a5
	move.l	a5,debutoflig
	move.b	#127,(a5)
	moveq	#12,d6
	moveq	#12,d7
	bsr	bcgetadr
	cmp.l	#$10000,d0
	beq	nocher

;tester si
;texte avec "texte"
;donn‚e hexa avec $xxxx
;donn‚e decimal avec xxxx
;buffer=buffer entr‚e

	lea	buffer,a5
	cmp.b	#$22,(a5)
	bne	noistext
	addq.l	#1,a5
	lea	chainech,a6

chlefin	cmp.b	#$22,(a5)
	beq.s	boncher
	tst.b	(a5)
	beq	nocher
	move.b	(a5)+,(a6)+
	bra.s	chlefin

boncher	clr.b	(a6)
	move.b	#1,scanning
	lea	chainech,a0
	move.l	dfenster,a1	;adresse debut fenetre instructions

recomit	move.l	a0,a2
	move.l	a1,a3

bcbonit	move.b	(a0)+,d0
	beq.s	istrouve
	move.b	d0,d1
	cmp.b	#"A",d1
	blo.s	nobirz
	cmp.b	#"Z",d1
	bhi.s	nobirz
	addi.b	#$20,d1
	bra.s	nobirzi

nobirz	cmp.b	#"a",d1
	blo.s	nobirzi
	cmp.b	#"z",d1
	bhi.s	nobirzi
	subi.b	#$20,d1

nobirzi	move.b	(a1)+,d2
	cmp.b	d1,d2
	beq.s	bcbonit
	cmp.b	d0,d2
	beq.s	bcbonit
	lea	1(a3),a1
	move.l	a2,a0
	tst.b	nowbreak
	beq.s	recomit

istrouve	;la chaine a ete trouv‚e

	move.l	a3,dfenster
	move.l	a3,a0
*	moveq	#NBLIG-1,d7	;lire 11 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa
	bra.s	nocher

noistext	nop

nocher	clr.b	nowbreak
	clr.b	scanning
	bsr	videlalig
	bra	retforclav

	ENDC

	IFEQ	DEMO

runjusque	;si l'adresse ne peut accepter un breakpoint
	;type illegal alors il faut tracer chaque instruction
	;et comparer avec cette adresse

	movem.l	d0-a6,-(sp)
	lea	buffer,a1
	move.l	#"Jusq",(a1)+
	move.l	#$75278520,(a1)+
	move.l	#$3a207f00,(a1)+
	move	#24*8-4,d1	;pos y
	moveq	#1,d0	;pos x
	lea	buffer,a1
	move.l	adrecran,a6
	bsr	afflalig
	move.l	#buffer,a5
	move.l	a5,debutoflig
	move.b	#127,(a5)
	moveq	#11,d6
	moveq	#11,d7
	bsr	bcgetadr
	cmp.l	#$10000,d0
	beq.s	noadrjus
	bsr	calcadr
	bsr	placebreak	;place un breakpoint
	tst.b	d7	;valable?
	beq.s	noadrjus	;non

	;oui alors lancer le prg
	
	movem.l	(sp)+,d0-a6
	andi	#$7fff,(sp)	;enlever trace
	bra	runprg	;lancer le programme

placebreak	;place un breakpoint

	moveq	#0,d7
	cmp.l	limiteram,d0	;limite RAM machine
	bhs.s	nofreeti
*	cmp.l	debutram,d4
*	blo.s	nofreeti
	move.l	d6,juskbreak	;adresse breakpoint
	moveq	#1,d7
	rts

nofreeti:
;cas adresse dans la rom ou n'existe pas
;d'ou tracer chaque instruction et rentrer dans
;les trap .... pour comparer avec l'adresse voulu

	rts

noadrjus	bsr	videlalig
	bra	retforclav

	ENDC

*flipstcomp:
*
*	movem.l	d0-a6,-(sp)
*	tst.b	stcomp
*	bne.s	setzerst
*	move.b	#1,stcomp
*	move.b	#1,stcomps
*	bra	retforclav
*
*setzerst:
*
*	clr.b	stcomp
*	clr.b	stcomps
*	bra	retforclav

mempagedown	movem.l	d0-a6,-(sp)
	add.l	#7*8,adrdebmem
	bsr	getmemory
	bra	retforclav

mempageup	movem.l	d0-a6,-(sp)
	sub.l	#7*8,adrdebmem
	bsr	getmemory
	bra	retforclav

adrmem	;changer l'adresse de la fenetre memoire

	movem.l	d0-a6,-(sp)
	lea	buffer,a1
	move.l	#"Adre",(a1)+
	move.l	#"sse ",(a1)+
	move.l	#"m‚mo",(a1)+
	move.l	#"ire ",(a1)+
	move.l	#$3a207f00,(a1)+
	move	#24*8-4,d1	;pos y
	moveq	#1,d0	;pos x
	lea	buffer,a1
	move.l	adrecran,a6
	bsr	afflalig
	move.l	#buffer,a5
	move.l	a5,debutoflig
	move.b	#127,(a5)
	moveq	#19,d6
	moveq	#19,d7
	bsr	bcgetadr
	cmp.l	#$10000,d0
	beq.s	noadrmem
	bsr	calcadr
	move.l	d6,adrdebmem
	bsr	getmemory

noadrmem	bsr	videlalig
	bra.s	retforclav

memorydown	;ligne en bas pour fenetre memoire
	;d'ou scroller d'une ligne et afficher la ligne du bas

	movem.l	d0-a6,-(sp)
	move.l	adrdebmem,a6	;adresse debut fenetre memoire
	bsr	scrmembas	;scroller
	move.l	adrdebmem,a5
	subq.l	#4*2,adrdebmem
	lea	-8(a5),a5
	move	#16*8-2,d5
	move.b	#1,scanning	;inhiber erreur bus lecture
	sub.l	a6,a6
	bsr	afflamem	;afficher la ligne
	clr.b	scanning

retforclav	movem.l	(sp)+,d0-a6
	move.l	retclav,a6
	jmp	(a6)

scrmembas	move	#1,d4	;scroll bas

entscrmem	move.l	adrecran,a6
	moveq	#1,d0
	moveq	#16,d1
	moveq	#NBLIGMEM,d2
	moveq	#44,d3
	bsr	scrolllig
	rts

memoryup	movem.l	d0-a6,-(sp)
	moveq	#0,d4
	bsr	entscrmem	;scroller
	move.l	adrdebmem,a5
	addq.l	#4*2,adrdebmem
	lea	56(a5),a5
	move	#22*8-2,d5
	move.b	#1,scanning	;inhiber erreur bus lecture
	sub.l	a6,a6
	bsr	afflamem	;afficher la ligne
	clr.b	scanning
	bra	retforclav

	IFEQ	DEMO

savedon:
;permet de sauver une partie de la memoire
;dans un fichier sur disque

	movem.l	d0-a6,-(sp)
	lea	ligsauver,a1
	moveq	#26,d6
	bsr	getname	;recuperer nom fichier
	tst.b	d7
	bne	nodoch
	cmp.l	#$001c0000,d0	;sortie avec ENTER?
	beq	nodoch	;oui alors abandon
*	move	#$f00,$ffff8240.w
	bsr	doboncar
;--------------------------------------------------------------
;a5=adresse fin nom fichier
;ici on sort avec le nom du fichier dans buffer+26 jusqu'a ','
;d'ou rentrer 1ere adresse puis deuxieme
	move.b	#127,-1(a5)
	clr.b	(a5)+
	move.l	a5,debutoflig
	move	d6,d7
	bsr	bcgetadr
	cmp.l	#$00010000,d0
	beq	nodoch
	cmp.l	#$001c0000,d0
	beq	nodoch
*	move	#$00f,$ffff8240.w
	bsr	doboncar	;afficher ','
	move.b	#127,-1(a5)	;remplacer "," par fin de ligne
	clr.b	(a5)+
	move.l	a5,-(sp)
	move	d6,d7
	bsr	bcgetadr
	cmp.l	#$10000,d0
	beq	nodoch
	clr.b	1(a5)
	cmp.b	#1,d1
	beq	nodochp
*	move	#$0f0,$ffff8240.w
	cmp.l	#$001c0000,d0
	bne	nodochp
;--------------------------------------------------------
;maintenant il faut
;1-- verifier le fichier
;2-- calculer la 1ere adresse
;3-- calculer la deuxieme
;et verifier en meme temps l'authenticite des valeurs

	lea	buffer,a6	;adresse debut nom fichier
	lea	texte,a5

bctrnom:

	cmp.b	#127,(a6)
	beq.s	endnom
	move.b	(a6)+,(a5)+
	bra.s	bctrnom

endnom:

*	move	#$0FF,$ffff8240.w
	clr.b	(a5)	;fin de fichier
	move	#$ffff,-(sp)
	pea	texte
	move	#$4e,-(sp)	;Fsfirst
	trap	#1
	addq.l	#8,sp
	cmp.l	#-33,d0	;fichier trouve?
	beq.s	goodpath	;non alors bon path
	tst.l	d0	;erreur recherche
	beq.s	goodpath	;non alors bon
	bra	nodochp

goodpath:

*	move	#$ff0,$ffff8240.w
	clr	-(sp)
	pea	texte
	move	#$3c,-(sp)	;Fcreate
	trap	#1
	addq.l	#8,sp
	tst.l	d0
	bmi	nodochp
;---------------------------------------------------
;recuperer adresses de depart et de fin
	move	d0,shandle
	bsr	calcadr	;1ere adresse
	move.l	d6,adrsavd

	move.l	(sp)+,debutoflig
	bsr	calcadr

	cmp.l	adrsavd,d6
	blo	nopossave

	sub.l	adrsavd,d6
*	cmp.l	#$100,d6
*	bne	nopossave
*	move	#$111,$ffff8240.w
;------------------------------------------------------
;j'utilise un buffer de 1024 octets (dans texte)
;pour le transfert qui se fait en superviseur

	move.b	#1,scanning	;flag recuperer erreur bus

	move.l	adrsavd,a0
	addq.l	#1,d6
	divu	#1024,d6
	subq	#1,d6
	bmi.s	resttrans

all1024:

	move	#1023,d7
	lea	texte,a1

trans1024:

	move.b	(a0)+,(a1)+
	dbra	d7,trans1024
	move.l	a0,-(sp)
	pea	texte
	move.l	#1024,-(sp)
	move	shandle,-(sp)
	move	#$40,-(sp)
	trap	#1
	lea	12(sp),sp
	move.l	(sp)+,a0
	tst.l	d0
	bmi.s	nopossave
	dbra	d6,all1024

resttrans:

	swap	d6
	moveq	#0,d7
	move	d6,d7
	subq	#1,d6
	bmi.s	nopossave
	lea	texte,a1

transreste:

	move.b	(a0)+,(a1)+
	dbra	d6,transreste
	pea	texte
	move.l	d7,-(sp)
	move	shandle,-(sp)
	move	#$40,-(sp)
	trap	#1
	lea	12(sp),sp

nopossave:

	move	shandle,-(sp)
	move	#$3e,-(sp)
	trap	#1
	addq.l	#4,sp

nodoch:

	bsr	videlalig
	bra	retforclav

nodochp:

	addq.l	#4,sp
	bra.s	nodoch

	ENDC

newreg:
;affecter un nouveau registre
;genre: "PC=100000"

	movem.l	d0-a6,-(sp)
	lea	buffer,a1
	move.l	#"Regi",(a1)+
	move.l	#"stre",(a1)+
	move.l	#"=val",(a1)+
	move.l	#"eur ",(a1)+
	move	#"- ",(a1)+
	move.b	#"",(a1)+
	clr.b	(a1)
	move	#24*8-4,d1	;pos y
	moveq	#1,d0	;pos x
	lea	buffer,a1
	move.l	adrecran,a6
	bsr	afflalig
	move.l	#buffer+18,a5
	move.l	a5,debutoflig
	move.b	#127,(a5)
	moveq	#19,d6
	moveq	#19,d7
	bsr	bcgetadr
	cmp.l	#$10000,d0
	beq.s	noadrcalc
	bsr	calcadr	;d6=adresse voulue

noadrcalc:

	bsr	videlalig
	movem.l	(sp)+,d0-a6
	bra	bcclav

sauterins:
;sauter instruction
;->PC<-- adresse instruction suivante
;scroller la fenetre de 1 ligne
;si le pc<>debut fenetre alors poser PC sur debut fenetre
;effacer l'ancienne fleche avant

	movem.l	d0-a6,-(sp)
	move.l	adrpcprg,a0	;adresse fleche courante
	cmp.l	dfenster,a0
	bne.s	nosauter
	move.l	dfenster,adrpcprg	;nouveau PC
	bsr	execbas	;scroller
	move.l	dfenster,adrpcprg	;nouveau PC
	bra.s	affnewfle

nosauter:
;chercher y de la fleche courante
;l'effacer si visible sur la fenetre

	lea	pfenster,a5
	move.l	adrpcprg,a6
	move.l	dfenster,adrpcprg	;nouveau PC
	moveq	#NBLIG-2,d5
	btst.b	#0,zoom
	beq.s	letm2
	addq	#8,d5

letm2:

	moveq	#6,d1	;1er ligne est apres premiere ligne de code

chadyfle:

	addq	#8,d1
	cmp.l	(a5)+,a6
	dbeq	d5,chadyfle
	bne.s	affnewfle
*	move	#$0f0,$ffff8240.w
	move	lglabi,d0
	addi	#11,d0
*	moveq	#10+LGLAB+1,d0
	move.l	adrecran,a6
	lea	breaktxtout,a1
	bsr	afflalig

affnewfle:

	move	#6,d1	;afficher nouveau PC
	move	lglabi,d0
	addi	#11,d0
*	moveq	#10+LGLAB+1,d0
	move.l	adrecran,a6
	lea	pcmark,a1
	bsr	afflalig
	move.l	adrpcprg,2+15*4(sp)	;nouveau PC
	bra	retforclav

swap50_60hz:

	movem.l	d0-a6,-(sp)
	move.l	moyenne,d0
	move.l	#moy60,moyenne
	cmp.l	#moy50,d0
	beq.s	set60_hz
	move.l	#moy50,moyenne

set60_hz:

	bsr	restmoyenne
	bra	retforclav

	IFEQ	DEMO

runandbreak:
;cette fonction permet de
;trace une instruction mais un breakpoint
;sera plac‚ a l'adresse du PC apres avoir trace cette
;instruction et le programme sera lance comme CTRL+R en debuts
;d'ou presence d'un flag special
;ceci etant un breakpoint il faut une place dans la liste
;sinon on annule la commande et on met un message

	movem.l	d0-a6,-(sp)
	move.l	adrpcprg,a6
	cmp.l	limiteram,a6
	bhs.s	norunbreak
	clr.b	altrun
	lea	breaklist,a6
	lea	slistill,a4
	moveq	#9,d7

voir_libret:

	addq.l	#2,a4
	tst.l	(a6)+
	dbeq	d7,voir_libret
	bne	nofreet
	subq.l	#4,a6
	subq.l	#2,a4
	move.l	#-1,(a6)
	move.l	a6,libbreakadr
	move.l	a4,libbreakins
	move.l	adrpcprg,outmetbreak
	move.b	#1,altrun

norunbreak:

	movem.l	(sp)+,d0-a6
	bra	contasonly

	ENDC

	IFEQ	DEMO

setletbreak:
;mettre/enlever un breakpoint
;interdiction si adresse pc=adresse debut fenetre
;utiliser alors ALT+R
;impossible de mettre un breakpoint en rom

	movem.l	d0-a6,-(sp)
	bsr	dosetbreak
	bra	retforclav

	ENDC

dosetbreak:

	move.l	dfenster,a5
	lea	juskbreak,a6
	tst.l	(a6)
	beq.s	noisjusk
	cmp.l	(a6),a5
	bne.s	noisjusk
	clr.l	(a6)
	bra.s	retmetlg

noisjusk:

	cmp.l	limiteram,a5
	bhs	nofreet
	cmp.l	adrpcprg,a5
	beq	nofreet
;------------Chercher si il y a deja un breakpoint-----------
	lea	breaklist,a6
	moveq	#9,d7
	move.l	dfenster,d0

voir_pris:

	tst.l	(a6)+
	beq.s	noprisbrk
	cmp.l	-4(a6),d0
	bne.s	noprisbrk
	clr.l	-(a6)

retmetlg:

	moveq	#6,d1
*	moveq	#2+8+LGLAB+1,d0
	move	lglabi,d0
	addi	#11,d0
	move.l	adrecran,a6
	lea	breaktxtout,a1
	bsr	afflalig
	bra.s	nofreet

noprisbrk:

	dbra	d7,voir_pris

;------------------------------------------------------------
	lea	breaklist,a6
	lea	slistill,a4
	moveq	#9,d7

voir_libre:

	addq.l	#2,a4
	tst.l	(a6)+
	dbeq	d7,voir_libre
	bne.s	nofreet
	move.l	a5,-(a6)	;adresse breakpoint
	movec	CACR,d1
	moveq	#0,d0
	movec	d0,CACR
	move	(a5),-(a4)	;sauver valeur instruction
	movec	d1,CACR
	moveq	#6,d1
*	moveq	#2+8+LGLAB+1,d0
	move	lglabi,d0
	addi	#11,d0
	move.l	adrecran,a6
	lea	breaktxt,a1
	bsr	afflalig

nofreet:

	rts

runprg:
;lancer le programme

	tst.b	prgprog
	beq	bcclav
	andi	#$7fff,(sp)

contasonly:

	clr.b	illegbrk
	lea	juskbreak,a6
	tst.l	(a6)
	beq.s	testnvbr
	moveq	#0,d0
	movec	CACR,d1
	movec	d0,CACR
	move.l	(a6),a5	;adresse breakpoint
	move	(a5),juskval
	move	#$4afc,(a5)	;instruction ILLEGAL
	movec	d1,CACR
	move.b	#1,illegbrk

testnvbr:

	lea	breaklist,a6
	moveq	#9,d7

mettrebreak:

	tst.l	(a6)+
	beq.s	nosetit
	cmp.l	#-1,-4(a6)
	beq.s	nosetit
	moveq	#0,d0
	movec	CACR,d1
	movec	d0,CACR
	move.l	-4(a6),a5	;adresse breakpoint
	move	#$4afc,(a5)	;instruction ILLEGAL
	movec	d1,CACR
	move.b	#1,illegbrk

nosetit:

	dbra	d7,mettrebreak

ahlala:

	IFNE	RESIDENT
	bsr	restorevideo
	move.l	sphysbase,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w
	ENDC
	movem.l	regdonnee,d0-d7
	movem.l	regadresse,a0-a6
	move.l	pilerte,a7
	move	(sp),savesr	;sr dans le programme
	clr.b	swaprez	;flag rezo changee
	clr	timer	;timer changement resolution dans vbl
	clr.b	tracenow	;flag=0 -> hors routine trace
	rte

memoifchange:
;reaffiche les contenus de memoire qui changent
;valable pour la fenetre edition memoire
;et pour la fenetre registres pour les registres d'adresse
;le changement fenetre memoire se fait ligne/ligne
;ainsi que pour les registres

	btst.b	#0,zoom
	bne.s	nomemoch
	movem.l	d0-a6,-(sp)
	bsr.s	fortheregs
	bsr.s	forthemem
	movem.l	(sp)+,d0-a6

nomemoch:

	rts

forthemem:
;changement contenu fenetre memoire
;adrdebmem=adresse de debut de la fenetre
;savememfen=anciennes valeurs

	move.l	adrdebmem,a5
	lea	savememfen,a6	;sauvegarde  valeurs memoire
	move.b	#1,scanning	;eviter les erreurs de bus
	moveq	#16*8-2,d5
	moveq	#6,d6

ligsuivm:

*	moveq	#7,d7	;8 octets/ligne
*	move.l	a5,a3
*	move.l	a6,a4
*
*for1ligm:
*
*	move.b	(a5)+,d4
*	tst.b	outmemory
*	beq.s	nometpointi
*	move.b	#"?",d4
*
*nometpointi:
*
*	cmp.b	(a6)+,d4
*	bne.s	refaitlig
*	dbra	d7,for1ligm
*
*lignows:
*
	bsr.s	refaitlig
	addq	#8,d5	;pos y ligne+ 1 ligne
	dbra	d6,ligsuivm
	rts

refaitlig:
;redessiner toute la ligne

*	move.l	a4,a6
*	move.l	a3,a5
	movem.l	a5/a6/d6/d5,-(sp)
	move	#$555,$ffff8242.w
	bsr	afflamem
	movem.l	(sp)+,a5/a6/d6/d5
	addq.l	#8,a5
	addq.l	#8,a6
	rts
*	bra.s	lignows

fortheregs:
;changement valeur/contenu registres An

	lea	saveregn,a0
	lea	rega0ch,a1
	lea	regadresse,a2
	lea	regadresse,a5
	move.b	#-1,(a0)
	moveq	#7,d7

all8rega:

	addq.b	#1,(a0)
	tst.b	(a1)+	;le registre a change de valeur?
	bne.s	noupan	;oui alors pas de test memoire
	bsr	testmemoire	;teste la memoire

noupan:

	dbra	d7,all8rega
	rts

testmemoire:
;teste la memoire
;si elle change
;alors redessiner la memoire du registre d'adresse
;a2=base registres d'adresses

	movem.l	d0-a6,-(sp)
	lea	valofregs,a6	;buffer de sauvegarde memoire
	moveq	#0,d6
	move.b	(a0),d6
	lsl	#2,d6	;index sur 8
	move.l	(a5,d6),a5	;adresse registre adresse
	move.l	a5,saveregv
	lsl	d6
	lea	(a6,d6),a6	;buffer sauvegarde pour ce registre
	moveq	#7,d4

for8all:

	move.b	(a5)+,d5
	tst.b	outmemory
	beq.s	isinmm
	move.b	#"?",d5

isinmm:

	cmp.b	(a6)+,d5
	bne.s	remetreg
	dbra	d4,for8all

retupecra:

	movem.l	(sp)+,d0-a6
	rts

remetreg:
;cas ou la memoire a change depuis dernier trace
;d'ou reaffichage

*	move	#$5f5,$ffff8240.w
	bsr	doupecra
	bra.s	retupecra

regifchange:
;affiche les registres qui ont chang‚

	movem.l	d0-a6,-(sp)
	clr.b	saveregn
	cmp.l	regdonnee,d0
	beq.s	nochd0
	move.l	d0,saveregv
	bsr	doupecr

nochd0:

	addq.b	#1,saveregn
	cmp.l	regdonnee+4,d1
	beq.s	nochd1
	move.l	d1,saveregv
	bsr	doupecr

nochd1:

	addq.b	#1,saveregn
	cmp.l	regdonnee+8,d2
	beq.s	nochd2
	move.l	d2,saveregv
	bsr	doupecr

nochd2:

	addq.b	#1,saveregn
	cmp.l	regdonnee+12,d3
	beq.s	nochd3
	move.l	d3,saveregv
	bsr	doupecr

nochd3:

	addq.b	#1,saveregn
	cmp.l	regdonnee+16,d4
	beq.s	nochd4
	move.l	d4,saveregv
	bsr	doupecr

nochd4:

	addq.b	#1,saveregn
	cmp.l	regdonnee+20,d5
	beq.s	nochd5
	move.l	d5,saveregv
	bsr	doupecr

nochd5:

	addq.b	#1,saveregn
	cmp.l	regdonnee+24,d6
	beq.s	nochd6
	move.l	d6,saveregv
	bsr	doupecr

nochd6:

	addq.b	#1,saveregn
	cmp.l	regdonnee+28,d7
	beq.s	nochd7
	move.l	d7,saveregv
	bsr	doupecr

nochd7:

	clr.b	rega0ch
	cmp.l	regadresse,a0
	beq.s	nocha0
	move.l	a0,saveregv
	move.b	#1,rega0ch
	clr.b	saveregn
	bsr	doupecra

nocha0:

	bsr	savelamem
	clr.b	rega1ch
	cmp.l	regadresse+4,a1
	beq.s	nocha1
	move.b	#1,rega1ch
	move.l	a1,saveregv
	move.b	#1,saveregn
	bsr	doupecra

nocha1:

	bsr	savelamem
	clr.b	rega2ch
	cmp.l	regadresse+8,a2
	beq.s	nocha2
	move.b	#1,rega2ch
	move.l	a2,saveregv
	move.b	#2,saveregn
	bsr	doupecra

nocha2:

	bsr	savelamem
	clr.b	rega3ch
	cmp.l	regadresse+12,a3
	beq.s	nocha3
	move.b	#1,rega3ch
	move.l	a3,saveregv
	move.b	#3,saveregn
	bsr	doupecra

nocha3:

	bsr	savelamem
	clr.b	rega4ch
	cmp.l	regadresse+16,a4
	beq.s	nocha4
	move.b	#1,rega4ch
	move.l	a4,saveregv
	move.b	#4,saveregn
	bsr	doupecra

nocha4:

	bsr	savelamem
	clr.b	rega5ch
	cmp.l	regadresse+20,a5
	beq.s	nocha5
	move.b	#1,rega5ch
	move.l	a5,saveregv
	move.b	#5,saveregn
	bsr	doupecra

nocha5:

	bsr	savelamem
	clr.b	rega6ch
	cmp.l	regadresse+24,a6
	beq.s	nocha6
	move.b	#1,rega6ch
	move.l	a6,saveregv
	move.b	#6,saveregn
	bsr	doupecra

nocha6:
;a7 represente la valeur de pile avant trace
;a7=USP si S=0 dans programme

	bsr	savelamem
	move	16*4(sp),d0	;valeur sr
	movec	USP,a0	;pile utilisateur
	btst	#13,d0	;bit S=0?
	beq.s	thisusp	;oui
;si S=1 (mode superviseur dans programme)
;la pile ISP est utilis‚ dans A7 si M=0
;si M=1 MSP est utilis‚

	movec	ISP,a0	;pile superviseur
	lea	16*4+$c(a0),a0	;valeur dans programme
	btst	#12,d0
	beq.s	thisusp
	movec	MSP,a0
	lea	16*4+$c(a0),a0	;valeur dans programme

thisusp:

	clr.b	rega7ch
	cmp.l	regadresse+28,a0
	beq.s	nocha7
	move.b	#1,rega7ch
	move.l	a0,regadresse+28
	move.l	a0,saveregv
	move.b	#7,saveregn
	bsr	doupecra

nocha7:

	bsr	savelamem
	move.l	USP,a0
	cmp.l	valpile,a0
	beq.s	nochusp
	move.l	a0,valpile	;nouvelle valeur
	btst.b	#0,zoom
	bne.s	nochusp
	bsr	chusp

nochusp:
;la valeur de pile ISP apres une instruction trac‚e
;est # suivant le bit M
;si M=0 la pile ISP est utilis‚e pour sauvegarder
;le contexte
;donc on y ajoute la taille de l'exception trace ($c)
;si M=1 alors la pile MSP est utilis‚
;ISP ne l'est que pour une interruption ce qui
;n'est pas le cas de trace

	movec	ISP,a0	;pile super
	move	16*4(sp),d0	;valeur SR au moment de trace
	btst	#12,d0	;bit M=1?
	bne.s	casmaster	;oui
	lea	$c+16*4(a0),a0	;+taille exception trace

casmaster:

	cmp.l	valisp,a0
	beq.s	nochisp
	move.l	a0,valisp
	btst.b	#0,zoom
	bne.s	nochisp
	bsr	chisp

nochisp:
;pour MSP
;si M=0 alors MSP ne change pas
;si M=1 ajouter la taille de trace ($c)

	movec	MSP,a0
	move	16*4(sp),d0
	btst	#12,d0
	beq.s	mspis
	lea	$c+16*4(a0),a0

mspis:

	cmp.l	valmsp,a0
	beq.s	nochmsp
	move.l	a0,valmsp
	btst.b	#0,zoom
	bne.s	nochmsp
	bsr	chmsp

nochmsp:

	move	savesr,d0
	cmp	savesrcmp,d0
	beq.s	nochsr
	move	savesrcmp,savesr
	move	savesrcmp,d0
	btst.b	#0,zoom
	bne.s	nochsr
	bsr	chsr

nochsr:

	movem.l	(sp)+,d0-a6
	rts

afffenregs:

	btst.b	#0,zoom
	bne	noafff
	lea	regdonnee,a5
	move.b	#"D",d2
	move	#6,d4
	moveq	#48,d5
	bsr	doall
	clr.b	saveregn
	lea	regadresse,a5
	move.b	#"A",d2
	moveq	#48,d5
	move	#10*8-2,d4
	bsr	doall
	bsr	chsr
	bsr	chusp
	bsr	chisp
	bsr	chmsp

noafff:

	rts

chsr:

	lea	texte,a1
	move.b	#"S",(a1)+
	move.b	#"R",(a1)+
	move.b	#"=",(a1)+
	moveq	#0,d7
	move	savesrcmp,d7
	bsr	transhexa3
	clr.b	(a1)
	move.l	adrecran,a6
	lea	texte,a1
	moveq	#60,d0
	move	#6,d1
	bsr	afflalig
	rts

chusp:

	lea	texte,a1
	move.b	#"U",(a1)+
	move.b	#"S",(a1)+
	move.b	#"P",(a1)+
	move.b	#"=",(a1)+
	move.l	valpile,d7
	bsr	transhexa2
	clr.b	(a1)
	move.l	adrecran,a6
	lea	texte,a1
	moveq	#48,d0
	move	#(14+4)*8,d1
	bsr	afflalig
	rts

chisp:

	lea	texte,a1
	move.b	#"I",(a1)+
	move.b	#"S",(a1)+
	move.b	#"P",(a1)+
	move.b	#"=",(a1)+
	move.l	valisp,d7
	bsr	transhexa2
	clr.b	(a1)
	move.l	adrecran,a6
	lea	texte,a1
	moveq	#48,d0
	move	#(14+5)*8,d1
	bsr	afflalig
	rts

chmsp:

	lea	texte,a1
	move.b	#"M",(a1)+
	move.b	#"S",(a1)+
	move.b	#"P",(a1)+
	move.b	#"=",(a1)+
	move.l	valmsp,d7
	bsr	transhexa2
	clr.b	(a1)
	move.l	adrecran,a6
	lea	texte,a1
	moveq	#48,d0
	move	#(14+6)*8,d1
	bsr	afflalig
	rts

doall:

	moveq	#7,d6
	moveq	#0,d3

allregd:

	lea	texte,a1
	move.b	d2,(a1)+
	move.b	d3,(a1)
	addi.b	#"0",(a1)+
	move.b	#"=",(a1)+
	move.l	(a5)+,d7
	bsr	transhexa2
	clr.b	(a1)
	move.l	adrecran,a6
	lea	texte,a1
	move	d5,d0	;pos x
	move	d4,d1	;pos y
	move	d1,-(sp)
	bsr	afflalig
	addq	#8,d4
	addq	#1,d3
	move	(sp)+,d7
	movem.l	d0-d7/a5,-(sp)
	cmp.b	#"A",d2
	bne.s	nofordn
	move	d7,d5	;pos y
	moveq	#0,d7
	move.b	saveregn,d7
	addq.b	#1,saveregn	
	lsl	#2,d7	;*4
	lea	regadresse,a0
	move.l	(a0,d7),a5	;valeur registre adresse
	move	#60,d2	;position x
	bsr	nowlesval

nofordn:

	movem.l	(sp)+,d0-d7/a5
	dbra	d6,allregd
	rts

doupecr:

	movem.l	d0-a6,-(sp)
	lea	regdonnee,a0
	moveq	#0,d1
	move.b	saveregn,d1
	lsl	#2,d1
	move.l	saveregv,(a0,d1)
	btst.b	#0,zoom
	bne.s	noaffreg
	lea	texte,a1
	move.l	saveregv,d7
	bsr	transhexa2
	clr.b	(a1)
	move.l	adrecran,a6
	moveq	#51,d0
	move	#1,d1
	add.b	saveregn,d1
	mulu	#8,d1
	subq	#2,d1
	lea	texte,a1
	bsr	afflalig

noaffreg:

	movem.l	(sp)+,d0-a6
	rts

doupecra:
;affiche la valeur du registre d'adresse voulu
;+le contenu depuis cette adresse
;+sauve le contenu de la memoire pour utilisation ult‚rieure

	movem.l	d0-a6,-(sp)
	lea	regadresse,a0
	moveq	#0,d1
	move.b	saveregn,d1
	lsl	#2,d1
	move.l	saveregv,(a0,d1)
	btst.b	#0,zoom
	bne.s	noupa
	lea	texte,a1
	move.l	saveregv,d7
	bsr	transhexa2
	clr.b	(a1)
	move.l	adrecran,a6
	moveq	#51,d0
	move	#10,d1
	add.b	saveregn,d1
	mulu	#8,d1
	subq	#2,d1
	move	d1,-(sp)
	lea	texte,a1
	bsr	afflalig
	move	(sp)+,d5
	moveq	#0,d7
	move.b	saveregn,d7
	lsl	#2,d7	;*4
	lea	regadresse,a0
	move.l	(a0,d7),a5	;valeur registre adresse
	move	#60,d2	;position x
	bsr	nowlesval

noupa:

	movem.l	(sp)+,d0-a6
	rts

savelamem:
;a5=adresse registre
;d7=index pour un long mot

	movem.l	d0-a6,-(sp)
	moveq	#0,d7
	move.b	saveregn,d7
	lsl	#2,d7
	lea	valofregs,a6
	lea	regadresse,a0
	move.l	(a0,d7),a5	;valeur registre adresse
	lsl	d7	;index 8 octets
	lea	(a6,d7),a6
	moveq	#7,d7	;sauver 8 octets

for8octs:

	move.b	(a5)+,d6
	tst.b	outmemory
	beq.s	setitme
	move.b	#"?",d6

setitme:

	move.b	d6,(a6)+
	dbra	d7,for8octs
	movem.l	(sp)+,d0-a6
	rts

suivre:
;suit le code pas a pas sauf dans exceptions

	ori	#$8000,(sp)	;trace on
	clr	getsaut
	bra	contasonly

traceinto:
;tracer une instruction
;d'ou desasembler ligne PC pour recuperer typesaut
;par CTRL+T-> ne pas rentrer dans les bsr/jsr/trap...
;si on se trouve dans une memoire non modifiable
;alors si bsr/jsr alors modifier adresse retour

	ori	#$8000,(sp)	;trace on
	move.l	adrpcprg,a0
	lea	texte,a1
	move.l	#retdesa,adrretour
	move.l	sp,pile
	bsr	dodesa

retdesa:

	clr.b	scanning
	move.l	pile,sp

nogetsaut:

	move.l	pilerte,a7
	cmp	#2,getsaut
	bne.s	norte
;---------------------------------------------------------
;cas rte alors mettre trace dans pile
	ori	#$8000,12(sp)

norte:

	clr.b	avanttrace
	cmp	#3,getsaut
	bne.s	notraptype
	move.b	#1,avanttrace	;adresse instruction trac‚e

notraptype:

	clr.b	avantsr
	cmp	#1,getsaut
	bne.s	nobjsrtype
	move.b	#1,avantsr

nobjsrtype:

	bra	contasonly

illegalr:

	ILLEGAL

finprg:
;cas fin de programme

	rte

breakprg:

	move.b	#1,nowbreak
	rts

newvbl:
;scrutation du clavier
;on peut breaker un programme qui tourne
;en appuyant sur SHIF DROIT-SHIFT GAUCHE-ALTERNATE
;pratiquement il faut tester le clavier et chercher
;ou bien $2a ou $38 ou $36
;si une des touches apparait alors mettre sa variable associe on
;si le bit 7 est … 1 cela veut dire pas de touche appuye donc on
;recommence depuis le debut
;le break est valide si on a appuye sur les trois touches sans en
;relever aucune (pas de bit 7 … 1)
;si le break est prevu alors eviter un second break

	tst.b	tracenow
	bne.s	noposchange
	addq	#1,timer
	cmp	#30,timer
	bne.s	noposchange
	move.b	#1,swaprez
	clr.b	tracenow
	bsr	restorevideo
	move.l	d0,-(sp)
	move.l	sphysbase,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w
	bsr	overmienne
	move.l	(sp)+,d0

noposchange:
;breakage ou pas suivant valeur de nowbreak

	tst.b	nowbreak
	beq.s	vbl
	tst.b	prgprog
	bne.s	brvbl
	clr.b	nowbreak
	bra.s	vbl

brvbl:

	tst.b	tracenow
	beq.s	dobrvbl
	clr.b	nowbreak
	bra.s	vbl

dobrvbl:

	ori	#$8000,(sp)
	clr.b	nowbreak

vbl:

	jmp	$0	;continuer routine vbl

newdivzero:

	or	#$8000,(sp)
	movem	d0-d1,-(sp)
	movec	CACR,d1
	moveq	#0,d0
	movec	d0,CACR
	move.l	8+4(sp),jmpbreak+2
	movec	d1,CACR
	move.l	#jmpbreak,2+4(sp)
	movem	(sp)+,d0-d1
	move.b	#1,swaprez
	clr.b	tracenow
	movem.l	d0-a6,-(sp)
	lea	divzertxt,a1
	moveq	#1,d0
	move	#24*8-4,d1
	move.l	adrecran,a6
	bsr	afflalig
	movem.l	(sp)+,d0-a6
	rte

newillegal:
;on a affaire a un illegal de debut de programme
;ou on a affaire a un illegal de bsr par exemple
;ou a un breakpoint...

	ori	#$8000,(sp)	;trace on
	clr.b	retbsr
	tst.b	illegbrk
	beq	notstbrk
	clr.b	illegbrk
	movem.l	a0-a2/d0-d1/d7,-(sp)
	tst.l	juskbreak
	beq.s	nojuski
	move.l	juskbreak,a2
	movec	CACR,d1
	moveq	#0,d0
	movec	d0,CACR
	move.l	a2,jmpbreak+2
	move	juskval,(a2)
	clr.l	juskbreak
	movec	d1,CACR
	bra	outbrbr

nojuski:

	lea	breaklist,a0
	lea	slistill,a1
	moveq	#9,d7
	move.l	2+24(sp),d0	;adresse de l'instruction illegal

alllist:

	addq.l	#2,a1
	cmp.l	(a0)+,d0
	dbeq	d7,alllist
	bne	noillegbrk
	clr.l	-(a0)
	move.l	d0,a2
	movec	CACR,d1
	moveq	#0,d0
	movec	d0,CACR
	move.l	a2,jmpbreak+2
	move	-2(a1),(a2)
	movec	d1,CACR

outbrbr:

	movem.l	(sp)+,a0-a2/d0-d1/d7
	move.b	#1,frombreak
	move.l	#jmpbreak,2(sp)
	rte

noillegbrk:

	movem.l	(sp)+,a0-a2/d0-d1/d7

notstbrk:

	tst.b	illegdeb
	beq.s	illegbsr
;illegal de debut
;remettre bonne instruction
;et partir dans la routine trace
	clr.b	illegdeb
	movem.l	d0/d1/a0,-(sp)
	movec	CACR,d1
	moveq	#0,d0	;enlever les caches
	movec	d0,CACR
	move.l	dfenster,a0	;adresse de debut du programme
	move.l	a0,jmpbreak+2
	move	saveil,(a0)
	move.l	#jmpbreak,2+12(sp)
	movec	d1,CACR
	movem.l	(sp)+,d0/d1/a0
	rte

illegbsr:

	movem.l	a0/d0-d1,-(sp)
;-------------------------------------------------------
;utilisation d'une pile pour sauver les illegal apres bsr
;ou trap
;contenu pointeur courant est zero
;contenu pointeur -4 contient adresse
;si celui ci =0 alors debut de pile

	move.l	pileilgal,a0
	tst.l	-4(a0)
	beq.s	noisbsr
	move.l	-4(a0),a0	;adresse retour
	cmp.l	#0,a0
	beq.s	noisbsr
	subq.l	#4,pileilgal

contillb:

	moveq	#0,d0
	movec	CACR,d1
	movec	d0,CACR
	move.l	a0,jmpbreak+2
	move.l	#jmpbreak,2+12(sp)	;adresse de retour
	movec	d1,CACR
	movem.l	(sp)+,a0/d0-d1
	rte

jmpbreak:

	jmp	$0

noisbsr:
;instruction illegal et erreur

	movem.l	(sp)+,a0/d0-d1
	movem.l	d0-a6,-(sp)
	lea	illegtxt,a1
	move.b	#1,tracenow
	move.b	#1,swaprez
	moveq	#1,d0
	move	#24*8-4,d1
	move.l	adrecran,a6
	bsr	afflalig
	movem.l	(sp)+,d0-a6
	movem	d0-d1,-(sp)
	moveq	#0,d0
	movec	CACR,d1
	movec	d0,CACR
	move.l	2+4(sp),jmpbreak+2
	move.l	#jmpbreak,2+4(sp)
	movec	d1,CACR
	movem	(sp)+,d0-d1
	rte

finirx:
;finir un programme revient a pointer sur un clr -(sp) et trap #1

	lea	(a7),a0
	andi	#$7fff,(a0)	;supprimer mode trace
	move.l	#finiri,2(a0)
	rte

chargerprg:
;charger un programme en memoire
;si pas d'extension prise extension PRG puis APP,TOS

	movem.l	d0-d7/a1-a6,-(sp)
	lea	ligcharger,a1
	moveq	#24,d6
	bsr	getname	;recuperer nom fichier
	tst.b	d7
	bne.s	nodochprg
	bsr	execcharge

nodochprg:

	movem.l	(sp)+,d0-d7/a1-a6
	bra	bcclav0

getname:

	move	#24*8-4,d1	;pos y
	moveq	#1,d0	;pos x
	move.l	adrecran,a6
	bsr	afflalig
	lea	buffer,a5
	move.b	#127,(a5)

bcgetclav:

	bsr	gettouche
	cmp.l	#$000E0000,d0
	beq.s	delcari
	cmp.l	#$00010000,d0
	beq	outchargei
	cmp.l	#$001c0000,d0
	beq.s	docharge
	cmp.b	#",",d1
	beq.s	getfin2
	cmp.b	#":",d1
	beq.s	boncar
	cmp.b	#"\",d1
	beq.s	boncar
	cmp.b	#".",d1
	beq.s	boncar
	cmp.b	#"_",d1
	beq.s	boncar
	cmp.b	#"a",d1
	blo.s	peutup
	cmp.b	#"z",d1
	bhi.s	bcgetclav
	bra.s	boncar

delcari:

	moveq	#24,d7
	bsr	dodelcar
	bra.s	bcgetclav

peutup:

	cmp.b	#"A",d1
	bhs.s	nonombre
	cmp.b	#"0",d1
	blo.s	bcgetclav
	cmp.b	#"9",d1
	bhi.s	bcgetclav
	bra.s	boncar

nonombre:

	cmp.b	#"Z",d1
	bhi.s	bcgetclav

boncar:

	cmp	#78,d6
	bhs.s	bcgetclav
	bsr	doboncar
	bra.s	bcgetclav

docharge:

	bsr	videlalig

getfin2:

	cmp.b	#127,(a5)+
	bne.s	getfin2
	clr.b	-(a5)
	clr.b	d7
	rts

outchargei:

	bsr	videlalig

outcharge:

	move.b	#1,d7
	rts

execcharge:

	move.l	adrsymboles,d0
	bsr	mfree
	clr.l	adrsymboles
	move.l	adrtext,d0
	bsr	mfree
	clr.l	adrtext
	move.l	adrbss,d0
	bsr	mfree
	clr.l	adrbss
	move.l	adrdata,d0
	bsr	mfree
	clr.l	adrdata
	lea	buffer,a5

;---------------------------------------------------------------
;on verifie la ligne de fichier
;ou regarde si on doit changer le rep/defaut et le drive/defaut

	bsr	seeifext

	bsr	traiterep
	tst.b	d7
	bne	outcharge

	clr	-(sp)	;ouvrir le fichier
	pea	buffer	;pour recuperer les labels
	move	#$3d,-(sp)	;s'ils existent
	trap	#1
	addq.l	#8,sp
	tst.l	d0
	bmi	outcharge

	move	d0,shandle

	pea	entete
	move.l	#18,-(sp)
	move	d0,-(sp)
	move	#$3f,-(sp)
	trap	#1
	lea	12(sp),sp
	tst.l	d0
	bmi	outcharge
	cmp.l	#18,d0
	bne	outcharge

	clr.b	tabsymb
	lea	entete,a0
	move.l	14(a0),d1	;taille table des symboles
	beq	notabsymb
	move.l	d1,d7
	divu	#14,d7	;/14
	bvs	notabsymb	;taille superieur … 14*FFFF alors pas de symboles
	swap	d7
	tst	d7
	bne	notabsymb
	swap	d7
	subq	#1,d7
	move	d7,nbsymboles

	move.l	d1,taillesymbs
	bsr	malloc
	tst.l	d0
	bmi	notabsymb
	move.l	d0,adrsymboles

	moveq	#$1c,d7	;taille entete
	add.l	2(a0),d7	;+taille texte
	add.l	6(a0),d7	;+taille datas

	clr	-(sp)
	move	shandle,-(sp)
	move.l	d7,-(sp)
	move	#$42,-(sp)
	trap	#1
	lea	10(sp),sp

	cmp.l	d7,d0
	bne	notabsymb

	move.l	adrsymboles,-(sp)	;lire la table des symboles
	move.l	taillesymbs,-(sp)	;en memoire
	move	shandle,-(sp)
	move	#$3f,-(sp)
	trap	#1
	lea	12(sp),sp

	tst.l	d0
	bmi	notabsymb
	cmp.l	taillesymbs,d0
	bne	notabsymb
	move.b	#1,tabsymb
	bsr	triertable	;tri la table et accelere la recherche
	bra	yestabsymb

seeifext:
;verifie si extension
;sinon ajouter PRG par defaut ou APP ou TOS

	movem.l	d0-a6,-(sp)
	lea	buffer,a0
	move.l	a0,a1

getfbuf:

	tst.b	(a0)+
	bne.s	getfbuf

bctrdebi:

	cmp.l	a1,a0
	beq.s	istrdeb
	cmp.b	#"\",-(a0)
	beq.s	istrdeb
	cmp.b	#".",(a0)
	bne.s	bctrdebi
	bra	istrdebi

istrdeb:
;cas pas de "."

	tst.b	(a0)+
	bne.s	istrdeb
	subq.l	#1,a0
	move.b	#".",(a0)+
	move.b	#"P",(a0)+
	move.b	#"R",(a0)+
	move.b	#"G",(a0)+
	clr.b	(a0)

istrdebi:

	movem.l	(sp)+,d0-a6
	rts

traiterep:

	bsr	uplesmins
	moveq	#0,d7	;flag erreur off
	lea	buffer,a5	;ligne [drive]+[path]+nom fichier
	cmp.b	#":",1(a5)
	bne.s	nochdrive
	moveq	#0,d5
	move.b	(a5),d5	;numero de drive de A … P
	cmp.b	#"P",d5
	bhi.s	erret
	cmp.b	#"A",d5
	blo.s	erret
	move	d5,-(sp)	;Dsetdrive
	move	#$e,-(sp)
	trap	#1
	addq.l	#4,sp	
	addq.l	#2,a5	;suite path

nochdrive:

	cmp.b	#"\",(a5)
	bne.s	nochpath
	move.l	a5,a4

getfin:

	tst.b	(a4)+
	bne	getfin

getanti:

	cmp.b	#"\",-(a4)
	bne.s	getanti
	clr.b	(a4)
	pea	buffer	;Dsetpath
	move	#$3b,-(sp)
	trap	#1
	addq.l	#6,sp
	move.b	#"\",(a4)

nochpath:

	rts

erret:
;erreur dans la recherche du path/drive donc abandonner

	moveq	#1,d7	;flag erreur on
	rts

uplesmins:
;scanne l'entree de masque
;minuscules->majuscules

	lea	buffer,a2

bcmask:

	tst.b	(a2)+
	beq.s	endmask
	cmp.b	#"a",-1(a2)
	blo.s	nominu
	cmp.b	#"z",-1(a2)
	bhi.s	nominu
	subi.b	#"a"-"A",-1(a2)

nominu:

	bra.s	bcmask

endmask:

	rts
triertable:
;tri la table et accelere la recherche
;des labels suivant une adresse et le type de zone (text,data,bss)
;bit 0 de bloc14bits+8 est 1 si zone BSS
;bit 1 pour zone TEXT
;bit 2 pour zone DATA
;un label prend 1 bloc ou 2 blocs max (max 22 de long 8+14)
;bloc long si bit bloc+8+1 different de zero ($48)
;sauver le debut de chaque zone de table
;pour chaque symbole, son offset

	moveq	#0,d1
	bsr	getnumber
	move	d0,nbbss
	move	d3,ttbss
	moveq	#1,d1
	bsr	getnumber
	move	d0,nbtext
	move	d3,tttext
	moveq	#2,d1
	bsr	getnumber
	move	d0,nbdata
	move	d3,ttdata

	move	ttbss,d1
	mulu	#16,d1
	beq.s	nobss
	bsr	malloc
	tst.l	d0
	bmi	notabsymb
	move.l	d0,adrbss

nobss:

	move	ttdata,d1
	mulu	#16,d1
	beq.s	nodata
	bsr	malloc
	tst.l	d0
	bmi	notabsymb
	move.l	d0,adrdata

nodata:

	move	tttext,d1
	mulu	#14,d1
	beq.s	notext
	bsr	malloc
	tst.l	d0
	bmi	notabsymb
	move.l	d0,adrtext

notext:

	move	nbbss,d5
	beq.s	notable1
	move.l	adrbss,a0	;but
	moveq	#0,d6
	bsr.s	gettabletrier

notable1:

	move	nbtext,d5
	beq.s	notable2
	move.l	adrtext,a0	;but
	moveq	#1,d6
	bsr.s	gettabletrier

notable2:

	move	nbdata,d5
	beq.s	notable3
	move.l	adrdata,a0	;but
	moveq	#2,d6
	bsr.s	gettabletrier

notable3:

	rts

gettabletrier:
;creer une table pour chaque zone
;avec l'offset dans le programme et l'adresse dans symboles
;pour chaque symbole
;puis tri cette liste
;a0=adresse debut table
;a1=adresse symboles
;d5=nbre de symboles de la zone
;d6=type de zone 0=BSS,1=TEXTE,2=DATA

	move	nbbss,d7
	add	nbdata,d7
	add	nbtext,d7
	subq	#1,d7
	move.l	adrsymboles,a1	;source

allset:

	btst.b	d6,8(a1)
	beq.s	nothis
	move.l	10(a1),(a0)+
	move.l	a1,(a0)+

nothis:

	lea	14(a1),a1
	tst.b	-14+9(a1)
	beq.s	noadd14
	lea	14(a1),a1

noadd14:

	dbra	d7,allset
	rts

getnumber:

	moveq	#0,d3
	moveq	#0,d0
	move.l	adrsymboles,a0
	move	nbsymboles,d7

allsymbs:

	btst	d1,8(a0)
	beq.s	noadd
	addq	#1,d0
	addq	#1,d3
	tst.b	9(a0)
	beq.s	noadd
	addq	#1,d3

noadd:

	lea	14(a0),a0
	tst.b	-14+8+1(a0)
	beq.s	nolo8
	subq	#1,d7
	bmi.s	endget
	lea	14(a0),a0

nolo8:

	dbra	d7,allsymbs

endget:

	rts

notabsymb:

	clr.l	adrsymboles
	clr.b	tabsymb

yestabsymb:

	move	shandle,-(sp)	;fermer le fichier
	move	#$3e,-(sp)
	trap	#1
	addq.l	#4,sp
;on charge et execute le programme
;le mode trace doit etre activ‚

	pea	envp
	pea	cmdl
	pea	buffer
	move	#3,-(sp)	;charge
	move	#$4b,-(sp)
	trap	#1
	lea	16(sp),sp

	move.b	#1,prgprog
	move.l	d0,basepage
	move.l	d0,a0
	move.l	$10(a0),adrdata0
	move.l	$18(a0),adrbss0
	lea	adrfin,a6
	move.l	$18(a0),(a6)
	move.l	$1c(a0),d7
	add.l	d7,(a6)
	move.l	8(a0),a0
	move.l	a0,adrpcprg
	move.l	a0,adrdebut
	move.l	a0,dfenster	;adresse 1er ligne fenetre
	clr.b	illegbrk
	move.b	#1,illegdeb	;mark illegal de debut de programme
	movec	CACR,d0
	move	d0,savecacr
	moveq	#0,d0	;enlever les caches
	movec	d0,CACR
	move	(a0),saveil
	move	#$4afc,(a0)	;instruction illegal

	bsr	restorevideo
	move.l	sphysbase,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w
	move.b	#1,swaprez

	move.l	#pilegal,pileilgal

	movec	USP,a0
	move.l	a0,valpile
	movec	ISP,a0
	move.l	a0,valisp
	movec	MSP,a0
	move.l	a0,valmsp

	move.l	basepage,-(sp)
	move.l	basepage,-(sp)
	move.l	basepage,-(sp)
	move	#4,-(sp)	;execute
	move	#$4b,-(sp)
	trap	#1
	lea	16(sp),sp	;ici on sort du programme

	move.l	basepage,d0
	bsr	mfree
	clr.l	basepage

	clr.b	prgprog

	move.b	#1,tracenow
	bsr	restmoyenne
	move.l	adrecran,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w

	move	#24*8-4,d1	;pos y
	moveq	#1,d0	;pos x
	lea	finprogramme,a1
	move.l	adrecran,a6
	bsr	afflalig
	rts

videlalig:

	movem.l	d0-a6,-(sp)
	lea	videligne,a1
	move.l	adrecran,a6
	moveq	#1,d0
	move	#24*8-4,d1
	bsr	doafflig
	movem.l	(sp)+,d0-a6
	rts

errorlire:

	lea	eroliretxt,a1
	bra.s	ent2err

erroropen:

	lea	erropentxt,a1

ent2err:

	move.l	adrecran,a6
	moveq	#1,d0
	move	#24*8-4,d1
	bsr	afflalig
	bsr	gettouche
	bra	outcharge

flipecrrez:
;changer l'adresse physique et la resolution
;et la palette

	movem.l	d0-a6,-(sp)
	bsr	restorevideo
	bsr	restpalette
	move.l	sphysbase,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w

bcclav2:

	bsr	gettouche
*	move	#$f00,$ffff8240.w
	cmp.l	#$002F0000,d0
	bne.s	bcclav2
	bsr	restmoyenne
*	clr	$ffff8246.w
	move.l	adrecran,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w
	bra	retforclav


pagebas:

	movem.l	d0-a6,-(sp)
	move.l	efenster,dfenster
	move.l	dfenster,a0
*	moveq	#NBLIG-1,d7	;lire 11 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa
	bra	retforclav

pagehaut:

	movem.l	d0-a6,-(sp)
*	REPT	NBLIG
	moveq	#NBLIG-1,d7
	btst.b	#0,zoom
	beq.s	dodoi
	addq	#8,d7

dodoi:

	bsr	dohaut
	move.l	saveadra0,dfenster	;adresse debut fenetre
	dbra	d7,dodoi
*	ENDR
	move.l	dfenster,a0	;adresse 1er ligne fenetre
*	moveq	#NBLIG-1,d7	;lire 11 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa
	bra	retforclav

getadr:
;changer l'adresse de debut de la fenetre
;possiblite d'entrer des labels
;ainsi que des registres A0...A7, D0...D7, USP,SSP,ISP,CAAR,VBR....

	movem.l	d0-d7/a1-a7,-(sp)
	lea	buffer,a1
	move.l	#"Adre",(a1)+
	move.l	#"sse:",(a1)+
	move	#" ",(a1)+
	clr.b	(a1)
	move	#24*8-4,d1	;pos y
	moveq	#1,d0	;pos x
	lea	buffer,a1
	move.l	adrecran,a6
	bsr	afflalig
	move.l	#buffer,a5
	move.l	a5,debutoflig
	move.b	#127,(a5)
	moveq	#10,d6
	moveq	#10,d7
	bsr	bcgetadr
	cmp.l	#$10000,d0
	beq.s	noadrc
	bsr	calcadr
	move.l	d6,a0	;nouvelle adresse
	move.l	a0,dfenster
*	moveq	#NBLIG-1,d7	;lire 11 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa

noadrc:

	bsr	videlalig
	movem.l	(sp)+,d0-d7/a1-a7
	move.l	retclav,a6
	jmp	(a6)

bcgetadr:

	bsr	gettouche
	cmp.l	#$000E0000,d0
	beq.s	delcar
	cmp.b	#$22,d1
	beq	setnumber
	cmp.b	#",",d1
	beq	sortadr
	cmp.l	#$10000,d0
	beq	sortadr
	cmp.l	#$001c0000,d0
	beq	sortadr
	cmp.b	#"{",d1
	beq.s	setnumber
	cmp.b	#"}",d1
	beq.s	setnumber
	cmp.b	#"=",d1
	beq.s	setnumber
	cmp.b	#"_",d1
	beq.s	setnumber
	cmp.b	#"$",d1
	beq.s	setnumber
	cmp.b	#"\",d1
	beq.s	setnumber
	cmp.b	#"0",d1
	blo.s	bcgetadr
	cmp.b	#"9",d1
	bls.s	setnumber
	cmp.b	#"A",d1
	blo.s	bcgetadr
	cmp.b	#"Z",d1
	bls.s	setnumber
	cmp.b	#"a",d1
	blo.s	bcgetadr
	cmp.b	#"z",d1
	bls.s	setnumber
	bra.s	bcgetadr

delcar:

	bsr.s	dodelcar
	bra.s	bcgetadr

dodelcar:

	cmp	d7,d6
	beq.s	noposdel
	subq.l	#1,a5
	move.l	a5,a1
	move.b	#127,(a1)
	move.b	#" ",1(a1)
	clr.b	2(a1)
	subq	#1,d6
	move	d6,d0
	move	#24*8-4,d1
	move.l	adrecran,a6
	bsr	doafflig

noposdel:

	rts

setnumberp:

	subi.b	#"a"-"A",d1

setnumber:

	cmp	#78,d6
	bhs	bcgetadr
	bsr.s	doboncar
	bra	bcgetadr

doboncar:

	move.l	a5,a1
	move.b	d1,(a1)
	move.b	#"",1(a1)
	clr.b	2(a1)
	addq.l	#1,a5
	move	d6,d0
	addq	#1,d6
	move	#24*8-4,d1
	move.l	adrecran,a6
	bsr	doafflig
	rts

calcadr:
;calcul de l'adresse
;si l'adresse est mauvaise, retour a la saisie
;d'abord rechercher si c'est un registre quelconque ou un label
;si non alors essayer comme un nbre
;resultat dans d6.l
;adresse source dans debutoflig
;{adresse} pour contenu a l'adresse en long mot

	clr.b	contofit
	move.l	debutoflig,a6
	cmp	#"w1",(a6)
	beq.s	gow1
	cmp	#"W1",(a6)
	beq.s	gow1
	cmp	#"w2",(a6)
	beq.s	gow2
	cmp	#"W2",(a6)
	beq.s	gow2
	cmp.l	#$50437f00,(a6)	;PC
	beq.s	gopc
	cmp.l	#$70637f00,(a6)	;PC
	beq.s	gopc
	cmp.b	#"{",(a6)
	bne.s	nocontof
	move.b	#1,contofit
	addq.l	#1,a6
	addq.l	#1,debutoflig
	bra	calcasnumber

nocontof:

	cmp.b	#"$",(a6)
	beq	calcasnumber
	lea	regdonnee,a5
	cmp.b	#"D",(a6)
	beq.s	firstAD
	cmp.b	#"d",(a6)
	beq.s	firstAD
	lea	regadresse,a5
	cmp.b	#"A",(a6)
	beq.s	firstAD
	cmp.b	#"a",(a6)
	beq.s	firstAD
	bra	noposregd

gow2:

	move.l	adrdebmem,d6
	bra	sortadr

gow1:

	move.l	dfenster,d6
	bra	sortadr

gopc:

	move.l	adrpcprg,d6
	bra	sortadr

firstAD:

	cmp.b	#"9",1(a6)
	bhi.s	noposregd
	cmp.b	#"0",1(a6)
	blo.s	noposregd
	cmp.b	#"",2(a6)
	bne.s	noposregd

casregda:
;cas entree d'un registre de donn‚e

	moveq	#0,d0
	move.b	1(a6),d0
	subi.b	#"0",d0
	mulu	#4,d0
	move.l	(a5,d0.l),d6
	bra	sortadr

noposregd:
;essayer avec les labels
;seulement si on a un program charg‚

	tst.b	prgprog	;programme en m‚moire
	beq	calcasnumber	;non
	move.l	adrsymboles,a5
	move	nbsymboles,d6
	move.l	debutoflig,a6
	move.l	a6,a3

nextlab:

	move.l	a5,a4
	move.l	a3,a6
	moveq	#7,d7

seeit:

	cmp.b	#127,(a6)
	beq.s	endlabent
	cmp.b	(a6)+,(a4)+
	dbne	d7,seeit
	bne.s	noseelong
	cmp.b	#127,(a6)	;label de 8 car
	beq.s	usethios	;oui alors peut etre
;-----------------------------------------
;cas label de plus de 8 caractere
	tst.b	9(a5)	;continuer sur suite label
	beq.s	noseelong	;non
;cas label de plus de 8 cars sur +14
	lea	14(a5),a4	;partie 2 du label
	moveq	#13,d7	;long max

seeit2:

	cmp.b	#127,(a6)
	beq.s	usethios
	cmp.b	(a6)+,(a4)+
	dbne	d7,seeit2
	beq.s	endlabent

noseelong:

	lea	14(a5),a5
	tst.b	-14+9(a5)
	beq.s	nomons
	subq	#1,d6
	bmi.s	endlist
	lea	14(a5),a5

nomons:

	dbra	d6,nextlab

endlist:

	bra.s	calcasnumber

usethios:

	cmp.b	#127,(a6)
	bne.s	calcasnumber

endlabent:

	move.l	10(a5),d6
	btst.b	#0,8(a5)	;zone
	beq.s	nobsszone
	add.l	adrbss0,d6
	bra.s	sortadr

nobsszone:

	btst.b	#1,8(a5)
	beq.s	notextzone
	add.l	adrdebut,d6
	bra.s	sortadr

notextzone:

	btst.b	#2,8(a5)
	beq.s	calcasnumber
;zone data
	add.l	adrdata0,d6
	bra.s	sortadr

calcasnumber:
;calcul avec buffer=nbre hexa
;possibilit‚ fin par }

	move.l	debutoflig,a6
	moveq	#0,d6

bcadr:

	moveq	#0,d7
	move.b	(a6)+,d7
	cmp.b	#127,d7
	beq.s	sortadr
	cmp.b	#"}",d7
	beq.s	sortadr
	subi.b	#"0",d7
	cmp.b	#9,d7
	bls.s	boncomme
	subi.b	#-"0"+"A"-10,d7

boncomme:

	lsl.l	#4,d6
	add.l	d7,d6
	bra.s	bcadr

sortadr:
;d6=adresse obtenue

	tst.b	contofit
	beq.s	noofit
;cas recuperer contenu de d6
	move.l	d6,a5
	move.b	#1,scanning
	moveq	#0,d6
	moveq	#4,d5

for4fois:

	move.b	(a5)+,d6
	tst.b	outmemory
	beq.s	noch1d6
	move.b	#"?",d6

noch1d6:

	subq	#1,d5
	beq.s	noofit
	lsl.l	#8,d6
	bra.s	for4fois

noofit:

	clr.b	scanning
	rts

moins2:

	movem.l	d0-a6,-(sp)
	subq.l	#2,dfenster
	move.l	dfenster,a0
*	moveq	#NBLIG-1,d7	;lire 11 ligne
	move	#1,posdeby
	clr	premadr
	bsr	bcdesa
	bra	retforclav

plus2:

	movem.l	d0-a6,-(sp)
	addq.l	#2,dfenster
	move.l	dfenster,a0
*	moveq	#NBLIG-1,d7	;lire 11 ligne
	move	#1,posdeby
	clr	premadr
	bsr	bcdesa
	bra	retforclav

verslebas:

	movem.l	d0-a6,-(sp)
	bsr.s	execbas
	bra	retforclav

execbas:

	move.l	pfenster,a0	;nouvelle adresse debut fenetre
	move.l	a0,dfenster
	bsr	scrhaut	;scroller fenetre

	move.l	#retadr,adrretour
	move.l	a7,pile
	lea	texte,a1	;adresse desassemblage
	move.l	efenster,a0
	move.l	a0,savepc
	bsr	dodesa

retadr:

	clr.b	scanning
	clr.b	(a1)
	move.l	pile,a7
	move.l	a0,efenster
	move.l	pfenster,a0	;nouvelle adresse debut fenetre

	lea	pfenster,a6
	lea	typesaut,a4
	lea	4(a6),a5
	lea	2(a4),a3

	moveq	#NBLIG-2,d7
	btst.b	#0,zoom
	beq.s	sucetoi
	addq	#8,d7
*	REPT	NBLIG-1
sucetoi:

	move.l	(a5)+,(a6)+
	move	(a3)+,(a4)+
*	ENDR
	dbra	d7,sucetoi

	btst.b	#0,zoom
	beq.s	asit
	move	getsaut,typesaut+(NBLIG-1+8)*2
	move.l	efenster,pfenster+(NBLIG-1+8)*4
	bra.s	noit

asit:

	move	getsaut,typesaut+(NBLIG-1)*2
	move.l	efenster,pfenster+(NBLIG-1)*4

noit:

	move	#NBLIG,posdeby	;position y derniere ligne
	btst.b	#0,zoom
	beq.s	lechemoi
	addq	#8,posdeby

lechemoi:

	bsr	afflig
	rts

verslehaut:
;methode utilisee
;remonter jusqu'a -6 par pas de 2
;si -6 termine a adresse courante alors la prendre
;si -4 termine a adresse courante alors la prendre
;si -2 termine a adresse courante alors la prendre

	movem.l	d0-a6,-(sp)
	bsr	dohaut	;reculer de n mots
	tst	d7
	bne.s	enthaut
	move.l	saveadra0,a0	;adresse 1er ligne fenetre
	move.l	a0,dfenster
*	moveq	#NBLIG-1,d7	;lire 12 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa
	bra	retforclav

enthaut:

	bsr	scrbas
	move.l	saveadra0,a0	;adresse 1er ligne fenetre
	move.l	a0,dfenster
	move.l	#retadri,adrretour
	move.l	sp,pile
	lea	texte,a1	;adresse desassemblage
	move.l	a0,savepc
	bsr	dodesa

retadri:

	clr.b	scanning
	clr.b	(a1)
	move.l	pile,sp

	lea	pfenster+NBLIG*4,a6
	btst.b	#0,zoom
	beq.s	noaddf
	lea	32(a6),a6

noaddf:

	lea	-4(a6),a5
	move.l	-4(a5),efenster

	move	#NBLIG-2,d7
*	REPT	NBLIG-1
	btst.b	#0,zoom
	beq.s	sucemoi
	addq	#8,d7

sucemoi:

	move.l	-(a5),-(a6)
*	ENDR

	dbra	d7,sucemoi
	move.l	a0,pfenster

	move	#1,posdeby	;position debut y
	bsr	afflig
	bra	retforclav

dohaut:
;remonte de 10 bytes
;si l'adresse fin instruction n'est pas celle debut ancienne
;alors essayer avec 8,6,4,2
;si avec 2 on n'obtient pas satisfaction alors
;la fenetre doit etre redessiner entierement car decalages des instruction

	move	d7,-(sp)
	move.l	dfenster,a0	;adresse debut fenetre
	move.l	#retp,adrretour
	lea	-10(a0),a0
	move.l	a0,saveadra0
	move.l	sp,pile
	move.l	a0,savepc
	lea	texte,a1
	bsr	dodesa

retp:

	clr.b	scanning
	move.l	pile,sp
	cmp.l	dfenster,a0
	beq	prendit
	move.l	dfenster,a0	;adresse debut fenetre
	move.l	#ret0,adrretour
	subq.l	#8,a0
	move.l	a0,saveadra0
	move.l	sp,pile
	move.l	a0,savepc
	lea	texte,a1
	bsr	dodesa

ret0:

	clr.b	scanning
	move.l	pile,sp
	cmp.l	dfenster,a0
	beq	prendit
	move.l	dfenster,a0	;adresse debut fenetre
	move.l	#ret1,adrretour
	subq.l	#6,a0
	move.l	a0,saveadra0
	move.l	sp,pile
	move.l	a0,savepc
	lea	texte,a1
	bsr	dodesa

ret1:

	clr.b	scanning
	move.l	pile,sp
	cmp.l	dfenster,a0
	beq.s	prendit
	move.l	#ret2,adrretour
	move.l	dfenster,a0	;adresse debut fenetre
	subq.l	#4,a0
	move.l	a0,saveadra0
	move.l	sp,pile
	move.l	a0,savepc
	lea	texte,a1
	bsr	dodesa

ret2:

	clr.b	scanning
	move.l	pile,sp
	cmp.l	dfenster,a0
	beq.s	prendit
	move.l	#prendit,adrretour
	move.l	dfenster,a0	;adresse debut fenetre
	subq.l	#2,a0
	move.l	a0,saveadra0
	move.l	sp,pile
	move.l	a0,savepc
	lea	texte,a1
	bsr	dodesa

prendit:

	clr.b	scanning
	move.l	pile,sp
	moveq	#1,d7
	cmp.l	dfenster,a0
	beq.s	nodraw
	moveq	#0,d7	;flag fenetre a redessiner entierement

nodraw:

	move	(sp)+,d7
	rts

finir:

	bsr	restorevideo
	bsr	restpalette
	move.l	sphysbase,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w

	move.l	ancimp,$502.w
	move.l	anctrap1,$84.w
	move.l	anctrap13,$b4.w
	move.l	anctrap14,$b8.w
	move.l	ancbuser,$8.w
	move.l	ancadrer,$c.w
	move.l	ancdivzero,$14.w
	move.l	anctrace,$24.w
	move.l	ancillegal,$10.w
	move.l	ancvbl,$70.w


	move.l	adrtext,d0
	bsr	mfree
	move.l	adrbss,d0
	bsr	mfree
	move.l	adrdata,d0
	bsr	mfree
	move.l	adrsymboles,d0
	bsr	mfree
	move.l	basepage,d0
	bsr	mfree
	move.l	adrsymboles,d0
	bsr	mfree

	move.l	savessp,-(sp)
	move	#$20,-(sp)
	trap	#1
	addq.l	#6,sp

finiri:

	clr	-(sp)
	trap	#1


mfree:

	tst.l	d0
	beq.s	nofree
	move.l	d0,-(sp)
	move	#$49,-(sp)
	trap	#1
	addq.l	#6,sp

nofree:

	rts

bcdesa:

	moveq	#NBLIG-1,d7
	btst.b	#0,zoom
	beq.s	letlig
	addq	#8,d7

letlig:

	move.l	sp,pile
	lea	texte,a1
	move.l	a0,savepc
	move	d7,savecompt
	move.l	#retour,adrretour
	clr.b	bad
	lea	texte,a1
	bsr	dodesa

retour:

	clr.b	scanning
	lea	pfenster,a6
	move	premadr,d6
	move.l	a0,(a6,d6.w)
	lea	typesaut,a6
	lsr	d6
	move	getsaut,(a6,d6)
	addq	#4,premadr

	move.l	pile,sp
	clr.b	(a1)
	bsr	afflig

	move	savecompt,d7
	dbra	d7,letlig
	move.l	a0,efenster	;adresse prochaine ligne en bas
	rts

gettouche:
;recuperer touche clavier
;d0=xxxx---- avec xxxx code scan (low byte)
;d0=----bbbb avec bit significatifs comme suit
;bit 0=SHIFT DROIT
;bit 1=SHIFT GAUCHE
;bit 2=CONTROL
;bit 3=ALT

	move	#$b,-(sp)
	trap	#1
	addq.l	#2,sp
	tst	d0
	beq.s	gettouche
	move	#7,-(sp)
	trap	#1
	addq.l	#2,sp
	move	d0,-(sp)
	andi.l	#$00FF0000,d0
	move.l	d0,-(sp)
	move	#-1,-(sp)
	move	#$b,-(sp)
	trap	#13
	addq.l	#4,sp
	or.l	(sp)+,d0
	move	(sp)+,d1	;code ascii
	rts

scrbas:

	move	#1,d4	;scroll bas

entscr:

	move.l	adrecran,a6
	moveq	#1,d0
	moveq	#1,d1
	moveq	#NBLIG,d2
	move.l	#44,d3
	btst.b	#0,zoom
	beq.s	let44
	move.l	#78,d3
	addq	#8,d2

let44:

	bsr	scrolllig
	rts

scrhaut:

	moveq	#0,d4	;scroll bas
	bra.s	entscr

afflig:

	movem.l	d0-a7,-(sp)
	move.l	a1,d6
	lea	buffer,a1
	move	#256/4-1,d5

met20p:

	move.l	#$20202020,(a1)+
	dbra	d5,met20p
*	move.l	#$20202020,(a1)+	;mise a zero du buffer de sortie
*	move.l	#$20202020,(a1)+
*	clr.b	(a1)+
*	move.b	#$20,(a1)+
*	move.l	#$20202020,(a1)+
*	move.l	#$20202020,(a1)+
*	move.l	#$20202020,(a1)+
*	move.l	#$20202020,(a1)+
*	move.l	#$20202020,(a1)+
*	move.l	#$20202020,(a1)+
*	move.l	#$20202020,(a1)+
*	move.l	#$20202020,(a1)+
*	move	#$2020,(a1)+
*	clr.b	(a1)+
	lea	buffer,a1
	move.l	savepc,d7
	move.l	d7,d5
	bsr	transhexa2
	move.l	#buffer+10,savebuffer

possymbs:

	tst.b	tabsymb
	beq.s	nosymbs
	move	lglabi,lglab
*	move	#LGLAB,lglab
	bsr	searchlab

nosymbs:

	move.l	d6,d7
	lea	texte,a4
	sub.l	a4,d7
	subq	#1,d7
	bmi	noaff
	lea	buffer,a1
*	lea	buffer+10+LGLAB+1,a1
	moveq	#0,d0
	move	lglabi,d0
	lea	11(a1,d0.l),a1
	move.l	savepc,d4
	cmp.l	debutram,d4
	bhs.s	noextend
	lea	buffer+10,a1

noextend:

	move.l	adrpcprg,a0
	tst.b	prgprog
	bne.s	vuprg
	sub.l	a0,a0

vuprg:

	cmp.l	savepc,a0
	bne.s	tout
	move.b	#"",-1(a1)

tout:

	tst.b	(a4)
	beq.s	endligi
	tst.b	(a1)
	beq.s	endligi
	move.b	(a4)+,(a1)+
	dbra	d7,tout

endligi:

	lea	buffer,a1
	clr.b	8(a1)
	move.l	#44,d0
	btst.b	#0,zoom
	beq.s	clraft
	move.l	#79,d0

clraft:

	clr.b	(a1,d0)
	tst.b	prgprog
	beq.s	nometmark
	cmp.l	juskbreak,d4
	beq.s	setitjusk
	cmp.l	debutram,d4
	blo.s	nometmark
	move.l	savepc,d4
	lea	breaklist,a6
	moveq	#9,d3

seeifbreak:

	cmp.l	(a6)+,d4
	dbeq	d3,seeifbreak
	bne.s	nometmark

setitjusk:

	lea	buffer,a6
	moveq	#0,d0
	move	lglabi,d0
	lea	11(a6,d0.l),a6
	move.b	#"",(a6)
*	move.b	#"",buffer+10+LGLAB

nometmark:

	move.l	adrecran,a6
	move	posdeby,d1
	mulu	#8,d1
	subq	#2,d1
	moveq	#1,d0
	lea	buffer,a1	;adresse
	clr.b	8(a1)
	bsr	afflalig
	move.l	adrecran,a6
	move	posdeby,d1
	mulu	#8,d1
	subq	#2,d1
	addq	#1,posdeby
	moveq	#11,d0
	lea	buffer+10,a1	;ligne instructions
	bsr	afflalig

noaff:

	bsr	videbuffer
	movem.l	(sp)+,d0-a7
	rts

searchlab:

	moveq	#0,d3
	tst.b	prgprog
	beq	outsymb
	move.l	adrdebut,a6
	cmp.l	savepc,a6
	bhi	outsymb
	move.l	adrtext,a6	;adresse debut
	move	nbtext,d4	;nbre
	subq	#1,d4
	move.l	adrdata0,d0
	move.l	adrbss0,d1
	cmp.l	savepc,d0
	bhi.s	zonetext
	move.l	adrdata,a6	;adresse
	move	nbdata,d4	;nbre
	subq	#1,d4
	cmp.l	savepc,d1
	bhi.s	zonedata
	move.l	adrfin,a6
	cmp.l	savepc,a6
	bls.s	outsymb
	move.l	adrbss,a6	;adresse debut des labels
	move	nbbss,d4	;nbre
	subq	#1,d4
	sub.l	d1,d5	;offset par rapport debut prog
	bra.s	chlesymb

zonetext:

	sub.l	adrdebut,d5
	bra.s	chlesymb

zonedata:

	sub.l	d0,d5

;la table a ete triee
;donc si l'offset est depasse dans la table
;on arrete la recherche
chlesymb:

	subq.l	#8,a6

bcchlesymb:

	addq.l	#8,a6
	cmp.l	(a6),d5	;meme offset
	dbeq	d4,bcchlesymb
	beq.s	yesissymb	;oui
	bra.s	outsymb

yesissymb:
;oui alors inserer le symbole

	move.l	savebuffer,a5
	move.l	4(a6),a6
	moveq	#7,d2

for8car:

	tst.b	(a6)
	beq.s	outsymbo
	move.b	(a6)+,(a5)+
	dbra	d2,for8car
	tst.b	1(a6)	;label de 8 car
	beq.s	outsymbo	;oui alors fin
	addq.l	#6,a6
	move	lglab,d2
	subq	#8,d2
	bls.s	outsymbo
*	subq	#1,d2

bcsuivcar:

	move.b	(a6)+,(a5)+
	dbeq	d2,bcsuivcar
	move.b	#" ",-1(a5)

outsymbo:

	moveq	#1,d3

outsymb:

	rts

videbuffer:

	move	#$b,-(sp)
	trap	#1
	addq.l	#2,sp
	tst	d0
	beq.s	endvide
	bsr	gettouche
	bra.s	videbuffer

endvide:

	rts

efface_ecran:

	lea	clrreg,a0
	movem.l	(a0),d4-d7
	move.l	adrecran,a0
	add.l	#32000,a0
	move	#32000/4/4-1,d0

clsecran:

	movem.l	d4-d7,-(a0)
	dbra	d0,clsecran
	rts

dodesa:
;ce flag permet de savoir si on a affaire … une zone inexploitable
;si oui on doit mettre "VIDE"
;ce qui sera fait dans la routine erreur bus

	move.b	#1,scanning
	clr.b	outmemory
	clr	getsaut
	lea	condition,a2	;condition 680x0
	lea	ccondition,a3	;condition copro
	cmp.l	limiteram,a0
	blo.s	inram
	bra	cascode

inram:

	cmp.l	debutram,a0
	bhs	cascode
;-----------------------------------------------------------
;cas en dessous du debut de la ram utilisable
;fournir un dc.w ou dc.l ou dc.b
;+ un libelle d'explication pour l'adresse courante
;exemple: $42E          DC.L xxxxxxxx    limite physique RAM

	lea	listeadr,a5
	lea	listpoint,a6
	lea	listaille,a4
	move	(a6)+,d7
	subq	#1,d7

chadrit:

	move.b	(a4)+,d4
	addq.l	#4,a6
	cmp.l	(a5)+,a0
	dbeq	d7,chadrit
	move.b	#"D",(a1)+
	move.b	#"C",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	cmp	#$ffff,d7
	beq.s	nofoundadr
	move.l	-4(a6),a5
	tst.b	d4
	bne.s	nocasw
	move.b	#"W",-2(a1)
	moveq	#0,d7
	move	(a0)+,d7
	bsr	transhexa3
	moveq	#3+2,d6

ajoutsp:

	move.b	#" ",(a1)+
	dbra	d6,ajoutsp
	bra.s	bctradr

nocasw:

	move.l	(a0)+,d7
	bsr	transhexa2
	move.b	#" ",(a1)+
	move.b	#" ",(a1)+

bctradr:

	move.b	(a5)+,(a1)+
	bne.s	bctradr
	rts

nofoundadr:

	move.b	#"W",-2(a1)
	moveq	#0,d7
	move.l	a0,d0
	btst	#0,d0
	beq.s	casword2
	move.b	(a0)+,d7
	lsl	#8,d7
	move.b	(a0)+,d7
	bra.s	after1

casword2:

	move	(a0)+,d7

after1:

	bsr	transhexa3
	rts

cascode:

	move.l	a0,d0
	btst	#0,d0
	beq.s	casword3
	move.b	(a0)+,d0
	tst.b	outmemory
	beq.s	noout
	addq.l	#1,a0
	bra	noinmemo

noout:

	lsl	#8,d0
	move.b	(a0)+,d0
	bra.s	after3

casword3:

	move	(a0)+,d0

after3:

	tst.b	outmemory
	beq.s	yesinmemo

noinmemo:

	move.b	#"V",(a1)+
	move.b	#"I",(a1)+
	move.b	#"D",(a1)+
	move.b	#"E",(a1)+
	rts

yesinmemo:

	cmp	#%0000001000111100,d0
	beq	andivccr
	cmp	#%0000001001111100,d0
	beq	andivsr
	cmp	#%0100101011111100,d0
	beq	illegal
	cmp	#%0100111001110001,d0
	beq	nop
	cmp	#%0100111001110000,d0
	beq	reset
	cmp	#%0100111001110100,d0
	beq	rtd
	cmp	#%0100111001110011,d0
	beq	rte
	cmp	#%0100111001110111,d0
	beq	rtr
	cmp	#%0100111001110101,d0
	beq	rts
	cmp	#%0100111001110010,d0
	beq	stop
	cmp	#%0100111001110110,d0
	beq	trapv
	cmp	#%0000101000111100,d0
	beq	eorivccr
	cmp	#%0000101001111100,d0
	beq	eorivsr
	cmp	#%0100111001111010,d0
	beq	movec
	cmp	#%0100111001111011,d0
	beq	movec
	cmp	#%0000000000111100,d0
	beq	orivccr
	cmp	#%0000000001111100,d0
	beq	orivsr
	move	d0,d3
	andi	#%1111111111111000,d3
	cmp	#%0100100001001000,d3
	beq	bkpt
	btst	#15,d0
	bne	cas151

cas150:
;cas bit 15 … zero pour les instructions
;ADDI,ADDQ,ANDI,Bcc,BCHG
;BCLR,BRA,BSET,BSR,BTST,CAS,CAS2,CHK,CHK2,CLR
;CMPI,CMP2,DBcc,DIVS.L,DIVSL.L,DIVU.L,DIVUL.L
;EORI,EXT,EXTB,JMP,JSR,LEA,LINK,MOVE,MOVEA
;MOVE DE CCR,MOVE VERS CCR
;MOVE DE SR,MOVE VERS SR,MOVE DE/VERS USP
;MOVEM,MOVEP,MOVEQ,MOVES,MULS (32 bits),MULU (32 bits)
;NBCD,NEG,NEGX,NOP,NOT,ORI
;PEA,Scc,SUBI,SUBQ,SWAP
;TAS,TRAP,TRAPcc,TST,UNLK

	btst	#14,d0
	bne	cas141b
;bit 15 … zero et bit 14 … zero pour
;ADDI,ANDI,BCHG
;BCLR,BSET,BTST,CAS,CAS2,CHK2,CMPI,CMP2
;EORI,MOVE,MOVEA
;MOVEP,MOVES,ORI,SUBI

	btst	#13,d0
	bne	bit131b	;entete %001....
;bit 15,13,14 … zero pour
;meme instruction que ci dessus avec MOVE (8 bits)
	btst	#12,d0	;entete %0001....
	bne	move
;bit 15,13,12,14 … zero pour
;ADDI,ANDI,BCHG
;BCLR,BSET,BTST,CAS,CAS2,CHK2,CMPI,CMP2
;EORI,MOVEP,MOVES,ORI,SUBI
	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0000011000000000,d3
	beq	addi
	cmp	#%0000001000000000,d3
	beq	divise
	move	d0,d3
	andi	#%0000000111000000,d3
	cmp	#%0000000101000000,d3
	beq	divise2
;BCHG (donnee),BCLR,BSET,BTST,CAS,CAS2,CHK2 (8/32 bits)
;CMPI,CMP2 (8/32 bits)
;EORI,MOVEP (sauf 32 mvr),MOVES,ORI,SUBI
	cmp	#%0000000001000000,d3
	beq	divise3
;BCLR,BSET,BTST,CAS,CAS2,CMP2 (8/32 bits)
;CMPI (op 8/32 bits),EORI (op 8/32 bits)
;MOVES (op 8/32 bits),ORI (op 8/32 bits),SUBI (op 8/32 bits)
;MOVEP (sauf 32 mvr)
	cmp	#%0000000110000000,d3
	beq	divise4
;BCLR (donnees),MOVEP (sauf 32 mvr et 16 rvm)
;BSET,BTST,CAS,CAS2,CMP2 (8/32 bits)
;CMPI (op 8/32 bits),EORI (op 8/32 bits)
;MOVES (op 8/32 bits),ORI (op 8/32 bits),SUBI (op 8/32 bits)

	cmp	#%0000000010000000,d3
	beq	divise5
;MOVEP (sauf 32 mvr et 16 rvm)
;BSET,BTST,CAS,CAS2,CMP2 (8/32 bits)
;CMPI (op 8 bits),EORI (op 8 bits)
;MOVES (op 8 bits),ORI (op 8 bits),SUBI (op 8 bits)

	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0000100000000000,d3
	beq	bset_tst_d
	cmp	#%0000101000000000,d3
	beq	cas8_eori8
	cmp	#%0000110000000000,d3
	beq.s	cas0_2_16_cmpi_8
	cmp	#%0000111000000000,d3
	beq	cas0_2_32_moves8
	tst	d3
	beq.s	ori8_cmp2_8_chk2_8
	cmp	#%0000010000000000,d3
	beq.s	subi_cmp2_32_chk2_32
;MOVEP,BSET (reg Dn),BTST (reg Dn)
	move	d0,d3
	andi	#%0000000000111000,d3
	cmp	#%001000,d3
	beq	movep
;BSET (reg Dn) et BTST (reg Dn)
	move	d0,d3
	andi	#%0000000111000000,d3
	cmp	#%0000000111000000,d3
	beq	bset
	cmp	#%0000000100000000,d3
	beq	btst
	bra	badmode

subi_cmp2_32_chk2_32:

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq.s	cmp2_chk2
	bra	subi

cmp2_chk2:

	btst.b	#3,(a0)
	bne	chk2
	bra	cmp2

ori8_cmp2_8_chk2_8:

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq.s	cmp2_chk2
	bra	ori

cas0_2_16_cmpi_8:

	move	d0,d3
	andi	#%111111,d3
	cmp	#%111100,d3
	beq	cas2
;CAS (16 bits),CMPI (8 bits)

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	bne	cmpi
;CAS (16 bits)
cas:

	move	d0,d3
	andi	#%1111100111000000,d3
	cmp	#%0000100011000000,d3
	bne	badmode
	move.b	#"C",(a1)+
	move.b	#"A",(a1)+
	move.b	#"S",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr.s	taille28
	move.b	#"D",(a1)+
	move	(a0)+,d1
	move	d1,d3
	andi	#%111,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	move.b	#",",(a1)+
	move.b	#"D",(a1)+
	move	d1,d3
	andi	#%0000000111000000,d3
	ror	#6,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	move.b	#",",(a1)+
	move	d0,d3
	move.l	#%000000111111111100,d5
	bra	getmodereg

taille28:

	move	d0,d3
	andi	#%0000011000000000,d3
	cmp	#%0000001000000000,d3
	bne.s	not288
	move.b	#"B",-2(a1)
	rts

not288:

	cmp	#%0000011000000000,d3
	bne.s	not2832
	move.b	#"L",-2(a1)
	rts

not2832:

	tst	d3
	beq	badmode
	rts

cas2:

	move.b	#"C",(a1)+
	move.b	#"A",(a1)+
	move.b	#"S",(a1)+
	move.b	#"2",(a1)+
	move.b	#" ",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move	d0,d3
	andi	#%0000011000000000,d3
	bsr.s	not288
	move.b	#"D",(a1)+
	move	(a0)+,d1
	move	(a0)+,d2
	move	d1,d3
	move	d2,d4
	andi	#%111,d3
	andi	#%111,d4
	addi.b	#"0",d3
	addi.b	#"0",d4
	move.b	d3,(a1)+
	move.b	#":",(a1)+
	move.b	#"D",(a1)+
	move.b	d4,(a1)+
	move	d1,d3
	move	d2,d4
	andi	#%0000000111000000,d3
	andi	#%0000000111000000,d4
	ror	#6,d3
	ror	#6,d4
	addi.b	#"0",d3
	addi.b	#"0",d4
	move.b	#",",(a1)+
	move.b	#"D",(a1)+
	move.b	d3,(a1)+
	move.b	#":",(a1)+
	move.b	#"D",(a1)+
	move.b	d4,(a1)+
	move.b	#",",(a1)+
	move	d1,d3
	move	d2,d4
	andi	#%0111000000000000,d3
	andi	#%0111000000000000,d4
	rol	#4,d3
	rol	#4,d4
	addi.b	#"0",d3
	addi.b	#"0",d4
	move.b	#"(",(a1)+
	move.b	#"D",(a1)+
	btst	#15,d1
	beq.s	rn1dn
	move.b	#"A",-1(a1)

rn1dn:

	move.b	d3,(a1)+
	move.b	#")",(a1)+
	move.b	#":",(a1)+
	move.b	#"(",(a1)+
	move.b	#"D",(a1)+
	btst	#15,d2
	beq.s	rn2dn
	move.b	#"A",-1(a1)

rn2dn:

	move.b	d4,(a1)+
	move.b	#")",(a1)+
	rts

bset_tst_d:
;cas BSET ou BTST pour donnee 16 bits
;equivalent BCLR ou BCHG donnee

	move	d0,d3
	andi	#%0000000111000000,d3
	tst	d3
	beq.s	btstd
	cmp	#%0000000011000000,d3
	beq	bsetd
	bra	badmode

cas8_eori8:

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq	cas
	bra	eori

cas0_2_32_moves8:

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq.s	cas0_2
	bra	moves

cas0_2:

	move	d0,d3
	andi	#%111111,d3
	cmp	#%111100,d3
	beq	cas2
	bra	cas

bset:

	move.b	#"B",(a1)+
	move.b	#"S",(a1)+
	move.b	#"E",(a1)+
	move.b	#"T",(a1)+
	bsr	sbitt
	bra	bbitt

btst:

	move.b	#"B",(a1)+
	move.b	#"T",(a1)+
	move.b	#"S",(a1)+
	move.b	#"T",(a1)+
	bsr	sbitt
	bsr	getreg	;registre de donnee
	move.l	#%111111111111111101,d5
	bra	contwae2

btstd:

	move.b	#"B",(a1)+
	move.b	#"T",(a1)+
	move.b	#"S",(a1)+
	move.b	#"T",(a1)+
	bsr	sbitt
	move.b	#"#",(a1)+
	moveq	#0,d7
	move	(a0)+,d7
	bsr	transhexa
	move.l	#%111110111111111101,d5
	bra	contwae2

bsetd:

	move.b	#"B",(a1)+
	move.b	#"S",(a1)+
	move.b	#"E",(a1)+
	move.b	#"T",(a1)+
	bsr	sbitt
	bra	bbittd

divise5:
;BCLR (donnees),CMPI (op 32 bits),EORI (op 32 bits)
;MOVES (op 32 bits),ORI (op 32 bits),SUBI (op 32 bits)

	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0000100000000000,d3
	beq.s	bclrd
	cmp	#%0000110000000000,d3
	beq	cmpi
	cmp	#%0000101000000000,d3
	beq	eori
	cmp	#%0000111000000000,d3
	beq	moves
	tst	d3
	beq	ori
	cmp	#%0000010000000000,d3
	beq	subi
	bra	badmode

bclrd:

	move.b	#"B",(a1)+
	move.b	#"C",(a1)+
	move.b	#"L",(a1)+
	move.b	#"R",(a1)+
	bsr	sbitt
	bra	bbittd

b11a1:

	move	d0,d3
	andi	#%1111111100000000,d3
	rts

divise4:
;BCLR (reg Dn),MOVEP (16 rvm)

	move	d0,d3
	andi	#%0000000000111000,d3
	cmp	#%001000,d3
	beq	movep
;BCLR (reg Dn)
bclr:

	move	d0,d3
	andi	#%1111000111000000,d3
	cmp	#%0000000110000000,d3
	bne	badmode
	move.b	#"B",(a1)+
	move.b	#"C",(a1)+
	move.b	#"L",(a1)+
	move.b	#"R",(a1)+
	bsr	sbitt
	bra	bbitt

divise3:
;BCHG (donnee),CMPI (op 16bits),EORI (op 16 bits)
;MOVES (op 16 bits),ORI (op 16 bits),SUBI (op 16 bits)

	move	d0,d3
	andi	#%0000111100000000,d3
	cmp	#%0000100000000000,d3
	beq	bchgd
	cmp	#%0000110000000000,d3
	beq	cmpi
	cmp	#%0000101000000000,d3
	beq.s	eori
	tst	d3
	beq.s	ori
	cmp	#%0000010000000000,d3
	beq.s	subi
	cmp	#%0000111000000000,d3
	beq.s	moves
	bra	badmode

moves:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#"S",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop
	move	(a0)+,d1
	bsr	getnumreg
	btst	#11,d1
	beq.s	mverr
;registre vers memoire
	bsr	getregad
	move.b	#",",(a1)+
	bra.s	getaesys

mverr:

	move	d5,-(sp)
	bsr.s	getaesys
	move	(sp)+,d5
	move.b	#",",(a1)+
	bra	getregad

getaesys:

	move.l	#%000000111111111100,d5
	move	d0,d3
	bra	getmodereg

subi:

	move.b	#"S",(a1)+
	move.b	#"U",(a1)+
	move.b	#"B",(a1)+
	bra	enti

eori:

	move.b	#"E",(a1)+

ori:

	move.b	#"O",(a1)+
	move.b	#"R",(a1)+
	bra	enti

cmpi:

	move.b	#"C",(a1)+
	move.b	#"M",(a1)+
	move.b	#"P",(a1)+
	bsr	chooset
	move.l	#%000000111111111101,d5
	move	d0,d3
	bra	getmodereg

bchgd:
;BCHG (donnee)

	bsr.s	sbchg	;taille octet ou long mot

bbittd:

	move.b	#"#",(a1)+
	moveq	#0,d7
	move	(a0)+,d7
	bsr	transhexa
	bra.s	contwae

divise2:
;bit 8 et 6 … 1 et bit 7 … zero pour
;BCHG (reg Dn),MOVEP (32 mvr)

	move	d0,d3
	andi	#%0000000000111000,d3
	cmp	#%0000000000001000,d3
	beq.s	movep
;cas BCHG (reg Dn)
bchg:

	move	d0,d3
	andi	#%1111000111000000,d3
	cmp	#%0000000101000000,d3
	bne	badmode
	bsr.s	sbchg	;taille octet ou long mot

bbitt:

	bsr	getreg	;registre de donnee

contwae:

	move.l	#%000000111111111101,d5

contwae2:

	move.b	#",",(a1)+
	move	d0,d3
	bra	getmodereg

sbchg:

	move.b	#"B",(a1)+
	move.b	#"C",(a1)+
	move.b	#"H",(a1)+
	move.b	#"G",(a1)+

sbitt:

	move.b	#".",(a1)+
	move.b	#"B",(a1)+
	move.b	#" ",(a1)+
	clr.b	taille
	move	d0,d3
	andi	#%111000,d3
	tst	d3
	bne.s	casoct
	move.b	#"L",-2(a1)
	move.b	#2,taille

casoct:

	rts

movep:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#"P",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	btst	#6,d0
	beq.s	cas16bits
	move.b	#"L",-1(a1)

cas16bits:

	move.b	#" ",(a1)+
	btst	#7,d0
	bne.s	regvmem
;memoire vers registre
	bsr.s	getae
	move.b	#",",(a1)+
	bra	getreg

regvmem:

	bsr	getreg	;registre de donnee
	move.b	#",",(a1)+

getae:

	bset	#5,d0	;mettre mode d16(An)
	move	d0,d3
	moveq	#%000000000000100000,d5
	bra	getmodereg	;mode adressage...

divise:
;bit 9 … 1 et bits 15,14,13,12,11,10,8 … zero pour
;ANDI,CHK2 (16 bits),CMP2 (16 bits)

	move	d0,d4
	andi	#%0000000011000000,d4
	cmp	#%0000000011000000,d4
	bne	andi
;CHK2,CMP2 (16 bits)
	btst	#3,(a0)
	bne.s	chk2
;CMP2 (16 bits)
cmp2:

	move	d0,d3
	andi	#%1111100111000000,d3
	cmp	#%0000000011000000,d3
	bne	badmode
	move.b	#"C",(a1)+
	move.b	#"M",(a1)+
	move.b	#"P",(a1)+
	bra.s	entcmp2

chk2:

	move.b	#"C",(a1)+
	move.b	#"H",(a1)+
	move.b	#"K",(a1)+

entcmp2:

	move.b	#"2",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move	(a0)+,d1
	move	d0,d3
	andi	#%0000011000000000,d3
	tst	d3
	bne.s	no8bit
	move.b	#"B",-2(a1)
	bra.s	saltles

no8bit:

	cmp	#%0000001000000000,d3
	beq.s	saltles
	cmp	#%0000010000000000,d3
	bne	badmode
	move.b	#"L",-2(a1)

saltles:

	move	d0,d3
	move	d1,-(sp)
	move.l	#%111110111111100100,d5
	bsr	getmodereg
	move	(sp)+,d1
	move.b	#",",(a1)+
	move.b	#"D",d5
	btst	#15,d1
	beq.s	nosetAn
	move.b	#"A",d5

nosetAn:

	move.b	d5,(a1)+
	move	d1,d3
	andi	#%0111000000000000,d3
	rol	#4,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

andi:
;ANDI

	move.b	#"A",(a1)+
	move.b	#"N",(a1)+
	move.b	#"D",(a1)+
	bra	enti

andivsr:

	bsr.s	dopartip

srent:

	move.b	#"S",(a1)+
	move.b	#"R",(a1)+
	rts

dopartir:

	move.b	#"O",(a1)+
	move.b	#"R",(a1)+
	bra.s	doparti

dopartiq:

	move.b	#"E",(a1)+
	move.b	#"O",(a1)+
	move.b	#"R",(a1)+
	bra.s	doparti

dopartip:

	move.b	#"A",(a1)+
	move.b	#"N",(a1)+
	move.b	#"D",(a1)+

doparti:

	move.b	#"I",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.b	#"#",(a1)+
	moveq	#0,d7
	move	(a0)+,d7
	bsr	transhexa
	move.b	#",",(a1)+
	rts

andivccr:

	bsr.s	dopartip

ccrent:

	move.b	#"C",(a1)+
	move.b	#"C",(a1)+
	move.b	#"R",(a1)+
	rts

eorivccr:

	bsr.s	dopartiq
	bra.s	ccrent

eorivsr:

	bsr.s	dopartiq
	bra.s	srent

movec:
;movec Rc,Rn ou Rn,Rc

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#"C",(a1)+
	move.b	#" ",(a1)+
	move	(a0)+,d1
	bsr.s	getnumreg
	btst	#0,d0
	beq	direction
;Rn vers Rc
	bsr	getregad
	move.b	#",",(a1)+
	bra.s	getregc

getnumreg:

	move	d1,d5
	andi	#%0111000000000000,d5
	rol	#1+3,d5
	addi.b	#"0",d5
	rts

getregc:

	move	d1,d3
	andi	#%0000111111111111,d3
	tst	d3
	bne.s	norsfc
	move.b	#"S",(a1)+

contfc:

	move.b	#"F",(a1)+
	move.b	#"C",(a1)+
	rts

norsfc:

	cmp	#$001,d3
	bne.s	nordfc
	move.b	#"D",(a1)+
	bra.s	contfc

nordfc:

	cmp	#$002,d3
	bne.s	norcacr
	move.b	#"C",(a1)+
	move.b	#"A",(a1)+
	move.b	#"C",(a1)+
	move.b	#"R",(a1)+
	rts

norcacr:

	cmp	#$800,d3
	bne.s	norusp
	move.b	#"U",(a1)+

spent:

	move.b	#"S",(a1)+
	move.b	#"P",(a1)+
	rts

norusp:

	cmp	#$801,d3
	bne.s	norvbr
	move.b	#"V",(a1)+
	move.b	#"B",(a1)+
	move.b	#"R",(a1)+
	rts

norvbr:

	cmp	#$802,d3
	bne.s	norcaar
	move.b	#"C",(a1)+
	move.b	#"A",(a1)+
	move.b	#"A",(a1)+
	move.b	#"R",(a1)+
	rts

norcaar:

	cmp	#$803,d3
	bne.s	normsp
	move.b	#"M",(a1)+
	bra.s	spent

normsp:

	cmp	#$804,d3
	bne	badmode
	move.b	#"I",(a1)+
	bra.s	spent

getregad:

	btst	#15,d1
	beq.s	regdedon2
	move.b	#"A",(a1)+
	bra.s	contaregd

regdedon2:

	move.b	#"D",(a1)+

contaregd:

	move.b	d5,(a1)+
	rts

direction:

	bsr	getregc
	move.b	#",",(a1)+
	bra.s	getregad

orivccr:

	bsr	dopartir
	bra	ccrent

orivsr:

	bsr	dopartir
	bra	srent

bkpt:

	move.b	#"B",(a1)+
	move.b	#"K",(a1)+
	move.b	#"P",(a1)+
	move.b	#"T",(a1)+
	move.b	#" ",(a1)+
	move.b	#"#",(a1)+
	moveq	#0,d7
	move	d0,d7
	andi	#%111,d7
	bra	transhexa

addi:

	move.b	#"A",(a1)+
	move.b	#"D",(a1)+
	move.b	#"D",(a1)+

enti:

	bsr.s	chooset
	move.l	#%000000111111111101,d5
	move	d0,d3
	bra	getmodereg

chooset:

	move.b	#"I",(a1)+
	move.b	#".",(a1)+
	move	d0,d3
	andi	#%0000000011000000,d3
	moveq	#0,d7
	tst	d3
	bne.s	nolgb
	move.b	#"B",(a1)+
	move	(a0)+,d7
	andi	#$ff,d7
	bra.s	contbwl

nolgb:

	cmp	#%0000000001000000,d3
	bne.s	nolgw
	move.b	#"W",(a1)+
	move	(a0)+,d7
	bra.s	contbwl

nolgw:

	cmp	#%0000000010000000,d3
	bne	badmode
	move.b	#"L",(a1)+
	move.l	(a0)+,d7

contbwl:

	move.b	#" ",(a1)+
	move.b	#"#",(a1)+
	bsr	transhexa
	move.b	#",",(a1)+
	rts


bit131b:
;cas bit 15,14 … 0 et bit 14 … 1 pour
;MOVE (16/32 bits) et MOVEA (16/32 bits)
;pour les taille mot et long mot

	move	d0,d3
	andi	#%0000000111000000,d3
	cmp	#%0000000001000000,d3
	beq	movea
;cas MOVE
move:

	move	d0,d3
	andi	#%111000,d3	;adressage source est
	cmp	#%001000,d3	;=An
	bne.s	notestt		;oui alors mauvais
	move	d0,d3		;si taille octet
	andi	#%0011000000000000,d3
	cmp	#%0001000000000000,d3	;taille octet?
	beq	badmode		;oui alors fin

notestt:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+

move2:

	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr.s	settaille
	move.l	#%111111111111111111,d5
	move	d0,d3
	bsr	getmodereg
	move	d0,d1
	lsr	#3,d0
	lsr	#8,d1
	lsr	d1
	andi	#%111000,d0
	andi	#%111,d1
	or	d1,d0
	move.b	#",",(a1)+
	move	d0,d3
	move.l	#%000000111111111111,d5
	bra	getmodereg

settaille:

	move.b	#1,taille
	move	d0,d3
	andi	#%0011000000000000,d3
	cmp	#%0001000000000000,d3
	beq.s	casbyte
	cmp	#%0010000000000000,d3
	beq.s	caslong
	subq.l	#3,a1
	move.b	#" ",(a1)+
	rts

caslong:

	move.b	#"L",-2(a1)
	move.b	#2,taille
	rts

casbyte:

	move.b	#"B",-2(a1)
	clr.b	taille
	rts

movea:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#"A",(a1)+
	bra	move2

cas141b:
;cas bit 15 … zero et bit 14 … 1
;ADDQ,Bcc
;BRA,BSR,CHK,CLR
;DBcc,DIVS.L,DIVSL.L,DIVU.L,DIVUL.L
;EXT,EXTB,JMP,JSR,LEA,LINK,MOVE DE CCR,MOVE VERS CCR
;MOVE DE/VERS SR,MOVE DE/VERS USP
;MOVEM,MOVEQ,MULS (32 bits),MULU (32 bits)
;NBCD,NEG,NEGX,NOT
;PEA,Scc,SUBQ,SWAP
;TAS,TRAP,TRAPcc,TST,UNLK

	move	d0,d3
	andi	#%1111000000000000,d3
	cmp	#%0101000000000000,d3
	beq	subise1
;Bcc,BRA,BSR,CHK,CLR,DIVS.L,DIVSL.L,DIVU.L,DIVUL.L
;EXT,EXTB,JMP,JSR,LEA,LINK,MOVE DE CCR,MOVE VERS CCR
;MOVE DE/VERS SR,MOVE DE/VERS USP
;MOVEM,MOVEQ,MULS (32 bits),MULU (32 bits)
;NBCD,NEG,NEGX,NOT,PEA,SWAP,TAS,TRAP,TST,UNLK

	cmp	#%0110000000000000,d3
	beq	subise2
;CHK,CLR,DIVS.L,DIVSL.L,DIVU.L,DIVUL.L
;EXT,EXTB,JMP,JSR,LEA,LINK,MOVE DE CCR,MOVE VERS CCR
;MOVE DE/VERS SR,MOVE DE/VERS USP
;MOVEM,MOVEQ,MULS (32 bits),MULU (32 bits)
;NBCD,NEG,NEGX,NOT,PEA,SWAP,TAS,TRAP,TST,UNLK

	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0100001000000000,d3
	beq	subise3
;CHK,DIVS.L,DIVSL.L,DIVU.L,DIVUL.L
;EXT,EXTB,JMP,JSR,LEA,LINK,MOVE VERS CCR
;MOVE DE/VERS SR,MOVE DE/VERS USP
;MOVEM,MOVEQ,MULS (32 bits),MULU (32 bits)
;NBCD,NEG,NEGX,NOT,PEA,SWAP,TAS,TRAP,TST,UNLK
	cmp	#%0100110000000000,d3
	beq	subise4
;CHK,EXT,EXTB,JMP,JSR,LEA,LINK,MOVE VERS CCR
;MOVE DE/VERS SR,MOVE DE/VERS USP
;MOVEM (registre vers memoire),MOVEQ
;NBCD,NEG,NEGX,NOT,PEA,SWAP,TAS,TRAP,TST,UNLK
	cmp	#%0100111000000000,d3
	beq	subise5
;CHK,EXT,EXTB,LEA,LINK (32 bits),MOVE VERS CCR
;MOVE DE/VERS SR,MOVEM (registre vers memoire),MOVEQ
;NBCD,NEG,NEGX,NOT,PEA,SWAP,TAS,TST
	cmp	#%0100100000000000,d3
	beq	subise6
;CHK,EXT/B (8/32),LEA,MOVE VERS CCR
;MOVE DE/VERS SR,MOVEQ
;NEG,NEGX,NOT,TAS,TST
	cmp	#%0100010000000000,d3
	beq	subise7
;CHK,EXT/B (8/32),LEA
;MOVE DE/VERS SR,MOVEQ
;NEGX,NOT,TAS,TST
	cmp	#%0100000000000000,d3
	beq	subise8
;CHK,EXT/B (8/32),LEA
;MOVE VERS SR,MOVEQ
;NOT,TAS,TST
	cmp	#%0100011000000000,d3
	beq	subise9
;CHK,EXT/B (8/32),LEA
;MOVEQ
;TAS,TST
	cmp	#%0100101000000000,d3
	beq	subise10
;CHK,EXT/B (8/32),LEA
;MOVEQ
	move	d0,d4
	andi	#%1111000000000000,d3
	cmp	#%0111000000000000,d3
	beq	moveq
;CHK,EXT/B (8/32),LEA
	btst	#6,d0
	beq.s	chk
;EXT/B (8/32),LEA
	move	d0,d4
	andi	#%111000,d4
	tst	d4
	beq	ext
;LEA
lea:

	move	d0,d3
	andi	#%1111000111000000,d3
	cmp	#%0100000111000000,d3
	bne	badmode
	move.b	#"L",(a1)+
	move.b	#"E",(a1)+
	move.b	#"A",(a1)+
	move.b	#" ",(a1)+
	move.l	#%111110111111100100,d5
	move	d0,d3
	bsr	getmodereg
	move.b	#",",(a1)+
	move.b	#"A",(a1)+
	move	d0,d3
	andi	#%0000111000000000,d3
	rol	#7,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

chk:
;CHK

	move.b	#"C",(a1)+
	move.b	#"H",(a1)+
	move.b	#"K",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.b	#1,taille
	move	d0,d3
	andi	#%0000000110000000,d3
	cmp	#%0000000100000000,d3
	bne.s	nolong
	move.b	#"L",-2(a1)
	move.b	#2,taille
	bra.s	outlg

nolong:

	cmp	#%0000000110000000,d3
	bne	badmode

outlg:

	move	d0,d3
	move.l	#%111111111111111101,d5
	bsr	getmodereg
	move.b	#",",(a1)+
	move.b	#"D",(a1)+
	move	d0,d3
	andi	#%0000111000000000,d3
	rol	#7,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

moveq:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#"Q",(a1)+
	move.b	#" ",(a1)+
	move.b	#"#",(a1)+
	moveq	#0,d7
	move.b	d0,d7
	btst	#7,d7
	beq.s	posdon
	neg.b	d7
	move.b	#"-",(a1)+

posdon:

	ext.l	d7
	bsr	transhexa
	move.b	#",",(a1)+
	bra	getreg

subise10:
;TAS,TST

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq.s	tas
;TST
tst:

	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0100101000000000,d3
	bne	badmode
	move.b	#"T",(a1)+
	move.b	#"S",(a1)+
	move.b	#"T",(a1)+
	move.l	#%111110111111111101,d5
	bra	enttst

tas:

	move.b	#"T",(a1)+
	move.b	#"A",(a1)+
	move.b	#"S",(a1)+
	move.b	#".",(a1)+
	move.b	#"B",(a1)+
	move.b	#" ",(a1)+
	move	d0,d3
	move.l	#%000000111111111101,d5
	bra	getmodereg

subise9:
;MOVE VERS SR,NOT

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq.s	movevsr
;NOT
not:

	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0100011000000000,d3
	bne	badmode
	move.b	#"N",(a1)+
	move.b	#"O",(a1)+
	move.b	#"T",(a1)+
	bra	entnegx

movevsr:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#" ",(a1)+
	move.b	#1,taille
	move	d0,d3
	move.l	#%111111111111111101,d5
	bsr	getmodereg
	move.b	#",",(a1)+
	move.b	#"S",(a1)+
	move.b	#"R",(a1)+
	rts

subise8:
;MOVE DE SR,NEGX

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq.s	movedsr
;NEGX
negx:

	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0100000000000000,d3
	bne	badmode
	move.b	#"N",(a1)+
	move.b	#"E",(a1)+
	move.b	#"G",(a1)+
	move.b	#"X",(a1)+
	bra.s	entnegx

movedsr:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#" ",(a1)+
	move.b	#"S",(a1)+
	move.b	#"R",(a1)+
	move.b	#",",(a1)+
	move	d0,d3
	move.l	#%000000111111111101,d5
	bra	getmodereg

subise7:
;MOVE VERS CCR,NEG

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq.s	movevccr
;NEG
neg:

	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0100010000000000,d3
	bne	badmode
	move.b	#"N",(a1)+
	move.b	#"E",(a1)+
	move.b	#"G",(a1)+

entnegx:

	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop
	move	d0,d3
	move.l	#%000000111111111101,d5
	bra	getmodereg

movevccr:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move	d0,d3
	move.b	#1,taille
	move.l	#%111111111111111101,d5
	bsr	getmodereg
	move.b	#",",(a1)+
	move.b	#"C",(a1)+
	move.b	#"C",(a1)+
	move.b	#"R",(a1)+
	rts

subise6:
;EXT/B (8/16 et 16/32),LINK (32 bits),MOVEM (reg vers mem)
;NBCD,PEA,SWAP

	move	d0,d3
	andi	#%1111111111000000,d3
	cmp	#%0100100010000000,d3
	beq	busi1
;EXT/B (16/32),LINK (32 bits),MOVEM (reg v mem/32 bits)
;NBCD,PEA,SWAP
	cmp	#%0100100011000000,d3
	beq.s	ext_movemrvm32
	cmp	#%0100100000000000,d3
	beq.s	busi2
;PEA,SWAP
	cmp	#%0100100011000000,d3
	beq	movem
;PEA,SWAP
	move	d0,d3
	andi	#%111000,d3
	tst	d3
	beq.s	swap
	bra.s	pea

ext_movemrvm32:

	move	d0,d3
	andi	#%111000,d3
	tst	d3
	beq	ext
	bra	movem

;PEA
pea:

	move.b	#"P",(a1)+
	move.b	#"E",(a1)+
	move.b	#"A",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	move	d0,d3
	move.l	#%111110111111100100,d5
	bra	getmodereg

swap:

	move.b	#"S",(a1)+
	move.b	#"W",(a1)+
	move.b	#"A",(a1)+
	move.b	#"P",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.b	#"D",(a1)+
	move	d0,d3
	andi	#%111,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

busi2:
;LINK (32 bits),NBCD

	move	d0,d3
	andi	#%111000,d3
	cmp	#%001000,d3
	beq	link32
;NBCD
nbcd:

	move	d0,d3
	andi	#%1111111111000000,d3
	cmp	#%0100100000000000,d3
	bne	badmode
	move.b	#"N",(a1)+
	move.b	#"B",(a1)+
	move.b	#"C",(a1)+
	move.b	#"D",(a1)+
	move.b	#".",(a1)+
	move.b	#"B",(a1)+
	move.b	#" ",(a1)+
	move	d0,d3
	move.l	#%000000111111111101,d5
	bra	getmodereg

busi1:
;EXT/B (8/16),MOVEM (reg v mem/16 bits)

	move	d0,d3
	andi	#%0000000000111000,d3
	tst	d3
	beq.s	ext
;MOVEM (reg v mem/16 bits)
	bra	movem

ext:

	move.b	#"E",(a1)+
	move.b	#"X",(a1)+
	move.b	#"T",(a1)+
	move	d0,d3
	andi	#%0000000111000000,d3
	cmp	#%0000000010000000,d3
	bne.s	nopw
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	bra.s	context

nopw:

	cmp	#%0000000011000000,d3
	bne.s	nopl
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	bra.s	context

nopl:

	cmp	#%0000000111000000,d3
	bne	badmode
	move.b	#"B",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+

context:

	move.b	#" ",(a1)+
	move.b	#"D",(a1)+
	move	d0,d3
	andi	#%111,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

subise5:
;JMP,JSR,LINK (16 bits),MOVE DE/VERS USP
;TRAP,UNLK

	move	d0,d3
	andi	#%1111111111000000,d3
	cmp	#%0100111011000000,d3
	beq	jmp
;JSR,LINK (16 bits),MOVE DE/VERS USP
;TRAP,UNLK
	cmp	#%0100111010000000,d3
	beq	jsr
;LINK (16 bits),MOVE DE/VERS USP
;TRAP,UNLK
	move	d0,d3
	andi	#%1111111111111000,d3
	cmp	#%0100111001010000,d3
	beq	link16
;MOVE DE/VERS USP,TRAP,UNLK
	cmp	#%0100111001100000,d3
	beq.s	movedvusp
	cmp	#%0100111001101000,d3
	beq.s	movedvusp
;TRAP,UNLK
	cmp	#%0100111001000000,d3
	beq.s	trap
	cmp	#%0100111001001000,d3
	beq.s	trap
;UNLK
	cmp	#%0100111001011000,d3
	beq.s	unlk
	bra	badmode

unlk:

	move.b	#"U",(a1)+
	move.b	#"N",(a1)+
	move.b	#"L",(a1)+
	move.b	#"K",(a1)+
	move.b	#" ",(a1)+
	move.b	#"A",(a1)+
	move	d0,d3
	andi	#%111,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

trap:

	move	#3,getsaut
	move.b	#"T",(a1)+
	move.b	#"R",(a1)+
	move.b	#"A",(a1)+
	move.b	#"P",(a1)+
	move.b	#" ",(a1)+
	move.b	#"#",(a1)+
	move.b	#"$",(a1)+
	move	d0,d3
	andi	#%1111,d3
	addi.b	#"0",d3
	cmp.b	#"9",d3
	bls.s	bonreg
	addi.b	#"A"-"0"-10,d3

bonreg:

	move.b	d3,(a1)+
	rts

movedvusp:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	move	d0,d3
	andi	#%111,d3
	addi.b	#"0",d3
	btst	#3,d0
	beq.s	anvusp
;USP vers An
	move.b	#"U",(a1)+
	move.b	#"S",(a1)+
	move.b	#"P",(a1)+
	move.b	#",",(a1)+
	move.b	#"A",(a1)+
	move.b	d3,(a1)+
	rts

anvusp:

	move.b	#"A",(a1)+
	move.b	d3,(a1)+
	move.b	#",",(a1)+
	move.b	#"U",(a1)+
	move.b	#"S",(a1)+
	move.b	#"P",(a1)+
	rts

link16:
;LINK (16 bits)

	move.b	#"W",d5
	bra.s	link

link32:
;LINK (32 bits)

	move.b	#"L",d5

link:

	move.b	#"L",(a1)+
	move.b	#"I",(a1)+
	move.b	#"N",(a1)+
	move.b	#"K",(a1)+
	move.b	#".",(a1)+
	move.b	d5,(a1)+
	move.b	#" ",(a1)+
	move.b	#"A",(a1)+
	move	d0,d3
	andi	#%111,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	move.b	#",",(a1)+
	move.b	#"#",(a1)+
	cmp.b	#"L",d5
	bne.s	cas16l
	move.l	(a0)+,d7
	btst	#31,d7
	beq	transhexa
	neg.l	d7
	move.b	#"-",(a1)+
	bra	transhexa

cas16l:

	move	(a0)+,d7
	btst	#15,d7
	beq.s	dohexatr
	neg	d7
	move.b	#"-",(a1)+

dohexatr:

	ext.l	d7
	bra	transhexa

jsr:
;JSR

	move	#1,getsaut
	move.b	#"J",(a1)+
	move.b	#"S",(a1)+
	move.b	#"R",(a1)+
	bra.s	jmpcas

jmp:
;JMP

	move.b	#"J",(a1)+
	move.b	#"M",(a1)+
	move.b	#"P",(a1)+

jmpcas:

	move.b	#" ",(a1)+
	move	d0,d3
	move.l	#%111110111111100100,d5
	bra	getmodereg

subise4:
;DIVS.L,DIVSL.L,DIVU.L,DIVUL.L
;MOVEM (memoire vers registre),MULS (32 bits),MULU (32 bits)

	btst	#7,d0
	beq	subibise
;MOVEM (memoire vers registre)
movem:

	move	d0,d3
	andi	#%1111101110000000,d3
	cmp	#%0100100010000000,d3
	bne	badmode
	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#"M",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	btst	#6,d0	;taille transfert
	bne.s	c32b
	subq.l	#3,a1
	move.b	#" ",(a1)+

c32b:

	btst	#10,d0
	beq.s	cregvmem
;cas memoire vers registre

	move	(a0),-(sp)
	addq.l	#2,a0
	move	d0,d3
	move.l	#%111110111111101100,d5
	bsr	getmodereg
	move.b	#",",(a1)+
	move	(sp)+,d1
	bra.s	getlistereg

cregvmem:

	move	(a0)+,d1
	bsr.s	getlistereg
	move.b	#",",(a1)+
	move	d0,d3
	move.l	#%000000111111110100,d5
	bra	getmodereg

getlistereg:
;tester si predecrementation
;si oui alors mode registre 2
;sinon mode 1
;mode 1: A7/A6/A5/A4/A3/A2/A1/A0/D7/D6/D5/D4/D3/D2/D1/D0
;mode 2: D0/D1/D2/D3/D4/D5/D6/D7/A0/A1/A2/A3/A4/A5/A6/A7

	move	d0,-(sp)
	move	d0,d3
	andi	#%111000,d3
	cmp	#%100000,d3
	beq.s	mode2
;cas postincrementation et autres modes (sauf predecrementation)
	moveq	#0,d5
	move	d1,d7
	andi	#%11111111,d7
	beq.s	noajtri
	move.b	#"D",d4
	moveq	#0,d7
	bsr	metlesreg2
	tst	d0
	beq.s	noajtri
;cas fin de pont
;mettre - si d0<>2 / sinon
	cmp	#2,d0
	beq.s	noajtri
	move.b	#"-",(a1)+
	move	d3,d6
	subq	#1,d6	;numero registre
	addi.b	#"0",d6
	move.b	d4,(a1)+
	move.b	d6,(a1)+

noajtri:

	move	d1,d7
	andi	#%1111111100000000,d7
	beq.s	noajttt
	tst	d5
	beq.s	noset2
	move.b	#"/",(a1)+

noset2:

	move.b	#"A",d4
	moveq	#8,d7
	bsr	metlesreg2
	tst	d0
	beq.s	noajttt
;cas fin de pont
;mettre - si d0<>2 / sinon
	cmp	#2,d0
	beq.s	noajttt
	move.b	#"-",(a1)+
	move	d3,d6
	subq	#1,d6	;numero registre
	addi.b	#"0",d6
	move.b	d4,(a1)+
	move.b	d6,(a1)+

noajttt:

	move	(sp)+,d0
	rts

mode2:

	move	d1,d7
	moveq	#0,d5
	andi	#%1111111100000000,d7
	beq.s	noajpontt
	move.b	#"D",d4
	moveq	#15,d7
	bsr.s	metlesreg1
	tst	d0
	beq.s	noajpontt
;cas fin de pont
;mettre - si d0<>2 / sinon
	cmp	#2,d0
	beq.s	noajpontt
	move.b	#"-",(a1)+
	move	d3,d6
	subq	#1,d6
	addi.b	#"0",d6
	move.b	d4,(a1)+
	move.b	d6,(a1)+

noajpontt:

	move	d1,d7
	andi	#%11111111,d7
	beq.s	noajponttt
	tst	d5
	beq.s	noset1
	move.b	#"/",(a1)+

noset1:

	move.b	#"A",d4
	moveq	#7,d7
	bsr.s	metlesreg1
	tst	d0
	beq.s	noajponttt
;cas fin de pont
;mettre - si d0<>2 / sinon
	cmp	#2,d0
	beq.s	noajpontt
	move.b	#"-",(a1)+
	move	d3,d6	;numero registre
	subq	#1,d6
	addi.b	#"0",d6
	move.b	d4,(a1)+
	move.b	d6,(a1)+

noajponttt:

	move	(sp)+,d0
	rts

metlesreg1:

	moveq	#0,d5
	moveq	#7,d2
	moveq	#0,d3
	moveq	#0,d0	;longueur pont

toutbit2:

	btst	d7,d1	;pas de registre ou fin pont?
	bne.s	setpont	;non
	tst	d0
	beq.s	noajpont
;cas fin de pont
;mettre - si d0<>2 / sinon
	cmp	#2,d0
	beq.s	metant
	move.b	#"-",(a1)+
	move	d3,d6
	subq	#1,d6	;numero registre
	addi.b	#"0",d6
	move.b	d4,(a1)+
	move.b	d6,(a1)+

metant:

	moveq	#0,d0
	bra.s	noajpont

setpont:
;debut de pont ou continuation si d0<>0
	tst	d0	;mise en place pont
	bne.s	nosetbit1	;oui alors sauter registre
	moveq	#1,d0	;mise en place pont et premier registre
	tst	d5
	beq.s	nosetanti1
	move.b	#"/",(a1)+

nosetanti1:

	move.b	d4,(a1)+
	move.b	d3,(a1)
	addi.b	#"0",(a1)+
	moveq	#1,d5

nosetbit1:

	tst	d0	;pont en marche
	beq.s	noajpont	;non
	addq	#1,d0	;oui alors largeur+1

noajpont:

	addq	#1,d3	;numero de registre
	subq	#1,d7
	dbra	d2,toutbit2
	rts

metlesreg2:

	moveq	#0,d5
	moveq	#7,d2
	moveq	#0,d3
	moveq	#0,d0

toutbit3:

	btst	d7,d1	;pas de registre ou fin pont?
	bne.s	setpont2	;non
	tst	d0
	beq.s	noajpont2
;cas fin de pont
;mettre - si d0<>2 / sinon
	cmp	#2,d0
	beq.s	metant2
	move.b	#"-",(a1)+
	move	d3,d6
	subq	#1,d6	;numero registre
	addi.b	#"0",d6
	move.b	d4,(a1)+
	move.b	d6,(a1)+

metant2:

	moveq	#0,d0
	bra.s	noajpont2

setpont2:
;debut de pont ou continuation si d0<>0
	tst	d0	;mise en place pont
	bne.s	nosetbit2	;oui alors sauter registre
	moveq	#1,d0	;mise en place pont et premier registre
	tst	d5
	beq.s	nosetanti2
	move.b	#"/",(a1)+

nosetanti2:

	move.b	d4,(a1)+
	move.b	d3,(a1)
	addi.b	#"0",(a1)+
	moveq	#1,d5

nosetbit2:


	tst	d0	;pont en marche
	beq.s	noajpont2	;non
	addq	#1,d0	;oui alors largeur+1

noajpont2:

	addq	#1,d3
	addq	#1,d7
	dbra	d2,toutbit3
	rts

subibise:
;DIVS.L,DIVSL.L,DIVU.L,DIVUL.L
;MULS (32 bits),MULU (32 bits)

	btst	#6,d0
	beq	sbibibi
;DIVS.L,DIVSL.L,DIVU.L,DIVUL.L
	move	(a0)+,d1
	btst	#11,d1
	beq	divul
;DIVS.L,DIVSL.L
divsl:

	move	d0,d3
	andi	#%1111111111000000,d3
	cmp	#%0100110001000000,d3
	bne	badmode
	move.b	#"D",(a1)+
	move.b	#"I",(a1)+
	move.b	#"V",(a1)+
	move.b	#"S",(a1)+

comdivu:

	move.b	#2,taille
	move	d1,d3
	andi	#%0111000000000000,d3
	rol	#4,d3
	addi.b	#"0",d3
	move	d1,d4
	andi	#%111,d4
	addi.b	#"0",d4
	move.b	#1,d7
	cmp.b	d3,d4
	beq.s	nosl
	btst	#10,d1
	bne.s	nosl
	clr.b	d7
	move.b	#"L",(a1)+

nosl:

	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	movem	d3-d4/d7/d1,-(sp)
	move	d0,d3
	move.l	#%111111111111111101,d5
	bsr	getmodereg
	movem	(sp)+,d3-d4/d7/d1
	move.b	#",",(a1)+
	move.b	#"D",(a1)+
	tst.b	d7
	beq.s	uselesdeux
	btst	#10,d1
	beq.s	onlyq

uselesdeux:

	move.b	d4,(a1)+
	move.b	#":",(a1)+
	move.b	#"D",(a1)+

onlyq:

	move.b	d3,(a1)+
	rts

divul:
;DIVU.L,DIVUL.L

	move.b	#"D",(a1)+
	move.b	#"I",(a1)+
	move.b	#"V",(a1)+
	move.b	#"U",(a1)+
	bra	comdivu

sbibibi:
;MULS (32 bits),MULU (32 bits)

	move	(a0)+,d1
	btst	#11,d1
	beq.s	mulul
;MULS (32 bits)
mulsl:

	move	d0,d3
	andi	#%1111111111000000,d3
	cmp	#%0100110000000000,d3
	bne	badmode
	move.b	#"M",(a1)+
	move.b	#"U",(a1)+
	move.b	#"L",(a1)+
	move.b	#"S",(a1)+
	bra.s	contmul

mulul:
;MULU (32 bits)

	move.b	#"M",(a1)+
	move.b	#"U",(a1)+
	move.b	#"L",(a1)+
	move.b	#"U",(a1)+

contmul:

	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	move	d1,-(sp)
	move.b	#2,taille
	move	d0,d3
	move.l	#%111111111111111101,d5
	bsr	getmodereg
	move	(sp)+,d1
	move.b	#",",(a1)+
	move.b	#"D",(a1)+
	move	d1,d3
	andi	#%0111000000000000,d3
	rol	#4,d3
	addi.b	#"0",d3
	move	d1,d4
	andi	#%111,d4
	addi.b	#"0",d4
	btst	#10,d1
	beq.s	res32b
	move.b	d4,(a1)+
	move.b	#":",(a1)+
	move.b	#"D",(a1)+

res32b:

	move.b	d3,(a1)+
	rts

subise3:
;CLR,MOVE DE CCR

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq.s	movedeccr
;CLR
clr:

	move	d0,d3
	andi	#%1111111100000000,d3
	cmp	#%0100001000000000,d3
	bne	badmode
	move.b	#"C",(a1)+
	move.b	#"L",(a1)+
	move.b	#"R",(a1)+
	move.l	#%000000111111111101,d5

enttst:

	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop
	move	d0,d3
	bra	getmodereg

movedeccr:

	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.b	#"C",(a1)+
	move.b	#"C",(a1)+
	move.b	#"R",(a1)+
	move.b	#",",(a1)+
	move	d0,d3
	move.l	#%000000111111111101,d5
	bra	getmodereg

subise2:
;Bcc,BRA,BSR

	move	d0,d3
	andi	#%0000111100000000,d3
	tst	d3
	beq.s	bra
	cmp	#%0000000100000000,d3
	beq	bsr
;Bcc
bcc:


	move.b	#"B",(a1)+
	bsr	setcondi2
	bra.s	entbcc

bra:

	move.b	#"B",(a1)+
	move.b	#"R",(a1)+
	move.b	#"A",(a1)+

entbcc:

	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.l	a0,a6
	move	d0,d3
	moveq	#0,d7
	andi	#%11111111,d3
	tst	d3
	beq.s	bra0
	cmp.b	#$ff,d3
	beq.s	bralong
	move.b	#"S",-2(a1)
	move.b	d3,d7
	btst	#7,d3
	beq.s	nowadd
	neg.b	d7
	bra.s	nowsub

bralong:

	move.b	#"L",-2(a1)
	move.l	(a0)+,d7
	btst	#31,d7
	beq.s	nowadd
	neg.l	d7
	bra.s	nowsub

bra0:

	subq.l	#3,a1
	move.b	#" ",(a1)+
	move	(a0)+,d7
	btst	#15,d7
	bne.s	neg7

nowadd:

	add.l	d7,a6
	bra.s	sneg7

neg7:

	neg	d7

nowsub:

	sub.l	d7,a6

sneg7:

	move.l	a6,d7
	tst.b	tabsymb
	beq.s	noislabb
	move.l	savepc,-(sp)
	move	d0,-(sp)
	move	d1,-(sp)
	move.l	a1,savebuffer
	move.l	d7,d5
	move.l	d7,savepc
	move	#22,lglab
	bsr	searchlab
	move	(sp)+,d1
	move	(sp)+,d0
	move.l	(sp)+,savepc
	tst.b	d3
	beq.s	noislabb
	move.l	a5,a1
	cmp.b	#$20,-1(a5)
	bne.s	nosub1b
	subq.l	#1,a1

nosub1b:

	rts

noislabb:

	bra	transhexa

bsr:

	move	#1,getsaut
	move.b	#"B",(a1)+
	move.b	#"S",(a1)+
	move.b	#"R",(a1)+
	bra	entbcc

subise1:
;ADDQ,DBcc,Scc,SUBQ,TRAPcc

	move	d0,d3
	andi	#%0000000011000000,d3
	cmp	#%0000000011000000,d3
	beq	cascc
;ADDQ,SUBQ
	btst	#8,d0
	beq.s	addq
;SUBQ
subq:

	move	d0,d3
	andi	#%0000000000111000,d3
	cmp	#%0000000000001000,d3
	bne.s	notstbq
	move	d0,d3
	andi	#%0000000011000000,d3
	tst	d3
	beq	badmode

notstbq:

	move.b	#"S",(a1)+
	move.b	#"U",(a1)+
	move.b	#"B",(a1)+
	bra.s	addqe2

addq:
;ADDQ

	move	d0,d3
	andi	#%0000000000111000,d3
	cmp	#%0000000000001000,d3
	bne.s	notstb
	move	d0,d3
	andi	#%0000000011000000,d3
	tst	d3
	beq	badmode

notstb:

	move.b	#"A",(a1)+
	move.b	#"D",(a1)+
	move.b	#"D",(a1)+

addqe2:

	move.b	#"Q",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop
	move.b	#"#",(a1)+
	moveq	#0,d7
	move	d0,d7
	andi	#%0000111000000000,d7
	rol	#7,d7
	tst	d7
	bne.s	noset8q
	moveq	#8,d7

noset8q:

	bsr	transhexa
	move.b	#",",(a1)+
	move	d0,d3
	move.l	#%000000111111111111,d5
	bra	getmodereg

cascc:
;DBcc,Scc,TRAPcc

	move	d0,d3
	andi	#%0000000000111000,d3
	cmp	#%0000000000001000,d3
	beq	dbcc
	move	d0,d3
	andi	#%0000000000111111,d3
	cmp	#%0000000000111010,d3
	beq.s	trapcc
	cmp	#%0000000000111011,d3
	beq.s	trapcc
	cmp	#%0000000000111100,d3
	beq.s	trapcc
;Scc
scc:

	move	d0,d3
	andi	#%1111000011000000,d3
	cmp	#%0101000011000000,d3
	bne	badmode
	move.b	#"S",(a1)+
	bsr	setcondi2
	move.b	#" ",(a1)+
	move	d0,d3
	move.l	#%000000111111111101,d5
	bra	getmodereg

trapcc:

	move.b	#"T",(a1)+
	move.b	#"R",(a1)+
	move.b	#"A",(a1)+
	move.b	#"P",(a1)+
	bsr	setcondi2
	btst	#2,d0
	bne.s	nooperande
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.b	#"#",(a1)+
	moveq	#0,d7
	btst	#0,d0
	beq.s	op16
	move.b	#"L",-3(a1)
	move.l	(a0)+,d7
	bra	transhexa

nooperande:

	rts

op16:

	move	(a0)+,d7
	bra	transhexa

dbcc:
;DBcc

	move.b	#"D",(a1)+
	move.b	#"B",(a1)+
	bsr.s	setcondi2
	move.b	#" ",(a1)+
	move.b	#"D",(a1)+
	move	d0,d3
	andi	#%111,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	move.b	#",",(a1)+
	moveq	#0,d7
	move.l	a0,a6	;adresse pc de base
	move	(a0)+,d7
	btst	#15,d7
	beq.s	casadd7
	neg	d7
	sub.l	d7,a6	;adresse de branchement
	bra.s	sauteadd7

casadd7:

	add.l	d7,a6

sauteadd7:

	move.l	a6,d7
	tst.b	tabsymb
	beq.s	noislabbx
	move.l	savepc,-(sp)
	move	d0,-(sp)
	move	d1,-(sp)
	move.l	a1,savebuffer
	move.l	d7,d5
	move.l	d7,savepc
	move	#22,lglab
	bsr	searchlab
	move	(sp)+,d1
	move	(sp)+,d0
	move.l	(sp)+,savepc
	tst.b	d3
	beq	noislabb
	move.l	a5,a1
	cmp.b	#$20,-1(a5)
	bne.s	nosub1bx
	subq.l	#1,a1

nosub1bx:

	rts

noislabbx:

	bra	transhexa

setcondi2:

	move	d0,d1
	andi	#%0000111100000000,d1
	ror	#7,d1
	move.b	(a2,d1.w),(a1)+
	move.b	1(a2,d1.w),(a1)+
	rts

trapv:

	move.b	#"T",(a1)+
	move.b	#"R",(a1)+
	move.b	#"A",(a1)+
	move.b	#"P",(a1)+
	move.b	#"V",(a1)+
	rts

stop:

	move.b	#"S",(a1)+
	move.b	#"T",(a1)+
	move.b	#"O",(a1)+
	move.b	#"P",(a1)+
	move.b	#" ",(a1)+
	move.b	#"#",(a1)+
	moveq	#0,d7
	move	(a0)+,d7
	bra	transhexa

rts:

	move.b	#"R",(a1)+
	move.b	#"T",(a1)+
	move.b	#"S",(a1)+
	rts

rtr:

	move.b	#"R",(a1)+
	move.b	#"T",(a1)+
	move.b	#"R",(a1)+
	rts

rte:

	move	#2,getsaut
	move.b	#"R",(a1)+
	move.b	#"T",(a1)+
	move.b	#"E",(a1)+
	rts

rtd:

	move.b	#"R",(a1)+
	move.b	#"T",(a1)+
	move.b	#"D",(a1)+
	move.b	#" ",(a1)+
	move.b	#"#",(a1)+
	moveq	#0,d7
	move	(a0)+,d7
	btst	#15,d7
	beq	transhexa
	neg	d7
	move.b	#"-",(a1)+
	bra	transhexa

reset:

	move.b	#"R",(a1)+
	move.b	#"E",(a1)+
	move.b	#"S",(a1)+
	move.b	#"E",(a1)+
	move.b	#"T",(a1)+
	rts

nop:

	move.b	#"N",(a1)+
	move.b	#"O",(a1)+
	move.b	#"P",(a1)+
	rts

illegal:

	move.b	#"I",(a1)+
	move.b	#"L",(a1)+
	move.b	#"L",(a1)+
	move.b	#"E",(a1)+
	move.b	#"G",(a1)+
	move.b	#"A",(a1)+
	move.b	#"L",(a1)+
	rts

cas151:
;cas bit 15 … 1 pour les instructions suivantes
;ABCD,ADD,ADDA,ADDX,AND,ASL/R,BFCHG,BFCLR,BFEXTS,BFEXTU
;BFFFO,BFINS,BFSET,BFTST,CMP,CMPA,CMPM,CPBCC,CPDBCC,CPGEN
;CPRESTORE,CPSAVE,CPSCC,CPTRAPCC,DIVS.W,DIVU.W,EOR,EXG
;LSL/SR,MULS (16 bits),MULU (16 bits),OR,PACK,PFLUSH
;PLOAD,PMOVE,PTEST,ROL/R,ROXR/L,SBCD,SUB,SUBA,SUBX,UNPK

	btst	#14,d0
	bne	cas141
;bit 15 … 1 et bit 14 … 0
;CMP,CMPA,CMPM,DIVS.W,DIVU.W,EOR,OR,PACK,SBCD,SUB,SUBA,SUBX,UNPK
	btst	#13,d0
	beq	bit130
;bit 15,13 … 1 et bit 14 … zero pour
;CMP,CMPA,CMPM,EOR

	btst	#12,d0
	beq	badmode

cas12z:
;CMP,CMPA,CMPM,EOR

	move	d0,d3
	andi	#%0000000111000000,d3
	cmp	#%0000000010000000,d3
	bls	cmp
	cmp	#%0000000111000000,d3
	beq	cmpa
	cmp	#%0000000011000000,d3
	beq	cmpa
	cmp	#%0000000100000000,d3
	beq.s	cmpm_eor
	cmp	#%0000000101000000,d3
	beq.s	cmpm_eor
	cmp	#%0000000110000000,d3
	beq.s	cmpm_eor
	bra	badmode

cmpm_eor:

	move	d0,d3
	andi	#%111000,d3
	cmp	#%001000,d3
	bne.s	eor
;CMPM
cmpm:

	move	d0,d3
	andi	#%1111000100111000,d3
	cmp	#%1011000100001000,d3
	bne	badmode
	move.b	#"C",(a1)+
	move.b	#"M",(a1)+
	move.b	#"P",(a1)+
	move.b	#"M",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop
	move	d0,d4
	andi	#%0000111000000000,d4
	rol	#4+3,d4
	addi.b	#"0",d4
	move	d0,d5
	andi	#%0000000000000111,d5
	addi.b	#"0",d5
	move.b	#"(",(a1)+
	move.b	#"A",(a1)+
	move.b	d5,(a1)+
	move.b	#")",(a1)+
	move.b	#"+",(a1)+
	move.b	#",",(a1)+
	move.b	#"(",(a1)+
	move.b	#"A",(a1)+
	move.b	d4,(a1)+
	move.b	#")",(a1)+
	move.b	#"+",(a1)+
	rts

;EOR
eor:

	move.b	#"E",(a1)+
	move.b	#"O",(a1)+
	move.b	#"R",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop2
	bsr	getreg
	move.b	#",",(a1)+
	move.l	#%000000111111111101,d5
	move	d0,d3
	bra	getmodereg

cmpa:

	move.b	#"C",(a1)+
	move.b	#"M",(a1)+
	move.b	#"P",(a1)+
	bra	adda

cmp:

	move.b	#"C",(a1)+
	move.b	#"M",(a1)+
	move.b	#"P",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.b	#1,taille
	bsr	tailleop
	move.l	#%111111111111111111,d5
	move	d0,d3
	bsr	getmodereg
	move.b	#",",(a1)+
	bra	getreg

bit130:
;bit 15 … 1 et bit 13,14 … zero pour
;DIVS.W,DIVU.W,OR,PACK,SBCD,SUB,SUBA,SUBX,UNPK

	btst	#12,d0
	bne	bit121
;bit 15 … 1 et 14,13,12 … zero pour
;DIVS.W,DIVU.W,OR,PACK,SBCD,UNPK
	move	d0,d3
	andi	#%0000000111000000,d3
	cmp	#%0000000111000000,d3
	beq	divsw
	cmp	#%0000000011000000,d3
	beq	divuw
;OR,PACK,SBCD,UNPK
	move	d0,d3
	andi	#%0000000000111000,d3
	tst	d3
	beq.s	caspx_or8dn
	cmp	#%0000000000001000,d3
	beq.s	caspx
;OR
or:

	move.l	#%000000111111111100,d5	;vers Ae

or2:

	move.b	#"O",(a1)+
	move.b	#"R",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop2
	btst	#8,d0
	beq.s	versdn2
	bsr	getreg
	move.b	#",",(a1)+
	move	d0,d3
	bra	getmodereg

versdn2:

	move.l	#%111111111111111101,d5
	move	d0,d3
	bsr	getmodereg
	move.b	#",",(a1)+
	bra	getreg

caspx_or8dn:

	btst	#8,d0
	beq.s	or

caspx:
;PACK,UNPK,SBCD
	move	d0,d3
	andi	#%0000000111110000,d3
	cmp	#%0000000101000000,d3
	beq.s	pack
	cmp	#%0000000100000000,d3
	beq.s	sbcd
	cmp	#%0000000110000000,d3
	beq.s	unpk
	bra	badmode

pack:

	move.b	#"P",(a1)+
	move.b	#"A",(a1)+
	move.b	#"C",(a1)+
	move.b	#"K",(a1)+

contaspk:

	move.b	#" ",(a1)+
	bsr	setddormm
	move.b	#",",(a1)+
	move.b	#"#",(a1)+
	moveq	#0,d7
	move	(a0)+,d7
	bra	transhexa

sbcd:

	move.b	#"S",(a1)+
	bra	entsbcd

unpk:

	move.b	#"U",(a1)+
	move.b	#"N",(a1)+
	move.b	#"P",(a1)+
	move.b	#"K",(a1)+
	bra.s	contaspk


divsw:
;instruction DIVS.W (32/16->r16:q16)

	move.b	#"D",(a1)+
	move.b	#"I",(a1)+
	move.b	#"V",(a1)+
	move.b	#"S",(a1)+

restdivusw:

	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.b	#1,taille
	move.l	#%111111111111111101,d5
	move	d0,d3
	bsr	getmodereg
	move.b	#",",(a1)+
	bra	getreg	;1er operande

divuw:

	move.b	#"D",(a1)+
	move.b	#"I",(a1)+
	move.b	#"V",(a1)+
	move.b	#"U",(a1)+
	bra.s	restdivusw

bit121:
;bit 15,12 … 1 et 14,13 … zero pour
;SUB,SUBA,SUBX

	move.b	#"S",(a1)+
	move.b	#"U",(a1)+
	move.b	#"B",(a1)+
	bra	enttypep

cas141:
;cas bit 15 … 1 et bit 14 … 1 pour
;ABCD,ADD,ADDA,ADDX,AND,ASL/R,BFCHG,BFCLR,BFEXTS,BFEXTU
;BFFFO,BFINS,BFSET,BFTST,CPBCC,CPDBCC,CPGEN,CPRESTORE,CPSAVE
;CPSCC,CPTRAPCC,EXG,LSL/R,MULS (16 bits),MULU (16 bits)
;PFLUSH,PLOAD,PMOVE,PTEST,ROL/R,ROXL/R

	btst	#13,d0
	bne	cas131
;cas bit 15,14 … 1 et 13 … zero pour
;ABCD,ADD,ADDA,ADDX,AND,EXG,MULS (16 bits),MULU (16 bits)
	btst	#12,d0
	bne	cas121b
;cas bit 15,14 … 1 et 13 et 12 … zero pour
;ABCD,AND,EXG,MULS (16 bits),MULU (16 bits)
	move	d0,d3
	andi	#%1111000111110000,d3
	cmp	#%1100000100000000,d3
	beq	abcd
;cas AND,EXG,MULS (16 bits) ou MULU (16 bits)
	move	d0,d3
	andi	#%0000000111000000,d3
	cmp	#%0000000111000000,d3
	beq	muls16
	cmp	#%0000000011000000,d3
	beq	mulu16
;AND et EXG
	move	d0,d3
	andi	#%1111000111111000,d3
	cmp	#%1100000101000000,d3
	beq.s	exgdd
	cmp	#%1100000101001000,d3
	beq.s	exgaa
	cmp	#%1100000110001000,d3
	beq	exgda
;cas AND
and:

	move.b	#"A",(a1)+
	move.b	#"N",(a1)+
	move.b	#"D",(a1)+
	move.l	#%111111111111111101,d5
	bra	enttype

setexg:

	move.b	#"E",(a1)+
	move.b	#"X",(a1)+
	move.b	#"G",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	rts

exgdd:
;echange entre 2 registres de donn‚es

	move.b	#"E",(a1)+
	move.b	#"X",(a1)+
	move.b	#"G",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	bsr	getreg	;1er operande
	move.b	#",",(a1)+
	move	d0,d3
	bra	casregd	;2eme operande

exgaa:
;echange entre 2 registres d'adresse

	move.b	#"E",(a1)+
	move.b	#"X",(a1)+
	move.b	#"G",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	bsr.s	setrega2
	move.b	#",",(a1)+
	bra.s	setrega1

setrega3:

	move	d0,d3	;mot d'extension modes indirects
	andi	#%111,d3
	move.b	#"A",(a1)+
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

setrega1:

	move	d0,d3
	andi	#%111,d3
	bra.s	rega

setrega2:

	move	d0,d3
	andi	#%0000111000000000,d3
	rol	#7,d3

rega:

	move.b	#"A",(a1)+
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

exgda:
;echange entre un reg adresse et un reg donnee

	move.b	#"E",(a1)+
	move.b	#"X",(a1)+
	move.b	#"G",(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	bsr	getreg
	move.b	#",",(a1)+
	bra.s	setrega1

mulu16:

	move.b	#"M",(a1)+
	move.b	#"U",(a1)+
	move.b	#"L",(a1)+
	move.b	#"U",(a1)+
	bra.s	mulsent

muls16:

	move.b	#"M",(a1)+
	move.b	#"U",(a1)+
	move.b	#"L",(a1)+
	move.b	#"S",(a1)+

mulsent:

	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	move.b	#1,taille
	move.l	#%111111111111111101,d5
	move	d0,d3
	bsr	getmodereg
	move.b	#",",(a1)+
	bra	getreg

abcd:

	move.b	#"A",(a1)+

entsbcd:

	move.b	#"B",(a1)+
	move.b	#"C",(a1)+
	move.b	#"D",(a1)+
	move.b	#" ",(a1)+
	bra	setddormm	;2 registres de donnee ou -(ax1),-(ax2)

cas121b:
;cas bit 15,14,12 … 1 et 13 … zero pour
;ADD,ADDA,ADDX

	move.b	#"A",(a1)+
	move.b	#"D",(a1)+
	move.b	#"D",(a1)+

enttypep:
;ADD,ADDA,ADDX,SUB,SUBA,SUBX

	move.l	#%000000111111111100,d5
	move	d0,d3
	andi	#%0000000111000000,d3
	cmp	#%0000000111000000,d3
	beq	adda
	cmp	#%0000000011000000,d3
	beq	adda
	move	d0,d3
	andi	#%0000000000110000,d3
	btst	#8,d0
	beq.s	enttype
	tst	d3
	beq	addx

;cas ADD/SUB ou OR par defaut d5 vers ae
enttype:

	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr.s	tailleop2
	btst	#8,d0
	beq.s	versdn
	bsr	getreg
	move.b	#",",(a1)+
	move	d0,d3
	bra	getmodereg

tailleop2:

	move	d0,d3
	andi	#%111000000,d3
	tst	d3
	beq.s	taioct
	cmp	#%100000000,d3
	beq.s	taioct
	cmp	#%110000000,d3
	beq.s	tailong
	cmp	#%111000000,d3
	beq.s	tailong
	cmp	#%010000000,d3
	beq.s	tailong
	move.b	#1,taille
	subq.l	#3,a1
	move.b	#" ",(a1)+
	rts

taioct:

	move.b	#"B",-2(a1)
	clr.b	taille
	rts

tailong:

	move.b	#"L",-2(a1)
	move.b	#2,taille
	rts

versdn:

	move	d0,d4
	andi	#%0000000000111000,d4
	cmp	#%0000000000001000,d4	;mode An
	bne.s	noavecAn		;non
	move	d0,d3		;oui alors
	andi	#%0000000111000000,d3	;mode
	tst	d3		;sur octet?
	beq	badmode		;oui alors impossible

noavecAn:

	move.l	#%111111111111111111,d5
	move	d0,d3
	bsr	getmodereg
	move.b	#",",(a1)+
	bra.s	getreg

execa3:

	move.l	#%000000111111111100,d5

adda:

	move.b	#"A",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop2
	move.l	#%111111111111111111,d5
	move	d0,d3
	bsr	getmodereg
	move.b	#",",(a1)+
	bra	setrega2

getreg:

	move	d0,d3
	andi	#%0000111000000000,d3
	rol	#7,d3
	addi.b	#"0",d3
	move.b	#"D",(a1)+	;registre de donnee
	move.b	d3,(a1)+
	rts

addx:

	move	d0,d3
	andi	#%0000000100110000,d3
	cmp	#%0000000100000000,d3
	bne	badmode
	move.b	#"X",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	bsr	tailleop

setddormm:

	move	d0,d4
	move	d0,d5
	andi	#%111,d5
	andi	#%0000111000000000,d4
	rol	#7,d4
	addi.b	#"0",d4
	addi.b	#"0",d5
	btst	#3,d0
	bne.s	predec
	move.b	#"D",(a1)+
	move.b	d5,(a1)+
	move.b	#",",(a1)+
	move.b	#"D",(a1)+
	move.b	d4,(a1)+
	rts

predec:

	move.b	#"-",(a1)+
	move.b	#"(",(a1)+
	move.b	#"A",(a1)+
	move.b	d5,(a1)+
	move.b	#")",(a1)+
	move.b	#",",(a1)+
	move.b	#"-",(a1)+
	move.b	#"(",(a1)+
	move.b	#"A",(a1)+
	move.b	d4,(a1)+
	move.b	#")",(a1)+
	rts

cas131:
;cas bit 15,14 et 13 … 1 pour:
;ASL/R,BFCHG,BFCLR,BFEXTS,BFEXTU,BFFFO,BFINS,BFSET,BFTST
;CPBCC,CPDBCC,CPGEN,CPRESTORE,CPSAVE,CPSCC,CPTRAPCC,LSL/R
;PFLUSH,PLOAD,PMOVE,PTEST,ROL/R,ROXL/R

	btst	#12,d0
	bne	cas121
;cas bit 15,14,13 … 1 et bit 12 … zero pour
;ASL/R,BFCHG,BFCLR,BFEXTS,BFEXTU,BFFFO,BFINS,BFSET,BFTST
;LSL/R,ROL/R,ROXL/R

	move	d0,d3
	andi	#%11000000,d3
	cmp	#%11000000,d3
	beq.s	casoutiti
;ASL/R (registre),LSL/R (registre),ROL/R (registre),ROXR/L (registre)
	move	d0,d3
	andi	#%1111000000011000,d3
	cmp	#%1110000000000000,d3
	beq	asl_r
	cmp	#%1110000000001000,d3
	beq	lsl_r
	cmp	#%1110000000011000,d3
	beq	rol_r
	cmp	#%1110000000010000,d3
	beq	roxl_r
	bra	badmode

casoutiti:
;ASL/R (adresse),LSL/R (adresse),ROL/R (adresse),ROXR/L (adresse)

	move	d0,d3
	andi	#%111000,d3	;mode+registre BFxxx
	cmp	#%111000,d3	;modes immediats
	beq	peutbf2

peutbf:
;pas de mode relatif au pc pour ces instructions seuls immediats

	move	d0,d3
	andi	#%1111111111000000,d3	;partie superieure
	cmp	#%1110101011000000,d3
	beq	bfchg
	cmp	#%1110110011000000,d3
	beq	bfclr
	cmp	#%1110111111000000,d3
	beq	bfins
	cmp	#%1110111011000000,d3
	beq	bfset

peutpart2:
;modes immediats et avec pc

	cmp	#%1110101111000000,d3
	beq	bfexts
	cmp	#%1110100111000000,d3
	beq	bfextu
	cmp	#%1110110111000000,d3
	beq	bfffo
	cmp	#%1110100011000000,d3
	beq	bftst
	cmp	#%1110000011000000,d3
	beq	asra
	cmp	#%1110000111000000,d3
	beq	asla
	cmp	#%1110001011000000,d3
	beq	lsra
	cmp	#%1110001111000000,d3
	beq	lsla
	cmp	#%1110011011000000,d3
	beq	rora
	cmp	#%1110011111000000,d3
	beq	rola
	cmp	#%1110010011000000,d3
	beq	roxra
	cmp	#%1110010111000000,d3
	beq	roxla
	bra	badmode

lsl_r	bsr.s	getprem2
	bra.s	zeste

rol_r	bsr.s	getprem3
	bra.s	zeste

roxl_r	bsr.s	getprem4
	bra.s	zeste

getprem1	btst	#8,d0
	beq.s	rotadr
	bsr	casasl
	rts

rotadr	bsr	casasr

seetaille	rts

getprem2	btst	#8,d0
	beq.s	rotadr2
	bsr	caslsl
	bra.s	seetaille

rotadr2	bsr	caslsr
	bra.s	seetaille

getprem3	btst	#8,d0
	beq.s	rotadr3
	bsr	casrol
	bra.s	seetaille

rotadr3	bsr	casror
	bra.s	seetaille

getprem4	btst	#8,d0
	beq.s	rotadr4
	bsr	casroxl
	bra.s	seetaille

rotadr4	bsr	casroxr
	bra.s	seetaille

asl_r	;ASL/R d‚calage registre

	bsr.s	getprem1

zeste	bsr.s	tailleop
	move.b	#"#",(a1)+
	btst	#5,d0
	beq.s	withnum
	move.b	#"D",-1(a1)

withnum	move	d0,d3
	andi	#%0000111000000000,d3
	rol	#7,d3
	tst	d3
	bne.s	noset8
	moveq	#8,d3

noset8	addi.b	#"0",d3
	move.b	d3,(a1)+
	move.b	#",",(a1)+
	move	d0,d3
	andi.b	#%111,d3	;numero de registre
	addi.b	#"0",d3
	move.b	#"D",(a1)+
	move.b	d3,(a1)+
	rts

tailleop	move	d0,d3
	andi	#%0000000011000000,d3
	tst	d3
	bne.s	notaioct
	move.b	#"B",-2(a1)
	clr.b	taille
	rts

notaioct	cmp	#%0000000010000000,d3
	bne.s	seenum
	move.b	#2,taille
	move.b	#"L",-2(a1)
	rts

seenum	cmp.b	#%0000000011000000,d3
	beq	badmode
	subq.l	#3,a1
	move.b	#" ",(a1)+
	rts

asra	bsr.s	casasr

controt	move.l	#%000000111111111100,d5
	move	d0,d3	;sauver type adressage
	bra	getmodereg

casasr	move.b	#"A",(a1)+

content2	move.b	#"S",(a1)+
	move.b	#"R",(a1)+

contww	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	rts

casasl	move.b	#"A",(a1)+

content	move.b	#"S",(a1)+
	move.b	#"L",(a1)+
	bra.s	contww

asla	bsr.s	casasl
	bra.s	controt

caslsl	move.b	#"L",(a1)+
	bra.s	content

caslsr	move.b	#"L",(a1)+
	bra.s	content2

lsra	bsr.s	caslsr
	bra.s	controt

lsla	bsr.s	caslsl
	bra.s	controt

casror	move.b	#"R",(a1)+
	move.b	#"O",(a1)+
	move.b	#"R",(a1)+
	bra.s	contww

casrol	move.b	#"R",(a1)+
	move.b	#"O",(a1)+
	move.b	#"L",(a1)+
	bra.s	contww

rora	bsr.s	casror
	bra.s	controt

rola	bsr.s	casrol
	bra.s	controt

casroxl	move.b	#"R",(a1)+
	move.b	#"O",(a1)+
	move.b	#"X",(a1)+
	move.b	#"L",(a1)+
	bra.s	contww

casroxr	move.b	#"R",(a1)+
	move.b	#"O",(a1)+
	move.b	#"X",(a1)+
	move.b	#"R",(a1)+
	bra.s	contww

roxra	bsr.s	casroxr
	bra	controt

roxla	bsr.s	casroxl
	bra	controt

bftst	move.b	#"B",(a1)+
	move.b	#"F",(a1)+
	move.b	#"T",(a1)+
	move.b	#"S",(a1)+
	move.b	#"T",(a1)+
	move.b	#" ",(a1)+
	move	(a0)+,d1
	move.l	#%111110111111100101,d5
	bra	dopart2p

bfffo	move.b	#"B",(a1)+
	move.b	#"F",(a1)+
	move.b	#"F",(a1)+
	move.b	#"F",(a1)+
	move.b	#"O",(a1)+
	bra.s	laparte

bfexts	move.b	#"B",(a1)+
	move.b	#"F",(a1)+
	move.b	#"E",(a1)+
	move.b	#"X",(a1)+
	move.b	#"T",(a1)+
	move.b	#"S",(a1)+

laparte	move.b	#" ",(a1)+
	move	(a0)+,d1
	move.l	#%111110111111100101,d5
	bsr.s	dopart2p
	bra.s	partcom2

bfextu	move.b	#"B",(a1)+
	move.b	#"F",(a1)+
	move.b	#"E",(a1)+
	move.b	#"X",(a1)+
	move.b	#"T",(a1)+
	move.b	#"U",(a1)+
	bra.s	laparte

partcom2	move.b	#",",(a1)+
	move.b	#"D",(a1)+
	move	d1,d4
	andi	#%0111000000000000,d4
	rol	#4,d4
	addi.b	#"0",d4
	move.b	d4,(a1)+	;num registre de donnees
	rts

bfset	;instruction BFSET

	move.b	#"B",(a1)+
	move.b	#"F",(a1)+
	move.b	#"S",(a1)+
	move.b	#"E",(a1)+
	move.b	#"T",(a1)+
	move.b	#" ",(a1)+
	bra	partcom

dopart2	move.l	#%111111100101,d5

dopart2p	move	d1,-(sp)
	move	d0,d3	;sauver type adressage
	bsr	getmodereg
	move.b	#"{",(a1)+
	move	(sp)+,d1
	move	d1,d3
	andi	#%11111000000,d3	;reg deplacement
	lsr	#6,d3
	btst	#11,d1
	beq.s	casnumdep
	cmp	#8,d3
	bhs	badmode
	move.b	#"D",(a1)+
	addi.b	#"0",d3
	move.b	d3,(a1)+
	bra.s	otherpart

casnumdep	moveq	#0,d7
	move	d3,d7
	bsr.s	transdeci

otherpart	move.b	#":",(a1)+
	move	d1,d3
	andi	#%11111,d3	;reg deplacement
	btst	#5,d1
	beq.s	casnumlg
	cmp	#8,d3
	bhs	badmode
	move.b	#"D",(a1)+
	addi.b	#"0",d3
	move.b	d3,(a1)+
	bra.s	otherpart2

casnumlg	moveq	#0,d7
	tst	d3
	bne.s	nomet32
	move	#32,d3

nomet32	move	d3,d7
	bsr.s	transdeci

otherpart2	move.b	#"}",(a1)+
	rts

transdeci	;d7=nbre en .W donc de 0 … 65535 max

	andi.l	#$ffff,d7
	divu	#10,d7
	tst	d7
	beq.s	nodiz
	addi.b	#"0",d7
	move.b	d7,(a1)+

nodiz	swap	d7
	addi.b	#"0",d7
	move.b	d7,(a1)+
	rts

bfins	;instruction BFINS

	move.b	#"B",(a1)+
	move.b	#"F",(a1)+
	move.b	#"I",(a1)+
	move.b	#"N",(a1)+
	move.b	#"S",(a1)+
	move.b	#" ",(a1)+
	move	(a0)+,d1
	move	d1,d3
	andi	#%0111000000000000,d3	;registre de donnee
	rol	#4,d3
	addi.b	#"0",d3
	move.b	#"D",(a1)+
	move.b	d3,(a1)+	;numero registre donnee
	move.b	#",",(a1)+
	bra	dopart2	;partie adresse/depl/largeur zone de bits

bfclr	;instruction BFCLR

	move.b	#"B",(a1)+
	move.b	#"F",(a1)+
	move.b	#"C",(a1)+
	move.b	#"L",(a1)+
	move.b	#"R",(a1)+
	move.b	#" ",(a1)+

partcom	move	(a0)+,d1
	move	d1,d3
	andi	#%1111000000000000,d3
	tst	d3
	bne	badmode
	bra	dopart2

partcomb	move	(a0)+,d1
	bra	dopart2

bfchg	;instruction BFCHG

	move.b	#"B",(a1)+
	move.b	#"F",(a1)+
	move.b	#"C",(a1)+
	move.b	#"H",(a1)+
	move.b	#"G",(a1)+
	move.b	#" ",(a1)+
	bra.s	partcom

peutbf2	move	d0,d3
	andi	#%111,d3
	tst	d3
	beq	peutbf
	cmp	#%1,d3
	beq	peutbf
	cmp	#%10,d3	;mode etendus pour certaines instructions
	beq	peutpart2
	cmp	#%11,d3
	beq	peutpart2
	bra	badmode

cas121:
;cas bits 15,14,13 et 12 … 1 pour:
;CPBCC,CPDBCC,CPGEN,CPRESTORE,CPSAVE,CPSCC,CPTRAPCC,PFLUSH
;PLOAD,PMOVE,PTEST

	btst	#7,d0
	bne	cas71
	btst	#6,d0
	bne	cas61

;CPGEN,CPSAVE,PFLUSH,PLOAD,PMOVE,PTEST
;bit 15,14,13 et 12 … 1 et bit 6 et 7 … zero
;CPGEN ne sera pas trait‚

	btst	#8,d0
	bne	cpsave

;CPGEN,PFLUSH,PLOAD,PMOVE,PTEST

	move	(a0)+,d1
	move	d1,d3
	andi	#%1110000000000000,d3
	cmp	#%0010000000000000,d3
	beq	pflushorl
	cmp	#%1000000000000000,d3
	beq.s	ptest
;PMOVE
	move	d0,d4
	andi	#%1111111111000000,d4
	cmp	#%1111000000000000,d4
	bne	badmode
	move.b	#"P",(a1)+
	move.b	#"M",(a1)+
	move.b	#"O",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	btst	#8,d1
	beq.s	nometfd
	move.b	#"F",(a1)+
	move.b	#"D",(a1)+

nometfd:

	cmp	#%0100000000000000,d3
	beq	pmovecst
	tst	d3
	beq	pmovett
	cmp	#%0110000000000000,d3
	beq.s	pmovem
	bra	badmode

ptest:

	move.b	#"P",(a1)+
	move.b	#"T",(a1)+
	move.b	#"S",(a1)+
	move.b	#"T",(a1)+
	bsr	dofcandae
	move.b	#",",(a1)+
	move.b	#"#",(a1)+
	moveq	#0,d7
	move	d1,d7
	andi	#%0001110000000000,d7
	rol	#6,d7
	addi.b	#"0",d7
	move.b	d7,(a1)+
	btst	#8,d1
	bne.s	unrega
	move	d1,d3		;pas de registre
	andi	#%0000000011100000,d3	;champ REG … zero
	bne	badmode		;non alors erreur
	rts

unrega:

	move.b	#",",(a1)+
	move.b	#"A",(a1)+
	move	d1,d3
	andi	#%0000000011100000,d3
	ror	#5,d3
	addi.b	#"0",d3
	move.b	d3,(a1)+
	rts

pmovem:
;pmove pour le registre MMUSR

	move	d1,d3
	andi	#%1111110111111111,d3
	cmp	#%0110000000000000,d3
	bne	badmode
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	btst	#9,d1
	bne.s	regvermem3
	bsr	doae
	move.b	#",",(a1)+
	bra.s	metmmusr

regvermem3:

	bsr.s	metmmusr
	move.b	#",",(a1)+
	bra	doae	;adresse effective

metmmusr:

	move.b	#"M",(a1)+
	move.b	#"M",(a1)+
	move.b	#"U",(a1)+
	move.b	#"S",(a1)+
	move.b	#"R",(a1)+
	rts

pmovett:
;pmove pour tt0 et tt1

	move	d1,d3
	andi	#%1110000011111111,d3
	tst	d3
	bne	badmode
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	btst	#9,d1
	bne.s	regvermem2
	bsr	doae	;adresse effective
	move.b	#",",(a1)+
	bra.s	doregt0t1

regvermem2:

	bsr.s	doregt0t1
	move.b	#",",(a1)+
	bra	doae	;adresse effective

pmovecst:
;pmove pour les registres CRP,SRP,TC

	move	d1,d3
	andi	#%1110000011111111,d3
	cmp	#%0100000000000000,d3
	bne	badmode
	bsr.s	dolongcst
	move.b	#" ",(a1)+
	btst	#9,d1
	bne.s	regvermem
	bsr	doae	;adresse effective
	move.b	#",",(a1)+
	bra.s	doregcst

regvermem:

	bsr.s	doregcst
	move.b	#",",(a1)+
	bra	doae	;adresse effective

dolongcst:
;longueur registres: .D (64bits) pour CRP et SRP
;.L pour TC

	move	d1,d3
	andi	#%0001110000000000,d3
	tst	d3
	bne.s	notcl
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	rts

notcl:

	cmp	#%0000100000000000,d3
	beq.s	metpd
	cmp	#%0000110000000000,d3
	bne	badmode

metpd:

	move.b	#".",(a1)+
	move.b	#"D",(a1)+
	rts

doregt0t1:

	move.b	#"T",(a1)+
	move.b	#"T",(a1)+
	move	d1,d3
	andi	#%0001110000000000,d3
	cmp	#%0000100000000000,d3
	bne.s	nott0
	move.b	#"0",(a1)+
	rts

nott0:

	cmp	#%0000110000000000,d3
	bne	badmode
	move.b	#"1",(a1)+
	rts

doregcst:

	move	d1,d3
	andi	#%0001110000000000,d3
	tst	d3
	bne.s	notc
	move.b	#"T",(a1)+
	move.b	#"C",(a1)+
	rts

notc:

	cmp	#%0000100000000000,d3
	bne.s	nosrp
	move.b	#"S",(a1)+
	move.b	#"R",(a1)+
	move.b	#"P",(a1)+
	rts

nosrp:

	cmp	#%0000110000000000,d3
	bne	badmode
	move.b	#"C",(a1)+
	move.b	#"R",(a1)+
	move.b	#"P",(a1)+

*sauteae:

	rts

pflushorl:
;CPGEN,PFLUSH,PLOAD

	move	d1,d3
	andi	#%0001110000000000,d3
	tst	d3
	bne.s	pflush
;CPGEN,PLOAD
;cas pload CPGEN non trait‚
pload:

	move	d0,d3
	andi	#%1111111111000000,d3
	cmp	#%1111000000000000,d3
	bne	badmode
	move.b	#"P",(a1)+
	move.b	#"L",(a1)+
	move.b	#"O",(a1)+
	move.b	#"A",(a1)+
	move.b	#"D",(a1)+
	move	d1,d3
	andi	#%1111110111100000,d3
	cmp	#%0010000000000000,d3	;verifier 2 eme mot
	bne	badmode

dofcandae:

	move.b	#"W",(a1)+
	btst	#9,d1	;acces en ecriture
	beq.s	dofcandae	;oui
	move.b	#"R",-1(a1)	;acces en lecture
	move.b	#" ",(a1)+
	move	d1,d3
	bsr.s	dofc1	;1er partie FC
	move.b	#",",(a1)+
	bra	doae	;partie adresse

pflush:

	move.b	#"P",(a1)+
	move.b	#"F",(a1)+
	move.b	#"L",(a1)+
	move.b	#"U",(a1)+
	move.b	#"S",(a1)+
	move.b	#"H",(a1)+
	move	d1,d3
	andi	#%0001110000000000,d3
	cmp	#%0000010000000000,d3
	beq.s	pflusha
	cmp	#%0001000000000000,d3
	beq.s	pflushc
	cmp	#%0001100000000000,d3
	beq.s	pflushca
	bra	badmode

pflusha:

	move.b	#"A",(a1)+
	rts

pflushc:
;partie avec 2 donnees FC et validation FC

	move.b	#" ",(a1)+
	move	d1,d3

dofc:

	bsr.s	dofc1	;1er partie FC
	move.b	#",",(a1)+
	move	d1,d3
	andi	#%11100000,d3
	lsr	#5,d3
	addi.b	#"0",d3
	move.b	#"#",(a1)+	;validation FC
	move.b	d3,(a1)+
	rts

pflushca:
;meme chose que pflush donnees mais en plus registre adresse

	move.b	#" ",(a1)+
	move	d1,d3
	bsr.s	dofc
	move.b	#",",(a1)+
	bra.s	doae	;partie adresse

dofc1:

	andi	#%11111,d3
	btst	#4,d3
	bne.s	casnumber
	btst	#3,d3
	bne.s	casregd
	tst.b	d3
	beq.s	casSFC
	cmp.b	#%1,d3
	bne	badmode
;cas DFC
	move.b	#"D",(a1)+
	bra.s	contFC

casSFC:

	move.b	#"S",(a1)+

contFC:

	move.b	#"F",(a1)+
	move.b	#"C",(a1)+
	rts

casregd:
;utilisation registre de donn‚es

	andi	#%111,d3
	addi.b	#"0",d3
	move.b	#"D",(a1)+
	bra.s	casnume2

casnumber:

	andi	#%111,d3
	addi.b	#"0",d3	;nbre de 0 … 7
	move.b	#"#",(a1)+

casnume2:

	move.b	d3,(a1)+
	rts

doae:
;partie adresse

	move.l	#%000000111111100100,d5
	move	d0,d3	;sauver type adressage
	bra	getmodereg

cpsave:
;instruction cpSAVE

	move.b	#"F",(a1)+
	move.b	#"S",(a1)+
	move.b	#"A",(a1)+
	move.b	#"V",(a1)+
	move.b	#"E",(a1)+
	move.b	#" ",(a1)+
	move.l	#%111111110100,d5	;mode possibles
	move	d0,d3	;sauver type adressage
	bra	getmodereg

cas61:
;cas bits 15,14,13,12 et 6 … 1 et bit 7 … zero pour:
;CMPM (16 bits),CPDBCC,CPRESTORE,CPSCC,CPTRAPCC

	btst	#8,d0
	bne	cas81
	move	d0,d1
	andi	#%111000,d1
	cmp.b	#%001000,d1	;mode=%001
	beq	cascpdbcc	;oui alors instruction dbcc copro
	move	d0,d1
	andi	#%111111,d1
	cmp.b	#%111010,d1
	beq.s	ftrapcc1
	cmp.b	#%111011,d1
	beq.s	ftrapcc2
	cmp.b	#%111100,d1
	beq.s	ftrapcc3
;instruction CPSCC
	move	d0,d3
	andi	#%1111000111000000,d3
	cmp	#%1111000001000000,d3
	bne	badmode
	move.b	#"F",(a1)+
	move.b	#"S",(a1)+
	move.l	#%111111111101,d5	;mode possibles

execadr:

	move	d0,-(sp)
	move	d0,d3	;sauver type adressage
	moveq	#-1,d0
	move	(a0)+,d1	;condition
	bsr	setcondi
	move.b	#" ",(a1)+
	move	(sp)+,d0
	bra	getmodereg

ftrapcc1:
;instruction cpTRAPcc
;operande sur 16 bits

	moveq	#0,d0
	bsr.s	settrapcc
	move	d0,d7
	andi.l	#$ffff,d7
	bra.s	doacc2

ftrapcc2:
;instruction cpTRAPcc
;operande sur 32 bits

	move	#%1000000,d0
	bsr.s	settrapcc
	move.l	d0,d7

doacc2:

	move.b	#"#",(a1)+
	bra	transhexa

ftrapcc3:
;instruction cpTRAPcc
;pas d'operande

	moveq	#-1,d0

settrapcc:

	move.b	#"F",(a1)+
	move.b	#"T",(a1)+
	move.b	#"R",(a1)+
	move.b	#"A",(a1)+
	move.b	#"P",(a1)+
	move	(a0)+,d1	;recuperer condition
	tst	d0
	bmi	setcondi
	bra	condicopro

cascpdbcc:
;instruction: cpDBcc

	move.l	a6,a5
	addq.l	#4,a5
	move	d0,d1
	andi	#%111000000000,d1;CP-ID=0?
	beq	badmode	;oui alors mettre dc $aabb
	btst	#8,d0
	bne	badmode
;instruction valide
	cmp	#%1000000000,d1	;copro 1?
	bne	badmode	;non alors rien
	move.b	#"F",(a1)+
	move.b	#"D",(a1)+
	move.b	#"B",(a1)+
	move	(a0)+,d1	;mot avec condition copro
	move	d0,d4
	andi	#%111,d4	;numero registre donnee
	addi.b	#"0",d4
	moveq	#0,d0	;simuler longueur 16 bits
	bsr	condicopro	;mettre condition+taille+espace
	move.b	#"D",(a1)+
	move.b	d4,(a1)+
	move.b	#",",(a1)+
	bra	metladress

cas81:
;cas bits 15,14,13,12,8 et 6 … 1 et bit 7 … zero
;CPRESTORE

	move	d0,d1
	andi	#%0000111000000000,d1;CP-ID=0?
	beq	badmode	;oui alors mettre dc $aabb
	move.b	#"F",(a1)+
	move.b	#"R",(a1)+
	move.b	#"E",(a1)+
	move.b	#"S",(a1)+
	move.b	#"T",(a1)+
	move.b	#"O",(a1)+
	move.b	#"R",(a1)+
	move.b	#"E",(a1)+
	move.b	#" ",(a1)+
	move	d0,d3
	move.l	#%111110111111101100,d5	;mode possibles

getmodereg:
;transcrir mode+registre en code

	andi	#%111111,d3	;isoler champs mode+registre
	move	d3,d4
	andi	#%111,d4	;decrypter registre
	addi.b	#"0",d4
	lsr	#3,d3	;decrypter mode
	tst.b	d3
	beq	mDn
	cmp.b	#%1,d3
	beq	mAn
	cmp.b	#%10,d3
	beq	mpAnp
	cmp.b	#%100,d3
	beq	mmoinsAn
	cmp.b	#%11,d3
	beq	mAnplus
	cmp.b	#%101,d3
	beq	md16An
	move.b	#1,usean
	cmp.b	#%110,d3
	beq	casmodext
	cmp.b	#%111,d3
	beq.s	casmodepc
;d3=%111
	rts

casmodepc:
;mode relatif au pc ou par donn‚e
;relatif:meme chose que avec An mais An=PC

	cmp.b	#%0+"0",d4
	beq.s	casadrw
	cmp.b	#%1+"0",d4
	beq	casadrl
	cmp.b	#%100+"0",d4
	beq	casdonnee
	cmp.b	#%10+"0",d4
	beq.s	d16pc
	cmp.b	#%11+"0",d4
	beq.s	extmodes
	bra	badmode	;mode inexistant

extmodes:
;cas mode etendu 68030 avec An remplac‚ par PC

	btst	#13,d5	;modes PC relatif autorises
	beq	badmode	;non alors arreter
	clr.b	usean	;remplacer An par PC
	bra	casmodext

d16pc:

	btst	#13,d5
	beq	badmode
	bsr	mettred16
	move.b	#"(",(a1)+
	move.b	#"P",(a1)+
	move.b	#"C",(a1)+
	move.b	#")",(a1)+
	rts

casadrw:
;adresse .w

	btst	#10,d5
	beq	badmode
	move	(a0)+,d7	;adresse
	tst.b	tabsymb
	beq.s	noislabw
	move.l	savepc,-(sp)
	move	d0,-(sp)
	move	d1,-(sp)
	move.l	a0,d5
	add	d7,d5
	move.l	a1,savebuffer
	move.l	d5,savepc
	move	#22,lglab
	bsr	searchlab
	move	(sp)+,d1
	move	(sp)+,d0
	move.l	(sp)+,savepc
	tst.b	d3
	beq.s	noislabw
	move.l	a5,a1
	cmp.b	#$20,-1(a5)
	bne.s	nosub1w
	subq.l	#1,a1

nosub1w:

	rts

noislabw:

	ext.l	d7
	bsr	transhexa
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	rts

casadrl:
;adresse .l

	btst	#11,d5
	beq	badmode
	move.l	(a0)+,d7	;adresse
	tst.b	tabsymb
	beq.s	noislab
	move.l	savepc,-(sp)
	move	d0,-(sp)
	move	d1,-(sp)
	move.l	a1,savebuffer
	move.l	d7,d5
	move.l	d7,savepc
	move	#22,lglab
	bsr	searchlab
	move	(sp)+,d1
	move	(sp)+,d0
	move.l	(sp)+,savepc
	tst.b	d3
	beq.s	noislab
	move.l	a5,a1
	cmp.b	#$20,-1(a5)
	bne.s	nosub1
	subq.l	#1,a1

nosub1:

	rts

noislab:

	bsr	transhexa
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	rts

casdonnee:
;avec donn‚e

	btst	#12,d5
	beq	badmode
	move.b	#"#",(a1)+
	move.b	taille,d7
	beq.s	set8bits
	cmp.b	#1,d7
	beq.s	set16bits
	cmp.b	#2,d7
	bne	badmode
	move.l	(a0)+,d7
	bra.s	dotr

set16bits:

	moveq	#0,d7
	move	(a0)+,d7
	bra.s	dotr

set8bits:

	moveq	#0,d7
	move	(a0)+,d7
	andi	#$ff,d7
	cmp.b	#"z",d7
	bhi.s	dotr
	cmp.b	#"a",d7
	bhs.s	docar

nocaraz:

	cmp.b	#"Z",d7
	bhi.s	dotr
	cmp.b	#"A",d7
	blo.s	dotr

docar:

	move.b	#$22,(a1)+
	move.b	d7,(a1)+
	move.b	#$22,(a1)+
	rts

dotr:

	bra	transhexa

mDn:
;cas Dn

	btst	#0,d5
	beq	badmode
	move.b	#"D",(a1)+
	move.b	d4,(a1)+
	rts

mmoinsAn:
;cas -(An)

	btst	#4,d5
	beq	badmode
	move.b	#"-",(a1)+
	bra	setan

mAn:
;cas An

	btst	#1,d5
	beq	badmode
	move.b	#"A",(a1)+
	move.b	d4,(a1)+
	rts

casmodext:
;mode d'adressage utilis‚:
;(d8,An,Xn*i)--> d8(An,Xn*i)
;(bd,An,Xn*i)
;([bd,An,Xn*i],od)
;([bd,An],Xn*i,od)
;cas particulier bd(An,Xn) avec bit 8 … zero

	btst	#6,d5	;mode etendu autorise
	beq	badmode	;non
	move	(a0)+,d1
	btst	#8,d1
	bne	cas2i
;
;cas mode (d8,An,Xn*i)
;
;     -------------------------------------------------------
;     |D/A| Registre|W/L| F/E  | 0 |    D‚placement 8 bits  |
;     -------------------------------------------------------
;       15  14 13 12 11  10  9   8   7  6  5  4  3  2  1  0
;
; D/A =0 registre de donn‚es et 1 pour registre d'adresse
; Registre= numero de registre d'index
; W/L =0 index 16 bits ou 1 pour index 32 bits
; F/E =0,1,2,3 pour *1,*2,*4,*8 registre d'index

	move.b	#"(",(a1)+
	move	d1,d7
	andi	#$ff,d7
	btst	#7,d7
	beq.s	casposa
	neg	d7
	andi	#$ff,d7
	move.b	#"-",(a1)+

casposa:

	ext.l	d7
	bsr	transhexa
	move.b	#".",(a1)+
	move.b	#"B",(a1)+
	move.b	#",",(a1)+
	move	d0,d3
	andi	#%111111,d3
	cmp	#%111011,d3
	bne.s	nozpc
	move.b	#"P",(a1)+
	move.b	#"C",(a1)+
	bra.s	joie

nozpc:

	bsr	setrega3

joie:

	bsr.s	makeADxip
	move.b	#")",(a1)+
	rts

makeADnmi:
;remplir suite avec An puis An ou Dn .L ou .W * index 1,2,4 ou 8

	bsr.s	rempAn

makeADxi:
;mettre ","+ index An ou Dn puis "*" index

	btst	#6,d1
	bne.s	nomult

makeADxip:

	move.b	#",",(a1)+
	move.b	#"D",d4	;registre index donnee
	btst	#15,d1
	beq.s	regdedon
	move.b	#"A",d4	;registre index adresse

regdedon:

	move.b	d4,(a1)+
	move	d1,d4
	andi	#%111000000000000,d4	;numero registre
	rol	#4,d4
	addi.b	#"0",d4
	move.b	d4,(a1)+
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	btst	#11,d1
	bne.s	cas32bit
	subq.l	#2,a1

cas32bit:

	move	d1,d3
	andi	#%11000000000,d3	;facteur multiplicatif
	beq.s	nomult
	move.b	#"*",(a1)+
	cmp	#%1000000000,d3
	bne.s	nomul2
	move.b	#"2",(a1)+
	rts

nomul2:

	cmp	#%10000000000,d3
	bne.s	nomul4
	move.b	#"4",(a1)+
	rts

nomul4:

	move.b	#"8",(a1)+

nomult:

	rts

rempAn:

	tst.b	usean
	bne	setrega3
	move.b	#"P",(a1)+
	move.b	#"C",(a1)+
	rts

cas2i:

	move	d1,d4
	andi	#%111001111,d4
	cmp	#%100000000,d4
	beq	cas22

;adresse type
;([bd,An,Xn*i],od)
;      ou
;([bd,An],Xn*i,od)
;      ou
;meme chose sans les [] si ISEL=0 (--> sans indiredtion)
;ajoute 1 mode a chaque fois

	move	d1,d3
	andi	#%111,d3
	move.b	#"(",(a1)+
	move	d1,d4
	andi	#%1111,d4	;format indirection memoire
	move	d3,-(sp)
	tst	d3
	beq.s	noind
	move.b	#"[",(a1)+

noind:

	btst	#6,d1	;tester IS
	beq	casprepost

;adressage avec indirection memoire simple
;sans pre ou post indexage
;([bd,An],od) sans index Xn*i
;ou sans indirection si d3=0--> (bd,An)

	bsr	makebdAn2
	move	(sp)+,d3
	tst	d3	;pas d'indirection?
	beq.s	mettreod	;oui alors ne pas mettre ]
	move.b	#"]",(a1)+

mettreod:

	move	d1,d4
	andi	#%11,d4	;taille od
	tst	d4
	bne.s	metod
	tst	d3
	bne	badmode
	move.b	#")",(a1)+
	rts

metod:

	cmp	#%1,d4
	beq.s	odnul
	move.b	#",",(a1)+
	cmp	#%10,d4
	bne.s	nood16
	clr.b	d6
	move	(a0)+,d7
	ext.l	d7
	btst	#15,d7
	beq.s	contod
	neg.l	d7
	andi	#$ffff,d7
	clr.b	d6
	bra.s	contodp

nood16:

	cmp	#%11,d4
	bne	badmode
	move.b	#1,d6
	move.l	(a0)+,d7
	btst	#31,d7
	beq.s	contod
	neg.l	d7

contodp:

	move.b	#"-",(a1)+

contod:

	bsr	transhexa
	bsr.s	setpointwl

odnul:

	move.b	#")",(a1)+
	rts

setpointwl:

	move.b	#".",(a1)+
	move.b	#"L",(a1)
	tst.b	d6
	bne.s	cas32bod
	subq.l	#2,a1

cas32bod:

	addq.l	#1,a1
	rts

casprepost:
;cas ou Xn existe (IS=0)
;choix entre postindex et preindex
;suivant valeur de isel

	move	d1,d4
	andi	#%111,d4
	cmp	#%100,d4
	beq	badmode
	cmp	#%101,d4
	beq.s	caspost
	cmp	#%110,d4
	beq.s	caspost
	cmp	#%111,d4
	beq.s	caspost
;cas preindex‚
;mettre bd,An comme mode precedent
	bsr.s	makebdAn2
	bsr	makeADxi
	move	(sp)+,d3
	tst	d3
	beq.s	nometb
	move.b	#"]",(a1)+

nometb:

	bra	mettreod

caspost:

	bsr.s	makebdAn2
	move	(sp)+,d3
	move.b	#"]",(a1)+
	bsr	makeADxi
	bra	mettreod

cas22:
;
;cas mode (bd,An,Xn*i)
;
;     -------------------------------------------------------
;     |D/A| Registre|W/L| F/E  | 1  0  0 |B-DEP| 0  0  0  0 |
;     -------------------------------------------------------
;       15  14 13 12 11  10  9   8  7  6  5  4   3  2  1  0
;                              +
;     -------------------------------------------------------
;     |               deplacement 16 bits                   |
;     -------------------------------------------------------
;     |               deplacement 32 bits                   |
;     -------------------------------------------------------
;
; D/A =0 registre de donn‚es et 1 pour registre d'adresse
; Registre= numero de registre d'index
; W/L =0 index 16 bits ou 1 pour index 32 bits
; F/E =0,1,2,3 pour *1,*2,*4,*8 registre d'index
; B-DEP =0,1,2,3 pour reserve,deplacement nul,deplacement 16 et 32 bits

	move.b	#"(",(a1)+
	bsr.s	makebdAn	;inserer bd et An
	bsr	makeADxi
	move.b	#")",(a1)+
	rts

makebdAn2:
;remplir bd,An avec possibilite An =ZAn (0)

	bsr.s	makebd

rempAn2:
;mettre An ou ZAn

	btst	#7,d1
	beq.s	nozan
	move.b	#"Z",(a1)+

nozan:

	bra	rempAn

makebdAn:
;remplir bd,An

	bsr.s	makebd
	bra	rempAn	;mettre An

makebd:

	move	d1,d4
	andi	#%110000,d4
	tst	d4
	beq	badmode
	cmp	#%10000,d4
	bne.s	nodepnul
	rts

nodepnul:

	cmp	#%100000,d4
	bne.s	nodep16
	clr.b	d6
	moveq	#0,d7
	move	(a0)+,d7
	btst	#15,d7
	beq.s	dotrans
	neg	d7
	move.b	#"-",(a1)+
	bra.s	dotrans

nodep16:
;deplacement 32 bits
	move.l	(a0)+,d7
	move.b	#1,d6
	btst	#31,d7
	beq.s	dotrans
	neg.l	d7

dotransp:

	move.b	#"-",(a1)+

dotrans:

	bsr	transhexa
	bsr	setpointwl
	move.b	#",",(a1)+

*nopointl:

	rts

mpAnp:
;cas (An)

	btst	#2,d5
	beq.s	badmode

setan:

	move.b	#"(",(a1)+
	move.b	#"A",(a1)+
	move.b	d4,(a1)+
	move.b	#")",(a1)+
	rts

mAnplus:
;cas (An)+

	btst	#3,d5
	beq.s	badmode
	bsr.s	setan
	move.b	#"+",(a1)+
	rts

md16An:
;cas d16(An)

	bsr.s	mettred16
	bra.s	setan

mettred16:

	move	(a0)+,d7	;deplacement 16 bits
	btst	#5,d5	;mode autoris‚?
	beq.s	badmode	;non
	btst	#15,d7
	beq.s	caspos
	neg	d7
	move.b	#"-",(a1)+

caspos:

	ext.l	d7
	bra	transhexa	;deplacement 16 bits

badmode:

	clr	getsaut
	tst.b	outmemory
	bne.s	dehors
	lea	texte,a1
	move.l	savepc,a5
	move.b	#"D",(a1)+
	move.b	#"C",(a1)+
	move.b	#".",(a1)+
	move.b	#"W",(a1)+
	move.b	#" ",(a1)+
	moveq	#0,d7
	move	(a5)+,d7
	bsr	transhexa3
	move.l	a5,a0
	move.b	#1,bad

hordela:

	move.l	adrretour,a6
	jmp	(a6)

dehors:

	move.b	#"V",(a1)+
	move.b	#"I",(a1)+
	move.b	#"D",(a1)+
	move.b	#"E",(a1)+
	bra.s	hordela

cas71:
;cas bits 15,14,13,12 et 7 … 1 pour:
;CPBCC

	btst	#8,d0
	bne.s	badmode
	lea	2(a6),a5
	move	d0,d1
	andi	#%111000000000,d1;CP-ID=0?
	beq.s	badmode	;oui alors mettre dc $aabb
	btst	#8,d0
	bne.s	badmode
;instruction valide
	cmp	#%1000000000,d1	;copro 1?
	bne.s	badmode	;non alors rien
	move.b	#"F",(a1)+
	move.b	#"B",(a1)+
	move	d0,d1
	bsr.s	condicopro
	bra.s	metladress

setcondi:

	andi	#%111111,d1
	mulu	#3,d1
	move.b	(a3,d1),(a1)+
	tst.b	1(a3,d1)
	beq.s	endcond
	move.b	1(a3,d1),(a1)+
	tst.b	2(a3,d1)
	beq.s	endcond
	move.b	2(a3,d1),(a1)+

endcond:

	rts

condicopro:
;d1=mot contenant condition copro

	bsr.s	setcondi
	btst	#6,d0
	beq.s	cas16b
	move.l	a6,a5
;cas 32 bits
	move.b	#".",(a1)+
	move.b	#"L",(a1)+
	move.b	#" ",(a1)+
	move.l	(a0)+,d0	;deplacement
	rts

cas16b:

	move.b	#" ",(a1)+
	move	(a0)+,d0	;deplacement
	ext.l	d0
	rts

metladress:

	add.l	d0,a5
	move.l	a5,d7
	bra.s	transhexa

transhexa3:

	movem.l	d1/d5-d6,-(sp)
	clr.b	premzer
	swap	d7
	moveq	#3,d6	;16 fois 4 bits
	bra.s	fois8

transhexa2:

	movem.l	d1/d5-d6,-(sp)
	clr.b	premzer
	moveq	#7,d6	;8 fois 4 bits
	bra.s	fois8

transhexa:
;d7=nombre a transcrir
;d1=buffer de transfert

	movem.l	d1/d5-d6,-(sp)
	move.b	#1,premzer
	moveq	#7,d6	;8 fois 4 bits
	move.b	#"$",(a1)+

fois8:

	moveq	#0,d1
	moveq	#3,d5

fois4:

	lsl.l	d7
	roxl.l	d1
	dbra	d5,fois4
	tst.b	premzer	;tester premier zeros
	beq.s	contnor	;non
	tst.b	d1	;premier zero
	dbne	d6,fois8	;oui alors boucle
	tst	d6	;adresse=0?
	bpl.s	contnor	;non
	addq	#1,d6	;oui alors mettre au moins zero

contnor:

	clr.b	premzer
	cmp.b	#9,d1
	bls.s	casadd0
	addi.b	#"A"-10,d1
	bra.s	nometzero
	dbra	d6,fois8
	movem.l	(sp)+,d1/d5-d6
	rts

casadd0:

	addi.b	#"0",d1

nometzero:

	move.b	d1,(a1)+
	dbra	d6,fois8
	movem.l	(sp)+,d1/d5-d6
	rts

;routine d'affichage d'une chaine termin‚ par 0
;+routine de scroll d'une partie de l'ecran vers le bas ou le haut
;de 8 pixels de hauteur
;a une position donne x
;sur un ecran 640*200 avec 2 plans
;d0=x;d1=y (0<=x<=79 et 0<=y<=24)
;a0=adresse debut fonte
;a1=adresse texte termin‚ par zero
;a6=adresse debut ecran

scrolllig:
;scroll de zone
;calcul adresse debut et fin
;deplacement de blocs de pixels
;pas d'effacement de la zone non modifiee
;d0 pos x a gauche
;d1 pos y en haut
;d2 hauteur zone
;d3 largeur zone
;d4 type scroll (haut=0;bas=1;droite=2;gauche=3)

	movem.l	d0-a7,-(sp)
	tst.b	haute	;mode 640*400 1 plan?
	beq	nohautes	;non
;oui
	mulu	#16,d1
	subq	#4,d1
	mulu	#80,d1
	lea	(a6,d1.l),a6
	lea	(a6,d0),a6
	subq	#1,d3
	bmi	outscroll
	tst.b	d4
	bne.s	scrbasht	
	lea	80*16(a6),a5	;adresse source
	move.l	a5,a4
	move	d2,d6	;hauteur
	subq	#1,d6
	bmi	outscroll
	mulu	#16,d6	;1 car=16 pixel haut
	addq	#1,d6
*	subq	#1,d6
	bmi	outscroll
	move.l	a5,a4
	move.l	a6,a3

toutlig:

	move	d3,d5	;largeur zone

;but=a6
toutlarg:

	move.b	(a5)+,(a6)+
	dbra	d5,toutlarg
	lea	80(a4),a4
	lea	80(a3),a3
	move.l	a4,a5
	move.l	a3,a6
	dbra	d6,toutlig
	bra	outscroll

scrbasht:

	subq	#1,d2	;hauteur zone en car
	bmi	outscroll
	move	d2,d7
	mulu	#16*80,d7
	add.l	d7,a6	;adresse source
	lea	-80(a6),a6
	lea	16*80(a6),a5	;adresse but
	mulu	#16,d2	;hauteur 1 car pixels
	subq	#1,d2

allhaut:

	move	d3,d7
	move.l	a5,a3
	move.l	a6,a4

forlarg:

	move.b	(a6)+,(a5)+
	dbra	d7,forlarg
	lea	-80(a3),a5
	lea	-80(a4),a6
	dbra	d2,allhaut
	bra.s	outscroll

nohautes:

	mulu	#8,d1
	subq	#2,d1
	tst.b	d4
	bne.s	scrollbas
	subq	#1,d2
	mulu	#8,d2
	mulu	#160,d1
	lea	(a6,d1.l),a1	;adresse y haute
	move	d0,d6
	bclr	#0,d6
	mulu	#2,d6
	add.l	d6,a1
	btst	#0,d0
	beq.s	noadd1a
	addq.l	#1,a1	;adresse haut gauche

noadd1a:

	lea	160*8(a1),a0	;adresse 2

scrollhaut:
;adresse 2=adresse source
;adresse 1=adresse but
;scroll en 3 partie
;1ere partie: zone … gauche qui peut etre de 1 caractere si impaire
;2eme partie: des .L par pas de 2 caracteres
;3eme partie: zone a droite qui peut ne contenir q'un caractere (paire cette fois)
;d5=scroll haut si 160 ou bas si -160

	move	#160,d5

entscroll:

	cmp	#1,d3
	beq.s	larg1car
	cmp	#2,d3
	beq.s	larg2car
;cas 3 et plus
;diviser en parties
;pour une largeur de 3 faire ainsi
;diviser en 2 avec 1+2 ou 2+1 (colonnes)
;pour une largeur de 4
;diviser en 2 ou 4 parties avec 2+2 ou 1+2+1 (colonnes)
;pour plus suivre le meme principe

	btst	#0,d0
	beq.s	casdeb2
;cas premier colonne impaire (traiter en 8 bits)
	bsr	scroll8bits
	subq	#1,d3
	addq	#1,d0
	bra.s	entscroll

casdeb2:

	bsr.s	scroll16bits
	subq	#2,d3
	addq	#2,d0
	bra.s	entscroll

larg2car:
;largeur de 2 caracteres
;soit traiter en .l si d0 paire
;soit traiter comme 2 car 8 bits

	btst	#0,d0
	beq.s	deuxderp
;tombe sur impaire->2 fois scroll 8 bits
	bsr.s	scroll8bits
	addq	#1,d0
	bsr.s	scroll8bits
	bra.s	outscroll

deuxderp:
;cas deux derniere colonnes paires

	bsr.s	scroll16bits
	bra.s	outscroll

larg1car:
;1car de large d'ou scroller sur 8 bits soit a gauche ou a droite

	bsr.s	scroll8bits

outscroll:

	movem.l	(sp)+,d0-a7
	rts

scrollbas:

	move	d2,d6
	subq	#1,d2
	mulu	#8,d2
	move	#-160,d5
	subq	#1,d6
	mulu	#8*160,d6
	lea	(a6,d6.l),a0	;adresse source
	move	d1,d6
	mulu	#160,d6
	sub.l	#160,d6
	add.l	d6,a0
	move	d0,d6
	bclr	#0,d6
	mulu	#2,d6
	add.l	d6,a0
	btst	#0,d0
	beq.s	noadda
	addq.l	#1,a0	;adresse haut gauche

noadda:

	lea	8*160(a0),a1
	bra.s	entscroll


scroll16bits:

	move	d2,d7
	subq	#1,d7
	move.l	a0,a4
	move.l	a1,a5

toutligs16:

	move.l	(a4),(a5)
	lea	(a4,d5),a4
	lea	(a5,d5),a5
	dbra	d7,toutligs16
	addq.l	#4,a0
	addq.l	#4,a1
	rts

scroll8bits:

	move	d2,d7
	subq	#1,d7
	move.l	a0,a4
	move.l	a1,a5

toutligs:

	move.b	(a4),(a5)
	move.b	2(a4),2(a5)
	lea	(a4,d5),a4
	lea	(a5,d5),a5
	dbra	d7,toutligs
	addq.l	#1,a0
	addq.l	#1,a1
	btst	#0,d0
	beq.s	only1
	addq.l	#2,a0
	addq.l	#2,a1

only1:

	rts

afflalig:
;a6 adresse debut ecran
;a1 adresse debut texte termin‚ par zero
;d0 position x (en caractere)
;d1 position y (en points)

	movem.l	d0-a6,-(sp)
	cmp	#24*8-4,d1
	bne.s	novidelig
	bsr	videlalig

novidelig:

	bsr	doafflig
	movem.l	(sp)+,d0-a6
	rts

doafflig:

	movem.l	d0-a6,-(sp)
	cmp	#25*8,d1
	bhs	endlig
	cmp	#80,d0
	bhs	endlig
	lea	fonte,a0
	mulu	#160,d1
	add.l	d1,a6	;pos debut ligne y
	tst.b	haute
	beq.s	nohht
	move	d0,d2
	ext.l	d2
	add.l	d2,a6
	bra.s	noadd1

nohht:

	move	d0,d2
	bclr	#0,d2
	mulu	#2,d2
	add.l	d2,a6	;adresse debut ligne
	btst	#0,d0
	beq.s	noadd1
	addq.l	#1,a6

noadd1:

	moveq	#0,d3
	move.b	(a1)+,d3	;caractere
	beq.s	endlig
	move	d3,d4
	mulu	#8,d4
	lea	(a0,d4.l),a3	;adresse dans fonte
	moveq	#7,d4
	move.l	a6,a5

all8lig:

	move.b	(a3)+,d5
	tst.b	haute
	beq.s	nohaute
*	clr.b	(a5)
*	clr.b	160(a5)
	move.b	d5,(a5)
	move.b	d5,80(a5)
	lea	160(a5),a5
	bra.s	afterb

nohaute:

	move.b	#$ff,2(a5)	;2eme plan
	move.b	d5,(a5)
*	or.b	d5,2(a5)
	lea	160(a5),a5

afterb:

	dbra	d4,all8lig
	addq.l	#1,a6
	tst.b	haute
	bne.s	onlyadd1
	btst	#0,d0
	beq.s	onlyadd1
	addq.l	#2,a6

onlyadd1:

	addq	#1,d0
	cmp	#80,d0
	bhs.s	endlig
	bra.s	noadd1

endlig:

	movem.l	(sp)+,d0-a6
	rts

malloc:

	move.l	d1,-(sp)
	move	#$48,-(sp)
	trap	#1
	addq.l	#6,sp
	rts

toutcadres:

	movem.l	d0-a7,-(sp)
	move.l	adrecran,a0
	move.l	#$ffff,d6
	tst.b	haute
	beq.s	liasse1
	moveq	#0,d6

liasse1:

	move	#32000/4-1,d7

mettreecr3:

	move.l	d6,(a0)+
	dbra	d7,mettreecr3

	moveq	#1,d4
	moveq	#0,d0	;x deb
	moveq	#0*8,d1	;y deb
	move.l	#78,d2	;largeur cadre
	move.l	#23*8,d3	;hauteur cadre
	move.l	adrecran,a6
	bsr	makecadre
	bsr.s	makepet
	movem.l	(sp)+,d0-a7
	rts

makepet:

	moveq	#1,d4
	moveq	#0,d0	;x deb
	move.l	#23*8-2,d1	;y deb
	moveq	#78,d2	;largeur cadre
	moveq	#2*8,d3	;hauteur cadre
	move.l	adrecran,a6
	bsr	makecadre
	rts

metcadres:
;cadre autour instructions
;appel fonction makecadre

	movem.l	d0-a7,-(sp)
	move.l	adrecran,a0
	move.l	#$ffff,d6
	tst.b	haute
	beq.s	liasse
	moveq	#0,d6

liasse:

	move	#32000/4-1,d7

mettreecr:

	move.l	d6,(a0)+
	dbra	d7,mettreecr

	moveq	#1,d4
	moveq	#0,d0	;x deb
	move.l	#0*8,d1	;y deb
	moveq	#44,d2	;largeur cadre
	moveq	#15*8,d3	;hauteur cadre
	move.l	adrecran,a6
	bsr	makecadre
	moveq	#1,d4
	moveq	#0,d0	;x deb
	move.l	#15*8,d1	;y deb
	moveq	#44,d2	;largeur cadre
	moveq	#8*8,d3	;hauteur cadre
	move.l	adrecran,a6
	bsr	makecadre
	bsr.s	makepet
	moveq	#1,d4
	moveq	#46,d0	;x deb
	moveq	#0,d1	;y deb
	moveq	#32,d2	;largeur cadre
	move.l	#23*8,d3	;hauteur cadre
	move.l	adrecran,a6
	bsr.s	makecadre

	move.l	adrecran,d0
	move.b	d0,$ffff820d.w
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.l	#8,d0
	move.b	d0,$ffff8201.w

	bsr	afffenregs
	bsr	getmemory

	move.l	dfenster,a0
*	moveq	#NBLIG-1,d7	;lire 11 lignes
	move	#1,posdeby	;position debut y
	clr	premadr
	bsr	bcdesa	;afficher instructions
	movem.l	(sp)+,d0-a7
	rts

makecadre:
;dessine un cadre
;d0 pos x debut en caracteres (en haut … gauche) paire
;d1 pos y debut en caracteres (en haut … gauche)
;d2 largeur en caractere paire
;d3 hauteur en caractere*8
;a6=adresse debut ecran

	movem.l	d0-a6,-(sp)
	tst.b	haute
	beq.s	nohautec
	movem.l	(sp)+,d0-a6
	rts

nohautec:

	move	d1,d5
	mulu	#160,d5
	move	d3,d7
	subq	#7,d7
	move	d0,d6
	mulu	#2,d6
	add.l	d5,d6
	lea	(a6,d6.l),a1
	move	d2,d6
	mulu	#2,d6
	lea	(a1,d6.l),a2
	lea	160*4(a1),a1
	lea	160*4(a2),a2
	movem.l	a1/a2,-(sp)
	or	#$0FFF,(a1)
	or	#$0FFF,2(a1)
	or	#$FFF0,(a2)
	or	#$FFF0,2(a2)
	cmp.b	#1,d4
	beq.s	cas1seul
	or	#$0FFF,160(a1)
	or	#$0FFF,162(a1)
	or	#$FFF0,160(a2)
	or	#$FFF0,162(a2)
	lea	160(a1),a1
	lea	160(a2),a2

cas1seul:

	lea	160(a1),a1
	lea	160(a2),a2
	cmp.b	#1,d4
	beq.s	ligvgaudroite
	subq	#2,d7

ligvgaudrd:

	or	#%0000110000000000,(a1)
	or	#%0000110000000000,2(a1)
	or	#%0000000000110000,(a2)
	or	#%0000000000110000,2(a2)
	lea	160(a1),a1
	lea	160(a2),a2
	dbra	d7,ligvgaudrd
	or	#$0FFF,(a1)
	or	#$0FFF,2(a1)
	or	#$0FFF,160(a1)
	or	#$0FFF,162(a1)
	or	#$FFF0,(a2)
	or	#$FFF0,2(a2)
	or	#$FFF0,160(a2)
	or	#$FFF0,162(a2)
	bra.s	lighor

ligvgaudroite:

	or	#%0000100000000000,(a1)
	or	#%0000100000000000,2(a1)
	or	#%0000000000010000,(a2)
	or	#%0000000000010000,2(a2)
	lea	160(a1),a1
	lea	160(a2),a2
	dbra	d7,ligvgaudroite
	or	#$0FFF,(a1)
	or	#$0FFF,2(a1)
	or	#$FFF0,(a2)
	or	#$FFF0,2(a2)

lighor:

	move	d2,d7
	lsr	d7
	subq	#2,d7
	movem.l	(sp)+,a1/a2
	addq.l	#4,a1
	move	d3,d6
	subq	#6,d6
	mulu	#160,d6
	lea	(a1,d6.l),a2
	lea	160(a2),a2
	cmp.b	#1,d4
	beq.s	lighbashaut
	lea	-160(a2),a2

lighbhd:

	or	#$ffff,(a1)+
	or	#$ffff,(a1)+
	or	#$ffff,160-4(a1)
	or	#$ffff,160-2(a1)
	or	#$ffff,(a2)+
	or	#$ffff,(a2)+
	or	#$ffff,160-4(a2)
	or	#$ffff,160-2(a2)
	dbra	d7,lighbhd
	bra.s	sortir

lighbashaut:

*	clr	160(a1)
*	clr	160+2(a1)
	or	#$ffff,(a1)+
	or	#$ffff,(a1)+
*	clr	-160(a2)
*	clr	-160+2(a2)
	or	#$ffff,(a2)+
	or	#$ffff,(a2)+
	dbra	d7,lighbashaut

sortir:

	movem.l	(sp)+,d0-a6
	rts
	DATA
	even
messhelp:	
	dc.b	" CTRL+C - sortir du programme",0
	dc.b	" L      - charger un programme ex‚cutable",0
	dc.b	" ALT+S  - sauver une partie de la m‚moire nom fichier, adr d‚but, adr fin",0
	dc.b	" T      - tracer une instruction",0
	dc.b	" Y      - tracer et rentrer dans les sous-programmes",0
	dc.b	" F      - changer la fr‚quence de balayage 50/60 Hz (Non disponible en VGA)",0
	dc.b	" J      - ex‚cuter jusqu'… une adresse",0
	dc.b	" A      - changer adresse d‚but fenˆtre instructions",0
	dc.b	" CTRL+A - changer adresse d‚but fenˆtre m‚moire",0
	dc.b	" R      - lancer le programme",0
	dc.b	" S      - sauter instruction si PC=adresse d‚but fenˆtre instruction",0
	dc.b	"        - se mettre … l'adresse d‚but fenˆtre instruction sinon",0
	dc.b	" C      - chercher",0
	dc.b	" V      - visualiser ecran physique/ecran logique",0
	dc.b	" Une adresse peut ˆtre donn‚e sous forme de label",0
	dc.b	" W1= adresse d‚but fenˆtre instructions, W2 adresse fenˆtre m‚moire",0
	dc.b	-1
	even
lglabi:	dc	8	;longueur label

listeadr:

	dc.l	$0,$4,$8,$c,$10,$14,$18,$1c
	dc.l	$400,$404,$408,$40c,$410,$414,$418,$41c
	dc.l	$420,$42e,$440,$444,$448,$44c,$44e,$45e
	dc.l	$484,$4c2,$4f2
	
	dc.l	$20,$24,$28,$2C
	dc.l	$64,$68,$6C,$70,$74,$78,$7C

	dc.l	$84,$b4,$b8

	dc.l	$118

listaille:

	dc.b	1,1,1,1,1,1,1,1
	dc.b	1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,0,1,1

	dc.b	1,1,1,1
	dc.b	1,1,1,1,1,1,1

	dc.b	1,1,1

	dc.b	1

	even

listpoint:	dc	42
	dc.l	reset_pile,pc_reset,bus_error
	dc.l	adresse_error,ins_illegal
	dc.l	zero_divise,chk_inst
	dc.l	trapv_inst
	dc.l	etv_timer,etv_critic,etv_term,etv_xtra
	dc.l	etv_xtra4,etv_xtra8,etv_xtra12,etv_xtra16
	dc.l	memvalid,phystop,seekrate,_fverify
	dc.l	palmode,sshiftmd,v_bas_ad,screenpt,conterm,_drvbits
	dc.l	_sysbase

	dc.l	violprivi
	dc.l	tracevec
	dc.l	emulA
	dc.l	emulF

	dc.l	inter1
	dc.l	inter2
	dc.l	inter3
	dc.l	inter4
	dc.l	inter5
	dc.l	inter6
	dc.l	inter7

	dc.l	vctrap1
	dc.l	vctrap13
	dc.l	vctrap14
	
	dc.l	vectclavier

vectclavier:	dc.b	"V Vecteur clavier",0

vctrap1:	dc.b	"V Vecteur trap #1 (GEMDOS)",0
vctrap13:	dc.b	"V Vecteur trap #13 (BIOS)",0
vctrap14:	dc.b	"V Vecteur trap #14 (eXtended BIOS)",0

inter1:	dc.b	"V Interruption niveau 1",0
inter2:	dc.b	"V Interruption niveau 2",0
inter3:	dc.b	"V Interruption niveau 3",0
inter4:	dc.b	"V Interruption niveau 4",0
inter5:	dc.b	"V Interruption niveau 5",0
inter6:	dc.b	"V Interruption niveau 6",0
inter7:	dc.b	"V Interruption niveau 7",0

emulA	dc.b	"V Emulateur line A",0
emulF:	dc.b	"V Emulateur line F",0
tracevec:	dc.b	"V Vecteur trace",0
violprivi:	dc.b	"V Violation de privil‚ge",0

reset_pile:	dc.b	"L Pile sur RESET",0
pc_reset:	dc.b	"L PC sur RESET",0
bus_error:	dc.b	"V Erreur de bus",0
adresse_error:	dc.b	"V Erreur d'adresse",0
ins_illegal:	dc.b	"V Instruction ill‚gale",0
zero_divise:	dc.b	"V Division par z‚ro",0
chk_inst:	dc.b	"V Instruction CHK",0
trapv_inst:	dc.b	"V Instruction TRAPV",0
etv_timer:	dc.b	"V Evnt Timer GEM",0
etv_critic:	dc.b	"V Erreur disque",0
etv_term:	dc.b	"V Routine fin GEMDOS",0
etv_xtra:	dc.b	"V Vecteur 1 libre",0
etv_xtra4:	dc.b	"V Vecteur 2 libre",0
etv_xtra8:	dc.b	"V Vecteur 3 libre",0
etv_xtra12:	dc.b	"V Vecteur 4 libre",0
etv_xtra16:	dc.b	"V Vecteur 5 libre",0
memvalid:	dc.b	"L=$752019F3 pour validation m‚moire",0
phystop:	dc.b	"A Limite physique RAM",0
seekrate:	dc.b	"W seek rate disquette",0
_fverify:	dc.b	"W V‚rification ‚criture disquette si #0",0
palmode:	dc.b	"W Mode 50 (PAL) ou 60 (NTSC) Hz (0->NTSC)",0
sshiftmd:	dc.b	"B R‚solution ‚cran (0=basse,1=moy,2=haute sur ST)",0
v_bas_ad:	dc.b	"L Adresse logique Vid‚o",0
screenpt:	dc.b	"L Adresse Vid‚o … mettre au prochain VBL",0
conterm:	dc.b	"B Attributs console (bit 0=clic clavier/1=r‚p‚tition)",0
_drvbits:	dc.b	"L Lecteurs disques connect‚s",0
_sysbase:	dc.b	"P Systeme d'exploitation",0

fonte:	incbin	"c:\atari_8.fnt"
	even

moyenne60:	dc	0,0,$3e,$32,9,$23f,$1c,$34,0,0
	dc	$20d,$201,$16,$4d,$1dd,$207,$81,4,$50
	dc.b	0,0,1

	even

moyenne50:	dc	0,0,$3e,$32,9,$23f,$1c,$34,0,0
	dc	$271,$265,$2f,$6f,$1ff,$26b,$81,4,$50
	dc.b	0,2,1
	even
videligne:

	dc.b	"          "
	dc.b	"          "
	dc.b	"          "
	dc.b	"          "
	dc.b	"          "
	dc.b	"          "
	dc.b	"          "
	dc.b	"        "
	dc.b	0

condition:

	dc.b	"TR","RA","HI","LS","CC","CS","NE"
	dc.b	"EQ","VC","VS","PL","MI","GE","LT"
	dc.b	"GT","LE"

ccondition:

	dc.b	"F",0,0,"EQ",0,"OGT","OGE","OLT","OLE","OGL"
	dc.b	"OR",0,"UN",0,"UEQ","UGT","UGE","ULT","ULE"
	dc.b	"NE",0,"T",0,0,"SF",0,"SEQ","GT",0,"GE",0,"LT",0
	dc.b	"LE",0,"GL",0,"GLE","NGL","NGL","NLE","NLT","NGE"
	dc.b	"NGT","SNE","ST",0

	even

finprogramme:	dc.b	"Fin du programme...",0
ligcharger:	dc.b	"Charger un programme : ",127,0
ligsauver:	dc.b	"Sauver [nom,d‚but,fin] : ",127,0
erropentxt:	dc.b	"Impossible d'ouvrir le fichier !!!",0
eroliretxt:	dc.b	"Impossible de charger le fichier !!!",0

breaktxt:	dc.b	"",0
breaktxtout:	dc.b	" ",0
pcmark:	dc.b	"",0
busertxtc:	dc.b	"Err. bus C.",0
busertxtld:	dc.b	"Err. bus Lo/D",0
busertxtlc:	dc.b	"Err. bus Lo/C",0
busertxtlb:	dc.b	"Err. bus Lo/B",0
adrertxt:	dc.b	"Err. adresse",0
divzertxt:	dc.b	"Division par z‚ro",0
illegtxt:	dc.b	"Instruction ill‚gale",0
adrfaute:	dc.b	"Adresse: "
adrfaltxt:	dc.b	"XXXXXXXX",0
adrpctxt2:	dc.b	"Adresse PC:"
adrpctxt:	dc.b	"XXXXXXXX",0
fileinsb:	dc.b	"File B: $"
fileinsbtxt:	dc.b	"XXXX",0
fileinsc:	dc.b	"File C: $"
fileinsctxt:	dc.b	"XXXX",0
adretgbtxt:	dc.b	"Adresse B: "
adretageb:	dc.b	"XXXXXXXX",0
cyclelec:	dc.b	"-Lec",0
cyclewri:	dc.b	"-Ecr",0
cyclemod:	dc.b	"-L_m_e",0
etagebinv:	dc.b	"Etage B inval.",0
etagecinv:	dc.b	"Etage C inval.",0
	even
*newadrecr:	incbin	d:\base.pi2
*deuxmem:	incbin	d:\base2.dat
chaine:	dc.b	0,0,$d,$a,0

	BSS

	even

moy50	ds.b	41
	even
moy60	ds.b	41
	even
juskval	ds	1	;ancien mot
juskbreak	ds.l	1	;breakpoint runner jusqu'a
valofregs	ds	4*8
tailleres	ds.l	1
debres	ds.l	1
newpc	ds.l	1
ancimp	ds.l	1
adrsave	ds.l	1
savememfen	ds	28
adrdebmem	ds.l	1
lglab	ds	1
debutoflig	ds.l	1
save2prem	ds.l	1
save2der	ds.l	1
save2premb	ds.l	1
save2derb	ds.l	1
savepal16	ds.l	16/2
savepal256	ds.l	256/2
moyenne	ds.l	1
outmetbreak	ds.l	1
libbreakadr	ds.l	1	;reg utilise pour ALT+R
libbreakins	ds.l	1	;meme chose
savesrcmp	ds	1	;sert pour l'affichage de SR
savesr2	ds	1
savesr	ds	1	;dans la fenetre des registres
anctrap1	ds.l	1	;ancien trap #1
anctrap2	ds.l	1	;'       '   #2
anctrap13	ds.l	1	;'       '   #13
anctrap14	ds.l	1	;'       '   #14
system	ds.l	1
debutram	ds.l	1
limiteram2	ds.l	1
limiteram	ds.l	1
ancbuser	ds.l	1
ancadrer	ds.l	1
pilerte	ds.l	1
ancdivzero	ds.l	1
ancillegal	ds.l	1
ancvbl	ds.l	1
anctrace	ds.l	1
retclav	ds.l	1
timer	ds	1
savecacr	ds	1
savebsrret	ds.l	1
savret	ds	1
saveil	ds	1
valpile	ds.l	1	;pile utilisateur
valisp	ds.l	1	;pile interruption
valmsp	ds.l	1	;pile master
valpile2	ds.l	1	;pile utilisateur
valisp2	ds.l	1	;pile interruption
valmsp2	ds.l	1	;pile master
saveregv	ds.l	1
regdonnee	ds.l	8
regdonnee2	ds.l	8
regadresse	ds.l	8
regadresse2	ds.l	8
adrpcprg	ds.l	1
tttext	ds	1
ttdata	ds	1
ttbss	ds	1
nbtext	ds	1	;nbre de symboles dans text-1
nbdata	ds	1	;nbre de symboles dans data-1
nbbss	ds	1	;nbre de symboles dans bss-1
shandle	ds	1
taillesymbs	ds.l	1	;taille table des symboles
nbsymboles	ds	1	;nbre max de symboles differents
adrdebut	ds.l	1	;adresse debut programme
adrfin	ds.l	1
envp	ds.b	2
cmdl	ds.b	2
tableoff	ds.l	1
adrsymboles	ds.l	1
adrswap	ds.l	1
savecompt	ds	1
posdeby	ds	1	;1ere valeur y affichage ligne
adrdata0	ds.l	1	;adresse debut zone data dans programme
adrbss0	ds.l	1	;meme chose pour zone BSS
adrtext	ds.l	1	;adresse zone text
adrdata	ds.l	1	;adresse debut zone DATA dans labels
adrbss	ds.l	1	;meme chose pour BSS
adrtexts	ds.l	1	;adresse zone text
adrdatas	ds.l	1	;adresse debut zone DATA dans labels
adrbsss	ds.l	1	;meme chose pour BSS
basepage	ds.l	1	;basepage programme prg en cours
adrecran	ds.l	1	;adresse ecran debuggueur
dfenster	ds.l	1	;adresse debut de memoire
efenster	ds.l	1	;adresse memoire fin de fenetre
savebuffer	ds.l	1
pfenster	ds.l	25	;adresse memoire de chaque ligne sauf premiere
typesaut	ds	25	;chaque ligne
slistill	ds	10	;sauvegarde instruction breakpoint
breaklist	ds.l	10	;liste des breakpoints

;pour chaque ligne correspond un code saut
;exemple si l'instruction est bsr alors code=1
;si pas d'instruction de sous routine alors code=0
;ceci est utilis‚ pour le tracer d'instruction type bsr
;un illegal est place alors pour stopper l'execution car le mode
;trace est alors enlev‚ et bien sur on sauvegarde le mot ecrase et
;l'adresse de l'illegal

pileilgal	ds.l	1	;adresse pointeur de pile illegal de bsr/trap
savetxt	ds.l	1
savepc	ds.l	1
pile	ds.l	1
savessp	ds.l	1
clrreg	ds.l	4
prem1	ds.l	1
prem2	ds.l	1
prem3	ds.l	1
adrretour	ds.l	1
saveadra0	ds.l	1
slogbase	ds.l	1
slogbase2	ds.l	1
sphysbase	ds.l	1
sphysbase2	ds.l	1
rezdeb	ds	1
getsaut	ds	1
marez	ds	1
premadr	ds	1
reprise	ds.b	1
court	ds.b	1
fcontrol	ds.b	1
nowbreak	ds.b	1
frombreak	ds.b	1	;exception trace depuis breakpoint
outmemory	ds.b	1
scanning	ds.b	1
altrun	ds.b	1
avantsr	ds.b	1
avanttrace	ds.b	1	;adresse instruction trac‚e
illegbrk	ds.b	1	;illegal de breakpoint
illegdeb	ds.b	1	;illegal de debut de prg
tracenow	ds.b	1
swaprez	ds.b	1
retbsr	ds.b	1
firstappel	ds.b	1
*stcomp	ds.b	1
*stcomps	ds.b	1
tabsymb	ds.b	1
numcour	ds.b	1
premzer	ds.b	1
usean	ds.b	1	;remplacer An par PC (si=0)
taille	ds.b	1
bad	ds.b	1
prgprog	ds.b	1
saveregn	ds.b	1
rega0ch	ds.b	1
rega1ch	ds.b	1
rega2ch	ds.b	1
rega3ch	ds.b	1
rega4ch	ds.b	1
rega5ch	ds.b	1
rega6ch	ds.b	1
rega7ch	ds.b	1
coul16	ds.b	1	;resolution en 16 couleurs
coul4	ds.b	1	;resolution en 4 couleurs
zoom	ds.b	1
contofit	ds.b	1	;flag recuperer contenu adresse calcul‚e
haute	ds.b	1	;mode haute 640*400 1 couleur
	even
entete	ds	9
hardregs	ds.b	2+18+12+4+2+1+1+1	;41 octets

	even

;FFFF... adresse des registres video du falcon
;820E.B,8210.W,820A.B,8260.B,8266...8290.W,82A2...82AC.W,82C2.W

chainech	ds.b	256
buffer	ds.b	256
	ds.l	256/4
newadr	ds.l	32000/4
texte	ds.l	25*100

	even

	ds.l	1
pilegal
	ds.l	2500
	ds.l	2500
pilesuper
	ds.l	2500
pileautre
	ds.l	2500
pileutil
	END