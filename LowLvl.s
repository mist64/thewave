;************************************************************

;		LowLvl


;************************************************************



	.psect



JFullMouse:
	lda	#0
	sta	mouseTop
	sta	mouseLeft+0
	sta	mouseLeft+1
	LoadB	mouseBottom,#199
.if	C64
	LoadW	mouseRight,#319
.else
	LoadW	mouseRight,#639
.endif
	rts

JFullMargins:
	lda	#0
	sta	windowTop
	sta	leftMargin+0
	sta	leftMargin+1
	LoadB	windowBottom,#199
.if	C64
	LoadW	rightMargin,#319
.else
	LoadW	rightMargin,#639
.endif
	rts

JHideScreen:
	LoadB	r1L,#0
	sta	r1H
.if	C64
	LoadB	r2L,#40
.else
	LoadB	r2L,#80
.endif
	LoadB	r2H,#25
	LoadB	r4H,#(LTGREY<<4|LTGREY)
	jmp	ColorRectangle

JGrayScreen:
	jsr	JHideScreen
	lda	#2
	jsr	SetPattern
	jsr	SetWholeScreen
	jsr	Rectangle
	jsr	ConvToCards
	LoadB	r4H,#(DKGREY<<4|LTGREY)
	jmp	ColorRectangle

JClearScreen:
	lda	#0
	jsr	SetPattern
	jsr	SetWholeScreen
	jmp	Rectangle

JImprintScreen:
	jsr	SetWholeScreen
	jmp	ImprintRectangle

;load the accumulator with the desired border color
;and call this routine to set it.
JSetBrdrColor:
.if	C64
	tax
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
	stx	$d020
	PopB	CPU_DATA
	rts
.else
	ldx	vdcClrMode
	bne	10$
	rts
 10$
	jmp	PutReg26

.endif


JClearTop:
	lda	#0
	jsr	SetPattern
	LoadB	r2L,#0
	LoadB	r2H,#15
	jsr	SetLeftRight
	jsr	Rectangle
	LoadB	r11L,#0
	lda	#%11111111
	jsr	HorizontalLine
	LoadB	r11L,#15
	lda	#%11111111
	jsr	HorizontalLine
	LoadB	r2L,#0
	LoadB	r2H,#15
	jsr	ConvToCards
	MoveB	menuColor,r4H
	jmp	ColorRectangle

SetWholeScreen:
	LoadB	r2L,#0
	LoadB	r2H,#199
SetLeftRight:
	LoadB	r3L,#0
	sta	r3H
SetRight:
.if	C128
	bit	graphicsMode
	bpl	50$
	LoadW	r4,#639
	rts
 50$
.endif
	LoadW	r4,#319
	rts

JClearBTop:
	lda	#0
	jsr	SetPattern
	LoadB	r2L,#16
	LoadB	r2H,#38
	jsr	SetLeftRight
	jsr	Rectangle
	jsr	ConvToCards
	MoveB	miscColor,r4H
	jsr	ColorRectangle
	jsr	SetLeftRight
	LoadB	r11L,#39
	lda	#%11111111
	jsr	HorizontalLine
	lda	#9
	jsr	SetPattern
	LoadB	r2L,#24
	LoadB	r2H,#38
.if	C64
	LoadW	r3,#8
	LoadW	r4,#319-16
.else
	LoadW	r3,#16
	LoadW	r4,#639-32
.endif
	jsr	Rectangle
	LoadB	r2L,#27
	LoadB	r2H,#37
	lda	#0
	jsr	SetPattern
	jsr	Rectangle
	jsr	ConvToCards
	MoveB	menuColor,r4H
	jmp	ColorRectangle

JClearBWindow:
	lda	#0
	jsr	SetPattern
	jsr	SetWholeScreen
	MoveB	bWinTop,r2L
	jsr	Rectangle
	jsr	ConvToCards
	LoadB	r4H,#(DKGREY<<4|WHITE)
	jmp	ColorRectangle


;This will take the ascii decimal string pointed at
;by r0-r1L and convert it to a 32-bit value and store
;the resulting value in r2-r3. The string can contain
;commas, but must be null terminated.
JDecTo32:
	jsr	ClrR2R3
	beq	90$	;branch if null string.
 30$
