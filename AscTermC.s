;**********************************

;	AscTermC


;**********************************


	.psect


InitTxtWindow:
.if	C64
	jsr	FixMseColor
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	lda	$d01d
	ora	#%00000010
	sta	$d01d
.if	C64
	PopB	CPU_DATA
.endif

;fall through...

StrXYZero:
	LoadB	botScrlLine,#NUMTERMLINES-1
	LoadB	topScrlLine,#0
	sta	stringX+0
	sta	stringX+1
	sta	cursorX+0
	sta	cursorX+1
	sta	r11L
	sta	r11H
	LoadB	stringY,#TOP_LINE
	sta	cursorY
	clc
	adc	baselineOffset
	sta	r1H
	rts


.if	C64
FixMseColor:
	jsr	FMC1
	bit	vtOn
	bmi	10$
 5$
	jmp	RstrMouse
 10$
	bit	ansiOn
	bpl	5$
	jmp	DoTermMouse
FMC1:
	ldx	sysMob0Clr
	bit	vtOn
	bpl	10$
	bit	ansiOn
	bpl	10$
	ldx	ansiBGColor
	lda	mseColor,x
	tax
 10$
FMC2:
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
	stx	mob0clr
	stx	mob1clr
	PopB	CPU_DATA
	rts

mseColor:
	.byte	LTBLUE,YELLOW,YELLOW,LTGREY
	.byte	LTBLUE,YELLOW,YELLOW,DKGREY


RstrMouse:
	LoadW	r0,#svMsePtr
	clc
	jsr	DTM2
	ldx	sysMob0Clr
	jmp	FMC2

DoTermMouse:
	LoadW	r0,#mse40Image
	sec
DTM2:
	php
	ldy	#0
 10$
	lda	(r0),y
	sta	mousePicData,y
	sta	spr0pic,y
	iny
	cpy	#63
	bcc	10$
	ldx	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
	lda	$d01c
	lsr	a
	plp
	rol	a
	sta	$d01c
	LoadB	$d025,#YELLOW
	LoadB	$d026,#BLACK
	stx	CPU_DATA
	rts


mse40Image:
	.byte	%10101010,%10000000,%00000000
	.byte	%10010101,%11000000,%00000000
	.byte	%10010111,%11000000,%00000000
	.byte	%10010111,%00000000,%00000000
	.byte	%10010101,%10000000,%00000000
	.byte	%10111101,%01100000,%00000000
	.byte	%11111111,%01011000,%00000000
	.byte	%11001111,%11010110,%00000000
	.byte	%00000011,%11111111,%00000000
	.byte	%00000000,%11111111,%00000000
	.byte	%00000000,%00111111,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000
	.byte	%00000000,%00000000,%00000000

SaveMsePointer:
	ldy	#62
 10$
	lda	mousePicData,y
	sta	svMsePtr,y
	dey
	bpl	10$
	rts

svMsePtr:
	.block	63

.endif

SetTxtPos:
	rep	%00100000
	lda	cursorX
	sta	stringX
	sta	r11
	sep	%00100000
	MoveB	cursorY,stringY
	clc
	adc	baselineOffset
	sta	r1H
	rts

SaveTxtPos:
	rep	%00100000
	lda	r11
	sta	stringX
	sta	cursorX
	sep	%00100000
	rts

endOfTerm:
