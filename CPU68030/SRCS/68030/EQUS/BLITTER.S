;****************************************************************
;		Registres du blitter.
;****************************************************************
blitter_base	equ		$ff8a00
blit		rsstruct
halftone:	rs.w		16
src_xinc:	rs.w		1
src_yinc:	rs.w		1
src_addr:	rs.l		1
endmask1:	rs.w		1
endmask2:	rs.w		1
endmask3:	rs.w		1
dst_xinc:	rs.w		1
dst_yinc:	rs.w		1
dst_addr:	rs.l		1
x_count:	rs.w		1
y_count:	rs.w		1
hop:		rs.b		1
op:		rs.b		1
line_num:	rs.b		1
skew:		rs.b		1
		rsend
