;*****************************************
;
;
;	Parse3HTM
;
;	routines called when an HTML
;	tag is encountered while parsing the
;	HTML document.
;
;*****************************************


	.psect


TBlockQuote:
	jsr	TLB2
	bit	tagMode
	bmi	40$
	CmpWI	marginWidth,#16
	bcc	75$
	ldx	#5
	lda	bqMode
	jsr	PushStack
	LoadB	bqMode,#%10000000
	jsr	L5GMarg2Stack
	jsr	SetGlobals
	clc
	lda	gLeftMargin+0
	adc	#8
	sta	gLeftMargin+0
	sta	leftMargin+0
	lda	gLeftMargin+1
	adc	#0
	sta	gLeftMargin+1
	sta	leftMargin+1
	jmp	LMargToString
 40$
	bit	bqMode
	bmi	50$
	rts
 50$
	jsr	TLB2
	jsr	Stk5ToLMarg
	ldx	#5
	jsr	PullStack
	sta	bqMode
 75$
;fall through...
GetMrgnWidth:
	rep	%00100000
	sec
	lda	rightMargin
	sbc	leftMargin
	ina
	sta	marginWidth
	sep	%00100000
	rts


THtml:
	bit	tagMode
	bmi	40$
	inc	htmlCount
	rts
 40$
	jsr	DumpText
	lda	htmlCount
	beq	50$
	dec	htmlCount
	bne	90$
 50$
	LoadB	htmlMode,#%00000000
 90$
	rts

;+++this currently does nothing.
THead:
	rts

;+++this currently does nothing.
TTitle:
	rts

TBody:
	bit	tagMode
	bmi	40$
	inc	bodyCount
	lda	htmlMode
	ora	#%01000000
	sta	htmlMode
	rts
 40$
	jsr	DumpText
	lda	bodyCount
	beq	50$
	dec	bodyCount
	bne	90$
 50$
	lda	htmlMode
	and	#%10111111
	sta	htmlMode
 90$
	rts


TItalic:
	bit	tagMode
	bpl	40$
	bit	italicMode
	bmi	20$
 10$
	rts
 20$
	ldx	#1
	jsr	PullStack
	sta	italicMode
	bit	italicMode
	bmi	10$
	ldx	#SET_ITALIC
	jmp	PutClrMode
 40$
	lda	italicMode
	ldx	#1
	jsr	PushStack
	LoadB	italicMode,#%10000000
	ldx	#SET_ITALIC
	jmp	PutSetMode


TUnderline:
	bit	tagMode
	bpl	40$
	bit	ulineMode
	bmi	20$
 10$
	rts
 20$
	ldx	#2
	jsr	PullStack
	sta	ulineMode
	bit	ulineMode
	bmi	10$
	ldx	#SET_UNDERLINE
	jmp	PutClrMode
 40$
	lda	ulineMode
	ldx	#2
	jsr	PushStack
	LoadB	ulineMode,#%10000000
	ldx	#SET_UNDERLINE
	jmp	PutSetMode


TBold:
	bit	tagMode
	bpl	40$
	bit	boldMode
	bmi	20$
 10$
	rts
 20$
	ldx	#0
	jsr	PullStack
	sta	boldMode
	bit	boldMode
	bmi	10$
	ldx	#SET_BOLD
	jmp	PutClrMode
 40$
	lda	boldMode
	ldx	#0
	jsr	PushStack
	LoadB	boldMode,#%10000000
	ldx	#SET_BOLD
	jmp	PutSetMode



PutSetMode:
	lda	#ESC_SETMODE
	.byte	44
PutClrMode:
	lda	#ESC_CLRMODE
	pha
	ldy	textStrPtr
	sta	textString,y
	iny
	txa
	sta	textString,y
	iny
	sty	textStrPtr
	pla
	cmp	#ESC_SETMODE
	beq	50$
	txa
	eor	#%11111111
	and	currentMode
	sta	currentMode
	rts
 50$
	txa
	ora	currentMode
	sta	currentMode
	rts

PutStyle:
	ldy	textStrPtr
	lda	#ESC_STYLE
	sta	textString,y
	iny
	lda	currentMode
	sta	textString,y
	iny
	sty	textStrPtr
	rts


;+++fix this in case an extra bank is needed
;+++to store the href strings.
TAnchor:
	bit	tagMode
	bmi	40$
	bit	anchorMode
	bpl	20$
	jsr	OffModeAnchor
 20$
	LoadB	anchorMode,#%10000000
	LoadB	hrefFound,#%11111111
	jsr	StoreNMAttr
	jsr	StoreHREF
	bit	hrefFound
	bmi	OMA2
	jmp	TUnderline
 40$
	bit	anchorMode
	bpl	OMA2
OffModeAnchor:
	LoadB	anchorMode,#%00000000
	bit	hrefFound
	bmi	OMA2
	jsr	TUnderline
	lda	#ESC_OFFANCHOR
	ldy	textStrPtr
	sta	textString,y
	iny
	sty	textStrPtr
OMA2:
	rts


anchorStarted:
	.block	1
hrefFound:
	.block	1
nxtLnkPtr:
	.block	1
linksToStore:
	.block	160
	.block	4

anchorTop:
	.block	3
anchorBottom:
	.block	3
anchorLeft:
	.block	2
anchorRight:
	.block	2
linkPtr:
	.block	3
anchorType:
	.block	1
	.block	2	;reserved.


StoreHREF:
	jsr	Get1stAttr
	bcs	30$
	rts
 20$
	jsr	GetNxtAttr
	bcs	30$
	rts
 30$
	cpx	#16	;look for HREF attribute.
	bne	20$	;branch if not found yet.
	lda	hrefFound
	and	#%01111111
	sta	hrefFound
	jsr	Look4Match	;see if there's a matching link.
	bcs	90$	;branch if one was found.
	ldx	nxtLnkPtr
	lda	linksToStore+0,x
	sta	r1L
	lda	linksToStore+1,x
	sta	r1H
	lda	linksToStore+2,x
	sta	r2L
	lda	#0
	sta	linksToStore+3,x
	ldy	#0
 40$
	lda	(r0),y
	beq	50$
;	sta	[r1],y
	.byte	$97,r1
	iny
	bne	40$
 50$
	lda	#0
;	sta	[r1],y
	.byte	$97,r1
	iny
	tya
	clc
	adc	r1L
	sta	linksToStore+0+4,x
	lda	r1H
	adc	#0
	sta	linksToStore+1+4,x
;+++fix this part when multiple banks are supported.
;	lda	r2L
;	sta	linksToStore+2+4,x
	lda	#%11111111
	sta	linksToStore+3+4,x
	inx
	inx
	inx
	inx
	stx	nxtLnkPtr
	lda	#ESC_ONANCHOR
	ldy	textStrPtr
	sta	textString,y
	iny
	sty	textStrPtr
 90$
	rts


;this looks for a matching href string that's already been stored.
;If none found, then it will jump to CkSameLine to see if one
;exists in the line that's currently being rendered but not yet
;stored.
Look4Match:
;	lda	anchorBank
	.byte	$af,[anchorBank,]anchorBank,0
	sta	r2L
	LoadB	r1L,#0
	sta	r1H
L4M2:
	ldy	#13
;	lda	[r1],y
	.byte	$b7,r1
	bpl	L4M5
L4M3:
	clc
	lda	r1L
	adc	#16
	sta	r1L
	bcc	L4M2
	inc	r1H
	bne	L4M2
L4M4:
	jmp	CkSameLine
L4M5:
	ldy	#3
;	lda	[r1],y
	.byte	$b7,r1
	iny
;	ora	[r1],y
	.byte	$17,r1
	iny
;	ora	[r1],y
	.byte	$17,r1
	beq	L4M4	;branch if end of tables.
	ldy	#10
;	lda	[r1],y
	.byte	$b7,r1
	sta	r3L
	iny
;	lda	[r1],y
	.byte	$b7,r1
	sta	r3H
	iny
;	lda	[r1],y
	.byte	$b7,r1
	sta	r4L
	jsr	CmpHREFString
	bne	L4M3
;fall through...
StHREFLink:
	ldx	nxtLnkPtr
	lda	linksToStore+0,x
	sta	linksToStore+0+4,x
	lda	linksToStore+1,x
	sta	linksToStore+1+4,x
	lda	linksToStore+2,x
	sta	linksToStore+2+4,x
	lda	linksToStore+3,x
	sta	linksToStore+3+4,x
	lda	r3L
	sta	linksToStore+0,x
	lda	r3H
	sta	linksToStore+1,x
	lda	r4L
	sta	linksToStore+2,x
	lda	#0
	sta	linksToStore+3,x
	inx
	inx
	inx
	inx
	stx	nxtLnkPtr
	lda	#ESC_ONANCHOR
	ldy	textStrPtr
	sta	textString,y
	iny
	sty	textStrPtr
	sec
	rts

;this looks for a matching href string that might be on the same
;line that is currently being rendered.
CkSameLine:
	ldx	nxtLnkPtr
	beq	90$
 10$
	dex
	dex
	dex
	dex
	lda	linksToStore+3,x
	bmi	70$
	lda	linksToStore+0,x
	sta	r3L
	lda	linksToStore+1,x
	sta	r3H
	lda	linksToStore+2,x
	sta	r4L
	jsr	CmpHREFString
	bne	70$
	jmp	StHREFLink
 70$
	txa
	bne	10$
 90$
	clc
	rts

CmpHREFString:
	ldy	#0
 20$
;	lda	[r3],y
	.byte	$b7,r3
	beq	30$
	cmp	(r0),y
	bne	90$
	iny
	bne	20$
	lda	#1	;clear the equals flag.
	rts
 30$
	cmp	(r0),y
 90$
	rts

StoreNMAttr:
	jsr	Get1stAttr
	bcs	30$
	rts
 20$
	jsr	GetNxtAttr
	bcc	90$
 30$
	cpx	#22	;look for NAME attribute.
	bne	20$	;branch if not found yet.
	lda	hrefFound
	and	#%10111111
	sta	hrefFound
	ldx	nxtLnkPtr
	lda	linksToStore+0,x
	sta	r1L
	lda	linksToStore+1,x
	sta	r1H
	lda	linksToStore+2,x
	sta	r2L
	lda	#%10000000
	sta	linksToStore+3,x
	ldy	#0
 40$
	lda	(r0),y
	beq	50$
;	sta	[r1],y
	.byte	$97,r1
	iny
	bne	40$
 50$
	lda	#0
;	sta	[r1],y
	.byte	$97,r1
	iny
	tya
	clc
	adc	r1L
	sta	linksToStore+0+4,x
	lda	r1H
	adc	#0
	sta	linksToStore+1+4,x
;+++fix this part when multiple banks are supported.
;	lda	r2L
;	sta	linksToStore+2+4,x
	lda	#%10000000
	sta	linksToStore+3+4,x
	inx
	inx
	inx
	inx
	stx	nxtLnkPtr
	lda	#ESC_NMANCHOR
	ldy	textStrPtr
	sta	textString,y
	iny
	sty	textStrPtr
 90$
	rts

;this will point r0 (24bit) to a free spot
;in the anchorBank for the current anchor table
;to be copied to. It will open up a hole so that
;the anchors are arranged in order from top to
;bottom as the page is rendered.
GetAncSpot:
;	lda	anchorBank
	.byte	$af,[anchorBank,]anchorBank,0
	sta	r1L
	LoadB	r0L,#0
	sta	r0H
 10$
	ldy	#3
;	lda	[r0],y
	.byte	$b7,r0
	iny
;	ora	[r0],y
	.byte	$17,r0
	iny
;	ora	[r0],y
	.byte	$17,r0
	beq	70$	;branch if empty spot.
	ldy	#2
	lda	anchorTop+2
;	cmp	[r0],y
	.byte	$d7,r0
	bne	30$
	dey
	lda	anchorTop+1
;	cmp	[r0],y
	.byte	$d7,r0
	bne	30$
	dey
	lda	anchorTop+0
;	cmp	[r0],y
	.byte	$d7,r0
 30$
	bcc	40$
	clc
	lda	r0L
	adc	#16
	sta	r0L
	bcc	10$
	inc	r0H
	bne	10$
	clc
	rts
 40$
	MoveB	r1L,r3L
	sta	r3H
	clc
	lda	r0L
	adc	#16
	sta	r1L
	lda	r0H
	adc	#0
	sta	r1H
	sec
	lda	#0
	sbc	r1L
	sta	r2L
	lda	#0
	sbc	r1H
	sta	r2H
	jsl	SDoSuperMove,0
	MoveB	r3L,r1L
 70$
	sec
	rts

StartAnchor:
	LoadB	anchorStarted,#%10000000
	clc
;	lda	curPageTop+0
	.byte	$af,[(curPageTop+0),](curPageTop+0),0
	adc	crsrY
	sta	anchorTop+0
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	adc	#0
	sta	anchorTop+1
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	adc	#0
	sta	anchorTop+2
	lda	curHeight
	dea
	clc
	adc	anchorTop+0
	sta	anchorBottom+0
	lda	anchorTop+1
	adc	#0
	sta	anchorBottom+1
	lda	anchorTop+2
	adc	#0
	sta	anchorBottom+2
	MoveB	r11L,anchorLeft+0
	sta	anchorRight+0
	MoveB	r11H,anchorLeft+1
	sta	anchorRight+1
	MoveW	linksToStore,linkPtr
	MoveB	linksToStore+2,linkPtr+2
	MoveB	linksToStore+3,anchorType
	rts


CkForAnchor:
	bit	anchorStarted
	bpl	60$
	bvs	60$
	jsr	StoreAnchor
	LoadB	anchorStarted,#%11000000
 60$
	rts

StopAnchor:
	bit	anchorStarted
	bpl	90$
	bvs	10$
	jsr	StoreAnchor
 10$
	ldx	nxtLnkPtr
	beq	40$
	dex
	dex
	dex
	dex
	stx	nxtLnkPtr
 40$
	ldx	#0
 50$
	lda	linksToStore+4,x
	sta	linksToStore+0,x
	inx
	cpx	#156
	bcc	50$
 90$
	LoadB	anchorStarted,#%00000000
	rts


StoreAnchor:
	bit	anchorStarted
	bpl	95$
	bvs	95$
	PushW	r0
	PushB	r1H
	PushW	r11
	jsr	GetAncSpot
	bcc	90$
	ldy	#15
 10$
	lda	anchorTop,y
;	sta	[r0],y
	.byte	$97,r0
	dey
	bpl	10$
 90$
	PopW	r11
	PopB	r1H
	PopW	r0
 95$
	rts

TComment:
	bit	tagMode
	bpl	10$
	rts
 10$
	jsr	DumpText
	jsr	FindCOMMENT
	bcc	90$
	rts
 90$
	lda	htmlMode
	and	#%00111111
	sta	htmlMode
	rts


;this skips through the <!-- ... --> string.
;+++eventually this will activate Javascript possibly.
TSkip:
 40$
	lda	#'-'
	jsr	FindChar
	bcc	90$
 50$
	jsr	LdaNxtChar
	bcc	90$
	cmp	#'-'
	bne	40$
 60$
	jsr	LdaNxtChar
	bcc	90$
	cmp	#'-'
	beq	60$
	cmp	#'>'
	bne	40$
 90$
	jmp	A0ToTagPtr


TParagraph:
	bit	tagMode
	bpl	TP2
	rts
TP2:
	jsr	FlushText
	jsr	SetGlobals
 20$
	jsr	GetNxtAttr
	bcc	80$
	cpx	#2	;look for ALIGN attribute.
	bne	20$	;branch if not found yet.
	lda	r0L
	cmp	#4
	bcs	80$
	sta	justification
 80$
	jmp	Scroll3Pixels


TLineBreak:
	bit	tagMode
	bpl	TLB2
	rts
TLB2:
	jsr	DumpText
TLB3:
 10$
	clc
	lda	tallestHeight
	bne	20$
	lda	curHeight
 20$
	adc	#1
	jsr	ScrollPixels
	LoadB	lastItalic,#0
	jsr	GetMrgnWidth
	jmp	CkForAnchor

ScrollPixels:
	.byte	44
Scroll3Pixels:
	lda	#3
	sta	pixToScroll
	jsr	JCurFrHeight
	sec
	sbc	#24+1
	sta	scrArSize
 20$
	lda	pixToScroll
	clc
	adc	crsrY
	cmp	scrArSize
	bcc	80$
	jsr	ScrollSegment
	bra	20$
 80$
	sta	crsrY
	rts

pixToScroll:
	.block	1
scrArSize:
	.block	1

FlushText:
	bit	textInString
	bmi	10$
	jsr	DumpText
	jmp	CkForAnchor
 10$
	jmp	TLB2

TH1:
	lda	#6
	.byte	44
TH2:
	lda	#5
	.byte	44
TH3:
	lda	#4
	.byte	44
TH4:
	lda	#3
	.byte	44
TH5:
	lda	#2
	.byte	44
TH6:
	lda	#1
	sta	hdlnDesired
	jsr	FlushText
	bit	tagMode
	bpl	40$
	bit	hdlnMode
	bmi	10$
	rts
 10$
	LoadB	hdlnMode,#%00000000
	ldx	#8
	jmp	RstFontStack
 40$
	jsr	Scroll3Pixels
	ldx	#8
	jsr	SvFontStack
	LoadB	hdlnMode,#%10000000
	LoadW	r0,#hdlFontName
;	phk
	.byte	$4b
	PopB	r1L
	lda	hdlnDesired
	jsr	JGetDesFont
	jmp	PutFont

hdlnDesired:
	.block	1
hlstackNum:
	.block	1

SvFontStack:
	stx	fStckNum
	lda	reqFntNum
	jsr	PushStack
	ldx	fStckNum
	lda	reqISOType
	jsr	PushStack
	ldx	fStckNum
	lda	reqFSize
	jsr	PushStack
	ldx	fStckNum
	lda	currentMode
	jmp	PushStack

RstFontStack:
	stx	fStckNum
	jsr	PullStack
	sta	currentMode
	ldx	fStckNum
	jsr	PullStack
	sta	reqFSize
	ldx	fStckNum
	jsr	PullStack
	sta	reqISOType
	ldx	fStckNum
	jsr	PullStack
	sta	reqFntNum
	jsr	PutFont
	jsr	PutStyle
	jsr	CmpFntRequest
	beq	50$
	jsr	ReLdReqFont
 50$
	rts

fStckNum:
	.block	1

THRule:
	jsr	FlushText
	jsr	SetGlobals
	jsr	GetWidNCenter
	lda	curHeight
	lsr	a
	clc
	adc	windowTop
	adc	crsrY
	sta	r11L
	lda	#%11111111
	jsl	SHorizontalLine,0
	inc	r11L
	lda	#%10101010
	jsl	SHorizontalLine,0
	jmp	TLB2


;this gets the width and align if found.
;this defaults to left.
GetWidNLeft:
	lda	#0
	.byte	44
;this defaults to center.
GetWidNCenter:
	lda	#1	;default to center.
	.byte	44
GetWidNRight:
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
	jsr	WidthPixels
	bra	20$
 60$
	rep	%00100000
	lda	marginWidth
	cmp	r1
	bcs	65$
	sta	r1
	bcc	68$	;branch always.
 65$
	sec
	sbc	r1
	lsr	a
	sta	r1
 68$
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
 79$
	jmp	AlignRight

AlignLeft:
	rep	%00100000
	clc
	lda	leftMargin
	adc	r1
	sta	r3
	sep	%00100000
	rts

AlignRight:
	rep	%00100000
	sec
	lda	rightMargin
	sbc	r1
	sta	r4
	sep	%00100000
	rts


WidthPercent:
	MoveW	marginWidth,r1
	CmpWI	r0,#100	;is it 100% or more?
	bcc	10$	;branch if not.
	rts
 10$
	ldx	#r1
	ldy	#r0L
	jsl	SBMult,0
	LoadW	r0,#100
	jsl	SDdiv,0
	rts

WidthPixels:
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
	CmpW	marginWidth,r1
	bcs	80$
	MoveW	marginWidth,r1
 80$
	rts

FrAreaWidth:
	jsr	JCurFrWidth
	sec
	lda	r1L
.if	C64
	sbc	#8
.else
	sbc	#16
.endif
	sta	r1L
	lda	r1H
	beq	10$
	sbc	#0
	sta	r1H
 10$
	rts

SetGlobals:
	MoveW	gLeftMargin,leftMargin
	MoveW	gRightMargin,rightMargin
	MoveB	globalJust,justification
	jmp	GetMrgnWidth


TCenter:
	jsr	FlushText
	bit	tagMode
	bpl	20$
	bit	centerMode
	bpl	15$
	ldx	#4
	jsr	PullStack
	sta	centerMode
	ldx	#4
	jsr	PullStack
	sta	globalJust
	sta	justification
 15$
	rts
 20$
	ldx	#4
	lda	globalJust
	jsr	PushStack
	lda	centerMode
	ldx	#4
	jsr	PushStack
	LoadB	centerMode,#%10000000
	LoadB	justification,#1
	sta	globalJust
	rts


TScript:
	bit	tagMode
	bmi	90$
 20$
	inc	scriptCount
 30$
	jsr	FindSCRIPT
	bcc	90$
	bit	tagMode
	bpl	20$
	dec	scriptCount
	bne	30$
 90$
	rts

