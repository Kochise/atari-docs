;****************************************************************
;		Structure d'information pour les sorties graphiques.
;****************************************************************
vdi_pb:		rsstruct
xmin_clip:	rs.w		1 ; Clipping X minimum(W).
xmax_clip:	rs.w		1 ; Clipping X maximum(W).
ymin_clip:	rs.w		1 ; Clipping Y minimum(W).
ymax_clip:	rs.w		1 ; Clipping Y maximum(W).

pt_nb:		rs.w		1 ; Nombre de points(W).
pt_addr:	rs.l		1 ; Adresse du buffer contenant les points(L).
		rsend
;****************************************************************
