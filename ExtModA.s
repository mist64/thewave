;************************************************************

;		ExtModA


;************************************************************


	.psect


;this is a 256 byte table of routine
;addresses and routine sizes.

ExtRTable:
;0
	.word	FReqRoutines	;file requestor routines.
	.word	endFReq-FReqRoutines
;1
	.word	MsgRoutines	;all message routines with messages.
	.word	endMsgs-MsgRoutines
;2
	.word	PhDirRoutines	;ISP and BBS directory routines.
	.word	endPhDir-PhDirRoutines

addFillBytes:
	.block	256-[addFillBytes

;actual code starts here at $0900 in prgBank.

FReqRoutines:
.if	C64
	sec
	rts
	nop
.else
	jmp	ER+JSwIf80-FReqRoutines
.endif
	jmp	ER+JDoDeskAccessory-FReqRoutines
	jmp	ER+JDoApplication-FReqRoutines
	jmp	ER+JXModSend-FReqRoutines
	jmp	ER+JXModRecv-FReqRoutines
	jmp	ER+JSelProtocol-FReqRoutines
	jmp	ER+JSvHTMLBuffer-FReqRoutines
	jmp	ER+JDownHTTP-FReqRoutines

JGetWrDocument:
	ldx	#0
	.byte	44
JGetNonGEOS:
	ldx	#1
	.byte	44
JGetAnyFile:
	ldx	#2
	.byte	44
EGetAppFile:
	ldx	#3
	.byte	44
EGetDAFile:
	ldx	#4
	lda	ER+r7LTable-FReqRoutines,x
	sta	ER+fReqType-FReqRoutines
	lda	ER+r10LTable-FReqRoutines,x
	sta	ER+permNmString+0-FReqRoutines
	lda	ER+r10HTable-FReqRoutines,x
	sta	ER+permNmString+1-FReqRoutines
	lda	ER+drvChgTable-FReqRoutines,x
	sta	ER+drvChgFlag-FReqRoutines
GetFRequest:
	LoadB	reqFileName,#0
	jsr	ER+SetDrvIcons-FReqRoutines
	jsr	ER+SetCurDName-FReqRoutines
	MoveB	ER+fReqType-FReqRoutines,r7L
	MoveW	ER+permNmString-FReqRoutines,r10
	LoadW	r5,#reqFileName
	LoadW	r6,#ER+onDiskTxt-FReqRoutines
	LoadW	r0,#ER+GetReqBox-FReqRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	cmp	#OPEN
	beq	80$
	cmp	#DISK
	beq	60$
	cmp	#'A'
	bcc	90$
	cmp	#'D'+1
	bcs	90$
	sec
	sbc	#'A'-8
	jsr	SetDevice
	jsr	OpenDisk
	jmp	ER+GetFRequest-FReqRoutines
 60$
	jsr	ER+InsDiskRequest-FReqRoutines
	jmp	ER+GetFRequest-FReqRoutines
 80$
	lda	reqFileName+0
	rts
 90$
	LoadB	reqFileName,#0
	rts


r7LTable:
	.byte	7,0,100,6,5
r10LTable:
	.byte	[(ER+writeString-FReqRoutines)
	.byte	[0,[0,[0,[0
r10HTable:
	.byte	](ER+writeString-FReqRoutines)
	.byte	]0,]0,]0,]0
drvChgTable:
	.byte	DISK,DISK,DISK,DISK,DISK
fReqType:
	.block	1
permNmString:
	.block	2
writeString:
	.byte	"Write Image",0

GetReqBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB
	.byte	DBGETFILES
	.byte	6,4
	.byte	DB_USR_ROUT
	.word	ER+PutDBTitle-FReqRoutines
	.byte	OPEN,DBI_X_2,25
	.byte	CANCEL,DBI_X_2,76
drvChgFlag:
	.byte	DISK,DBI_X_2,42
	.byte	DBUSRICON,DBI_X_2,59
	.word	ER+drvATable-FReqRoutines
	.byte	DBUSRICON,DBI_X_2+3,59
	.word	ER+drvBTable-FReqRoutines
	.byte	DBUSRICON,DBI_X_2,67
	.word	ER+drvCTable-FReqRoutines
	.byte	DBUSRICON,DBI_X_2+3,67
	.word	ER+drvDTable-FReqRoutines
	.byte	DB_USR_ROUT
	.word	ER+AppMFReq-FReqRoutines
	.byte	0


PutDBTitle:
	MoveW	r6,r0
	LoadB	r1H,#DEF_DB_TOP+12
.if	C64
	LoadW	r11,#DEF_DB_LEFT+136
.else
	LoadW	r11,#(DEF_DB_LEFT+136)*2
.endif
	jmp	PutString


AppMFReq:
	LoadW	appMain,#ER+HiliteDrv-FReqRoutines
	rts

HiliteDrv:
	lda	#0
	sta	appMain+1
	sta	appMain+0
	sec
	lda	curDrive
	sbc	#8
	asl	a
	sta	r2L
	asl	a
	clc
	adc	r2L
	tay
	ldx	#0
 10$
	lda	ER+drvITables-FReqRoutines,y
	sta	r2L,x
	iny
	inx
	cpx	#6
	bcc	10$
	jmp	InvertRectangle


drvITables:
.if	C64
	.byte	DEF_DB_TOP+59
	.byte	DEF_DB_TOP+66
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+0)
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+23)

	.byte	DEF_DB_TOP+59
	.byte	DEF_DB_TOP+66
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+24)
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+47)

	.byte	DEF_DB_TOP+67
	.byte	DEF_DB_TOP+74
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+0)
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+23)

	.byte	DEF_DB_TOP+67
	.byte	DEF_DB_TOP+74
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+24)
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+47)
.else
	.byte	DEF_DB_TOP+59
	.byte	DEF_DB_TOP+66
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+0)*2
	.word	((DEF_DB_LEFT+(DBI_X_2*8)+23)*2)+1

	.byte	DEF_DB_TOP+59
	.byte	DEF_DB_TOP+66
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+24)*2
	.word	((DEF_DB_LEFT+(DBI_X_2*8)+47)*2)+1

	.byte	DEF_DB_TOP+67
	.byte	DEF_DB_TOP+74
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+0)*2
	.word	((DEF_DB_LEFT+(DBI_X_2*8)+23)*2)+1

	.byte	DEF_DB_TOP+67
	.byte	DEF_DB_TOP+74
	.word	(DEF_DB_LEFT+(DBI_X_2*8)+24)*2
	.word	((DEF_DB_LEFT+(DBI_X_2*8)+47)*2)+1
.endif



SetDrvIcons:
	PushB	curDrive
	ldx	#8
	stx	ER+tmpDrvCk-FReqRoutines
 10$
	lda	ER+drvLTable-8-FReqRoutines,x
	sta	r0L
	lda	ER+drvHTable-8-FReqRoutines,x
	sta	r0H
	ldy	#0
	tya
	sta	(r0),y
	iny
	sta	(r0),y
	txa
	jsr	SetDevice
	txa
	bne	50$
	ldx	ER+tmpDrvCk-FReqRoutines
	ldy	#0
	lda	ER+picLTable-8-FReqRoutines,x
	sta	(r0),y
	iny
	lda	ER+picHTable-8-FReqRoutines,x
	sta	(r0),y
 50$
	inc	ER+tmpDrvCk-FReqRoutines
	ldx	ER+tmpDrvCk-FReqRoutines
	cpx	#12
	bcc	10$
	pla
	jmp	SetDevice

tmpDrvCk:
	.block	1
drvLTable:
	.byte	[(ER+drvATable-FReqRoutines)
	.byte	[(ER+drvBTable-FReqRoutines)
	.byte	[(ER+drvCTable-FReqRoutines)
	.byte	[(ER+drvDTable-FReqRoutines)
drvHTable:
	.byte	](ER+drvATable-FReqRoutines)
	.byte	](ER+drvBTable-FReqRoutines)
	.byte	](ER+drvCTable-FReqRoutines)
	.byte	](ER+drvDTable-FReqRoutines)
