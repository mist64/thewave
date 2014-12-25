;*****************************************
;
;
;	Parse1HTM
;
;	routines for parsing an HTML document
;
;
;*****************************************


	.psect


ParseJmpTable:
;ParseHTML
	jmp	JParseHTML

;LCurFrRegs:
	jmp	JCurFrRegs
;LFrRegs:
	jmp	JFrRegs
;LCurFrHeight:
	jmp	JCurFrHeight
;LFrHeight:
	jmp	JFrHeight
;LCurFrBottom:
	jmp	JCurFrBottom
;LFrBottom:
	jmp	JFrBottom
;LCurFrWidth:
	jmp	JCurFrWidth
;LFrWidth:
	jmp	JFrWidth

;CurFrDimensions:
	jmp	JCurFrDimensions
;FrDimensions:
	jmp	JFrDimensions
;GetCurFrame:
	jmp	JGetCurFrame
;GetFrame:
	jmp	JGetFrame

;GetDesFont:
	jmp	JGetDesFont


JParseHTML:
	MoveB	a1L,stHTMLBank
	LoadB	a0L,#0
	sta	a0H
	ldy	#2
	ldx	#0
 5$
;	lda	[a0],y
	.byte	$b7,a0
	sta	lhtmlByte,x
	iny
	inx
	cpx	#3
	bcc	5$
	ldx	#0
 10$
;	lda	[a0],y
	.byte	$b7,a0
	sta	ohtmlSize,x
	iny
	inx
	cpx	#3
	bcc	10$
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	sta	xdloadFlag
	and	#%00000011
	cmp	#%00000011
	bne	25$
	ldy	#0
;	lda	[a0],y
	.byte	$b7,a0
	sta	lhtmlByte+0
	sec
	sbc	#8
	sta	ohtmlSize+0
	iny
;	lda	[a0],y
	.byte	$b7,a0
	sta	lhtmlByte+1
	sbc	#0
	sta	ohtmlSize+1
	MoveB	a1L,lhtmlByte+2
	LoadB	ohtmlSize+2,#0
 25$
	jsl	SMouseOff,0
	jsr	InitFrames
	PushB	dispBufferOn
	LoadB	dispBufferOn,#ST_WR_BACK
	jsr	InitBrsVariables
	lda	xdloadFlag
	beq	30$
	and	#%00000011
	cmp	#%00000001	;viewing as-is?
	beq	40$	;branch if so.
	cmp	#%00000011
	beq	40$
	cmp	#%00000010	;forcing html display?
	beq	65$	;branch if so.
 30$
	jsr	FindHTML
	bcs	60$
 40$
	jsr	ShowAnyway
	bra	70$
 60$
	jsr	FlushTag
	jsr	THtml
 65$
	jsr	DrPrgrssBar
	jsr	DoHeadTag
	jsr	DoBodyTag
	bcc	40$
	jsr	FindHTML
 70$
	jsr	TLB2
	jsl	SFullMargins,0
	LoadB	currentMode,#0
	jsr	StashBSegment	;stash the last segment.
	jsr	SetBtmOfPage
	jsr	SetEPgTop
	PopB	dispBufferOn
	jsl	SMouseUp,0
	jsl	SUseSystemFont,0
	rts

xdloadFlag:
	.block	1

InitBrsVariables:
	LoadB	crsrY,#0
;	sta	endPageTop+0
	.byte	$8f,[(endPageTop+0),](endPageTop+0),0
;	sta	endPageTop+1
	.byte	$8f,[(endPageTop+1),](endPageTop+1),0
;	sta	endPageTop+2
	.byte	$8f,[(endPageTop+2),](endPageTop+2),0
	sta	justification
	sta	globalJust
	sta	textStrLength+0
	sta	textStrLength+1
	sta	textInString
	sta	listMode
	sta	centerMode
	sta	anchorMode
	sta	hdlnMode
	sta	tfontMode
	sta	tableMode
	sta	trMode
	sta	tdMode
	sta	curTable+0
	sta	curTable+1
	sta	captionMode
	sta	boldMode
	sta	ulineMode
	sta	italicMode
	sta	addressMode
	sta	preMode
	sta	ttMode
	sta	tagMode
	sta	lastPutChar
	sta	charWaiting
	sta	lastRdChar
	sta	ignoreWrap
	sta	textStrPtr
	sta	spacePtr
	sta	currentMode
	sta	tallestBaseline
	sta	tallestHeight
	sta	lastItalic
	sta	btmOfPage+0
	sta	btmOfPage+1
	sta	btmOfPage+2
	sta	htmlCount
	sta	headCount
	sta	bodyCount
	sta	scriptCount
	sta	stuffOnScreen
	sta	nhtmlSize+0
	sta	nhtmlSize+1
	sta	nhtmlSize+2

;cont'd on next page...

;...cont'd from previous page.
IBV2:
	jsr	ClrAnchor
	jsr	SetFrMargins
	ldy	#31
	lda	#$ff
 10$
	sta	stackPointer,y
	dey
	bpl	10$
	jsr	PutStyle
	jsr	GetMrgnWidth
	jsr	RewindHTML
;	lda	pageBank
	.byte	$af,[pageBank,]pageBank,0
	tax
	jsl	SClearBank,0
	jsr	InitLnkTable
	jsr	ZeroCPgTop
	jsr	FetchBSegment
	LoadW	r0,#defFontName ;switch to the default font.
;	phk
	.byte	$4b
	PopB	r1L
	lda	#3	;+++default to the base size.
	jsr	JGetDesFont	;and load the font.
	jsr	PutFont
;fall through...
ZeroCPgTop:
	lda	#0
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
	rts

ClrAnchor:
	ldx	#15
	lda	#0
 10$
	sta	anchorTop,x
	dex
	bpl	10$
	rts

RewindHTML:
	LoadB	a0L,#0
	sta	a0H
	MoveB	stHTMLBank,a1L
	lda	xdloadFlag
	and	#%00000011
	cmp	#%00000011
	bne	20$
	LoadB	a0L,#8
	rts
 20$
	ldy	#0
;	lda	[a0],y
	.byte	$b7,a0
	pha
	iny
;	lda	[a0],y
	.byte	$b7,a0
	sta	a0H
	PopB	a0L
	rts

stHTMLBank:
	.block	1

LCallRoutine:
	sta	LJmpRoutine+1
	stx	LJmpRoutine+2
	txa
	bne	LJmpRoutine
	rts
LJmpRoutine:
	jmp	$1000	;this changes.


SetEPgTop:
	sec
;	lda	frmHeight
	.byte	$af,[frmHeight,]frmHeight,0
	sbc	#18
	sta	r2H
	lda	btmOfPage+0
	sta	r1L
	lda	btmOfPage+2
	sta	r2L
	lda	btmOfPage+1
	sta	r1H
	ora	r2L
	bne	60$
	sec
	lda	r1L
	sbc	r2H
	bcs	40$
	lda	#0
 40$
	sta	r1L
	bra	70$
 60$
	sec
	lda	r1L
	sbc	r2H
	sta	r1L
	lda	r1H
	sbc	#0
	sta	r1H
	lda	r2L
	sbc	#0
	sta	r2L
 70$
	lda	r2L
;	sta	endPageTop+2
	.byte	$8f,[(endPageTop+2),](endPageTop+2),0
	lda	r1H
;	sta	endPageTop+1
	.byte	$8f,[(endPageTop+1),](endPageTop+1),0
	lda	r1L
	and	#%11111000
;	sta	endPageTop+0
	.byte	$8f,[(endPageTop+0),](endPageTop+0),0
	rts


FindHTML:
	lda	#0
	.byte	44
FindHead:
	lda	#1
	.byte	44
FindBody:
	lda	#3
	.byte	44
FindCOMMENT:
	lda	#21
	.byte	44
FindSCRIPT:
	lda	#47
	sta	tagToFind
 10$
	jsr	FindNxtTag
	bcc	90$
	lda	curTagNum
	cmp	tagToFind
	bne	10$
 90$
	rts

tagToFind:
	.block	1


SetBtmOfPage:
	clc
;	lda	curPageTop+0
	.byte	$af,[(curPageTop+0),](curPageTop+0),0
	adc	crsrY
	sta	r1L
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	adc	#0
	sta	r1H
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	adc	#0
	sta	r2L
	cmp	btmOfPage+2
	bne	40$
	lda	r1H
	cmp	btmOfPage+1
	bne	40$
	lda	r1L
	cmp	btmOfPage+0
 40$
	bcc	80$
	MoveW	r1,btmOfPage
	MoveB	r2L,btmOfPage+2
	rts
 80$
	MoveW	btmOfPage,r1
	MoveB	btmOfPage+2,r2L
	rts

btmOfPage:
	.block	3

DoBodyTag:
 10$
	jsr	FindBody
	bcs	40$
	lda	xdloadFlag
	beq	90$
	and	#%00000011
	cmp	#%00000010	;forcing html display?
	bne	90$	;branch if not.
	LoadB	tagMode,#%00000000
	jsr	RewindHTML
	jsr	TBody
	bra	50$
 40$
	bit	tagMode
	bmi	10$
	jsr	TBody
	jsr	FlushTag
	jsr	PntNxtChar
	bcc	90$
	bit	tagMode	;did we find </BODY>?
	bmi	10$	;branch if so.
 50$
	jsr	FrmtA0Text
	sec
	rts
 90$
	clc
	rts

OffListMode:
	bit	listMode
	bvc	90$
	lda	listMode
	and	#%00111111
	cmp	#3
	beq	90$
	ldy	curTagNum
	cpy	#6
	bcc	90$
	cpy	#12
	bcc	40$
	cpy	#22
	bcc	90$
	cpy	#29	;+++check this with new tags.
	bcs	90$
 40$
	jsr	FlushText
	jsr	Stk3ToLMarg
;	ldx	#3
;	jsr	PullStack
;	sta	leftMargin+1
;	ldx	#3
;	jsr	PullStack
;	sta	leftMargin+0
	lda	listMode
	and	#%00111111
	sta	listMode
 90$
	rts

InitLnkTable:
	ldx	#0
	stx	nxtLnkPtr
 10$
	lda	#0
	sta	linksToStore+0,x
	sta	linksToStore+1,x
	lda	#%11111111
	sta	linksToStore+3,x
;	lda	linkBank
	.byte	$af,[linkBank,]linkBank,0
	sta	linksToStore+2,x
	inx
	inx
	inx
	inx
	cpx	#160
	bcc	10$
	rts

DoHeadTag:
	LoadB	titleString,#0
	jsr	SaveHTMPtr
	jsr	FindHead
	bcc	90$
	bit	tagMode	;is this </HEAD>?
	bmi	90$	;branch if so.
	lda	htmlMode
	ora	#%10000000
	sta	htmlMode
 40$
	jsr	FlushTag
;+++add code here to parse the HEAD area.
 50$
	jsr	SaveHTMPtr
	jsr	FindNxtTag
	bcs	60$
	rts
 60$
	lda	curTagNum
	cmp	#1	;is this a HEAD tag?
	beq	70$
	jsr	FlushTag
	lda	curTagNum
	cmp	#3
	bne	50$
	beq	90$
 70$
	bit	tagMode	;is this a closing tag?
	bpl	40$	;branch if not.
	jsr	FlushTag
	lda	htmlMode
	and	#%01111111
	sta	htmlMode
	rts
 90$
	lda	htmlMode
	and	#%01111111
	sta	htmlMode
	jmp	RstrHTMPtr


SaveHTMPtr:
	MoveW	a0,htmlSave
	MoveB	a1L,htmlSave+2
	MoveB	nhtmlSize+2,snhtmlSize+2
	MoveB	tagPtr+0,stagPtr+0
	MoveB	tagPtr+1,stagPtr+1
	MoveB	tagPtr+2,stagPtr+2
	MoveB	atagPtr+0,satagPtr+0
	MoveB	atagPtr+1,satagPtr+1
	MoveB	atagPtr+2,satagPtr+2
	rts

RstrHTMPtr:
	MoveW	htmlSave,a0
	MoveB	htmlSave+2,a1L
	MoveB	snhtmlSize+2,nhtmlSize+2
	MoveB	stagPtr+0,tagPtr+0
	MoveB	stagPtr+1,tagPtr+1
	MoveB	stagPtr+2,tagPtr+2
	MoveB	satagPtr+0,atagPtr+0
	MoveB	satagPtr+1,atagPtr+1
	MoveB	satagPtr+2,atagPtr+2
	rts

htmlSave:
	.block	3
snhtmlSize:
	.block	1
stagPtr:
	.block	3
satagPtr:
	.block	3

FindLTChar:
	lda	#'<'
	.byte	44
FindGTChar:
	lda	#'>'
FindChar:
	sta	charToFind
	clc
;	lda	[a0]
	.byte	$a7,a0
 10$
	cmp	charToFind
	beq	30$
 20$
	jsr	LdaNxtChar
	bcs	10$
 30$
	rts		;carry is set from comparisons.

charToFind:
	.block	1


LdaNxtChar:
	jsr	PntNxtChar
;	lda	[a0]
	.byte	$a7,a0
	rts

PntNxtChar:
	lda	a1L
	cmp	lhtmlByte+2
	bne	30$
	lda	a0H
	cmp	lhtmlByte+1
	bne	30$
	lda	a0L
	cmp	lhtmlByte+0
	bne	30$
	clc
	rts
 30$
	inc	a0L
	bne	50$
	inc	a0H
	bne	50$
	phy
	phx
	ldx	a1L
	jsl	SNxtBank,0
	bcs	45$
	plx
	ply
	LoadB	a0L,#$ff
	sta	a0H
	rts
 45$
	inc	nhtmlSize+2
	stx	a1L
	plx
	ply
 50$
	sec
	rts

;this is similar to LdaNxtChar except that
;it will also activate the progress bar. This
;is only called by the routines that put characters
;on the screen.
LdaNShow:
	lda	a1L
	cmp	lhtmlByte+2
	bne	30$
	lda	a0H
	cmp	lhtmlByte+1
	bne	30$
	lda	a0L
	cmp	lhtmlByte+0
	bne	30$
	clc
	rts
 30$
	inc	a0L
	bne	50$
	inc	a0H
	bne	50$
	phy
	phx
	ldx	a1L
	jsl	SNxtBank,0
	bcs	45$
	plx
	ply
	LoadB	a0L,#$ff
	sta	a0H
	rts
 45$
	inc	nhtmlSize+2
	stx	a1L
	plx
	ply
 50$
	dec	prgrssCounter
	bne	70$
	jsl	SCkAbortKey,0
	bcc	90$
	MoveW	a0,nhtmlSize
	jsr	ShowFrmProgress
 70$
;	lda	[a0]
	.byte	$a7,a0
	sec
 90$
	rts

FindISOMatch:
	jsr	SaveHTMPtr
	jsr	LdaNxtChar
	bcc	90$
	cmp	#'#'
	bne	ISOEntity
	ldy	#0
 10$
	phy
	jsr	LdaNxtChar
	ply
	bcc	20$
	cmp	#'0'
	bcc	25$
	cmp	#'9'+1
	bcs	25$
	sta	isoString,y
	iny
	cpy	#3
	bcc	10$
	phy
	jsr	LdaNxtChar
	ply
	bcs	25$
 20$
	lda	#0
 25$
	sta	endNumChar
	sty	numISOChars
	lda	#0
	sta	isoString,y
	LoadW	r0,#isoString
	jsr	Str2Value
	bcc	90$
	lda	r7H
	bne	90$
	PushB	r7L
	ldy	numISOChars
	iny
	lda	endNumChar
	cmp	#59
	bne	50$
	iny
 50$
	jsr	RstrNAdd
	pla
	rts
 90$
	jsr	RstrHTMPtr
	lda	#'&'
	rts


ISOEntity:
	sta	isoString+0
	ldy	#1
 10$
	phy
	jsr	LdaNxtChar
	ply
	bcc	30$
	sta	isoString,y
	iny
	cpy	#7
	bcc	10$
 30$
	ldx	#0
 40$
	jsr	CkISOCharacter
	bcs	75$
	inx
	cpx	#[(iso2Table-iso1Table)
	bcc	40$
	ldx	#0
 50$
	jsr	CkISOBTable
	bcs	75$
	inx
	cpx	#[(isoB2Table-isoB1Table)
	bcc	50$
	jsr	RstrHTMPtr
	lda	#'&'
	rts
 75$
	pha
	lda	isoString,y
	cmp	#59
	bne	80$
	iny
 80$
	jsr	RstrNAdd
	pla
	rts

endNumChar:
	.block	1
numISOChars:
	.block	1
isoString:
	.block	8

RstrNAdd:
	jsr	RstrHTMPtr
	cpy	#0
	beq	50$
 20$
	jsr	PntNxtChar
	dey
	bne	20$
 50$
	rts

CkISOCharacter:
	ldy	#0
	lda	isoString,y
 10$
	cmp	iso1Table,x
	beq	20$
	inx
	cpx	#[(iso2Table-iso1Table)
	bcc	10$
	clc
	rts
 20$
	iny
	lda	iso2Table,x
	cmp	isoString,y
	bne	90$
	iny
	lda	iso3Table,x
	cmp	isoString,y
	bne	90$
	iny
	lda	iso4Table,x
	beq	40$
	cmp	isoString,y
	bne	90$
	iny
	lda	iso5Table,x
	beq	40$
	cmp	isoString,y
	bne	90$
	iny
	lda	iso6Table,x
	beq	40$
	cmp	isoString,y
	bne	90$
	iny
 40$
	txa
	clc
	adc	#160
	sec
	rts
 90$
	clc
	rts


iso1Table:
	.byte	"nicpcybs"
	.byte	"ucolnsrm"
	.byte	"dpssampm"
	.byte	"csorfffi"
	.byte	"AAAAAAAC"
	.byte	"EEEEIIII"
	.byte	0,"NOOOOOt"
	.byte	"OUUUU",0,0,"s"
	.byte	"aaaaaaac"
	.byte	"eeeeiiii"
	.byte	0,"noooood"
	.byte	"ouuuu",0,0,"y"
iso2Table:
	.byte	"beeouere"
	.byte	"moraohea"
	.byte	"eluuciai"
	.byte	"eurarrrq"
	.byte	"gacturEc"
	.byte	"gacugacu"
	.byte	0,"tgactui"
	.byte	"sgacu",0,0,"z"
	.byte	"gacturec"
	.byte	"gacugacu"
	.byte	0,"tgactui"
	.byte	"sgacu",0,0,"u"
iso3Table:
	.byte	"sxnurnvc"
	.byte	"lpdqtygc"
	.byte	"guppucrd"
	.byte	"dpdqaaau"
	.byte	"rciimile"
	.byte	"rcimrcim"
	.byte	0,"irciimm"
	.byte	"lrcim",0,0,"l"
	.byte	"rciimile"
	.byte	"rcimrcim"
	.byte	0,"irciimv"
	.byte	"lrcim",0,0,"m"

iso4Table:
	.byte	"pctnr",0,"bt"
	.byte	0,"yfu",0,0,0,"r"
	.byte	0,"s23trad"
	.byte	"i1muccce"
	.byte	"aurllnid"
	.byte	"aurlaurl"
	.byte	0,"laurlle"
	.byte	"aaurl",0,0,"i"
	.byte	"aurllnid"
	.byte	"aurlaurl"
	.byte	0,"laurll",0
	.byte	"aaurl",0,0,"l"
iso5Table:
	.byte	0,"l",0,"de",0,"a",0
	.byte	0,0,0,"o",0,0,0,0
	.byte	0,"m",0,0,"eo",0,"o"
	.byte	"l",0,0,"o113s"
	.byte	"vtcd",0,"ggi"
	.byte	"vtc0vtc",0
	.byte	0,"dvtcd",0,"s"
	.byte	"svtc",0,0,0,"g"
	.byte	"vtcd",0,"ggi"
	.byte	"vtc0vtc",0
	.byte	0,"dvtcd",0,0
	.byte	"svtc",0,0,0,0
iso6Table:
	.byte	0,0,0,0,"n",0,"r",0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,"n",0,0,0,0,0,"t"
	.byte	0,0,0,0,"424t"
	.byte	"ee",0,"e",0,0,0,"l"
	.byte	"ee",0,0,"ee",0,0
	.byte	0,"eee",0,"e",0,0
	.byte	"hee",0,0,0,0,0
	.byte	"ee",0,"e",0,0,0,"l"
	.byte	"ee",0,0,"ee",0,0
	.byte	0,"eee",0,"e",0,0
	.byte	"hee",0,0,0,0,0


CkISOBTable:
	ldy	#0
	lda	isoString,y
 10$
	cmp	isoB1Table,x
	beq	20$
	inx
	cpx	#[(isoB2Table-isoB1Table)
	bcc	10$
	clc
	rts
 20$
	iny
	lda	isoB2Table,x
	cmp	isoString,y
	bne	50$
	iny
	lda	isoB3Table,x
	beq	40$
	cmp	isoString,y
	bne	50$
	iny
	lda	isoB4Table,x
	beq	40$
	cmp	isoString,y
	bne	50$
	iny
 40$
	lda	isoBCharTable,x
	sec
	rts
 50$
	clc
	rts

isoB1Table:
	.byte	"eeqalg"
isoB2Table:
	.byte	"mnumtt"
isoB3Table:
	.byte	"ssop",0,0
isoB4Table:
	.byte	"ppt",0,0,0

isoBCharTable:
	.byte	160,160,34,38,60,62

CapCharacter:
	cmp	#'z'+1
	bcs	50$
	cmp	#'a'
	bcc	50$
	sbc	#32
 50$
	rts

CkItalOverlap:
	sta	lastRdChar
	sta	lastCRChar
	bit	lastItalic
	bpl	50$
	bit	italicMode
	bmi	50$
	PushB	tagMode
	LoadB	tagMode,#%00000000
	jsr	TItalic
	PopB	tagMode
	lda	#' '
	jsr	PutOurChar
	PushB	tagMode
	LoadB	tagMode,#%10000000
	jsr	TItalic
	PopB	tagMode
	lda	lastRdChar
 50$
	jsr	PutOurChar
	MoveB	italicMode,lastItalic
	rts

lastItalic:
	.block	1
lastCRChar:
	.block	1

FrmtA0Text:
;	lda	[a0]
	.byte	$a7,a0
	beq	70$
 10$
	cmp	#'<'
	bne	20$
	jsr	DoNxtTag
	bcs	10$
	bcc	FA0T75
 20$
	cmp	#'&'
	bne	25$
	jsr	FindISOMatch
	bra	60$
 25$
	cmp	#160
	bcs	60$
	cmp	#127
	bcs	70$
	cmp	#33
	bcs	60$
	bit	preMode
	bpl	55$
	cmp	#' '
	beq	60$
	cmp	#TAB
	beq	59$
	cmp	#LF
	bne	30$
	lda	lastCRChar
	cmp	#CR
	bne	45$
	LoadB	lastCRChar,#0
	beq	70$	;branch always.
 30$
	sta	lastCRChar
	cmp	#CR
	bne	70$
 45$
	jsr	FlushText
	bra	70$
 55$
	lda	lastRdChar
	cmp	#' '
	beq	70$
 59$
	lda	#' '
 60$
	jsr	CkItalOverlap
 70$
	jsr	LdaNShow
	bcs	10$
FA0T75:
	jmp	DumpText

PutOurChar:
	cmp	#33
	bcc	10$
	cmp	#127
	bcc	20$
	cmp	#160
	bcs	20$
 10$
	bit	preMode
	bmi	20$
	bit	textInString
	bpl	60$
	lda	lastPutChar
	jsr	IsSpace
	beq	60$
	lda	#' '
 20$
	sta	reqISOType
	sta	charWaiting
	cmp	#127
	bcc	40$
	cmp	#161
	bcs	30$
	lda	#32
	sta	reqISOType
	bne	40$
 30$
	sbc	#129
 40$
	pha
	jsr	CmpFntRequest
	beq	45$
	jsr	ReLdReqFont
 45$
	pla
	ldx	currentMode
	jsl	SGetRealSize,0
	tya
	clc
	adc	textStrLength+0
	sta	r13L
	lda	textStrLength+1
	adc	#0
	sta	r13H
	cmp	marginWidth+1
	bne	50$
	lda	r13L
	cmp	marginWidth+0
 50$
	bcc	70$
	bit	textInString
	bpl	70$
	jsr	DumpNWrap
	bcc	65$
	jsr	TLB3
	lda	charWaiting
	cmp	#' '
	bne	20$
 60$
	sec
 65$
	rts
 70$

;continuation of PutOurChar.
POC2:
	bit	textInString
	bmi	72$
	LoadB	tallestBaseline,#0
	sta	tallestHeight
 72$
	lda	baselineOffset
	cmp	tallestBaseline
	bcc	75$
	sta	tallestBaseline
 75$
	lda	curHeight
	cmp	tallestHeight
	bcc	80$
	sta	tallestHeight
 80$
	MoveW	r13,textStrLength
	ldy	textStrPtr
	lda	charWaiting
	sta	textString,y
	sta	lastPutChar
	inc	textStrPtr
	jsr	IsSpace
	bne	85$
	sty	spacePtr
	MoveW	r13,lastSpcLength
 85$
	LoadB	charWaiting,#0
	LoadB	textInString,#%10000000
	sec
	rts



DumpText:
	lda	#%10000000
	.byte	44
DumpNWrap:
	lda	#%00000000
	sta	ignoreWrap
	lda	textStrPtr
	cmp	#2
	bcs	10$
	LoadB	textInString,#0
	sta	ignoreWrap
	rts
 10$
	clc
	lda	crsrY
	adc	windowTop
	adc	tallestBaseline
	sta	r1H
	ldy	textStrPtr
	lda	#0
	sta	textString,y
	LoadW	r0,#textString
	jsr	PutOurString
	bcc	85$	;branch if word wrap occured.
	LoadB	textStrPtr,#0
	sta	lastPutChar
	sta	textStrLength+0
	sta	textStrLength+1
	sta	textInString
	jsr	PutStyle
	jsr	PutFont
 85$
	LoadB	spacePtr,#0
	sta	ignoreWrap
	sta	lastItalic
	sec
	lda	r1H
	sbc	tallestBaseline
	sbc	windowTop
	sta	crsrY
	lda	listMode
	bpl	89$
	and	#%00111111
	cmp	#3
	beq	89$
	lda	justification
	cmp	#1
	beq	89$
;	lda	listMode
;	and	#%01111111
;	sta	listMode
	MoveW	listMargin,leftMargin
	jsr	GetMrgnWidth
 89$
	rts


PutOurString:
	bit	ignoreWrap
	bmi	5$
	lda	lastPutChar
	jsr	IsSpace
	beq	5$
	lda	charWaiting
	jsr	IsSpace
	beq	5$
	ldy	spacePtr
	bne	10$
 5$
	jsr	PutThisString
	sec
	rts
 10$
	lda	#0
	sta	(r0),y
	PushW	textStrLength
	MoveW	lastSpcLength,textStrLength
	jsr	PutThisString
	sec
	pla
	sbc	lastSpcLength+0
	sta	textStrLength+0
	pla
	sbc	lastSpcLength+1
	sta	textStrLength+1
	MoveB	textStrPtr,cktextStrPtr
	LoadB	textStrPtr,#0
	jsr	PutStyle
	jsr	PutFont
	ldy	spacePtr
	iny
	ldx	textStrPtr
 20$
	lda	textString,y
	sta	textString,x
	inx
	iny
	cpy	cktextStrPtr
	bcc	20$
	stx	textStrPtr
	lda	tdMode
	beq	80$
	rep	%00100000
	lda	rightMargin
	cmp	maxCellRight
	bcc	70$
	sta	maxCellRight
 70$
	sep	%00100000
 80$
	clc
	rts

cktextStrPtr:
	.block	1

charToPut:
	.block	1

PutThisString:
	LoadB	waitForPrintable,#0
PTS2:
	ldy	#0
	lda	(r0),y
	bne	15$
	rts
 15$
	sty	reqISOType
	cmp	#32
	bcc	70$
	cmp	#127
	bcc	40$
	cmp	#160
	beq	35$
	bcc	65$
	sta	reqISOType
 30$
	sec
	sbc	#129
	.byte	44
 35$
	lda	#' '
 40$
	sta	charToPut
	bit	waitForPrintable
	bmi	55$
	LoadB	waitForPrintable,#%10000000
	jsr	SetR11ToLeft
 55$
	jsr	CmpFntRequest
	beq	60$
	jsr	ReLdAReqFont
 60$
	bit	anchorStarted
	bvc	63$
	jsr	StartAnchor
 63$
	lda	charToPut
	jsr	JSLSmallPutChar
	LoadB	stuffOnScreen,#%10000000
	jsr	AdjRSides	;adjust for anchors and table cells.
 65$
	inc	r0L
	bne	PTS2
	inc	r0H
	bne	PTS2	;branch always.
 70$
;	jmp	DoEscStrings
;fall through to next page...

;previous page falls through to here.
;handle the escape strings.
DoEscStrings:
	ldx	#[(endEBrsTable-escBrsTable)-1
 10$
	cmp	escBrsTable,x
	beq	20$
	dex
	bpl	10$
	jsr	Add1ToR0
	jmp	PTS2
 20$
	txa
	asl	a
	tax
	iny
	lda	(r0),y
;	jsr	(escJsrTable,x)
	.byte	$fc,[escJsrTable,]escJsrTable
	jmp	PTS2

escBrsTable:
	.byte	ESC_STYLE,ESC_LMARGIN
	.byte	ESC_RMARGIN,ESC_LSTMARGIN
	.byte	ESC_NEWCARDSET,ESC_SETMODE
	.byte	ESC_CLRMODE
	.byte	ESC_ONANCHOR,ESC_OFFANCHOR
	.byte	ESC_NMANCHOR
endEBrsTable:

escJsrTable:
	.word	EscStyle,EscLMargin
	.word	EscRMargin,EscLSetMargin
	.word	EscNewCardset,EscSetMode
	.word	EscClrMode
	.word	OnAnchor,OffAnchor
	.word	NmAnchor

EscStyle:
	sta	currentMode
	jmp	Add2ToR0

EscLMargin:
	sta	leftMargin+0
	iny
	lda	(r0),y
	sta	leftMargin+1
	jsr	Add3ToR0
	jmp	GetMrgnWidth

EscRMargin:
	sta	rightMargin+0
	iny
	lda	(r0),y
	sta	rightMargin+1
	jsr	Add3ToR0
	jmp	GetMrgnWidth

EscLSetMargin:
	MoveW	r11,listMargin
	jmp	Add1ToR0

EscNewCardset:
	sta	reqFntNum
	iny
	lda	(r0),y
	sta	reqISOType
	iny
	lda	(r0),y
	beq	45$
	cmp	#8
	bcc	50$
	lda	#7
	.byte	44
 45$
	lda	#1
 50$
	sta	reqFSize
	jmp	Add4ToR0

EscSetMode:
	ora	currentMode
	sta	currentMode
	jmp	Add2ToR0

EscClrMode:
	eor	#%11111111
	and	currentMode
	sta	currentMode
	jmp	Add2ToR0


AdjRSides:
	bit	anchorStarted
	bpl	20$
	sec
	lda	r11L
	sbc	#1
	sta	anchorRight+0
	lda	r11H
	sbc	#0
	sta	anchorRight+1
 20$
	lda	tdMode
	beq	50$
	rep	%00100000
	lda	r11
	cmp	maxCellRight
	bcc	40$
	sta	maxCellRight
 40$
	sep	%00100000
 50$
	rts

OffAnchor:
	jsr	Add1ToR0
	jmp	StopAnchor

OnAnchor:
	LoadB	anchorStarted,#%11000000
	jmp	Add1ToR0

NmAnchor:
	jsr	Add1ToR0
	jsr	StartAnchor
	jmp	StopAnchor

CmpFntRequest:
	lda	reqFntNum
	cmp	desFntNum
	bne	55$
	lda	reqISOType
	eor	desISOType	;check if bit 7 matches.
	and	#%10000000
	bne	55$
	lda	reqFSize
	cmp	desFSize
 55$
	rts

reqFntNum:
	.block	1
reqISOType:
	.block	1
reqFSize:
	.block	1


SetR11ToLeft:
	lda	justification
	beq	50$
	cmp	#1
	beq	30$
	cmp	#2
	bne	50$	;+++full justify not yet supported.
	sec
	lda	rightMargin+0
	sbc	textStrLength+0
	sta	r11L
	lda	rightMargin+1
	sbc	textStrLength+1
	sta	r11H
	rts
 30$
	sec
	lda	marginWidth+0
	sbc	textStrLength+0
	sta	r11L
	lda	marginWidth+1
	sbc	textStrLength+1
	bcs	40$
	LoadB	r11L,#0
 40$
	lsr	a
	pha
	lda	r11L
	ror	a
	clc
	adc	leftMargin+0
	sta	r11L
	pla
	adc	leftMargin+1
	sta	r11H
	rts
 50$
	MoveW	leftMargin,r11
	rts

Add1ToR0:
	lda	#1
	.byte	44
Add2ToR0:
	lda	#2
	.byte	44
Add3ToR0:
	lda	#3
	.byte	44
Add4ToR0:
	lda	#4
Add2R0:
	clc
	adc	r0L
	sta	r0L
	bcc	10$
	inc	r0H
 10$
	rts


IsSpace:
	cmp	#' '
	beq	10$
	cmp	#160
 10$
	rts

ScrollSegment:
	jsr	StashBSegment
	lda	crsrY
	and	#%11111000
	jsr	Add2CPgTop
	jsr	FetchBSegment
	lda	crsrY
	and	#%00000111
	sta	crsrY
	rts

Add2CPgTop:
	clc
;	adc	curPageTop+0
	.byte	$6f,[(curPageTop+0),](curPageTop+0),0
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
	bcc	20$
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	adc	#0
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	adc	#0
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
 20$
	rts

.if	C64
StashBSegment:
	bit	stuffOnScreen
	bpl	25$
	LoadB	stuffOnScreen,#%00000000
	ldx	#r1
	jsr	CalcPgTop
	bcc	25$
	LoadW	r0,#$6000+(40*40)
	LoadB	r4L,#20
	LoadB	r3L,#0
	stx	r3H
 20$
	jsr	PutSegment
	bcs	30$
 25$
	rts
 30$
	AddVW	#320,r0
	clc
	lda	r1L
	adc	#[312
	sta	r1L
	lda	r1H
	adc	#]312
	sta	r1H
	ora	r1L
	bne	50$
	ldx	r3H
	jsr	GetPgBank
	bcc	90$
	stx	r3H
 50$
	dec	r4L
	bne	20$
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	bne	90$
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	bne	90$
;	lda	curPageTop+0
	.byte	$af,[(curPageTop+0),](curPageTop+0),0
	cmp	#160	;+++this should be the bottom of
			;+++the current frame.
	bcs	90$
	pha
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	pha
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	pha
	lda	#0
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
	jsl	SFetchFSegment,0
	pla
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
	pla
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
	pla
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
 90$
	rts

PutSegment:
	CmpWI	r1,#(-311)
	bcs	20$
	jsl	SDoSuperMove,0
	sec
	rts
 20$
	PushW	r0
	PushB	r1H
	sta	r2H
	PushB	r1L
	sta	r2L
	ldx	#r2
	jsl	SDabs,0
	jsl	SDoSuperMove,0
	clc
	lda	r0L
	adc	r2L
	sta	r0L
	lda	r0H
	adc	r2H
	sta	r0H
	sec
	lda	#[312
	sbc	r2L
	sta	r2L
	lda	#]312
	sbc	r2H
	sta	r2H
	ldx	r3H
	jsr	GetPgBank
	bcc	90$
	stx	r3H
	LoadB	r1L,#0
	sta	r1H
	jsl	SDoSuperMove,0
	sec
 90$
	PopW	r1
	PopW	r0
	LoadW	r2,#312
	rts


FetchBSegment:
	ldx	#r0
	jsr	CalcPgTop
	bcc	90$
	LoadW	r1,#$6000+(40*40)
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
	jsr	GetPgBank
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
	jsl	SDoSuperMove,0
	sec
	rts
 20$
	PushW	r1
	PushB	r0H
	sta	r2H
	PushB	r0L
	sta	r2L
	ldx	#r2
	jsl	SDabs,0
	jsl	SDoSuperMove,0
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
	jsr	GetPgBank
	bcc	90$
	stx	r3L
	LoadB	r0L,#0
	sta	r0H
	jsl	SDoSuperMove,0
	sec
 90$
	PopW	r0
	PopW	r1
	LoadW	r2,#312
	rts


CalcPgTop:
;	lda	curPageTop+0
	.byte	$af,[(curPageTop+0),](curPageTop+0),0
	and	#%11111000
	sta	$00,x
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	sta	$01,x
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	sta	$02,x
	LoadB	r2H,#39
	ldy	#r2H
	jsl	SMult24,0
	lda	r6L
	sta	$00,x
	lda	r6H
	sta	$01,x
;	lda	pageBank
	.byte	$af,[pageBank,]pageBank,0
	tax
	lda	r7L
	beq	60$
 20$
	jsr	GetPgBank
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
StashBSegment:
	bit	stuffOnScreen
	bmi	10$
	rts
 10$
	LoadB	stuffOnScreen,#%00000000
	ldx	#r1
	jsr	CalcPgTop
	LoadW	r0,#$6000+(40*80)
	LoadB	r3L,#0
	stx	r3H
	LoadB	r4L,#100-40
	jsr	StashBRasters
	LoadB	r4L,#100
	LoadW	r0,#$a040
	jsr	StashBRasters
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	bne	90$
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	bne	90$
;	lda	curPageTop+0
	.byte	$af,[(curPageTop+0),](curPageTop+0),0
	cmp	#160	;+++this should be the bottom of
			;+++the current frame.
	bcs	90$
	pha
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	pha
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	pha
	lda	#0
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
	jsl	SFetchFSegment,0
	pla
;	sta	curPageTop+2
	.byte	$8f,[(curPageTop+2),](curPageTop+2),0
	pla
;	sta	curPageTop+1
	.byte	$8f,[(curPageTop+1),](curPageTop+1),0
	pla
;	sta	curPageTop+0
	.byte	$8f,[(curPageTop+0),](curPageTop+0),0
 90$
	rts

StashBRasters:
 20$
	jsr	PutSegment
	bcc	90$
	AddVW	#78,r1
	AddVW	#80,r0
	dec	r4L
	bne	20$
 90$
	rts

PutSegment:
	CmpWI	r1,#(-77)
	bcs	20$
	jsl	SDoSuperMove,0
	sec
	rts
 20$
	PushW	r0
	PushB	r1H
	sta	r2H
	PushB	r1L
	sta	r2L
	ldx	#r2
	jsl	SDabs,0
	jsl	SDoSuperMove,0
	clc
	lda	r0L
	adc	r2L
	sta	r0L
	lda	r0H
	adc	r2H
	sta	r0H
	sec
	lda	#[78
	sbc	r2L
	sta	r2L
	lda	#]78
	sbc	r2H
	sta	r2H
	ldx	r3H
	jsr	GetPgBank
	bcc	90$
	stx	r3H
	LoadB	r1L,#0
	sta	r1H
	jsl	SDoSuperMove,0
	sec
 90$
	PopW	r1
	PopW	r0
	LoadW	r2,#78
	rts

CalcPgTop:
;	lda	curPageTop+0
	.byte	$af,[(curPageTop+0),](curPageTop+0),0
	and	#%11111000
	sta	$00,x
;	lda	curPageTop+1
	.byte	$af,[(curPageTop+1),](curPageTop+1),0
	sta	$01,x
;	lda	curPageTop+2
	.byte	$af,[(curPageTop+2),](curPageTop+2),0
	sta	$02,x
	LoadB	r2H,#78
	ldy	#r2H
	jsl	SMult24,0
	lda	r6L
	sta	$00,x
	lda	r6H
	sta	$01,x
;	lda	pageBank
	.byte	$af,[pageBank,]pageBank,0
	tax
	lda	r7L
	beq	60$
 20$
	jsr	GetPgBank
	bcc	90$
	dec	r7L
	bne	20$
 60$
	LoadW	r2,#78
	sec
	rts
 90$
	clc
	rts

FetchBSegment:
	ldx	#r0
	jsr	CalcPgTop
	LoadW	r1,#$6000+(40*80)
	LoadB	r3H,#0
	stx	r3L
	LoadB	r4L,#100-40
	jsr	FetchBRasters
	LoadB	r4L,#100
	LoadW	r1,#$a040
FetchBRasters:
 20$
	jsr	GetSegment
	bcc	90$
	AddVW	#78,r0
	AddVW	#80,r1
	dec	r4L
	bne	20$
 90$
	rts


GetSegment:
	CmpWI	r0,#(-77)
	bcs	20$
	jsl	SDoSuperMove,0
	sec
	rts
 20$
	PushW	r1
	PushB	r0H
	sta	r2H
	PushB	r0L
	sta	r2L
	ldx	#r2
	jsl	SDabs,0
	jsl	SDoSuperMove,0
	clc
	lda	r1L
	adc	r2L
	sta	r1L
	lda	r1H
	adc	r2H
	sta	r1H
	sec
	lda	#[78
	sbc	r2L
	sta	r2L
	lda	#]78
	sbc	r2H
	sta	r2H
	ldx	r3L
	jsr	GetPgBank
	bcc	90$
	stx	r3L
	LoadB	r0L,#0
	sta	r0H
	jsl	SDoSuperMove,0
	sec
 90$
	PopW	r0
	PopW	r1
	LoadW	r2,#78
	rts

.endif

GetPgBank:
	jsl	SGetNxtBank,0
	bcc	90$
	cmp	#0
	bne	40$
	phx
	jsl	SClearBank,0
	plx
 40$
	sec
 90$
	rts

;point r0 to a font name and load acc with a number requesting
;a point size (1,2,3,4,5,6, or 7) and this will load
;the character set and make it the current set.
;If the upper ISO character set is desired, set bit 7
;of the accumulator.
JGetDesFont:
	sta	desISOType
	and	#%01111111
	beq	10$
	cmp	#8
	bcc	15$
	lda	#7
	.byte	44
 10$
	lda	#1
 15$
	sta	desFSize
	jsr	IsFontDefined	;is the desired font listed?
	bcc	50$	;branch if not.
	jmp	ReLdDesFont
 50$
	jsr	LdDefFont
	clc
	rts

defFontName:
	.byte	"default",0
hdlFontName:
	.byte	"headline",0
monFontName:
	.byte	"monospaced",0

ReLdAReqFont:
	jsr	ReqToDesFont
;fall through...
ReLdAFont:
	PushW	r0
	PushW	r11
	PushB	r1H
	jsr	ReLdDesFont
	PopB	r1H
	PopW	r11
	PopW	r0
	rts

ReqToDesFont:
	MoveB	reqFntNum,desFntNum
	MoveB	reqISOType,desISOType
	MoveB	reqFSize,desFSize
	rts

ReLdReqFont:
	jsr	ReqToDesFont
;fall through...
ReLdDesFont:
	jsr	PntFontRecord
	bcs	RLDF2
	jsr	LdDefFont
	clc
	rts

LdDefFont:
	LoadW	r0,#defFontName ;switch to the default font.
;	phk
	.byte	$4b
	PopB	r1L
	jsr	IsFontDefined	;is the default font listed?
	bcc	RLDF3	;branch if not.
	jsr	PntFontRecord
	bcc	RLDF3
RLDF2:
	jsr	LoadDesFont
	bcc	RLDF3
	MoveB	desISOType,reqISOType
	MoveB	desFSize,reqFSize
	MoveB	desFntNum,reqFntNum
	LoadW	r0,#fontBase
	jsl	SLoadCharSet,0
	sec
	rts
RLDF3:
	LoadB	desISOType,#%00000000
	sta	reqISOType
	jsl	SUseSystemFont,0
	clc
	rts

;point r0-r1L to a font name and this will determine if the font is listed
;in the font table, and if so, then the carry will be set and desFntNum
;will indicate the position in the table.
IsFontDefined:
;	lda	numFonts	;any fonts defined?
	.byte	$af,[numFonts,]numFonts,0
	sta	numXFonts
	beq	55$	;branch if not.
;	lda	fListPtr+0
	.byte	$af,[(fListPtr+0),](fListPtr+0),0
	sta	r9L
;	lda	fListPtr+1
	.byte	$af,[(fListPtr+1),](fListPtr+1),0
	sta	r9H
;	lda	fontBank
	.byte	$af,[fontBank,]fontBank,0
	sta	r10L
	ldx	#0
 5$
	ldy	#0
 10$
;	lda	[r9],y
	.byte	$b7,r9
	beq	60$
;	cmp	[r0],y
	.byte	$d7,r0
	bne	30$
	iny
	bne	10$	;branch always, hopefully.
	clc		;something wrong, name too big.
	rts		;font not found.
 30$
;	lda	[r9],y
	.byte	$b7,r9
	beq	40$
	iny
	bne	30$
	clc
	rts
 40$
	iny
	tya
	clc
	adc	r9L
	sta	r9L
	bcc	50$
	inc	r9H
 50$
	inx
	cpx	numXFonts	;checked all fonts yet?
	bcc	5$	;branch if not.
 55$
	clc
	rts
 60$
;	cmp	[r0],y	;pointing to both null terminators?
	.byte	$d7,r0
	bne	40$	;branch if not.
	stx	desFntNum
	sec
	rts

;load desFntNum with a font listing number and this will
;point r9 to the record entry within table 4.
PntFontRecord:
;	lda	numScrFonts
	.byte	$af,[numScrFonts,]numScrFonts,0
	sta	numXScrFonts
;	lda	fontBank
	.byte	$af,[fontBank,]fontBank,0
	sta	r10L
	LoadB	r9L,#0
	sta	r9H
	bit	desISOType
	bpl	10$
	inc	r9H
 10$
	lda	desFntNum
	asl	a
	tay
 15$
;	lda	[r9],y
	.byte	$b7,r9
	sta	r5L
	iny
;	lda	[r9],y
	.byte	$b7,r9
	sta	r5H
	ora	r5L
	beq	35$
	LoadW	r9,#$0200
	ldx	#0
	ldy	#0
 20$
;	lda	[r9],y
	.byte	$b7,r9
	cmp	r5L
	bne	30$
	iny
;	lda	[r9],y
	.byte	$b7,r9
	dey
	cmp	r5H
	beq	40$
 30$
	inx
	cpx	numXScrFonts
	bcs	35$
	iny
	iny
	bne	20$
	inc	r9H
	lda	r9H
	cmp	#4
	bcc	20$
 35$
	clc
	rts		;this font ID not available.
 40$
	LoadB	r9H,#0
	stx	r9L
	LoadB	r13L,#42
	ldx	#r9
	ldy	#r13L
	jsl	SBMult,0
	clc
	lda	r9H
	adc	#4
	sta	r9H
	sec
	rts

numXFonts:
	.block	1
numXScrFonts:
	.block	1

DEBUG128=0
.if	DEBUG128
ChgColor:
	sta	CC1+1
	phx
	phy
	ldx	#13
 10$
	lda	r0,x
	pha
	dex
	bpl	10$
CC1:
	lda	#0
	sta	r4H
	LoadB	r1L,#0
	LoadB	r1H,#2
	LoadB	r2L,#80
	LoadB	r2H,#2
	jsl	SColorRectangle,0
	ldx	#0
 30$
	pla
	sta	r0,x
	inx
	cpx	#14
	bcc	30$
	ply
	plx
	rts
.endif

;+++open the program directory first.
;point r9 at the record entry for the font.
;desFSize should also be loaded with 1-7.
;This will then either bring the font from
;fontBank into bank 0 or load it from disk
;into bank 0 in addition to placing it into
;storage within the fontBank.
LoadDesFont:
	lda	desFSize
	beq	3$
	cmp	#8
	bcc	5$
	lda	#7
	.byte	44
 3$
	lda	#1
 5$
	sta	desFSize
	clc
;	adc	baseFntSize
	.byte	$6f,[baseFntSize,]baseFntSize,0
	beq	10$
	bmi	10$
	cmp	#8
	bcc	20$
	lda	#7
	.byte	44
 10$
	lda	#1
 20$
	sta	tempFSize
	sec
	sbc	#1
	asl	a
	clc
	adc	r9L
	sta	r9L
	bcc	LDF1
	inc	r9H
LDF1:
	ldy	#0
;	lda	[r9],y
	.byte	$b7,r9
	iny
;	ora	[r9],y	;is this character set loaded yet?
	.byte	$17,r9
	beq	15$	;branch if not.
	jsr	FetchCharSet
	sec
	rts
 15$
	ldy	#28
;	lda	[r9],y
	.byte	$b7,r9	;does this size exist on disk?
	bne	LDF3	;branch if so.
LDF2:
	SubVW	#2,r9
	dec	tempFSize	;check the next size down.
	bne	LDF1
	clc		;character set not available.
	rts

;continued on next page...

;previous page continues here.
LDF3:
	sta	r1L
	iny
;	lda	[r9],y
	.byte	$b7,r9
	sta	r1H
	LoadW	r7,#fontBase
	LoadW	r2,#FONTBUFSIZE
	PushW	r9
	PushB	r10L
	jsl	SReadFile,0
	PopB	r10L
	PopW	r9
	txa
	bne	LDF2
	sec
	lda	r7L
	sbc	#[fontBase
	sta	r2L
	lda	r7H
	sbc	#]fontBase
	sta	r2H	;r2 holds the size in bytes.
	LoadW	r0,#fontBase
	jsr	GetFreeSpot
	ldy	#0
	lda	r1L
;	sta	[r9],y
	.byte	$97,r9
	iny
	lda	r1H
;	sta	[r9],y
	.byte	$97,r9
	ldy	#14
	lda	r2L
;	sta	[r9],y
	.byte	$97,r9
	iny
	lda	r2H
;	sta	[r9],y
	.byte	$97,r9
	LoadB	r3L,#0	;source bank.
;	lda	fontBank
	.byte	$af,[fontBank,]fontBank,0
	sta	r3H	;destination bank.
	jsl	SDoSuperMove,0
	sec
	rts

tempFSize:
	.block	1

FetchCharSet:
	ldy	#0
;	lda	[r9],y
	.byte	$b7,r9
	sta	r0L
	iny
;	lda	[r9],y
	.byte	$b7,r9
	sta	r0H
	LoadW	r1,#fontBase
	ldy	#14
;	lda	[r9],y
	.byte	$b7,r9
	sta	r2L
	iny
;	lda	[r9],y
	.byte	$b7,r9
	sta	r2H
	LoadB	r3H,#0
;	lda	fontBank
	.byte	$af,[fontBank,]fontBank,0
	sta	r3L
	jsl	SDoSuperMove,0
	clc
	lda	r1L
	adc	r2L
	sta	r7L	;let em know where the
	lda	r1H	;end of the font is.
	adc	r2H
	sta	r7H
	rts

;+++this needs to make room by knocking a character set
;+++out when the bank is too full.
GetFreeSpot:
	clc
;	lda	fEndData+0
	.byte	$af,[(fEndData+0),](fEndData+0),0
	sta	r1L
	adc	r2L
;	sta	fEndData+0
	.byte	$8f,[(fEndData+0),](fEndData+0),0
;	lda	fEndData+1
	.byte	$af,[(fEndData+1),](fEndData+1),0
	sta	r1H
	adc	r2H
;	sta	fEndData+1
	.byte	$8f,[(fEndData+1),](fEndData+1),0
	rts



