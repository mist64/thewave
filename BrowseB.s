;************************************************************

;		BrowseB


;************************************************************



	.psect


;+++these need finishing.
DoBackPage:
	rts

DoFwdPage:
	rts

DoReLdPage:
	jsr	StopURLEditor
	jsr	SwpHREFURL
	LoadB	dloadFlag,#%00000000
	sta	urlBufPtr
	jmp	GetReqHTML

DoHistList:
	rts

StrtURLEditor:
	ldx	#0
	jmp	LURLEdFunction

StopURLEditor:
	bit	urlEdRunning
	bpl	90$
	php
	sei
	jsr	PromptOff
	LoadB	alphaFlag,#0
	sta	urlEdRunning
	plp
 90$
	rts

M_SvSource:
	jsr	GotoFirstMenu
	MoveB	htmlBank,a1L
	LoadB	a0L,#0
	sta	a0H
	jmp	SvHTMLBuffer

HTTPDownload:
	bit	onAnchor
	bmi	10$
	rts
 10$
	LoadB	dloadFlag,#%10000000
	jmp	GetReqHTML



BrowseKeys:
	lda	menuNumber
	beq	5$
	rts
 5$
	lda	keyData
	ldx	#0
 30$
	cmp	mkeyTable,x
	beq	70$
	inx
	cpx	#[(mKeyRoutines-mkeyTable)
	bcc	30$
	bit	onAnchor
	bpl	40$
	jmp	AnchorKeys
 40$
	bit	urlEdRunning
	bpl	50$
	jmp	URLEdKeys
 50$
	rts
 70$
	txa
	asl	a
	tax
;	jmp	(mKeyRoutines,x)
	.byte	$7c,[mKeyRoutines,]mKeyRoutines

mkeyTable:
	.byte	KEY_UP,KEY_DOWN,KEY_F3,KEY_F5
	.byte	KEY_F1,KEY_F7
mKeyRoutines:
	.word	KScrFUp,KScrFDown,KPageFUp,KPageFDown
	.word	KScr2Top,KScr2Bottom


AnchorKeys:
	lda	keyData
	ldx	#0
 30$
	cmp	akeyTable,x
	beq	40$
	inx
	cpx	#[(aKeyRoutines-akeyTable)
	bcc	30$
	rts
 40$
	txa
	asl	a
	tax
;	jmp	(aKeyRoutines,x)
	.byte	$7c,[aKeyRoutines,]aKeyRoutines

akeyTable:
	.byte	"d"
aKeyRoutines:
	.word	HTTPDownload

URLEdKeys:
	lda	keyData
	cmp	#32
	bcc	20$
	cmp	#127
	bcs	20$
	ldx	#2
	jmp	LURLEdFunction
 20$
	cmp	#CR
	bne	30$
	jmp	DoReLdPage
 30$
	ldx	#4
	jmp	LURLEdFunction


KScr2Top:
	jsr	CkOnAnchor
	jsr	Scr2Top
	jmp	CkVsblAnchors

Scr2Top:
	jsr	StopURLEditor
	LoadB	curPageTop+0,#0
	sta	curPageTop+1
	sta	curPageTop+2
	jsr	CalcCPBottom
.if	C128
	jsr	TempHideMouse
.endif
	jsr	JFetchFSegment
	jmp	ReStrtSBar

KScr2Bottom:
	jsr	CkOnAnchor
	jsr	Scr2Bottom
	jmp	CkVsblAnchors

Scr2Bottom:
	jsr	StopURLEditor
	jsr	MoveECPg
.if	C128
	jsr	TempHideMouse
.endif
	jsr	JFetchFSegment
	jmp	ReStrtSBar


.if	C64
KPageFDown:
	lda	frmHeight
	sec
	sbc	#8
	.byte	44
KScrFDown:
	lda	#8
	pha
	jsr	CkOnAnchor
	pla
	jsr	SFD2
	jmp	CkVsblAnchors

PageFDown:
	lda	frmHeight
	sec
	sbc	#8
	.byte	44
ScrFDown:
	lda	#8
SFD2:
	sta	r0L
	jsr	StopURLEditor
	jsr	CmpCEPg
	bcc	30$
	bne	50$
	rts
 30$
	lda	r0L
	jsr	Add2CurPg
	jsr	CmpCEPg
	bcc	60$
 50$
	jsr	MoveECPg
 60$
	jsr	JFetchFSegment
	jmp	ReStrtSBar


KPageFUp:
	lda	frmHeight
	sec
	sbc	#8
	.byte	44
KScrFUp:
	lda	#8
	pha
	jsr	CkOnAnchor
	pla
	jsr	SFU2
	jmp	CkVsblAnchors

PageFUp:
	lda	frmHeight
	sec
	sbc	#8
	.byte	44
ScrFUp:
	lda	#8
SFU2:
	sta	r0L
	jsr	StopURLEditor
	lda	curPageTop+2
	ora	curPageTop+1
	bne	60$
	lda	curPageTop+0
	bne	50$
	rts
 50$
	cmp	r0L
	bcs	60$
	LoadB	curPageTop+0,#0
	jsr	CalcCPBottom
	jsr	JFetchFSegment
	jmp	ReStrtSBar
 60$
	jsr	SbcR0LCPg
	jsr	JFetchFSegment
	jmp	ReStrtSBar


JFetchFSegment:
	ldx	#r0
	jsr	CalcPgTop
	bcc	90$
	LoadW	r1,#$a000+(40*40)
	LoadB	r4L,#20
	LoadB	r3H,#0
	stx	r3L
 20$
	jsr	GetSegment
	bcc	90$
	AddVW	#320,r1
	clc
	lda	r0L
	adc	#[312
	sta	r0L
	lda	r0H
	adc	#]312
	sta	r0H
	ora	r0L
	bne	50$
	ldx	r3L
	jsr	GetNxtBank
	bcc	90$
	stx	r3L
 50$
	dec	r4L
	bne	20$
 90$
	rts


GetSegment:
	CmpWI	r0,#(-311)
	bcs	20$
	jsr	DoSuperMove
	sec
	rts
 20$
	PushW	r1
	PushB	r0H
	sta	r2H
	PushB	r0L
	sta	r2L
	ldx	#r2
	jsr	Dabs
	jsr	DoSuperMove
	clc
	lda	r1L
	adc	r2L
	sta	r1L
	lda	r1H
	adc	r2H
	sta	r1H
	sec
	lda	#[312
	sbc	r2L
	sta	r2L
	lda	#]312
	sbc	r2H
	sta	r2H
	ldx	r3L
	jsr	GetNxtBank
	bcc	90$
	stx	r3L
	LoadB	r0L,#0
	sta	r0H
	jsr	DoSuperMove
	sec
 90$
	PopW	r0
	PopW	r1
	LoadW	r2,#312
	rts


CalcPgTop:
	lda	curPageTop+0
	and	#%11111000
	sta	$00,x
	lda	curPageTop+1
	sta	$01,x
	lda	curPageTop+2
	sta	$02,x
	LoadB	r2H,#39
	ldy	#r2H
	jsr	Mult24
	lda	r6L
	sta	$00,x
	lda	r6H
	sta	$01,x
	ldx	pageBank
	lda	r7L
	beq	60$
 20$
	jsr	GetNxtBank
	bcc	90$
	dec	r7L
	bne	20$
 60$
	LoadW	r2,#312
	sec
	rts
 90$
	clc
	rts

.endif

.if	C128

KPageFDown:
	jsr	CkOnAnchor
	jsr	PageFDown
	jmp	CkVsblAnchors

PageFDown:
	jsr	StopURLEditor
	lda	frmHeight
	sec
	sbc	#8
	jsr	CanGoDown
	bcs	50$
	rts
 50$
	jsr	OTempHideMouse
	jsr	JFetchFSegment
	jmp	ReStrtSBar

KPageFUp:
	jsr	CkOnAnchor
	jsr	PageFUp
	jmp	CkVsblAnchors

PageFUp:
	jsr	StopURLEditor
	lda	frmHeight
	sec
	sbc	#8
	jsr	CanGoUp
	bcs	50$
	rts
 50$
	jsr	OTempHideMouse
	jsr	JFetchFSegment
	jmp	ReStrtSBar


