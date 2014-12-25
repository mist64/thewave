;************************************************************

;		BrowseC


;************************************************************



	.psect


CkLinkClick:
	bit	mouseData
	bpl	10$
 5$
	rts
 10$
	MoveW	mouseXPos,mouseXClick
	MoveB	mouseYPos,mouseYClick
	jsr	StopURLEditor
	bit	onAnchor
	bmi	70$
	lda	mouseYClick
	cmp	bWinTop
	bcs	5$
	lda	#0
 20$
	pha
	jsr	LdIconRegs
	MoveW	r3,r0
	jsr	Conv2Pixels
	jsr	IsMseInRegion
	cmp	#[TRUE
	beq	40$
	pla
	ina
	cmp	#[((endBITables-bIconTables)/8)
	bcc	20$
	lda	mouseYClick
	cmp	#24
	bcc	5$
	cmp	#39
	bcs	5$
	rep	%00100000
	lda	mouseXClick
.if	C64
	cmp	#[8
	.byte	]8
	bcc	30$
	cmp	#[304
	.byte	]304
.else
	cmp	#[16
	.byte	]16
	bcc	30$
	cmp	#[608
	.byte	]608
.endif
	bcc	35$
 30$
	sep	%00100000
	rts
 35$
	sep	%00100000
	jmp	StrtURLEditor
 40$
	pla
	lda	r0L
	ldx	r0H
	jmp	CallRoutine
 70$
	LoadB	dloadFlag,#%00000000
	sta	onAncEdRunning
	jmp	GetReqHTML


;this takes values from card registers r1L,
;r1H, r2L, and r2H and converts them to
;rectangle registers r2L, r2H, r3, and r4.
Conv2Pixels:
.if	C128
	lda	r1L
	bpl	10$
	asl	a
	sta	r1L
 10$
	lda	r2L
	bpl	20$
	asl	a
	sta	r2L
 20$
.endif
	lda	#0
	asl	r1L
	rol	a
	asl	r1L
	rol	a
	asl	r1L
	rol	a
	sta	r3H
	MoveB	r1L,r3L
	lda	r2L
	asl	a
	asl	a
	asl	a
	clc
	dea
	adc	r3L
	sta	r4L
	lda	r3H
	adc	#0
	sta	r4H
	MoveB	r1H,r2L
	lda	r2H
	dea
	clc
	adc	r2L
	sta	r2H
	rts

GetReqHTML:
	jsr	SvBrwsVectors
	MoveB	pageLoaded,svpageLoaded
	LoadB	urlBufPtr,#0
 5$
	jsr	SvURLFields
 6$
	jsr	LSepHREFString
;	jsr	SwpHREFURL
	jsr	CkOnNAnchor
	lda	prtclFound
	bne	10$
	jsr	CkPathField
	bne	50$
	jsr	CkAncField
	beq	50$
	bit	dloadFlag
	bmi	90$
	jmp	JmpAncName
 10$
	cmp	#4
	beq	60$
	cmp	#'A'
	bcs	60$
	cmp	#2
	bne	90$
 15$
	bit	commMode	;already got a PPP link?
	bmi	20$	;branch if so.
	jsr	StartInet	;dial out.
	bit	commMode	;login work OK?
	bpl	90$	;branch if not.
 20$
	lda	dloadFlag
	bpl	40$
	pha
	jsr	DLoadHTTP
	PopB	dloadFlag
	bra	90$
 40$
	jsr	DoHTTP
	bcs	70$
	bcc	5$
 50$
	bit	svpageLoaded
	bvs	15$
 60$
	bit	dloadFlag
	bmi	90$
	jsr	OpnPathDir
	bcc	90$
	jsr	RHTML2
	bcc	90$
 70$
	jsr	CkAncField
	bne	80$
	jmp	ShowPage
 80$
;	jsr	SwpHREFURL
	jsr	SvURLFields
	jsr	ShowPage
	jmp	JmpAncName
 90$
	MoveB	svpageLoaded,pageLoaded
	jsr	RstrURLFields
;	jsr	Href2URL
	jsr	LDoURLBar
	jmp	RstBrwsVectors

DLoadHTTP:
	LoadB	xFileName+0,#0
 10$
	jsr	DownHTTP
	bcs	90$
	jsr	LSepHREFString
	jsr	CkAbortKey
	bcs	10$
 90$
	rts

SvURLFields:
	phb
	PushB	prg2Bank
	plb
	ldy	#0
 10$
	lda	prtclField,y
	sta	prtclField+256,y
	iny
	bne	10$
	plb
	rts

RstrURLFields:
	phb
	PushB	prg2Bank
	plb
	ldy	#0
 10$
	lda	prtclField+256,y
	sta	prtclField,y
	iny
	bne	10$
	plb
	rts

SvAncField:
	phb
	PushB	prg2Bank
	plb
	ldy	#0
 10$
	lda	anchNmField,y
	sta	anchNmField+256,y
	iny
	cpy	#32
	bcc	10$
	plb
	rts

CkAncField:
	MoveB	prg2Bank,CAF2+3
CAF2:
;	lda	anchNmField
	.byte	$af,[anchNmField,]anchNmField,3
	rts

CkPathField:
	MoveB	prg2Bank,CPF2+3
CPF2:
;	lda	pathField
	.byte	$af,[pathField,]pathField,3
	rts


SwpHREFURL:
	phb
	PushB	prg2Bank
	plb
	ldy	#0
 10$
	lda	hrefString,y
	pha
	lda	urlString,y
	sta	hrefString,y
	pla
	sta	urlString,y
	iny
	bne	10$
	plb
	rts

Href2URL:
	phb
	PushB	prg2Bank
	plb
	ldy	#0
 10$
	lda	hrefString,y
	sta	urlString,y
	iny
	bne	10$
	plb
	rts

ClrURLString:
	MoveB	prg2Bank,CUS3+3
	ldx	#0
	txa
CUS3:
;	sta	urlString,x
	.byte	$9f,[urlString,]urlString,3 ;this can change.
	inx
	bne	CUS3
	rts

OpnPathDir:
	lda	prtclFound
	beq	15$
	cmp	#4
	beq	15$
	sec
	sbc	#'A'-8
	cmp	curDrive
	beq	5$
	jsr	SetDevice
 5$
	lda	partnFound
	beq	10$
	jsr	GetHeadTS
	ldx	partnFound
	cpx	r2L
	beq	10$
	jsr	GoXPartition
 10$
	jsr	OpenRoot
	bra	18$
 15$
	jsr	OpenURLDir
 18$
	LoadB	pathPtr,#0
 20$
	jsr	LReadInDirectory
	LoadW	r0,#pathField
	MoveB	prg2Bank,r1L
	LoadW	r6,#subPathName
	LoadB	r7L,#0
	ldy	#16
	lda	#0
 30$
	sta	subPathName,y
	dey
	bpl	30$
	ldy	pathPtr
	ldx	#0
 40$
;	lda	[r0],y
	.byte	$b7,r0
	bne	60$
	lda	subPathName
	beq	45$
	jsr	FindSubDir
	beq	20$
	cpx	#STRUCT_MISMATCH
	bne	45$
	sec
	rts
 45$
	jmp	FindIndexFile
 60$
	cmp	#'/'
	beq	80$
	cmp	#'.'
	bne	70$
	jsr	CkUp2Parent
	bcs	20$
 70$
	sta	subPathName,x
	iny
	inx
	cpx	#17
	bcc	40$
 80$
	iny
	sty	pathPtr
	jsr	FindSubDir
	bra	20$
 90$
	jsr	DoDiskError
	clc
	rts


FindSubDir:
	jsr	LFindLFile
	txa
	bne	90$
	ldx	#STRUCT_MISMATCH
	lda	dirEntryBuf+0
	and	#%10011111
	cmp	#$86	;is this a subdir?
	bne	90$	;branch if not.
	lda	#(5|64)
	jsr	GetNewKernal
	jsr	DownDirectory
	jsr	RstrKernal
	txa
 90$
	rts

CkUp2Parent:
	phy
	iny
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#'.'
	bne	90$
	iny
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#'/'
	bne	90$
	iny
	sty	pathPtr
	pla
	lda	#(5|64)
	jsr	GetNewKernal
	jsr	UpDirectory
	jsr	RstrKernal
	sec
	rts
 90$
	ply
	lda	#'.'
	clc
	rts

