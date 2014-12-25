;************************************************************

;		WaveInit


;************************************************************


	.psect


StartWave:
	jmp	JStartWave
;OpenModem:
	jmp	JOpenModem
;CloseModem:
	jmp	JCloseModem
;InitIORecv:
	jmp	JInitIORecv
;DoneIORecv:
	jmp	JDoneIORecv
;GetBufByte:
	jmp	JGetBufByte
;GetTCPByte:
	jmp	JGetTCPByte
;PutTCPByte:
	jmp	JPutTCPByte
;GetFrmBuf:
	jmp	JGetFrmBuf
;OnTimer:
	jmp	JOnTimer
;On16Timer:
	jmp	JOn16Timer
;OffTimer:
	jmp	JOffTimer
;CkTimer:
	jmp	JCkTimer
;Disconnect:
	jmp	JDisconnect
;DefSLSettings:
	jmp	JDefSLSettings

defSettings:
;defVtOn:
	.byte	%11111111
;defAnsiOn:
	.byte	%10000000
;defBaudRate:
	.byte	0	;3=2400,6=9600,8=19200,9=38400
			;10=57600,11=115200,0=auto detect.
;defDataBits:
	.byte	8	;8 or 7.
;defParity:
	.byte	0	;0=no,1=odd,2=even.
;defStopBits:
	.byte	1	;1 or 2.
;defSLAddress:
	.word	0	;0=auto detect.

.include	Modem


JSaveSRamVars:
	LoadW	r0,#COMM_BASE
	LoadB	r1L,#0
	sta	r1H
;	lda	#0
	ldx	prgBank
	jmp	FSRV2

JFtchSRamVars:
	LoadW	r1,#COMM_BASE
	ldx	#0
	stx	r0L
	stx	r0H
	lda	prgBank
.if	C128
	jsr	FSRV2
	jmp	MoveNMICode
.endif
FSRV2:
	sta	r3L
	stx	r3H
	LoadW	r2,#(ModemTable-COMM_BASE)

;fall through...


;previous page continues here.
JDoSuperMove:
	PushW	r0
	PushW	r1
	lda	#$54	;default to mvn.
	sta	smBanks+0
	MoveB	r3L,smBanks+2
	MoveB	r3H,smBanks+1
	cmp	r3L
	bne	50$
	rep	%00100000	;16 bit acc.
	lda	r1
	cmp	r0
	bcc	50$
	lda	r2
	dea
	clc
	adc	r0
	sta	r0
	lda	r2
	dea
	clc
	adc	r1
	sta	r1
	sep	%00100000	;8 bit acc.
	lda	#$44	;use mvp.
	sta	smBanks+0
 50$
	rep	%00110000	;16 bit a,x,y.
	ldx	r0
	ldy	r1
	lda	r2
	dea
	phb
smBanks:
	mvn	0,2
	plb
	sep	%00110000	;8 bit a,x,y.
	PopW	r1
	PopW	r0
	rts


SetNativeMode:
	php
	sei
.if	C128
	LoadW	r0,#IRQ16Routine
	LoadW	r1,#IRQ128
	LoadW	r2,#(endIRQRoutine-IRQ16Routine)
	jsr	MoveData
	LoadB	r3L,#1
	LoadB	r3H,#0
	jsr	MoveBData
.endif
	MoveW	$ffea,ffeaSave
	MoveW	$ffee,ffeeSave
.if	C64
	LoadW	$ffea,#$9fff
	LoadW	$ffee,#IRQ16Routine
.else
	LoadW	$ffea,#$ff25
	LoadW	$ffee,#IRQ128
	PushB	$d506
	ora	#%00001000
	sta	$d506
	MoveW	$ffea,ffea128Save
	MoveW	$ffee,ffee128Save
	LoadW	$ffea,#$ff25
	LoadW	$ffee,#IRQ128
	PopB	$d506
.endif
	clc
	xce		;native mode.
	plp
	rts

SetEmulationMode:
	php
	sei
	sec
	xce		;emulation mode.
	MoveW	ffeaSave,$ffea
	MoveW	ffeeSave,$ffee
.if	C128
	PushB	$d506
	ora	#%00001000
	sta	$d506
	MoveW	ffea128Save,$ffea
	MoveW	ffee128Save,$ffee
	PopB	$d506
.endif
	plp
	rts


.if	C64

IRQ16Routine:
	sei
	rep	%00110000
;	sta	saveIRQAcc
	.byte	$8f,[saveIRQAcc,]saveIRQAcc,0
	pla
	pha
	and	#[%00000100	;did an IRQ occur while IRQ's are disabled?
	.byte	]%00000100	;(this can happen at 20 mhz!)
	bne	BadIRQ
;	lda	saveIRQAcc
	.byte	$af,[saveIRQAcc,]saveIRQAcc,0
	pha
	phx
	phy
	sep	%00110000
	phb
;	phk
	.byte	$4b
	plb
;	phk
	.byte	$4b
;	pea	IRQ16b
	.byte	$f4,[IRQ16b,]IRQ16b
	lda	#%00000100
	pha
	jmp	MainIRQ

IRQ16b:
	plb
	rep	%00110000
	ply
	plx
	pla
	rti

BadIRQ:
;	lda	saveIRQAcc
	.byte	$af,[saveIRQAcc,]saveIRQAcc,0
	jmp	($ffea)

saveIRQAcc:
	.block	2

.else
IRQ16Routine:
	sei
	rep	%00110000
;	sta	IRQ128+saveIRQAcc-IRQ16Routine
	.byte	$8f
	.word	IRQ128+saveIRQAcc-IRQ16Routine
	.byte	0
	pla
	pha
	and	#[%00000100	;did an IRQ occur while IRQ's are disabled?
	.byte	]%00000100	;(this can happen at 20 mhz!)
	bne	BadIRQ	;branch if so.
;	lda	IRQ128+saveIRQAcc-IRQ16Routine
	.byte	$af
	.word	IRQ128+saveIRQAcc-IRQ16Routine
	.byte	0
	pha
	phx
	phy
	sep	%00110000
	phb
;	phk
	.byte	$4b
	plb
	lda	#%00000100
	pha		;push a fake processor flag.
	pha		;one extra for MainIRQ to skip over.
	PushB	config
	LoadB	config,#$7e
	PushB	$d506
	and	#%11110000
	sta	$d506
	jsr	MainIRQ
	PopB	$d506
	PopB	config
	pla		;pull the two fake bytes.
	pla
	plb
	rep	%00110000
	ply
	plx
	pla
	rti

BadIRQ:
;	lda	IRQ128+saveIRQAcc-IRQ16Routine
	.byte	$af
	.word	IRQ128+saveIRQAcc-IRQ16Routine
	.byte	0
	jmp	($ffea)

saveIRQAcc:
	.block	2
endIRQRoutine:
.endif

;+++don't do any native mode stuff in this routine since this is also
;+++run at the very start while emulation mode is still running.
JSetNewDir:
	stx	curOpenDir
	lda	curDrive
	sta	prgDrive,x
	jsr	GetHeadTS
	ldx	curOpenDir
	lda	r2L
	sta	prgPart,x
	lda	dirHeadTrack
	sta	prgTrack,x
	lda	dirHeadSector
	sta	prgSector,x
;fall through...
SetCurDir:
	ldx	curOpenDir
	lda	prgDrive,x
	sta	presDrive
	lda	prgPart,x
	sta	presPart
	lda	prgTrack,x
	sta	presTrack
	lda	prgSector,x
	sta	presSector
	rts


JGetNxtBank:
	lda	bankBAM,x
	beq	20$
	cmp	#1
	beq	90$
	cmp	#255
	beq	90$
	tax
	sec
 10$
	rts
 20$
	txy
	jsr	JGetNewBank
	bcc	10$
	txa
	sta	bankBAM,y
	lda	#0	;indicate a new bank allocated.
	sec
	rts
 90$
;fall through...
JGetNewBank:
	ldx	stBank
 10$
	lda	bankBAM,x
	cmp	#1
	beq	50$
	inx
	cpx	endSBank
	bcc	10$
	clc
	rts
 50$
	lda	#0
	sta	bankBAM,x
	sec
	rts

JGetPrevBank:
	txa
	ldx	stBank
 30$
	cmp	bankBAM,x
	beq	50$
	inx
	cpx	endSBank
	bcc	30$
	clc
 50$
	rts


;this frees up all banks in a chain beyond the
;requested bank.
;So in order to free up an entire chain of banks
;including the first one, you must call this routine
;with x holding the number of the first bank in the
;chain. Following that, load x again and call FreeBank
;to free up the first bank in the chain.
JFreeBnkChain:
	lda	bankBAM,x
	beq	80$
	cmp	#1
	beq	90$
	cmp	#255
	beq	90$
	pha
	lda	#0
	sta	bankBAM,x
	plx
 10$
	lda	bankBAM,x
	cmp	#1
	beq	90$
	cmp	#255
	beq	90$
	pha
	lda	#1
	sta	bankBAM,x
	plx
	bne	10$
 80$
	sec
	rts
 90$
	clc
	rts

;this frees up a single bank. It only works on
;the last bank of a chain.
JFreeBank:
	lda	bankBAM,x
	beq	20$
	clc
	rts
 20$
	lda	#1
	sta	bankBAM,x
	jsr	JGetPrevBank
	bcc	80$
	lda	#0
	sta	bankBAM,x
 80$
	sec
	rts

JClearBank:
	stx	JCB2+3
	rep	%00110000	;16 bit a,x,y.
	ldx	#0
	.byte	0
	txa
JCB2:
;	sta	$020000,x
	.byte	$9f,[$00,]$00,2 ;this changes.
	inx
	inx
	bne	JCB2
	sep	%00110000	;8 bit a,x,y.
	rts

JNxtBank:
	lda	bankBAM,x
	beq	90$
	cmp	#1
	beq	90$
	cmp	#255
	beq	90$
	tax
	sec
	rts
 90$
	clc
	rts

AddMnRoutine:
	jsr	RemvMnRoutine
	ldx	#0
 10$
	lda	appMTable+0,x
	ora	appMTable+1,x
	beq	50$
	inx
	inx
	cpx	#16
	bcc	10$
	ldx	#0
	rts
 50$
	lda	r0L
	sta	appMTable+0,x
	lda	r0H
	sta	appMTable+1,x
	txa
	lsr	a
	ina
	tax
	rts

RemvMnRoutine:
	cpx	#9
	bcs	90$
	txa
	beq	90$
	dea
	asl	a
	tax
	lda	#0
	sta	appMTable+0,x
	sta	appMTable+1,x
 90$
	rts

ClrAllAppMains:
	ldx	#0
	tax
 10$
	sta	appMTable,x
	inx
	cpx	#20
	bcc	10$
	rts


AppMainRoutine:
	ldx	#0
 10$
	phx
	lda	appMTable+0,x
	ora	appMTable+1,x
	beq	40$
;	jsr	(appMTable,x)
	.byte	$fc,[appMTable,]appMTable
 40$
	plx
	inx
	inx
	cpx	#16
	bcc	10$
	rts


JmpModBase:
	jsr	LoadModule
	jmp	ModBase+0

LoadModule:
	pha
	jsr	GetModule
	PopB	curModule
	rts

GetModule:
	asl	a
	tax
	rep	%00100000
	lda	modLdTable-2,x
	sta	r1
	lda	modRmTable-2,x
	sta	r0
	sec
	lda	modRmTable+0,x
	sbc	r0
	sta	r2
	sep	%00100000
	MoveB	prgBank,r3L
	LoadB	r3H,#0
	jmp	JDoSuperMove

modLdTable:
	.word	MainTable,ModBase,ModBase

JOpenPrgDir:
	ldx	#0
	.byte	44
JOpenSrcDir:
	ldx	#1
	.byte	44
JOpenDesDir:
	ldx	#2
	.byte	44
JOpenSavDir:
	ldx	#3
	.byte	44
JOpenURLDir:
	ldx	#4
	.byte	44
JOpenCurDir:
	ldx	#5
	stx	curOpenDir
	lda	prgDrive,x
	jsr	SetDevice
	bne	90$
	jsr	GetHeadTS
	txa
	bne	90$
	ldx	curOpenDir
	lda	prgPart,x
	tax
	cpx	r2L
	beq	60$
	jsr	JGoXPartition
	bne	90$
 60$
	ldx	curOpenDir
	lda	prgTrack,x
	sta	r1L
	lda	prgSector,x
	sta	r1H
	jsr	OpenDirectory
	txa
	bne	90$
	jsr	SetCurDir
	ldx	#0
 90$
	rts

JSvDefaults:
	jsr	JOpnPrgFile
	bne	90$
	MoveB	fileHeader+2,r1L
	MoveB	fileHeader+3,r1H
	jsr	RdBlkDskBuf
	bne	90$
	ldx	#0
 20$
	lda	defSettings,x
	sta	diskBlkBuf+2+45,x
	inx
	cpx	#8
	bcc	20$
	jsr	WrBlkDskBuf
 90$
	rts

JGoXPartition:
	lda	#(5|64)
	jsr	GetNewKernal
	jsr	GoPartition
	jsr	RstrKernal
	txa
	rts

;+++ insert an error routine in here to notify the user that the program
;+++disk is unavailable.
JOpnPrgFile:
	jsr	JOpenPrgDir
	LoadW	r0,#prgName
	jsr	OpenRecordFile
	phx
	jsr	CloseRecordFile
	plx
	rts

JOpnSysFile:
	jsr	JOpenPrgDir
	LoadW	r0,#sysName
	jsr	OpenRecordFile
	phx
	jsr	CloseRecordFile
	plx
	rts

sysName:
.if	C64
	.byte	"System64",0
.else
	.byte	"System128",0
.endif

JCkAbortKey:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	php
	sei
	LoadB	$dc03,#%00000000
	LoadB	$dc02,#%11111111
	LoadB	$dc00,#%01111111
	lda	$dc01
	plp
	asl	a
.if	C64
	PopB	CPU_DATA
.endif
	rts


JLoadAscii:
	LoadB	htmlSize+0,#0
	sta	htmlSize+1
	sta	htmlSize+2
	jsr	NullA0
	lda	dirEntryBuf+0
	and	#%10111111
	cmp	#($80|USR)
	bne	60$
	lda	dirEntryBuf+22
	cmp	#APPL_DATA
	bne	60$
	LoadW	r9,#dirEntryBuf
	jsr	GetFHdrInfo
	txa
	bne	60$
	ldy	#0
 10$
	lda	wrString,y
	beq	20$
	cmp	fileHeader+77,y
	bne	60$
	iny
	bne	10$	;branch always.
 20$
	lda	fileHeader+90
	cmp	#'2'
	bcs	30$
	lda	#64
	.byte	44
 30$
	lda	#61
	sta	maxGWPages
	jmp	ReadGWAscii
 60$
	jmp	RdAsIsFile

maxGWPages:
	.block	1
curGWRecord:
	.block	1
wrString:
	.byte	"Write Image",0

RdAsIsFile:
	LoadB	gwFileFlag,#%00000000
	MoveB	dirEntryBuf+1,r1L
	MoveB	dirEntryBuf+2,r1H
	LoadW	r4,#diskBlkBuf
	LoadB	r5L,#0
	sta	r5H
 10$
	jsr	ReadByte
	cpx	#0
	bne	80$
	jsr	StaA0Inc
	bcs	10$
 80$
	lda	#0
;	sta	[a0]
	.byte	$87,a0
	rts


ReadSFile:
	LoadB	gwFileFlag,#%00000000
	MoveB	dirEntryBuf+1,r1L
	MoveB	dirEntryBuf+2,r1H
	LoadW	r4,#diskBlkBuf
	LoadB	r5L,#0
	sta	r5H
 5$
	sta	lastChRead
 10$
	jsr	ReadByte
	cpx	#0
	bne	80$
	cmp	#127
	bcs	5$
	cmp	#32
	bcs	60$
	cmp	#0
	beq	5$
	cmp	#TAB
	beq	55$
	cmp	#LF
	bne	30$
	ldx	lastChRead
	cpx	#CR
	beq	5$
	lda	#CR
	bne	65$
 30$
	cmp	#CR
	beq	60$
	bne	5$
 55$
	lda	#' '
 60$
	sta	lastChRead
 65$
	jsr	StaA0Inc
	bcs	10$
 80$
NullA0:
	lda	#0
;	sta	[a0]
	.byte	$87,a0
	rts

lastChRead:
	.block	1


StaA0Inc:
;	sta	[a0]
	.byte	$87,a0
	inc	a0L
	bne	50$
	jsr	JCkAbortKey
	bcs	30$
	dec	a0L
	jsr	NullA0
	clc
	rts
 30$
	inc	a0H
	bne	50$
	ldx	a1L
	jsr	JGetNxtBank
	bcs	40$
	LoadB	a0L,#$ff
	sta	a0H
	jsr	NullA0
	clc
	rts
 40$
	stx	a1L
	jsr	JClearBank
 50$
	inc	htmlSize+0
	bne	60$
	inc	htmlSize+1
	bne	60$
	inc	htmlSize+2
 60$
	sec
	rts

ReadGWAscii:
	LoadB	gwFileFlag,#%10000000
	MoveB	dirEntryBuf+1,r1L
	MoveB	dirEntryBuf+2,r1H
	LoadW	r4,#fileHeader
	jsr	GetBlock
	LoadB	curGWRecord,#0
	LoadW	r4,#diskBlkBuf
 10$
	LoadB	r5L,#0
	sta	r5H
	lda	curGWRecord
	cmp	maxGWPages
	bcc	13$
 12$
	jmp	NullA0
 13$
	asl	a
	tay
	lda	fileHeader+3,y
	sta	r1H
	lda	fileHeader+2,y
	sta	r1L
	beq	12$
	inc	curGWRecord
	jsr	ReadByte
	cpx	#0
	bne	10$
	cmp	#ESC_RULER
	beq	15$
	lda	#23
	.byte	44
 15$
	lda	#26
	.byte	44
 16$
	lda	#3
	.byte	44
 17$
	lda	#5
	jsr	SkipGWBytes
	bne	10$
 20$
	jsr	ReadByte
	cpx	#0
	bne	10$
	cmp	#ESC_RULER
	beq	15$
	cmp	#NEWCARDSET
	beq	16$
	cmp	#ESC_GRAPHICS
	beq	17$
	cmp	#TAB
	beq	40$
	cmp	#CR
	beq	50$
	cmp	#' '
	bcc	20$
	cmp	#127
	bcs	20$
	.byte	44
 40$
	lda	#' '
 50$
	jsr	StaA0Inc
	bcs	20$
	jmp	NullA0

SkipGWBytes:
	sta	bytesToSkip
 10$
	jsr	ReadByte
	cpx	#0
	bne	90$
	dec	bytesToSkip
	bne	10$
 90$
	rts

bytesToSkip:
	.block	1


;this divides a 16 bit number into a 32 bit number.
JD32div:
	LoadB	r8L,#0
	sta	r8H
	LoadB	r9L,#32
 20$
	asl	r6L
	rol	r6H
	rol	r7L
	rol	r7H
	rol	r8L
	rol	r8H
	bcs	40$
	lda	r8H
	cmp	$01,y
	bne	30$
	lda	r8L
	cmp	$00,y
 30$
	bcc	50$
 40$
	lda	r8L
	sbc	$00,y
	sta	r8L
	lda	r8H
	sbc	$01,y
	sta	r8H
	inc	r6L
 50$
	dec	r9L
	bne	20$
	rts


JExitWave:
	jsr	CloseModem
	LoadW	r0,#deskName
	jsr	FetchDTName
	MoveB	deskName+13,dtDrive
	MoveB	deskName+14,dtPartition
	MoveB	deskName+15,dtType
	lda	#10
	jsr	GetNewKernal
	jsr	CloseSRam
.if	C128
	lda	#0
	jsr	SetColorMode
	bit	graphicsMode
	bpl	50$
.endif
	jsr	GrayScreen
	MoveB	screencolors,r4H
	jsr	ColorRectangle
 50$
	jsr	JOpenPrgDir
	jsr	SetEmulationMode
	jmp	EnterDesktop


FetchDTName:
	dec	numDesktops
	ldy	#FETCH
	LoadB	r1H,#]$fe00
	lda	numDesktops
	asl	a
	asl	a
	asl	a
	asl	a
	sta	r1L
	LoadW	r2,#16
	LoadB	r3L,#0
	jmp	DoRAMOp

CloseSRam:
	lda	stBank
	bne	10$
	rts
 10$
	lda	ramExpType
	cmp	#4
	bne	50$
	lda	#(0|64)
	jsr	GetNewKernal
	ldy	sramPartition
	jsr	DelRamDevice	;ext kernal call.
	jmp	RstrKernal
 50$
	jsr	InitForIO
	lda	ssFirstPage+0
	.byte	$8f	;sta firstPage(long)
	.word	firstPage
	.byte	1
	lda	ssFirstPage+1
	.byte	$8f	;sta firstPage(long)
	.word	firstBank
	.byte	1
	lda	ssFirstPage+2
	.byte	$8f	;sta firstPage(long)
	.word	lastPage
	.byte	1
	lda	ssFirstPage+3
	.byte	$8f	;sta firstPage(long)
	.word	lastBank
	.byte	1
	jmp	DoneWithIO


SvBrwsVectors:
	rep	%00100000
	lda	otherPressVec
	sta	brwsOthPress
	lda	keyVector
	sta	brwsKeyVector
	lda	#[0
	.byte	]0
	sta	otherPressVec
	sta	keyVector
	sep	%00100000
	rts

RstBrwsVectors:
	rep	%00100000
	lda	brwsOthPress
	sta	otherPressVec
	lda	brwsKeyVector
	sta	keyVector
	sep	%00100000
	rts
