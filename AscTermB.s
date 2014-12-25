;************************************************************

;	AscTermB

;	routines for the ASCII terminal window.

;************************************************************


	.psect


;+++make an echo routine for when TCP is used.
SndTermByte:
	bit	commMode
	bmi	20$
	jmp	Send1Byte
 20$
;	cmp	#CR
;	bne	40$
;	jsr	PutTCPByte
;	lda	#LF
; 40$
	jsr	PutTCPByte
	jsr	OutTermBuffer
	ldx	#0
	rts

GetTermByte:
	bit	commMode
	bmi	20$
	jmp	GetFrmBuf
 20$
	lda	tcpOpen
	bmi	30$
	bne	25$
	clc
	rts
 25$
	LoadB	GetTermByte+0,#$4c
	LoadB	GetTermByte+1,#[EndTCPSession
	LoadB	GetTermByte+2,#]EndTCPSession
 30$
	PushB	r1H
	PushW	r11
	jsr	GetTCPByte
	sta	GTB4+1
	PopW	r11
	PopB	r1H
GTB4:
	lda	#0	;this changes.
	rts


EndTCPSession:
	PushB	r1H
	PushW	r11
	jsr	GetTCPByte
	sta	ETS4+1
	PopW	r11
	PopB	r1H
	bcc	ETS5
ETS4:
	lda	#0	;this changes.
	rts
ETS5:
	LoadB	vtPointer,#0
	sta	vtEscape
	LoadB	GetTermByte+0,#$2c
	LoadB	GetTermByte+1,#[commMode
	LoadB	GetTermByte+2,#]commMode
	jsr	LClsTCPConnection
	LoadB	tcpOpen,#%00000000
	jsr	FixMainLoop
	jsr	InetSession
	bcc	90$
	jsr	ResetFont
	jsr	DoPageBreak
	jmp	StartTelnet
 90$
	jsr	ResetFont
	jsr	RecolorPad
	jmp	TurnOnPrompt


WatchPPP:
	jsr	GetFrmBuf
	bcc	15$
	cmp	#PPP_FLAG
	beq	20$
	sec
 15$
	rts
 20$
	LoadB	GetTermByte+0,#$2c
	LoadB	GetTermByte+1,#[commMode
	LoadB	GetTermByte+2,#]commMode
	MoveB	curVtOn,vtOn
	jsr	RecolorPad
	jsr	FixMainLoop
	lda	waveRunning
	and	#%00100000
	beq	70$
	jsr	LPPPLinkUp
	bcs	30$
	lda	#%00000000
	.byte	44
 30$
	lda	#%10000000
	sta	commMode
;+++if PPP failed, announce it here.
	jmp	QuitTerm
 70$
	jsr	LPPPLinkUp
	bcc	90$
	LoadB	commMode,#%10000000
	lda	hostName+0
	bne	80$
	jmp	IS1
 80$
	jsr	DoPageBreak
	jmp	StartTelnet
 90$
	jsr	LSaveTxtScreen
	ldx	#3
	ldy	#1
	jsr	LURLBarMsg	;display "Disconnecting..."
	jsr	Disconnect
;+++announce that PPP failed here.
	jsr	LRstrTxtScreen
	jsr	DefSLSettings
	jsr	ResetFont
	jmp	TurnOnPrompt

DispInChars:
	jsr	SetTxtPos
DIC2:
	bit	modKeyCopy	;CMDR key held down?
	bvs	4$	;branch if so.
	lda	menuNumber	;is a menu dropped?
	bne	4$	;branch if so.
	bit	vtEscape	;currently working on a VT command?
	bpl	5$	;branch if not.
	jsr	SaveTxtPos
	jsr	TurnOffCursor
	jmp	DoVT_2
 4$
	jsr	SaveTxtPos
	jmp	TurnOnCursor
 5$
	jsr	GetTermByte
	bcc	4$
	pha
	jsr	TurnOffCursor
	pla
 10$
	cmp	#ESC
	bne	15$
	jsr	SaveTxtPos
	jmp	DoVT100
 15$
	cmp	#(128|ESC)
	bne	20$
	LoadB	vtPointer,#1
	LoadB	vtEscape,#%10000000
	jsr	SaveTxtPos
	jmp	DoVT_2
 20$
	cmp	#IAC
	bne	25$
	bit	commMode
	bpl	25$
	jsr	SaveTxtPos
	jsr	LDoIACMode
	bcc	4$
	cmp	#IAC
	bne	10$
 25$
	cmp	#32
	bcc	85$
	cmp	#127
	bne	30$
	jsr	DoDelete
	jmp	DIC2
 30$
	jsr	PutVTChar
	jmp	DIC2
 85$
	asl	a
	tax
;	jsr	(ascRoutines,x)
	.byte	$fc,[ascRoutines,]ascRoutines
	jmp	DIC2

;call this with the acc holding an ascii value
;between 32 and 254.
PutVTChar:
	and	vtOn
	bit	vtOn
	bmi	10$
	cmp	#32
	bcs	PAC2
	rts
 10$
	bit	useG3Set
	bpl	60$
	tax
	bpl	30$
	and	#%01111111
	cmp	#32
	bcs	20$
	ora	#%10000000
	jmp	PutExtChar
 20$
	tax
	lda	g3bTable-32,x
	jmp	PAC2
 30$
	lda	g3aTable-32,x
	jmp	PAC2
 60$

;fall through to next page...

;...previous page continues here
PutAnsiChar:
	bit	ansiOn
	bvc	PAC2
	jmp	PutISOChar
PAC2:
	cmp	#32
	bcc	PutExtChar
	cmp	#127
	bcc	PutLowChar
	beq	90$
	cmp	#160
	bcc	PutExtChar
	cmp	#255
	bcc	PutHighChar
 90$
	rts


PutISOChar:
	cmp	#32
	bcc	90$
	cmp	#127
	bcc	PutLowChar
	beq	30$
	cmp	#159
	bcc	Put8859ExtChar
	cmp	#161
	bcs	Put8859HighChar ;branch always.
 30$
	lda	#32
	bne	PutLowChar	;branch always.
 90$
	rts



PutLowChar:
	sta	nxtChar
	jsr	PntLowerSet
	jmp	PutCChar

PutHighChar:
	and	#%01111111
	sta	nxtChar
	jsr	PntUpperSet
	jmp	PutCChar

PutExtChar:
	jsr	PntExtraSet
	clc
	adc	#$20
	bpl	50$
	adc	#$20
	and	#%01111111
 50$
	sta	nxtChar
	jmp	PutCChar

Put8859ExtChar:
	jsr	PntExtraSet
	sec
	sbc	#$20
	sta	nxtChar
	jmp	PutCChar

Put8859HighChar:
	jsr	Pnt8859Set
	sec
	sbc	#129
	sta	nxtChar
	jmp	PutCChar


PntLowerSet:
	bit	charSetUsed
	bmi	90$
	pha
	LoadW	r0,#fontBase
	jsr	LoadCharSet
	lda	charSetUsed
	and	#%11111100
	ora	#%10000000
	sta	charSetUsed
	pla
 90$
	rts

PntUpperSet:
	pha
	lda	charSetUsed
	and	#%10000011
	beq	90$
 30$
	LoadW	r0,#ansiBuffer
	jsr	LoadCharSet
	lda	charSetUsed
	and	#%01111100
	sta	charSetUsed
 90$
	pla
	rts


PntExtraSet:
	pha
	lda	charSetUsed
	lsr	a
	bcs	90$
	LoadW	r0,#vtExtraBuffer
	jsr	LoadCharSet
	lda	charSetUsed
	and	#%01111101
	ora	#%00000001
	sta	charSetUsed
 90$
	pla
	rts

Pnt8859Set:
	pha
	lda	charSetUsed
	lsr	a
	lsr	a
	bcs	90$
	LoadW	r0,#buf8859
	jsr	LoadCharSet
	lda	charSetUsed
	and	#%01111110
	ora	#%00000010
	sta	charSetUsed
 90$
	pla
	rts

ascRoutines:
	.word	NullRoutine,NullRoutine,Term3Ident,NullRoutine
	.word	AnswerBack,AnswerBack,NullRoutine,DoBeep
	.word	Do8,DoTab,DoLineFeed,NullRoutine
	.word	DspPageBreak,DispCR,SetG3Set,SetRegSet
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine
	.word	VTOff,NullRoutine,VTOff,NullRoutine
	.word	NullRoutine,NullRoutine,NullRoutine,NullRoutine


VTOff:
	LoadB	vtEscape,#0
	sta	vtPointer
	sta	endCharacter
	sta	vtState
	LoadB	maxVTChars,#VTSTRLENGTH
	rts

TurnOffCursor:
	bit	crsrRunning
	bmi	10$
	rts
 10$
	php
	sei
	jsr	PromptOff
	LoadB	alphaFlag,#0
	sta	crsrRunning
	plp
NullRoutine:
	rts

TurnOnCursor:
	bit	crsrRunning
	bpl	10$
	rts
 10$
	LoadB	alphaFlag,#%10000000
	sta	crsrRunning
	jmp	PromptOn

WrapTxtLine:
	jsr	DispCR
	jsr	DoLineFeed
	lda	nxtChar
	jmp	PutChar

SetRegSet:
	lda	#%00000000
	.byte	44
SetG3Set:
	lda	#%10000000
	sta	useG3Set
	rts


SendCR:
	lda	#CR
	jmp	SndTermByte

DoPageBreak:
	jsr	TurnOffCursor
	jsr	DspPageBreak
	jmp	TurnOnPrompt

DspPageBreak:
	jsr	RecolorPad
	jsr	ClearPad
	jsr	StrXYZero
	LoadB	currentMode,#0
	rts

DoLineFeed:
	PushB	crsrRunning
	jsr	TurnOffCursor
	lda	cursorY
	lsr	a
	lsr	a
	lsr	a
	cmp	botScrlLine
	bcc	50$
	beq	30$
	clc
	lda	cursorY
	adc	#TLINEHEIGHT
	sta	cursorY
	lsr	a
	lsr	a
	lsr	a
	cmp	botScrlLine
	bcc	60$
	beq	60$
	cmp	#24
	bcc	50$
	lda	#192
	bne	60$
 30$
	PushW	r11
.if	C128
	jsr	TempHideMouse
.endif
	jsr	LScrollScreen
	PopW	r11
	lda	botScrlLine
.if	C128
	cmp	#24
	bne	40$
	ldx	topScrlLine
	bne	40$
	dea
 40$
.endif
	asl	a
	asl	a
	asl	a
	sta	cursorY
	bra	60$
 50$
	clc
	lda	cursorY
	adc	#TLINEHEIGHT
	sta	cursorY
 60$
	sta	stringY
	clc
	adc	baselineOffset
	sta	r1H
	pla
	bpl	70$
	jmp	TurnOnPrompt
 70$
	rts

DispCR:
	PushB	crsrRunning
	jsr	TurnOffCursor
	LoadB	r11L,#0
	sta	r11H
	sta	cursorX+0
	sta	cursorX+1
	sta	stringX+0
	sta	stringX+1
	pla
	bpl	50$
	jmp	TurnOnPrompt
 50$
	rts

AnswerBack:
	LoadW	r0,#ansBackString
	jmp	SndR0String

ansBackString:
	.byte	"WaveTerm V1.0",0

SndR0String:
	ldy	#0
	bit	commMode
	bmi	50$
 10$
	phy
	lda	(r0),y
	beq	20$
	jsr	SndTermByte
	bne	20$
	ply
	iny
	bne	10$	;branch always.
	rts		;but just in case.
 20$
	pla
 45$
	rts
 50$
	lda	(r0),y
	beq	60$
	iny
	bne	50$
 60$
	tya
	beq	45$
	dey
	sty	r1L
	ldy	#0
 70$
	cpy	r1L
	beq	80$
	phy
	lda	(r0),y
	jsr	PutTCPByte
	ply
	iny
	bne	70$
 80$
	lda	(r0),y
	jmp	SndTermByte


Do8:
	bit	commMode
	bpl	10$
	jsr	SaveTxtPos
	jsr	Back1Space
	jmp	SetTxtPos
 10$
DoDelete:
	lda	r11H
	bne	10$
	lda	r11L
.if	C64
	cmp	#4
.else
	cmp	#8
.endif
	bcs	10$
	rts
 10$
	lda	#'M'
	ldx	currentMode
	jsr	GetRealSize
	sty	realWidth
	lda	#8
	jmp	PutChar


;this uses PutChar to put the character to the
;screen and also puts a color value to the
;color memory if colors are turned on.
PutCChar:
	bit	vtOn
	bpl	50$
	bit	ansiOn
	bpl	50$
	pha
.if	C128
	lda	vdcClrMode
	beq	45$
.endif
	rep	%00110000
.if	C128
	lda	r1
	pha
.endif
	lda	cursorY
	and	#[$00ff
	.byte	]$00ff
	lsr	a
	lsr	a
	tax
	lda	r11
	lsr	a
	lsr	a
	lsr	a
	clc
	adc	clrMtrxTable,x
.if	C64
	pha
	sep	%00110000
	ldx	ansiFGColor
	lda	ansiFGTable,x
	ldx	ansiBGColor
	ora	ansiBGTable,x
	rep	%00010000
	plx
	sta	COLOR_MATRIX,x
	sep	%00010000
.else
	sta	r1
	sep	%00110000
	ldx	ansiFGColor
	lda	fore80Table,x
	ldx	ansiBGColor
	ora	back80Table,x
	jsr	PokeVRam
	PopW	r1
.endif
 45$
	pla
 50$
	jmp	PutChar

clrMtrxTable:
.if	C64
	.word	40*0
	.word	40*1
	.word	40*2
	.word	40*3
	.word	40*4
	.word	40*5
	.word	40*6
	.word	40*7
	.word	40*8
	.word	40*9
	.word	40*10
	.word	40*11
	.word	40*12
	.word	40*13
	.word	40*14
	.word	40*15
	.word	40*16
	.word	40*17
	.word	40*18
	.word	40*19
	.word	40*20
	.word	40*21
	.word	40*22
	.word	40*23
	.word	40*24
.else
	.word	$4000+(80*0)
	.word	$4000+(80*1)
	.word	$4000+(80*2)
	.word	$4000+(80*3)
	.word	$4000+(80*4)
	.word	$4000+(80*5)
	.word	$4000+(80*6)
	.word	$4000+(80*7)
	.word	$4000+(80*8)
	.word	$4000+(80*9)
	.word	$4000+(80*10)
	.word	$4000+(80*11)
	.word	$4000+(80*12)
	.word	$4000+(80*13)
	.word	$4000+(80*14)
	.word	$4000+(80*15)
	.word	$4000+(80*16)
	.word	$4000+(80*17)
	.word	$4000+(80*18)
	.word	$4000+(80*19)
	.word	$4000+(80*20)
	.word	$4000+(80*21)
	.word	$4000+(80*22)
	.word	$4000+(80*23)
	.word	$4000+(80*24)
.endif

.if	C128
fore80Table:
	.byte	BLACK80<<4,DK80RED<<4,DK80GREEN<<4,DK80YELLOW<<4
	.byte	DK80BLUE<<4,DK80PURPLE<<4,DK80CYAN<<4,LT80GREY<<4
;these are used for bold characters.
	.byte	DK80GREY<<4,LT80RED<<4,LT80GREEN<<4,LT80YELLOW<<4
	.byte	LT80BLUE<<4,LT80PURPLE<<4,LT80CYAN<<4,WHITE80<<4

back80Table:
	.byte	BLACK80,DK80RED,DK80GREEN,DK80YELLOW
	.byte	DK80BLUE,DK80PURPLE,DK80CYAN,LT80GREY
.endif

DoTab:
	rep	%00100000
	clc
	lda	r11
.if	C64
	cmp	#[288
	.byte	]288
	bcs	60$
	and	#[$ffe0
	.byte	]$ffe0
	adc	#[32
	.byte	]32
.else
	cmp	#[576
	.byte	]576
	bcs	60$
	and	#[$ffc0
	.byte	]$ffc0
	adc	#[64
	.byte	]64
.endif
	sta	r11
 60$
	sep	%00100000
	rts

SendDelete:
	bit	commMode
	bpl	30$
	lda	deleteValue
	bpl	20$
	lda	#IAC
	jsr	PutTCPByte
	lda	#EC
 20$
	jmp	SndTermByte
 30$
	lda	deleteValue
	bpl	40$
	lda	#8
 40$
	jmp	SndTermByte

SendESC:
	lda	#ESC
	jmp	SndTermByte



SendUp:
	lda	#'A'
	.byte	44
SendDown:
	lda	#'B'
	.byte	44
SendRight:
	lda	#'C'
	.byte	44
SendLeft:
	lda	#'D'
	pha
	bit	commMode
	bmi	50$
	lda	#ESC
	jsr	SndTermByte
	bne	90$
	lda	#'['
	bit	keyPadMode
	bpl	40$
	lda	#'O'
 40$
	jsr	SndTermByte
	bne	90$
	pla
	jmp	SndTermByte
 50$
	lda	#ESC
	jsr	PutTCPByte
	lda	#'['
	bit	keyPadMode
	bpl	55$
	lda	#'O'
 55$
	jsr	PutTCPByte
	pla
	jmp	SndTermByte
 90$
	pla
	rts


EchoCharacter:
	sta	nxtChar
	jsr	TurnOffCursor
	jsr	SetTxtPos
	lda	nxtChar
	jsr	PutVTChar
	jsr	SaveTxtPos
	jmp	TurnOnPrompt

KeyLoop:
	lda	mouseOn
	and	#%01000000
	beq	10$
	rts
 10$
	lda	modKeyCopy
	cmp	#%00100000	;is the CTRL key being held?
	bne	40$
	lda	keyData
	cmp	#32
	bcc	30$
	cmp	#64
	bcc	50$
	cmp	#96
	bcs	50$
	sec
	sbc	#64
 30$
	jmp	SndTermByte	;send the CTRL key byte to the modem.
 40$
	lda	keyData
	cmp	#32
	bcc	70$
	cmp	#127
	bcs	70$
	jsr	SndTermByte
	cpx	#0
	bne	60$
	bit	localEcho
	bpl	50$
	lda	keyData
	jsr	EchoCharacter
 50$
	jsr	GetNextChar
	sta	keyData
	cmp	#0
	bne	10$
 60$
	rts
 70$
;fall through to next page...


;previous page continues here.
CkNonAsciiKeys:
	bit	modKeyCopy
	bvc	10$
	jsr	DoCMDRKeys
	bra	50$
 10$
	ldx	#0
 20$
	cmp	keyPTable,x
	beq	30$
	inx
	cpx	#[(keyTable-keyPTable)
	bcc	20$	;branch always.
	bcs	50$
 30$
	txa
	asl	a
	tax
;	jsr	(keyTable,x)
	.byte	$fc,[keyTable,]keyTable
 50$
	jsr	GetNextChar
	sta	keyData
	cmp	#0
	beq	60$
	jmp	KeyLoop
 60$
	rts

keyPTable:
	.byte	CR,KEY_ENTER,KEY_CLEAR,KEY_DELETE
	.byte	KEY_ESC,KEY_UP,KEY_DOWN,KEY_RIGHT,KEY_LEFT
	.byte	KEY_LARROW
keyTable:
	.word	SendCR,SendCR,DoPageBreak,SendDelete
	.word	SendESC,SendUp,SendDown,SendRight,SendLeft
	.word	SendESC



DoCMDRKeys:
	and	#%01111111
	ldx	#0
 10$
	cmp	cmdrKeyTable,x
	beq	50$
	inx
	cpx	#[(cmdrKeyRoutine-cmdrKeyTable)
	bcc	10$
	rts
 50$
	txa
	asl	a
	tax
;	jmp	(cmdrKeyRoutine,x)
	.byte	$7c,[cmdrKeyRoutine,]cmdrKeyRoutine,0

cmdrKeyTable:
	.byte	"xhe"
	.byte	"va"
.if	debug
	.byte	"ocb"
.endif
cmdrKeyRoutines:
	.word	SendBreak,HangUp,ToglEcho
	.word	ToglVT100,ToglANSI
.if	debug
	.word	OpenDebug,CloseDebug,RewindDebug

RewindDebug:
	LoadB	debugEnd+0,#0
	sta	debugEnd+1
	rts

.endif

ToglEcho:
	lda	localEcho
	eor	#%10000000
	sta	localEcho
	rts

.if	debug
OpenDebug:
	LoadB	cmdrOOpened,#%10000000
	LoadB	inModBuf+0,#0
	sta	inModBuf+1
	jsr	LInitDebug
	MoveW	r5,inModBuf
	MoveB	r6L,inModBank
	MoveW	appMain,appMain3Save
	LoadW	appMain,#StashModByte
	rts

StashModByte:
	MoveW	inModBuf,r5
	MoveB	inModBank,r6L
 10$
	jsr	GetFrmBuf
	bcc	20$
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	10$
	inc	r5H
	bne	10$
 20$
	MoveW	r5,inModBuf
	MoveB	r6L,inModBank
 90$
	rts

CloseDebug:
	MoveW	inModBuf,r5
	MoveB	inModBank,r6L
	LoadB	inModBuf+0,#0
	sta	inModBuf+1
	bit	cmdrOOpened
	bpl	50$
	MoveW	appMain3Save,appMain
 50$
	jmp	LWriteDebug

.endif

SendBreak:
	MoveW	breakTime,r0
	jsr	On16Timer
	jsr	OnBreak
 10$
	jsr	CkTimer
	bcc	10$
	jmp	OffBreak

breakTime:
	.word	8	;+++ this will get moved
			;+++ into a default area.

M_HangUp:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
HangUp:
	jsr	TurnOffCursor
	jsr	LSaveTxtScreen
	ldx	#3
	ldy	#1
	jsr	LURLBarMsg	;display "Disconnecting..."
	jsr	Disconnect
	jsr	LRstrTxtScreen
	jsr	DefSLSettings
	jsr	ResetFont
	jsr	RecolorPad
	jsr	FixMainLoop
	lda	waveRunning
	and	#%00100000
	bne	50$
	jmp	TurnOnPrompt
 50$
	jmp	QuitTerm

