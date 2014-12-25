;*****************************************
;
;
;	Parse4HTM
;
;	routines called when an HTML
;	tag is encountered while parsing the
;	HTML document.
;
;*****************************************


	.psect


TOList:
	jsr	FlushText
	jsr	Scroll3Pixels
	bit	tagMode
	bmi	30$
	lda	listMode
	ldx	#3
	jsr	PushStack
	LoadB	listMode,#2
	lda	olNumber
	ldx	#3
	jsr	PushStack
	LoadB	olNumber,#1
	lda	globalJust
	ldx	#3
	jsr	PushStack
	LoadB	globalJust,#0
	sta	justification
	jsr	L3GMarg2Stack
	jmp	Add6LMargin
 30$
	lda	listMode
	and	#%00111111
	cmp	#2
	bne	90$
	jsr	Stk3ToLMarg
	ldx	#3
	jsr	PullStack
	sta	globalJust
	sta	justification
	ldx	#3
	jsr	PullStack
	sta	olNumber
	ldx	#3
	jsr	PullStack
	sta	listMode
 90$
	rts

TUList:
	jsr	FlushText
	jsr	Scroll3Pixels
	bit	tagMode
	bmi	30$
	lda	listMode
	ldx	#3
	jsr	PushStack
	LoadB	listMode,#1
	lda	globalJust
	ldx	#3
	jsr	PushStack
	LoadB	globalJust,#0
	sta	justification
	jsr	L3GMarg2Stack
	jmp	Add6LMargin
 30$
	lda	listMode
	and	#%00111111
	cmp	#1
	bne	90$
	jsr	Stk3ToLMarg
	ldx	#3
	jsr	PullStack
	sta	globalJust
	sta	justification
	ldx	#3
	jsr	PullStack
	sta	listMode
 90$
	rts


L3GMarg2Stack:
	ldx	#3
	.byte	44
L5GMarg2Stack:
	ldx	#5
	.byte	44
L6GMarg2Stack:
	ldx	#6
	phx
	lda	gLeftMargin+0
	jsr	PushStack
	plx
	lda	gLeftMargin+1
	jmp	PushStack

R5GMarg2Stack:
	ldx	#5
	.byte	44
R6GMarg2Stack:
	ldx	#6
	phx
	lda	gRightMargin+0
	jsr	PushStack
	plx
	lda	gRightMargin+1
	jmp	PushStack


Stk3ToLMarg:
	ldx	#3
	.byte	44
Stk5ToLMarg:
	ldx	#5
	.byte	44
Stk6ToLMarg:
	ldx	#6
	phx
	jsr	PullStack
	sta	leftMargin+1
	sta	gLeftMargin+1
	plx
	jsr	PullStack
	sta	leftMargin+0
	sta	gLeftMargin+0
;fall through...
LMargToString:
	ldy	textStrPtr
	lda	#ESC_LMARGIN
	sta	textString,y
	iny
	lda	leftMargin+0
	sta	textString,y
	iny
	lda	leftMargin+1
	sta	textString,y
	iny
	sty	textStrPtr
	jmp	GetMrgnWidth


Stk5ToRMarg:
	ldx	#5
	.byte	44
Stk6ToRMarg:
	ldx	#6
	phx
	jsr	PullStack
	sta	rightMargin+1
	sta	gRightMargin+1
	plx
	jsr	PullStack
	sta	rightMargin+0
	sta	gRightMargin+0
;fall through...
RMargToString:
	ldy	textStrPtr
	lda	#ESC_RMARGIN
	sta	textString,y
	iny
	lda	rightMargin+0
	sta	textString,y
	iny
	lda	rightMargin+1
	sta	textString,y
	iny
	sty	textStrPtr
	jmp	GetMrgnWidth

Add6LMargin:
	ldy	textStrPtr
	lda	#ESC_LMARGIN
	sta	textString,y
	iny
	clc
	lda	gLeftMargin+0
	adc	#6
	sta	gLeftMargin+0
	sta	leftMargin+0
	sta	textString,y
	lda	gLeftMargin+1
	adc	#0
	iny
	sta	gLeftMargin+1
	sta	leftMargin+1
	sta	textString,y
	iny
	sty	textStrPtr
	jmp	GetMrgnWidth

TList:
	bit	tagMode
	bmi	90$
	jsr	FlushText
	lda	listMode
	and	#%00111111
	beq	90$
	cmp	#3
	bcs	90$
	jsr	L3GMarg2Stack
	lda	listMode
	ora	#%11000000
	sta	listMode
	and	#%00111111
	cmp	#2
	bne	40$
	lda	olNumber
	inc	olNumber
	jsr	Bin2TextString
	lda	#'.'
	jsr	PutOurChar
	bra	50$
 40$
	lda	#183	;middot character.
	jsr	PutOurChar
 50$
	lda	#' '
	jsr	PutOurChar
	LoadB	textInString,#%00000000
	lda	#ESC_LSTMARGIN
	ldy	textStrPtr
	sta	textString,y
	inc	textStrPtr
 90$
	rts


TDList:
	jsr	FlushText
	jsr	Scroll3Pixels
	bit	tagMode
	bmi	30$
	lda	listMode
	ldx	#3
	jsr	PushStack
	LoadB	listMode,#3
	rts
 30$
	lda	listMode
	and	#%00111111
	cmp	#3
	bne	90$
	bit	listMode
	bpl	40$
	jsr	Stk3ToLMarg
	ldx	#3
	jsr	PullStack
	sta	globalJust
	sta	justification
 40$
	ldx	#3
	jsr	PullStack
	sta	listMode
 90$
	rts

TDTerm:
	bit	tagMode
	bmi	90$
	jsr	FlushText
	lda	listMode
	and	#%00111111
	cmp	#3
	bne	90$
	bit	listMode
	bpl	50$
	bvc	90$
	jsr	Stk3ToLMarg
	ldx	#3
	jsr	PullStack
	sta	globalJust
	sta	justification
 50$
	lda	globalJust
	ldx	#3
	jsr	PushStack
	jsr	L3GMarg2Stack
	LoadB	listMode,#(128|3)
 90$
	rts


TDDefinition:
	bit	tagMode
	bmi	90$
	jsr	FlushText
	lda	listMode
	and	#%00111111
	cmp	#3
	bne	90$
	bit	listMode
	bpl	40$
	bvs	90$
	bvc	50$
 40$
	lda	globalJust
	ldx	#3
	jsr	PushStack
	jsr	L3GMarg2Stack
 50$
	jsr	Add6LMargin
	LoadB	listMode,#(128|64|3)
 90$
	rts


Bin2TextString:
	ldx	#0
 10$
	cmp	#100
	bcc	20$
	inx
	sec
	sbc	#100
	bcs	10$
 20$
	stx	binAscString+0
	ldx	#0
 30$
	cmp	#10
	bcc	40$
	inx
	sec
	sbc	#10
	bcs	30$
 40$
	stx	binAscString+1
	sta	binAscString+2
	lda	binAscString+0
	beq	50$
	clc
	adc	#'0'
	jsr	PutOurChar
 50$
	lda	binAscString+1
	bne	60$
	cmp	binAscString+0
	beq	70$
 60$
	clc
	adc	#'0'
	jsr	PutOurChar
 70$
	lda	binAscString+2
	clc
	adc	#'0'
	jmp	PutOurChar

binAscString:
	.block	3


TTable:
	jsr	FlushText
	bit	tagMode
	bpl	40$
	bit	tableMode
	bmi	50$
	rts
 40$
	jsr	Scroll3Pixels
	lda	globalJust
	ldx	#6
	jsr	PushStack
	lda	currentMode
	ldx	#6
	jsr	PushStack
	jsr	L6GMarg2Stack
	jsr	R6GMarg2Stack
	jsr	SaveTblRegs
	inc	curTable
	jsr	GetTblDimensions
	LoadB	tableMode,#%10000000
	LoadB	currentMode,#0
	sta	globalJust
	sta	justification
	sta	trMode
	sta	tdMode
	LoadB	tblClmCounter,#255
	jmp	SetTopBottom
 50$
	jsr	TTD2
	bit	trMode
	bpl	60$
	jsr	TTR3
 60$
	jsr	StashBSegment
	PushW	tableRight
	dec	curTable
	jsr	RstrTblRegs
	jsr	Stk6ToRMarg
	jsr	Stk6ToLMarg
	ldx	#6
	jsr	PullStack
	sta	currentMode
	ldx	#6
	jsr	PullStack
	sta	globalJust
	sta	justification
	lda	tdMode
	beq	85$
	lda	tblClmCounter
	asl	a
	tay
	rep	%00100000
	pla
	cmp	maxCellRight
	bcc	80$
	sta	maxCellRight
	sta	rightMargin
	sta	gRightMargin
	sep	%00100000
	jsr	RMargToString
	LoadB	textInString,#%10000000
 80$
	sep	%00100000
	jsr	PutStyle
	jmp	FixRowBottom
 85$
	pla
	pla
	jsr	PutStyle
	jmp	FixRowBottom

GetTblDimensions:
	lda	globalJust
	cmp	#3
	bcc	10$
	lda	#0
 10$
	asl	a
	tax
;	jsr	(widRoutine,x)
	.byte	$fc,[widRoutine,]widRoutine
	rep	%00100000
	lda	r3
	sta	tableLeft
	sta	gLeftMargin
	lda	r4
	sta	tableRight
	sta	gRightMargin
	sep	%00100000
	jsr	SetGlobals
	jsr	SaveHTMPtr
	PushB	tagMode
	PushB	curTagNum
	jsr	GetTblColumns
	PopB	curTagNum
	PopB	tagMode
	jsr	RstrHTMPtr
	MoveW	marginWidth,r0
	LoadB	r1H,#0
	MoveB	numTblColumns,r1L
	ldx	#r0
	ldy	#r1
	jsl	SDdiv,0
	MoveW	r0,defClmWidth

;fall through to next page...

;previous page falls through to here...
RbldCells:
	ldx	numTblColumns
	cpx	#40
	bcc	35$
	ldx	#39
 35$
	rep	%00100000
	ldy	#0
	lda	tableLeft+0,y
 40$
	clc
	adc	defClmWidth
	sta	tableLeft+2,y
	iny
	iny
	dex
	bne	40$
	lda	tableRight
 50$
	sta	tableLeft+2,y
	iny
	iny
 60$
	cpy	#80
	bcc	50$
	sep	%00100000
	rts

widRoutine:
	.word	TblWNLeft,TblWNCenter,TblWNRight


SaveTblRegs:
	rep	%00110000
	jsr	PntCurTable
	ldy	#[0
	.byte	]0
 10$
	lda	tableRegs,y
	sta	tableStack,x
	inx
	inx
	iny
	iny
	cpy	#[128
	.byte	]128
	bcc	10$
	sep	%00110000
	rts

RstrTblRegs:
	rep	%00110000
	jsr	PntCurTable
	ldy	#[0
	.byte	]0
 10$
	lda	tableStack,x
	sta	tableRegs,y
	inx
	inx
	iny
	iny
	cpy	#[128
	.byte	]128
	bcc	10$
	sep	%00110000
	rts

PntCurTable:
	lda	curTable
	cmp	#[8
	.byte	]8
	bcc	10$
	lda	#[7
	.byte	]7
 10$
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	tax
	rts

;this gets the width and align if found.
;this defaults to left.
TblWNLeft:
	lda	#0
	.byte	44
;this defaults to center.
TblWNCenter:
	lda	#1	;default to center.
	.byte	44
TblWNRight:
	lda	#2	;default to right.
	sta	r2L
	MoveW	marginWidth,r1	;default to full width.
 20$
	jsr	GetNxtAttr
	bcc	60$
	cpx	#38	;is this the WIDTH= attribute?
	beq	30$	;branch if so.
	cpx	#2	;is it the ALIGN= attribute?
	bne	20$	;branch if not.
	MoveB	r0L,r2L
	bra	20$
 30$
	cmp	#2	;is width in percent requested?
	bne	40$	;branch if width in pixels.
	jsr	WidthPercent
	bra	20$
 40$
.if	C64
	LoadW	r1,#312	;width of screen area (not frame!)
.else
	LoadW	r1,#624	;width of screen area (not frame!)
.endif
	CmpWI	r0,#800	;is width 800 pixels or more?
	bcs	20$	;branch if so.
	ldx	#r1
	ldy	#r0
	jsl	SDMult,0
	LoadW	r0,#800
	jsl	SD32div,0
	MoveW	r6,r1
	bra	20$
 60$
;fall through to next page...


;previous page continues here...
TblW2:
	rep	%00100000
	lda	marginWidth
	cmp	r1
	bcs	50$
	lda	leftMargin
	adc	r1
;	cmp	frmRight
	.byte	$cf,[frmRight,]frmRight,0
	bcc	30$
;	lda	frmRight
	.byte	$af,[frmRight,]frmRight,0
 30$
	sta	rightMargin
	lda	#[0
	.byte	]0
	sta	r2L	;change to left justified.
	sta	r1
	beq	60$	;branch always.
 50$
	sec
	sbc	r1
	lsr	a
	sta	r1
 60$
	sep	%00100000
	lda	r2L
	cmp	#3	;anything but LEFT,RIGHT, or CENTER?
	bcs	75$	;branch if so.
	cmp	#1	;is it ALIGN=CENTER?
	beq	75$	;branch if so.
	asl	r1L
	rol	r1H
	cmp	#2	;is it ALIGN=RIGHT?
	beq	70$	;branch if so.
	jsr	AlignRight	;do ALIGN=LEFT.
	LoadB	r1L,#0
	sta	r1H
	jmp	AlignLeft
 70$
	jsr	AlignLeft
	LoadB	r1L,#0
	sta	r1H
	jmp	AlignRight
 75$
	jsr	AlignLeft
 80$
	jmp	AlignRight

;this returns the number of table columns in numTblColumns.
GetTblColumns:
	LoadB	numTblColumns,#1
	LoadB	tempTblColumns,#0
	LoadB	tblTagCount,#1
 10$
	jsr	FindNxtTag
	bcc	GTC80
;	jsr	FlushTag
	lda	curTagNum
	cmp	#30	;TABLE tag?
	bne	15$
 12$
	bit	tagMode
	bmi	13$
	inc	tblTagCount
	bne	10$	;branch always.
 13$
	dec	tblTagCount
	beq	GTC80
	bne	10$
 15$
	ldx	tblTagCount
	dex
	bne	10$
	bit	tagMode
	bmi	10$
	cmp	#32	;TD tag?
	beq	30$	;branch if so.
	cmp	#39	;TH tag?
	beq	30$	;branch if so.
	cmp	#31	;TR tag?
	bne	10$	;branch if not.
 16$
	ldx	#0
	lda	tempTblColumns
	stx	tempTblColumns
	cmp	numTblColumns
	bcc	20$
	sta	numTblColumns
 20$
	jsr	FindNxtTag
	bcc	GTC80
;	jsr	FlushTag
	lda	curTagNum
	cmp	#30
	beq	12$
	bit	tagMode
	bmi	20$
	cmp	#31
	beq	16$
	cmp	#32
	beq	30$
	cmp	#39
	bne	20$
 30$
	jsr	GetNxtAttr
	bcc	40$
	cpx	#10
	bne	30$
	lda	r0L
	.byte	44
 40$
	lda	#1
	clc
	adc	tempTblColumns
	sta	tempTblColumns
	bra	20$
GTC80:
	lda	tempTblColumns
	cmp	numTblColumns
	bcc	85$
	sta	numTblColumns
 85$
	rts

tempTblColumns:
	.block	1

tblTagCount:
	.block	1


TTRow:
	jsr	FlushText
	bit	tableMode
	bmi	10$
	rts
 10$
	bit	tagMode
	bmi	TTR2
	jsr	TTD2
	jsr	StashBSegment
TTR1:
	LoadB	trMode,#%10000000
	LoadB	tblClmCounter,#255
	jsr	FixRowBottom
	lda	rowBottom+0
	and	#%00000111
	sta	crsrY
	lda	rowBottom+0
	and	#%11111000
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
	lda	rowBottom+1
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
	lda	rowBottom+2
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
	jsr	FetchBSegment
	jsr	Scroll3Pixels
	jsr	RbldCells
	jsr	SetTopBottom
	jmp	SetTblGlobals
TTR2:
	jsr	TTD2
	jsr	StashBSegment
TTR3:
	bit	trMode
	bmi	10$
	rts
 10$
	LoadB	trMode,#%00000000
	LoadB	tblClmCounter,#255
	jsr	FixRowBottom
	lda	rowBottom+0
	and	#%00000111
	sta	crsrY
	lda	rowBottom+0
	and	#%11111000
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
	lda	rowBottom+1
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
	lda	rowBottom+2
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
	jsr	FetchBSegment
	jsr	SetTopBottom
	jmp	SetTblGlobals


SetTopBottom:
	clc
;	lda	curPageTop+0
	.byte	$af,[(curPageTop+0),](curPageTop+0),0
	adc	crsrY
	sta	rowTop+0
	sta	rowBottom+0
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	adc	#0
	sta	rowTop+1
	sta	rowBottom+1
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	adc	#0
	sta	rowTop+2
	sta	rowBottom+2
	rts

SetTblGlobals:
	MoveW	tableLeft,gLeftMargin
	MoveW	tableRight,gRightMargin
	jmp	SetGlobals

TTHeader:
	lda	#%11000000
	.byte	44
TTData:
	lda	#%10000000
	pha
	jsr	FlushText
	bit	tableMode
	bmi	10$
	pla
	rts
 10$
	jsr	FlushText
	jsr	StashBSegment
	bit	tagMode
	bmi	60$
	jsr	TTD2
	bit	trMode
	bmi	20$
	jsr	TTR1
 20$
	lda	globalJust
	ldx	#17
	jsr	PushStack
	ldx	#17
	jsr	SvFontStack
	lda	#0
	sta	currentMode
	sta	globalJust
	sta	justification
	PopB	tdMode
	and	#%01000000
	beq	50$
	LoadB	currentMode,#SET_BOLD
 50$
	jsr	PutStyle
	jmp	PntTxtCell
 60$
	pla
TTD2:
	lda	tdMode
	beq	90$
	lda	tblClmCounter
	asl	a
	tay
	rep	%00100000
	lda	maxCellRight
	beq	40$
	sta	tableLeft+2,y
 40$
	sep	%00100000
	ldx	#17
	jsr	RstFontStack
	ldx	#17
	jsr	PullStack
	sta	globalJust
	sta	justification
	LoadB	tdMode,#%00000000
	jsr	FixRowBottom
	jsr	SetBtmOfPage
 90$
	rts

FixRowBottom:
	PushW	r0
	clc
;	lda	curPageTop+0
	.byte	$af,[(curPageTop+0),](curPageTop+0),0
	adc	crsrY
	sta	r0L
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	adc	#0
	sta	r0H
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	adc	#0
	pha
	cmp	rowBottom+2
	bne	10$
	lda	r0H
	cmp	rowBottom+1
	bne	10$
	lda	r0L
	cmp	rowBottom+0
 10$
	pla
	bcc	90$
	sta	rowBottom+2
	MoveB	r0H,rowBottom+1
	MoveB	r0L,rowBottom+0
 90$
	PopW	r0
	rts

PntTxtCell:
	inc	tblClmCounter
	lda	tblClmCounter
	cmp	numTblColumns
	bcc	10$
	jsr	TTR1
	inc	tblClmCounter
 10$
	jsr	CkTDWidth
	lda	tblClmCounter
	asl	a
	tay
	rep	%00100000
	clc
	lda	tableLeft+0,y
	adc	r1
 30$
	cmp	tableRight
	bcc	40$
	lda	tableRight
 40$
	sta	tableLeft+2,y
	lda	tableLeft+0,y
	clc
	adc	#[2
	.byte	]2
	sta	gLeftMargin
	lda	#[0
	.byte	]0
	sta	maxCellRight
	lda	tableLeft+2,y
	bit	lockCellWidth-1 ;(16bit test)
	bpl	60$
	sta	maxCellRight
 60$
	sec
	sbc	#2
	.byte	]2
	sta	gRightMargin
	sep	%00100000
	jsr	SetGlobals
	jsr	LMargToString
	jsr	RMargToString
	lda	rowTop+0
	and	#%00000111
	sta	crsrY
	lda	rowTop+0
	and	#%11111000
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
	lda	rowTop+1
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
	lda	rowTop+2
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
	jmp	FetchBSegment

CkTDWidth:
	LoadB	lockCellWidth,#%10000000
 10$
	jsr	GetNxtAttr
	bcc	90$
	cpx	#38	;is this the WIDTH= attribute?
	bne	10$	;branch if not.
	cmp	#2	;is width in percent requested?
	bne	40$	;branch if width in pixels.
	jsr	SetTblGlobals
	jsr	WidthPercent
	sec
	rts
 40$
	jsr	SetTblGlobals
	jsr	WidthPixels
	sec
	rts
 90$
	LoadB	lockCellWidth,#%00000000
	lda	tblClmCounter
	asl	a
	tay
	rep	%00100000
	sec
	lda	tableLeft+2,y
	sbc	tableLeft+0,y
	cmp	defClmWidth
	bcs	95$
	lda	defClmWidth
 95$
	sta	r1
	sep	%00100000
	clc
	rts

lockCellWidth:
	.block	1

TCaption:
	jsr	FlushText
	bit	tagMode
	bmi	20$
	jsr	TCenter
	LoadB	captionMode,#%10000000
 10$
	rts
 20$
	bit	captionMode
	bpl	10$
	jsr	Scroll3Pixels
	jsr	TCenter
	LoadB	captionMode,#%00000000
	jmp	SetTopBottom


TFont:
	bit	tagMode
	bpl	20$
	bit	tfontMode
	bmi	10$
	rts
 10$
	ldx	#14
	jsr	RstFontStack
	ldx	#14
	jsr	PullStack
	sta	tfontMode
	rts
 20$
	ldx	#14
	lda	tfontMode
	jsr	PushStack
	LoadB	tfontMode,#%10000000
	ldx	#14
	jsr	SvFontStack
	LoadB	facePtr+0,#0
	sta	facePtr+1
	sta	fSzPtr
 30$
	jsr	GetNxtAttr
	bcc	60$
	cpx	#14
	bne	35$
	MoveW	r0,facePtr
	bra	30$
 35$
	cpx	#31
	bne	30$
	jsr	FSizeAttr
	bra	30$
 60$
	lda	facePtr+1
	beq	70$
	sta	r0H
	MoveB	facePtr+0,r0L
;	phk
	.byte	$4b
	PopB	r1L
	lda	fSzPtr
	bne	65$
	lda	reqFSize
 65$
	jsr	JGetDesFont
	jmp	PutFont
 70$
	lda	fSzPtr
	beq	90$
	sta	reqFSize
	jmp	PutFont
 90$
	rts

facePtr:
	.block	2
fSzPtr:
	.block	1

FSizeAttr:
	tax
	beq	50$
	bmi	20$
	cmp	#2
	bcs	90$
 20$
	lda	r0L
	clc
	adc	#3	;+++get this from the default
			;+++base size when ready.
	bmi	60$
	beq	60$
	bne	55$
 50$
	lda	r0L
	bne	55$
	lda	#3	;+++get default size from defaults.
 55$
	cmp	#8
	bcc	70$
	lda	#7
	.byte	44
 60$
	lda	#1
 70$
	sta	fSzPtr
 90$
	rts


PutFont:
	ldy	textStrPtr
	lda	#ESC_NEWCARDSET
	sta	textString,y
	iny
	lda	reqFntNum
	sta	textString,y
	iny
	lda	reqISOType
	sta	textString,y
	iny
	lda	reqFSize
	sta	textString,y
	iny
	sty	textStrPtr
	rts


TTeletype:
	bit	tagMode
	bpl	20$
	bit	ttMode
	bmi	10$
	rts
 10$
	ldx	#15
	jsr	RstFontStack
	ldx	#15
	jsr	PullStack
	sta	ttMode
	rts
 20$
	ldx	#15
	lda	ttMode
	jsr	PushStack
	LoadB	ttMode,#%10000000
	ldx	#15
	jsr	SvFontStack
	LoadW	r0,#monFontName
;	phk
	.byte	$4b
	PopB	r1L
.if	C64
	lda	#2	;+++get this from a default.
.else
	lda	#3
.endif
	jsr	JGetDesFont
	jmp	PutFont


TKeyboard:
	bit	tagMode
	bpl	20$
	jsr	TItalic
	jmp	TTeletype
 20$
	jsr	TTeletype
	jmp	TItalic

TDefine:
	bit	tagMode
	bpl	20$
	jsr	TItalic
	jmp	TBold
 20$
	jsr	TBold
	jmp	TItalic

TPre:
	LoadB	lastCRChar,#0
	bit	tagMode
	bpl	40$
	bit	preMode
	bmi	10$
	rts
 10$
	jsr	FlushText
	jsr	TLB3
	jsr	TTeletype
	ldx	#16
	jsr	PullStack
	sta	preMode
	rts
 40$
	jsr	FlushText
	jsr	TLB3
	ldx	#16
	lda	preMode
	jsr	PushStack
	LoadB	preMode,#%10000000
	jmp	TTeletype



TAddress:
	bit	tagMode
	bmi	40$
	LoadB	addressMode,#%10000000
	jmp	TBlockQuote
 40$
	bit	addressMode
	bmi	50$
	rts
 50$
	LoadB	addressMode,#%00000000
	jmp	TBlockQuote


TImg:
	jsr	DoImgWidth
	jsr	Get1stAttr
	bcc	15$
 10$
	cpx	#3	;alt attribute?
	beq	60$
	jsr	GetNxtAttr
	bcs	10$
 15$
	rts
 60$
	lda	#160
	jsr	PutR0Char
 70$
;	lda	(r0)
	.byte	$b2,r0
	beq	90$
	jsr	PutR0Char
	inc	r0L
	bne	70$
	inc	r0H
	bne	70$
 90$
	rts

PutR0Char:
	tax
	PushW	r0
	txa
	jsr	PutOurChar
	PopW	r0
	rts


DoImgWidth:
	jsr	Get1stAttr
	bcc	15$
 10$
	cpx	#38	;is this the WIDTH= attribute?
	beq	30$	;branch if so.
	jsr	GetNxtAttr
	bcs	10$
 15$
	rts
 30$
	cmp	#2	;is width in percent requested?
	bne	40$	;branch if width in pixels.
	jsr	WidthPercent
	bra	50$
 40$
.if	C64
	LoadW	r1,#312	;width of screen area (not frame!)
.else
	LoadW	r1,#624	;width of screen area (not frame!)
.endif
	CmpWI	r0,#800	;is width 800 pixels or more?
	bcs	50$	;branch if so.
	ldx	#r1
	ldy	#r0
	jsl	SDMult,0
	LoadW	r0,#800
	jsl	SD32div,0
	MoveW	r6,r1
 50$
	lda	tdMode	;+++for now, we're only concerned with
	beq	80$	;+++table cell widths.
	lda	tblClmCounter
	asl	a
	tay
	rep	%00100000
	clc
	lda	r1
	adc	textStrLength
	adc	leftMargin
	cmp	maxCellRight
	bcc	70$
	sta	maxCellRight
	cmp	rightMargin
	bcc	70$
	cmp	tableRight
	bcc	60$
	lda	tableRight
 60$
	sta	maxCellRight
	sta	rightMargin
	sta	gRightMargin
	sep	%00100000
	jsr	RMargToString
	LoadB	textInString,#%10000000
	rts
 70$
	sep	%00100000
 80$
	rts


TForm:
	bit	tagMode
	bpl	10$
	rts
 10$
	rts	;+++temporary.

	LoadB	formsFound,#1
 20$
	jsr	FindNxtTag
	bcc	90$
	lda	curTagNum
	cmp	#46
	bne	20$
	bit	tagMode
	bmi	30$
	inc	formsFound
	bne	20$
	rts
 30$
	dec	formsFound
	bne	20$
	rts
 90$
	LoadB	htmlMode,#%00000000
	rts

formsFound:
	.block	1
