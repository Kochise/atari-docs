	CODE
	;; immédiat vers direct
	move.b  #09, D1		; $123C, $0009
	move.w  #10, D2		; $343C, $000A
	move.l  #11, D3		; $263C, $0000, $000B
	
	;; direct vers direct
	move.b  D1, D2		; $1401
	move.w  D2, D3		; $3602
	move.l  D3, D4		; $2803
	
	;; direct vers immédiat:	 INTERDIT
	;move.l  D3, #2
	