;the directory should already be loaded prior
;to calling this. If an index file is found,
;the carry will be set,it's name will be pointed
;at by r0, and it's dir entry will be in dirEntryBuf.
FindIndexFile:
	jsr	HTMIndexFind
	beq	80$
	jsr	HTMLIndexFind
	beq	80$
	clc
	rts
 80$
	sec
	rts

index1Str:
	.byte	"index.htm"
i1Terminator:
	.byte	"l",0

HTMIndexFind:
	lda	#0
	.byte	44
HTMLIndexFind:
	lda	#'l'
	sta	i1Terminator
	LoadW	r6,#index1Str
	LoadB	r7L,#0
	jsr	LFindLFile
	txa
	rts

JmpAncName:
	LoadW	r14,#hrefString+256
	MoveB	prg2Bank,r15L
	sta	JAN4+3
	ldy	#160
	lda	#0
;	sta	[r14],y
	.byte	$97,r14
	dec	r14H
	jsr	FindNmAnchor
	bcc	JAN8
	jsr	SvAncField
	jsr	RstrURLFields
	ldy	#0
JAN2:
;	lda	[r14],y
	.byte	$b7,r14
	beq	JAN3
	cmp	#'#'
	beq	JAN3
	iny
	bne	JAN2
	beq	JAN8
JAN3:
	ldx	#0
	lda	#'#'
;	sta	[r14],y
	.byte	$97,r14
	iny
JAN4:
;	lda	anchNmField,x
	.byte	$bf,[anchNmField,]anchNmField,3
;	sta	[r14],y
	.byte	$97,r14
	beq	JAN5
	inx
	iny
	bne	JAN4
JAN5:
	ldy	#0
;	lda	[r1],y
	.byte	$b7,r1
	and	#%11111000
	sta	curPageTop+0
	iny
;	lda	[r1],y
	.byte	$b7,r1
	sta	curPageTop+1
	iny
;	lda	[r1],y
	.byte	$b7,r1
	sta	curPageTop+2
	jsr	CalcCPBottom
	jsr	CmpCEPg
	bcc	JAN6
	jsr	MoveECPg
JAN6:
	jsr	JFetchFSegment
	jsr	CkVsblAnchors
	jsr	ReStrtSBar
JAN8:
	jsr	Href2URL
	jsr	LDoURLBar
	jmp	RstBrwsVectors



FindNmAnchor:
	lda	anchorBank
	sta	r2L
	LoadB	r1L,#0
	sta	r1H
	jsr	R5AncNmField
 50$
	ldy	#13
;	lda	[r1],y
	.byte	$b7,r1
	bmi	60$
	ldy	#3
;	lda	[r1],y
	.byte	$b7,r1
	iny
;	ora	[r1],y
	.byte	$17,r1
	iny
;	ora	[r1],y
	.byte	$17,r1
	beq	58$	;branch if empty spot.
 55$
	clc
	lda	r1L
	adc	#16
	sta	r1L
	bcc	50$
	inc	r1H
	bne	50$
 58$
	clc
	rts
 60$
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
	ldy	#0
 65$
;	lda	[r3],y
	.byte	$b7,r3
	beq	70$
;	cmp	[r5],y
	.byte	$d7,r5
	bne	55$
	iny
	bne	65$
	clc
	rts
 70$
;	cmp	[r5],y
	.byte	$d7,r5
	bne	55$
	rts		;carry is set.


R5AncNmField:
	LoadW	r5,#anchNmField
	MoveB	prg2Bank,r6L
	rts

DoHTTP:
	jsr	ClearBWindow
	LoadB	keyVector+0,#0
	sta	keyVector+1
	ldx	watchMOffset
	jsr	RemvMnRoutine
	LoadB	watchMOffset,#0
	ldx	pageBank
	jsr	FreeNClear
	ldx	htmlBank
	jsr	FreeNClear
	ldx	anchorBank
	jsr	FreeNClear
	ldx	linkBank
	jsr	FreeNClear
	MoveB	htmlBank,a1L
	LoadB	dloadFlag,#%00000000
	jsr	LStartHTTP
	bcc	50$
	and	#%01000000
	beq	50$
	clc
	rts
 50$
	LoadB	pageLoaded,#%11000000
	jsr	OpenPrgDir
	jsr	ClrMsgBox
	MoveB	htmlBank,a1L
	jsr	LParseHTML
	LoadB	curPageTop+0,#0
	sta	curPageTop+1
	sta	curPageTop+2
	jsr	CalcCPBottom
	sec
	rts

