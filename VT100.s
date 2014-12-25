;************************************************************

;	VT100

;	VT100 routines for the terminal.

;************************************************************

VTSTRLENGTH =64


	.psect



ToglVT100:
	lda	vtOn
	eor	#%10000000
	ora	#%01111111
	sta	vtOn
	sta	curVtOn
	jmp	RecolorPad

ToglANSI:
	bit	vtOn
	bmi	10$
	rts
 10$
	lda	ansiOn
	eor	#%10000000
	sta	ansiOn
	jmp	RecolorPad


DoVT100:
	LoadB	vtEscape,#%10000000
	LoadB	maxVTChars,#VTSTRLENGTH
	LoadB	vtPointer,#0
	sta	vtState
	sta	endCharacter
DoVT_2:
	jsr	GetTermByte
	bcs	20$
	jmp	TurnOnCursor
 20$
	cmp	#ESC
	beq	DoVT100
	cmp	#(128|ESC)
	bne	22$
	LoadB	vtString+0,#'['
	ldx	#1
	stx	vtState
	stx	vtPointer
	bne	DoVT_2	;branch always.
 22$
	cmp	#IAC
	bne	24$
	bit	commMode
	bpl	24$
	jsr	LDoIACMode
	bcc	DoVT_2
 24$
	ldx	vtPointer	;is this the first character after the ESC?
	bne	25$	;branch if not.
	jsr	CkEscState
	lda	vtState
	beq	90$
	jmp	DoVT_2
 25$
	cmp	#32
	bcs	30$
	asl	a
	tax
	jsr	SetTxtPos
;	jsr	(ascRoutines,x)
	.byte	$fc,[ascRoutines,]ascRoutines
	jsr	SaveTxtPos
	jmp	DoVT_2
 30$
	cmp	#127
	bcs	90$
	sta	vtString,x
	inx
	stx	vtPointer
	cpx	maxVTChars
	bcs	60$
	cmp	#60	;is this a final character code?
	bcc	DoVT_2	;branch if not.
	sta	endCharacter
	dex
	dec	vtPointer
 60$
	lda	#0
	sta	vtString,x
	lda	vtState
	dea
	jsr	JmpStateRoutine
 90$
	jsr	VTOff
	jmp	DispInChars

vtEscape:
	.block	1
vtPointer:
	.block	1
maxVTChars:
	.block	1
endCharacter:
	.block	1
vtString:
	.block	VTSTRLENGTH+1


CkEscState:
	sta	vtString+0
	ldx	#0
 10$
	cmp	escChars,x
	beq	20$
	inx
	cpx	#[(escRoutines-escChars)
	bcc	10$
	jmp	FlushNow
 20$
	LoadB	vtPointer,#1
	txa
	inx
	stx	vtState
JmpStateRoutine:
	asl	a
	tax
;	jmp	(escRoutines,x)
	.byte	$7c,[escRoutines,]escRoutines

vtState:
	.block	1

escChars:
	.byte	"[()#PDME7s8u=>ZcHNO<"
escRoutines:
	.word	Do1State	;[
	.word	LVTParentheses	;(
	.word	RVTParentheses	;)
	.word	Flush1Char	;#
	.word	FlushNow	;P
	.word	MoveDDown	;D
	.word	MoveMUp	;M
	.word	DoEReturn	;E
	.word	SaveVTAttributes ;7
	.word	SaveVTAttributes ;s
	.word	RstrVTAttributes ;8
	.word	RstrVTAttributes ;u
	.word	SetAppMode	;=
	.word	SetStdMode	;>
	.word	DoZVTReport	;Z
	.word	FlushNow	;c
	.word	FlushNow	;H
	.word	DoG2NxtChar	;N
	.word	DoG3NxtChar	;O
	.word	FlushNow	;<

Flush1Char:
	lda	vtPointer
	cmp	#2
	bcc	10$
	jmp	FlushNow
 10$
	LoadB	maxVTChars,#2
	sec
	rts

DoZVTReport:
	bit	vtOn
	bpl	90$
	jsr	Term2Ident
 90$
	jmp	FlushNow

DoEReturn:
	bit	vtOn
	bpl	90$
	jsr	DispCR
	jsr	DoLineFeed
 90$
	jmp	FlushNow

MoveDDown:
	bit	vtOn
	bpl	90$
	jsr	Move1Down
 90$
	jmp	FlushNow

MoveMUp:
	bit	vtOn
	bpl	90$
	jsr	Move1Up
 90$
;fall through...
FlushNow:
	LoadB	vtState,#0
	jmp	ClrVTString

SetStdMode:
	lda	#%00000000
	.byte	44
SetAppMode:
	lda	#%10000000
	sta	keyPadMode
	jmp	FlushNow

SaveVTAttributes:
	MoveB	charSetUsed,sCharSUsed
	MoveB	useG3Set,sUseG3Set
	MoveW	cursorX,sCrsrX
	MoveB	cursorY,sCrsrY
	MoveB	ansiBold,sAnsiBold
	MoveB	ansiFGColor,sAnsiFGColor
	MoveB	ansiBGColor,sAnsiBGColor
	MoveB	currentMode,sCurrentMode
	jmp	FlushNow

RstrVTAttributes:
	MoveB	sAnsiBold,ansiBold
	MoveB	sAnsiFGColor,ansiFGColor
	MoveB	sAnsiBGColor,ansiBGColor
	MoveB	sCurrentMode,currentMode
	MoveB	sCrsrX+0,cursorX+0
	sta	stringX+0
	MoveB	sCrsrX+1,cursorX+1
	sta	stringX+1
	MoveB	sCrsrY,cursorY
	sta	stringY
	MoveB	sUseG3Set,useG3Set
	LoadW	r0,#fontBase
	MoveB	sCharSUsed,charSetUsed
	bmi	60$
	lsr	a
	bcc	50$
	LoadW	r0,#vtExtraBuffer
	jsr	LoadCharSet
	jmp	FlushNow
 50$
	lsr	a
	bcc	55$
	LoadW	r0,#Pnt8859Set
	jsr	LoadCharSet
	jmp	FlushNow
 55$
	LoadW	r0,#ansiBuffer
 60$
	jsr	LoadCharSet
	jmp	FlushNow


LVTParentheses:
	bit	vtOn
	bpl	5$
	ldx	vtPointer
	cpx	#2
	beq	10$
	LoadB	maxVTChars,#2
 5$
	sec
	rts
 10$
	dex
	lda	vtString,x
	cmp	#'A'
	beq	20$
	cmp	#'B'
	bne	50$
 20$
	jsr	SetRegSet
	clc
	rts
 50$
	cmp	#'O'
	beq	60$
	cmp	#'0'
	bne	90$
 60$
	jsr	SetG3Set
 90$
	clc
	rts

RVTParentheses:
	bit	vtOn
	bpl	5$
	ldx	vtPointer
	cpx	#2
	beq	10$
	LoadB	maxVTChars,#2
 5$
	sec
	rts
 10$
	dex
	lda	vtString,x
	cmp	#'A'
	beq	20$
	cmp	#'B'
	bne	50$
 20$
	jsr	SetG3Set
	clc
	rts
 50$
	cmp	#'O'
	beq	60$
	cmp	#'0'
	bne	90$
 60$
	jsr	SetRegSet
 90$
	clc
	rts

DoG2NxtChar:
	bit	vtOn
	bpl	5$
	ldx	vtPointer
	cpx	#2
	beq	10$
	LoadB	maxVTChars,#2
 5$
	sec
	rts
 10$
	dex
	lda	vtString,x
	bmi	40$
	tax
	lda	g2aTable-32,x
	bra	50$
 40$
	and	#%01111111
	tax
	lda	g2bTable-32,x
 50$
	pha
	jsr	SetTxtPos
	pla
	jsr	PutAnsiChar
	jsr	SaveTxtPos
	clc
	rts

DoG3NxtChar:
	bit	vtOn
	bpl	5$
	ldx	vtPointer
	cpx	#2
	beq	10$
	LoadB	maxVTChars,#2
 5$
	sec
	rts
 10$
	dex
	lda	vtString,x
	bmi	40$
	tax
	lda	g3aTable-32,x
	bra	50$
 40$
	and	#%01111111
	tax
	lda	g3bTable-32,x
 50$
	pha
	jsr	SetTxtPos
	pla
	jsr	PutAnsiChar
	jsr	SaveTxtPos
	clc
	rts

g2aTable:
	.byte	" !",34,"#$%&'()*+,-./"
	.byte	"0123456789:;<=>?"
	.byte	"@ABCDEFGHIJKLMNO"
	.byte	"PQRSTUVWXYZ[\]^_"
	.byte	"`abcdefghijklmno"
	.byte	"pqrstuvwxyz{|}~",127

g3aTable:
	.byte	" !",34,"#$%&'()*+,-./"
	.byte	"0123456789:;<=>?"
	.byte	"@ABCDEFGHIJKLMNO"
	.byte	"PQRSTUVWXYZ[\]^ "
	.byte	4,177,7,7,7,7,248,241
	.byte	7,7,217,191,218,192,197,196
	.byte	196,196,95,95,195,180,193,194
	.byte	179,243,242,227,216,156,7,127

g2bTable:
g3bTable:
	.byte	255,173,155,156,254,157,124,21
	.byte	254,254,166,174,170,45,254,254
	.byte	248,241,253,254,254,230,20,249
	.byte	254,254,167,175,172,171,254,168
	.byte	254,254,254,254,142,143,146,128
	.byte	254,144,254,254,254,254,254,254
	.byte	254,165,254,254,254,254,153,254
	.byte	254,254,254,254,154,254,254,225
	.byte	133,160,131,254,132,134,145,135
	.byte	138,130,136,137,141,161,140,139
	.byte	254,164,149,162,147,254,148,246
	.byte	237,151,163,150,129,254,254,152

Do1State:
	bit	vtOn
	bpl	3$
	lda	endCharacter
	bne	5$
 3$
	sec
	rts
 5$
	jsr	VTParameter
	lda	endCharacter
	bpl	10$
	rts
 10$
	sec
	sbc	#60
	asl	a
	tax
;	jsr	(vtRoutines,x)
	.byte	$fc,[vtRoutines,]vtRoutines
ClrVTString:
	ldx	#VTSTRLENGTH
	lda	#0
 20$
	sta	vtString,x
	dex
	bpl	20$
	rts

vtRoutines:
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	InsChars	;@ (64)
	.word	MoveUp	;A (65)
	.word	MoveDown	;B (66)
	.word	MoveRight	;C (67)
	.word	MoveLeft	;D (68)
	.word	NullRoutine,NullRoutine
	.word	GoToColumn	;G (71)
	.word	VTCursor	;H (72)
	.word	NullRoutine	;I (73)
	.word	VTClear	;J (74)
	.word	EraseInLine	;K (75)
	.word	InsLines	;L (76)
	.word	DelLines	;M (77)
	.word	EraseInLine	;N (78)
	.word	VTClear	;O (79)
	.word	DelChars	;P (80)
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine,NullRoutine
	.word	Term2Ident	;c (99)
	.word	GoToRow	;d (100)
	.word	NullRoutine
	.word	VTCursor	;f (102)
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine,NullRoutine
	.word	FontMode	;m (109)
	.word	AnsiReport	;n (110)
	.word	NullRoutine,NullRoutine,NullRoutine
	.word	SetScrRegion	;r (114)
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine	; (127)


Term2Ident:
	lda	vtString+1
	cmp	#'?'
	bne	10$
	rts
 10$
	LoadW	r0,#vt1IdentString
	jmp	SndR0String

Term3Ident:
	lda	vtString+1
	cmp	#'?'
	bne	10$
	rts
 10$
	LoadW	r0,#vt3IdentString
	jmp	SndR0String

vt1IdentString:
	.byte	ESC,"[?1",$3b,"2c",0
vt3IdentString:
	.byte	ESC,"[?c",0


AnsiReport:
	lda	vtBinary
	cmp	#5
	bne	10$
 5$
	LoadW	r0,#ansStatString
	jmp	SndR0String
 10$
	cmp	#6
	bne	90$
 20$
	lda	#ESC
	jsr	PutMdmByte
	lda	#'['
	jsr	PutMdmByte
	lda	cursorY
	lsr	a
	lsr	a
	lsr	a
	ina
	jsr	Snd2Ascii
	lda	#$3b	;semi-colon.
	jsr	PutMdmByte
	rep	%00100000
	lda	cursorX
	lsr	a
	lsr	a
.if	C128
	lsr	a
.endif
	sep	%00100000
	ina
	jsr	Snd2Ascii
	lda	#'R'
	bit	commMode
	bmi	80$
	jmp	Send1Byte
 80$
	jmp	SndTermByte
 90$
	rts

ansStatString:
	.byte	ESC,"[0n",0

Snd2Ascii:
	jsr	LByte2Ascii
	ldy	#0
 10$
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#'0'
	bne	40$
	iny
	cpy	#2
	bcc	10$
 40$
	phy
;	lda	[r0],y
	.byte	$b7,r0
	beq	80$
	jsr	PutMdmByte
	ply
	iny
	cpy	#3
	bcc	40$
	rts
 80$
	ply
	rts

PutMdmByte:
	bit	commMode
	bmi	10$
	jmp	Send1Byte
 10$
	jmp	PutTCPByte

VTClear:
	lda	#0
	jsr	SetPattern
	ldx	vtBinary	;get the parameter value.
	cpx	#3	;is it less than 3?
	bcc	10$	;branch if within range.
	rts		;or do nothing.
 10$
	txa
	asl	a
	tax
;	jmp	(vtClrTable,x)
	.byte	$7c,[vtClrTable,]vtClrTable

vtClrTable:
	.word	ClrToEnd,ClrFromStart,DspPageBreak

ClrToEnd:
	jsr	ClrLnToEnd
	lda	cursorY
	cmp	#BOT_LINE
	bcc	10$
	rts
 10$
	adc	#TLINEHEIGHT
	sta	r2L
	LoadB	r2H,#BOT_LINE+TLINEHEIGHT-1
	jmp	ClrLft2Right

ClrFromStart:
	jsr	ClrLnFromStart
	sec
	lda	cursorY
	cmp	#TOP_LINE+TLINEHEIGHT
	bcs	10$
	rts
 10$
	sbc	#1
	sta	r2H
	LoadB	r2L,#TOP_LINE
	jmp	ClrLft2Right


VTCursor:
	lda	vtBinary+0	;get the row value.
	beq	20$
	dea
	cmp	#NUMTERMLINES
	bcc	10$
	lda	#NUMTERMLINES-1
 10$
	asl	a
	asl	a
	asl	a
 20$
	sta	cursorY
	sta	stringY
	clc
	adc	baselineOffset
	sta	r1H
	LoadB	cursorX+1,#0
	lda	vtBinary+1	;get the column value.
	beq	30$
	dea
	cmp	#80
	bcc	30$
	lda	#79
 30$
	asl	a
	rol	cursorX+1
	asl	a
	rol	cursorX+1
.if	C128
	asl	a
	rol	cursorX+1
.endif
	sta	cursorX+0
	sta	stringX+0
	sta	r11L
	MoveB	cursorX+1,stringX+1
	sta	r11H
	rts

EraseInLine:
	lda	#0
	jsr	SetPattern
	ldy	vtBinary	;get the parameter value.
	cpy	#3	;is it higher than 2?
	bcc	10$	;branch if not.
	rts		;or do nothing.
 10$
	lda	eraseLTable,y
	ldx	eraseHTable,y
	jmp	CallRoutine

eraseLTable:
	.byte	[ClrLnToEnd,[ClrLnFromStart,[ClrEntLine
eraseHTable:
	.byte	]ClrLnToEnd,]ClrLnFromStart,]ClrEntLine


ClrLnFromStart:
	lda	cursorX+0
	ora	cursorX+1
	bne	10$
	rts
 10$
	sec
	lda	cursorX+0
	sbc	#1
	sta	r4L
	lda	cursorX+1
	sbc	#0
	sta	r4H
	LoadB	r3L,#0
	sta	r3H
	jsr	LnTopBottom
	jmp	ClrNColor

ClrLnToEnd:
	jsr	LnTopBottom
	MoveW	cursorX,r3
	jsr	SetRight
	jmp	ClrNColor

ClrEntLine:
	jsr	LnTopBottom
ClrLft2Right:
	jsr	SetLftRght
	jmp	ClrNColor

LnTopBottom:
	MoveB	cursorY,r2L
	clc
	adc	#TLINEHEIGHT-1
	sta	r2H
	rts

ClrNColor:
	jsr	Rectangle
	bit	vtOn
	bmi	10$
 5$
	rts
 10$
	bit	ansiOn
	bpl	5$
	jsr	ConvToCards
	ldx	ansiFGColor
	lda	ansiFGTable,x
	ldx	ansiBGColor
	ora	ansiBGTable,x
	sta	r4H
	jmp	ColorRectangle

MoveUp:
	jsr	GetMoveParameter
 10$
	pha
	jsr	Move1Up
	pla
	dea
	bne	10$
	rts

Move1Up:
	sec
	lda	cursorY
	sbc	#TLINEHEIGHT
	bcs	10$
	lda	#0
 10$
	sta	cursorY
	sta	stringY
	lsr	a
	lsr	a
	lsr	a
	cmp	topScrlLine
	bcc	20$
	rts
 20$
	lda	topScrlLine
	sta	r3L
	asl	a
	asl	a
	asl	a
	sta	cursorY
	sta	stringY
	lda	botScrlLine
	sta	r3H
	jmp	LScrDnRegion


MoveDown:
	jsr	GetMoveParameter
 10$
	pha
	jsr	Move1Down
	pla
	dea
	bne	10$
	rts

Move1Down:
	clc
	lda	cursorY
	adc	#TLINEHEIGHT
	sta	cursorY
	sta	stringY
	lsr	a
	lsr	a
	lsr	a
	cmp	botScrlLine
	bcc	10$
	bne	20$
 10$
	rts
 20$
	lda	botScrlLine
	sta	r3H
	asl	a
	asl	a
	asl	a
	sta	cursorY
	sta	stringY
	lda	topScrlLine
	sta	r3L
	jmp	LScrUpRegion


MoveRight:
	jsr	GetMoveParameter
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
.if	C128
	asl	a
.endif
	clc
	adc	cursorX
.if	C64
	cmp	#[317
	.byte	]317
.else
	cmp	#[633
	.byte	]633
.endif
	bcc	60$
.if	C64
	lda	#[316
	.byte	]316
.else
	lda	#[632
	.byte	]632
.endif
 60$
	sta	cursorX
	sta	stringX
	sep	%00100000
	rts


MoveLeft:
	jsr	GetMoveParameter
	.byte	44
Back1Space:
	lda	#1
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
.if	C128
	asl	a
.endif
	sta	r11
	sec
	lda	cursorX
	sbc	r11
	bcs	50$
	lda	#[0
	.byte	]0
 50$
	sta	cursorX
	sta	stringX
	sep	%00100000
	rts

GetMoveParameter:
	lda	vtBinary	;get the parameter value.
	bne	10$
	lda	#1
 10$
	rts


GoToRow:
	jsr	GetMoveParameter
	dea
	beq	10$
	cmp	#NUMTERMLINES
	bcc	10$
	lda	#NUMTERMLINES-1
 10$
	asl	a
	asl	a
	asl	a
	sta	cursorY
	sta	stringY
	LoadB	cursorX+0,#0
	sta	cursorX+1
	sta	stringX+0
	sta	stringX+1
	rts

GoToColumn:
	jsr	GetMoveParameter
	dea
	beq	10$
	cmp	#80
	bcc	10$
	lda	#79
 10$
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	asl	a
	asl	a
.if	C128
	asl	a
.endif
	sta	cursorX
	sta	stringX
	sep	%00100000
	rts

FontMode:
	ldy	#0
	lda	vtParPointer
	bne	10$
	jmp	PlainFont
 10$
	phy
	lda	vtBinary,y	;get the parameter value.
	cmp	#8
	bcc	40$
	cmp	#22
	bcc	80$
	cmp	#28
	bcc	30$
	cmp	#30
	bcc	80$
	cmp	#40
	bcs	15$
	jsr	MakeFGColor
	bra	80$
 15$
	cmp	#50
	bcs	80$
	jsr	MakeBGColor
	bra	80$
 30$
	sec
	sbc	#14
 40$
	asl	a
	tax
;	jsr	(vtfontRoutines,x)
	.byte	$fc,[vtfontRoutines,]vtfontRoutines
 80$
	ply
	iny
	cpy	vtParPointer
	bcc	10$
	rts

vtfontRoutines:
	.word	PlainFont,BoldFont,NullRoutine,ItalicFont
	.word	UnLineFont,BlinkFont,ItalicFont,RevFont
	.word	RmvBold,NullRoutine,RmvUnLine,RmvBlink
	.word	NullRoutine,RmvReverse


;call this with the acc holding a value between
;30 and 39.
MakeFGColor:
	sec
	sbc	#30
	cmp	#8
	bcc	40$
	beq	90$
	lda	#7
 40$
	ora	ansiBold
	sta	ansiFGColor
 90$
	rts

;call this with the acc holding a value between
;40 and 49.
MakeBGColor:
	sec
	sbc	#40
	cmp	#8
	bcc	40$
	beq	90$
	lda	#0
 40$
	sta	ansiBGColor
.if	C64
	jsr	FixMseColor
.endif
 90$
	rts

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

;+++fix this to load default colors from
;+++a configuration setting.
PlainFont:
	LoadB	ansiFGColor,#7
	LoadB	ansiBGColor,#0
	LoadB	currentMode,#0
	sta	ansiBold
	rts

BoldFont:
	lda	#%00001000
	sta	ansiBold
	ora	ansiFGColor
	sta	ansiFGColor
	rts

RmvBold:
	lda	#%00000000
	sta	ansiBold
	lda	ansiFGColor
	and	#%00000111
	sta	ansiFGColor
	rts

BlinkFont:
ItalicFont:
	lda	#SET_ITALIC
	.byte	44
UnLineFont:
	lda	#SET_UNDERLINE
	.byte	44
RevFont:
	lda	#SET_REVERSE
	ora	currentMode
	sta	currentMode
	rts

RmvUnLine:
	lda	#[~SET_UNDERLINE
	.byte	44
RmvBlink:
	lda	#[~SET_ITALIC
	.byte	44
RmvReverse:
	lda	#[~SET_REVERSE
	and	currentMode
	sta	currentMode
	rts

InsLines:
	jsr	GetMoveParameter
 20$
	pha
	MoveB	botScrlLine,r3H
	lda	cursorY
	lsr	a
	lsr	a
	lsr	a
	sta	r3L
	jsr	LScrDnRegion
	pla
	dea
	bne	20$
	rts

DelLines:
	jsr	GetMoveParameter
 20$
	pha
	MoveB	botScrlLine,r3H
	lda	cursorY
	lsr	a
	lsr	a
	lsr	a
	sta	r3L
	jsr	LScrUpRegion
	pla
	dea
	bne	20$
	rts

DelChars:
	jsr	GetMoveParameter
 10$
	pha
	jsr	Del1Char
	pla
	dea
	bne	10$
	rts

InsChars:
	jsr	GetMoveParameter
 10$
	pha
	jsr	Ins1Char
	pla
	dea
	bne	10$
	rts

.if	C64
Del1Char:
	CmpWI	cursorX,#316
	bcs	90$
	LoadB	r15H,#TLINEHEIGHT
	ldx	cursorY
	stx	r14L
 10$
	LoadB	r15L,#%00000000
	jsr	GetScanLine
	rep	%00010000
	ldy	#[312
	.byte	]312
 30$
	lda	(r5),y
	asl	a
	rol	r14H
	asl	a
	rol	r14H
	asl	a
	rol	r14H
	asl	a
	rol	r14H
	ora	r15L
	sta	(r5),y
	lda	r14H
	and	#%00001111
	sta	r15L
	cpy	cursorX
	beq	60$
	bcc	60$
	rep	%00110000
	tya
	sec
	sbc	#[8
	.byte	]8
	tay
	sep	%00100000
	cpy	cursorX
	bcs	30$
	lda	(r5),y
	and	#%11110000
	ora	r15L
	sta	(r5),y
 60$
	sep	%00110000
	inc	r14L
	ldx	r14L
	dec	r15H
	bne	10$
 90$
	rts


Ins1Char:
	CmpWI	cursorX,#316
	bcs	90$
	LoadB	r15H,#TLINEHEIGHT
	ldx	cursorY
	stx	r14L
 10$
	jsr	GetScanLine
	rep	%00010000
	ldy	#[304
	.byte	]304
	sty	leftY
	ldy	#[312
	.byte	]312
	sty	rightY
 30$
	ldy	rightY
	lda	(r5),y
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	sta	(r5),y
	cpy	cursorX
	bcc	60$
	beq	60$
	ldy	leftY
	lda	(r5),y
	lsr	a
	ror	r14H
	lsr	a
	ror	r14H
	lsr	a
	ror	r14H
	lsr	a
	ror	r14H
	lda	(r5),y
	and	#%11110000
	sta	(r5),y
	ldy	rightY
	lda	r14H
	and	#%11110000
	ora	(r5),y
	sta	(r5),y
	ldy	leftY
	cpy	cursorX
	bcc	60$
	rep	%00100000
	lda	rightY
	sec
	sbc	#[8
	.byte	]8
	sta	rightY
	lda	leftY
	sec
	sbc	#[8
	.byte	]8
	sta	leftY
	sep	%00100000
	bra	30$
 60$
	sep	%00110000
	inc	r14L
	ldx	r14L
	dec	r15H
	bne	10$
 90$
	rts

leftY:
	.block	2
rightY:
	.block	2


.else

Del1Char:
	CmpWI	cursorX,#632
	bcc	10$
	rts
 10$
	jsr	SetDelRegs
	jsr	Mv80Chars
	LoadW	r3,#632
	LoadW	r4,#639
;fall through...
Clr1Char:
	MoveB	cursorY,r2L
	clc
	adc	#7
	sta	r2H
	lda	#0
	jsr	SetPattern
	jmp	Rectangle

SetDelRegs:
	ldx	cursorY
	jsr	GetScanLine
	rep	%00100000
	lda	cursorX
	lsr	a
	lsr	a
	lsr	a
	sta	r15
	clc
	adc	r5
	sta	r1
	ina
	sta	r0
	sec
	lda	#[79
	.byte	]79
	sbc	r15
	sta	r2
	sep	%00100000
	LoadB	r15H,#TLINEHEIGHT
	rts

Mv80Chars:
 20$
	jsr	MoveVData
	AddVW	#80,r0
	AddVW	#80,r1
	dec	r15H
	bne	20$
	rts



Ins1Char:
	jsr	SetDelRegs
	PushW	r0
	MoveW	r1,r0
	PopW	r1
	jsr	Mv80Chars
	clc
	MoveB	cursorX+0,r3L
	adc	#7
	sta	r4L
	MoveB	cursorX+1,r3H
	adc	#0
	sta	r4H
	jmp	Clr1Char

.endif


SetScrRegion:
	lda	vtParPointer
	bne	10$
 5$
	LoadB	topScrlLine,#0
	LoadB	botScrlLine,#NUMTERMLINES-1
	rts
 10$
	lda	vtBinary+0
	beq	20$
	dea
	cmp	#NUMTERMLINES
	bcc	20$
	lda	#NUMTERMLINES-1
 20$
	sta	topScrlLine
	lda	vtBinary+1
	beq	25$
	dea
	cmp	#NUMTERMLINES
	bcc	30$
 25$
	lda	#NUMTERMLINES-1
 30$
	sta	botScrlLine
	cmp	topScrlLine
	bcc	5$
	beq	5$
	rts

VTParameter:
	ldy	#31
	lda	#0
 2$
	sta	vtBinary,y
	dey
	bpl	2$
	iny
	sty	vtParPointer
	iny
 5$
	ldx	#0
	stx	vtParString+0
	stx	vtParString+1
	stx	vtParString+2
 15$
	lda	vtString,y
	beq	30$	;branch if end of string.
	cmp	#' '	;space?
	beq	30$	;branch to ignore spaces.
	cmp	#$3b	;semi-colon?
	beq	30$	;branch if so.
	sta	vtParString,x
	iny
	cpy	#VTSTRLENGTH
	bcs	90$
	inx
	cpx	#3
	bcc	15$
 25$
	lda	vtString,y
	beq	30$
	cmp	#$3b
	beq	30$
	cmp	#' '
	beq	30$
	iny
	cpy	#VTSTRLENGTH
	bcc	25$
	bcs	90$
 30$
	lda	vtParString+0	;past the last parameter?
	beq	80$	;branch if so.
	phy
	jsr	Asc2Binary
	ply
	bcc	90$	;branch on any error.
	ldx	vtParPointer
	sta	vtBinary,x
	inc	vtParPointer
	cpx	#31
	bcs	90$
	iny
	cpy	#VTSTRLENGTH
	bcs	90$
	lda	vtString,y	;end of string yet?
	bne	5$	;branch if not.
 80$
	sec
	rts
 90$
	clc
	rts


vtParString:
	.block	3

vtParPointer:
	.block	1
vtBinary:
	.block	32

;this will take the ascii decimal string at vtParString and
;convert it to an 8-bit binary number. If the string contains
;any invalid characters or exceeds 255, the carry will be clear
;to indicate an error.
;destroys a,x,y,r5-r9
Asc2Binary:
	ldy	#0
	sty	r7L
	sty	r7H
	lda	vtParString,y
	beq	90$	;branch if null string.
 30$
	lda	vtParString,y
	beq	50$
	jsr	DecToBin
	bcc	90$
	phy
	jsr	PutDecDigit
	ply
;	bcs	90$	;we're only working with 3 characters.
	iny
	cpy	#3
	bcc	30$
 50$
	lda	r7H
	bne	90$
	lda	r7L
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

;this multiplies the current value in r7 by 10 and then adds
;the value in the accumulator.
PutDecDigit:
	pha
	MoveW	r7,r5
	LoadB	r9L,#10
	ldx	#r5
	ldy	#r9L
	jsr	BMult
	pla
	clc
	adc	r5L
	sta	r7L
	lda	r5H
	adc	#0
	sta	r7H
	rts