KScrFDown:
	jsr	CkOnAnchor
	jsr	ScrFDown
	jmp	CkVsblAnchors

ScrFDown:
	jsr	StopURLEditor
	lda	#8
	jsr	CanGoDown
	bcs	50$
	rts
 50$
	jsr	OTempHideMouse
	jsr	CmpCEPg
	bne	60$
	jsr	JFetchFSegment
	jmp	ReStrtSBar
 60$
	jsr	ScrUpScreen
	jmp	ReStrtSBar

KScrFUp:
	jsr	CkOnAnchor
	jsr	ScrFUp
	jmp	CkVsblAnchors

ScrFUp:
	jsr	StopURLEditor
	lda	#8
	jsr	CanGoUp
	bcs	50$
	rts
 50$
	jsr	OTempHideMouse
	lda	curPageTop+0
	ora	curPageTop+1
	ora	curPageTop+2
	bne	60$
	jsr	JFetchFSegment
	jmp	ReStrtSBar
 60$
	jsr	ScrDnScreen
	jmp	ReStrtSBar


CanGoDown:
	sta	r0L
	jsr	CmpCEPg
	bcc	20$
	bne	50$
	clc
	rts
 20$
	lda	r0L
	jsr	Add2CurPg
	jsr	CmpCEPg
	bcc	60$
 50$
	jsr	MoveECPg
 60$
	sec
	rts

CanGoUp:
	sta	r0L
	lda	curPageTop+2
	ora	curPageTop+1
	bne	60$
	lda	curPageTop+0
	bne	50$
	clc
	rts
 50$
	cmp	r0L
	bcs	60$
	LoadB	curPageTop+0,#0
	jsr	CalcCPBottom
	sec
	rts
 60$
	jsr	SbcR0LCPg
	sec
	rts


JFetchFSegment:
	ldx	#r1
	jsr	CalcPgTop
	stx	r2L
	LoadW	r0,#(40*80)
	LoadB	r13L,#20
 20$
	jsr	Fill8Rasters
	bcc	90$
	dec	r13L
	bne	20$
 90$
	rts

ScrUpScreen:
	LoadW	r1,#(40*80)
	LoadW	r0,#(48*80)
	ldx	#24
	jsr	ReadReg
	pha
	ora	#%10000000
	jsr	WriteReg
	LoadB	r13H,#152
 10$
	ldx	#18
	lda	r1H
	jsr	WriteReg
	inx
	lda	r1L
	jsr	WriteReg
	ldx	#32
	lda	r0H
	jsr	WriteReg
	inx
	lda	r0L
	jsr	WriteReg
	lda	#78
	ldx	#30
	jsr	WriteReg
	AddVW	#80,r0
	AddVW	#80,r1
	dec	r13H
	bne	10$
	ldx	#24
	pla
	jsr	WriteReg
;fall through...
;FetchBotRow:
	ldx	#r1
	jsr	CalcPgTop
	stx	r2L
	clc
	lda	r1L
	adc	#[(152*78)
	sta	r1L
	lda	r1H
	adc	#](152*78)
	sta	r1H
	bcc	50$
	jsr	GetNxtBank
	bcs	40$
	rts
 40$
	stx	r2L
 50$
	LoadW	r0,#(192*80)
	jmp	Fill8Rasters

ScrDnScreen:
	LoadW	r0,#(191*80)
	LoadW	r1,#(199*80)
	ldx	#24
	jsr	ReadReg
	pha
	ora	#%10000000
	jsr	WriteReg
	LoadB	r13H,#152
 10$
	ldx	#18
	lda	r1H
	jsr	WriteReg
	inx
	lda	r1L
	jsr	WriteReg
	ldx	#32
	lda	r0H
	jsr	WriteReg
	inx
	lda	r0L
	jsr	WriteReg
	lda	#78
	ldx	#30
	jsr	WriteReg
	SubVW	#80,r0
	SubVW	#80,r1
	dec	r13H
	bne	10$
	ldx	#24
	pla
	jsr	WriteReg