FullURLBar:
	bit	pageLoaded
	bvs	FUB6
	jsr	ClrURLString
	MoveB	prg2Bank,URL2+3
	sta	URL3+3
	ldx	#0
FUB2:
	lda	dirEntryBuf+3,x
	beq	FUB3
	cmp	#$a0
	beq	FUB3
URL2:
;	sta	urlString,x
	.byte	$9f,[urlString,]urlString,3 ;this can change.
	inx
	cpx	#16
	bcc	FUB2
FUB3:
	lda	#0
URL3:
;	sta	urlString,x
	.byte	$9f,[urlString,]urlString,3 ;this can change.
	lda	curType
	and	#%00001111
	cmp	#DRV_NATIVE
	bne	FUB6
	lda	curDirHead+34
	beq	FUB6
	jsr	InstDirName
	lda	#(5|64)
	jsr	GetNewKernal
FUB4:
	jsr	InsrtParent
	bcs	FUB4
	jsr	RstrKernal
FUB6:
	jsr	InstDrvPart
	LoadB	urlBufPtr,#0
	jmp	LDoURLBar


InsrtParent:
	lda	curDirHead+34
	beq	40$
	jsr	UpDirectory
	txa
	beq	50$
 40$
	clc
	rts
 50$
	lda	curDirHead+34
	beq	40$
InstDirName:
	ldy	#0
 60$
	lda	curDirHead+144,y
	beq	70$
	cmp	#$a0
	beq	70$
	iny
	cpy	#16
	bcc	60$
 70$
	sty	r5L
	lda	#253
	sec
	sbc	r5L
	tax
	LoadW	r0,#urlString
	MoveB	prg2Bank,r1L
	sta	IDN3+3
	sta	IDN6+3
	sta	IDN7+3
	ldy	#255
	lda	#0
;	sta	[r0],y
	.byte	$97,r0
	dey
IDN3:
;	lda	urlString,x
	.byte	$bf,[urlString,]urlString,3 ;this can change.
;	sta	[r0],y
	.byte	$97,r0
	dey
	dex
	cpx	#255
	bne	IDN3
	inx
IDN5:
	lda	curDirHead+144,x
IDN6:
;	sta	urlString,x
	.byte	$9f,[urlString,]urlString,3 ;this can change.
	inx
	cpx	r5L
	bcc	IDN5
	lda	#'/'
IDN7:
;	sta	urlString,x
	.byte	$9f,[urlString,]urlString,3 ;this can change.
	rts

InstDrvPart:
	jsr	BldDrvURLString
	stx	r5L
	lda	#254
	sec
	sbc	r5L
	tax
	LoadW	r0,#urlString
	MoveB	prg2Bank,r1L
	sta	IDP3+3
	sta	IDP6+3
	ldy	#255
	lda	#0
;	sta	[r0],y
	.byte	$97,r0
	dey
IDP3:
;	lda	urlString,x
	.byte	$bf,[urlString,]urlString,3 ;this can change.
;	sta	[r0],y
	.byte	$97,r0
	dey
	dex
	cpx	#255
	bne	IDP3
	inx
IDP5:
	lda	fileTxt,x
IDP6:
;	sta	urlString,x
	.byte	$9f,[urlString,]urlString,3 ;this can change.
	inx
	cpx	r5L
	bcc	IDP5
	rts



BldDrvURLString:
	lda	urlDrive
	clc
	adc	#'A'-8
	sta	fileTxt+0
	lda	urlPart
	jsr	LByte2Ascii
	ldy	#0
	ldx	#1
 20$
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#'0'
	bne	25$
	iny
	cpy	#2
	bcc	20$
 25$
;	lda	[r0],y
	.byte	$b7,r0
	sta	fileTxt,x
	inx
	iny
	cpy	#3
	bcc	25$
	lda	#':'
	sta	fileTxt,x
	inx
	lda	#'/'
	sta	fileTxt,x
	inx
	lda	#0
	sta	fileTxt,x
	rts

fileTxt:
	.byte	"A255:/",0	;this changes.

endBrowser:
