.macro	LoadB	dt,vl
	lda	#vl
	sta	dt
.endm

.macro	LoadW	dt,vl
	lda	#](vl)
	sta	dt+1
	lda	#[(vl)
	sta	dt+0
.endm

.macro	MoveB	sc,dt
	lda	sc
	sta	dt
.endm

.macro	MoveW	sc,dt
	lda	sc+1
	sta	dt+1
	lda	sc+0
	sta	dt+0
.endm


.macro	AddVW	vl,dt
	clc
	lda	#[(vl)
	adc	dt+0
	sta	dt+0
.if	(vl >= 0) && (vl <= 255)
	bcc	noInc
	inc	dt+1
noInc:
.else
	lda	#](vl)
	adc	dt+1
	sta	dt+1
.endif
.endm


.macro	SubVW	vl,dt
	sec
	lda	dt+0
	sbc	#[(vl)
	sta	dt+0
.if	(vl >= 0) && (vl <= 255)
	bcs	noDec
	dec	dt+1
noDec:
.else
	lda	dt+1
	sbc	#](vl)
	sta	dt+1
.endif
.endm

.macro	CmpW	sc,dt
	lda	sc+1
	cmp	dt+1
	bne	done
	lda	sc+0
	cmp	dt+0
done:
.endm

.macro	CmpWI	sc,im
	lda	sc+1
	cmp	#](im)
	bne	done
	lda	sc+0
	cmp	#[(im)
done:
.endm


.macro	PushB	sc
	lda	sc
	pha
.endm

.macro	PushW	sc
	lda	sc+1
	pha
	lda	sc+0
	pha
.endm

.macro	PopB	dt
	pla
	sta	dt
.endm

.macro	PopW	dt
	pla
	sta	dt+0
	pla
	sta	dt+1
.endm

.macro	bra	ad
	clv
	bvc	ad
.endm

.macro	xce
	.byte	$fb
.endm

.macro	sep	vl
	.byte	$e2,[vl
.endm

.macro	rep	vl
	.byte	$c2,[vl
.endm

.macro	jsl	ad,vl
	.byte	$22,[ad,]ad,[vl
.endm

.macro	jml	ad,vl
	.byte	$5c,[ad,]ad,[vl
.endm

.macro	phb
	.byte	$8b
.endm

.macro	plb
	.byte	$ab
.endm

.macro	phx
	.byte	$da
.endm

.macro	plx
	.byte	$fa
.endm

.macro	phy
	.byte	$5a
.endm

.macro	ply
	.byte	$7a
.endm

.macro	rtl
	.byte	$6b
.endm


.macro	txy
	.byte	$9b
.endm

.macro	tyx
	.byte	$bb
.endm

.macro	mvn	sb,db
	.byte	$54,[db,[sb
.endm

.macro	ina
	.byte	$1a
.endm

.macro	dea
	.byte	$3a
.endm

