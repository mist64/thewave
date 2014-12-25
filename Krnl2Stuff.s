;************************************************************

;	Krnl2Stuff

;************************************************************


	.psect


.if	C64
JScrollScreen:
;	lda	topScrlLine
	.byte	$af,[topScrlLine,]topScrlLine,0
	sta	r3L
;	lda	botScrlLine
	.byte	$af,[botScrlLine,]botScrlLine,0
	sta	r3H
;fall through...
JScrUpRegion:
	MoveB	r3L,r1L
	LoadB	r0L,#40
	ldx	#r1L
	ldy	#r0L
	jsl	SBBMult,0
	sec
	lda	r3H
	sbc	r3L
	sta	r2L
	LoadB	r0L,#40
	ldx	#r2L
	ldy	#r0L
	jsl	SBBMult,0
	phb
	lda	#0
	pha
	plb
	PushW	r1
	bit	vtOn
	bpl	20$
	bit	ansiOn
	bpl	20$
	rep	%00110000
	clc
	lda	r1
	adc	#[COLOR_MATRIX
	.byte	]COLOR_MATRIX
	sta	r1
	adc	#[40
	.byte	]40
	sta	r0
	ldy	#[0
	.byte	]0
 10$
	lda	(r0),y
	sta	(r1),y
	iny
	iny
	cpy	r2
	bcc	10$
 20$
	rep	%00110000
	pla
	asl	a
	asl	a
	asl	a
	clc
	adc	#[$a000
	.byte	]$a000
	sta	r1
	adc	#[320
	.byte	]320
	sta	r0
	lda	r2
	asl	a
	asl	a
	asl	a
	sta	r2
	ldy	#[0
	.byte	]0
 30$
	lda	(r0),y
	sta	(r1),y
	iny
	iny
	cpy	r2
	bcc	30$
	sep	%00110000
	plb
	lda	r3H
SUR2:
	asl	a
	asl	a
	asl	a
	sta	r2L
	clc
	adc	#7
	sta	r2H
	LoadB	r3L,#0
	sta	r3H
	LoadW	r4,#319
	lda	#0
	jsl	SSetPattern,0
	jsl	SRectangle,0
;	lda	vtOn
	.byte	$af,[vtOn,]vtOn,0
	bmi	50$
 45$
	rts
 50$
;	lda	ansiOn
	.byte	$af,[ansiOn,]ansiOn,0
	bpl	45$
	jsl	SConvToCards,0
;	lda	ansiFGColor
	.byte	$af,[ansiFGColor,]ansiFGColor,0
	tax
	lda	ansiFGTable,x
	pha
;	lda	ansiBGColor
	.byte	$af,[ansiBGColor,]ansiBGColor,0
	tax
	pla
	ora	ansiBGTable,x
	sta	r4H
	jsl	SColorRectangle,0
	rts

JScrDnRegion:
	MoveB	r3L,r0L
	LoadB	r1L,#40
	ldx	#r0L
	ldy	#r1L
	jsl	SBBMult,0
	PushW	r0
	sec
	lda	r3H
	sbc	r3L
	sta	r2L
	LoadB	r1L,#40
	ldx	#r2L
	ldy	#r1L
	jsl	SBBMult,0
;	lda	vtOn
	.byte	$af,[vtOn,]vtOn,0
	bpl	20$
;	lda	ansiOn
	.byte	$af,[ansiOn,]ansiOn,0
	bpl	20$
	rep	%00100000
	clc
	lda	r0
	adc	#[COLOR_MATRIX
	.byte	]COLOR_MATRIX
	sta	r0
	adc	#[40
	.byte	]40
	sta	r1
	sep	%00100000
	jsl	SMoveData,0
 20$
	rep	%00100000
	pla
	asl	a
	asl	a
	asl	a
	clc
	adc	#[$a000
	.byte	]$a000
	sta	r0
	adc	#[320
	.byte	]320
	sta	r1
	lda	r2
	asl	a
	asl	a
	asl	a
	sta	r2
	sep	%00100000
	jsl	SMoveData,0
	lda	r3L
	jmp	SUR2

;+++the rest of these routines need to be
;+++modified to work in the SuperRAM.
;+++they are currently not called.

;this will scroll a region of the screen up one line.
;r1L=left screen column (0-79)
;r1H=top screen row (0-24)
;r2L=width of scrolling region (1-80)
;r2H=height of scrolling region (1-25)
ScrUp:
	lda	r1H
	asl	a
	asl	a
	asl	a
	tax
	jsr	GetScanLine
	rep	%00110000
	lda	r1L
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
	sta	r3
	lda	r2L
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
	dea
	clc
	adc	r3
	sta	r4
	lda	r2H
	and	#[$00ff
	.byte	]$00ff
	tax
	dex
	beq	60$
	lda	r5
 20$
	phx
	clc
	adc	#[320
	.byte	]320
	sta	r6
	jsr	MoveLine
	lda	r6
	sta	r5
	plx
	dex
	bne	20$
 60$
	sep	%00110000
	clc
	lda	r1H
	adc	r2H
	asl	a
	asl	a
	asl	a
	dea
	sta	r2H
	sec
	sbc	#7
	sta	r2L
	lda	#0
	jsr	SetPattern
	jmp	Rectangle

ScrDown:
	clc
	lda	r1H
	adc	r2H
	dea
	asl	a
	asl	a
	asl	a
	tax
	jsr	GetScanLine
	rep	%00110000
	lda	r1L
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
	sta	r3
	lda	r2L
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
	dea
	clc
	adc	r3
	sta	r4
	lda	r2H
	and	#[$00ff
	.byte	]$00ff
	tax
	dex
	beq	60$
	lda	r5
 20$
	phx
	sec
	sbc	#[320
	.byte	]320
	sta	r6
	jsr	MoveLine
	lda	r6
	sta	r5
	plx
	dex
	bne	20$
 60$
	sep	%00110000
	clc
	lda	r1H
	asl	a
	asl	a
	asl	a
	sta	r2L
	clc
	adc	#7
	sta	r2H
	lda	#0
	jsr	SetPattern
	jmp	Rectangle

;this must be called with a,x,y set to 16 bits.
MoveLine:
	lda	r3
	and	#[%00000100	;left side on even byte?
	.byte	]%00000100
	bne	40$	;branch if not.
	lda	r4
	and	#[%00000100	;right side on even byte?
	.byte	]%00000100
	beq	20$	;branch if not.
	sec
	lda	r4
	sbc	r3
	ina
	lsr	a
	tax
	ldy	r4	;we can move all whole bytes.
	dey
	jmp	MoveXBytes
 20$
	ldy	r4
	jsr	MvRtUp
	ldy	r4
	dey
	dey
	dey
	tya
	dey
	dey
	sec
	sbc	r3
	lsr	a
	tax
	beq	45$
	jmp	MoveXBytes
 40$
	ldy	r3
	jsr	MvLftUp
	lda	r4
	and	#[%00000100	;right side on even byte?
	.byte	]%00000100
	bne	60$	;branch if so.
	ldy	r4
	jsr	MvRtUp
	ldy	r4
	dey
	dey
	dey
	tya
	dey
	dey
	sec
	sbc	r3
	sbc	#4
	lsr	a
	tax
	bne	50$
 45$
	rts
 50$
	jmp	MoveXBytes
 60$
	sec
	lda	r4
	sbc	r3
	sbc	#3
	lsr	a
	tax
	ldy	r4	;we can move all whole bytes.
	dey

;fall through...

MoveXBytes:
 10$
	lda	(r6),y
	sta	(r5),y
	dey
	dey
	dex
	bne	10$
	rts

MvRtUp:
	ldx	#[4
	.byte	]4
	iny
	iny
	iny
 30$
	lda	(r6),y
	and	#[$f0f0
	.byte	]$f0f0
	sta	r15
	lda	(r5),y
	and	#[$0f0f
	.byte	]$0f0f
	ora	r15
	sta	(r5),y
	dey
	dey
	dex
	bne	30$
	rts

