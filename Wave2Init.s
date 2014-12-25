;************************************************************

;		Wave2Init


;************************************************************

slBase=a5

	.psect


reLdFlag:
	.block	1

RunMain:
	lda	#1
	jsr	GetModule
	LoadW	appMain,#AppMainRoutine
.if	C128
	jsr	SwIf80
	bcs	40$
	jmp	JExitWave
 40$
	lda	#2
	jsr	SetColorMode
	jsr	HideScreen
.endif
	bit	reLdFlag
	bpl	50$
	jsr	OpenModem
	jmp	ReDoBrowser
 50$
	jsr	DefSLSettings
	ldx	defBaudRate
	bne	60$
	jsr	AutoBaud
	MoveB	bpsRate,globalBPSRate
	bra	70$
 60$
	jsr	SetBPS
	MoveB	bpsRate,desBaudRate
 70$
	jmp	DoBrowser

IsCurDesktop:
	jsr	PntDTName
	LoadW	r1,#prgName
	ldx	#r0
	ldy	#r1
	jsr	CmpString
	beq	5$
	lda	#%00000000
	sta	reLdFlag
	rts
 5$
	lda	#%11111111
	sta	reLdFlag
	rts

JStartWave:
	jsr	ClrRamsect
	jsr	CkVersion
	jsr	SetPrgName
	jsr	IsCurDesktop
	bmi	20$
	jsr	Ck4SysFile
	ldx	#0
	jsr	JSetNewDir
	ldx	#5
 10$
	lda	prgDrive
	sta	prgDrive,x
	lda	prgPart
	sta	prgPart,x
	lda	prgTrack
	sta	prgTrack,x
	lda	prgSector
	sta	prgSector,x
	dex
	bne	10$
 20$
	jsr	PutDesktop
	jsr	JOpenCurDir
	jsr	JOpenPrgDir
	bit	reLdFlag
	bmi	30$
	jsr	BldFontTables
	jsr	LdAllModules
 30$
	jsr	JSaveSRamVars
	jmp	RunMain


LdAllModules:
	jsr	JOpnPrgFile
	jsr	LdSLCode
	LoadW	a0,#ExtTable
	MoveB	prgBank,a1L
	lda	#5
	jsr	LdModRoutines
	MoveW	a0,modRmTable
	LoadB	a0H,#1
 10$
	jsr	GetAMod
	rep	%00100000
	ldx	a0L
	sec
	lda	r7
	sbc	r0
	sta	r2
	clc
	lda	modRmTable-2,x
	sta	r1
	adc	r2
	sta	modRmTable+0,x
	sep	%00100000
	LoadB	r3L,#0
	MoveB	prgBank,r3H
	jsr	JDoSuperMove
	inc	a0H
	lda	a0H
	cmp	#4
	bcc	10$
	jsr	JOpnSysFile
	LoadW	a0,#LPrgBase
	MoveB	prg2Bank,a1L
	lda	#1
	jsr	LdModRoutines
	LoadW	a0,#DOSBase
	lda	#2
	jsr	LdModRoutines
	LoadW	a0,#ParseHTML
	lda	#3

;fall through to next page...

;previous page falls through to here.
LdModRoutines:
	asl	a
	tax
	lda	fileHeader+2,x
	sta	r1L
	lda	fileHeader+3,x
	sta	r1H
	LoadB	r5L,#0
	sta	r5H
	LoadW	r4,#diskBlkBuf
 20$
	jsr	ReadByte
	cpx	#0
	bne	90$
;	sta	[a0]
	.byte	$87,a0
	inc	a0L
	bne	20$
	inc	a0H
	bne	20$
 90$
	rts

GetAMod:
	asl	a
	tax
	stx	a0L
	LoadB	r7L,#[ModBase
	sta	r0L
	LoadB	r7H,#]ModBase
	sta	r0H
	LoadW	r2,#$4000
	lda	fileHeader+2,x
	sta	r1L
	lda	fileHeader+3,x
	sta	r1H
	jmp	ReadFile


LdSLCode:
	LoadW	r7,#COMM_BASE
	LoadW	r2,#COMM_SIZE
	MoveB	fileHeader+2+12,r1L
	MoveB	fileHeader+2+13,r1H
	jsr	ReadFile
	txa
	beq	30$
	LoadW	r0,#COMM_BASE
	ldy	#0
 10$
	ldx	#0
 20$
	lda	subCommCode,x
	sta	(r0),y
	inx
	iny
	cpx	#3
	bcc	20$
	cpy	#(COMMJMPSIZE*3)
	bcc	10$
 30$
.if	C128
	jsr	MoveNMICode
.endif
	MoveB	defSLAddress+0,a5L
	MoveB	defSLAddress+1,a5H
	ora	a5L
	beq	80$
	jmp	IsSLThere
 80$
	jmp	InitComm

;this code gets substituted in place of the SL driver
;if the driver is not found on disk. It gets put into
;each jump table entry. This prevents a big crash.
subCommCode:
	ldx	#128
	rts


CkVersion:
	lda	driverVersion
	cmp	#$52
	bcc	95$
	lda	version
	cmp	#$41
	bcc	95$
	cmp	#$43	;is a newer kernal or the newer Toolbox installed?
	bcs	80$	;branch if so.
	lda	ramExpType
	cmp	#4	;is SuperRAM chosen as the ram device?
	beq	90$	;branch if so.
 80$
	rts
 90$
	jmp	BadToolbox
 95$
BadHardware:
	LoadW	r0,#badVersBox
	jsr	DoDlgBox
	jmp	EnterDesktop

BadToolbox:
	LoadW	r0,#toolBoxDB
	jsr	DoDlgBox
	jmp	EnterDesktop


TwoWaveFound:
	LoadW	r0,#twoWaveBox
	jsr	DoDlgBox
	jmp	JExitWave

twoWaveBox:
	.byte	DEF_DB_POS

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_1_Y
	.word	two1Text
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	two2Text
	.byte	OK,DBI_X_2,DBI_Y_2

	.byte	0

two1Text:
.if	C64
	.byte	"Two different Wave64 versions found.",0
.else
	.byte	"Two different Wave128 versions found.",0
.endif

two2Text:
	.byte	"The Wave will now exit.",0


Ck4SysFile:
	LoadW	noSysLoc,#noSysText
	LoadW	r6,#sysName
	jsr	FindFile
	txa
	bne	90$
	LoadW	r9,#dirEntryBuf
	jsr	GetFHdrInfo
	txa
	bne	89$
	LoadW	r0,#prmSysName
	LoadW	r1,#fileHeader+77
	ldx	#r0
	ldy	#r1
	jsr	CmpString
	bne	89$
	rts
 89$
	LoadW	noSysLoc,#badSysText
 90$
	LoadW	r0,#noSysDB
	jsr	DoDlgBox
	bit	reLdFlag
	bmi	95$
	jmp	EnterDesktop
 95$
	jmp	JExitWave

prmSysName:
.if	C64
	.byte	"WaveSys64   "
.else
	.byte	"WaveSys128  "
.endif
	.byte	VERSLETTER,VERSMAJOR,".",VERSMINOR,0

toolBoxDB:
	.byte	DEF_DB_POS

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_1_Y
	.word	tb1Text
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	tb2Text
	.byte	OK,DBI_X_2,DBI_Y_2

	.byte	0

tb1Text:
.if	C64
	.byte	"You must install Toolbox 64 V5.3",0
.else
	.byte	"You must install Toolbox 128 V5.3",0
.endif
tb2Text:
	.byte	"or higher to use The Wave.",0

badVersBox:
	.byte	DEF_DB_POS

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_1_Y
	.word	vers1Text
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	vers2Text
	.byte	OK,DBI_X_2,DBI_Y_2

	.byte	0

vers1Text:
	.byte	"The Wave requires Wheels V4.2 or",0
vers2Text:
	.byte	"higher, plus a SuperCPU with SuperRAM.",0

noSysDB:
	.byte	DEF_DB_POS

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
noSysLoc:
	.word	noSysText
	.byte	OK,DBI_X_2,DBI_Y_2

	.byte	0

noSysText:
.if	C64
	.byte	"System64 file not found",0
.else
	.byte	"System128 file not found",0
.endif
badSysText:
.if	C64
	.byte	"Wrong System64 file",0
.else
	.byte	"Wrong System128 file",0
.endif


ClrRamsect:
	LoadW	r0,#(endOfRamsect-sramVars)
	LoadW	r1,#sramVars
	jmp	ClearRam

SetPrgName:
	jsr	SPN2
	beq	SPN3
 10$
	lda	dtDrive
	jsr	SetDevice
	ldx	dtPartition
	jsr	JGoXPartition
	jsr	OpenRoot
	jsr	SPN2
	beq	SPN3
	jmp	NoWave
SPN2:
	LoadW	r6,#prgName
	LoadB	r7L,#APPLICATION
	LoadB	r7H,#1
	LoadW	r10,#permName
	jsr	FindFTypes
	lda	r7H
SPN3:
	rts

permName:
.if	C64
	.byte	"WaveTerm64  "
.else
	.byte	"WaveTerm128 "
.endif
	.byte	VERSLETTER,VERSMAJOR,".",VERSMINOR,0

;+++have this ask the user to insert
;+++a disk containing The Wave.
NoWave:
	rts


PutDesktop:
	bit	reLdFlag
	bpl	10$
	jsr	SetNativeMode
	jsr	GetSTBank
	MoveB	stBank,prgBank
	jsr	JFtchSRamVars
	ldx	#3
 3$
	lda	sysFileVersion,x
	cmp	prmSysName+12,x
	beq	5$
	jmp	TwoWaveFound
 5$
	dex
	bpl	3$
	MoveW	slAddress,slBase
	MoveB	bufBank,recvBank
	sta	getBank
	MoveB	prgBank,prg1+2
	MoveB	prg2Bank,rcvTCPBank
	sta	sndTCPBank
	sta	prg2+2
	rts
 10$
	lda	numDesktops
	cmp	#16	;number of desktops chained maxed out?
	bcc	20$
	jmp	EnterDesktop	;+++maybe show an error msg here.
 20$
	jsr	DoSuperCk
	bne	30$
	jmp	BadHardware
 30$
	jsr	SetNativeMode
	jsr	ValBankBAM
	jsr	AllocBanks
	LoadB	recvLocation+0,#0
	sta	recvLocation+1
	sta	getLocation+0
	sta	getLocation+1
	jsr	PntDTName
	LoadW	r1,#deskName
	LoadW	r2,#12
	jsr	MoveData
	MoveB	stBank,deskName+12
	MoveB	dtDrive,deskName+13
	MoveB	dtPartition,deskName+14
	MoveB	dtType,deskName+15
	jsr	StashDTName
	LoadW	r0,#prgName
	lda	#10
	jsr	GetNewKernal
	MoveB	curDrive,dtDrive
	jsr	GetHeadTS
	MoveB	r2L,dtPartition
	MoveB	curType,dtType
	ldx	#3
 50$
	lda	prmSysName+12,x
	sta	sysFileVersion,x
	dex
	bpl	50$
	jmp	LoadDefaults


PntDTName:
.if	C64
	LoadW	r0,#$c3cf
.else
	LoadW	r0,#$ca01
.endif
	rts

ValBankBAM:
	ldx	#0
	lda	#255
 10$
	sta	bankBAM,x
	inx
	cpx	stBank
	bcc	10$
	lda	#1
 20$
	sta	bankBAM,x
	inx
	cpx	endSBank
	bcc	20$
	lda	#255
 30$
	sta	bankBAM,x
	inx
	bne	30$
	rts


AllocBanks:
	jsr	JGetNewBank
	stx	prgBank
	stx	prg1+2
	jsr	JClearBank
	jsr	JGetNewBank
	stx	prg2Bank
	stx	prg2+2
	stx	rcvTCPBank
	stx	sndTCPBank
	jsr	JClearBank
	jsr	JGetNewBank
	stx	bufBank
	stx	recvBank
	stx	getBank
	jsr	JGetNewBank
	stx	termBank
	jsr	JClearBank
	jsr	JGetNewBank
	stx	fontBank
	jsr	JClearBank
	jsr	JGetNewBank
	stx	dirBank
	jsr	JClearBank
	jsr	JGetNewBank
	stx	anchorBank
	jsr	JClearBank
	jsr	JGetNewBank
	stx	linkBank
	jsr	JClearBank
	jsr	JGetNewBank
	stx	htmlBank
	jsr	JClearBank
	jsr	JGetNewBank
	stx	pageBank
	jmp	JClearBank

StashDTName:
	LoadW	r0,#deskName
	LoadW	r2,#16
	LoadB	r1H,#]$fe00
	lda	numDesktops
	asl	a
	asl	a
	asl	a
	asl	a
	sta	r1L
	LoadB	r3L,#0
	jsr	StashRAM
	inc	numDesktops
	rts


GetSTBank:
	LoadW	r0,#stBank
	LoadW	r2,#1
	LoadB	r1H,#]$fe00
	lda	numDesktops
	sec
	sbc	#1
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	#12
	sta	r1L
	LoadB	r3L,#0
	jmp	FetchRAM


DoSuperCk:
	LoadB	sramSize,#0
	sta	stBank
	jsr	InitForIO
	bit	superCheck
	bmi	20$
	lda	ramExpType
	cmp	#4
	beq	30$
.if	C64
	lda	$e487+0
	cmp	#'2'
	bcs	30$
	lda	$e487+2
	cmp	#'4'
	bcs	30$
.else
	PushB	config
	and	#%11001111
	sta	config
	ldx	$f6dd+0
	ldy	$f6dd+2
	PopB	config
	cpx	#'2'
	bcs	30$
	cpy	#'4'
	bcs	30$
.endif
 20$
	ldx	#0
	.byte	44
 30$
	ldx	#255
	jsr	DoneWithIO
	txa
	bne	80$
	rts
 80$
;fall through to next page...



;previous page continues here.
CkSRamSize:
	lda	ramExpType
	cmp	#4
	bne	10$
	jmp	DoOSRamSpace
 10$
	jsr	InitForIO
	lda	firstBank
	cmp	lastBank
	bcs	90$
	sec
	lda	lastBank
	sbc	firstBank
	cmp	#12	;at least 12 banks of ram?
	bcc	90$	;branch if not.
	cmp	#16	;just a 1mb SIMM in use?
	bcc	50$
	pha
	lsr	a
	lsr	a
	sta	r2L
	pla
	sec
	sbc	r2L	;use 75% of the ram.
	cmp	#16
	bcs	50$
	lda	#16
 50$
	sta	r2L
	ldx	#3
 55$
	lda	firstPage,x
	sta	ssFirstPage,x
	dex
	bpl	55$
	lda	firstPage
	beq	70$
	lda	#0
;	sta	firstPage,1
	.byte	$8f,[firstPage,]firstPage,1
	lda	firstBank
	ina
;	sta	firstBank,1
	.byte	$8f,[firstBank,]firstBank,1
 70$
	MoveB	firstBank,stBank
	clc
	adc	r2L
	sta	endSBank
;	sta	firstBank,1
	.byte	$8f,[firstBank,]firstBank,1
	sec
	lda	endSBank
	sbc	stBank
	sta	sramSize
 90$
	jsr	DoneWithIO
	lda	sramSize
	rts

DoOSRamSpace:
	lda	#(0|64)
	jsr	GetNewKernal
	jsr	GetRAMInfo	;ext kernal call.
	lda	r2L
	cmp	#12	;at least 8 banks of ram available?
	bcc	90$	;branch if not.
	cmp	#16	;only a 1mb SIMM in use?
	bcc	5$	;branch if so and take all of what's left.
	pha
	lsr	r2L
	lsr	r2L
	pla
	sec
	sbc	r2L	;take just 75% of the ram.
	cmp	#16
	bcs	5$
	lda	#16
 5$
	pha
	PushB	r3L
	ldy	#1
 10$
	jsr	RamDevInfo
	lda	r3L
	beq	20$
	iny
	cpy	#9
	bcc	10$
	pla
	pla
	jsr	RstrKernal
	lda	sramSize
	rts
 20$
	sty	sramPartition
	PopB	r3L
	clc
	adc	reuBank
	sta	stBank
	PopB	r2L
	sta	sramSize
	clc
	adc	stBank
	sta	endSBank
	LoadB	r7L,#53
	LoadW	r0,#waveRamTxt
	jsr	SvRamDevice
 90$
	jsr	RstrKernal
	lda	sramSize
	rts

waveRamTxt:
	.byte	"WAVERAM",0


LoadDefaults:
	LoadB	ignoreDCD,#%00000000
	LoadB	ispNumber,#CR
	LoadB	bWinTop,#40
	LoadB	desProtocol,#4	;ymodem
	LoadB	autoProtocol,#%10000000
	LoadB	ignoreTimeouts,#%10000000
	LoadB	deleteValue,#8
	lda	defVtOn
	sta	curVtOn
	sta	vtOn
	lda	defAnsiOn
	sta	ansiOn
	ldx	#3
 20$
	lda	defBaudRate,x
	sta	desBaudRate,x
	dex
	bpl	20$
	LoadB	globalBPSRate,#0
	rts

;+++open the program directory here.
dskFntList==$4b00
fontLine==$5000
font1Table==$5100
font2Table==$5200
font3Table==$5300
font4Table==$5500
BldFontTables:
	LoadW	fListPtr,#font4Table
	LoadB	numFonts,#0
	sta	numScrFonts
	ldx	fontBank
	jsr	JClearBank
	LoadW	r1,#dskFntList
	LoadW	r0,#(5*256)+(128*42)+$500
	jsr	ClearRam
	LoadW	r6,#flName
	jsr	FindFile
	txa
	bne	90$
	LoadB	a0L,#0
	sta	a0H
	MoveB	htmlBank,a1L
	jsr	JLoadAscii
	jsr	ReadInFonts	;find available fonts on disk.
	LoadB	a0L,#0
	sta	a0H
	MoveB	htmlBank,a1L
	jsr	ParseFontList
	ldx	htmlBank
	jsr	JClearBank
 90$
;+++reopen previous directory.
	rts

flName:
.if	C64
	.byte	"FontList64",0
.else
	.byte	"FontList128",0
.endif


ParseFontList:
 10$
	jsr	GetFntLine
	bcc	70$
	ldy	#0
	jsr	PntNonSpace
	bcc	10$
 35$
	sty	fnPtr
 40$
	iny
	beq	10$
	lda	fontLine,y
	beq	10$
	cmp	#'='
	beq	50$
	cmp	#TAB
	beq	45$
	cmp	#' '
	bne	40$
 45$
	lda	#0
	sta	fontLine,y
 50$
	jsr	CkFName
	bcc	10$
	stx	nameFound
	ldy	fnPtr
	iny
	jsr	Pnt2Param
	bcc	10$
	jsr	GetParm
	jsr	Add2FTable
	lda	numFonts
	cmp	#128
	bcc	10$
	lda	numScrFonts
	cmp	#128
	bcc	10$
 70$
	jmp	FinishTables


fnPtr:
	.block	1
nameFound:
	.block	1
parmString:
	.block	32


Pnt2Param:
 10$
	lda	fontLine,y
	iny
	bne	30$
	clc		;where'd the '=' go?
	rts
 30$
	cmp	#'='
	bne	10$
;fall through...
PntNonSpace:
 20$
	lda	fontLine,y
	beq	90$
	cmp	#TAB
	beq	30$
	cmp	#' '
	beq	30$
	sec
	rts
 30$
	iny
	bne	20$	;branch always.
 90$
	clc
	rts

GetParm:
	ldx	#0
 10$
	lda	fontLine,y
	beq	50$
	cmp	#TAB
	beq	50$
	sta	parmString,x
	iny
	inx
	cpx	#31
	bcc	10$
 50$
	dex
	beq	60$
	lda	parmString,x
	cmp	#' '
	beq	50$
 60$
	inx
	lda	#0
	sta	parmString,x
	rts

CkFName:
	ldx	#1
 20$
	jsr	CkFNTables
	bcc	60$
	rts
 60$
	inx
	cpx	#5
	bcc	20$
	clc
	rts


CkFNTables:
	ldy	fnPtr
	lda	fn1Table-1,x
	cmp	fontLine,y
	bne	50$
	iny
	lda	fn2Table-1,x
	cmp	fontLine,y
	bne	50$
	iny
	lda	fn3Table-1,x
	cmp	fontLine,y
	bne	50$
	iny
	lda	fn4Table-1,x
	beq	40$
	cmp	fontLine,y
	bne	50$
	iny
	lda	fn5Table-1,x
	beq	40$
	cmp	fontLine,y
	bne	50$
	iny
	lda	fn6Table-1,x
	beq	40$
	cmp	fontLine,y
	bne	50$
	iny
	lda	fn7Table-1,x
	beq	40$
	cmp	fontLine,y
	bne	50$
	iny
	lda	fn8Table-1,x
	beq	40$
	cmp	fontLine,y
	bne	50$
	iny
 40$
	lda	fontLine,y
	beq	45$
	cmp	#'='
	bne	50$
 45$
	sec
	rts
 50$
	clc
	rts

