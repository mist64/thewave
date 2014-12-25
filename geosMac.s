.macro	LoadB	dest,value
	lda	#value
	sta	dest
.endm

.macro	LoadW	dest,value
	lda	#](value)
	sta	dest+1
	lda	#[(value)
	sta	dest+0
.endm

.macro	MoveB	source,dest
	lda	source
	sta	dest
.endm

.macro	MoveW	source,dest
	lda	source+1
	sta	dest+1
	lda	source+0
	sta	dest+0
.endm

.macro	add	source
	clc
	adc	source
.endm

.macro	AddB	source,dest
	clc
	lda	source
	adc	dest
	sta	dest
.endm

.macro	AddW	source,dest
	lda	source
	clc
	adc	dest+0
	sta	dest+0
	lda	source+1
	adc	dest+1
	sta	dest+1
.endm

.macro	AddVB	value,dest
	lda	dest
	clc
	adc	#value
	sta	dest
.endm


.macro	AddVW	value,dest
	clc
	lda	#[(value)
	adc	dest+0
	sta	dest+0
.if	(value >= 0) && (value <= 255)
	bcc	noInc
	inc	dest+1
noInc:
.else
	lda	#](value)
	adc	dest+1
	sta	dest+1
.endif
.endm

.macro	sub	source
	sec
	sbc	source
.endm

.macro	SubB	source,dest
	sec
	lda	dest
	sbc	source
	sta	dest
.endm

.macro	SubW	source,dest
	lda	dest+0
	sec
	sbc	source+0
	sta	dest+0
	lda	dest+1
	adc	#$ff
	sbc	source+1
	sta	dest+1
.endm


.macro	SubVW	value,dest
	sec
	lda	dest+0
	sbc	#[(value)
	sta	dest+0
.if	(value >= 0) && (value <= 255)
	bcs	noDec
	dec	dest+1
noDec:
.else
	lda	dest+1
	sbc	#](value)
	sta	dest+1
.endif
.endm

.macro	CmpB	source,dest
	lda	source
	cmp	dest
.endm

.macro	CmpBI	source,immed
	lda	source
	cmp	#immed
.endm

.macro	CmpW	source,dest
	lda	source+1
	cmp	dest+1
	bne	done
	lda	source+0
	cmp	dest+0
done:
.endm

.macro	CmpWI	source,immed
	lda	source+1
	cmp	#](immed)
	bne	done
	lda	source+0
	cmp	#[(immed)
done:
.endm


.macro	PushB	source
	lda	source
	pha
.endm

.macro	PushW	source
	lda	source+1
	pha
	lda	source+0
	pha
.endm

.macro	PopB	dest
	pla
	sta	dest
.endm

.macro	PopW	dest
	pla
	sta	dest+0
	pla
	sta	dest+1
.endm

.macro	bra	addr
	clv
	bvc	addr
.endm

.macro	smb	bitNumber,dest
	pha
	lda	#(1 << bitNumber)
	ora	dest
	sta	dest
	pla
.endm

.macro	smbf	bitNumber,dest
	lda	#(1 << bitNumber)
	ora	dest
	sta	dest
.endm

.macro	rmb	bitNumber,dest
	pha
	lda	#[~(1 << bitNumber)
	and	dest
	sta	dest
	pla
.endm

.macro	rmbf	bitNumber,dest
	lda	#[~(1 << bitNumber)
	and	dest
	sta	dest
.endm


.macro	bbs	bitNumber,source,addr
	php
	pha
	lda	source
	and	#(1 << bitNumber)
	beq	nobranch
	pla
	plp
	bra	addr
nobranch:
	pla
	plp
.endm

.macro	bbsf	bitNumber,source,addr
.if	(bitNumber = 7)
	bit	source
	bmi	addr
.elif	(bitNumber = 6)
	bit	source
	bvs	addr
.else
	lda	source
	and	#(1 << bitNumber)
	bne	addr
.endif
.endm

.macro	bbr	bitNumber,source,addr
	php
	pha
	lda	source
	and	#(1 << bitNumber)
	bne nobranch
	pla
	plp
	bra addr
nobranch:
	pla
	plp
.endm

.macro	bbrf	bitNumber,source,addr
.if	(bitNumber = 7)
	bit	source
	bpl	addr
.elif	(bitNumber = 6)
	bit	source
	bvc	addr
.else
	lda	source
	and	#(1 << bitNumber)
	beq	addr
.endif
.endm
