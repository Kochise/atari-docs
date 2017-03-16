;AES.S ½ Brainstorm 1993
;This file includes all equates/structures/macros for programming the AES.
;TAB=16
	IFND	_AES
;all the AES macros garbage d0 and return int_out[0] in d0

;  #[ Miscellaneous equates:
;drag'n drop
DD_OK	equ 0
DD_NAK	equ 1
DD_EXT	equ 2
DD_LEN	equ 3
DD_TRASH	equ 4
DD_PRINTER	equ 5
DD_CLIPBOARD	equ 6
DD_TIMEOUT	equ 4000	;timeout in msec
DD_NUMEXTS	equ 8	;number of bytes of "preferred extensions" sent by recipient during open
DD_EXTSIZE	equ 32
DD_NAMEMAX	equ 128	;max size of a drag&drop item name
DD_HDRMAX	equ 8+DD_NAMEMAX	;max length of a drag&drop header

;alerts
AL_NONE	equ 0
AL_STOP	equ 1
AL_QUES	equ 2
AL_EXCL	equ 3
AL_INFO	equ 4	;4.1
AL_DISK	equ 5	;4.1

;evnt_multi flags
MU_KEYBD	equ 1
MU_BUTTON	equ 2
MU_M1	equ 4
MU_M2	equ 8
MU_MESAG	equ $10
MU_TIMER	equ $20

;keyboard states
K_RSHIFT	equ 1
K_LSHIFT	equ 2
K_CTRL	equ 4
K_ALT	equ 8

;event messages values
MN_SELECTED	equ 10
WM_REDRAW	equ 20
WM_TOPPED	equ 21
WM_CLOSED	equ 22
WM_FULLED	equ 23
WM_ARROWED	equ 24
WM_HSLID	equ 25
WM_VSLID	equ 26
WM_SIZED	equ 27
WM_MOVED	equ 28
WM_NEWTOP	equ 29	;3.0
WM_UNTOPPED	equ 30	;4.0
WM_ONTOP	equ 31	;4.0
WM_BOTTOMED	equ 33	;4.1
WM_ICONIFY	equ 34	;4.2
WM_UNICONIFY	equ 35	;4.2
WM_ALLICONIFY	equ 36	;4.2
WM_TOOLBAR	equ 37	;4.2
AC_OPEN	equ 40
AC_CLOSE	equ 41
AP_TERM	equ 50	;4.0
AP_TFAIL	equ 51	;4.0
AP_RESCHG	equ 57	;4.0
SHUT_COMPLETED	equ 60	;4.0
RESCH_COMPLETED	equ 61	;4.0
AP_DRAGDROP	equ 63	;4.1
CH_EXIT	equ 80	;4.0
CT_UPDATE	equ 50	;Xcontrol
CT_MOVE	equ 51	;Xcontrol
CT_NEWTOP	equ 52	;Xcontrol
CT_KEY	equ 53	;Xcontrol

;menu_bar
ME_ASK	equ -1
ME_HIDE	equ 0
ME_SHOW	equ 1
ME_SET	equ 0
ME_NORM	equ 1

;object types
G_BOX	equ 20
G_TEXT	equ 21
G_BOXTEXT	equ 22
G_IMAGE	equ 23
G_USERDEF	equ 24
G_IBOX	equ 25
G_BUTTON	equ 26
G_BOXCHAR	equ 27
G_STRING	equ 28
G_FTEXT	equ 29
G_FBOXTEXT	equ 30
G_ICON	equ 31
G_TITLE	equ 32
G_CICON	equ 33	;3.3

;object flags
NONE	equ 0
SELECTABLE	equ 1
DEFAULT	equ 2
EXIT	equ 4
EDITABLE	equ 8
RBUTTON	equ $10
LASTOB	equ $20
TOUCHEXIT	equ $40
HIDETREE	equ $80
INDIRECT	equ $100
INDICATOR	equ $200
BACKGND	equ $400
ACTIVATOR	equ $600
SUBMENU	equ $800

;object states
NORMAL	equ 0
SELECTED	equ 1
CROSSED	equ 2
CHECKED	equ 4
DISABLED	equ 8
OUTLINED	equ $10
SHADOWED	equ $20

;object colors
WHITE	equ 0
BLACK	equ 1
RED	equ 2
GREEN	equ 3
BLUE	equ 4
CYAN	equ 5
YELLOW	equ 6
MAGENTA	equ 7
LWHITE	equ 8
LBLACK	equ 9
LRED	equ 10
LGREEN	equ 11
LBLUE	equ 12
LCYAN	equ 13
LYELLOW	equ 14
LMAGENTA	equ 15

MAX_LEN	equ 81	;max string length
MAX_DEPTH	equ 8	;max tree depth

;tedinfos fonts
GDOS_PROP	equ 0	;4.2
GDOS_MONO	equ 1	;4.2
GDOS_BITM	equ 2	;4.2
IBM	equ 3
SMALL	equ 5

;tedinfos states
ED_START	equ 0
ED_INIT	equ 1
ED_CHAR	equ 2
ED_END	equ 3

;tedinfos justification
TE_LEFT	equ 0
TE_RIGHT	equ 1
TE_CNTR	equ 2

;form_dial opcodes
FMD_START	equ 0
FMD_GROW	equ 1
FMD_SHRINK	equ 2
FMD_FINISH	equ 3

;graf_mouse types
ARROW	equ 0
TEXT_CRSR	equ 1
HOURGLASS	equ 2
BEE	equ 2
POINT_HAND	equ 3
FLAT_HAND	equ 4
THIN_CROSS	equ 5
THICK_CROSS	equ 6
OUTLN_CROSS	equ 7
USER_DEF	equ 255
M_OFF	equ 256
M_ON	equ 257

;window attributes
WI_NAME	equ 1
WI_CLOSE	equ 2
WI_FULL	equ 4
WI_MOVE	equ 8
WI_INFO	equ $10
WI_SIZE	equ $20
WI_UPARROW	equ $40
WI_DNARROW	equ $80
WI_VSLIDE	equ $100
WI_LFARROW	equ $200
WI_RARROW	equ $400
WI_HSLIDE	equ $800
WI_SMALLER	equ $4000	;4.1

;wind_get & wind_set flags
WF_KIND	equ 1
WF_NAME	equ 2
WF_INFO	equ 3
WF_WORKXYWH	equ 4
WF_CURRXYWH	equ 5
WF_PREVXYWH	equ 6
WF_FULLXYWH	equ 7
WF_HSLIDE	equ 8
WF_VSLIDE	equ 9
WF_TOP	equ 10
WF_FIRSTXYWH	equ 11
WF_NEXTXYWH	equ 12
WF_NEWDESK	equ 14
WF_HSLSIZE	equ 15
WF_VSLSIZE	equ 16
WF_SCREEN	equ 17
WF_COLOR	equ 18
WF_DCOLOR	equ 19
WF_OWNER	equ 20
WF_BEVENT	equ 24
WF_BOTTOM	equ 25	;4.1
WF_ICONIFY	equ 26	;4.1
WF_UNICONIFY	equ 27	;4.1
WF_UNICONIFYXYWH	equ 28	;4.1
WF_TOOlBAR	equ 30	;4.1
WF_FTOOLBAR	equ 31	;4.1
WF_NTOOLBAR	equ 32	;4.1

;window elements
W_BOX	equ 0
W_TITLE	equ 1
W_CLOSER	equ 2
W_NAME	equ 3
W_FULLER	equ 4
W_INFO	equ 5
W_DATA	equ 6
W_WORK	equ 7
W_SIZER	equ 8
W_VBAR	equ 9
W_UPARROW	equ 10
W_DNARROW	equ 11
W_VSLIDE	equ 12
W_VELEV	equ 13
W_HBAR	equ 14
W_LFARROW	equ 15
W_RTARROW	equ 16
W_HSLIDE	equ 17
W_HELEV	equ 18

;arrow messages
WA_UPPAGE	equ 0
WA_DNPAGE	equ 1
WA_UPLINE	equ 2
WA_DNLINE	equ 3
WA_LFPAGE	equ 4
WA_RTPAGE	equ 5
WA_LFLINE	equ 6
WA_RTLINE	equ 7

;wind_calc flags
WC_BORDER	equ 0
WC_WORK	equ 1

;wind_update flags
END_UPDATE	equ 0
BEG_UPDATE	equ 1
END_MCTRL	equ 2
BEG_MCTRL	equ 3
BEG_VUPDATE	equ 257	;4.0
BEG_VMCTRL	equ 259	;4.0

;shel_write
SH_LAUNCH_PRG	equ 0	;4.0
SH_LAUNCH_APP	equ 1	;4.0
SH_RESERVED1	equ 2	;4.0
SH_LAUNCH_ACC	equ 3	;4.0
SH_SHUTDOWN	equ 4	;4.0
SH_CHGRES	equ 5	;4.0
SH_RESERVED2	equ 6	;4.0
SH_BROADCAST	equ 7	;4.0
SH_AESENV	equ 8	;4.0
SH_TERMOK	equ 9	;4.0
SH_SENDMSG	equ 10	;4.0
;  #] Miscellaneous equates: 
;  #[ Miscellaneous structs:
MOBLK	RSSTRUCT
m_out	rs.w 1
m_x	rs.w 1
m_y	rs.w 1
m_w	rs.w 1
m_h	rs.w 1
	RSEND

ORECT	RSSTRUCT
o_link	rs.l 1	;ORECT *
o_x	rs.w 1
o_y	rs.w 1
o_w	rs.w 1
o_h	rs.w 1
	RSEND

GRECT	RSSTRUCT
g_x	rs.w 1
g_y	rs.w 1
g_w	rs.w 1
g_h	rs.w 1
	RSEND

TEDINFO	RSSTRUCT
te_ptext	rs.l 1	;char *
te_ptmplt	rs.l 1	;char *
te_pvalid	rs.l 1	;char *
te_font	rs.w 1
te_fontid	rs.w 1
te_just	rs.w 1
te_color	rs.w 1
te_fontsz	rs.w 1
te_thickness	rs.w 1
te_txtlen	rs.w 1
te_tmplen	rs.w 1
	RSEND

ICONBLK	RSSTRUCT
ib_pmask	rs.l 1	;short *
ib_pdata	rs.l 1	;short *
ib_ptext	rs.l 1	;char *
ib_char	rs.w 1
ib_xchar	rs.w 1
ib_ychar	rs.w 1
ib_xicon	rs.w 1
ib_yicon	rs.w 1
ib_wicon	rs.w 1
ib_hicon	rs.w 1
ib_xtext	rs.w 1
ib_ytext	rs.w 1
ib_wext	rs.w 1
ib_htext	rs.w 1
	RSEND

CICON	RSSTRUCT	;3.3
num_planes	rs.w 1
col_data	rs.l 1	;short *
col_mask	rs.l 1	;short *
sel_data	rs.l 1	;short *
sel_mask	rs.l 1	;short *
next_res	rs.l 1	;CICON *
	RSEND

CICONBLK	RSSTRUCT	;3.3
monoblk	rs.b ICONBLK.SIZEOF
main_list	rs.l 1	;CICON *
	RSEND

BITBLK	RSSTRUCT
bi_pdata	rs.l 1	;short *
bi_wb	rs.w 1
bi_hl	rs.w 1
bi_x	rs.w 1
bi_y	rs.w 1
bi_color	rs.w 1
	RSEND

USERBLK	RSSTRUCT
ub_code	rs.l 1
ub_parm	rs.l 1
	RSEND

OBJECT	RSSTRUCT
ob_next	rs.w 1
ob_head	rs.w 1
ob_tail	rs.w 1
ob_type	rs.w 1
ob_flags	rs.w 1
ob_state	rs.w 1
ob_spec	rs.l 1
ob_x	rs.w 1
ob_y	rs.w 1
ob_width	rs.w 1
ob_height	rs.w 1
	RSEND

PARMBLK	RSSTRUCT
pb_tree	rs.l 1	;OBJECT *
pb_obj	rs.w 1
pb_prevstate	rs.w 1
pb_currstate	rs.w 1
pb_x	rs.w 1
pb_y	rs.w 1
pb_w	rs.w 1
pb_h	rs.w 1
pb_xc	rs.w 1
pb_yc	rs.w 1
pb_wc	rs.w 1
pb_hc	rs.w 1
pb_parm	rs.l 1
	RSEND

MENU	RSSTRUCT
mn_tree	rs.l 1	;OBJECT *
mn_menu	rs.w 1
mn_item	rs.w 1
mn_scroll	rs.w 1
mn_kstate	rs.w 1
	RSEND

MN_SET	RSSTRUCT
display	rs.l 1
drag	rs.l 1
delay	rs.l 1
speed	rs.l 1
height	rs.w 1
	RSEND

;rsrc_gaddr structure types
R_TREE	equ 0
R_OBJECT	equ 1
R_TEDINFO	equ 2
R_ICONBLK	equ 3
R_BITBLK	equ 4
R_STRING	equ 5
R_IMAGEDATA	equ 6
R_OBSPEC	equ 7
R_TEPTEXT	equ 8
R_TEPTMPLT	equ 9
R_TEPVALID	equ 10
R_IBPMASK	equ 11
R_IBPDATA	equ 12
R_IBPTEXT	equ 13
R_BIPDATA	equ 14
RR_FRSTR	equ 15
R_FRIMG	equ 16

RSHHDR	RSSTRUCT
rsh_vrsn	rs.w 1
rsh_object	rs.w 1
rsh_tedinfo	rs.w 1
rsh_iconblk	rs.w 1
rsh_bitblk	rs.w 1
rsh_frstr	rs.w 1
rsh_string	rs.w 1
rsh_imdata	rs.w 1
rsh_frimg	rs.w 1
rsh_trindex	rs.w 1
rsh_nobs	rs.w 1
rsh_ntree	rs.w 1
rsh_nted	rs.w 1
rsh_nib	rs.w 1
rsh_nbb	rs.w 1
rsh_nstring	rs.w 1
rsh_nimages	rs.w 1
rsh_rssize	rs.w 1
	RSEND

RSHLHDR	RSSTRUCT
rshl_vrsn	rs.w 1
rshl_object	rs.l 1
rshl_tedinfo	rs.l 1
rshl_iconblk	rs.l 1
rshl_bitblk	rs.l 1
rshl_frstr	rs.l 1
rshl_string	rs.l 1
rshl_imdata	rs.l 1
rshl_frimg	rs.l 1
rshl_trindex	rs.l 1
rshl_nobs	rs.l 1
rshl_ntree	rs.l 1
rshl_nted	rs.l 1
rshl_nib	rs.l 1
rshl_nbb	rs.l 1
rshl_nstring	rs.l 1
rshl_nimages	rs.l 1
rshl_rssize	rs.l 1
	RSEND

MFORM	RSSTRUCT
mf_xhot	rs.w 1
mf_yhot	rs.w 1
mf_nplanes	rs.w 1
mf_fg	rs.w 1
mf_bg	rs.w 1
mf_mask	rs.w 16
mf_data	rs.w 16
	RSEND
;  #] Miscellaneous structs: 
;  #[ Functions equates:
;APPL
_appl_init	equ $0a000100
_appl_read	equ $0b020101
_appl_write	equ $0c020101
_appl_find	equ $0d000101
_appl_tplay	equ $0e020101
_appl_trecord	equ $0f010101
_appl_search	equ $12010301
_appl_exit	equ $13000100
_appl_getinfo	equ $82010500
;EVNT
_evnt_keybd	equ $14000100
_evnt_button	equ $15030500
_evnt_mouse	equ $16050500
_evnt_mesag	equ $17000101
_evnt_timer	equ $18020100
_evnt_multi	equ $19100701
_evnt_dclick	equ $1a020100
;MENU
_menu_bar	equ $1e010101
_menu_icheck	equ $1f020101
_menu_ienable	equ $20020101
_menu_tnormal	equ $21020101
_menu_text	equ $22010102
_menu_register	equ $23010101
_menu_popup	equ $24020102
_menu_attach	equ $25020102
_menu_istart	equ $26030101
_menu_settings	equ $27010101
;OBJC
_objc_add	equ $28020101
_objc_delete	equ $29010101
_objc_draw	equ $2a060101
_objc_find	equ $2b040101
_objc_offset	equ $2c010301
_objc_order	equ $2d020101
_objc_edit	equ $2e040201
_objc_change	equ $2f080101
;FORM
_form_do	equ $32010101
_form_dial	equ $33090100
_form_alert	equ $34010101
_form_error	equ $35010100
_form_center	equ $36000501
_form_keybd	equ $37030301
_form_button	equ $38020201
;GRAF
_graf_rubberbox	equ $46040300
_graf_dragbox	equ $47080300
_graf_movebox	equ $48060100
_graf_growbox	equ $49080100
_graf_shrinkbox	equ $4a080100
_graf_watchbox	equ $4b040101
_graf_slidebox	equ $4c030101
_graf_handle	equ $4d000500
_graf_mouse	equ $4e010101
_graf_mkstate	equ $4f000500
;SRCP
_scrp_read	equ $50000101
_scrp_write	equ $51000101
;FSEL
_fsel_input	equ $5a000202
_fsel_exinput	equ $5b000203
;WIND
_wind_create	equ $64050100
_wind_open	equ $65050100
_wind_close	equ $66010100
_wind_delete	equ $67010100
_wind_get	equ $68020500
_wind_set	equ $69060100
_wind_find	equ $6a020100
_wind_update	equ $6b010100
_wind_calc	equ $6c060500
_wind_new	equ $6d000000
;RSRC
_rsrc_load	equ $6e000101
_rsrc_free	equ $6f000100
_rsrc_gaddr	equ $70020100
_rsrc_saddr	equ $71020101
_rsrc_obfix	equ $72010101
_rsrc_rcfix	equ $73000101
;SHEL
_shel_read	equ $78000102
_shel_write	equ $79030102
_shel_get	equ $7a010101
_shel_put	equ $7b010101
_shel_find	equ $7c000101
_shel_envrn	equ $7d000102
;  #] Functions equates: 
;  #[ Macros:
;APPL
appl_init	MACRO	;;void
	clr.w	control+8	;;see _AES
	move.l	#_\:,d0
	bsr	_AES
	ENDM

appl_read	MACRO	;;short apid,short length,void *appbuff
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.l	\3,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

appl_write	MACRO	;;short apid,short length,void *appbuff
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.l	\3,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

appl_find	MACRO	;;char *name
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

appl_tplay	MACRO	;;void *mem,short num,short scale
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

appl_trecord	MACRO	;;void *mem,short count
	move.w	\2,int_in
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

appl_exit	MACRO	;;void
	move.l	#_\:,d0
	bsr	_AES
	ENDM

appl_search	MACRO	;;short mode,char *name
	move.w	\1,int_in
	move.l	\2,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

appl_getinfo	MACRO	;;short type
	move.w	\1,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;EVNT
evnt_keybd	MACRO	;;void
	move.l	#_\:,d0
	bsr	_AES
	ENDM

evnt_button	MACRO	;;short clicks,short whichbutton,short whichstate
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

evnt_mouse	MACRO	;;short enterexit,short inx,short iny,short inw,short inh
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.l	#_\:,d0
	bsr	_AES
	ENDM

evnt_mesag	MACRO	;;short mesagbuf[]
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

evnt_timer	MACRO	;;unsigned long interval
	move.l	\1,d0
	swap	d0
	move.l	d0,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

evnt_multi	MACRO	;;short type,short clicks,short whichbutton,short whichstate,short enterexit1,short in1x,short in1y,short in1w,short in1h,short enterexit2,short in2x,short in2y,short in2w,short in2h,short mesagbuf[],long interval
	move.w	\1,int_in
	IF	\?2
	move.w	\2,int_in+2
	ENDIF
	IF	\?3
	move.w	\3,int_in+4
	ENDIF
	IF	\?4
	move.w	\4,int_in+6
	ENDIF
	IF	\?5
	move.w	\5,int_in+8
	ENDIF
	IF	\?6
	move.w	\6,int_in+10
	ENDIF
	IF	\?7
	move.w	\7,int_in+12
	ENDIF
	IF	\?8
	move.w	\8,int_in+14
	ENDIF
	IF	\?9
	move.w	\9,int_in+16
	ENDIF
	IF	\?A
	move.w	\A,int_in+18
	ENDIF
	IF	\?B
	move.w	\B,int_in+20
	ENDIF
	IF	\?C
	move.w	\C,int_in+22
	ENDIF
	IF	\?D
	move.w	\D,int_in+24
	ENDIF
	IF	\?E
	move.w	\E,int_in+26
	ENDIF
	IF	\?F
	move.l	\F,addr_in
	ENDIF
	IF	\?G
	move.l	\G,d0
	swap	d0
	move.l	d0,int_in+28
	ENDIF
	move.l	#_\:,d0
	bsr	_AES
	ENDM

evnt_dclick	MACRO	;;short toset,short setget
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;MENU
menu_bar	MACRO	;;void *tree,short showflag
	move.l	\1,addr_in
	move.w	\2,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_icheck	MACRO	;;void *tree,short item,short checkflag
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_ienable	MACRO	;;void *tree,short item,short enableflag
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_tnormal	MACRO	;;void *tree,short item,short normalflag
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_text	MACRO	;;void *tree,short item,char *text
	move.l	\1,addr_in
	move.w	\2,int_in
	move.l	\3,addr_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_register	MACRO	;;short apid,char *menutext
	move.w	\1,int_in
	move.l	\2,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_popup	MACRO	;;MENU *me_menu,short me_xpos,short me_ypos,MENU *me_mdata
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.l	\4,addr_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_attach	MACRO	;;short me_flag,OBJECT *me_tree,short me_item,MENU *me_mdata
	move.w	\1,int_in
	move.l	\2,addr_in
	move.w	\3,int_in+2
	move.l	\4,addr_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_istart	MACRO	;;short me_flag,OBJECT *me_tree,short me_imenu,short me_item
	move.w	\1,int_in
	move.l	\2,addr_in
	move.w	\3,int_in+2
	move.w	\4,int_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

menu_settings	MACRO	;;short me_flag,MN_SET *me_values
	move.w	\1,int_in
	move.l	\2,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;OBJC
objc_add	MACRO	;;void *tree,short parent,short child
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

objc_delete	MACRO	;;void *tree,short object
	move.l	\1,addr_in
	move.w	\2,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

objc_draw	MACRO	;;void *tree,short start,short depth,short cx,short cy,short cw,short ch
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.w	\4,int_in+4
	move.w	\5,int_in+6
	move.w	\6,int_in+8
	move.w	\7,int_in+10
	move.l	#_\:,d0
	bsr	_AES
	ENDM

objc_find	MACRO	;;void *tree,short start,short depth,short mx,short my
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.w	\4,int_in+4
	move.w	\5,int_in+6
	move.l	#_\:,d0
	bsr	_AES
	ENDM

objc_offset	MACRO	;;void *tree,short object
	move.l	\1,addr_in
	move.w	\2,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

objc_order	MACRO	;;void *tree,short object,short newpos
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

objc_edit	MACRO	;;void *tree,short object,short char,short index,short kind
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.w	\4,int_in+4
	move.w	\5,int_in+6
	move.l	#_\:,d0
	bsr	_AES
	ENDM

objc_change	MACRO	;;void *tree,short object,short res,short cx,short cy,short cw,short ch,short newstate,short redraw
	move.l	\1,addr_in
	move.w	\2,int_in
	clr.w	int_in+2	;reserved
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.w	\6,int_in+10
	move.w	\7,int_in+12
	move.w	\8,int_in+14
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;FORM
form_do	MACRO	;;void *tree,short startobj
	move.l	\1,addr_in
	move.w	\2,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

form_dial	MACRO	;;short flag,short sx,short sy,short sw,short sh,short bx,short by,short bw,short bh
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.w	\6,int_in+10
	move.w	\7,int_in+12
	move.w	\8,int_in+14
	move.w	\9,int_in+16
	move.l	#_\:,d0
	bsr	_AES
	ENDM

form_alert	MACRO	;;short defbutton,char *str
	move.w	\1,int_in
	move.l	\2,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

form_error	MACRO	;;short errorcode
	move.w	\1,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

form_center	MACRO	;;void *tree
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

form_keybd	MACRO	;;void *ktree,short kobject,short kobnext,short kchar
	move.l	#_\:,d0
	bsr	_AES
	ENDM

form_button	MACRO	;;void *btree,short bobject,short bclicks
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;GRAF
graf_rubberbox	MACRO	;;short ix,short iy,short iw,short ih
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_dragbox	MACRO	;;short ix,short iy,short iw,short ih,short bx,short by,short bw,short bh
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.w	\6,int_in+10
	move.w	\7,int_in+12
	move.w	\8,int_in+14
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_movebox	MACRO	;;short sw,short sh,short sx,short sy,short dx,short dy
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.w	\6,int_in+10
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_growbox	MACRO	;;short sx,short sy,short sw,short sh,short fx,short fy,short fw,short fh
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.w	\6,int_in+10
	move.w	\7,int_in+12
	move.w	\8,int_in+14
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_shrinkbox	MACRO	;;short fx,short fy,short fw,short fh,short sx,short sy,short sw,short sh
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.w	\6,int_in+10
	move.w	\7,int_in+12
	move.w	\8,int_in+14
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_watchbox	MACRO	;;void *tree,short object,short instate,short outstate
	clr.w	int_in
	move.l	\1,addr_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_slidebox	MACRO	;;void *tree,short parent,short object,short direction
	move.l	\1,addr_in
	move.w	\2,int_in
	move.w	\3,int_in+2
	move.w	\4,int_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_handle	MACRO	;;void
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_mouse	MACRO	;;short form,void *formaddress
	move.w	\1,int_in
	IF	\?2
	move.l	\2,addr_in
	ENDIF
	move.l	#_\:,d0
	bsr	_AES
	ENDM

graf_mkstate	MACRO	;;void
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;SCRP
scrp_read	MACRO	;;char *scrappath
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

scrp_write	MACRO	;;char *scrappath
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;FSEL
fsel_input	MACRO	;;char *path,char *file
	move.l	\1,addr_in
	move.l	\2,addr_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

fsel_exinput	MACRO	;;char *path,char *file,char *prompt
	move.l	\1,addr_in
	move.l	\2,addr_in+4
	move.l	\3,addr_in+8
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;WIND
wind_create	MACRO	;;short parts,short wx,short wy,short ww,short wh
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_open	MACRO	;;short whandle,short wx,short wy,short ww,short wh
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_close	MACRO	;;short whandle
	move.w	\1,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_delete	MACRO	;;short whandle
	move.w	\1,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_get	MACRO	;;short whandle,short what
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_set	MACRO	;;short whandle,short what
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_find	MACRO	;;short x,short y
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_update	MACRO	;;short code
	move.w	\1,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_calc	MACRO	;;short type,short parts,short inx,short iny,short inw,short inh
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.w	\4,int_in+6
	move.w	\5,int_in+8
	move.w	\6,int_in+10
	move.l	#_\:,d0
	bsr	_AES
	ENDM

wind_new	MACRO	;;void
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;RSRC
rsrc_load	MACRO	;;char *Name
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

rsrc_free	MACRO	;;void
	move.l	#_\:,d0
	bsr	_AES
	ENDM

rsrc_gaddr	MACRO	;;short type,short index,void *address
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	#1,control+8
	move.l	#_\:,d0
	bsr	_AES
	clr.w	control+8
	ENDM

rsrc_saddr	MACRO	;;short type,short index,void *address
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.l	\3,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

rsrc_obfix	MACRO	;;void *tree,short index
	move.l	\1,addr_in
	move.w	\2,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

rsrc_rcfix	MACRO	;;RSHHDR *tree
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

;SHEL
shel_read	MACRO	;;char *command,char *tail
	move.l	\1,addr_in
	move.l	\2,addr_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

shel_write	MACRO	;;short exit,short graphic,short aes,char *command,char *tail
	move.w	\1,int_in
	move.w	\2,int_in+2
	move.w	\3,int_in+4
	move.l	\4,addr_in
	move.l	\5,addr_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM

shel_get	MACRO	;;char *buf,short len
	move.l	\1,addr_in
	move.l	\2,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

shel_put	MACRO	;;char *buf,short len
	move.l	\1,addr_in
	move.l	\2,int_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

shel_find	MACRO	;;char *buf
	move.l	\1,addr_in
	move.l	#_\:,d0
	bsr	_AES
	ENDM

shel_envrn	MACRO	;;char *result,char *param
	move.l	\1,addr_in
	move.l	\2,addr_in+4
	move.l	#_\:,d0
	bsr	_AES
	ENDM
;  #] Macros: 
;  #[ _AES:
	TEXT
_AES:	movem.l	d1-d2/a0-a2,-(sp)
	IF	__MPU
	lea	(control,pc),a1
	ELSEIF	;__MPU
	lea	control,a1
	ENDIF	;__MPU
	movep.l	d0,1(a1)
	moveq	#0,d0
	movep.l	d0,0(a1)
;	move.w	d0,8(a1)	;done by appl_init
	move.w	#$c8,d0
	pea	.aes_pb(pc)
	move.l	(sp)+,d1
	trap	#2
	IF	__MPU
	move.w	(int_out,pc),d0
	ELSE	;__MPU
	move.w	int_out,d0
	ENDIF	;__MPU
	movem.l	(sp)+,d1-d2/a0-a2
	rts
.aes_pb:	dc.l	control,global,int_in,int_out,addr_in,addr_out
	BSS
control:	ds.w	5
global:	ds.w	14
int_in:	ds.w	16
int_out:	ds.w	7
addr_in:	ds.l	3
addr_out:	ds.l	1
	TEXT
;  #] _AES: 
	ENDIF	;_AES