;	lda	[r0],y
	.byte	$b7,r0
	beq	50$
	cmp	#','
	bne	40$
	inc	r0L
	bne	30$
	inc	r0H
	bne	30$
 40$
	jsr	Dec2Bin
	bcc	90$
	jsr	Dec32Digit
	iny
	cpy	#10
	bcc	30$
 50$
	sec
	rts
 90$
	clc
	rts

ClrR2R3:
	ldy	#0
	sty	r2L
	sty	r2H
	sty	r3L
	sty	r3H
;	lda	[r0],y
	.byte	$b7,r0
	rts

;This will take the ascii hex string pointed at
;by r0-r1L and convert it to a 32-bit value and store
;the resulting value in r2-r3. The string must be
;null terminated.
JHexTo32:
	jsr	ClrR2R3
	beq	90$	;branch if null string.
 30$
;	lda	[r0],y
	.byte	$b7,r0
	beq	50$
	jsr	Hex2Bin
	bcc	90$
	jsr	Hex32Digit
	iny
	cpy	#8
	bcc	30$
 50$
	sec
	rts
 90$
	clc
	rts


;this converts an ascii decimal digit to binary if
;the accumulator holds a valid character. Carry is
;set if successful.
Dec2Bin:
	cmp	#'9'+1
	bcs	90$
	sec
	sbc	#'0'
	rts
 90$
	clc
	rts

;this converts an ascii hex digit to binary if
;the accumulator holds a valid character. Carry is
;set if successful.
Hex2Bin:
	ora	#%00100000
	sec
	sbc	#'0'
	bcc	90$
	cmp	#10
	bcc	80$
	sbc	#'a'-'0'-10
	cmp	#10
	bcc	90$
	cmp	#16
	bcs	90$
 80$
	sec
	rts
 90$
	rts

Hex32Digit:
	ldx	#16
	.byte	44
Dec32Digit:
	ldx	#10
	stx	r9L
	pha
	phy
	ldx	#r2
	ldy	#r9L
	jsr	JMult32
	ply
	pla
	clc
	adc	r6L
	sta	r2L
	lda	r6H
	adc	#0
	sta	r2H
	lda	r7L
	adc	#0
	sta	r3L
	lda	r7H
	adc	#0
	sta	r3H
	rts

DrScrBar:
	MoveB	scrAreaTop,r3L
	MoveB	scrAreaBottom,r3H
	MoveW	scrAreaLeft,r4
	lda	#%11111111
	jsr	VerticalLine
	MoveW	scrAreaRight,r4
	lda	#%11111111
	jsr	VerticalLine
	LoadW	r0,#scrArwPic
	MoveB	scrArwLeft,r1L
	MoveB	scrArwTop,r1H
.if	C64
	LoadB	r2L,#1
.else
	LoadB	r2L,#(1|DOUBLE_B)
.endif
	LoadB	r2H,#16
	jmp	BitmapUp

scrArwPic:



ClrScrBar:
	lda	#0
	jsr	SetPattern
	ldx	#5
 10$
	lda	scrAreaTop,x
	sta	r2,x
	dex
	bpl	10$
	jsr	CSB2
	ldx	#5
 20$
	lda	scrArrsTop,x
	sta	r2,x
	dex
	bpl	20$
CSB2:
	jsr	Rectangle
	jsr	ConvToCards
	MoveB	menuColor,r4H
	jmp	ColorRectangle


;call this to initialize the scrollbar. Point r0 at a table containing
;the topmost screen position for the scrollbar, the leftmost position,
;the height of the area, the volume the scrollbar is to travel through,
;the location within the volume to position the scrollbar to, and the
;size of the visible area.
JInitScrBar:
	ldy	#29
 10$
	lda	(r0),y
	sta	scrBarTable,y
	dey
	bpl	10$
	sec
	lda	scrAreaBottom
	sbc	scrAreaTop
	clc
	adc	#1
	sta	scrAreaHeight
	sta	r1L
	MoveB	scrBarVolume+0,r1H
	MoveB	scrBarVolume+1,r2L
	MoveB	scrBarVolume+2,r2H
	ldx	#r1H
	ldy	#r1L
	jsr	JMult24
	clc
	lda	scrBarVolume+0
	adc	scrBarSegment
	sta	r1L
	lda	scrBarVolume+1
	adc	#0
	sta	r1H
	lda	scrBarVolume+2
	adc	#0
	beq	30$
 20$
	lsr	r7H
	ror	r7L
	ror	r6H
	ror	r6L
	lsr	a
	ror	r1H
	ror	r1L
	cmp	#0
	bne	20$
 30$
	ldy	#r1
	jsr	D32div
	clc
	lda	scrAreaTop
	adc	r6L
	sta	scrBarBottom
	sec
	lda	scrAreaHeight
	sbc	r6L
	beq	40$
	bcs	50$
 40$
	lda	#1
 50$
	sta	scrBarHeight
	LoadB	r3H,#0
	lda	scrArwLeft
	asl	a
	rol	r3H
	asl	a
	rol	r3H
	asl	a
	rol	r3H
	sta	scrArrsLeft+0
	clc
.if	C64
	adc	#7
.else
	adc	#15
.endif
	sta	scrArrsRight+0
	MoveB	r3H,scrArrsLeft+1
	adc	#0
	sta	scrArrsRight+1
	clc
	lda	scrArwTop
	sta	scrArrsTop
	adc	#15
	sta	scrArrsBottom
	jsr	ClrScrBar
	bit	scrBarTable
	bpl	80$
	jsr	DrScrBar
	MoveB	scrBarLocation+0,r1H
	MoveB	scrBarLocation+1,r2L
	MoveB	scrBarLocation+2,r2H
	jsr	JPosScrBar
 80$
	ldx	watchMOffset
	LoadW	r0,#WatchMouse
	jsr	AddMnRoutine
	stx	watchMOffset
	rts


JPosScrBar:
	sec
	lda	scrBarBottom
	sbc	scrAreaTop
	sta	r1L
	ldx	#r1H
	ldy	#r1L
	jsr	JMult24
	MoveB	scrBarVolume+0,r1L
	MoveB	scrBarVolume+1,r1H
	lda	scrBarVolume+2
	beq	30$
 20$
	lsr	r7H
	ror	r7L
	ror	r6H
	ror	r6L
	lsr	a
	ror	r1H
	ror	r1L
	cmp	#0
	bne	20$
 30$
	ldy	#r1
	jsr	D32div

;fall through to PlaceScrBar...


;previous page falls through to here.
PlaceScrBar:
	clc
	lda	scrAreaTop
	sta	r2L
	adc	r6L
	sta	scrBarTop
	sec
	sbc	#1
	sta	r2H
	clc
	lda	scrAreaLeft+0
	adc	#1
	sta	r3L
	lda	scrAreaLeft+1
	adc	#0
	sta	r3H
	sec
	lda	scrAreaRight+0
	sbc	#1
	sta	r4L
	lda	scrAreaLeft+1
	sbc	#0
	sta	r4H
	lda	r2L
	cmp	scrBarTop
	beq	35$
	lda	#0
	jsr	SetPattern
	jsr	Rectangle
 35$
	clc
	lda	r2H
	adc	scrBarHeight
	cmp	scrAreaBottom
	bcc	40$
	lda	scrAreaBottom
 40$
	sta	r2H
	MoveB	scrBarTop,r2L
	lda	#2
	jsr	SetPattern
	jsr	Rectangle
	lda	#%11111111
	jsr	FrameRectangle
	lda	r2L
	cmp	scrBarBottom
	bcs	80$
	lda	r2L
	adc	scrBarHeight
	sta	r2L
	MoveB	scrAreaBottom,r2H
	lda	#0
	jsr	SetPattern
	jsr	Rectangle
 80$
	rts

WatchMouse:
	lda	menuNumber
	beq	10$
	rts
 10$
	bit	mouseData
	bmi	95$
	bit	scrBarTable
	bpl	95$
