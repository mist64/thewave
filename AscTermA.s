;**********************************

;	AscTermA


;**********************************


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
ssub2_left	= 32
ssub3_left	= 64
ssub4_left	= 88
ssub1_width	= 64
ssub2_width	= 104
ssub3_width	= 80
ssub4_width	= 96
.else
ssub1_left	= 0
ssub2_left	= 64
ssub3_left	= 128
ssub4_left	= 176
ssub1_width	= 128
ssub2_width	= 208
ssub3_width	= 160
ssub4_width	= 192
.endif

ssub1_right	= ssub1_left+ssub1_width-1
ssub2_right	= ssub2_left+ssub2_width-1
ssub3_right	= ssub3_left+ssub3_width-1
ssub4_right	= ssub4_left+ssub4_width-1

ssub1_num	= 1
ssub2_num	= 7
ssub3_num	= 2
ssub4_num	= 4

ssub1_bottom	= smenu_bottom+1+(ssub1_num*14)+1
ssub2_bottom	= smenu_bottom+1+(ssub2_num*14)+5
ssub3_bottom	= smenu_bottom+1+(ssub3_num*14)+3
ssub4_bottom	= smenu_bottom+1+(ssub4_num*14)+7


TermStart:
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
	sta	currentMode
	LoadB	dispBufferOn,#ST_WR_FORE

	rep	%00110000
	pla
	sta	mainTReturn
	tsx
	stx	mainTStack
	lda	#[(MainLoop-1)
	.byte	](MainLoop-1)
	pha
	sep	%00110000

	jsr	FullMargins
.if	C64
	jsr	SaveMsePointer
.endif
	jsr	TermScreen
;fall through to next page...

;previous page falls through to here.
RST2:
	PushB	baseFntSize
	LoadB	baseFntSize,#0
	jsr	OpenPrgDir
	lda	#4
	jsr	GetTrmSet
	bcc	45$
	lda	#3
	jsr	GetTrmSet
	bcc	45$
	lda	#2
	jsr	GetTrmSet
	bcc	45$
	lda	#1
	jsr	GetTrmSet
	bcs	50$
 45$
	PopB	baseFntSize
;+++display an error message here.
	jmp	QuitTerm
 50$
	PopB	baseFntSize
	jsr	InitTxtWindow
	jsr	ResetFont
	jsr	SaveVTAttributes
	LoadB	crsrRunning,#0
	sta	keyPadMode


;fall through to next page...

;previous page continues here.
RST3:
	jsr	LRstTermScreen
	jsr	TurnOnPrompt
	LoadW	keyVector,#KeyLoop
	LoadW	StringFaultVec,#WrapTxtLine
	ldx	dispInOffset
	LoadW	r0,#DispInChars
	jsr	AddMnRoutine	;watch for incoming bytes.
	stx	dispInOffset
	ldx	ckOnTOffset
	LoadW	r0,#CkOnTMenu
	jsr	AddMnRoutine	;watch for mouse at top of screen.
	stx	ckOnTOffset
	lda	waveRunning
	and	#%01111111
	ora	#%01000000
	sta	waveRunning	;indicate the terminal is running.
	and	#%00100000	;does the browser want a manual login?
	beq	80$	;branch if not.
	jmp	IS2	;go set up a manual login.
 80$
	rts

trmFontName:
	.byte	"terminal",0



FixMainReturn:
	rep	%00100000
	pla
	ina
	sta	FMR+1
	lda	mainTStack
;	tcs
	.byte	$1b
	lda	mainTReturn
	pha
	sep	%00100000
FMR:
	jmp	$1000	;this changes.

FixMainLoop:
	rep	%00100000
	pla
	ina
	sta	FML+1
	lda	mainTStack
;	tcs
	.byte	$1b
	lda	#[(MainLoop-1)
	.byte	](MainLoop-1)
	pha
	sep	%00100000
FML:
	jmp	$1000	;this changes.


ResetFont:
	LoadB	charSetUsed,#%10000000
	LoadW	r0,#fontBase
	jsr	LoadCharSet
	jmp	SetRegSet


GetTrmSet:
	pha
	LoadW	r0,#trmFontName
;	phk
	.byte	$4b
	PopB	r1L
	pla
	pha
	jsr	LGetDesFont
	bcc	45$
.if	C64
	lda	r7L
	cmp	#[(fontBase+586)
	bne	45$
	lda	r7H
	cmp	#](fontBase+586)
.else
	lda	r7L
	cmp	#[(fontBase+970)
	bne	45$
	lda	r7H
	cmp	#](fontBase+970)
.endif
	beq	50$
 45$
	pla
	clc
	rts
 50$
	plx
	dex
	beq	80$
	dex
	lda	trmFntLTable,x
	sta	r1L
	lda	trmFntHTable,x
	sta	r1H
	LoadW	r0,#fontBase
	LoadW	r2,#$0400
	jsr	MoveData
 80$
	sec
	rts

trmFntLTable:
	.byte	[ansiBuffer,[vtExtraBuffer
	.byte	[buf8859
trmFntHTable:
	.byte	]ansiBuffer,]vtExtraBuffer
	.byte	]buf8859

.if	C64
fntLSzs:
	.byte	[(fontBase+602),[(fontBase+602),[(fontBase+498)
fntHSzs:
	.byte	](fontBase+602),](fontBase+602),](fontBase+498)
.endif

CkOnTMenu:
	lda	mouseYPos
	beq	10$
	rts
 10$
	jsr	TurnOffCursor
	MoveW	appMain,tmAppMain
	LoadW	appMain,#CkOffTMenu
	jsr	LSaveTxtScreen
	jsr	ClearTop
	php
	sei
	PushB	mouseYPos
	PushW	mouseXPos
	LoadW	r0,#MainMenu
	lda	#0
	jsr	DoMenu
	PopW	mouseXPos
	pla
	beq	30$
	dea
 30$
	sta	mouseYPos
	plp
	rts

CkOffTMenu:
	lda	menuNumber
	bne	5$
	lda	mouseYPos
	cmp	#16
	bcs	10$
 5$
	rts
 10$
OffTMenu:
	LoadW	appMain,#AppOffMenu
	rts


AppOffMenu:
	lda	mouseOn
	and	#%10111111
	sta	mouseOn
	MoveW	tmAppMain,appMain
	jmp	LRstrTxtScreen


RecolorPad:
	jsr	SetWinRegs
	jmp	CP2

TermBorder:
.if	C64
	lda	sysBorder
.else
	lda	sys80Border
.endif
	bit	vtOn
	bpl	50$
	bit	ansiOn
	bpl	50$
	ldx	ansiBGColor
.if	C64
	lda	ansiBGTable,x
.else
	lda	back80Table,x
.endif
 50$
	jmp	SetBrdrColor

TermScreen:
	jsr	HideScreen
;fall through...
ClearPad:
	jsr	ErasePad
CP2:
	LoadB	ansiFGColor,#7
	LoadB	ansiBGColor,#0
	sta	ansiBold
	jsr	ConvToCards
	bit	vtOn
	bpl	20$
	bit	ansiOn
	bpl	20$
	ldx	ansiFGColor
	lda	ansiFGTable,x
	ldx	ansiBGColor
	ora	ansiBGTable,x
	sta	r4H
	jsr	ColorRectangle
.if	C64
	jsr	TermBorder
	jmp	FixMseColor
.else
	jmp	TermBorder
.endif
 20$
	jsr	SysScrColor
	jsr	ColorRectangle
.if	C64
	jsr	TermBorder
	jmp	FixMseColor
.else
	jmp	TermBorder
.endif


ErasePad:
	jsr	SetWinRegs
	lda	#0
	jsr	SetPattern
	jmp	Rectangle

SetWinRegs:
	LoadB	r2L,#TOP_LINE
	LoadB	r2H,#BOT_LINE+TLINEHEIGHT-1
SetLftRght:
	LoadB	r3L,#0
	sta	r3H
SetRight:
.if	C64
	LoadW	r4,#319
.else
	LoadW	r4,#639
.endif
	rts

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
	.byte	"open",0
mmenu3Text:
	.byte	"transfer",0
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
	.byte	BOLDON," open ",0
m80menu3Text:
	.byte	BOLDON," transfer ",0
m80menu4Text:
	.byte	BOLDON," options ",0

.endif

SetSubMenu:
	pha
	jsr	TurnOffCursor
	plx
	lda	#PLAINTEXT
	bit	commMode
	bpl	10$
	lda	#ITALICON
 10$
	sta	opmenu2Text+0
	sta	opmenu3Text+0
	lda	subHTable,x
	sta	r0H
	pha
	lda	subLTable,x
	sta	r0L
	pha
	ldy	#5
 50$
	lda	(r0),y
	sta	r2,y
	dey
	bpl	50$
	jsr	ImprintRectangle
	jsr	ConvToCards
	jsr	TSetSaveColor
	jsr	SaveColor
	MoveB	menuColor,r4H
	jsr	ColorRectangle
	PopW	r0
	rts


TRaiseMenu:
	jsr	RecoverRectangle
	jsr	ConvToCards
	jsr	TSetRstrColor
	jsr	RstrColor
	lda	mouseYPos
	cmp	#16
	bcs	50$
	rts
 50$
	jsr	OffTMenu
	jmp	TurnOnPrompt

