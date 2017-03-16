;TOS.S ½ Brainstorm 1993-1994
;This file includes all equates/structures for TOS programming.
;TAB=16
	IFND	_TOS
_TOS	equ	1
;  #[ Miscellaneous equates:
;for Fsfirst/Fsnext
FS_READONLY	equ	$01
FS_HIDDEN	equ	$02
FS_SYSTEM	equ	$04
FS_VOLUME	equ	$08
FS_SUBDIR	equ	$10
FS_ARCHIVE	equ	$20

;for Fopen
O_RDONLY	equ	0
O_WRONLY	equ	1
O_RDWR	equ	2

;for Fseek
SEEK_SET	equ	0
SEEK_CUR	equ	1
SEEK_END	equ	2

;  #] Miscellaneous equates:
;  #[ Miscellaneous structs:

CCLINE	RSSTRUCT
maxlen	rs.b	1
curlen	rs.b	1
buffer	rs.b	255
	RSEND

DTA	RSSTRUCT
res	rs.b	21
attrib	rs.b	1
time	rs.w	1
date	rs.w	1
length	rs.l	1
fname	rs.b	14
	RSEND

DFREE	RSSTRUCT
free	rs.l	1
total	rs.l	1
secsiz	rs.l	1
clsiz	rs.l	1
	RSEND

BASPAG	RSSTRUCT
lowtpa	rs.l	1
hitpa	rs.l	1
tbase	rs.l	1
tlen	rs.l	1
dbase	rs.l	1
dlen	rs.l	1
bbase	rs.l	1
blen	rs.l	1
dta	rs.l	1	;DTA *
parent	rs.l	1	;BASPAG *
res0	rs.l	1
env	rs.l	1	;char *
stdfh	rs.b	6
res1	rs.b	1
curdrv	rs.b	1
res2	rs.l	18
cmdlin	rs.b	128
	RSEND

BPB	RSSTRUCT
recsiz	rs.w	1
clsiz	rs.w	1
clsizb	rs.w	1
rdlen	rs.w	1
fsiz	rs.w	1
fatrec	rs.w	1
datrec	rs.w	1
numcl	rs.w	1
bflags	rs.w	1
	RSEND

IOREC	RSSTRUCT
buf	rs.l	1
size	rs.w	1
hd	rs.w	1
tl	rs.w	1
low	rs.w	1
hi	rs.w	1
	RSEND

SYSHDR	RSSTRUCT
entry	rs.w	1
version	rs.w	1
start	rs.l	1
base	rs.l	1
membot	rs.l	1
shell	rs.l	1
magic	rs.l	1
gendat	rs.l	1
palmode	rs.w	1
gendatg	rs.w	1
root	rs.l	1
kbshift	rs.l	1	;char *
run	rs.l	1	;BASPAG **
	RSEND

;  #] Miscellaneous structs:
	ENDIF	;_TOS


