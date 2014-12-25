;*****************************************
;
;
;	ParseHTML2
;
;	routines for parsing an HTML document
;
;
;*****************************************


	.psect


;here's a list of the tags that get a stack page along with the
;number of the stack each one uses.

;<B> = 0
;<I>,<CITE> = 1
;<U> = 2
;<UL>,<OL>,<DL> = 3
;<CENTER> = 4
;<BLOCKQUOTE>,<BQ> = 5
;<TABLE> = 6
;<H1> - <H6> = 8 - 13
;<FONT> = 14
;<TT>,<CODE>,<KBD>,<SAMP> = 15
;<PRE> = 16
;<TD>,<TH> = 17


PushStack:
	pha
	jsr	PointStack
	pla
;	sta	(a6)
	.byte	$92,a6
	dec	stackPointer,x
	rts

PullStack:
	jsr	PointStack
	inc	a6L
	inc	stackPointer,x
;	lda	(a6)
	.byte	$b2,a6
	rts

PointStack:
	lda	stackPointer,x
	sta	a6L
	txa
	clc
	adc	#]tagStack
	sta	a6H
	rts


JSLSmallPutChar:
	phb
	pha
	lda	#0
	pha
	plb
	pla
	jsl	FSmallPutChar,0
	plb
	rts

ShowFrmProgress:
	ldx	#5
 5$
	lda	nhtmlSize,x
	sta	r3,x
	dex
	bpl	5$
	bmi	15$
 10$
	lsr	r5H
	ror	r5L
	ror	r4H
	lsr	r4L
	ror	r3H
	ror	r3L
 15$
	lda	r5H
	bne	10$
 20$
	lda	r4H
	ora	r5L
	beq	40$
	CmpW	r3,r4H
	bcc	30$
	bne	40$
 30$
	jsr	JCurFrHeight
	dea
	sta	r2L
	ldx	#r3
	ldy	#r2L
	jsl	SBMult,0
	ldy	#r4H
	jsl	SD32div,0
 40$
	jsr	JCurFrHeight
	dea
	cmp	r6L
	bcs	45$
	sta	r6L
 45$
	jsr	LdFrScrRegs
	jsr	JCurFrBottom
	sta	r2H
	sec
	sbc	r6L
	sta	r2L
	lda	#1
	jsl	SSetPattern,0
;fall through...
ForeRectangle:
	PushB	dispBufferOn
	LoadB	dispBufferOn,#ST_WR_FORE
	jsl	SRectangle,0
	PopB	dispBufferOn
	rts

;these two must remain together.
nhtmlSize:
	.block	3
ohtmlSize:
	.block	3

DrPrgrssBar:
	lda	#0
	jsl	SSetPattern,0
	jsr	LdFrScrRegs
	jsr	ForeRectangle
	jsr	ForeFrRectangle
	jsl	SConvToCards,0
;	lda	menuColor
	.byte	$af,[menuColor,]menuColor,0
	sta	r4H
	jsl	SColorRectangle,0
	rts

LdFrScrRegs:
	jsr	JCurFrRegs
	sec
	lda	r4L
.if	C64
	sbc	#7
.else
	sbc	#15
.endif
	sta	r3L
	lda	r4H
	sbc	#0
	sta	r3H
	rts

ForeFrRectangle:
	PushB	dispBufferOn
	LoadB	dispBufferOn,#ST_WR_FORE
	lda	#%11111111
	jsl	SFrameRectangle,0
	PopB	dispBufferOn
	rts

DoNxtTag:
	LoadB	curAttrNum,#0
	jsr	A0ToTagPtr
	jsr	CkIfTag
	stx	curTagNum
	sta	tagMode
	bcs	40$
	jsr	TagPtrToA0
	jsr	PntPastParam
	bcs	50$
	rts
 40$
	jsr	A0ToTagPtr
	jsr	OffListMode
	lda	curTagNum
	asl	a
	tax
;	jsr	(tagRoutines,x)
	.byte	$fc,[tagRoutines,]tagRoutines
	bit	htmlMode
	bvc	90$
 50$
	jsl	SCkAbortKey,0
	bcc	90$
	jsr	FlushTag
	jmp	LdaNxtChar
 90$
	clc
	rts

FlushTag:
 10$
	jsr	GetNxtAttr
	bcs	10$
	rts

tagPtr:
	.block	3

A0ToTagPtr:
	MoveB	a0L,tagPtr+0
	MoveB	a0H,tagPtr+1
	MoveB	a1L,tagPtr+2
	rts

TagPtrToA0:
	MoveB	tagPtr+0,a0L
	MoveB	tagPtr+1,a0H
	MoveB	tagPtr+2,a1L
	rts

FindNxtTag:
	LoadB	curAttrNum,#0
 10$
	jsr	FindLTChar
	bcc	90$
	jsr	CkIfTag
	stx	curTagNum
	sta	tagMode
	bcc	20$
	rts
 20$
	jsr	TagPtrToA0
	bcc	10$	;branch always.
 90$
	rts


;if this is a recognized tag, the carry will
;be set, x will hold the tag number and bit 7
;of the acc will be clear for an opening tag
;or set for a closing tag.
CkIfTag:
	jsr	LdaNxtChar
	bcc	90$
	cmp	#'/'
	bne	10$
	jsr	PntNxtChar
	bcc	90$
	lda	#%10000000
	.byte	44
 10$
	lda	#0
	pha
	jsr	A0ToTagPtr
	ldx	#0
 20$
	jsr	TagPtrToA0
	jsr	CkXTag
	bcc	30$
	jsr	A0ToTagPtr
	pla
	rts
 30$
	inx
	cpx	#[(cmd2Table-cmd1Table)
	bcc	20$
	pla
 90$
	lda	#0
	ldx	#255
	clc
	rts


CkXTag:
;	lda	[a0]
	.byte	$a7,a0
	jsr	CapCharacter
 10$
	cmp	cmd1Table,x
	beq	20$
	inx
	cpx	#[(cmd2Table-cmd1Table)
	bcc	10$
	clc
	rts
 20$
	lda	cmd2Table,x
	beq	27$
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	cmd2Table,x
	bne	25$
	lda	cmd3Table,x
	beq	27$
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	cmd3Table,x
	bne	25$
	lda	cmd4Table,x
	beq	27$
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	cmd4Table,x
	beq	30$
 25$
	clc
	rts
 27$
	beq	CC2
 30$
	lda	cmd5Table,x
	beq	CC2
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	cmd5Table,x
	bne	25$
	lda	cmd6Table,x
	beq	CC2
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	cmd6Table,x
	bne	25$
	lda	cmd7Table,x
	beq	CC2
	jsr	LdaNxtChar
	bcc	CC4
	jsr	CapCharacter
	cmp	cmd7Table,x
	bne	CC4
	lda	cmd8Table,x
	beq	CC2
	jsr	LdaNxtChar
	bcc	CC4
	jsr	CapCharacter
	cmp	cmd8Table,x
	bne	CC4
	lda	cmd9Table,x
	beq	CC2
	jsr	LdaNxtChar
	bcc	CC4
	jsr	CapCharacter
	cmp	cmd9Table,x
	bne	CC4
	lda	cmd10Table,x
	beq	CC2
	jsr	LdaNxtChar
	bcc	CC4
	jsr	CapCharacter
	cmp	cmd10Table,x
	bne	CC4
CC2:
	jsr	LdaNxtChar
	bcc	CC4
	cmp	#' '
	beq	CC3
	cmp	#'>'
	beq	CC3
	cmp	#LF
	beq	CC3
	cmp	#CR
	beq	CC3
	cpx	#40
	bne	CC4
CC3:
	sec
	rts
CC4:
	clc
	rts


cmd1Table:
	.byte	"HHTBBPHH"
	.byte	"HHHHBIUE"
	.byte	"SFCDKCBB"
	.byte	"HCLUOATT"
	.byte	"TVTSCPCT"
	.byte	"!ADDDIFS"
cmd2Table:
	.byte	"TEIOR",0,"12"
	.byte	"3456",0,0,0,"M"
	.byte	"TOOFBOLQ"
	.byte	"REILL",0,"AR"
	.byte	"DATAIRAH"
	.byte	"-DLTDMOC"
cmd3Table:
	.byte	"MATD",0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	"RNDNDMO",0
	.byte	0,"N",0,0,0,0,"B",0
	.byte	0,"R",0,"MTEP",0
	.byte	"-D",0,0,0,"GRR"
cmd4Table:
	.byte	"LDLY",0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	"OTE",0,0,"MC",0
	.byte	0,"T",0,0,0,0,"L",0
	.byte	0,0,0,"PE",0,"T",0
	.byte	0,"R",0,0,0,0,"MI"
cmd5Table:
	.byte	0,0,"E",0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	"N",0,0,0,0,"EK",0
	.byte	0,"E",0,0,0,0,"E",0
	.byte	0,0,0,0,0,0,"I",0
	.byte	0,"E",0,0,0,0,0,"P"
cmd6Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	"G",0,0,0,0,"NQ",0
	.byte	0,"R",0,0,0,0,0,0
	.byte	0,0,0,0,0,0,"O",0
	.byte	0,"S",0,0,0,0,0,"T"
cmd7Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,"TU",0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,"N",0
	.byte	0,"S",0,0,0,0,0,0

cmd8Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,"O",0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
cmd9Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,"T",0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
cmd10Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,"E",0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0

tagRoutines:
	.word	THtml,THead,TTitle,TBody
	.word	TLineBreak,TParagraph,TH1,TH2
	.word	TH3,TH4,TH5,TH6
	.word	TBold,TItalic,TUnderline,TItalic
	.word	TBold,TFont,TTeletype,TDefine
	.word	TKeyboard,TComment,TBlockQuote,TBlockQuote
	.word	THRule,TCenter,TList,TUList
	.word	TOList,TAnchor,TTable,TTRow
	.word	TTData,TItalic,TTeletype,TTeletype
	.word	TItalic,TPre,TCaption,TTHeader
	.word	TSkip,TAddress,TDList,TDTerm
	.word	TDDefinition,TImg,TForm,TScript

Get1stAttr:
	LoadB	curAttrNum,#0
GetNxtAttr:
	lda	curAttrNum
	bne	10$
	jsr	TagPtrToA0
 10$
	inc	curAttrNum
;	lda	[a0]
	.byte	$a7,a0
	cmp	#'>'
	beq	90$
	cmp	#' '
	beq	20$
	cmp	#LF
	beq	20$
	cmp	#CR
	beq	20$
	jsr	PntPastParam
	bcc	90$
	cmp	#'>'
	beq	90$
 20$
	jsr	PntNonSpace
	bcc	90$
	cmp	#'>'
	beq	90$
	jsr	CkIfAttr
	bcc	10$
	rts
 90$
	LoadB	curAttrNum,#0
	clc
	rts

CkIfAttr:
	MoveB	a0L,atagPtr+0
	MoveB	a0H,atagPtr+1
	MoveB	a1L,atagPtr+2
	ldx	#1
 10$
	MoveB	atagPtr+0,a0L
	MoveB	atagPtr+1,a0H
	MoveB	atagPtr+2,a1L
	jsr	CkXAttr
	bcs	20$
	inx
	cpx	#[(attr2Table-attr1Table+1)
	bcc	10$
	clc
	rts
 20$
	bne	30$
	LoadB	attrString+0,#0
	LoadW	r0,#attrString
	sec
	rts
 30$
	lda	parTypeTable-1,x
	bne	40$
	jsr	PntPastParam
	clc
	rts
 40$
	phx
	asl	a
	tax
;	jsr	(GetParRoutines-2,x)
	.byte	$fc,[(GetParRoutines-2),](GetParRoutines-2)
	plx
	rts

GetParRoutines:
	.word	GetParValue,GetParString,GetParTerm

atagPtr:
	.block	3

PntPastParam:
 10$
	jsr	LdaNxtChar
	bcc	90$
	cmp	#' '
	beq	80$
	cmp	#'>'
	beq	80$
	cmp	#LF
	beq	80$
	cmp	#CR
	bne	10$
 80$
	sec
 90$
	rts

PntNonSpace:
 10$
	jsr	LdaNxtChar
	bcc	90$
	cmp	#' '
	beq	10$
	cmp	#LF
	beq	10$
	cmp	#CR
	beq	10$
	sec
 90$
	rts


GetParValue:
	jsr	GetParString
	bcc	90$
	jsr	Str2Value
	bcc	90$
	MoveW	r7,r0
	lda	signByte
	sec
 90$
	rts


;point r0 to a string containing a decimal number and this
;will return its value in r7.
;destroys a,x,y,r6,r9
Str2Value:
	LoadB	signByte,#0
	ldy	#0
	lda	(r0),y
	cmp	#'0'
	bcs	16$
	cmp	#'+'
	beq	15$
	cmp	#'-'
	bne	90$
	dec	signByte
	dec	signByte
 15$
	inc	signByte
	iny
 16$
	tya
	ldy	#0
	clc
	adc	r0L
	sta	r0L
	bcc	20$
	inc	r0H
 20$
	LoadB	r7L,#0
	sta	r7H
 30$
	lda	(r0),y
	beq	50$
	cmp	#'%'
	bne	40$
	LoadB	signByte,#2	;indicate percent.
	iny
	lda	(r0),y
	bne	90$
	sec
	rts
 40$
	jsr	DecToBin
	bcc	90$
	jsr	PutDecDigit
	bcs	90$
	iny
	bne	30$	;branch always?
 50$
	bit	signByte
	bpl	80$
	ldx	#r7
	jsl	SDnegate,0
 80$
	sec
	rts
 90$
	clc
	rts


;this converts an ascii decimal digit to binary if
;the accumulator holds a valid character. Carry is
;set if successful.
DecToBin:
	cmp	#'9'+1
	bcs	90$
	sec
	sbc	#'0'
	rts
 90$
	clc
	rts

PutDecDigit:
	pha
	phy
	MoveW	r7,r5
	LoadB	r9L,#10
	ldx	#r5
	ldy	#r9L
	jsl	SBMult,0
	ply
	pla
	clc
	adc	r5L
	sta	r7L
	lda	r5H
	adc	#0
	sta	r7H
	rts


GetParString:
	ldy	#0
;	lda	[a0]
	.byte	$a7,a0
 5$
	cmp	#34
	beq	50$
	cmp	#39
	beq	50$
	cmp	#CR
	beq	10$
	cmp	#LF
	bne	15$
 10$
	jsr	LdaNxtChar
	bcs	5$
	rts
 15$
	sta	attrString,y
	iny
 20$
	jsr	LdaNxtChar
	bcc	90$
	cmp	#' '
	beq	70$
	cmp	#CR
	beq	70$
	cmp	#LF
	beq	70$
	cmp	#'>'
	beq	70$
	sta	attrString,y
	iny
	cpy	#255
	bcc	20$
	bcs	70$
 50$
	sta	delimiter
 60$
	jsr	LdaNxtChar
	bcc	90$
	cmp	delimiter
	beq	65$
	cmp	#CR
	beq	60$
	cmp	#LF
	beq	60$
	sta	attrString,y
	iny
	cpy	#255
	bcc	60$
 65$
	jsr	PntPastParam
 70$
	lda	#0
	sta	attrString,y
	LoadW	r0,#attrString
	sec
 90$
	rts


GetParTerm:
	jsr	GetParString
	bcc	20$
	ldx	#0
 10$
	jsr	CkXParTerm
	bcs	20$
	inx
	cpx	#[(parm2Table-parm1Table)
	bcc	10$
	clc
	ldx	#0
 20$
	stx	r0L
	rts


CkXAttr:
;	lda	[a0]
	.byte	$a7,a0
	jsr	CapCharacter
 10$
	cmp	attr1Table-1,x
	beq	20$
	inx
	cpx	#[(attr2Table-attr1Table+1)
	bcc	10$
	clc
	rts
 20$
	lda	attr2Table-1,x
	beq	27$
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	attr2Table-1,x
	bne	25$
	lda	attr3Table-1,x
	beq	27$
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	attr3Table-1,x
	bne	25$
	lda	attr4Table-1,x
	beq	27$
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	attr4Table-1,x
	beq	30$
 25$
	clc
	rts
 27$
	beq	CA2
 30$
	lda	attr5Table-1,x
	beq	CA2
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	attr5Table-1,x
	bne	25$
	lda	attr6Table-1,x
	beq	CA2
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	attr6Table-1,x
	bne	25$
	lda	attr7Table-1,x
	beq	CA2
	jsr	LdaNxtChar
	bcc	25$
	jsr	CapCharacter
	cmp	attr7Table-1,x
	bne	CA8
	lda	attr8Table-1,x
	beq	CA2
	jsr	LdaNxtChar
	bcc	CA8
	jsr	CapCharacter
	cmp	attr8Table-1,x
	bne	CA8
	lda	attr9Table-1,x
	beq	CA2
	jsr	LdaNxtChar
	bcc	CA8
	jsr	CapCharacter
	cmp	attr9Table-1,x
	bne	CA8
CA2:
	jsr	LdaNxtChar
	bcc	CA8
	cmp	#'='
	bne	CA5
CA4:
	jsr	PntNonSpace
	bcc	CA8
	lda	#1
	sec
	rts
CA5:
	cmp	#'>'
	beq	CA7
	cmp	#' '
	beq	CA6
	cmp	#LF
	beq	CA6
	cmp	#CR
	bne	CA8
CA6:
	jsr	PntNonSpace
	bcc	CA8
	cmp	#'='
	beq	CA4
CA7:
	lda	#0
	sec
	rts
CA8:
	clc
	rts


attr1Table:
	.byte	"AAABBCCC"
	.byte	"CCCCEFHH"
	.byte	"ILMMMNNN"
	.byte	"RRSSSSSS"
	.byte	"TTUVVWWC"
attr2Table:
	.byte	"CLLGOHLO"
	.byte	"OOOONAER"
	.byte	"DOAEUAOO"
	.byte	"OOCEHIIR"
	.byte	"EOSAAIRO"
attr3Table:
	.byte	"TITCREEL"
	.byte	"LLMOCCIE"
	.byte	0,"WXTLMRW"
	.byte	"WWRLANZC"
	.byte	"XPELLDAN"
attr4Table:
	.byte	"IG",0,"ODCAO"
	.byte	"SSPRTEGF"
	.byte	0,"SLHTEER"
	.byte	"SSOEPGE",0
	.byte	"TMMIUTPT"
attr5Table:
	.byte	"ON",0,"LEKRR"
	.byte	0,"PADY",0,"H",0
	.byte	0,"REOI",0,"SA"
	.byte	0,"PLCEL",0,0
	.byte	0,"AAGEH",0,"I"
attr6Table:
	.byte	"N",0,0,"ORE",0,0
	.byte	0,"ACSP",0,"T",0
	.byte	0,"CNDP",0,"IP"
	.byte	0,"ALT",0,"E",0,0
	.byte	0,"RPN",0,0,0,"N"
attr7Table:
	.byte	0,0,0,"R",0,"D",0,0
	.byte	0,"NT",0,"E",0,0,0
	.byte	0,0,"G",0,"L",0,"Z",0
	.byte	0,"NIE",0,0,0,0
	.byte	0,"G",0,0,0,0,0,"U"

attr8Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,"T",0,"E",0,"E",0
	.byte	0,0,"ND",0,0,0,0
	.byte	0,"I",0,0,0,0,0,"E"
attr9Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,"H",0,0,0,0,0
	.byte	0,0,"G",0,0,0,0,0
	.byte	0,"N",0,0,0,0,0,0
attr10Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0

parTypeTable:
	.byte	2,3,2,2,2,0,3,2
	.byte	1,1,0,2,2,2,1,2
	.byte	2,2,1,3,0,2,0,0
	.byte	1,1,3,0,3,0,1,2
	.byte	2,1,2,3,2,1,3,0

CkXParTerm:
	ldy	#0
	lda	attrString,y
	jsr	CapCharacter
 10$
	cmp	parm1Table,x
	beq	20$
	inx
	cpx	#[(parm2Table-parm1Table)
	bcc	10$
	clc
	rts
 20$
	iny
	lda	parm2Table,x
	beq	27$
	lda	attrString,y
	jsr	CapCharacter
	cmp	parm2Table,x
	bne	25$
	iny
	lda	parm3Table,x
	beq	27$
	lda	attrString,y
	jsr	CapCharacter
	cmp	parm3Table,x
	bne	25$
	iny
	lda	parm4Table,x
	beq	27$
	lda	attrString,y
	jsr	CapCharacter
	cmp	parm4Table,x
	beq	30$
 25$
	clc
	rts
 27$
	beq	CP2
 30$
	iny
	lda	parm5Table,x
	beq	CP2
	lda	attrString,y
	jsr	CapCharacter
	cmp	parm5Table,x
	bne	25$
	iny
	lda	parm6Table,x
	beq	CP2
	lda	attrString,y
	jsr	CapCharacter
	cmp	parm6Table,x
	bne	25$
	iny
	lda	parm7Table,x
	beq	CP2
	lda	attrString,y
	jsr	CapCharacter
	cmp	parm7Table,x
	bne	CP5
	iny
CP2:
	lda	attrString,y
	bne	CP5
	sec
	rts
CP5:
	clc
	rts


;these tables contain some of the values that an attribute can equal.
;these tables include the following parameters:
;LEFT,RIGHT,CENTER,JUSTIFY,TEXTTOP,TOP,MIDDLE,BOTTOM

parm1Table:
	.byte	"LCRJTTMB"
	.byte	"A"
parm2Table:
	.byte	"EEIUEOIO"
	.byte	"L"
parm3Table:
	.byte	"FNGSXPDT"
	.byte	"L"
parm4Table:
	.byte	"TTHTT",0,"DT"
	.byte	0
parm5Table:
	.byte	0,"ETIT",0,"LO"
	.byte	0
parm6Table:
	.byte	0,"R",0,"FO",0,"EM"
	.byte	0
parm7Table:
	.byte	0,0,0,"YP",0,0,0
	.byte	0
parm8Table:
	.byte	0,0,0,0,0,0,0,0
	.byte	0


ShowAnyway:
	jsr	FlushText
;	lda	pageBank
	.byte	$af,[pageBank,]pageBank,0
	tax
	phx
	jsl	SFreeBnkChain,0
	plx
	jsl	SClearBank,0
;	PushB	dispBufferOn
;	LoadB	dispBufferOn,#(ST_WR_FORE|ST_WR_BACK)
;	jsl	SClearBWindow,0
;	ldx	#2
;	jsl	SDoMsgDB,0
;	plx
;	stx	dispBufferOn
;	cmp	#YES
;	beq	20$
;	rts
; 20$
	jsr	AnalyzeText
	jsr	DrPrgrssBar
	jsr	InitBrsVariables
	LoadB	lastAscRead,#0
	LoadB	curTagNum,#37
	jsr	TPre
;	lda	[a0]
	.byte	$a7,a0
 30$
	jsr	Conv2Ascii
	cmp	#0
	beq	70$
	cmp	#CR
	bne	50$
	jsr	TLB2
	bra	70$
 50$
	jsr	PutOurChar
 70$
	jsr	LdaNShow
	bcs	30$
 90$
	jmp	DumpText

prgrssCounter:
	.block	1
textType:
	.block	1

AnalyzeText:
	LoadB	textType,#0	;default to ascii text.
;	lda	gwFileFlag	;did we load a geoWrite file?
	.byte	$af,[gwFileFlag,]gwFileFlag,0
	bmi	80$	;branch if so.
	ldx	#11
	lda	#0
 10$
	sta	asciiVote,x
	dex
	bpl	10$
	jsr	InitBrsVariables
	jsr	CkAllWords
	jsr	TallyVotes
 80$
	rts


CkAllWords:
	jsr	ClrVotes
	jsr	PntNxtWord
 5$
	jsr	Vote1stCharacter
 10$
	jsr	LdaNxtChar
	bcc	90$
	cmp	#' '
	beq	40$
	cmp	#CR
	beq	40$
	cmp	#'.'
	beq	50$
 20$
	jsr	VoteCharacter
	bcs	10$
 30$
	jsr	LdaNxtChar
	bcc	90$
	cmp	#' '
	beq	45$
	cmp	#CR
	beq	45$
	cmp	#'.'
	beq	CkAllWords
	bne	30$
 40$
	jsr	AddToVotes
 45$
	jsr	PntNxtWord
	bcs	20$
	rts
 50$
	jsr	AddToVotes
 55$
	jsr	PntNxtWord
	bcs	5$
 90$
	rts


PntNxtWord:
 10$
	jsr	LdaNxtChar
	bcc	90$
	cmp	#' '
	beq	10$
	cmp	#CR
	beq	10$
	cmp	#'.'
	beq	10$
	cmp	#'A'
	bcc	10$
	cmp	#'Z'+1
	bcc	80$
	cmp	#'a'
	bcc	10$
	cmp	#'z'+1
	bcc	80$
	cmp	#('A'|$80)
	bcc	10$
	cmp	#('Z'|$80)+1
	bcs	10$
 80$
	sec
 90$
	rts

Vote1stCharacter:
	cmp	#91
	bcc	60$	;vote for screencode and ascii.
	cmp	#123
	bcc	70$	;vote for reverse ascii.
	inc	petsciWord
	inc	wordSize
	rts
 60$
	inc	screenWord
	inc	asciiWord
	inc	wordSize
	rts
 70$
	inc	revAscWord
	inc	wordSize
	rts

VoteCharacter:
	cmp	#27
	bcc	60$	;vote for screencode.
	cmp	#65
	bcc	90$	;branch for no vote.
	cmp	#91
	bcc	70$	;vote for reverse ascii
			;and petascii.
	cmp	#97
	bcc	90$
	cmp	#123
	bcs	90$	;branch for no vote.
	inc	asciiWord
	inc	wordSize
	sec
	rts
 60$
	inc	screenWord
	inc	wordSize
	sec
	rts
 70$
	inc	revAscWord
	inc	petsciWord
	inc	wordSize
	sec
	rts
 90$
	clc
	rts

TallyVotes:
	ldx	#0
	MoveW	asciiVote,r0
	MoveB	asciiVote+2,r1L
	lda	petsciVote+2
	cmp	r1L
	bne	10$
	lda	petsciVote+1
	cmp	r0H
	bne	10$
	lda	petsciVote+0
	cmp	r0L
 10$
	bcc	20$
	ldx	#1
	MoveW	petsciVote,r0
	MoveB	petsciVote+2,r1L
 20$
	lda	screenVote+2
	cmp	r1L
	bne	30$
	lda	screenVote+1
	cmp	r0H
	bne	30$
	lda	screenVote+0
	cmp	r0L
 30$
	bcc	40$
	ldx	#2
	MoveW	screenVote,r0
	MoveB	screenVote+2,r1L
 40$
	lda	revAscVote+2
	cmp	r1L
	bne	50$
	lda	revAscVote+1
	cmp	r0H
	bne	50$
	lda	revAscVote+0
	cmp	r0L
 50$
	bcc	80$
	ldx	#3
 80$
	txa
	asl	a
	sta	textType
	rts


AddToVotes:
	lda	wordSize
	cmp	#14
	bcs	40$
	clc
	lda	asciiVote+0
	adc	asciiWord
	sta	asciiVote+0
	bcc	10$
	inc	asciiVote+1
	bne	10$
	inc	asciiVote+2
 10$
	clc
	lda	petsciVote+0
	adc	petsciWord
	sta	petsciVote+0
	bcc	20$
	inc	petsciVote+1
	bne	20$
	inc	petsciVote+2
 20$
	clc
	lda	screenVote+0
	adc	screenWord
	sta	screenVote+0
	bcc	30$
	inc	screenVote+1
	bne	30$
	inc	screenVote+2
 30$
	clc
	lda	revAscVote+0
	adc	revAscWord
	sta	revAscVote+0
	bcc	40$
	inc	revAscVote+1
	bne	40$
	inc	revAscVote+2
 40$
ClrVotes:
	lda	#0
	sta	asciiWord
	sta	petsciWord
	sta	screenWord
	sta	revAscWord
	sta	wordSize
	rts


;these 4 must stay together.
asciiVote:
	.block	3
petsciVote:
	.block	3
screenVote:
	.block	3
revAscVote:
	.block	3

asciiWord:
	.block	1
petsciWord:
	.block	1
screenWord:
	.block	1
revAscWord:
	.block	1

wordSize:
	.block	1

Conv2Ascii:
	ldx	textType
;	jmp	(convJmpTable,x)
	.byte	$7c,[convJmpTable,]convJmpTable

convJmpTable:
	.word	DoTrueAscii,DoPetascii
	.word	DoScreencode,DoRevAscii

DoRevAscii:
	and	#%01111111
	tax
	lda	revConvTable,x
	rts

DoPetascii:
	tax
	lda	petConvTable,x
	rts

DoScreencode:
	tax
	lda	scrConvTable,x
	rts


DoTrueAscii:
	and	#%01111111
	cmp	#127
	beq	70$
	cmp	#32
	bcs	75$
	cmp	#TAB
	beq	60$
	cmp	#LF
	bne	30$
	lda	lastAscRead
	cmp	#CR
	beq	70$
	lda	#CR
	bne	80$
 30$
	cmp	#CR
	beq	75$
	bne	70$
 60$
	lda	#' '
	.byte	44
 70$
	lda	#0
 75$
	sta	lastAscRead
 80$
	rts

lastAscRead:
	.block	1

petConvTable:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,32,0,0,0,CR,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	32,33,34,35,36,37,38,39
	.byte	40,41,42,43,44,45,46,47
	.byte	48,49,50,51,52,53,54,55
	.byte	56,57,58,59,60,61,62,63
	.byte	"@abcdefg"
	.byte	"hijklmno"
	.byte	"pqrstuvw"
	.byte	"xyz[|]^_"
	.byte	"-ABCDEFG"
	.byte	"HIJKLMNO"
	.byte	"PQRSTUVW"
	.byte	"XYZ{|}~ "
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,13,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	32,33,34,35,36,37,38,39
	.byte	40,41,42,43,44,45,46,47
	.byte	48,49,50,51,52,53,54,55
	.byte	56,57,58,59,60,61,62,63
	.byte	"-ABCDEFG"
	.byte	"HIJKLMNO"
	.byte	"PQRSTUVW"
	.byte	"XYZ{|}~ "
	.byte	"-ABCDEFG"
	.byte	"HIJKLMNO"
	.byte	"PQRSTUVW"
	.byte	"XYZ{|}~ "


scrConvTable:
	.byte	"@abcdefg"
	.byte	"hijklmno"
	.byte	"pqrstuvw"
	.byte	"xyz[\]^",13
	.byte	32,33,34,35,36,37,38,39
	.byte	40,41,42,43,44,45,46,47
	.byte	48,49,50,51,52,53,54,55
	.byte	56,57,58,59,60,61,62,63
	.byte	"-ABCDEFG"
	.byte	"HIJKLMNO"
	.byte	"PQRSTUVW"
	.byte	"XYZ[\]^_"
	.byte	" ABCDEFG"
	.byte	"HIJKLMNO"
	.byte	"PQRSTUVW"
	.byte	"XYZ{|}~ "
	.byte	"@abcdefg"
	.byte	"hijklmno"
	.byte	"pqrstuvw"
	.byte	"xyz[\]^",13
	.byte	32,33,34,35,36,37,38,39
	.byte	40,41,42,43,44,45,46,47
	.byte	48,49,50,51,52,53,54,55
	.byte	56,57,58,59,60,61,62,63
	.byte	"-ABCDEFG"
	.byte	"HIJKLMNO"
	.byte	"PQRSTUVW"
	.byte	"XYZ[\]^_"
	.byte	" ABCDEFG"
	.byte	"HIJKLMNO"
	.byte	"PQRSTUVW"
	.byte	"XYZ{|}~ "

revConvTable:
	.byte	0,0,0,0,0,0,0,0
	.byte	0,32,0,0,0,13,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	0,0,0,0,0,0,0,0
	.byte	32,33,34,35,36,37,38,39
	.byte	40,41,42,43,44,45,46,47
	.byte	48,49,50,51,52,53,54,55
	.byte	56,57,58,59,60,61,62,63
	.byte	"@abcdefg"
	.byte	"hijklmno"
	.byte	"pqrstuvw"
	.byte	"xyz[|]^_"
	.byte	"`ABCDEFG"
	.byte	"HIJKLMNO"
	.byte	"PQRSTUVW"
	.byte	"XYZ{|}~ "



InitFrames:
	ldx	#97
	lda	#0
 10$
;	sta	numFrames,x
	.byte	$9f,[numFrames,]numFrames,0
	dex
	bpl	10$
;	lda	bWinTop
	.byte	$af,[bWinTop,]bWinTop,0
	sta	r2L
	LoadB	r2H,#199
	LoadB	r3L,#0
	sta	r3H
.if	C64
	LoadW	r4,#319
.else
	LoadW	r4,#639
.endif
	jsr	InitNxtFrame
	jmp	JGetCurFrame

InitNxtFrame:
;	lda	numFrames
	.byte	$af,[numFrames,]numFrames,0
	cmp	#16
	bcc	10$
	clc
	rts
 10$
	tax
	lda	r2L
;	sta	frTopTable,x
	.byte	$9f,[frTopTable,]frTopTable,0
	lda	r2H
;	sta	frBotTable,x
	.byte	$9f,[frBotTable,]frBotTable,0
	lda	r3L
;	sta	frLLeftTable,x
	.byte	$9f,[frLLeftTable,]frLLeftTable,0
	lda	r3H
;	sta	frHLeftTable,x
	.byte	$9f,[frHLeftTable,]frHLeftTable,0
	lda	r4L
;	sta	frLRightTable,x
	.byte	$9f,[frLRightTable,]frLRightTable,0
	lda	r4H
;	sta	frHRightTable,x
	.byte	$9f,[frHRightTable,]frHRightTable,0
	txa
;	sta	curFrame
	.byte	$8f,[curFrame,]curFrame,0
	ina
;	sta	numFrames
	.byte	$8f,[numFrames,]numFrames,0
	dea
	sec
	rts


JCurFrRegs:
;	lda	curFrame
	.byte	$af,[curFrame,]curFrame,0
JFrRegs:
;	cmp	numFrames
	.byte	$cf,[numFrames,]numFrames,0
	bcc	10$
	clc
	rts
 10$
	tax
;	lda	frTopTable,x
	.byte	$bf,[frTopTable,]frTopTable,0
	sta	r2L
;	lda	frBotTable,x
	.byte	$bf,[frBotTable,]frBotTable,0
	sta	r2H
;	lda	frLLeftTable,x
	.byte	$bf,[frLLeftTable,]frLLeftTable,0
	sta	r3L
;	lda	frHLeftTable,x
	.byte	$bf,[frHLeftTable,]frHLeftTable,0
	sta	r3H
;	lda	frLRightTable,x
	.byte	$bf,[frLRightTable,]frLRightTable,0
	sta	r4L
;	lda	frHRightTable,x
	.byte	$bf,[frHRightTable,]frHRightTable,0
	sta	r4H
	sec
	rts


JCurFrHeight:
;	lda	curFrame
	.byte	$af,[curFrame,]curFrame,0
JFrHeight:
;	cmp	numFrames
	.byte	$cf,[numFrames,]numFrames,0
	bcc	10$
	clc
	rts
 10$
	tax
	sec
;	lda	frBotTable,x
	.byte	$bf,[frBotTable,]frBotTable,0
;	sbc	frTopTable,x
	.byte	$ff,[frTopTable,]frTopTable,0
	ina
	sec
	rts

JCurFrBottom:
;	lda	curFrame
	.byte	$af,[curFrame,]curFrame,0
JFrBottom:
;	cmp	numFrames
	.byte	$cf,[numFrames,]numFrames,0
	bcc	10$
	clc
	rts
 10$
	tax
;	lda	frBotTable,x
	.byte	$bf,[frBotTable,]frBotTable,0
	sec
	rts


JCurFrWidth:
;	lda	curFrame
	.byte	$af,[curFrame,]curFrame,0
JFrWidth:
;	cmp	numFrames
	.byte	$cf,[numFrames,]numFrames,0
	bcc	10$
	clc
	rts
 10$
	tax
;	lda	frLRightTable,x
	.byte	$bf,[frLRightTable,]frLRightTable,0
;	sbc	frLLeftTable,x
	.byte	$ff,[frLLeftTable,]frLLeftTable,0
	sta	r1L
;	lda	frHRightTable,x
	.byte	$bf,[frHRightTable,]frHRightTable,0
;	sbc	frHLeftTable,x
	.byte	$ff,[frHLeftTable,]frHLeftTable,0
	sta	r1H
	inc	r1L
	bne	50$
	inc	r1H
 50$
	sec
	rts

SetFrMargins:
	jsr	JCurFrRegs
	MoveB	r2L,windowTop
	MoveB	r2H,windowBottom
	sec
	lda	r4L
.if	C64
	sbc	#8
.else
	sbc	#16
.endif
	sta	rightMargin+0
	sta	gRightMargin+0
	lda	r4H
	sbc	#0
	sta	rightMargin+1
	sta	gRightMargin+1
	MoveB	r3L,leftMargin+0
	sta	gLeftMargin+0
	MoveB	r3H,leftMargin+1
	sta	gLeftMargin+1
	rts

JCurFrDimensions:
	jsr	JCurFrRegs
	jsr	JCurFrWidth
	jsr	JCurFrHeight
	sta	r5L
	rts

JFrDimensions:
	pha
	jsr	JFrRegs
	bcc	90$
	pla
	pha
	jsr	JFrWidth
	bcc	90$
	pla
	pha
	jsr	JFrHeight
	sta	r5L
 90$
	pla
	rts


JGetCurFrame:
;	lda	curFrame
	.byte	$af,[curFrame,]curFrame,0
JGetFrame:
;	cmp	numFrames
	.byte	$cf,[numFrames,]numFrames,0
	bcc	10$
	clc
	rts
 10$
	jsr	JFrDimensions
	ldx	#8
 20$
	lda	r1,x
;	sta	frmWidth,x
	.byte	$9f,[frmWidth,]frmWidth,0
	dex
	bpl	20$
	sec
	rts

