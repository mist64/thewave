;************************************************************

;		BrowseA


;************************************************************



	.psect


smenu_top	= 0
smenu_left	= 0
smenu_bottom	= 15
.if	C64
smenu_width	= 152
.else
smenu_width	= 304
.endif
smcard_width	= smenu_width/8
smenu_right	= smenu_left+smenu_width-1

.if	C64
ssub1_left	= 0
ssub2_left	= 40
ssub3_left	= 56
ssub4_left	= 88
ssub1_width	= 64
ssub2_width	= 104
ssub3_width	= 104
ssub4_width	= 96
.else
ssub1_left	= 0
ssub2_left	= 64
ssub3_left	= 112
ssub4_left	= 168
ssub1_width	= 128
ssub2_width	= 160
ssub3_width	= 176
ssub4_width	= 160
.endif

ssub1_right	= ssub1_left+ssub1_width-1
ssub2_right	= ssub2_left+ssub2_width-1
ssub3_right	= ssub3_left+ssub3_width-1
ssub4_right	= ssub4_left+ssub4_width-1

ssub1_num	= 1
ssub2_num	= 4
ssub3_num	= 8
ssub4_num	= 5

ssub1_bottom	= smenu_bottom+1+(ssub1_num*14)+1
ssub2_bottom	= smenu_bottom+1+(ssub2_num*14)+7
ssub3_bottom	= smenu_bottom+1+(ssub3_num*14)+7
ssub4_bottom	= smenu_bottom+1+(ssub4_num*14)+1


BrwsJumpTable:
;StartBrowser:
	jmp	JStartBrowser
;ReStartBrowser:
	jmp	JReStartBrowser
;FetchFSegment:
	jmp	JFetchFSegment

JStartBrowser:
	lda	waveRunning
	and	#%11011111
	sta	waveRunning
	jsr	OffIcons
	jsr	MakeBrScreen
DoStartPage:
	jsr	RunStartup
	bcs	50$
	rts
 50$
	jmp	ShowPage

JReStartBrowser:
	jsr	OffIcons
	jsr	MakeBrScreen
RestartUser:
	jsr	RstBrwsVectors
ShowPage:
	jsr	JFetchFSegment
	LoadB	urlBufPtr,#0
	jsr	LDoURLBar
	jsr	StartSBar
	jsr	CkVsblAnchors
	cli
 50$
	bit	mouseData
	bpl	50$
	rep	%00100000
	lda	#[CkLinkClick
	.byte	]CkLinkClick
	sta	otherPressVec
	sta	brwsOthPress
	lda	#[BrowseKeys
	.byte	]BrowseKeys
	sta	keyVector
	sta	brwsKeyVector
	sep	%00100000
	lda	waveRunning
	and	#%11011111
	sta	waveRunning
	rts


OffIcons:
	lda	mouseOn
	and	#%10011111
	sta	mouseOn
.if	C64
	lda	#0
	sta	$003f	;turn off icons.
	sta	$0040
.else
	lda	#0
	sta	$0040	;turn off icons.
	sta	$0041
.endif
	rts


MakeBrScreen:
	jsr	UseSystemFont
	jsr	ClearScreen
	jsr	ClearTop
	jsr	ClearBTop
	jsr	ClearBWindow
.if	C64
	lda	sysBorder
.else
	lda	sys80Border
.endif
	jsr	SetBrdrColor
	LoadW	r0,#MainMenu
	lda	#0
	jsr	DoMenu
	jsr	DoBIcons
	lda	waveRunning	;indicate the browser is running.
	ora	#%11000000
	sta	waveRunning
	rts

DoBIcons:
	lda	#0
 10$
	pha
	jsr	LdIconRegs
	jsr	BitmapUp
	pla
	ina
	cmp	#[((endBITables-bIconTables)/8)
	bcc	10$
	rts

LdIconRegs:
	asl	a
	asl	a
	asl	a
	tay
	ldx	#0
 20$
	lda	bIconTables,y
	sta	r0,x
	iny
	inx
	cpx	#8
	bcc	20$
	rts

bIconTables:
backITable:
	.word	backIPic
.if	C64
	.byte	1,16,2,8
.else
	.byte	1|DOUBLE_B,16,2|DOUBLE_B,8
.endif
	.word	DoBackPage

forwITable:
	.word	forwIPic
.if	C64
	.byte	4,16,2,8
.else
	.byte	4|DOUBLE_B,16,2|DOUBLE_B,8
.endif
	.word	DoFwdPage

reLdITable:
	.word	reLdIPic
.if	C64
	.byte	7,16,2,8
.else
	.byte	7|DOUBLE_B,16,2|DOUBLE_B,8
.endif
	.word	DoReLdPage

startITable:
	.word	startIPic
.if	C64
	.byte	10,16,2,8
.else
	.byte	10|DOUBLE_B,16,2|DOUBLE_B,8
.endif
	.word	DoStartPage


urlLITable:
	.word	urlLIPic
.if	C64
	.byte	38,24,2,7
.else
	.byte	38|DOUBLE_B,24,2|DOUBLE_B,7
.endif
	.word	LDoURL2Left

urlHITable:
	.word	urlRIPic
.if	C64
	.byte	38,32,2,7
.else
	.byte	38|DOUBLE_B,32,2|DOUBLE_B,7
.endif
	.word	LDoURL2Right

histITable:
	.word	histIPic
.if	C64
	.byte	0,24,1,15
.else
	.byte	0|DOUBLE_B,24,1|DOUBLE_B,15
.endif
	.word	DoHistList

endBITables:

backIPic:


forwIPic:


reLdIPic:


startIPic:


urlLIPic:


urlRIPic:


histIPic:



M_ViewSource:
	lda	#%00000001
	.byte	44
M_RendrSource:
	lda	#%00000010
	.byte	44
M_ViewHeader:
	lda	#%00000011
	sta	dloadFlag
	jsr	GotoFirstMenu
	jmp	FS2

M_FontBigger:
	jsr	GotoFirstMenu
	lda	opmenu4Text
	cmp	#PLAINTEXT
	beq	10$
	rts
 10$
FontBigger:
	lda	baseFntSize
	cmp	#4
	bne	10$
	rts
 10$
	bcc	20$
	cmp	#254
	bcs	20$
	LoadB	baseFntSize,#255
 20$
	inc	baseFntSize
	jmp	FS2


M_FontSmaller:
	jsr	GotoFirstMenu
	lda	opmenu5Text
	cmp	#PLAINTEXT
	beq	10$
	rts
 10$
FontSmaller:
	lda	baseFntSize
	cmp	#254
	bne	10$
	rts
 10$
	bcs	20$
	cmp	#5
	bcc	20$
	LoadB	baseFntSize,#1
 20$
	dec	baseFntSize
FS2:
	jsr	ClearBWindow
	jsr	OpenPrgDir
	LoadB	keyVector+0,#0
	sta	keyVector+1
	ldx	watchMOffset
	jsr	RemvMnRoutine
	LoadB	watchMOffset,#0
	ldx	pageBank
	jsr	FreeNClear
	ldx	anchorBank
	jsr	FreeNClear
	ldx	linkBank
	jsr	FreeNClear
	MoveB	htmlBank,a1L
	jsr	LParseHTML
	LoadB	curPageTop+0,#0
	sta	curPageTop+1
	sta	curPageTop+2
	jsr	CalcCPBottom
	jmp	ShowPage


.if	C64
;table for the main menu.

MainMenu:
	.byte	smenu_top
	.byte	smenu_bottom
	.word	smenu_left
	.word	smenu_right
	.byte	4|HORIZONTAL

	.word	mmenu1Text
	.byte	DYN_SUB_MENU
	.word	SetSubMenu

	.word	mmenu2Text
	.byte	DYN_SUB_MENU
	.word	SetSubMenu

	.word	mmenu3Text
	.byte	DYN_SUB_MENU
	.word	SetSubMenu

	.word	mmenu4Text
	.byte	DYN_SUB_MENU
	.word	SetSubMenu