fn1Table:
	.byte	"ffsi"
fn2Table:
	.byte	"oots"
fn3Table:
	.byte	"nnao"
fn4Table:
	.byte	"ttn",0
fn5Table:
	.byte	"dnd",0
fn6Table:
	.byte	"iaa",0
fn7Table:
	.byte	"rmr",0
fn8Table:
	.byte	0,"ed",0

;the preceding table contains the following:
;fontdir,fontname,standard,iso

GetFntLine:
 5$
	ldy	#0
	tya
 10$
	sta	fontLine,y
	iny
	bne	10$
 20$
;	lda	[a0]
	.byte	$a7,a0
	beq	75$
	inc	a0L
	bne	30$
	inc	a0H
 30$
	cmp	#CR
	beq	70$
	cmp	#59
	beq	60$
	sta	fontLine,y
	iny
	bne	20$
 55$
	jsr	FlushToEOL
	bra	5$
 60$
	cpy	#0
	beq	55$
	jsr	FlushToEOL
	sec
	rts
 70$
	cpy	#0
	beq	20$
	sec
	rts
 75$
	cpy	#0
	beq	90$
 80$
	sec
	rts
 90$
	clc
	rts


FlushToEOL:
 10$
;	lda	[a0]
	.byte	$a7,a0
	beq	80$
	inc	a0L
	bne	30$
	inc	a0H
 30$
	cmp	#CR
	bne	10$
 80$
	rts

Add2FTable:
	ldy	nameFound
	lda	add2FLTable-1,y
	ldx	add2FHTable-1,y
	jmp	CallRoutine

add2FLTable:
	.byte	[ChgFntDir,[Add2FList,[Add2StdID,[Add2ISOID
add2FHTable:
	.byte	]ChgFntDir,]Add2FList,]Add2StdID,]Add2ISOID

;+++finish this one.
ChgFntDir:
	rts

Add2FList:
	MoveW	fListPtr,r1
	ldy	#0
 10$
	lda	parmString,y
	sta	(r1),y
	beq	50$
	iny
	bne	10$	;branch always.
	rts		;name way too long, skip it.
 50$
	iny
	tya
	clc
	adc	fListPtr+0
	sta	fListPtr+0
	bcc	60$
	inc	fListPtr+1
 60$
	inc	numFonts
	rts


Add2StdID:
	jsr	GetFntID
	bcs	10$
 5$
	rts
 10$
	lda	numFonts
	beq	5$
	sec
	sbc	#1
	asl	a
	tay
	lda	r2L
	sta	font1Table,y
	iny
	lda	r2H
	sta	font1Table,y
	jmp	PutFntTS


Add2ISOID:
	jsr	GetFntID
	bcs	10$
 5$
	rts
 10$
	lda	numFonts
	beq	5$
	sec
	sbc	#1
	asl	a
	tay
	lda	r2L
	sta	font2Table,y
	iny
	lda	r2H
	sta	font2Table,y
;fall through...
PutFntTS:
	LoadW	r0,#font3Table
	ldy	#0
	ldx	numScrFonts
	beq	40$	;branch if no t,s pointers listed yet.
 10$
	lda	(r0),y
	cmp	r2L
	bne	30$
	iny
	lda	(r0),y
	dey
	cmp	r2H
	bne	30$
	rts		;font t,s pointers already listed.
 30$
	iny
	iny
	bne	35$
	inc	r0H	;this table can be two pages long.
 35$
	dex
	bne	10$
 40$
	lda	r2L
	sta	(r0),y
	iny
	lda	r2H
	sta	(r0),y
	LoadW	r4,#fileHeader
	jsr	GetBlock
	MoveB	fontBank,r10L
	MoveB	numScrFonts,r9L
	LoadB	r9H,#0
	LoadB	r1L,#42
	ldx	#r9
	ldy	#r1L
	jsr	BMult
	clc
	lda	r9H
	adc	#4
	sta	r9H
	ldy	#28
	ldx	#12	;minimum point size of 6.
 50$
	lda	fileHeader+2,x
	beq	60$
;	sta	[r9],y
	.byte	$97,r9
	iny
	lda	fileHeader+3,x
;	sta	[r9],y
	.byte	$97,r9
	iny
	cpy	#42	;7 point sizes stored yet?
	beq	80$	;branch if so.
 60$
	inx
	inx
	cpx	#50	;maximum point size of 24.
	bcc	50$	;branch if not to 24 yet.
 80$
	inc	numScrFonts
	rts


;+++fix this to open up the font directory.
;+++adjust this to read in 128 fonts instead of 60.
ReadInFonts:
	LoadB	r2L,#60
	LoadW	r0,#dskFntList
	jsr	Get1stDirEntry
	txa
	beq	RIF2
	rts
RIF2:
	ldy	#0	;the next several lines will
	lda	(r5),y	;try to verify this as a font file.
	and	#%10001111
	cmp	#$83
	bne	60$	;branch if not a USR file.
	ldy	#22
	lda	(r5),y
	cmp	#FONT
	bne	60$	;branch if not a FONT filetype.
	ldy	#19
	lda	(r5),y
	beq	60$	;branch if not header block.
	ldy	#21
	lda	(r5),y
	cmp	#VLIR
	bne	60$	;branch if not a VLIR file.
	ldx	#0	;we'll assume it's a font file now.
	ldy	#3
 25$
	lda	(r5),y
	cmp	#$a0
	beq	30$
	sta	tempFntList,x
	iny
	inx
	cpx	#16
	bcc	25$
 30$
	lda	#0
	sta	tempFntList,x
	ldy	#1
	lda	(r5),y
	sta	tempFntList+17
	iny
	lda	(r5),y
	sta	tempFntList+18
	ldy	#19
	lda	(r5),y
	sta	r1L
	iny
	lda	(r5),y
	sta	r1H
	LoadW	r4,#fileHeader
	jsr	GetBlock
	bne	60$
	lda	fileHeader+130
	and	#%11000000
	sta	tempFntList+19
	lda	fileHeader+131
	sta	tempFntList+20
	ldy	#20
 50$
	lda	tempFntList,y
	sta	(r0),y
	dey
	bpl	50$
	AddVW	#21,r0
	dec	r2L
	beq	70$
 60$
	jsr	GetNxtDirEntry
	tya
	bne	70$
	jmp	RIF2
 70$
	rts

;bytes 0-16 font filename.
;bytes 17,18 t,s pointer to index block.
;bytes 19,20 font ID.
tempFntList:
	.block	21


GetFntID:
	LoadB	r2L,#60
	LoadW	r0,#dskFntList
	LoadW	r1,#parmString
 10$
	ldy	#0
	lda	(r0),y
	beq	90$
	ldx	#r0
	ldy	#r1
	jsr	CmpString
	bne	60$
	ldx	#3
	ldy	#20
 40$
	lda	(r0),y
	sta	r1,x
	dey
	dex
	bpl	40$
	sec
	rts
 60$
	AddVW	#21,r0
	dec	r2L
	bne	10$
 90$
	clc
	rts

FinishTables:
	LoadB	r1L,#0
	sta	r1H
	LoadW	r0,#font1Table
	LoadW	r2,#$0100
	LoadB	r3L,#0
	MoveB	fontBank,r3H
	jsr	JDoSuperMove
	inc	r0H
	inc	r1H
	jsr	JDoSuperMove
	inc	r0H
	inc	r1H
	inc	r2H	;move 2 pages.
	jsr	JDoSuperMove
	MoveB	numScrFonts,r1L
	LoadB	r1H,#0
	LoadB	r4L,#42
	ldx	#r1
	ldy	#r4L
	jsr	BMult
	clc
	lda	r1H
	adc	#4
	sta	r1H
	sec
	lda	fListPtr+0
	sbc	#[font4Table
	sta	r2L
	lda	fListPtr+1
	sbc	#]font4Table
	sta	r2H
	LoadW	r0,#font4Table
	jsr	JDoSuperMove
	clc
	lda	r1L
	sta	fListPtr+0
	adc	r2L
	sta	fDataPtr+0
	sta	fEndData+0
	lda	r1H
	sta	fListPtr+1
	adc	r2H
	sta	fDataPtr+1
	sta	fEndData+1
	rts

endWInit:
