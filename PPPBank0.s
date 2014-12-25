;*************************************
;
;	PPPBank0
;
;*************************************

.if	Pass1

.noeqin
.noglbl

C64=1
C128=0
C64AND128=0

.include	WheelsEquates
.include	WheelsSyms
.include	superMac
.include	TermEquates

.glbl
.eqin

.endif


	.psect


JSendPPPFrame:
	lda	r2L
	ora	r2H
	beq	90$
	lda	proto0LTable,x
	sta	pppProtocol+1
	lda	proto0HTable,x
	sta	pppProtocol+0
	lda	#$ff
	sta	outCRC+0
	sta	outCRC+1
	lda	#PPP_FLAG	;1st	 flag byte.
	jsr	JSend1Byte
	bne	90$
	lda	#PPP_ADDRESS	;address byte.
	jsr	CRCAndOut
	bne	90$
	lda	#PPP_CONTROL	;control byte.
	jsr	CRCAndOut
	bne	90$
	lda	pppProtocol+0
	jsr	CRCAndOut
	bne	90$
	lda	pppProtocol+1
	jsr	CRCAndOut
	bne	90$
 20$
;	lda	[r0]
	.byte	$a7,r0
	inc	r0L
	bne	25$
	inc	r0H
 25$
	jsr	CRCAndOut
	bne	90$
	ldx	#r2
	jsr	Ddec
	bne	20$
	lda	outCRC+0
	eor	#$ff
	jsr	NoCRCOut
	bne	90$
	lda	outCRC+1
	eor	#$ff
	jsr	NoCRCOut
	bne	90$
	lda	#PPP_FLAG	;last	 flag byte.
	jsr	JSend1Byte
	bne	90$
	sec
	rts
 90$
	clc
	rts

proto0LTable:
	.byte	[NCP_PROTOCOL,[LCP_PROTOCOL,[PAP_PROTOCOL,[IP_PROTOCOL
proto0HTable:
	.byte	]NCP_PROTOCOL,]LCP_PROTOCOL,]PAP_PROTOCOL,]IP_PROTOCOL
pppProtocol:
	.block	2

CRCAndOut:
	tay
	eor	outCRC+0
	tax
	lda	crc00Table,x
	eor	outCRC+1
	sta	outCRC+0
	lda	crc01Table,x
	sta	outCRC+1
	tya
NoCRCOut:
	cmp	#PPP_FLAG	;same as a flag byte?
	beq	50$	;branch if so.
	cmp	#PPP_ESCAPE	;same as an escape byte?
	beq	50$	;branch if so.
	cmp	#(128|XON)
	beq	50$
	cmp	#(128|XOFF)
	beq	50$
	cmp	#$20	;is it 32 or higher?
	bcs	60$	;branch if so.
 50$
	pha
	lda	#PPP_ESCAPE
	jsr	JSend1Byte	;send an escape byte.
	pla
	eor	#$20	;eor the actual byte.
 60$
	jmp	JSend1Byte	;send the byte.

outCRC:
	.block	2


crc00Table: 
	.byte	$00,$89,$12,$9b,$24,$ad,$36,$bf 
	.byte	$48,$c1,$5a,$d3,$6c,$e5,$7e,$f7 
	.byte	$81,$08,$93,$1a,$a5,$2c,$b7,$3e
	.byte	$c9,$40,$db,$52,$ed,$64,$ff,$76 
	.byte	$02,$8b,$10,$99,$26,$af,$34,$bd 
	.byte	$4a,$c3,$58,$d1,$6e,$e7,$7c,$f5 
	.byte	$83,$0a,$91,$18,$a7,$2e,$b5,$3c 
	.byte	$cb,$42,$d9,$50,$ef,$66,$fd,$74 
	.byte	$04,$8d,$16,$9f,$20,$a9,$32,$bb 
	.byte	$4c,$c5,$5e,$d7,$68,$e1,$7a,$f3 
	.byte	$85,$0c,$97,$1e,$a1,$28,$b3,$3a 
	.byte	$cd,$44,$df,$56,$e9,$60,$fb,$72 
	.byte	$06,$8f,$14,$9d,$22,$ab,$30,$b9 
	.byte	$4e,$c7,$5c,$d5,$6a,$e3,$78,$f1 
	.byte	$87,$0e,$95,$1c,$a3,$2a,$b1,$38 
	.byte	$cf,$46,$dd,$54,$eb,$62,$f9,$70 
	.byte	$08,$81,$1a,$93,$2c,$a5,$3e,$b7 
	.byte	$40,$c9,$52,$db,$64,$ed,$76,$ff 
	.byte	$89,$00,$9b,$12,$ad,$24,$bf,$36 
	.byte	$c1,$48,$d3,$5a,$e5,$6c,$f7,$7e
	.byte	$0a,$83,$18,$91,$2e,$a7,$3c,$b5 
	.byte	$42,$cb,$50,$d9,$66,$ef,$74,$fd 
	.byte	$8b,$02,$99,$10,$af,$26,$bd,$34 
	.byte	$c3,$4a,$d1,$58,$e7,$6e,$f5,$7c 
	.byte	$0c,$85,$1e,$97,$28,$a1,$3a,$b3 
	.byte	$44,$cd,$56,$df,$60,$e9,$72,$fb 
	.byte	$8d,$04,$9f,$16,$a9,$20,$bb,$32 
	.byte	$c5,$4c,$d7,$5e,$e1,$68,$f3,$7a 
	.byte	$0e,$87,$1c,$95,$2a,$a3,$38,$b1 
	.byte	$46,$cf,$54,$dd,$62,$eb,$70,$f9 
	.byte	$8f,$06,$9d,$14,$ab,$22,$b9,$30 
	.byte	$c7,$4e,$d5,$5c,$e3,$6a,$f1,$78 


crc01Table: 
	.byte	$00,$11,$23,$32,$46,$57,$65,$74 
	.byte	$8c,$9d,$af,$be,$ca,$db,$e9,$f8 
	.byte	$10,$01,$33,$22,$56,$47,$75,$64 
	.byte	$9c,$8d,$bf,$ae,$da,$cb,$f9,$e8 
	.byte	$21,$30,$02,$13,$67,$76,$44,$55 
	.byte	$ad,$bc,$8e,$9f,$eb,$fa,$c8,$d9 
	.byte	$31,$20,$12,$03,$77,$66,$54,$45 
	.byte	$bd,$ac,$9e,$8f,$fb,$ea,$d8,$c9 
	.byte	$42,$53,$61,$70,$04,$15,$27,$36 
	.byte	$ce,$df,$ed,$fc,$88,$99,$ab,$ba 
	.byte	$52,$43,$71,$60,$14,$05,$37,$26 
	.byte	$de,$cf,$fd,$ec,$98,$89,$bb,$aa 
	.byte	$63,$72,$40,$51,$25,$34,$06,$17 
	.byte	$ef,$fe,$cc,$dd,$a9,$b8,$8a,$9b 
	.byte	$73,$62,$50,$41,$35,$24,$16,$07 
	.byte	$ff,$ee,$dc,$cd,$b9,$a8,$9a,$8b 
	.byte	$84,$95,$a7,$b6,$c2,$d3,$e1,$f0 
	.byte	$08,$19,$2b,$3a,$4e,$5f,$6d,$7c 
	.byte	$94,$85,$b7,$a6,$d2,$c3,$f1,$e0 
	.byte	$18,$09,$3b,$2a,$5e,$4f,$7d,$6c 
	.byte	$a5,$b4,$86,$97,$e3,$f2,$c0,$d1 
	.byte	$29,$38,$0a,$1b,$6f,$7e,$4c,$5d 
	.byte	$b5,$a4,$96,$87,$f3,$e2,$d0,$c1 
	.byte	$39,$28,$1a,$0b,$7f,$6e,$5c,$4d 
	.byte	$c6,$d7,$e5,$f4,$80,$91,$a3,$b2 
	.byte	$4a,$5b,$69,$78,$0c,$1d,$2f,$3e
	.byte	$d6,$c7,$f5,$e4,$90,$81,$b3,$a2 
	.byte	$5a,$4b,$79,$68,$1c,$0d,$3f,$2e
	.byte	$e7,$f6,$c4,$d5,$a1,$b0,$82,$93 
	.byte	$6b,$7a,$48,$59,$2d,$3c,$0e,$1f 
	.byte	$f7,$e6,$d4,$c5,$b1,$a0,$92,$83 
	.byte	$7b,$6a,$58,$49,$3d,$2c,$1e,$0f 