;fall through...
;+++fix for 64K+
;FetchTopRow:
	ldx	#r1
	jsr	CalcPgTop
	stx	r2L
	LoadW	r0,#(40*80)
	jmp	Fill8Rasters


CalcPgTop:
	lda	curPageTop+0
	and	#%11111000
	sta	$00,x
	lda	curPageTop+1
	sta	$01,x
	lda	curPageTop+2
	sta	$02,x
	LoadB	r2H,#78
	ldy	#r2H
	jsr	Mult24
	lda	r6L
	sta	$00,x
	lda	r6H
	sta	$01,x
	ldx	pageBank
	lda	r7L
	beq	60$
 20$
	jsr	GetNxtBank
	bcc	90$
	dec	r7L
	bne	20$
 60$
	sec
 90$
	rts

Fill8Rasters:
	LoadB	r12H,#78
	LoadB	r13H,#8
 10$
	CmpWI	r1,#(-77)
	bcc	40$
	jsr	SplitRasters
	bcs	75$
	rts
 40$
	jsr	FillRaster
	clc
	lda	r1L
	adc	#78
	sta	r1L
	bcc	75$
	inc	r1H
	bne	75$
	ldx	r2L
	jsr	GetNxtBank
	bcc	90$
	stx	r2L
 75$
	AddVW	#80,r0
	dec	r13H
	bne	10$
	sec
 90$
	rts

FillRaster:
	ldx	#18
	stx	$d600
	lda	r0H
 5$
	bit	$d600
	bpl	5$
	sta	$d601
	inx
	stx	$d600
	lda	r0L
 10$
	bit	$d600
	bpl	10$
	sta	$d601
	ldx	#31
	stx	$d600
	ldy	#0
 20$
;	lda	[r1],y
	.byte	$b7,r1
 30$
	bit	$d600
	bpl	30$
	sta	$d601
	iny
	cpy	r12H
	bcc	20$
	rts


SplitRasters:
	PushW	r0
	MoveW	r1,r3
	ldx	#r3
	jsr	Dabs
	MoveB	r3L,r12H
	jsr	FillRaster
	clc
	lda	r0L
	adc	r3L
	sta	r0L
	lda	r0H
	adc	r3H
	sta	r0H
	sec
	lda	#[78
	sbc	r12H
	sta	r12H
	ldx	r2L
	jsr	GetNxtBank
	bcc	90$
	stx	r2L
	LoadB	r1L,#0
	sta	r1H
	jsr	FillRaster
	MoveB	r12H,r1L
	sec
 90$
	PopW	r0
	LoadB	r12H,#78
	rts

.endif


CmpCEPg:
	lda	curPageTop+2
	cmp	endPageTop+2
	bne	10$
	lda	curPageTop+1
	cmp	endPageTop+1
	bne	10$
	lda	curPageTop+0
	cmp	endPageTop+0
 10$
	rts

MoveECPg:
	MoveW	endPageTop,curPageTop
	MoveB	endPageTop+2,curPageTop+2
;fall through...
CalcCPBottom:
	lda	frmHeight
	dea
	clc
	adc	curPageTop+0
	sta	curPageBottom+0
	lda	curPageTop+1
	adc	#0
	sta	curPageBottom+1
	lda	curPageTop+2
	adc	#0
	sta	curPageBottom+2
	rts

Add2CurPg:
	clc
	adc	curPageTop+0
	sta	curPageTop+0
	bcc	35$
	inc	curPageTop+1
	bne	35$
	inc	curPageTop+2
 35$
	jmp	CalcCPBottom

SbcR0LCPg:
	sec
	lda	curPageTop+0
	sbc	r0L
	sta	curPageTop+0
	bcs	65$
	lda	curPageTop+1
	sbc	#0
	sta	curPageTop+1
	lda	curPageTop+2
	sbc	#0
	sta	curPageTop+2
 65$
	jmp	CalcCPBottom