picLTable:
	.byte	[(ER+DrvAPic-FReqRoutines)
	.byte	[(ER+DrvBPic-FReqRoutines)
	.byte	[(ER+DrvCPic-FReqRoutines)
	.byte	[(ER+DrvDPic-FReqRoutines)
picHTable:
	.byte	](ER+DrvAPic-FReqRoutines)
	.byte	](ER+DrvBPic-FReqRoutines)
	.byte	](ER+DrvCPic-FReqRoutines)
	.byte	](ER+DrvDPic-FReqRoutines)


;this copies the current disk name and truncates
;the $a0's off the end and terminates it with a
;null byte.
SetCurDName:
	ldx	#r0
	jsr	GetPtrCurDkNm
	ldy	#0
 50$
	lda	(r0),y
	beq	60$
	cmp	#$a0
	beq	60$
	sta	ER+curDName-FReqRoutines,y
	iny
	cpy	#16
	bcc	50$
 60$
	lda	#0
	sta	ER+curDName-FReqRoutines,y
	rts

onDiskTxt:
	.byte	BOLDON,"On disk:",PLAINTEXT
	.byte	GOTOXY
oDT2:
.if	C64
	.word	DEF_DB_LEFT+136
.else
	.word	(DEF_DB_LEFT+136)*2
.endif
	.byte	DEF_DB_TOP+20
curDName:
	.block	17

.if	C64
drvATable:
	.word	ER+DrvAPic-FReqRoutines
	.byte	0,0,3,8
	.word	ER+DrvASelected-FReqRoutines
drvBTable:
	.word	ER+DrvBPic-FReqRoutines
	.byte	0,0,3,8
	.word	ER+DrvBSelected-FReqRoutines
drvCTable:
	.word	ER+DrvCPic-FReqRoutines
	.byte	0,0,3,8
	.word	ER+DrvCSelected-FReqRoutines
drvDTable:
	.word	ER+DrvDPic-FReqRoutines
	.byte	0,0,3,8
	.word	ER+DrvDSelected-FReqRoutines
.else
drvATable:
	.word	ER+DrvAPic-FReqRoutines
	.byte	0,0,3|DOUBLE_B,8
	.word	ER+DrvASelected-FReqRoutines
drvBTable:
	.word	ER+DrvBPic-FReqRoutines
	.byte	0,0,3|DOUBLE_B,8
	.word	ER+DrvBSelected-FReqRoutines
drvCTable:
	.word	ER+DrvCPic-FReqRoutines
	.byte	0,0,3|DOUBLE_B,8
	.word	ER+DrvCSelected-FReqRoutines
drvDTable:
	.word	ER+DrvDPic-FReqRoutines
	.byte	0,0,3|DOUBLE_B,8
	.word	ER+DrvDSelected-FReqRoutines
.endif

DrvASelected:
	lda	#'A'
	.byte	44
DrvBSelected:
	lda	#'B'
	.byte	44
DrvCSelected:
	lda	#'C'
	.byte	44
DrvDSelected:
	lda	#'D'
	sta	sysDBData
	jmp	RstrFrmDialog

DrvAPic:


DrvBPic:


DrvCPic:


DrvDPic:



InsDiskRequest:
	jsr	ER+CkIfRemovable-FReqRoutines
	beq	10$
	rts
 10$
	LoadW	r0,#ER+insDskBox-FReqRoutines
	jmp	DoColorBox

insDskBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT,[FrameDB,]FrameDB
	.byte	DBTXTSTR,TXT_LN_X	,TXT_LN_2_Y
	.word	ER+insDiskTxt-FReqRoutines
	.byte	OK,DBI_X_2,DBI_Y_2
	.byte	0

insDiskTxt:
	.byte	BOLDON,"Insert disk in drive",PLAINTEXT,0