;	php
;	sei
	ldx	#5
 20$
	lda	scrAreaTop,x
	sta	r2,x
	dex
	bpl	20$
	jsr	IsMseInRegion
	cmp	#[TRUE
	bne	50$
	lda	mouseYPos
	cmp	scrBarTop	;click above scrollbar?
	bcc	74$	;branch if so.
	clc
	lda	scrBarTop
	adc	scrBarHeight
	cmp	mouseYPos	;click below the scrollbar?
	bcc	76$	;branch if so.
	beq	76$	;branch if so.
	bcs	72$	;branch if right on it.
 50$
	ldx	#5
 60$
	lda	scrArrsTop,x
	sta	r2,x
	dex
	bpl	60$
	jsr	IsMseInRegion
	cmp	#[TRUE
	bne	90$
	clc
	lda	r2L
	adc	#7
	cmp	mouseYPos	;clicked on up or down arrow?
	bcc	70$	;branch if down arrow.
	ldy	#6
	.byte	44
 70$
	ldy	#8
	.byte	44
 72$
	ldy	#0
	.byte	44
 74$
	ldy	#2
	.byte	44
 76$
	ldy	#4
	jmp	DoScrRoutines
 90$
;	plp
 95$
	lda	app1MnRoutine+0
	ldx	app1MnRoutine+1
	jmp	CallRoutine

DoScrRoutines:
	sty	scrRtnToCall
.if	C128
	LoadB	keepMouse,#%10000000
.endif
	MoveB	mouseTop,DSR2+1
	MoveB	mouseBottom,DSR3+1
	MoveB	mouseLeft+0,DSR4+1
	MoveB	mouseLeft+1,DSR5+1
	MoveB	mouseRight+0,DSR6+1
	MoveB	mouseRight+1,DSR7+1
	MoveB	mouseXPos+0,mouseLeft+0
	sta	mouseRight+0
	MoveB	mouseXPos+1,mouseLeft+1
	sta	mouseRight+1
	MoveB	mouseYPos,mouseTop
	sta	mouseBottom
	sta	clickYSpot
;	plp
	ldy	scrRtnToCall
	bne	55$
	jsr	MoveScrBar
	bra	90$
 55$
	cpy	#6
	bcs	60$
	jsr	DoSBarClick
	bra	90$
 60$
	ldy	scrRtnToCall
	lda	scrollRoutines+0,y
	ldx	scrollRoutines+1,y
	beq	90$
	jsr	CallRoutine
.if	C128
	jsr	Soft80Handler
.endif
	bit	mouseData
	bpl	60$
 90$
DSR2:
	lda	#0
	sta	mouseTop
DSR3:
	lda	#0
	sta	mouseBottom
DSR4:
	lda	#0
	sta	mouseLeft+0
DSR5:
	lda	#0
	sta	mouseLeft+1
DSR6:
	lda	#[319
	sta	mouseRight+0
DSR7:
	lda	#]319
	sta	mouseRight+1
.if	C128
	LoadB	keepMouse,#%00000000
.endif
	lda	app2MnRoutine+0
	ldx	app2MnRoutine+1
	jmp	CallRoutine

scrRtnToCall:
	.block	1

DoSBarClick:
	LoadB	dblCounter,#3
 20$
	ldy	scrRtnToCall
	lda	scrollRoutines+0,y
	ldx	scrollRoutines+1,y
	beq	90$
	jsr	CallRoutine
.if	C128
	jsr	Soft80Handler
.endif
	lda	dblCounter
	beq	30$
	dec	dblCounter
	LoadB	dblClickCount,#15
 30$
	bit	mouseData
	bmi	90$
	lda	mouseYPos
	cmp	scrBarTop
	beq	80$
	bcc	70$
	clc
	lda	scrBarTop
	adc	scrBarHeight
	cmp	mouseYPos
	bcc	70$
	bne	80$
 70$
	lda	dblClickCount
	beq	20$
	bne	30$
 80$
	jmp	MoveScrBar
 90$
	rts

dblCounter:
	.block	1