mmenu1Text:
	.byte	"wheels",0
mmenu2Text:
	.byte	"file",0
mmenu3Text:
	.byte	"open",0
mmenu4Text:
	.byte	"options",0


.else
MainMenu:
	.byte	smenu_top
	.byte	smenu_bottom
	.word	smenu_left
	.word	smenu_right
	.byte	4|HORIZONTAL

	.word	m80menu1Text
	.byte	DYN_SUB_MENU
	.word	SetSubMenu

	.word	m80menu2Text
	.byte	DYN_SUB_MENU
	.word	SetSubMenu

	.word	m80menu3Text
	.byte	DYN_SUB_MENU
	.word	SetSubMenu

	.word	m80menu4Text
	.byte	DYN_SUB_MENU
	.word	SetSubMenu

m80menu1Text:
	.byte	BOLDON," wheels ",0
m80menu2Text:
	.byte	BOLDON," file ",0
m80menu3Text:
	.byte	BOLDON," open ",0
m80menu4Text:
	.byte	BOLDON," options ",0

.endif

SetSubMenu:
	pha
	jsr	StopURLEditor
	plx
	lda	#ITALICON
	sta	opmenu2Text+0
	sta	opmenu3Text+0
	sta	opmenu4Text+0
	sta	opmenu5Text+0
	lda	#0
	sta	opmenu4Text+13
	sta	opmenu5Text+14
	lda	baseFntSize
	cmp	#4
	beq	10$
	ina
	bpl	5$
	lda	#'1'
	sta	opmenu4Text+16
	lda	#'-'
	bne	6$
 5$
	clc
	adc	#'0'
	sta	opmenu4Text+16
	lda	#'+'
 6$
	sta	opmenu4Text+15
	lda	#' '
	sta	opmenu4Text+13
	lda	#PLAINTEXT
	sta	opmenu4Text+0
 10$
	lda	baseFntSize
	cmp	#254
	beq	40$
	dea
	bpl	20$
	eor	#%11111111
	clc
	adc	#'1'
	sta	opmenu5Text+17
	lda	#'-'
	bne	30$
 20$
	clc
	adc	#'0'
	sta	opmenu5Text+17
	lda	#'+'
 30$
	sta	opmenu5Text+16
	lda	#' '
	sta	opmenu5Text+14
	lda	#PLAINTEXT
	sta	opmenu5Text+0
 40$
	bit	commMode
	bmi	50$
	lda	#PLAINTEXT
	sta	opmenu2Text+0
	sta	opmenu3Text+0
 50$
	lda	subLTable,x
	sta	r0L
	lda	subHTable,x
	sta	r0H
	ldy	#5
 70$
	lda	(r0),y
	sta	r2,y
	dey
	bpl	70$
	PushW	r0
	jsr	ImprintRectangle
	jsr	ConvToCards
	jsr	SetSaveColor
	jsr	SaveColor
	MoveB	menuColor,r4H
	jsr	ColorRectangle
	PopW	r0
	rts

subLTable:
	.byte	[WheelsMenu,[FileMenu
	.byte	[OpenMenu,[OptionsMenu
subHTable:
	.byte	]WheelsMenu,]FileMenu
	.byte	]OpenMenu,]OptionsMenu

WheelsMenu:
	.byte	smenu_bottom+1
	.byte	ssub1_bottom
	.word	ssub1_left
	.word	ssub1_right
	.byte	ssub1_num|VERTICAL

	.word	wmenu1Text
	.byte	MENU_ACTION
	.word	M_ExitWave

wmenu1Text:
	.byte	"quit",0


FileMenu:
	.byte	smenu_bottom+1
	.byte	ssub2_bottom
	.word	ssub2_left
	.word	ssub2_right
	.byte	ssub2_num|VERTICAL

	.word	fmenu1Text
	.byte	MENU_ACTION
	.word	M_SvSource

	.word	fmenu2Text
	.byte	MENU_ACTION
	.word	M_ViewSource

	.word	fmenu3Text
	.byte	MENU_ACTION
	.word	M_RendrSource

	.word	fmenu4Text
	.byte	MENU_ACTION
	.word	M_ViewHeader

fmenu1Text:
	.byte	"save source",0
fmenu2Text:
	.byte	"view source",0
fmenu3Text:
	.byte	"render source",0
fmenu4Text:
	.byte	"view header",0

OpenMenu:
	.byte	smenu_bottom+1
	.byte	ssub3_bottom
	.word	ssub3_left
	.word	ssub3_right
	.byte	ssub3_num|VERTICAL

	.word	omenu1Text
	.byte	MENU_ACTION
	.word	M_ISPDir

	.word	omenu2Text
	.byte	MENU_ACTION
	.word	M_DoAsciiTerm

	.word	omenu3Text
	.byte	MENU_ACTION
	.word	GotoFirstMenu

	.word	omenu4Text
	.byte	MENU_ACTION
	.word	GotoFirstMenu

	.word	omenu5Text
	.byte	MENU_ACTION
	.word	GotoFirstMenu

	.word	omenu6Text
	.byte	MENU_ACTION
	.word	MGetAnyFile

	.word	omenu7Text
	.byte	MENU_ACTION
	.word	M_RunApp

	.word	omenu8Text
	.byte	MENU_ACTION
	.word	M_RunDA

omenu1Text:
	.byte	"ISP directory",0
omenu2Text:
	.byte	"new terminal",0
omenu3Text:
	.byte	ITALICON,"existing terminal",PLAINTEXT,0
omenu4Text:
	.byte	ITALICON,"new browser",PLAINTEXT,0
omenu5Text:
	.byte	ITALICON,"existing browser",PLAINTEXT,0
omenu6Text:
	.byte	"view local file",0
omenu7Text:
	.byte	"application",0
omenu8Text:
	.byte	"desk accessory",0

OptionsMenu:
	.byte	smenu_bottom+1
	.byte	ssub4_bottom
	.word	ssub4_left
	.word	ssub4_right
	.byte	ssub4_num|VERTICAL

	.word	opmenu1Text
	.byte	MENU_ACTION
	.word	M_HangUp

	.word	opmenu2Text
	.byte	MENU_ACTION
	.word	M_SLAddress

	.word	opmenu3Text
	.byte	MENU_ACTION
	.word	M_MdmSettings

	.word	opmenu4Text
	.byte	MENU_ACTION
	.word	M_FontBigger

	.word	opmenu5Text
	.byte	MENU_ACTION
	.word	M_FontSmaller

opmenu1Text:
	.byte	"hang up",0
opmenu2Text:
	.byte	PLAINTEXT,"interface address",PLAINTEXT,0
opmenu3Text:
	.byte	PLAINTEXT,"modem settings",PLAINTEXT,0
opmenu4Text:
	.byte	PLAINTEXT,"font bigger",PLAINTEXT," (+1)",0
opmenu5Text:
	.byte	PLAINTEXT,"font smaller",PLAINTEXT," (-1)",0

M_HangUp:
	jsr	GotoFirstMenu
	ldx	#3
	ldy	#1
	jsr	LURLBarMsg	;display "Disconnecting..."
	jsr	Disconnect
	jsr	DefSLSettings
	jmp	LDoURLBar


M_MdmSettings:
	jsr	GotoFirstMenu
	bit	commMode
	bpl	10$
	rts
 10$
	ldx	#1
	jsr	DoSelBox
	ldx	#3
 20$
	lda	desBaudRate,x
	sta	defBaudRate,x
	dex
	bpl	20$
	jsr	OpenModem
	ldx	defBaudRate
	beq	50$
	jsr	SetBPS
	ldx	bpsRate
	stx	defBaudRate
 50$
	stx	desBaudRate
	jmp	SvDefaults

M_SLAddress:
	jsr	GotoFirstMenu
	bit	commMode
	bpl	10$
	rts
 10$
	ldx	#2
	jsr	DoSelBox
	jmp	SvDefaults
