	CODE
	;; effective adress vers Registre
        add.b   #09, D1		; $D33C, $0009
	add.w   #10, D2		; $D57C, $000A
	add.l   #11, D3		; $D7BC, $0000, $000B

	;add.b   D3, #2		; INTERDIT
	
	;; Registre vers effective adress
	add.b   D1, D4		; $D901	
	