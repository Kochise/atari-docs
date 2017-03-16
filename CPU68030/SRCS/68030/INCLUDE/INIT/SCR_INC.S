;****************************************************************
;		Structures des donn‚es.
;****************************************************************
;----------------------------------------------------------------
;		Description du bloc de paramŠtres.
;----------------------------------------------------------------
;		Structure du bloc de paramŠtres.
scr_pb:		rsstruct
fgs:		rs.l		1 ; Flags … positionner(L).

nb:		rs.w		1 ; Nombre d'‚crans … r‚server (0=pas d'‚cran)(W).
bpp:		rs.w		1 ; Nombre de bits par plan (1,2,4,8,16,24)(W).
w:		rs.w		1 ; Largeur voulue(W).
h:		rs.w		1 ; Hauteur voulue(W).
display_w:	rs.w		1 ; .
display_h:	rs.w		1 ; .
border_x:	rs.w		1 ; .
border_y:	rs.w		1 ; .
ext_clk_frq:	rs.l		1 ; Fr‚quence de l'horloge externe(L).
pal_addr:	rs.l		1 ; Adresse de la palette … afficher(qui doit faire 256L)(L).
		rsend

;		Description des bits de scr_pb.fgs
; Flags logiciels.
scr_pb_cls_fg	equ		0 ; Effacement des ‚crans … l'initialisation.
scr_pb_lntbl_fg	equ		1 ; R‚servation et calcul d'une table de lignes.
scr_pb_pal_fg	equ		2 ; Uilisation d'une palette.
scr_pb_scroll_fg equ		3 ; Utilisation d'un scrolling.
; Flags hardwares.
scr_pb_extclk_fg equ		16 ; Utilisation d'une horloge externe.
scr_pb_comp_fg	equ		17 ; Compatibilit‚ ST.
scr_pb_interl_fg equ		18 ; Entrelacement.
scr_pb_lndbl_fg	equ		19 ; Doublage des lignes.

;----------------------------------------------------------------
;		Structure du bloc d'information.
;----------------------------------------------------------------
scr_inf:	rsstruct
fgs:		rs.l		1 ; Copie de scr_pb.fgs(L).
pb_addr:	rs.l		1 ; Adresse du bloc de paramŠtres ‚cran actuel.

;		Donn‚es de l'‚cran.
monitor:	rs.w		1 ; Type de moniteur: 0=mono; 1=couleur; 2=VGA; 3=TV(W).
scr_nb:		rs.w		1 ; Nombre d'‚crans(W).
physic_w:	rs.w		1 ; Largeur physique de l'‚cran(W).
physic_h:	rs.w		1 ; Hauteur physique de l'‚cran(W).
virtual_w:	rs.w		1 ; Largeur virtuelle de l'‚cran(W).
virtual_h:	rs.w		1 ; Hauteur virtuelle de l'‚cran(W).
w:		rs.w		1 ; Largeur totale(W).
h:		rs.w		1 ; Hauteur totale(W).
videl_frq:	rs.l		1 ; Fr‚quence du Videl(L).
horiz_frq:	rs.l		1 ; Fr‚quence horizontale(L).
vert_frq:	rs.l		1 ; Fr‚quence verticale(L).

;		M‚moire.
scr_addr:	rs.l		1 ; Adresse de d‚but des ‚crans(L).
physic_scr_addr: rs.l		1 ; Adresse de l'‚cran physique (L).
logic_scr_addr:	rs.l		1 ; Adresse de l'‚cran logique (L).
ln_tbl_addr:	rs.l		1 ; Adresse d'une table d'offsets de lignes(L).
ln_size:	rs.l		1 ; Taille d'une ligne en octets(L).
scr_size:	rs.l		1 ; Taille de l'‚cran en octets(L).

;		Scrolling.
scroll_addr:	rs.l		1 ; Offset de l'‚cran physique sur l'‚cran virtuel(L).
scroll_x:	rs.w		1 ; Position X de l'‚cran physique sur l'‚cran virtuel(W).
scroll_y:	rs.w		1 ; Position Y(W).
scroll_xmin:	rs.w		1 ; Position X minimale(W).
scroll_xmax:	rs.w		1 ; Position X maximale(W).
scroll_ymin:	rs.w		1 ; Position Y minimale(W).
scroll_ymax:	rs.w		1 ; Position Y maximale(W).

;		Registres video hardware.
extralinew:	rs.w		1
linew:		rs.w		1 
hscroll:	rs.w		1
spshift:	rs.w		1
hht:		rs.w		1
hbb:		rs.w		1
hbe:		rs.w		1
hdb:		rs.w		1
hde:		rs.w		1
hss:		rs.w		1
hfs:		rs.w		1
hee:		rs.w		1
vft:		rs.w		1
vbb:		rs.w		1
vbe:		rs.w		1
vdb:		rs.w		1
vde:		rs.w		1
vss:		rs.w		1
rco:		rs.w		1
vco:		rs.w		1

sizeof:		rs.l		1
		rsend

;		Description des bits de scr_inf.fgs.
scr_inf_init_fg	equ		0 ; Ecran initialise.
scr_inf_set_fg	equ		1 ; Ecran positionne.
;****************************************************************


;****************************************************************
;		Video hardware.
;****************************************************************
;----------------------------------------------------------------
;		Adresses.
;----------------------------------------------------------------
vid_vbasehi	equ		$ff8201 ; Video Base Address High(B).
vid_vbasemid	equ		$ff8203 ; Video Base Address Mid(B).
vid_vbaselo	equ		$ff820d ; Video Base Address Low(B).
vid_vcounthi	equ		$ff8205 ; Video Counter Address High(B).
vid_vcountmid	equ		$ff8207 ; Video Counter Address Mid(B).
vid_vcountlo	equ		$ff8209 ; Video Counter Address Low(B).
vid_syncmode	equ		$ff820a ; Video Shifter Sync Mode(B).
vid_extralinew	equ		$ff820e ; Video Extra Line Width(W,9 bits): number of extra words per scanline.
vid_linew	equ		$ff8210 ; Video Line Width(W,10 bits): width of a physic scanline in words.
vid_st_pal	equ		$ff8240 ; ST/E Compatible Palette(16W,12 bits).
vid_shiftmode	equ		$ff8260 ; ST Video Shifter Mode(B,2 bits).
vid_hscroll	equ		$ff8264 ; Horizontal Scroll Register(B,4 bits).
vid_spshift	equ		$ff8266 ; SPSHIFT Control Register(W,11 bits).
vid_hhc		equ		$ff8280 ; Horizontal Hold Counter(W,9 bits).
vid_hht		equ		$ff8282 ; Horizontal Hold Timer(W,9 bits).
vid_hbb		equ		$ff8284 ; Horizontal Border Begin(W,9 bits).
vid_hbe		equ		$ff8286 ; Horizontal Border End(W,9 bits).
vid_hdb		equ		$ff8288 ; Horizontal Display Begin(W,10 bits).
vid_hde		equ		$ff828a ; Horizontal Display End(W,9 bits).
vid_hss		equ		$ff828c ; Horizontal Synchro Start(W,9 bits).
vid_hfs		equ		$ff828e ; Horizontal Frequency Start?(W,9 bits).
vid_hee		equ		$ff8290 ; HEE(W,9 bits).
vid_vfc		equ		$ff82a0 ; Vertical Frequency Counter(W,11 bits).
vid_vft		equ		$ff82a2 ; Vertical Frequency Timer(W,11 bits).
vid_vbb		equ		$ff82a4 ; Vertical Border Begin(W,11 bits).
vid_vbe		equ		$ff82a6 ; Vertical Border End(W,11 bits).
vid_vdb		equ		$ff82a8 ; Vertical Display Begin(W,11 bits).
vid_vde		equ		$ff82aa ; Vertical Display End(W,11 bits).
vid_vss		equ		$ff82ac ; Vertical Synchro Start(W,11 bits).
vid_rco		equ		$ff82c0 ; RCO(W,8 bits).
vid_vco		equ		$ff82c2 ; Video Control(W,4 bits).
vid_f30_pal	equ		$ff9800 ; Palette Falcon 030.

;----------------------------------------------------------------
;		Bits des registres.
;----------------------------------------------------------------
;		SPSHIFT.
vid_spshift_256	equ		4 ; Mode 256 couleurs parmi 262144.
vid_spshift_vsync equ		5 ; Utiliser le signal de synchronisation verticale externe.
vid_spshift_hsync equ		6 ; Utiliser le signal de synchronisation horizontal externe.
vid_spshift_tc16 equ		8 ; Mode True Color 16 bits.
vid_spshift_2	equ		10 ; Mode 2 couleurs parmi 262144.

;		VCO.
vid_vco_ln_dbl	equ		0 ; Active le mode double ligne.
vid_vco_interl	equ		1 ; Active le mode entrelac‚.
vid_vco_2pix	equ		2 ; Mode double pixel.
vid_vco_4pix	equ		3 ; Mode quadruple pixel.

;		RCO.
vid_rco_4pix_fg1 equ		0 ; Doit etre mis … 0 en mode quadruple pixel.
vid_rco_4pix_fg2 equ		1 ; Doit etre mis … 1 en mode quadruple pixel.
vid_rco_freq	equ		2 ; Si mis … 0, le Videl est … 32 Mhz, sinon … 25 Mhz.
vid_rco_interl	equ		3 ; En mode entrelac‚: si mis … 0, les lignes paires/impaires
;s'affichent les unes par dessus les autres. Sinon elles sont d‚cal‚es.
vid_rco_fg3	equ		4 ; Doit etre fixe … 0.
vid_rco_fg4	equ		5 ; Doit etre fixe … 0.
vid_rco_fg5	equ		6 ; Doit etre fixe … 0.
vid_rco_fg6	equ		7 ; Doit etre fixe … 1.
vid_rco_fg7	equ		8 ; Doit etre mis … 0 en mode compatible ST, sinon … 1.
;****************************************************************


;****************************************************************
;		
;****************************************************************
red		equ		2048
green		equ		32
blue		equ		1
red_shift	equ		11
green_shift	equ		5
blue_shift	equ		0

;****************************************************************
