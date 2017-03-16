;****************************************************************
;		Macros du GEMDOS.
;****************************************************************
Pterm0		macro
		clr.w		-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Cconin		macro
		move.w		#1,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Cconout		macro
		move.w		\1,-(sp)
		move.w		#2,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Cauxin		macro
		move.w		#3,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Cauxout		macro
		move.w		\1,-(sp)
		move.w		#4,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Cprnout		macro
		move.w		\1,-(sp)
		move.w		#5,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Crawio		macro
		move.w		\1,-(sp)
		move.w		#6,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Crawcin		macro
		move.w		#7,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Cnecin		macro
		move.w		#8,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Cconws		macro
		move.l		\1,-(sp)
		move.w		#9,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Cconrs		macro
		move.l		\1,-(sp)
		move.w		#10,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Cconis		macro
		move.w		#11,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Dsetdrv		macro
		move.w		\1,-(sp)
		move.w		#14,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Cconos		macro
		move.w		#16,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Cprnos		macro
		move.w		#17,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Cauxis		macro
		move.w		#18,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Cauxos		macro
		move.w		#19,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Maddalt		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#20,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Dgetdrv		macro
		move.w		#25,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Fsetdta		macro
		move.l		\1,-(sp)
		move.w		#26,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Supervisor	macro
		move.l		\1,-(sp)
		move.w		#32,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Tgetdate	macro
		move.w		#42,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Tsetdate	macro
		move.w		\1,-(sp)
		move.w		#43,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Tgettime	macro
		move.w		#44,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Tsettime	macro
		move.w		\1,-(sp)
		move.w		#45,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Fgetdta		macro
		move.w		#47,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Sversion	macro
		move.w		#48,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Ptermres	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#49,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Dfree		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#54,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Dcreate		macro
		move.l		\1,-(sp)
		move.w		#57,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Ddelete		macro
		move.l		\1,-(sp)
		move.w		#58,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Dsetpath	macro
		move.l		\1,-(sp)
		move.w		#59,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Fcreate		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#60,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Fopen		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#61,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Fclose		macro
		move.w		#62,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Fread		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#63,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Fwrite		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#64,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Fdelete		macro
		move.l		\1,-(sp)
		move.w		#65,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Fseek		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#66,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Fattrib		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#67,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Mxalloc		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#68,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Fdup		macro
		move.w		\1,-(sp)
		move.w		#69,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Fforce		macro
		move.w		\1,-(sp)
		move.w		#70,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Dgetpath	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#71,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Malloc		macro
		move.l		\1,-(sp)
		move.w		#72,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Mfree		macro
		move.l		\1,-(sp)
		move.w		#73,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Mshrink		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		clr.w		-(sp)
		move.w		#74,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Pexec		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		\4,-(sp)
		move.w		#75,-(sp)
		trap		#1
		lea		(16.w,sp),sp
		endm

Pterm		macro
		move.w		\1,-(sp)
		move.w		#76,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Fsfirst		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#78,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Fsnext		macro
		move.w		#79,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Frename		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#86,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Fdatime		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#87,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Flock		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		#92,-(sp)
		trap		#1
		lea		(14.w,sp),sp
		endm

Syield		macro
		move.w		#255,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Fpipe		macro
		move.l		\1,-(sp)
		move.w		#256,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Fcntl		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#260,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Finstat		macro
		move.w		\1,-(sp)
		move.w		#261,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Foutstat	macro
		move.w		\1,-(sp)
		move.w		#262,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Fgetchar	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#263,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Fputchar	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#264,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Pwait		macro
		move.w		#265,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pnice		macro
		move.w		\1,-(sp)
		move.w		#266,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Pgetpid		macro
		move.w		#267,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pgetppid	macro
		move.w		#268,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pgetpgrp	macro
		move.w		#269,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Psetpgrp	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#270,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Pgetuid		macro
		move.w		#271,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Psetuid		macro
		move.w		\1,-(sp)
		move.w		#272,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Pkill		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#273,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Psignal		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#274,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Pvfork		macro
		move.w		#275,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pgetgid		macro
		move.w		#276,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Psetgid		macro
		move.w		\1,-(sp)
		move.w		#277,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Psigblock	macro
		move.l		\1,-(sp)
		move.w		#278,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Psigsetmask	macro
		move.l		\1,-(sp)
		move.w		#279,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Pusrval		macro
		move.w		#280,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pdomain		macro
		move.w		\1,-(sp)
		move.w		#281,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Psigreturn	macro
		move.w		#282,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pfork		macro
		move.w		#283,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pwait3		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#284,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Fselect		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		\4,-(sp)
		move.w		#285,-(sp)
		trap		#1
		lea		(16.w,sp),sp
		endm

Prusage		macro
		move.l		\1,-(sp)
		move.w		#286,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Psetlimit	macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#287,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Talarm		macro
		move.l		\1,-(sp)
		move.w		#288,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Pause		macro
		move.w		#289,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Sysconf		macro
		move.w		\1,-(sp)
		move.w		#290,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Psigpending	macro
		move.w		#291,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Dpathconf	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#292,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Pmsg		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#293,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Fmidipipe	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#294,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Prenice		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#295,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Dopendir	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#296,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Dreaddir	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#297,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Drewinddir	macro
		move.l		\1,-(sp)
		move.w		#298,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Dclosedir	macro
		move.l		\1,-(sp)
		move.w		#299,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Fxattr		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#300,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Flink		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#301,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Fsymlink	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#302,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Freadlink	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#303,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Dcntl		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#304,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Fchown		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#305,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Fchmod		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#306,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Pumask		macro
		move.w		\1,-(sp)
		move.w		#307,-(sp)
		trap		#1
		addq.l		#4,sp
		endm

Psemaphore	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#308,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Dlock		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#309,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Psigpause	macro
		move.l		\2,-(sp)
		move.w		#310,-(sp)
		trap		#1
		addq.l		#6,sp
		endm

Psigaction	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#311,-(sp)
		trap		#1
		lea		(12.w,sp),sp
		endm

Pgeteuid	macro
		move.w		#312,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pgetegid	macro
		move.w		#313,-(sp)
		trap		#1
		addq.l		#2,sp
		endm

Pwaitpid	macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#314,-(sp)
		trap		#1
		addq.l		#8,sp
		endm

Dgetcwd		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#315,-(sp)
		trap		#1
		lea		(10.w,sp),sp
		endm

Salert		macro
		move.l		\1,-(sp)
		move.w		#316,-(sp)
		trap		#1
		addq.l		#6,sp
		endm