TSetSaveColor:
	LoadW	r0,#mColor
	MoveW	RecoverVector,trcvrSave
	LoadW	RecoverVector,#TRaiseMenu
	rts

TSetRstrColor:
	LoadW	r0,#mColor
	MoveW	trcvrSave,RecoverVector
	rts

trcvrSave:
	.block	2

subLTable:
	.byte	[WheelsMenu,[OpenMenu
	.byte	[TransMenu,[OptionsMenu
subHTable:
	.byte	]WheelsMenu,]OpenMenu
	.byte	]TransMenu,]OptionsMenu

WheelsMenu:
	.byte	smenu_bottom+1
	.byte	ssub1_bottom
	.word	ssub1_left
	.word	ssub1_right
	.byte	ssub1_num|VERTICAL

	.word	wmenu1Text
	.byte	MENU_ACTION
	.word	M_QuitTerm

wmenu1Text:
	.byte	"exit",0


OpenMenu:
	.byte	smenu_bottom+1
	.byte	ssub2_bottom
	.word	ssub2_left
	.word	ssub2_right
	.byte	ssub2_num|VERTICAL

	.word	omenu1Text
	.byte	MENU_ACTION
	.word	M_BBSDir

	.word	omenu2Text
	.byte	MENU_ACTION
	.word	M_ISPDir

	.word	omenu3Text
	.byte	MENU_ACTION
	.word	M_InetSession

	.word	omenu4Text
	.byte	MENU_ACTION
	.word	GotoFirstMenu

	.word	omenu5Text
	.byte	MENU_ACTION
	.word	GotoFirstMenu

	.word	omenu6Text
	.byte	MENU_ACTION
	.word	GotoFirstMenu

	.word	omenu7Text
	.byte	MENU_ACTION
	.word	GotoFirstMenu

omenu1Text:
	.byte	"SHELL/BBS directory",0
omenu2Text:
	.byte	"PPP directory",0
omenu3Text:
	.byte	"Internet session",0
omenu4Text:
	.byte	ITALICON,"new terminal",PLAINTEXT,0
omenu5Text:
	.byte	ITALICON,"existing terminal",PLAINTEXT,0
omenu6Text:
	.byte	ITALICON,"new browser",PLAINTEXT,0
omenu7Text:
	.byte	ITALICON,"existing browser",PLAINTEXT,0


TransMenu:
	.byte	smenu_bottom+1
	.byte	ssub3_bottom
	.word	ssub3_left
	.word	ssub3_right
	.byte	ssub3_num|VERTICAL

	.word	smenu1Text
	.byte	MENU_ACTION
	.word	M_SendFile
	.word	smenu2Text
	.byte	MENU_ACTION
	.word	M_RecvFile

smenu1Text:
	.byte	"send file",0
smenu2Text:
	.byte	"receive file",0

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
	.word	M_DoTrmMode

opmenu1Text:
	.byte	"hang up",0
opmenu2Text:
	.byte	PLAINTEXT,"interface address",PLAINTEXT,0
opmenu3Text:
	.byte	PLAINTEXT,"modem settings",PLAINTEXT,0
opmenu4Text:
	.byte	"terminal options",0


M_QuitTerm:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
QuitTerm:
	jsr	TurnOffCursor
	jsr	LSaveTxtScreen
	lda	waveRunning
	and	#%10111111
	sta	waveRunning	;indicate a transition is taking place.
	LoadB	currentMode,#0
	jsr	UseSystemFont
	jsr	ClearScreen
	jsr	ConvToCards
	jsr	SysScrColor
	jsr	ColorRectangle
.if	C64
	ldx	sysMob0Clr
	jsr	FMC2
	jsr	RstrMouse
	lda	sysBorder
.else
	lda	sys80Border
.endif
	jsr	SetBrdrColor
	jsr	OffInputs
	lda	mouseOn
	and	#[~(1 << MENUON_BIT)
	sta	mouseOn	;turn menus off
	jsr	FixMainReturn
	jmp	ReDoBrowser


OffInputs:
	php
	sei
	jsr	TurnOffCursor
	LoadB	keyVector+0,#0
	sta	keyVector+1
	sta	otherPressVec+0
	sta	otherPressVec+1
	sta	StringFaultVec+0
	sta	StringFaultVec+1
	ldx	dispInOffset
	jsr	RemvMnRoutine	;remove DispInChars from appMain.
	LoadB	dispInOffset,#0
	ldx	ckOnTOffset
	jsr	RemvMnRoutine	;remove CkOnTMenu from appMain.
	LoadB	ckOnTOffset,#0
	ldx	flushOffset
	jsr	RemvMnRoutine
	LoadB	flushOffset,#0
	sta	flushRunning
	plp
	rts

M_BBSDir:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
	jsr	TurnOffCursor
	jsr	ResetFont
	jsr	BBSDir
	php
	jsr	ResetFont
	plp
	bcc	50$
	jsr	DoPageBreak
 50$
	jsr	DefSLSettings
	jsr	RecolorPad
	jmp	TurnOnPrompt

M_ISPDir:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
	jsr	TurnOffCursor
	jsr	MouseOff
	LoadB	GetTermByte+0,#$2c
	LoadB	GetTermByte+1,#[commMode
	LoadB	GetTermByte+2,#]commMode
	LoadB	hostName+0,#0
	jsr	ResetFont
	jsr	ISPDir
	php
	jsr	ResetFont
	plp
	bcc	90$
	jmp	IS2
 90$
	jsr	DefSLSettings
	jsr	RecolorPad
	jsr	MouseUp
	jmp	TurnOnPrompt


M_InetSession:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
IS1:
	jsr	TurnOffCursor
	jsr	MouseOff
	LoadB	GetTermByte+0,#$2c
	LoadB	GetTermByte+1,#[commMode
	LoadB	GetTermByte+2,#]commMode
	LoadB	hostName+0,#0
	jsr	InetSession
	bcs	IS2
	jsr	ResetFont
	jsr	RecolorPad
	jsr	MouseUp
	jmp	TurnOnPrompt
IS2:
	bit	commMode
	bmi	50$
	bit	manualLogin
	bpl	IS1
	lda	vtOn
	ora	#%01111111
	sta	curVtOn
	and	#%01111111
	sta	vtOn
	jsr	ResetFont
	jsr	DoPageBreak
	jsr	RecolorPad
	LoadB	GetTermByte+0,#$4c
	LoadB	GetTermByte+1,#[WatchPPP
	LoadB	GetTermByte+2,#]WatchPPP
	jsr	MouseUp
	jmp	TurnOnPrompt
 50$
	jsr	StartTelnet
	bcc	IS1
	jsr	ResetFont
	jsr	DoPageBreak
	jsr	MouseUp
	jmp	TurnOnPrompt

StartTelnet:
	jsr	LInitTNVars
	jsr	LSaveTxtScreen
	lda	hostName+0
	beq	90$
	ldx	#0
	jsr	LURLBarMsg
	LoadW	r0,#hostName
	LoadB	r1L,#0
	jsr	LReslvAddress
	bcc	90$
	PushW	r0
	PushB	r1L
	ldx	#1
	jsr	LURLBarMsg
	PopB	r1L
	PopW	r0
	LoadW	r2,#$0100	;indicate a telnet session.
	LoadW	r3,#23	;destination telnet port.
	jsr	LOpnTCPConnection
	php
	jsr	LRstrTxtScreen
	jsr	ResetFont
	plp
	rts
 90$
	jsr	LRstrTxtScreen
	jsr	ResetFont
	clc
	rts


M_SendFile:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
	jsr	TurnOffCursor
	jsr	XModSend
	jsr	ResetFont
	jmp	TurnOnPrompt

M_RecvFile:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
	jsr	TurnOffCursor
	jsr	XModRecv
	jsr	ResetFont
TurnOnPrompt:
.if	C64
	lda	#7
.else
	lda	#8
.endif
	jsr	InitTextPrompt
	jmp	TurnOnCursor

M_DoTrmMode:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
	jsr	TurnOffCursor
	jsr	GetVTANSComb
	sta	chgTestFlag
	jsr	DoTrmMode
	php
	jsr	ResetFont
	plp
	bcs	50$
	jmp	TurnOnPrompt
 50$
	jsr	GetVTANSComb
	cmp	chgTestFlag
	beq	60$
	jsr	RecolorPad
 60$
	jmp	TurnOnPrompt

GetVTANSComb:
	lda	vtOn
	asl	a
	lda	ansiOn
	rol	a
	rol	a
	and	#%00000011
	rts

chgTestFlag:
	.block	1


M_SLAddress:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
	bit	commMode
	bmi	90$
	jsr	TurnOffCursor
	ldx	#2
	jsr	DoSelBox
	jsr	SvDefaults
 90$
	jsr	ResetFont
	jmp	TurnOnPrompt

M_MdmSettings:
	jsr	GotoFirstMenu
	jsr	AppOffMenu
	bit	commMode
	bmi	90$
	jsr	TurnOffCursor
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
	jsr	SvDefaults
 90$
	jsr	ResetFont
	jmp	TurnOnPrompt