MoveScrBar:
	sec
	lda	scrAreaTop
	sbc	scrBarTop
	clc
	adc	mouseYPos
	sta	mouseTop
	sec
	lda	scrBarBottom
	sbc	scrAreaTop
	clc
	adc	mouseTop
	sta	mouseBottom
 20$
	bit	mouseData
	bmi	90$
	lda	mouseYPos
	cmp	clickYSpot
	beq	20$
	tax
	sec
	sbc	clickYSpot
	stx	clickYSpot
	clc
	adc	scrBarTop
	sec
	sbc	scrAreaTop
	sta	r6L
	jsr	PlaceScrBar
.if	C128
	jsr	Soft80Handler
.endif
	jsr	SendSBPos
	bra	20$
 90$
	rts


clickYSpot:
	.block	1

SendSBPos:
	sec
	lda	scrBarTop
	sbc	scrAreaTop
	sta	r1L
	MoveB	scrBarVolume+0,r1H
	MoveB	scrBarVolume+1,r2L
	MoveB	scrBarVolume+2,r2H
	ldx	#r1H
	ldy	#r1L
	jsr	JMult24
	sec
	lda	scrBarBottom
	sbc	scrAreaTop
	sta	r1L
	ldy	#r1L
	jsr	D32div
	lda	scrOnRoutine+0
	ldx	scrOnRoutine+1
	jmp	CallRoutine

JOTempHideMouse:
.if	C64
	rts
.else
	bit	keepMouse
	bmi	90$
	jsr	TempHideMouse
 90$
	rts

keepMouse:
	.block	1

.endif

JDoBeep:
	lda	alarmSetFlag
	and	#%11000000
	ora	#%01000001
	sta	alarmSetFlag
	rts


.if	C128

GetReg24:
	ldx	#24
	.byte	44
GetReg25:
	ldx	#25
	.byte	44
GetReg26:
	ldx	#26
	.byte	44
GetReg28:
	ldx	#28

;fall through...

JReadReg:
	stx	$d600
 10$
	bit	$d600
	bpl	10$
	lda	$d601
	rts


PutReg24:
	ldx	#24
	.byte	44
PutReg25:
	ldx	#25
	.byte	44
PutReg26:
	ldx	#26
	.byte	44
PutReg28:
	ldx	#28
	.byte	44
PutReg30:
	ldx	#30

;fall through...

JWriteReg:
	stx	$d600
 10$
	bit	$d600
	bpl	10$
	sta	$d601
	rts


;	r0 address in CPU ram.
;	r1  address in VDC ram.
;	r2  number of bytes to transfer.
;	r3L bank in CPU ram.
JStashVRam:
	lda	#%10000000
	.byte	44
JFetchVRam:
	lda	#%00000000
	sta	vDirection
	jsr	OTempHideMouse
	lda	r2L
	ora	r2H
	beq	90$
	php
	sei
	PushW	r0
	PushW	r1
	PushW	r2
	jsr	R1To18
	MoveB	r3L,r1L
	ldx	#31
	stx	$d600
	rep	%00010000
	ldy	#[0
	.byte	]0
	bit	vDirection
	bpl	50$
 20$
;	lda	[r0],y
	.byte	$b7,r0
 30$
	bit	$d600
	bpl	30$
	sta	$d601
	iny
	cpy	r2
	bcc	20$
	bcs	80$
 50$
	bit	$d600
	bpl	50$
	lda	$d601
;	sta	[r0],y
	.byte	$97,r0
	iny
	cpy	r2
	bcc	50$
 80$
	sep	%00010000
	PopW	r2
	PopW	r1
	PopW	r0
	plp
 90$
	rts

vDirection:
	.block	1

JiFillVRam:
	PopW	returnAddress
	jsr	R0_R2L
	jsr	JFillVRam
	php
	lda	#6
	jmp	DoInlineReturn


;r1=address in VDC ram to poke a byte to.
;accumulator holds value to poke.
JPokeVRam:
	pha
	jsr	R1To18
	pla
	ldx	#31
	jmp	JWriteReg

;r1=address in VDC ram to peek.
;returns with accumulator holding the value.
JPeekVRam:
	jsr	R1To18
	ldx	#31
	jmp	JReadReg


JClearVRam:
	LoadB	r2L,#0

	;fall through to JFillVRam...

;this will fill an area of the VDC with a byte value. Call the routine with
;r0=# bytes to fill, r1=starting address in VDC, r2L=fill byte value.
JFillVRam:
	jsr	OTempHideMouse
	php
	sei
	jsr	GetReg24
	sta	mvsave24
	and	#%01111111
	jsr	JWriteReg
	jsr	R1To18
	ldx	#31
	lda	r2L
	jsr	JWriteReg
	jsr	R1To18
	MoveW	r0,r2
	jmp	MVD5

;this simply puts the value from r1 into reg 18 for destination
;addresses on memory moves and fills.

R1To18:
	ldx	#18	;now set the starting address
	lda	r1H	;of the destination memory into reg 18-19
	jsr	JWriteReg
	inx
	lda	r1L
	jmp	JWriteReg


JiMoveVData:
	PopW	returnAddress
	jsr	R0_R2L
	lda	(returnAddress),y
	sta	r2H
	jsr	JMoveVData
	php
	lda	#7
	jmp	DoInlineReturn

R0_R2L:
	ldy	#1
	lda	(returnAddress),y
	sta	r0L
	iny
	lda	(returnAddress),y
	sta	r0H
	iny
	lda	(returnAddress),y
	sta	r1L
	iny
	lda	(returnAddress),y
	sta	r1H
	iny
	lda	(returnAddress),y
	sta	r2L
	iny
	rts

JMoveVData:
	lda	r2L
	ora	r2H
	bne	10$
	rts
 10$
	jsr	OTempHideMouse
	CmpW	r1,r0
	bcs	20$
	jmp	MVD1
 20$
	rep	%00100000
	lda	r3
	pha
	lda	r2
	pha
	lda	r1
	pha
	lda	r0
	pha
	sec
	lda	r1
	sbc	r0
	cmp	#[255
	.byte	]255
	bcc	30$
	lda	#[255
	.byte	]255
 30$
	sta	r3
	lda	r0
	clc
	adc	r2
	sec
	sbc	r3
	sta	r0
	lda	r1
	clc
	adc	r2
	sec
	sbc	r3
	sta	r1
	sep	%00100000
	php
	sei
	jsr	GetReg24	;x gets set to 24.
	sta	mvsave24
	ora	#%10000000
	jsr	JWriteReg
	lda	r2H
	bne	40$
	lda	r3L
	cmp	r2L
	bcs	60$
 40$
	jsr	MoveVBytes
	lda	r2H
	bne	50$
	lda	r3L
	cmp	r2L
	bcs	55$
 50$
	jsr	R3LFrmR2R0R1
	bra	40$
 55$
	MoveB	r2L,r3L
	jsr	R3LFrmR0R1
	bra	65$
 60$
	lda	r2L
	beq	70$
	sta	r3L
 65$
	jsr	MoveVBytes
 70$
	lda	mvsave24	;and put reg 24 back.
	jsr	PutReg24
	plp
	PopW	r0
	PopW	r1
	PopW	r2
	PopW	r3
	rts


MoveVBytes:
	ldx	#32	;now set the starting address
	lda	r0H	;of the source memory into reg 32-33.
	jsr	JWriteReg
	inx
	lda	r0L
	jsr	JWriteReg
	jsr	R1To18
	ldx	#30
	lda	r3L
	jmp	JWriteReg


R3LFrmR2R0R1:
	sec
	lda	r2L
	sbc	r3L
	sta	r2L
	lda	r2H
	sbc	#0
	sta	r2H
R3LFrmR0R1:
	sec
	lda	r0L
	sbc	r3L
	sta	r0L
	lda	r0H
	sbc	#0
	sta	r0H
	sec
	lda	r1L
	sbc	r3L
	sta	r1L
	lda	r1H
	sbc	#0
	sta	r1H
	rts


MVD1:
	PushB	r3L
	LoadB	r3L,#255
	jsr	MVD2
	PopB	r3L
	rts

MVD2:
	php
	sei
	PushW	r2
	jsr	GetReg24	;x gets set to 24.
	sta	mvsave24
	ora	#%10000000
	jsr	JWriteReg
	ldx	#32	;now set the starting address
	lda	r0H	;of the source memory into reg 32-33.
	jsr	JWriteReg
	inx
	lda	r0L
	jsr	JWriteReg
	jsr	R1To18
MVD5:
	ldx	#30
 10$
	lda	r2H
	bne	20$
	lda	r3L
	cmp	r2L
	bcs	30$
 20$
	lda	r3L
	jsr	JWriteReg	;move 255 bytes at a time.
	sec
	lda	r2L
	sbc	r3L
	sta	r2L
	lda	r2H
	sbc	#0
	sta	r2H
	bra	10$
 30$
	lda	r2L	;how many bytes left to move?
	beq	40$	;branch if none.
	jsr	JWriteReg	;move the remaining bytes.
 40$
	lda	mvsave24	;and put reg 24 back.
	jsr	PutReg24
	PopW	r2
	plp
	rts

mvsave24:
	.block	1



.else

;these do nothing on the 64.

JReadReg:
JWriteReg:
JMoveVData:
JiMoveVData:
JClearVRam:
JFillVRam:
JiFillVRam:
JStashVRam:
JFetchVRam:
JPokeVRam:
JPeekVRam:
	rts

.endif

RaiseMenu:
	jsr	RecoverRectangle
	jsr	ConvToCards
	jsr	JSetRstrColor
	jmp	RstrColor

JSetSaveColor:
	LoadW	r0,#mColor
	MoveW	RecoverVector,rcvrSave
	LoadW	RecoverVector,#RaiseMenu
	rts

JSetRstrColor:
	LoadW	r0,#mColor
	MoveW	rcvrSave,RecoverVector
	rts


.if	C64
JPattScreen:
	lda	sysBorder
	jsr	JSetBrdrColor
	jsr	JHideScreen
	LoadW	curPattern,#backSysPattern
	jsr	SetWholeScreen
	jsr	Rectangle
	jsr	ConvToCards
	MoveB	backColor,r4H
	jmp	ColorRectangle
.else
JPattScreen:
	lda	sys80Border
	jsr	JSetBrdrColor
	jsr	JHideScreen
	LoadW	curPattern,#backSysPattern
	jsr	SetWholeScreen
	jsr	Rectangle
	jsr	ConvToCards
	MoveB	backColor,r4H
	jmp	ColorRectangle
.endif

JFrameDB:
.if	C64
	ldx	#$43
.else
	ldx	#$44
.endif
	lda	$00,x
	sta	r0L
	lda	$01,x
	sta	r0H
	jsr	LdDBCoords
	inc	r2L
	inc	r2L
	dec	r2H
	AddVW	#2,r3
	SubVW	#1,r4
	lda	#%11111111
	jmp	FrameRectangle


LdDBCoords:
	ldy	#0
	lda	(r0),y	;DEF_DB_POS?
	bmi	50$	;branch if so.
	iny
	ldx	#0
 10$
	lda	(r0),y
	sta	r2,x
	iny
	inx
	cpx	#6
	bcc	10$
	rts
 50$
	LoadB	r2L,#DEF_DB_TOP
	LoadB	r2H,#DEF_DB_BOT
.if	C64
	LoadW	r3,#DEF_DB_LEFT
	LoadW	r4,#DEF_DB_RIGHT
	rts
.else
	bit	graphicsMode
	bmi	60$
	LoadW	r3,#DEF_DB_LEFT
	LoadW	r4,#DEF_DB_RIGHT
	rts
 60$
	LoadW	r3,#(DEF_DB_LEFT*2)
	LoadW	r4,#(DEF_DB_RIGHT*2)+1
	rts
.endif


JDoColorBox:
	jsr	SvForeScreen
	jsr	SaveDB
	PushW	keyVector	;+++other vectors may also need to
			;+++be preserved?
	LoadB	keyVector+0,#0
	sta	keyVector+1
	MoveB	nmiSet,curNmiSet
	jsr	OffNMIReceive
	jsr	RstrNMIInterrupts
	jsr	SetEmulationMode
	jsr	DoDlgBox
	PushB	r0L
	jsr	SetNativeMode
	bit	waveRunning
	bmi	40$
	jsr	RstrTerminal
 40$
	bit	curNmiSet
	bpl	50$
	jsr	SetNMIInterrupts
	jsr	OnNMIReceive
 50$
	PopB	r0L
	PopW	keyVector
	lda	r0L
	rts

curNmiSet:
	.block	1

SaveDB:
	MoveW	RecoverVector,saveRecVec
	LoadW	RecoverVector,#RstrDB
	ldx	#31
 10$
	lda	r0,x
	pha
	dex
	bpl	10$
	jsr	LdDBCoords
	jsr	ConvToCards
	bit	waveRunning
	bpl	40$
	LoadW	r0,#mColor
	jsr	SaveColor
 40$
	MoveB	appDBColor,r4H
	jsr	ColorRectangle
	ldx	#0
 50$
	pla
	sta	r0,x
	inx
	cpx	#32
	bcc	50$
 80$
	rts

saveRecVec:
	.block	2


RstrDB:
	ldx	#31
 10$
	lda	r0,x
	pha
	dex
	bpl	10$
	bit	waveRunning
	bpl	40$
 30$
	jsr	ConvToCards
	LoadW	r0,#mColor
	jsr	RstrColor
 40$
	ldx	#0
 50$
	pla
	sta	r0,x
	inx
	cpx	#32
	bcc	50$
	bit	waveRunning
	bpl	85$
	jsr	RecoverRectangle
 85$
	MoveW	saveRecVec,RecoverVector
	rts

SvForeScreen:
	ldx	#31
 10$
	lda	r0,x
	pha
	dex
	bpl	10$
	bit	waveRunning
	bmi	20$
	jsr	LSaveTxtScreen
	bra	30$
 20$
	jsr	ImprintScreen
 30$
	ldx	#0
 50$
	pla
	sta	r0,x
	inx
	cpx	#32
	bcc	50$
	rts

RstrTerminal:
	ldx	#31
 10$
	lda	r0,x
	pha
	dex
	bpl	10$
	jsr	LRstrTxtScreen
	ldx	#0
 50$
	pla
	sta	r0,x
	inx
	cpx	#32
	bcc	50$
	rts

;this multiplies an 8 bit number with a 24 bit number.
JMult24:
	lda	#24
	sta	r8L
	lda	#0
 20$
	lsr	$02,x
	ror	$01,x
	ror	$00,x
	bcc	50$
	clc
	adc	$00,y
 50$
	ror	a
	ror	r7L
	ror	r6H
	ror	r6L
	dec	r8L
	bne	20$
	sta	r7H
	rts

;this multiplies an 8 bit number with a 32 bit number.
;the result is a 40 bit number in r6L-r8L. Bits 32-39
;are also left in the accumulator.
JMult32:
	lda	#32
	sta	r8L
	lda	#0
 20$
	lsr	$03,x
	ror	$02,x
	ror	$01,x
	ror	$00,x
	bcc	50$
	clc
	adc	$00,y
 50$
	ror	a
	ror	r7H
	ror	r7L
	ror	r6H
	ror	r6L
	dec	r8L
	bne	20$
	sta	r8L
	rts


JSysScrColor:
.if	C64
	lda	sysScrnColors
JColrR4H:
	sta	r4H
	rts
.else
	lda	sys80ScrnColors
JColrR4H:
	sta	r4H
	lsr	a
	ror	r4H
	lsr	a
	ror	r4H
	lsr	a
	ror	r4H
	lsr	a
	ror	r4H
	lda	r1H
	ora	#%10000000
	sta	r1H
	rts
.endif


JSetNxtDrive:
	ldx	drvCking
	inx
	cpx	#12
	bcc	50$
	rts
 50$
	.byte	44
JSet1stDrive:
	ldx	#8
 20$
	cpx	noCkDrv
	beq	30$
	lda	driveType-8,x
	beq	30$
	and	#%11110000
	bit	eorDrvType
	bpl	25$
	cmp	#TYPE_RL
	beq	50$
 25$
	eor	eorDrvType
	bpl	50$
 30$
	inx
	cpx	#12
	bcc	20$
	rts
 50$
	stx	drvCking
	clc
	rts

drvCking:
	.block	1
noCkDrv:
	.block	1
eorDrvType:
	.block	1


endResMod:

