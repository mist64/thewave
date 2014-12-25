;***********************************************

;	Main

;***********************************************


	.psect


WaveJumpTable:
;jump table to call resident routines from within bank 0.
;DoBrowser:
	jmp	JDoBrowser
;ReDoBrowser:
	jmp	JReDoBrowser
;ESelProtocol:
	jmp	JESelProtocol
;EDoSelBox:
	jmp	JEDoSelBox
;EDoMdmSettings:
	jmp	JEDoMdmSettings
;CkAbortKey:
	jmp	JCkAbortKey
;FullMouse:
	jmp	JFullMouse
;FullMargins:
	jmp	JFullMargins
;ClearScreen:
	jmp	JClearScreen
;HideScreen:
	jmp	JHideScreen
;GrayScreen:
	jmp	JGrayScreen
;SetBrdrColor:
	jmp	JSetBrdrColor
;SuperSwap:
	jmp	JSuperSwap
;DoBeep:
	jmp	JDoBeep
;GoXPartition:
	jmp	JGoXPartition
;SetSaveColor:
	jmp	JSetSaveColor
;SetRstrColor:
	jmp	JSetRstrColor
;PattScreen:
	jmp	JPattScreen
;FrameDB:
	jmp	JFrameDB
;DoColorBox:
	jmp	JDoColorBox

;GetNxtBank:
	jmp	JGetNxtBank
;NxtBank:
	jmp	JNxtBank
;GetNewBank:
	jmp	JGetNewBank
;GetPrevBank:
	jmp	JGetPrevBank
;FreeBnkChain:
	jmp	JFreeBnkChain
;FreeBank:
	jmp	JFreeBank
;ClearBank:
	jmp	JClearBank

WJT2:
;ImprintScreen:
	jmp	JImprintScreen
;OpnPrgFile:
	jmp	JOpnPrgFile
;OpnSysFile:
	jmp	JOpnSysFile
;OpenPrgDir:
	jmp	JOpenPrgDir
;OpenSrcDir:
	jmp	JOpenSrcDir
;OpenDesDir:
	jmp	JOpenDesDir
;OpenSavDir:
	jmp	JOpenSavDir
;OpenURLDir:
	jmp	JOpenURLDir
;OpenCurDir:
	jmp	JOpenCurDir
;SetNewDir:
	jmp	JSetNewDir
;SvDefaults:
	jmp	JSvDefaults
;SysScrColor:
	jmp	JSysScrColor
;ColrR4H:
	jmp	JColrR4H
;SetNxtDrive:
	jmp	JSetNxtDrive
;Set1stDrive:
	jmp	Set1stDrive
;ClearTop:
	jmp	JClearTop
;ClearBTop:
	jmp	JClearBTop
;ClearBWindow:
	jmp	JClearBWindow

WJT3:
;LoadAscii:
	jmp	JLoadAscii
;DoSuperMove:
	jmp	JDoSuperMove
;SaveSRamVars:
	jmp	JSaveSRamVars
;FtchSRamVars:
	jmp	JFtchSRamVars
;DecTo32:
	jmp	JDecTo32
;HexTo32:
	jmp	JHexTo32
;D32div:
	jmp	JD32div
;Mult24:
	jmp	JMult24
;Mult32:
	jmp	JMult32
;ExitWave:
	jmp	JExitWave
;InitScrBar:
	jmp	JInitScrBar
;PosScrBar:
	jmp	JPosScrBar

;these routines won't do anything on the 64.
WJT4:
;ReadReg:
	jmp	JReadReg
;WriteReg:
	jmp	JWriteReg
;MoveVData:
	jmp	JMoveVData
;iMoveVData:
	jmp	JiMoveVData
;ClearVRam:
	jmp	JClearVRam
;FillVRam:
	jmp	JFillVRam
;iFillVRam:
	jmp	JiFillVRam
;StashVRam:
	jmp	JStashVRam
;FetchVRam:
	jmp	JFetchVRam
;PokeVRam:
	jmp	JPokeVRam
;PeekVRam:
	jmp	JPeekVRam
;OTempHideMouse
	jmp	JOTempHideMouse

;jump table to call resident routines from other banks.
;Some of the routines are omitted due to an inability to run from
;any bank other than bank 0.
SJmpTable:
;SCkAbortKey:
	jsr	SuperJSL
;SFullMargins:
	jsr	SuperJSL
;SGetNxtBank:
	jsr	SuperJSL
;SNxtBank:
	jsr	SuperJSL
;SGetNewBank:
	jsr	SuperJSL
;SFreeBnkChain:
	jsr	SuperJSL
;SFreeBank:
	jsr	SuperJSL
;SClearBank:
	jsr	SuperJSL
;SClearBWindow:
	jsr	SuperJSL
;SDoSuperMove:
	jsr	SuperJSL
;SDecTo32:
	jsr	SuperJSL
;SHexTo32:
	jsr	SuperJSL
;SD32div:
	jsr	SuperJSL
;SMult24:
	jsr	SuperJSL
;SMult32:
	jsr	SuperJSL

;SMoveVData:
	jsr	SuperJSL
;SStashVRam:
	jsr	SuperJSL
;SFetchVRam:
	jsr	SuperJSL

;calls routines within the SLDriver.
;SCkRecv:
	jsr	SuperJSL
;SCheckDCD:
	jsr	SuperJSL

;calls routines within the modem driver.
;SOpenModem:
	jsr	SuperJSL
;SDefSLSettings
	jsr	SuperJSL

SJT9:
;SHorizontalLine:
	jsr	SuperJSL
;SRectangle:
	jsr	SuperJSL
;SFrameRectangle:
	jsr	SuperJSL
;SSetPattern:
	jsr	SuperJSL
;SPutChar:
	jsr	SuperJSl
;SUseSystemFont:
	jsr	SuperJSL
;SBBMult:
	jsr	SuperJSL
;SBMult:
	jsr	SuperJSL
;SDMult:
	jsr	SuperJSL
;SDdiv:
	jsr	SuperJSL
;SDabs:
	jsr	SuperJSL
;SDnegate:
	jsr	SuperJSL
;SMoveData:
	jsr	SuperJSL
;SGetRandom:
	jsr	SuperJSL
;SMouseUp:
	jsr	SuperJSL
;SMouseOff:
	jsr	SuperJSL
;SGetRealSize:
	jsr	SuperJSL
;SInitTextPrompt:
	jsr	SuperJSL
;SLoadCharSet:
	jsr	SuperJSL
;SPutBlock:
	jsr	SuperJSL
;SGetFreeDirBlk:
	jsr	SuperJSL
;SBlkAlloc:
	jsr	SuperJSL
;SReadFile:
	jsr	SuperJSL
;SEnterTurbo:
	jsr	SuperJSL
;SReadBlock:
	jsr	SuperJSL

SJT16:
;SGetDirHead:
	jsr	SuperJSL
;SPutDirHead:
	jsr	SuperJSL
;SInitForIO:
	jsr	SuperJSL
;SDoneWithIO:
	jsr	SuperJSL
;SSetNextFree:
	jsr	SuperJSL
;SPrmptOn:
	jsr	SuperJSL
;SPrmptOff:
	jsr	SuperJSL
;SOpenDisk:
	jsr	SuperJSL
;STempHideMouse:
	jsr	SuperJSL
;SColorRectangle:
	jsr	SuperJSL
;SConvToCards:
	jsr	SuperJSL
;SGetOffPgTS:
	jsr	SuperJSL
;SRdBlkDskBuf:
	jsr	SuperJSL
;SWrBlkDskBuf:
	jsr	SuperJSL
;SReadLink:
	jsr	SuperJSL
;SSendPPPFrame:
	jsr	SuperJSL
;SDisconnect:
	jsr	SuperJSL
;SFetchFSegment:
	jsr	SuperJSL


;jump table into extended mod routines.
;these are for calling the routines from bank 0.
ext0Table:
;SwIf80:
	jsr	GetExtRoutine
;DoDeskAccessories:
	jsr	GetExtRoutine
;DoApplication:
	jsr	GetExtRoutine
;XModSend:
	jsr	GetExtRoutine
;XModRecv:
	jsr	GetExtRoutine
;SelProtocol:
	jsr	GetExtRoutine
;SvHTMLBuffer:
	jsr	GetExtRoutine
;DownHTTP:
	jsr	GetExtRoutine
;GetWrDocument:
	jsr	GetExtRoutine
;GetNonGEOS:
	jsr	GetExtRoutine
;GetAnyFile:
	jsr	GetExtRoutine
;GetAppFile:
	jsr	GetExtRoutine
;GetDAFile:
	jsr	GetExtRoutine

;BrowseMsg:
	jsr	GetExtRoutine
;ClrMsgBox:
	jsr	GetExtRoutine
;DoMsgDB:
	jsr	GetExtRoutine
;DoDiskError:
	jsr	GetExtRoutine
;DoSelBox:
	jsr	GetExtRoutine

;ISPDir:
	jsr	GetExtRoutine
;BBSDir:
	jsr	GetExtRoutine
;InetSession:
	jsr	GetExtRoutine
;BeginISP:
	jsr	GetExtRoutine
;DoTrmMode:
	jsr	GetExtRoutine


;super jump table for certain extended mod routines
;when calling from any upper bank.
ext1Table:
;SSwIf80:
	jsr	SuperExtRoutine
;SDoDeskAccessories:
	jsr	SuperExtRoutine
;SDoApplication:
	jsr	SuperExtRoutine
;SXModSend:
	jsr	SuperExtRoutine
;SXModRecv:
	jsr	SuperExtRoutine
;SSelProtocol:
	jsr	SuperExtRoutine
;SSvHTMLBuffer:
	jsr	SuperExtRoutine
;SDownHTTP:
	jsr	SuperExtRoutine
;SGetWrDocument:
	jsr	SuperExtRoutine
;SGetNonGEOS:
	jsr	SuperExtRoutine
;SGetAnyFile:
	jsr	SuperExtRoutine
;SGetAppFile:
	jsr	SuperExtRoutine
;SGetDAFile:
	jsr	SuperExtRoutine

;SBrowseMsg:
	jsr	SuperExtRoutine
;SClrMsgBox:
	jsr	SuperExtRoutine
;SDoMsgDB:
	jsr	SuperExtRoutine
;SDoDiskError:
	jsr	SuperExtRoutine
;SDoSelBox:
	jsr	SuperExtRoutine

;SISPDir:
	jsr	SuperExtRoutine
;SBBSDir:
	jsr	SuperExtRoutine
;SInetSession:
	jsr	SuperExtRoutine
;SBeginISP:
	jsr	SuperExtRoutine
;SDoTrmMode:
	jsr	SuperExtRoutine

prgBnkRoutines:
;LParseHTML:
	jsr	JSLPrg2Bank
	nop
;LDialOut:
	jsr	JSLPrg2Bank
	nop
;LPPPLinkUp:
	jsr	JSLPrg2Bank
	nop
;LSndTrmRequest:
	jsr	JSLPrg2Bank
	nop
;LLdTCPBlock:
	jsr	JSLPrg2Bank
	nop
;LOutTCPBuffer:
	jsr	JSLPrg2Bank
	nop
;LOpnTCPConnection:
	jsr	JSLPrg2Bank
	nop
;LClsTCPConnection:
	jsr	JSLPrg2Bank
	nop
;LReslvAddress:
	jsr	JSLPrg2Bank
	nop
;LSepHREFString:
	jsr	JSLPrg2Bank
	nop
;LStartHTTP:
	jsr	JSLPrg2Bank
	nop
;LDoIACMode:
	jsr	JSLPrg2Bank
	nop
;LInitTNVars
	jsr	JSLPrg2Bank
	nop

;LSendXModem:
	jsr	JSLPrg2Bank
	nop
;LRecvXModem:
	jsr	JSLPrg2Bank
	nop
;LSendYModem:
	jsr	JSLPrg2Bank
	nop
;LRecvYModem:
	jsr	JSLPrg2Bank
	nop
;LSendZModem:
	jsr	JSLPrg2Bank
	nop
;LRecvZModem:
	jsr	JSLPrg2Bank
	nop
;LReadInDirectory:
	jsr	JSLPrg2Bank
	nop
;LFindLFile:
	jsr	JSLPrg2Bank
	nop
;LWrBigBuffer:
	jsr	JSLPrg2Bank
	nop
;LPutLongString:
	jsr	JSLPrg2Bank
	nop

;LDoURLBar:
	jsr	JSLPrg2Bank
	nop
;LPutURLString:
	jsr	JSLPrg2Bank
	nop
;LByte2Ascii:
	jsr	JSLPrg2Bank
	nop
;LSizeToDec:
	jsr	JSLPrg2Bank
	nop
;LRstTermScreen:
	jsr	JSLPrg2Bank
	nop
;LSaveTxtScreen:
	jsr	JSLPrg2Bank
	nop
;LRstrTxtScreen:
	jsr	JSLPrg2Bank
	nop
;LDoURL2Left:
	jsr	JSLPrg2Bank
	nop
;LDoURL2Right:
	jsr	JSLPrg2Bank
	nop
;LURLBarMsg:
	jsr	JSLPrg2Bank
	nop
;LURLEdFunction:
	jsr	JSLPrg2Bank
	nop

;LScrollScreen:
	jsr	JSLPrg2Bank
	nop
;LScrUpRegion:
	jsr	JSLPrg2Bank
	nop
;LScrDnRegion:
	jsr	JSLPrg2Bank
	nop


;LAddrTo32Bits:
	jsr	JSLPrg2Bank
	nop

;LCurFrRegs:
	jsr	JSLPrg2Bank
	nop
;LFrRegs:
	jsr	JSLPrg2Bank
	nop
;LCurFrHeight:
	jsr	JSLPrg2Bank
	nop
;LFrHeight:
	jsr	JSLPrg2Bank
	nop
;LCurFrBottom:
	jsr	JSLPrg2Bank
	nop
;LFrBottom:
	jsr	JSLPrg2Bank
	nop
;LCurFrWidth:
	jsr	JSLPrg2Bank
	nop
;LFrWidth:
	jsr	JSLPrg2Bank
	nop
;LCurFrDimensions:
	jsr	JSLPrg2Bank
	nop
;LFrDimensions:
	jsr	JSLPrg2Bank
	nop
;LGetCurFrame:
	jsr	JSLPrg2Bank
	nop
;LGetFrame:
	jsr	JSLPrg2Bank
	nop

;LGetDesFont:
	jsr	JSLPrg2Bank
	nop

.if	debug
;LWriteDebug:
	jsr	JSLPrg2Bank
	nop
;LInitDebug:
	jsr	JSLPrg2Bank
	nop
.endif


;FSmallPutChar:
	jsr	SmallPutChar
	rtl

;FCkAbortKey:
	jsr	JCkAbortKey
	rtl

;FGetFrmBuf:
	jsr	JGetFrmBuf
	rtl

;FGetBufByte:
	jsr	JGetBufByte
	rtl

;FSend1Byte:
	jsr	Send1Byte
	rtl

;FGetTCPByte:
	jsr	JGetTCPByte
	rtl

;FPutTCPByte:
	jsr	JPutTCPByte
	rtl

;FOnTimer:
	jsr	OnTimer
	rtl

;FCkTimer:
	jsr	CkTimer
	rtl

;FGetCharWidth:
	jsr	GetCharWidth
	rtl

;use this to jsr to a bank 0 routine from any
;other bank using the jump tables that call this.
SuperJSL:
;	sta	SJ5+1
	.byte	$8f,[(SJ5+1),](SJ5+1),0
	php
	pla
;	sta	SJ4+1
	.byte	$8f,[(SJ4+1),](SJ4+1),0
	txa
;	sta	SJ6+1
	.byte	$8f,[(SJ6+1),](SJ6+1),0
	pla
;	sta	SJ1+1
	.byte	$8f,[(SJ1+1),](SJ1+1),0
	pla
;	sta	SJ1+2
	.byte	$8f,[(SJ1+2),](SJ1+2),0
	phb
;	phk
	.byte	$4b
	plb
	rep	%00110000	;16 bit a,x,y.
	sec
SJ1:
	lda	#0	;this changes.
	.byte	0	;16 bit acc.
	sbc	#[(SJmpTable+2)
	.byte	](SJmpTable+2)
	jsr	DivBy3
	asl	a
	tax
	lda	sjTable,x
	sta	SJ7+1
	sep	%00110000
SJ4:
	lda	#0	;this changes.
	pha
SJ5:
	lda	#0	;this changes.
SJ6:
	ldx	#0	;this changes.
	plp
SJ7:
	jsr	$5000	;this changes.
	sta	SJ9+1
	php
	PopB	SJ8+1
	plb
SJ8:
	lda	#0
	pha
SJ9:
	lda	#0
	plp
	rtl


sjTable:
	.word	JCkAbortKey,JFullMargins
	.word	JGetNxtBank,JNxtBank
	.word	JGetNewBank,JFreeBnkChain
	.word	JFreeBank,JClearBank
	.word	JClearBWindow,JDoSuperMove
	.word	JDecTo32,JHexTo32
	.word	JD32div,JMult24
	.word	JMult32,MoveVData
	.word	StashVRam,FetchVRam
	.word	CkRecv,CheckDCD
	.word	OpenModem,DefSLSettings
	.word	HorizontalLine,Rectangle
	.word	FrameRectangle,SetPattern
	.word	PutChar,UseSystemFont
	.word	BBMult,BMult
	.word	DMult,Ddiv
	.word	Dabs,Dnegate
	.word	MoveData,GetRandom
	.word	MouseUp,MouseOff
	.word	GetRealSize,InitTextPrompt
	.word	LoadCharSet,PutBlock
	.word	GetFreeDirBlk,BlkAlloc
	.word	ReadFile,EnterTurbo
	.word	ReadBlock,GetDirHead
	.word	PutDirHead,InitForIO
	.word	DoneWithIO,SetNextFree
	.word	PromptOn,PromptOff
	.word	OpenDisk,TempHideMouse
	.word	ColorRectangle,ConvToCards
	.word	GetOffPgTS,RdBlkDskBuf
	.word	WrBlkDskBuf,ReadLink
	.word	SendPPPFrame,Disconnect
	.word	FetchFSegment


DivBy3:
	sta	routNum+1
	lda	#0
	.byte	0
	ldx	#16
	.byte	0
 20$
	asl	routNum+1
	rol	a
	cmp	#3
	.byte	0
	bcc	50$
	sbc	#3
	.byte	0
	inc	routNum+1
 50$
	dex
	bne	20$
routNum:
	lda	#0	;this changes.
	.byte	0
	rts

JSLPrg2Bank:
	sta	PB5+1
	php
	pla
	sta	PB4+1
	pla
	sec
	sbc	#[(prgBnkRoutines+2)
	clc
	adc	#[LPrgBase
	sta	PB6+1
	lda	#]LPrgBase
	adc	#0
	sta	PB6+2
	pla		;throw this away.
	MoveB	prg2Bank,PB6+3
	pha
	plb
PB4:
	lda	#0
	pha
PB5:
	lda	#0
	plp
PB6:
	jsl	LPrgBase,0	;this changes.
;	sta	PB8+1
	.byte	$8f,[(PB8+1),](PB8+1),0
	php
	pla
;	sta	PB7+1
	.byte	$8f,[(PB7+1),](PB7+1),0
	lda	#0
	pha
	plb
PB7:
	lda	#0
	pha		;this changes.
PB8:
	lda	#0	;this changes.
	plp
	rts

GetExtRoutine:
	sta	GER5+1
	php
	PopB	GER4+1
	stx	GER6+1
	sty	GER7+1
	jsr	SaveR0R9
	pla
	sec
	sbc	#[(ext0Table+2)
	sta	r4L
	pla
	sbc	#](ext0Table+2)
	sta	r4H
	LoadW	r1,#3
	ldx	#r4
	ldy	#r1
	jsr	Ddiv
	ldx	r4L
	lda	jmpOffsTable,x
	sta	GER8+1
	lda	modNumTable,x
	asl	a
	asl	a
	sta	r4H
	LoadB	r5L,#]ExtTable
	MoveB	prgBank,r5H
	ldy	#3
 20$
;	lda	[r4H],y
	.byte	$b7,r4H
	sta	extAddress,y
	dey
	bpl	20$
	jsr	JSuperSwap
	jsr	RstrR0R9
GER4:
	lda	#0	;this changes.
	pha
GER5:
	lda	#0	;this changes.
GER6:
	ldx	#0	;this changes.
GER7:
	ldy	#0	;this changes.
	plp
GER8:
	jsr	ER	;this changes.
	sta	GER10+1
	php
	PopB	GER9+1
	stx	GER11+1
	sty	GER12+1
	jsr	SaveR0R9
	jsr	JSuperSwap
	jsr	RstrR0R9
;continued next page...

GER9:
	lda	#0	;this changes.
	pha
GER10:
	lda	#0	;this changes.
GER11:
	ldx	#0	;this changes.
GER12:
	ldy	#0	;this changes.
	plp
	rts

JSuperSwap:
	MoveW	extAddress,r0
	MoveB	prgBank,r1L
	LoadW	r1H,#ER
	LoadB	r2H,#0
	rep	%00010000
	ldy	#[0
	.byte	]0
 10$
;	lda	[r0],y
	.byte	$b7,r0
	tax
;	lda	[r1H],y
	.byte	$b7,r1H
;	sta	[r0],y
	.byte	$97,r0
	txa
;	sta	[r1H],y
	.byte	$97,r1H
	iny
	cpy	extSize
	bcc	10$
	sep	%00010000
	rts

SaveR0R9:
	ldx	#19
 10$
	lda	r0,x
	sta	r0R9Save,x
	dex
	bpl	10$
	rts

RstrR0R9:
	ldx	#19
 10$
	lda	r0R9Save,x
	sta	r0,x
	dex
	bpl	10$
	rts


;these 2 must remain together.
extAddress:
	.block	2
extSize:
	.block	2

r0R9Save:
	.block	20

modNumTable:
	.byte	0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte	1,1,1,1,1
	.byte	2,2,2,2,2
jmpOffsTable:
	.byte	0,3,6,9,12,15,18,21,24,27,30,33,36
	.byte	0,3,6,9,12
	.byte	0,3,6,9,12


;use this to jsr to an extended routine from any
;other bank using the jump tables that call this.
SuperExtRoutine:
;	sta	SER5+1
	.byte	$8f,[(SER5+1),](SER5+1),0
	php
	pla
;	sta	SER4+1
	.byte	$8f,[(SER4+1),](SER4+1),0
	txa
;	sta	SER6+1
	.byte	$8f,[(SER6+1),](SER6+1),0
	tya
;	sta	SER7+1
	.byte	$8f,[(SER7+1),](SER7+1),0
	pla
;	sta	SER1+1
	.byte	$8f,[(SER1+1),](SER1+1),0
	pla
;	sta	SER1+2
	.byte	$8f,[(SER1+2),](SER1+2),0
	phb
;	phk
	.byte	$4b
	plb
	rep	%00110000	;16 bit a,x,y.
	sec
SER1:
	lda	#0	;this changes.
	.byte	0	;16 bit acc.
	sbc	#[(ext1Table+2)
	.byte	](ext1Table+2)
	jsr	DivBy3
	asl	a
	tax
	lda	seTable,x
	sta	SER8+1
	sep	%00110000
SER4:
	lda	#0	;this changes.
	pha
SER5:
	lda	#0	;this changes.
SER6:
	ldx	#0	;this changes.
SER7:
	ldy	#0	;this changes.
	plp
SER8:
	jsr	GetAnyFile	;this changes.
	sta	SER10+1
	php
	PopB	SER9+1
	plb
SER9:
	lda	#0	;this changes.
	pha
SER10:
	lda	#0	;this changes.
	plp
	rtl


seTable:
	.word	SwIf80
	.word	DoDeskAccessories,DoApplication
	.word	XModSend,XModRecv
	.word	SSelProtocol,SvHTMLBuffer
	.word	DownHTTP,GetWrDocument,GetNonGEOS
	.word	GetAnyFile
	.word	GetAppFile,GetDAFile

	.word	BrowseMsg,ClrMsgBox
	.word	DoMsgDB,DoDiskError
	.word	DoSelBox

	.word	ISPDir,BBSDir,InetSession,BeginISP
	.word	DoTrmMode

JDoBrowser:
	lda	waveRunning
	and	#%10111111
	sta	waveRunning
	jsr	ClearScreen
	lda	#2
	jmp	JmpModBase

JReDoBrowser:
	lda	waveRunning
	and	#%10111111
	sta	waveRunning
	jsr	ClearScreen
	lda	#2
	jsr	LoadModule
	jmp	ReStartBrowser

JESelProtocol:
	PushW	extAddress
	PushW	extSize
	jsr	JSuperSwap
	jsr	SelProtocol
	php
	sta	JES4+1
	PopB	JES3+1
	PopW	extSize
	PopW	extAddress
	jsr	JSuperSwap
JES3:
	lda	#0	;this changes.
	pha
JES4:
	lda	#0	;this changes.
	plp
	rts

JEDoMdmSettings:
	ldx	#1
JEDoSelBox:
	stx	JED2+1
	PushW	extAddress
	PushW	extSize
	jsr	JSuperSwap
JED2:
	ldx	#0	;this changes.
	jsr	DoSelBox
	php
	sta	JED4+1
	PopB	JED3+1
	PopW	extSize
	PopW	extAddress
	jsr	JSuperSwap
JED3:
	lda	#0	;this changes.
	pha
JED4:
	lda	#0	;this changes.
	plp
	rts