;if removable media, equals flag is set,
;otherwise cleared.
CkIfRemovable:
	lda	curType
	bmi	50$
	and	#%11110000
	cmp	#(TYPE_RL+$10)
	bcs	60$
	cmp	#TYPE_HD
	bcc	60$
 50$
	lda	#255
	rts
 60$
	lda	#0
	rts


JDoApplication:
	jsr	ER+EGetAppFile-FReqRoutines
	bne	10$
 5$
	clc
	rts
 10$
	jsr	ER+CkRightMode-FReqRoutines
	bcc	5$
	lda	waveRunning
	and	#%10111111
	sta	waveRunning	;indicate a transition is taking place.
.if	C128
	lda	#0
	jsr	SetColorMode
.endif
	jsr	ER+ClrScrnColors-FReqRoutines
	jsr	ClearScreen
	ldy	#16
 40$
	lda	reqFileName,y
	sta	ER+eReqFileName-FReqRoutines,y
	dey
	bpl	40$
	ldy	#[(endLdCode-LdCode)
 50$
	lda	ER+LdCode-FReqRoutines,y
	sta	$7900,y
	dey
	bpl	50$
	jmp	$7911

LdCode:
eReqFileName:
	.block	17
	jsr	SuperSwap
	jsr	OffNMIReceive
	jsr	RstrNMIInterrupts
	jsr	ClrAllAppMains
	jsr	SaveSRamVars
	jsr	SetEmulationMode
	LoadW	r0,#($7900-$0400)
	LoadW	r1,#$0400
	jsr	ClearRam
	LoadB	r0L,#%00000000
	LoadW	r6,#$7900
	jsr	GetFile
	jmp	EnterDesktop

endLdCode:


JDoDeskAccessories:
	jsr	ER+EGetDAFile-FReqRoutines
	bne	10$
 5$
	clc
	rts
 10$
	jsr	ER+CkRightMode-FReqRoutines
	bcc	5$
	lda	waveRunning
	and	#%10111111
	sta	waveRunning	;indicate a transition is taking place.
;	jsr	ER+ClrScrnColors-FReqRoutines
	MoveB	nmiSet,ER+nmiDASet-FReqRoutines
	jsr	OffNMIReceive
	jsr	RstrNMIInterrupts
	jsr	SetEmulationMode
	LoadB	r0L,#%00000000
	LoadW	r6,#reqFileName
	jsr	GetFile
	jsr	SetNativeMode
	bit	ER+nmiDASet-FReqRoutines
	bpl	50$
	jsr	SetNMIInterrupts
	jsr	OnNMIReceive
 50$
	lda	waveRunning
	ora	#%01000000
	sta	waveRunning	;indicate a browser or terminal is running again.
	sec
	rts

nmiDASet:
	.block	1


CkRightMode:
	LoadW	r6,#reqFileName
	jsr	FindFile
	LoadW	r9,#dirEntryBuf
	jsr	GetFHdrInfo
	lda	fileHeader+96
.if	C64
	cmp	#$20
	beq	30$
	cmp	#$60
	beq	30$
	cmp	#$c0
	beq	30$
	sec
	rts
 30$
	jmp	ER+WrongMode-FReqRoutines
.else
	jmp	ER+CkForScrSwitch-FReqRoutines
.endif

ClrScrnColors:
	LoadB	r1L,#0
	sta	r1H
.if	C64
	LoadB	r2L,#40
.else
	lda	#40
	bit	graphicsMode
	bpl	50$
	asl	a
 50$
	sta	r2L
.endif
	LoadB	r2H,#25
	MoveB	screencolors,r4H
	jmp	ColorRectangle


.if	C128
CkForScrSwitch:
	cmp	#$80
	bne	20$
	jmp	ER+WrongMode-FReqRoutines
 20$
	cmp	#$40
	beq	25$
	cmp	#$60
	beq	25$
	cmp	#$c0
	bne	30$
 25$
	sec
	rts
 30$
;fall through...
Switch40:
	LoadB	ER+sw8040Txt-FReqRoutines,#'4'
SWITCH2:
	LoadW	r0,#ER+swBox-FReqRoutines
	jsr	DoColorBox
	cmp	#OK
	beq	30$
	clc
	rts
 30$
	lda	#0
	jsr	SetColorMode
	lda	graphicsMode
	eor	#%10000000
	sta	graphicsMode
	jsr	SetNewMode
	sec
	rts

JSwIf80:
	bit	graphicsMode
	bpl	10$
	sec
	rts
 10$
;fall through...
Switch80:
	LoadB	ER+sw8040Txt-FReqRoutines,#'8'
	jmp	ER+SWITCH2-FReqRoutines


swBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT,[FrameDB,]FrameDB
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	ER+swTxt-FReqRoutines
	.byte	OK,DBI_X_0,DBI_Y_2
	.byte	CANCEL,DBI_X_2,DBI_Y_2
	.byte	0

swTxt:
	.byte	BOLDON,"Switch monitor to "
sw8040Txt:
	.byte	"80 col.",0

.endif

WrongMode:
	LoadW	r0,#ER+wrModeBox-FReqRoutines
	jsr	DoColorBox
	clc
	rts

wrModeBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT,[FrameDB,]FrameDB
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	ER+wrModeTxt-FReqRoutines
	.byte	CANCEL,DBI_X_2,DBI_Y_2
	.byte	0

wrModeTxt:
.if	C64
	.byte	"Application is 128 only",0
.else
	.byte	"Application is 64 only",0
.endif


JSvHTMLBuffer:
	jsr	ER+GetDstFName-FReqRoutines
	bcs	10$
	rts
 10$
	ldy	#0
;	lda	[a0],y
	.byte	$b7,a0
	pha
	iny
;	lda	[a0],y
	.byte	$b7,a0
	pha
	ldy	#5
	ldx	#0
 40$
;	lda	[a0],y
	.byte	$b7,a0
	sta	r2,x
	iny
	inx
	cpx	#3
	bcc	40$
	PopB	a0H
	PopB	a0L
	jsr	ER+Pnt2XFName-FReqRoutines
	jmp	LWrBigBuffer

Pnt2XFName:
	LoadW	r0,#xFileName
	LoadB	r1L,#0
	rts

GetDstFName:
	LoadB	xFileName+0,#0
GDFN2:
 10$
	jsr	ER+EnterXName-FReqRoutines
	beq	90$
 15$
	jsr	ER+SelDestDir-FReqRoutines
	bcc	90$
	jsr	OpenDisk
	LoadW	r6,#xFileName
	jsr	FindFile
	txa
	bne	30$
	LoadW	r0,#ER+xExistBox-FReqRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	cmp	#21
	beq	10$
	cmp	#22
	beq	15$
	cmp	#20
	bne	90$
	jsr	ER+Pnt2XFName-FReqRoutines
	jsr	DeleteFile
;+++show error here such as write-protect on, etc.
 30$
	sec
	rts
 90$
	clc
	rts


JDownHTTP:
	lda	xFileName+0
	bne	10$
	jsr	ER+CopyURLFName-FReqRoutines
	jsr	ER+GDFN2-FReqRoutines
	bcc	90$
 10$
	jsr	GetNewBank
	bcc	90$
	stx	a1L
	LoadB	dloadFlag,#%10000000
	jsr	ER+Pnt2XFName-FReqRoutines
	jsr	DeleteFile
	jsr	ER+Pnt2XFName-FReqRoutines
	jsr	LStartHTTP
	php
	pha
	ldx	a1L
	jsr	FreeBank
	pla
	plp
	bcc	90$
	and	#%01000000
	beq	89$
	clc
	rts
 89$
	jsr	DoBeep
 90$
	sec
	rts



CopyURLFName:
	LoadW	r0,#pathField
	MoveB	prg2Bank,r1L
	ldy	#0
	sty	xFileName+0
 5$
;	lda	[r0],y
	.byte	$b7,r0
	beq	10$
	iny
	cpy	#160
	bcc	5$
 10$
	tya
	beq	90$
	dey
 20$
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#'/'
	beq	30$
	dey
	cpy	#255
	bne	20$
 30$
	iny
	ldx	#0
 40$
;	lda	[r0],y
	.byte	$b7,r0
	sta	xFileName,x
	iny
	inx
	cpx	#16
	bcc	40$
 90$
	rts

JXModRecv:
	jsr	ER+JSelProtocol-FReqRoutines
	bcc	90$
	lda	desProtocol
	beq	90$	;ascii mode not ready.
	cmp	#4
	beq	50$	;branch if ymodem. (4)
	bcs	90$	;branch if anything else not supported yet.
	LoadB	xFileName+0,#0
 10$
	jsr	ER+EnterXName-FReqRoutines
	beq	90$
 15$
	jsr	ER+SelDestDir-FReqRoutines
	bcc	90$
	jsr	OpenDisk
	LoadW	r6,#xFileName
	jsr	FindFile
	txa
	bne	40$
	LoadW	r0,#ER+xExistBox-FReqRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	cmp	#21
	beq	10$
	cmp	#22
	beq	15$
	cmp	#20
	bne	90$
	jsr	ER+Pnt2XFName-FReqRoutines
	jsr	DeleteFile
;+++show error here such as write-protect on, etc.
 40$
	jsr	LSaveTxtScreen
	jsr	ER+Pnt2XFName-FReqRoutines
	jsr	LRecvXModem
	jsr	DoBeep
	jmp	LRstrTxtScreen
 50$
	jsr	ER+SelDestDir-FReqRoutines
	bcc	90$
	jsr	OpenDisk
	jsr	LSaveTxtScreen
	jsr	LRecvYModem
	jsr	DoBeep
	jmp	LRstrTxtScreen
 90$
	clc
	rts


;this pops up a DB asking the user to enter a filename.
;Equals flag is cleared if a name was entered.
EnterXName:
	LoadW	r5,#xFileName
	LoadW	r0,#ER+xNameBox-FReqRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	lda	xFileName+0
 90$
	rts

xNameBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	ER+saveXTxt-FReqRoutines

	.byte	DBGETSTRING,TXT_LN_X,TXT_LN_3_Y
	.byte	r5,16

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0

saveXTxt:
	.byte	BOLDON,"Enter a name to save as:",PLAINTEXT,0


ovrWrClicked:
	lda	#20
	.byte	44
diffNmClicked:
	lda	#21
	.byte	44
useDifClicked:
	lda	#22
	sta	sysDBData
	jmp	RstrFrmDialog

xExistBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,20
	.word	ER+fNmExTxt-FReqRoutines

	.byte	DBUSRICON
	.byte	4,31
	.word	ER+ovrWrTable-FReqRoutines
	.byte	DBTXTSTR,52,37
	.word	ER+ovrWrTxt-FReqRoutines

	.byte	DBUSRICON
	.byte	4,43
	.word	ER+diffNmTable-FReqRoutines
	.byte	DBTXTSTR,52,49
	.word	ER+diffNmTxt-FReqRoutines

	.byte	DBUSRICON
	.byte	4,55
	.word	ER+useDifTable-FReqRoutines
	.byte	DBTXTSTR,52,61
	.word	ER+useDifTxt-FReqRoutines

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0


fNmExTxt:
	.byte	BOLDON,"Filename exists!!!",PLAINTEXT,0

ovrWrTable:
	.word	ER+butnPic-FReqRoutines
	.byte	4,31
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+ovrWrClicked-FReqRoutines

ovrWrTxt:
	.byte	"Overwrite existing file",0

diffNmTable:
	.word	ER+butnPic-FReqRoutines
	.byte	4,43
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+diffNmClicked-FReqRoutines

diffNmTxt:
	.byte	"Enter a different name",0

useDifTable:
	.word	ER+butnPic-FReqRoutines
	.byte	4,55
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+useDifClicked-FReqRoutines

useDifTxt:
	.byte	"Use a different directory",0

butnPic:


JXModSend:
	jsr	ER+JSelProtocol-FReqRoutines
	bcc	90$
	jsr	ER+JGetNonGEOS-FReqRoutines
	lda	reqFileName+0
	beq	90$
	LoadW	r6,#reqFileName
	jsr	FindFile
	txa
	bne	90$
	lda	desProtocol
	beq	90$	;ascii mode not ready.
	cmp	#4
	beq	50$	;branch if ymodem. (4)
	bcs	90$	;branch if anything else not supported yet.
	jsr	LSaveTxtScreen
	jsr	LSendXModem
	jsr	DoBeep
	jmp	LRstrTxtScreen
 50$
	jsr	LSaveTxtScreen
	jsr	LSendYModem
	LoadB	dirEntryBuf+0,#0
	sta	dirEntryBuf+1
	sta	dirEntryBuf+2	;indicate no more files.
	jsr	LSendYModem	;send final null packet.
	jsr	DoBeep
	jmp	LRstrTxtScreen
 90$
	clc
	rts

JSelProtocol:
	LoadW	r0,#ER+protSelBox-FReqRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	sec
	rts
 90$
	clc
	rts

protSelBox:
	.byte	SET_DB_POS
	.byte	DEF_DB_TOP,DEF_DB_BOT+40
.if	C64
	.word	DEF_DB_LEFT-16,DEF_DB_RIGHT+16
.else
	.word	(DEF_DB_LEFT-16)|DOUBLE_W,(DEF_DB_RIGHT+16)|DOUBLE_W|ADD1_W
.endif

	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,16
	.word	ER+protSelTxt-FReqRoutines

	.byte	DBTXTSTR,36,32
	.word	ER+noneTxt-FReqRoutines
	.byte	DBTXTSTR,36,44
	.word	ER+xmTxt-FReqRoutines
	.byte	DBTXTSTR,36,56
	.word	ER+xmcTxt-FReqRoutines
	.byte	DBTXTSTR,36,68
	.word	ER+xm1kTxt-FReqRoutines

	.byte	DBTXTSTR,132,32
	.word	ER+ymTxt-FReqRoutines
	.byte	DBTXTSTR,132,44
	.word	ER+ymgTxt-FReqRoutines
	.byte	DBTXTSTR,132,56
	.word	ER+zmTxt-FReqRoutines
	.byte	DBTXTSTR,132,68
	.word	ER+kmTxt-FReqRoutines

	.byte	DBTXTSTR,44,84
	.word	ER+aDetTxt-FReqRoutines
	.byte	DBTXTSTR,44,96
	.word	ER+ignTmTxt-FReqRoutines

	.byte	DB_USR_ROUT
	.word	ER+PutProtIcons-FReqRoutines

	.byte	DBOPVEC
	.word	ER+CkProtClick-FReqRoutines

	.byte	OK,DBI_X_0,DBI_Y_2+40
	.byte	CANCEL,DBI_X_2,DBI_Y_2+40

	.byte	0


PutProtIcons:
	ldy	#0
 10$
	lda	ER+protLocTable-FReqRoutines,y
	sta	r1L
	lda	ER+protLocTable+1-FReqRoutines,y
	sta	r1H
.if	C64
	LoadB	r2L,#2
.else
	LoadB	r2L,#(2|DOUBLE_B)
.endif
	LoadB	r2H,#8
	phy
	LoadW	r0,#ER+btnPic-FReqRoutines
	jsr	BitmapUp
	ply
	iny
	iny
	cpy	#20
	bcc	10$
	lda	#2
	jsr	SetPattern
	lda	desProtocol
	jsr	ER+ProtHilite-FReqRoutines
	bit	autoProtocol
	bpl	30$
	lda	#8
	jsr	ER+ProtHilite-FReqRoutines
 30$
	bit	ignoreTimeouts
	bpl	50$
	lda	#9
	jsr	ER+ProtHilite-FReqRoutines
 50$
	rts

ProtHilite:
	cmp	#10	;in case of wrong value.
	bcc	10$
	rts
 10$
	asl	a
	tay
	lda	ER+protLocTable+1-FReqRoutines,y
	ina
	sta	r2L
	clc
	adc	#4
	sta	r2H
	LoadB	r3H,#0
	lda	ER+protLocTable-FReqRoutines,y
	asl	a
	rol	r3H
	asl	a
	rol	r3H
	asl	a
	rol	r3H
	ina
	sta	r3L
	bne	30$
	inc	r3H
 30$
	clc
.if	C64
	adc	#12
.else
	adc	#28
.endif
	sta	r4L
	lda	r3H
	adc	#0
	sta	r4H
	jmp	Rectangle


CkProtClick:
	bit	mouseData
	bmi	25$
	ldy	#0
 10$
	lda	ER+protLocTable+1-FReqRoutines,y
	sta	r2L
	clc
	adc	#7
	sta	r2H
	LoadB	r3H,#0
	lda	ER+protLocTable-FReqRoutines,y
	asl	a
	rol	r3H
	asl	a
	rol	r3H
	asl	a
	rol	r3H
	sta	r3L
	clc
.if	C64
	adc	#71
.else
	adc	#143
.endif
	sta	r4L
	lda	r3H
	adc	#0
	sta	r4H
	jsr	IsMseInRegion
	cmp	#[TRUE
	beq	30$
	iny
	iny
	cpy	#20
	bcc	10$
 25$
	rts
 30$
	tya
	lsr	a
	tay
	cpy	#8
	bcs	50$
	lda	ER+protSupported-FReqRoutines,y
	beq	25$	;branch if not yet supported.
	phy
	lda	#0
	jsr	SetPattern
	lda	desProtocol
	jsr	ER+ProtHilite-FReqRoutines
	lda	#2
	jsr	SetPattern
	PopB	desProtocol
	jmp	ER+ProtHilite-FReqRoutines
 50$
	cpy	#9
	beq	70$
	bcs	25$
	lda	autoProtocol
	eor	#%10000000
	sta	autoProtocol
	bmi	60$
	lda	#0
	.byte	44
 60$
	lda	#2
	jsr	SetPattern
	lda	#8
	jmp	ER+ProtHilite-FReqRoutines
 70$
	lda	ignoreTimeouts
	eor	#%10000000
	sta	ignoreTimeouts
	bmi	75$
	lda	#0
	.byte	44
 75$
	lda	#2
	jsr	SetPattern
	lda	#9
	jmp	ER+ProtHilite-FReqRoutines


;this identifies the currently supported
;protocols. Eventually, this table will
;be removed when all the protocols are implemented.
protSupported:
	.byte	0,1,1,1,1,0,0,0

protLocTable:
.if	C64
	.byte	8,58
	.byte	8,70
	.byte	8,82
	.byte	8,94
	.byte	20,58
	.byte	20,70
	.byte	20,82
	.byte	20,94

	.byte	9,110
	.byte	9,122
.else
	.byte	16,58
	.byte	16,70
	.byte	16,82
	.byte	16,94
	.byte	40,58
	.byte	40,70
	.byte	40,82
	.byte	40,94

	.byte	18,110
	.byte	18,122
.endif


protSelTxt:
	.byte	BOLDON,"Choose a transfer protocol",PLAINTEXT,0

btnPic:



noneTxt:
	.byte	ITALICON,"ASCII",PLAINTEXT,0
xmTxt:
	.byte	BOLDON,"XModem",PLAINTEXT,0
xmcTxt:
	.byte	BOLDON,"XModem-CRC",PLAINTEXT,0
xm1kTxt:
	.byte	BOLDON,"XModem-1K",PLAINTEXT,0
ymTxt:
	.byte	BOLDON,"YModem",PLAINTEXT,0
ymgTxt:
	.byte	ITALICON,"YModem-G",PLAINTEXT,0
zmTxt:
	.byte	ITALICON,"ZModem",PLAINTEXT,0
kmTxt:
	.byte	ITALICON,"Kermit",PLAINTEXT,0

aDetTxt:
	.byte	BOLDON,"Auto-detect",PLAINTEXT,0
ignTmTxt:
	.byte	BOLDON,"Ignore timeouts",PLAINTEXT,0