StartSBar:
	LoadB	mainSBTable,#0
	MoveB	endPageTop+0,r1H
	MoveB	endPageTop+1,r2L
	lda	endPageTop+2
	ldx	#3
 10$
	lsr	a
	ror	r2L
	ror	r1H
	dex
	bne	10$
	sta	mainSBTable+11
	MoveB	r1H,mainSBTable+9
	MoveB	r2L,mainSBTable+10
	jsr	CurPgBy8
	MoveB	r1H,mainSBTable+12
	MoveB	r2L,mainSBTable+13
	MoveB	r2H,mainSBTable+14
	lda	mainSBTable+9
	ora	mainSBTable+10
	ora	mainSBTable+11
	beq	20$
	LoadB	mainSBTable+0,#%10000000
 20$
	jsr	LCurFrDimensions
	MoveB	r2L,mainSBTable+1
	sec
	lda	r2H
	sbc	#16
	sta	mainSBTable+2
	ina
	sta	mainSBTable+8
	lda	r5L
	lsr	a
	lsr	a
	lsr	a
	sta	mainSBTable+15
	sec
	MoveB	r4L,mainSBTable+5
.if	C64
	sbc	#7
.else
	sbc	#15
.endif
	sta	mainSBTable+3
	sta	r4L
	MoveB	r4H,mainSBTable+6
	sbc	#0
	sta	mainSBTable+4
	sta	r4H
	lda	r4L
	lsr	r4H
	ror	a
	lsr	r4H
	ror	a
	lsr	r4H
	ror	a
	sta	mainSBTable+7
	LoadW	r0,#mainSBTable
	jmp	InitScrBar

ReStrtSBar:
	jsr	CurPgBy8
	jmp	PosScrBar

CurPgBy8:
	MoveB	curPageTop+0,r1H
	MoveB	curPageTop+1,r2L
	lda	curPageTop+2
	ldx	#3
 10$
	lsr	a
	ror	r2L
	ror	r1H
	dex
	bne	10$
	sta	r2H
	rts

mainSBTable:
	.block	1	;bit 7 set means to draw the scrollbar.
			;if cleared, then clear the scrollbar.
	.byte	40	;top of scrollbar area.
	.byte	183	;bottom of scrollbar area.
.if	C64
	.word	312
	.word	319
	.byte	39	;card position for scroll arrows.
.else
	.word	624
	.word	639
	.byte	78	;card position for scroll arrows.
.endif
	.byte	184	;top pixel position for scroll arrows.
	.block	3	;endPageTop/8
	.block	3	;curPageTop/8
	.byte	21	;usable screen height/8
	.word	RePosPage	;called if scrollbar clicked and moved.
	.word	PageFUp	;routine if click above scrollbar.
	.word	PageFDown	;routine if click below scrollbar.
	.word	ScrFUp	;routine if up arrow clicked.
	.word	ScrFDown	;routine if down arrow clicked.
	.word	AnchorWatch	;routine to call if scrollbar isn't clicked
			;on during appMain.
	.word	CkVsblAnchors	;routine to call after scrollbar was clicked on.

RePosPage:
	jsr	StopURLEditor
	ldx	#3
	lda	r6L
 10$
	asl	a
	rol	r6H
	rol	r7L
	dex
	bne	10$
	sta	r6L
	cmp	curPageTop+0
	bne	20$
	lda	r6H
	cmp	curPageTop+1
	bne	20$
	lda	r7L
	cmp	curPageTop+2
	bne	20$
	rts
 20$
	MoveB	r6L,curPageTop+0
	MoveB	r6H,curPageTop+1
	MoveB	r7L,curPageTop+2
	jsr	CalcCPBottom
	jsr	CmpCEPg
	bcc	50$
	jsr	MoveECPg
 50$
	jmp	JFetchFSegment


AnchorWatch:
	lda	menuNumber
	beq	10$
 5$
	rts
 10$
;	jsr	CkVsblAnchors
	lda	numAnchors
	beq	5$
	bit	onAnchor
	bpl	12$
	jsr	CkOffAnchor
	beq	5$
	jsr	CkOnAnchor
 12$
	LoadW	r10,#anchorRam
	lda	#0
 15$
	pha
	ldy	#5
 30$
	lda	(r10),y
	sta	r2,y
	dey
	bpl	30$
	jsr	IsMseInRegion
	cmp	#[TRUE
	beq	40$
	AddVW	#9,r10
	pla
	ina
	cmp	numAnchors
	bcc	15$
	rts
 40$
	pla

;fall through to next page...

;previous page continues here.
AW2:
	ldx	#5
 5$
	lda	r2,x
	sta	cAnchorRam,x
	dex
	bpl	5$
	ldy	#6
	sty	cAncPtr
 10$
	lda	(r10),y
	sta	actLinkPtr-6,y
	iny
	cpy	#9
	bcc	10$
	LoadB	onAnchor,#%10000000
	jsr	InvertRectangle
	MoveB	urlEdRunning,onAncEdRunning
	bpl	20$
	jsr	StopURLEditor
 20$
	lda	numAnchors
	cmp	#1
	beq	60$
	LoadW	r10,#anchorRam
	lda	#0
 25$
	pha
	ldy	#8
 30$
	lda	(r10),y
	cmp	actLinkPtr-6,y
	bne	50$
	dey
	cpy	#6
	bcs	30$
 35$
	lda	(r10),y
	cmp	cAnchorRam,y
	bne	38$
	dey
	bpl	35$
	bmi	50$
 38$
	ldx	cAncPtr
	ldy	#0
 40$
	lda	(r10),y
	sta	cAnchorRam,x
	sta	r2,y
	inx
	iny
	cpy	#6
	bcc	40$
	stx	cAncPtr
	PushW	r10
	jsr	InvertRectangle
	PopW	r10
 50$
	AddVW	#9,r10
	pla
	ldx	cAncPtr
	cpx	#60
	bcs	60$
	ina
	cmp	numAnchors
	bcc	25$
 60$
	MoveW	actLinkPtr,r1H
	MoveB	actLinkPtr+2,r2H
	LoadW	r0,#hrefString
	MoveB	prg2Bank,r1L
	ldy	#0
 70$
;	lda	[r1H],y
	.byte	$b7,r1H
;	sta	[r0],y
	.byte	$97,r0
	beq	75$
	iny
	bne	70$
	lda	#0
	dey
;	sta	[r0],y
	.byte	$97,r0
 75$
	jmp	LPutURLString

cAncPtr:
	.block	1
onAncEdRunning:
	.block	1

CkOffAnchor:
	ldx	#5
 40$
	lda	cAnchorRam,x
	sta	r2,x
	dex
	bpl	40$
	jsr	IsMseInRegion
	cmp	#[TRUE
	rts

CkOnAnchor:
	lda	#%00000000
	.byte	44
CkOnNAnchor:
	lda	#%10000000
	sta	noURLBar
	bit	onAnchor
	bmi	30$
	clc
	rts
 30$
	ldx	#0
 35$
	ldy	#0
 40$
	lda	cAnchorRam,x
	sta	r2,y
	inx
	iny
	cpy	#6
	bcc	40$
	phx
	jsr	InvertRectangle
	plx
	cpx	cAncPtr
	bcc	35$
	LoadB	onAnchor,#0
	bit	noURLBar
	bmi	80$
	jsr	LDoURLBar
 80$
	bit	onAncEdRunning
	bpl	85$
	jsr	StrtURLEditor
 85$
	sec
	rts

noURLBar:
	.block	1
onAnchor:
	.block	1
numAnchors:
	.block	1
ancTablePtr:
	.block	2
actLinkPtr:
	.block	3

CkVsblAnchors:
	jsr	LGetCurFrame
	LoadB	numAnchors,#0
	LoadW	r10,#anchorRam
	MoveB	anchorBank,r1L
	LoadB	r0L,#0
	sta	r0H
 10$
	ldy	#13
;	lda	[r0],y
	.byte	$b7,r0	;is this a NAME anchor?
	bmi	60$	;branch if so.
	ldy	#3
;	lda	[r0],y
	.byte	$b7,r0
	iny
;	ora	[r0],y
	.byte	$17,r0
	iny
;	ora	[r0],y
	.byte	$17,r0
	beq	90$	;branch if empty spot.
	jsr	IsAncVisible
	bcc	60$
	ldy	#5
 20$
	lda	r2,y
	sta	(r10),y
	dey
	bpl	20$
	SubVW	#4,r10
	ldy	#10
 30$
;	lda	[r0],y
	.byte	$b7,r0
	sta	(r10),y
	iny
	cpy	#13
	bcc	30$
	AddVW	#13,r10
	inc	numAnchors
 60$
	clc
	lda	r0L
	adc	#16
	sta	r0L
	bcc	10$
	inc	r0H
	bne	10$
 90$
	rts


;point r0 (24bit) to an anchor table in anchorBank
;and this will check if it's currently visible on
;the screen. And if so, r2L,r2H,r3,and r4 will surround
;the area of the screen where the anchor is.
IsAncVisible:
	ldy	#5
;	lda	[r0],y
	.byte	$b7,r0
	cmp	curPageTop+2
	bne	10$
	dey
;	lda	[r0],y
	.byte	$b7,r0
	cmp	curPageTop+1
	bne	10$
	dey
;	lda	[r0],y
	.byte	$b7,r0
	cmp	curPageTop+0
 10$
	bcs	20$
 15$
	rts		;carry is clear.
 20$
	ldy	#2
	lda	curPageBottom+2
;	cmp	[r0],y
	.byte	$d7,r0
	bne	25$
	dey
	lda	curPageBottom+1
;	cmp	[r0],y
	.byte	$d7,r0
	bne	25$
	dey
	lda	curPageBottom+0
;	cmp	[r0],y
	.byte	$d7,r0
 25$
	bcc	15$
	ldy	#0
;	lda	[r0],y
	.byte	$b7,r0
	sbc	curPageTop+0
	sta	r2L
	iny
;	lda	[r0],y
	.byte	$b7,r0
	sbc	curPageTop+1
	iny
;	lda	[r0],y
	.byte	$b7,r0
	sbc	curPageTop+2
	lda	frmTop
	bcc	30$
	clc
	adc	r2L

 30$
	sta	r2L
	cmp	frmBottom
	beq	35$
	bcc	35$
	clc
	rts
 35$
	sec
	ldy	#3
;	lda	[r0],y
	.byte	$b7,r0
	sbc	curPageTop+0
	sta	r2H
	iny
;	lda	[r0],y
	.byte	$b7,r0
	sbc	curPageTop+1
	bne	40$
	iny
;	lda	[r0],y
	.byte	$b7,r0
	sbc	curPageTop+2
	bne	40$
	lda	r2H
	cmp	frmHeight
	bcc	50$
 40$
	lda	frmHeight
	dea
 50$
	clc
	adc	frmTop
	sta	r2H
	ldy	#6
	ldx	#0
 60$
;	lda	[r0],y
	.byte	$b7,r0
	sta	r3,x
	iny
	inx
	cpx	#4
	bcc	60$
	rts		;carry is set.

RunStartup:
	jsr	OpenPrgDir
	jsr	LReadInDirectory
	LoadW	r1,#reqFileName
	LoadW	r6,#stupName
	ldx	#r6
	ldy	#r1
	jsr	CopyString
	LoadB	r7L,#0
	jsr	LFindLFile
	txa
	bne	90$
	jmp	RHTML2
 90$
	LoadB	urlBufPtr,#0
	jsr	LDoURLBar	;ignore error if START file not found.
	clc
	rts

RunHTML:
	PushW	r6
	jsr	LReadInDirectory
	PopW	r6
	LoadB	r7L,#0
	jsr	LFindLFile
	txa
	beq	RHTML2
	phx
	LoadB	urlBufPtr,#0
	jsr	LDoURLBar
	plx
	jsr	DoDiskError
	clc
	rts
RHTML2:
	jsr	ClearBWindow
	ldx	#4	;make this the url directory.
	jsr	SetNewDir
	LoadB	pageLoaded,#%00000000
	jsr	FullURLBar
	LoadB	keyVector+0,#0
	sta	keyVector+1
	ldx	htmlBank
	jsr	FreeNClear
	ldx	watchMOffset
	jsr	RemvMnRoutine
	LoadB	watchMOffset,#0
	ldx	pageBank
	jsr	FreeNClear
	ldx	anchorBank
	jsr	FreeNClear
	ldx	linkBank
	jsr	FreeNClear
	ldx	#0
	jsr	BrowseMsg
	jsr	OpenURLDir
	MoveB	htmlBank,a1L
	jsr	InitHTMBank
	jsr	LoadAscii
	jsr	FixHTMBank
	lda	pageLoaded
	ora	#%10000000
	sta	pageLoaded
	jsr	OpenPrgDir
	jsr	ClrMsgBox
	LoadB	dloadFlag,#%00000000
	jsr	LParseHTML
	jsr	OpenURLDir
	LoadB	curPageTop+0,#0
	sta	curPageTop+1
	sta	curPageTop+2
	jsr	CalcCPBottom
	sec
	rts

FreeNClear:
	phx
	jsr	FreeBnkChain
	plx
	jmp	ClearBank


stupName:
.if	C64
	.byte	"START64.HTML",0
.else
	.byte	"START128.HTML",0
.endif

InitHTMBank:
	MoveB	a1L,htmInitString+4
	LoadB	a0L,#0
	sta	a0H
	ldy	#0
 10$
	lda	htmInitString,y
;	sta	[a0],y
	.byte	$97,a0
	iny
	cpy	#8
	bcc	10$
	sty	a0L
	rts

FixHTMBank:
	PushB	a1L
	PushB	a0H
	PushB	a0L
	MoveB	htmInitString+4,a1L
	LoadB	a0L,#0
	sta	a0H
	ldy	#2
 10$
	pla
;	sta	[a0],y
	.byte	$97,a0
	iny
	cpy	#5
	bcc	10$
	ldx	#0
 20$
	lda	htmlSize,x
;	sta	[a0],y
	.byte	$97,a0
	iny
	inx
	cpx	#3
	bcc	20$
	rts

htmInitString:
	.byte	8,0,8,0,3,0,0,0 ;the fifth one changes.

M_DoAsciiTerm:
	jsr	GotoFirstMenu
DoAsciiTerm:
	lda	waveRunning
	and	#%10111111
	sta	waveRunning	;indicate a transition is taking place.
	jsr	SvBrwsVectors
	ldx	watchMOffset
	jsr	RemvMnRoutine
	LoadB	watchMOffset,#0
	ldx	flushOffset
	jsr	RemvMnRoutine
	LoadB	flushOffset,#0
	sta	flushRunning
	lda	#3
	jmp	JmpModBase

M_ISPDir:
	jsr	GotoFirstMenu
	jsr	ISPDir
	bcc	90$
	bit	manualLogin
	bmi	50$
	sec
	rts
 50$
	lda	waveRunning
	ora	#%00100000
	sta	waveRunning
	jmp	DoAsciiTerm
 90$
	jsr	DefSLSettings
	clc
	rts

StartInet:
	jsr	BeginISP
	bcc	45$
	jsr	LDialOut
	bcc	45$
	bit	manualLogin
	bmi	50$
	sec
 45$
	rts
 50$
	lda	waveRunning
	ora	#%00100000
	sta	waveRunning
	jmp	DoAsciiTerm


MGetAnyFile:
	jsr	GotoFirstMenu
	jsr	SvBrwsVectors
	jsr	OpenURLDir
	jsr	GetAnyFile
	bne	10$
	jmp	RstBrwsVectors
 10$
	jsr	ClearBWindow
	jsr	R6ReqFileName
	jsr	RunHTML
	jmp	ShowPage

R6ReqFileName:
	LoadW	r6,#reqFileName
	rts

M_ExitWave:
	jsr	GotoFirstMenu
	jsr	StopURLEditor
	jmp	ExitWave

M_RunApp:
	jsr	GotoFirstMenu
	jsr	SvBrwsVectors
	jsr	DoApplication
	jmp	RstBrwsVectors

M_RunDA:
	jsr	GotoFirstMenu
	jsr	SvBrwsVectors
	jsr	SaveSRamVars
	jsr	DoDeskAccessories
	bcs	50$
	rts
 50$
	jmp	JReStartBrowser

