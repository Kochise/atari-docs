;VDI.S ½ Brainstorm 1993
;This file includes all equates/structures/macros for programming the VDI.
;TAB=16
;to do:v_cellarray/vq_cellarray/escapes/bezier/fsm
	IFND	_VDI
;since our contrl[3] is a byte,we can't allocate more than 255b for intin.
SSIZE_MAX	equ	128	;max size for any VDI string (128<=SSIZE_MAX<=255)

;all the VDI macros garbage d0/a0 (some d1) and return intout[0] in d0

;  #[ Miscellaneous equates:
IP_HOLLOW	equ 0
IP_1PATT	equ 1
IP_2PATT	equ 2
IP_3PATT	equ 3
IP_4PATT	equ 4
IP_5PATT	equ 5
IP_6PATT	equ 6
IP_SOLID	equ 7

;vswr_mode equates
MD_REPLACE	equ 1
MD_TRANS	equ 2
MD_XOR	equ 3
MD_ERASE	equ 4

;styles
FIS_HOLLOW	equ 0
FIS_SOLID	equ 1
FIS_PATTERN	equ 2
FIS_HATCH	equ 3
FIS_USER	equ 4

;line types
SOLID	equ 1
LONGDASH	equ 2
DOT	equ 3
DASHDOT	equ 4
DASH	equ 5
DASH2DOT	equ 6
USERLINE	equ 7

;line ends
SQUARE	equ 0
ARROWED	equ 1
ROUND	equ 2

;vro_cpyfm equates
ALL_WHITE	equ 0
S_AND_D	equ 1
S_AND_NOTD	equ 2
S_ONLY	equ 3
NOTS_AND_D	equ 4
D_ONLY	equ 5
S_XOR_D	equ 6
S_OR_D	equ 7
NOT_SORD	equ 8
NOT_SXORD	equ 9
D_INVERT	equ 10
NOT_D	equ 11
S_OR_NOTD	equ 12
NOTS_OR_D	equ 13
NOT_SANDD	equ 14
ALL_BLACK	equ 15

;returned by vq_gdos
GDOS_NONE	equ -2	;GDOS not installed
GDOS_FSM	equ '_FSM'	;FSMGDOS installed
GDOS_FNT	equ '_FNT'	;FONTGDOS installed

;for use with vst_error
GDOS_CHARERR	equ 1	;character not found in font
GDOS_READERR	equ 8
GDOS_OPENERR	equ 9
GDOS_FILEERR	equ 10
GDOS_MEMERR	equ 11
GDOS_GENERR	equ -1
;  #] Miscellaneous equates:
;  #[ Miscellaneous structs:
MFDB	RSSTRUCT	;for vro_cpyfm & vrt_cpyfm
fd_addr	rs.l 1	;void *
fd_w	rs.w 1
fd_h	rs.w 1
fd_wdwidth	rs.w 1
fd_stand	rs.w 1
fd_nplanes	rs.w 1
fd_r1	rs.w 1
fd_r2	rs.w 1
fd_r3	rs.w 1
	RSEND

FSM_INT	RSSTRUCT
value	rs.w 1
remainder	rs.w 1	;modulo 16384
	RSEND

FSM_FPOINT_T	RSSTRUCT
x	rs.b FSM_INT.SIZEOF
y	rs.b FSM_INT.SIZEOF
	RSEND

FSM_DATA_FPOINT_T	RSSTRUCT
pt	rs.b FSM_INT.SIZEOF
cpt	rs.b FSM_INT.SIZEOF
sharp	rs.b FSM_INT.SIZEOF
	RSEND

FSM_COMPONENT_T	RSSTRUCT
reserved1	rs.w 1
nextComponent	rs.l 1	;FSM_COMPONENT_T *
numPoints	rs.b 1
numCurves	rs.b 1
numContours	rs.b 1
reserved2	rs.b 13
points	rs.l 1	;fsm_data_fpoint_t *
startPts	rs.l 1	;unsigned char *
	RSEND

;  #] Miscellaneous structs:
;  #[ Functions equates:
;Control
_v_opnwk 	equ $010b0000	;open workstation
_v_clswk 	equ $02 	;close workstation
_v_opnvwk	equ $640b0000	;open virtual screen workstation
_v_clsvwk	equ $65 	;close virtual screen workstation
_v_clrwk 	equ $03 	;clear workstation
_v_updwk 	equ $04 	;update workstation
_vst_load_fonts	equ $77010000	;load fonts
_vst_unload_fonts	equ $78010000	;unload fonts
_vs_clip 	equ $81010002	;set clipping rectangle

;Output
_v_pline 	equ $06000000	;polyline (byte 0=count(n))
_v_pmarker	equ $07000000	;polymarker (byte 0=count(n))
_v_gtext 	equ $08000001	;text (byte 2=n)
_v_fillarea	equ $09000000	;filled area (byte 0=count(n))
*_v_cellarray	equ $0a000002	;cell array (byte 2=n)
_v_contourfill	equ $67010001	;contour fill
_vr_recfl	equ $72000002	;fill rectangle
_v_bar	equ $0b000102	;bar
_v_arc	equ $0b020204	;arc
_v_circle	equ $0b000403	;circle
_v_pieslice	equ $0b020304	;pie
_v_ellarc	equ $0b020602	;elliptical arc
_v_ellpie	equ $0b020702	;elliptical pie
_v_ellipse	equ $0b000502	;ellipse
_v_rbox	equ $0b000802	;rounded rectangle
_v_rfbox 	equ $0b000902	;filled rounded rectangle
_v_justified	equ $0b020a02	;justified graphics text (byte 2=n+2)

;Attributes
_vswr_mode	equ $20010000	;set writing mode
_vs_color	equ $0e040000	;set color representation
_vsl_type	equ $0f010000	;set polyline line type
_vsl_udsty	equ $71010000	;set user-defined line style pattern
_vsl_width	equ $10000001	;set polyline line width
_vsl_color	equ $11010000	;set polyline color index
_vsl_ends	equ $6c020000	;set polyline end styles
_vsm_type	equ $12010000	;set polymarker type
_vsm_height	equ $13000001	;set polymarker height
_vsm_color	equ $14010000	;set polymarker color index
_vst_height	equ $0c000001	;set character height,absolute mode
_vst_point	equ $6b010000	;set character height,points mode
_vst_rotation	equ $0d010000	;set character baseline vector
_vst_font	equ $15010000	;set text face
_vst_color	equ $16010000	;set graphic text color index
_vst_effects	equ $6a010000	;set graphic text special effects
_vst_alignment	equ $27020000	;set graphic text alignment
_vsf_interior	equ $17010000	;set fill interior index
_vsf_style	equ $18010000	;set fill style index
_vsf_color	equ $19010000	;set fill color index
_vsf_perimeter	equ $68010000	;set fill perimeter visibility
_vsf_udpat	equ $70000000	;set user-defined fill pattern (byte 2=16*planes)

;Raster
_vro_cpyfm	equ $6d010004	;copy raster,opaque
_vrt_cpyfm	equ $79030004	;copy raster,transparent
_vr_trnfm	equ $6e000000	;transform form
_v_get_pixel	equ $69000001	;get pixel

;Input
_vsin_mode	equ $21020000	;set input mode
_vrq_locator	equ $1c000001	;input locator,request mode
_vsm_locator	equ $1c000001	;input locator,sample mode
_vrq_valuator	equ $1d010000	;input valuator,request mode
_vsm_valuator	equ $1d010000	;input valuator,sample mode
_vrq_choice	equ $1e010000	;input choice,request mode
_vsm_choice	equ $1e010000	;input choice,sample mode
_vrq_string	equ $1f020001	;input string,request mode
_vsm_string	equ $1f020001	;input string,sample mode
_vsc_form	equ $6f250000	;set mouse form
_vex_timv	equ $76 	;exchange timer interrupt vector
_v_show_c	equ $7a010000	;show cursor
_v_hide_c	equ $7b 	;hide cursor
_vq_mouse	equ $7c 	;sample mouse button state
_vex_butv	equ $7d 	;exchange button change vector
_vex_motv	equ $7e 	;exchange mouse movement vector
_vex_curv	equ $7f 	;exchange cursor change vector
_vq_key_s	equ $80000000	;sample keyboard state information

;Inquire
_vq_extnd	equ $66010000	;extended inquire function
_vq_color	equ $1a020000	;inquire color representation
_vql_attributes	equ $23 	;inquire current polyline attributes
_vqm_attributes	equ $24 	;inquire current polymarker attributes
_vqf_attributes	equ $25 	;inquire current fill area attributes
_vqt_attributes	equ $26 	;inquire current graphic text attributes
_vqt_extent	equ $74 	;inquire text extent (byte 2=n)
_vqt_width	equ $75010000	;inquire character cell width
_vqt_name	equ $82010000	;inquire face name and index
_vqt_fontinfo	equ $83000000	;inquire current face information
*_vq_cellarray	equ $1b000002	;inquire cell array
_vqin_mode	equ $73010000	;inquire input mode

;Escapes
*_vq_chcells	equ $05000100	;inquire addressable alpha character cells
*_v_exit_cur	equ $05000200	;exit alpha mode
*_v_enter_cur	equ $05000300	;enter alpha mode
*_v_curup 	equ $05000400	;alpha cursor up
*_v_curdown	equ $05000500	;alpha cursor down
*_v_curright	equ $05000600	;alpha cursor right
*_c_curleft	equ $05000700	;alpha cursor left
*_v_curhome	equ $05000800	;home alpha cursor
*_v_eeos	equ $05000900	;erase to end of alpha screen
*_v_eeol	equ $05000a00	;erase to end of alpha text line
*_v_curaddress	equ $05020b00	;direct alpha cursor address
*_v_curtext	equ $05000c00	;output cursor addressable alpha text (byte 2=n)
*_v_rvon	equ $05000d00	;reverse video on
*_v_rvoff 	equ $05000e00	;reverse video off
*_vq_curaddress	equ $05000f00	;inquire current alpha cursor address
*_vq_tabstatus	equ $05001000	;inquire tablet status
*_v_hardcopy	equ $05001100	;hardcopy
*_v_dspcur	equ $05001201	;place graphic cursor at location
*_v_rmcur 	equ $05001300	;remove last graphic cursor
*_v_form_adv	equ $05001400	;form advance
*_v_output_window	equ $05001500	;output window
*_v_clear_disp_list	equ $05001600 ;clear display list
*_v_bit_image	equ $05051702	;output bit image file (byte 2=n+5)
*_vq_scan 	equ $05001800	;inquire printer scan
*_v_alpha_text	equ $05001900	;output alpha text (byte 2=n)
*_vs_palette	equ $05013c00	;select palette
*_v_sound 	equ $05023d00	;generate specified tone
*_vs_mute 	equ $05013e00	;set/clear tone muting flag
*_vqp_films	equ $
*_vqp_state	equ $
*_vsp_state	equ $
*_vsp_save	equ $
*_vsp_message	equ $
*_vqp_error	equ $
*_v_meta_extents	equ $05006202	;update metafile extents
*_v_write_meta	equ $05006300	;write metafile item (byte 0=num_ptsin,byte 2=num_intin)
*_vm_pagesize	equ $05036300	;physical page size
*_wm_coords	equ $05056300	;coordinate window
*_vm_filename	equ $05006400	;change gem vdi filename (byte 2=n)
*_v_offset	equ $05016500	;set line offset
*_v_fontinit	equ $05026600	;init system font
*_v_escape2000	equ $05000000	;set # of additionnal copies
*_vt_resolution	equ $05025100	;set tablet axis resolution in lines/inch
*_vt_axis 	equ $05025200	;set table axis resolution in lines
*_vt_origin	equ $05025300	;set tablet x and y origin
*_vq_tdimensions	equ $05005400	;return tablet x and y dimensions
*_vt_alignment	equ $05025500	;set tablet alignment
*_vsp_film	equ $05025b00	;set camera file type and exposure time
*_vqp_filename	equ $05015c00	;inquire camera file name
*_vsc_expose	equ $05015d00	;disable or enable file exposure for frame preview

;Beziers
*_v_bez_on	equ $0b000d01
*_v_bez_off	equ $0b000d00
*_v_set_app_buff	equ $ff000600
*_v_bez	equ $06000d00
*_v_bez_fill	equ $09000d00
*_v_bez_qual	equ $05036300

;FSM/SPEEDO
*_vqt_f_extent	equ $f0000000
*_v_ftext	equ $f1000001
*_v_killoutline	equ $f2020000
*_v_getoutline	equ $f3030000
*_vst_scratch	equ $f4010000
*_vst_error	equ $f5030000
*_vst_arbpt	equ $f6010000
*_vqt_advance	equ $f7010000
*_vqt_devinfo	equ $f8010000
*_v_savecache	equ $f9000000
*_v_loadcache	equ $fa000000
*_v_flushcache	equ $fb
*_vst_setsize	equ $fc010000
*_vst_skew	equ $fd010000
*_vqt_get_tables	equ $fe000000
*_vqt_cachesize	equ $ff010000
;  #] Functions equates:
;  #[ Macros:
;Control
vq_gdos	MACRO
	moveq	#-2,d0
	trap	#2
	ENDM

v_opnwk	MACRO	;intin must be filled before this call
	move.l	#_\:,d0
	bsr	_VDI
	move.w	contrl+12,vdi_handle	;;set new handle
	ENDM

v_clswk	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_opnvwk	MACRO	;intin must be filled before this call
	move.l	#_\:,d0
	bsr	_VDI
	move.w	contrl+12,vdi_handle	;;set new handle
	ENDM

v_clsvwk	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_clrwk	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_updwk	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_load_fonts	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_unload_fonts	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vs_clip	MACRO	;short clip_flag,short pxyarray[4]
	move.w	\1,intin
	lea	ptsin,a0
	move.w	\2,(a0)+	;;ptsin+0
	move.w	\3,(a0)+	;;ptsin+2
	move.w	\4,(a0)+	;;ptsin+4
	move.w	\5,(a0)+	;;ptsin+6
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

;Output
v_pline	MACRO	;short count (ptsin must be filled with pxyarrays[])
	move.l	#_\:,d0
;;	move.w	\1,d1		;;unrem this if \1 is An
;;	move.b	d1,d0		;;unrem this if \1 is An
	move.b	\1,d0		;;rem this if \1 is An
	bsr	_VDI
	ENDM

v_pmarker	MACRO	;short count (ptsin must be filled with pxyarrays[])
	move.l	#_\:,d0
;;	move.w	\1,d1		;;unrem this if \1 is An
;;	move.b	d1,d0		;;unrem this if \1 is An
	move.b	\1,d0		;;rem this if \1 is An
	bsr	_VDI
	ENDM

v_gtext	MACRO	;short x,short y,char *str
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.l	#_\:,d0
	move.l	\3,a0
	moveq	#0,d1
	bsr	_SVDI
	ENDM

v_fillarea	MACRO	;short count (ptsin must be filled with pxyarrays[])
	move.l	#_\:,d0
;;	move.w	\1,d1		;;unrem this if \1 is An
;;	move.b	d1,d0		;;unrem this if \1 is An
	move.b	\1,d0		;;rem this if \1 is An
	bsr	_VDI
	ENDM
	
;Not finished:
;v_cellarray	MACRO	;short row_length,short pxyarray[4],short elements,short nrows,short write_mode,short col_array[]
;	lea	ptsin,a0
;	move.w	\2,(a0)+	;;ptsin+0
;	move.w	\3,(a0)+	;;ptsin+2
;	move.w	\4,(a0)+	;;ptsin+4
;	move.w	\5,(a0)+	;;ptsin+6
;	move.l	#_\:,d0
;	swap	d0
;;;	move.w	\1,d1		;;unrem this if \1 is An
;;;	move.b	d1,d0		;;unrem this if \1 is An
;	move.b	\1,d0		;;rem this if \1 is An
;	swap	d0
;	bsr	_VDI
;	ENDM
	
v_contourfill	MACRO	;short x,short y,short index
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vr_recfl	MACRO	;short pxyarray[]
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+4
	move.w	\4,ptsin+6
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_bar	MACRO	;short pxyarray[]
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+4
	move.w	\4,ptsin+6
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_arc	MACRO	;short x,short y,short radius,short begang,short endang
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+12
	moev.w	\4,intin
	move.w	\5,intin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_pieslice	MACRO	;short x,short y,short radius,short begang,short endang
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+12
	moev.w	\4,intin
	move.w	\5,intin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_circle	MACRO	;short x,short y,short radius
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+8
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_ellarc	MACRO	;short x,short y,short xrad,short yrad,short begang,short endang
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+4
	move.w	\4,ptsin+6
	move.w	\5,intin
	move.w	\6,intin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_ellpie	MACRO	;short x,short y,short xrad,short yrad,short begang,short endang
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+4
	move.w	\4,ptsin+6
	move.w	\5,intin
	move.w	\6,intin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_ellipse	MACRO	;short x,short y,short xrad,short yrad
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+4
	move.w	\4,ptsin+6
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_rbox	MACRO	;short pxyarray[]
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+4
	move.w	\4,ptsin+6
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_rfbox	MACRO	;short pxyarray[]
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\3,ptsin+4
	move.w	\4,ptsin+6
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_justified	MACRO	;short x,short y,char *str,short len,short word_space,short char_space
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.w	\4,ptsin+4
	move.w	\5,intin
	move.w	\6,intin+2
	move.l	#_\:,d0
	move.l	\3,a0
	moveq	#4,d1
	bsr	_SVDI
	ENDM

;Attributes
vswr_mode	MACRO	;short mode
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vs_color	MACRO	;short index,short rgb[]
	move.w	\1,intin
	move.w	\2,intin+2
	move.w	\3,intin+4
	move.w	\4,intin+6
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsl_type	MACRO	;short style
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsl_udsty	MACRO	;short pattern
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsl_width	MACRO	;short width
	move.w	\1,ptsin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsl_color	MACRO	;short index
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsl_ends	MACRO	;short begstyle,short endstyle
	move.w	\1,intin
	move.w	\2,intin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsm_type	MACRO	;short symbol
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsm_height	MACRO	;short height
	move.w	\1,ptsin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsm_color	MACRO	;short index
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_height	MACRO	;short height
	move.w	\1,ptsin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_point	MACRO	;short point
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_rotation	MACRO	;short angle
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_font	MACRO	;short font
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_color	MACRO	;short index
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_effects	MACRO	;short effect
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vst_alignment	MACRO	;short hin,short vin
	move.w	\1,intin
	move.w	\2,intin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsf_interior	MACRO	;short style
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsf_style	MACRO	;short index
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsf_color	MACRO	;short index
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsf_perimeter	MACRO	;short vis
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

;since our contrl[3] is a byte,we can't use this MACRO for planes > 4
vsf_updat	MACRO	;short planes (max 4) (fill intin[] before this call)
	move.w	\1,d1
	asl.w	#4,d1
	move.l	#swap(_\:),d0
	move.b	d1,d0
	swap	d0
	bsr	_VDI
	ENDM

;Raster
vro_cpyfm	MACRO	;short mode,short pxyarray_org[],short pxyarray_dst[],MFDB *src,MFDB *dst
	move.w	\1,intin
	move.w	\2,ptsin
	move.w	\3,ptsin+2
	move.w	\4,ptsin+4
	move.w	\5,ptsin+6
	move.w	\6,ptsin+8
	move.w	\7,ptsin+10
	move.w	\8,ptsin+12
	move.w	\9,ptsin+14
	move.l	\A,contrl+14
	move.l	\B,contrl+18
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vrt_cpyfm	MACRO	;short mode,short pxyarray_org[],short pxyarray_dst[],MFDB *src,MFDB *dst,short index1,short index2
	move.w	\1,intin
	move.w	\2,ptsin
	move.w	\3,ptsin+2
	move.w	\4,ptsin+4
	move.w	\5,ptsin+6
	move.w	\6,ptsin+8
	move.w	\7,ptsin+10
	move.w	\8,ptsin+12
	move.w	\9,ptsin+14
	move.l	\A,contrl+14
	move.l	\B,contrl+18
	move.w	\C,intin+2
	move.w	\D,intin+4
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vr_trnfm	MACRO	;MFDB *src,MFDB *dst
	move.l	\1,contrl+14
	move.l	\2,contrl+18
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_get_pixel	MACRO	;short x,short y
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

;Input:
vsin_mode	MACRO	;short dev_type,short mode
	move.w	\1,intin
	move.w	\2,intin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vrq_locator	MACRO	;short x,short y
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsm_locator	MACRO	;short x,short y
	move.w	\1,ptsin
	move.w	\2,ptsin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vrq_valuator	MACRO	;short valuator_in
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsm_valuator	MACRO	;short valuator_in
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vrq_choice	MACRO	;short ch_in
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsm_choice	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vrq_string	MACRO	;short max_length,short echo_mode,short x,short y
	move.w	\1,intin
	move.w	\2,intin+2
	move.w	\3,ptsin
	move.w	\4,ptsin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsm_string	MACRO	;short max_length,short echo_mode,short x,short y
	move.w	\1,intin
	move.w	\2,intin+2
	move.w	\3,ptsin
	move.w	\4,ptsin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vsc_form	MACRO	;short form[]
	movem.l	a0-a1,-(sp)
	move.l	\1,a0
	lea	intin,a1
	moveq	#18-1,d0	;37 words
.\@	move.l	(a0)+,(a1)+
	dbf	d0,.\@
	move.w	(a0),(a1)
	movem.l	(sp)+,a0-a1
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vex_timv	MACRO	;void *time_addr
	move.l	\1,contrl+14
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_show_c	MACRO	;short reset
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

v_hide_c	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vq_mouse	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vex_butv	MACRO	;void *new_p
	move.l	\1,contrl+14
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vex_motv	MACRO	;void *new_p
	move.l	\1,contrl+14
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vex_curv	MACRO	;void *new_p
	move.l	\1,contrl+14
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vq_key_s	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

;Inquire
vq_extnd	MACRO	;short flag
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI

vq_color	MACRO	;short index,short flag
	move.w	\1,intin
	move.w	\2,intin+2
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vql_attributes	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vqm_attributes	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vqf_attributes	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vqt_attributes	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vqt_extent	MACRO	;char *str
	move.l	#_\:,d0
	move.l	\1,a0
	moveq	#0,d1
	bsr	_SVDI
	ENDM

vqt_width	MACRO	;short chr
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vqt_name	MACRO	;short element
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vqt_fontinfo	MACRO	;void
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

vqin_mode	MACRO	;short dev_type
	move.w	\1,intin
	move.l	#_\:,d0
	bsr	_VDI
	ENDM

;Escapes
;  #] Macros:
;  #[ _VDI:
	TEXT
_SVDI:	movem.l	d1-d2/a1-a2,-(sp)	;put a0 string in intin from d1
	IF	__MPU
	lea	(intin,pc,d1.l),a1
	ELSE	;__MPU
	lea	intin,a1
	add.l	d1,a1
	ENDIF	;__MPU
	move	#SSIZE_MAX,d2
	moveq	#0,d1
.copy:	move.b	(a0)+,d1
	move.w	d1,(a1)+
	dbeq	d2,.copy
	move	#SSIZE_MAX-1,d1
	sub.w	d2,d1
	swap	d0
	move.b	d1,d0
	swap	d0
	bra.b	*+6			;skip movem
_VDI:	movem.l	d1-d2/a1-a2,-(sp)	;standard call
	IF	__MPU
	lea	(contrl+12,pc),a1
	ELSE	;__MPU
	lea	contrl+12,a1
	ENDIF	;__MPU
	moveq	#0,d1
	move.l	d1,-(a1)
	move.l	d1,-(a1)
	move.l	d1,-(a1)
	move.l	d0,-(sp)
	tst.b	(sp)
	addq.w	#4,sp
	bne.b	.long
	move.b	d0,1(a1)
	bra.b	.vdi
.long:	move.b	d0,3(a1)
	lsr.w	#8,d0
	move.b	d0,11(a1)
	swap	d0
	move.b	d0,7(a1)
	lsr.w	#8,d0
	move.b	d0,1(a1)
.vdi:	IF	__MPU
	move.w	(vdi_handle,pc),12(a1)
	ELSE	;__MPU
	move.w	vdi_handle,12(a1)
	ENDIF	;__MPU
	pea	.vdi_pb(pc)
	move.l	(sp)+,d1
	moveq	#$73,d0
	trap	#2
	IF	__MPU
	move.w	(intout,pc),d0
	ELSE	;__MPU
	move.w	intout,d0
	ENDIF	;__MPU
	movem.l	(sp)+,d1-d2/a1-a2
	rts
.vdi_pb:	dc.l	contrl,intin,ptsin,intout,ptsout

	BSS
vdi_handle:	ds.w	1
contrl:	ds.w	12
intin:	ds.w	SSIZE_MAX
intout:	ds.w	128
ptsin:	ds.w	512	;since TOS 1.02
ptsout:	ds.w	128
	TEXT
;  #] _VDI:
	ENDIF	;_VDI