MvLftUp:
	ldx	#[4
	.byte	]4
	iny
	iny
 30$
	lda	(r6),y
	and	#[$0f0f
	.byte	]$0f0f
	sta	r15
	lda	(r5),y
	and	#[$f0f0
	.byte	]$f0f0
	ora	r15
	sta	(r5),y
	dey
	dey
	dex
	bne	30$
	rts

.else
JScrollScreen:
;	lda	topScrlLine
	.byte	$af,[topScrlLine,]topScrlLine,0
	sta	r3L
;	lda	botScrlLine
	.byte	$af,[botScrlLine,]botScrlLine,0
	sta	r3H
	cmp	#24
	bne	80$
	lda	r3L
	bne	80$
	ldx	#1	;scroll two lines.
	.byte	44
 80$
;fall through...
JScrUpRegion:
	ldx	#0	;scroll one line.
	PushB	a0L
	stx	a0L
	MoveB	r3L,r1L
	LoadB	r0L,#80
	ldx	#r1L
	ldy	#r0L
	jsl	SBBMult,0
	sec
	lda	r3H
	sbc	r3L
	sta	r2L
	LoadB	r0L,#80
	ldx	#r2L
	ldy	#r0L
	jsl	SBBMult,0
	phb
	lda	#0
	pha
	plb
	PushW	r1
	bit	vtOn
	bpl	20$
	bit	ansiOn
	bpl	20$
	lda	vdcClrMode
	beq	20$
	rep	%00100000
	clc
	lda	r1
	adc	#[$4000
	.byte	]$4000
	sta	r1
	clc
	adc	#[80
	.byte	]80
	ldx	a0L
	beq	15$
	adc	#[80
	.byte	]80
	pha
	sec
	lda	r2
	sbc	#[80
	.byte	]80
	sta	r2
	pla
 15$
	sta	r0
	sep	%00100000
	jsl	SMoveVData,0
 20$
	rep	%00100000
	pla
	asl	a
	asl	a
	asl	a
	sta	r1
	clc
	adc	#[640
	.byte	]640
	ldx	a0L
	beq	30$
	adc	#[640
	.byte	]640
 30$
	sta	r0
	lda	r2
	asl	a
	asl	a
	asl	a
	sta	r2
	sep	%00100000
	jsl	SMoveVData,0
	plb
	lda	r3H
	ldx	a0L
	beq	60$
	dea
 60$
SUR2:
	asl	a
	asl	a
	asl	a
	sta	r2L
	clc
	adc	#7
	ldx	a0L
	beq	20$
	adc	#8
 20$
	sta	r2H
	LoadB	r3L,#0
	sta	r3H
	LoadW	r4,#639
	lda	#0
	jsl	SSetPattern,0
	jsl	SRectangle,0
;	lda	vtOn
	.byte	$af,[vtOn,]vtOn,0
	bmi	70$
 65$
	PopB	a0L
	rts
 70$
;	lda	ansiOn
	.byte	$af,[ansiOn,]ansiOn,0
	bpl	65$
	jsl	SConvToCards,0
;	lda	ansiFGColor
	.byte	$af,[ansiFGColor,]ansiFGColor,0
	tax
	lda	ansiFGTable,x
	pha
;	lda	ansiBGColor
	.byte	$af,[ansiBGColor,]ansiBGColor,0
	tax
	pla
	ora	ansiBGTable,x
	sta	r4H
	jsl	SColorRectangle,0
	PopB	a0L
	rts


JScrDnRegion:
	PushB	a0L
	ldx	#0	;scroll one line.
	stx	a0L
	MoveB	r3L,r0L
	LoadB	r1L,#80
	ldx	#r0L
	ldy	#r1L
	jsl	SBBMult,0
	PushW	r0
	sec
	lda	r3H
	sbc	r3L
	sta	r2L
	LoadB	r1L,#80
	ldx	#r2L
	ldy	#r1L
	jsl	SBBMult,0
;	lda	vtOn
	.byte	$af,[vtOn,]vtOn,0
	bpl	20$
;	lda	ansiOn
	.byte	$af,[ansiOn,]ansiOn,0
	bpl	20$
;	lda	vdcClrMode
	.byte	$af,[vdcClrMode,]vdcClrMode,0
	beq	20$
	rep	%00100000
	clc
	lda	r0
	adc	#[$4000
	.byte	]$4000
	sta	r0
	adc	#[80
	.byte	]80
	sta	r1
	sep	%00100000
	jsl	SMoveVData,0
 20$
	rep	%00100000
	pla
	asl	a
	asl	a
	asl	a
	sta	r0
	clc
	adc	#[640
	.byte	]640
	sta	r1
	lda	r2
	asl	a
	asl	a
	asl	a
	sta	r2
	sep	%00100000
	jsl	SMoveVData,0
	lda	r3L
	jmp	SUR2

;+++the rest of these routines need to be
;+++modified to work in the SuperRAM.
;+++they are currently not called.

ScrUp:
	PushB	r2L
	PushB	r1L
	PushB	r1H
	PushB	r2H
	dea
	beq	60$
	sta	r15H
	lda	r1H
	asl	a
	asl	a
	asl	a
	tax
	jsr	GetScanLine
	lda	r1L
	clc
	adc	r5L
	sta	r1L
	lda	r5H
	adc	#0
	sta	r1H
	clc
	lda	r1L
	adc	#[640
	sta	r0L
	lda	r1H
	adc	#]640
	sta	r0H
	LoadB	r2H,#0
 20$
	LoadB	r15L,#8
 30$
	jsr	MoveVData
	AddVW	#80,r0
	AddVW	#80,r1
	dec	r15L
	bne	30$
	dec	r15H
	bne	20$
 60$
	PopB	r2H
	pla
	clc
	adc	r2H
	asl	a
	asl	a
	asl	a
	dea
	sta	r2H
	sec
	sbc	#7
	sta	r2L
	pla
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
	asl	a
	sta	r3
	sep	%00100000
	pla
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
	asl	a
	dea
	clc
	adc	r3
	sta	r4
	sep	%00100000
	lda	#0
	jsr	SetPattern
	jmp	Rectangle

ScrDown:
	PushB	r2L
	PushB	r1L
	PushB	r1H
	lda	r2H
	dea
	beq	60$
	sta	r15H
	clc
	adc	r1H
	asl	a
	asl	a
	asl	a
	clc
	adc	#7
	tax
	jsr	GetScanLine
	lda	r1L
	clc
	adc	r5L
	sta	r1L
	lda	r5H
	adc	#0
	sta	r1H
	sec
	lda	r1L
	sbc	#[640
	sta	r0L
	lda	r1H
	sbc	#]640
	sta	r0H
	LoadB	r2H,#0
 20$
	LoadB	r15L,#8
 30$
	jsr	MoveVData
	SubVW	#80,r0
	SubVW	#80,r1
	dec	r15L
	bne	30$
	dec	r15H
	bne	20$
 60$
	pla
	asl	a
	asl	a
	asl	a
	sta	r2L
	clc
	adc	#7
	sta	r2H
	pla
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
	asl	a
	sta	r3
	sep	%00100000
	pla
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
	asl	a
	dea
	clc
	adc	r3
	sta	r4
	sep	%00100000
	lda	#0
	jsr	SetPattern
	jmp	Rectangle

.endif


;translation table for the ANSI foreground colors.
ansiFGTable:
	.byte	BLACK<<4,RED<<4,GREEN<<4,BROWN<<4
	.byte	BLUE<<4,PURPLE<<4,LTBLUE<<4,LTGREY<<4
;these additional 8 colors represent BOLD.
	.byte	DKGREY<<4,LTRED<<4,LTGREEN<<4,YELLOW<<4
	.byte	LTBLUE<<4,LTRED<<4,CYAN<<4,WHITE<<4


;translation table for the ANSI background colors.
ansiBGTable:
	.byte	BLACK,RED,GREEN,BROWN
	.byte	BLUE,PURPLE,LTBLUE,LTGREY

