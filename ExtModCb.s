;************************************************************

;		ExtModCb


;************************************************************


	.psect


JDoTrmMode:
	lda	phDirMode
	ora	commMode
	bmi	5$
	lda	#0
	.byte	44
 5$
	lda	#DBTXTSTR
	sta	ER+ecFlag-PhDirRoutines
	ldx	#6
	lda	#0
 10$
	sta	ER+tdspMap-PhDirRoutines,x
	dex
	bpl	10$
	lda	#2
	bit	vtOn
	bpl	60$
	ldx	#0
	bit	ansiOn
	bmi	15$
	ldx	#1
 15$
	sta	ER+tdspMap-PhDirRoutines,x
 20$
	ldx	#2
	bit	ansiOn
	bvc	30$
	ldx	#3
 30$
	sta	ER+tdspMap-PhDirRoutines,x
 60$
	ldx	#6
	lda	ER+ecFlag-PhDirRoutines
	bne	65$
	dex
 65$
	lda	deleteValue
 70$
	cmp	ER+delTable-4-PhDirRoutines,x
	beq	80$
	dex
	cpx	#4
	bne	70$
 80$
	lda	#2
	sta	ER+tdspMap-PhDirRoutines,x

;fall through to next page...

;previous page continues here.
JDTM2:
	LoadW	r0,#ER+trmModeBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	lda	vtOn
	and	#%01111111
	ora	#%01111111
	ldx	ER+tdspMap+0-PhDirRoutines
	bne	38$
	ldx	ER+tdspMap+1-PhDirRoutines
	beq	40$
 38$
	ora	#%10000000
 40$
	sta	vtOn
	lda	ansiOn
	and	#%00111111
	ldx	ER+tdspMap+0-PhDirRoutines
	beq	50$
	ora	#%10000000
 50$
	ldx	ER+tdspMap+2-PhDirRoutines
	bne	60$
	ora	#%01000000
 60$
	sta	ansiOn
	ldx	#6
 70$
	lda	ER+tdspMap-PhDirRoutines,x
	bne	80$
	dex
	cpx	#4
	bne	70$
 80$
	lda	ER+delTable-4-PhDirRoutines,x
	sta	deleteValue
	sec
	rts
 90$
	clc
	rts


trmModeBox:
	.byte	SET_DB_POS
	.byte	DEF_DB_TOP,DEF_DB_BOT+56
.if	C64
	.word	DEF_DB_LEFT,DEF_DB_RIGHT
.else
	.word	DEF_DB_LEFT|DOUBLE_W,DEF_DB_RIGHT|DOUBLE_W|ADD1_W
.endif

	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,16
	.word	ER+trmModeTxt-PhDirRoutines
	.byte	DBTXTSTR,36,30
	.word	ER+ansModeTxt-PhDirRoutines
	.byte	DBTXTSTR,36,42
	.word	ER+vtModeTxt-PhDirRoutines
	.byte	DBTXTSTR,36,56
	.word	ER+ansCharTxt-PhDirRoutines
	.byte	DBTXTSTR,36,68
	.word	ER+vtCharTxt-PhDirRoutines

	.byte	DBTXTSTR,24,82
	.word	ER+delSendsTxt-PhDirRoutines
	.byte	DBTXTSTR,36,96
	.word	ER+del8Txt-PhDirRoutines
	.byte	DBTXTSTR,36,108
	.word	ER+del127Text-PhDirRoutines

	.byte	DB_USR_ROUT
	.word	ER+PutTDspIcons-PhDirRoutines

	.byte	DBOPVEC
	.word	ER+CkTDspClick-PhDirRoutines

	.byte	OK,DBI_X_1,DBI_Y_2+56
	.byte	CANCEL,DBI_X_2,DBI_Y_2+56

ecFlag:
	.byte	DBTXTSTR,36,120
	.word	ER+delECTxt-PhDirRoutines

	.byte	0


PutTDspIcons:
	ldy	#0
 10$
	lda	ER+tdspLocTable+0-PhDirRoutines,y
	sta	r1L
	lda	ER+tdspLocTable+1-PhDirRoutines,y
	sta	r1H
.if	C64
	LoadB	r2L,#2
.else
	LoadB	r2L,#(2|DOUBLE_B)
.endif
	LoadB	r2H,#8
	phy
	LoadW	r0,#ER+buttonPic-PhDirRoutines
	jsr	BitmapUp
	ply
	iny
	iny
	cpy	#12
	bcc	10$
	lda	ER+ecFlag-PhDirRoutines
	beq	90$
	cpy	#14
	bcc	10$
 90$
MarkTDIcons:
	ldx	#0
 10$
	phx
	lda	ER+tdspMap-PhDirRoutines,x
	jsr	SetPattern
	pla
	pha
	jsr	ER+TDspHilite-PhDirRoutines
	plx
	inx
	cpx	#6
	bcc	10$
	lda	ER+ecFlag-PhDirRoutines
	beq	90$
	cpx	#7
	bcc	10$
 90$
	rts

tdspMap:
	.block	7

TDspHilite:
	cmp	#7	;in case of wrong value.
	bcc	10$
	rts
 10$
	asl	a
	tay
	lda	ER+tdspLocTable+1-PhDirRoutines,y
	ina
	sta	r2L
	clc
	adc	#4
	sta	r2H
	LoadB	r3H,#0
	lda	ER+tdspLocTable+0-PhDirRoutines,y
	asl	a
	rol	r3H
	asl	a
	rol	r3H
	asl	a
	rol	r3H
	ina
	bne	30$
	inc	r3H
 30$
	sta	r3L
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


CkTDspClick:
	bit	mouseData
	bmi	25$
	ldy	#0
 10$
	lda	ER+tdspLocTable+1-PhDirRoutines,y
	sta	r2L
	clc
	adc	#7
	sta	r2H
	LoadB	r3H,#0
	lda	ER+tdspLocTable+0-PhDirRoutines,y
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
	cpy	#12
	bcc	10$
	lda	ER+ecFlag-PhDirRoutines
	beq	25$
	cpy	#14
	bcc	10$
 25$
	rts
 30$
	tya
	lsr	a
	tay
	beq	50$
	cpy	#1
	beq	70$
	cpy	#4
	bcc	40$
	lda	#0
	ldx	#4
 35$
	sta	ER+tdspMap-PhDirRoutines,x
	inx
	cpx	#7
	bcc	35$
	lda	#2
	sta	ER+tdspMap-PhDirRoutines,y
	jmp	ER+MarkTDIcons-PhDirRoutines
 40$
	lda	ER+tdspMap+0-PhDirRoutines
	ora	ER+tdspMap+1-PhDirRoutines
	beq	25$
	lda	ER+tdspMap+2-PhDirRoutines
	eor	#2
	sta	ER+tdspMap+2-PhDirRoutines
	lda	ER+tdspMap+3-PhDirRoutines
	eor	#2
	sta	ER+tdspMap+3-PhDirRoutines
	jmp	ER+MarkTDIcons-PhDirRoutines
;branch here if ansi mode clicked.
 50$
	lda	ER+tdspMap+0-PhDirRoutines
	eor	#2
	sta	ER+tdspMap+0-PhDirRoutines
	beq	80$
	lda	#0
	sta	ER+tdspMap+1-PhDirRoutines
	beq	80$
;branch here if vt-102 mode clicked.
 70$
	lda	ER+tdspMap+1-PhDirRoutines
	eor	#2
	sta	ER+tdspMap+1-PhDirRoutines
	beq	80$
	lda	#0
	sta	ER+tdspMap+0-PhDirRoutines
 80$
	lda	ER+tdspMap+0-PhDirRoutines
	sta	ER+tdspMap+2-PhDirRoutines
	lda	ER+tdspMap+1-PhDirRoutines
	sta	ER+tdspMap+3-PhDirRoutines
	jmp	ER+MarkTDIcons-PhDirRoutines

tdspLocTable:
.if	C64
	.byte	10,56
	.byte	10,68
	.byte	10,82
	.byte	10,94
	.byte	10,122
	.byte	10,134
	.byte	10,146
.else
	.byte	20,56
	.byte	20,68
	.byte	20,82
	.byte	20,94
	.byte	20,122
	.byte	20,134
	.byte	20,146
.endif

delTable:
	.byte	8,127,255

trmModeTxt:
	.byte	BOLDON,"Configure the display",PLAINTEXT,0

ansModeTxt:
	.byte	BOLDON,"ANSI mode",PLAINTEXT,0
vtModeTxt:
	.byte	BOLDON,"VT102 mode",PLAINTEXT,0
ansCharTxt:
	.byte	BOLDON,"ANSI characters",PLAINTEXT,0
vtCharTxt:
	.byte	BOLDON,"VT-102 characters",PLAINTEXT,0

delSendsTxt:
	.byte	BOLDON,"DELETE key sends:",PLAINTEXT,0

del8Txt:
	.byte	BOLDON,"Decimal 8",PLAINTEXT,0
del127Text:
	.byte	BOLDON,"Decimal 127",PLAINTEXT,0
delECTxt:
	.byte	BOLDON,"Telnet EC",PLAINTEXT,0


Connect:
	jsr	LDialOut
	bcc	90$
	bit	manualLogin	;are we doing a manual login?
	bmi	80$	;branch if so and skip the session DB for now.
	bit	commMode	;did a PPP connection get made?
	bpl	80$	;branch if not.
	bit	waveRunning	;was this called from the browser?
	bmi	80$	;branch if so.
	jsr	ER+DoInetDB-PhDirRoutines
	bcc	90$
	jsr	ER+DoInetAddress-PhDirRoutines
	lda	hostName+0
	beq	90$
 80$
	sec
	rts
 90$
	clc
	rts

JBeginISP:
	LoadB	phDirMode,#%10000000
	jsr	ER+IsOneISP-PhDirRoutines ;is there exactly one ISP?
	bcc	50$	;branch if not.
	rts
 50$
	jmp	ER+ISPDir-PhDirRoutines


JInetSession:
	LoadB	hostName+0,#0
	LoadB	phDirMode,#%10000000
	jsr	ER+DoInetDB-PhDirRoutines
	bcc	90$
	jsr	ER+DoInetAddress-PhDirRoutines
	lda	hostName+0
	beq	90$
;+++keep track of telnet,ftp,irc here.
;+++only telnet is used right now.
	lda	tcpOpen
	beq	60$
	bit	commMode
	bpl	50$
	jsr	LClsTCPConnection
 50$
	LoadB	tcpOpen,#%00000000
 60$
	bit	commMode
	bmi	80$
	jsr	ER+IsOneISP-PhDirRoutines ;is there exactly one ISP?
	bcs	70$	;branch if so and dial out.
	jsr	ER+ISPDir-PhDirRoutines
	bcc	90$
 70$
	jsr	LDialOut
	bcc	90$
 80$
	sec
	rts
 90$
	LoadB	phDirMode,#%00000000
	clc
	rts

DoInetDB:
	lda	#0
	bit	commMode
	bpl	10$
	lda	#DBUSRICON
 10$
	sta	ER+hangButton-PhDirRoutines
	LoadW	r0,#ER+inetBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
;+++only 20 (telnet) is checked at this time.
	cmp	#20
	bne	70$
	sec
	rts
 70$
	cmp	#23	;hanging up is allowed.
	bne	90$
	ldx	#3
	ldy	#1
	jsr	LURLBarMsg	;display "Disconnecting..."
	jsr	Disconnect
	jsr	LRstrTxtScreen
	jsr	DefSLSettings
 90$
	clc
	rts


inetBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,20
	.word	ER+inetTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,31
	.word	ER+tnetTable-PhDirRoutines
	.byte	DBTXTSTR,52,37
	.word	ER+tnetTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,43
	.word	ER+ftpTable-PhDirRoutines
	.byte	DBTXTSTR,52,49
	.word	ER+ftpTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,55
	.word	ER+ircTable-PhDirRoutines
	.byte	DBTXTSTR,52,61
	.word	ER+ircTxt-PhDirRoutines

	.byte	CANCEL,DBI_X_2,DBI_Y_2

hangButton:
	.byte	DBUSRICON
	.byte	4,71
	.word	ER+hangTable-PhDirRoutines
	.byte	DBTXTSTR,52,77
	.word	ER+hangTxt-PhDirRoutines

	.byte	0


inetTxt:
	.byte	BOLDON,"Choose an Internet session",PLAINTEXT,0


buttonPic:


tnetTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+TNetClicked-PhDirRoutines

tnetTxt:
	.byte	BOLDON,"Telnet",PLAINTEXT,0

ftpTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+FTPClicked-PhDirRoutines

ftpTxt:
	.byte	ITALICON,"FTP",PLAINTEXT,0

ircTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+IRCClicked-PhDirRoutines

ircTxt:
	.byte	ITALICON,"IRC",PLAINTEXT,0

hangTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+HangClicked-PhDirRoutines

hangTxt:
	.byte	BOLDON,"Hang up",PLAINTEXT,0

TNetClicked:
	lda	#20
	.byte	44
FTPClicked:
	lda	#21
	.byte	44
IRCClicked:
	lda	#22
	.byte	44
HangClicked:
	lda	#23
	sta	sysDBData
	jmp	RstrFrmDialog

DoInetAddress:
	ldx	#3
	jsr	SetNewDir
	jsr	OpenPrgDir
	jsr	ER+LdTnetHistory-PhDirRoutines
 10$
	LoadB	hostName+0,#0
	sta	ER+tnetName+0-PhDirRoutines
	jsr	ER+PntA0XMod-PhDirRoutines
	LoadB	r10L,#0	;+++this might not be needed.
	sta	r10H
	LoadW	r5,#ER+Get1stTNet-PhDirRoutines
	LoadB	r7L,#(128|32)
	LoadW	r6,#ER+tnetName+0-PhDirRoutines
	LoadW	r0,#ER+tnetAdrBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	ldx	hostName+0
	beq	60$
	cmp	#OPEN
	beq	80$
	cmp	#41
	bne	40$
	LoadW	r0,#ER+rmPhBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#OK
	bne	10$
	jsr	ER+RmNmEntry-PhDirRoutines
	jsr	ER+SvTnetHistory-PhDirRoutines
	bra	10$
 40$
	cmp	#40
	bne	60$
	jsr	ER+EditNmEntry-PhDirRoutines
	jsr	ER+SvTnetHistory-PhDirRoutines
	bra	10$
 60$
	lda	ER+tnetName+0-PhDirRoutines
	beq	90$
	ldy	#0
 70$
	lda	ER+tnetName-PhDirRoutines,y
	sta	hostName,y
	beq	80$
	iny
	cpy	#32
	bcc	70$
	lda	#0
	sta	hostName,y
 80$
	jsr	ER+InsHostName-PhDirRoutines
	bcc	85$
	jsr	ER+SvTnetHistory-PhDirRoutines
 85$
	jsr	OpenSavDir
	sec
	rts
 90$
	jsr	OpenSavDir
	LoadB	hostName+0,#0
	clc
	rts



LdTnetHistory:
	jsr	ER+PntA0XMod-PhDirRoutines
	rep	%00110000
	lda	#[0
	.byte	]0
	ldy	#[1022
	.byte	]1022
 10$
;	sta	[a0],y
	.byte	$97,a0
	dey
	dey
	bpl	10$
	sep	%00110000
	LoadW	r6,#ER+wHistName-PhDirRoutines
	jsr	FindFile
	txa
	bne	30$
	MoveB	dirEntryBuf+20,r1H
	MoveB	dirEntryBuf+19,r1L
	beq	30$
	LoadW	r4,#fileHeader
	jsr	GetBlock
	bne	30$
	LoadW	r0,#ER+histHeader+77-PhDirRoutines
	LoadW	r1,#fileHeader+77
	ldx	#r0
	ldy	#r1
	jsr	CmpString
	bne	30$
	MoveB	dirEntryBuf+2,r1H
	MoveB	dirEntryBuf+1,r1L
	jsr	GetBlock
	beq	40$
 30$
	jmp	ER+MakeHstFile-PhDirRoutines
 40$
	MoveB	fileHeader+2,r1L
	beq	90$
	MoveB	fileHeader+3,r1H
	LoadB	r5L,#0
	sta	r5H
	LoadW	r4,#diskBlkBuf
 50$
	jsr	ReadByte
	cpx	#0
	bne	80$
;	sta	[a0]
	.byte	$87,a0
	inc	a0L
	bne	70$
	inc	a0H
 70$
	CmpWI	a0,#xModBuffer+1015
	bcc	50$
 80$
	lda	#0
;	sta	[a0]
	.byte	$87,a0
 90$
	rts

PntA0XMod:
	LoadW	a0,#xModBuffer
	MoveB	prg2Bank,a1L
	rts

SvTnetHistory:
	LoadW	r0,#ER+wHistName-PhDirRoutines
	jsr	OpenRecordFile
	txa
	bne	90$	;branch if history file not available.
	lda	#0
	jsr	PointRecord
	jsr	ER+SwapXModBuf-PhDirRoutines
	rep	%00010000
	ldx	#[0
	.byte	]0
 20$
;	lda	$003000,x
	.byte	$bf,[$3000,]$3000,0
	beq	60$
 30$
	inx
;	lda	$003000,x
	.byte	$bf,[$3000,]$3000,0
	bne	30$
	inx
	inx
	inx
	inx
	inx
	inx
	inx
	cpx	#[1023
	.byte	]1023
	bcc	20$
 60$
	inx
	stx	r2
	sep	%00010000
	LoadW	r7,#$3000
	jsr	WriteRecord
	jsr	CloseRecordFile
	jsr	ER+SwapXModBuf-PhDirRoutines
 90$
	rts

SwapXModBuf:
	LoadW	r0,#xModBuffer
	MoveB	prg2Bank,r1L
	LoadW	r1H,#$3000
	LoadB	r2H,#0
	rep	%00010000
	ldy	#[1023
	.byte	]1023
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
	dey
	bpl	10$
	sep	%00010000
	rts

;this will insert the string at hostName into the
;buffer at xModBuffer. If the name is already the
;first name, the carry will be clear indicating
;the buffer does not need to be updated to disk.
InsHostName:
	jsr	ER+PntA0XMod-PhDirRoutines
;	lda	[a0]
	.byte	$a7,a0	;is the buffer empty?
	bne	30$	;branch if not.
	jsr	ER+EdTNetOptions-PhDirRoutines
	bra	62$
 30$
	jsr	ER+FindNmString-PhDirRoutines
	bcs	40$
	jsr	ER+EdTNetOptions-PhDirRoutines
	bra	50$
 40$
	jsr	ER+Y2Options-PhDirRoutines
	ldx	#0
 46$
;	lda	[a0],y
	.byte	$b7,a0
	sta	vtOn,x
	iny
	inx
	cpx	#6
	bcc	46$
	CmpWI	a0,#xModBuffer	;already the first name?
	bne	50$	;branch if not.
	clc
	rts
 50$
	sec
	lda	a0L
	sbc	#[xModBuffer
	sta	r2L
	lda	a0H
	sbc	#]xModBuffer
	sta	r2H
	LoadW	r0,#xModBuffer
	MoveB	prg2Bank,r3L
	sta	r3H
	ldy	#0
 55$
	lda	hostName,y
	beq	60$
	iny
	cpy	#31
	bcc	55$
 60$
	iny
	tya
	clc
	adc	#6
	adc	r0L
	sta	r1L
	lda	r0H
	adc	#0
	sta	r1H
	jsr	DoSuperMove
 62$
	jsr	ER+PntA0XMod-PhDirRoutines
	ldy	#0
 65$
	lda	hostName,y
;	sta	[a0],y
	.byte	$97,a0
	beq	70$
	iny
	bne	65$
 70$
	jsr	ER+StrTNOptions-PhDirRoutines
	sec
	rts

GetTNOptions:
	jsr	ER+Y2Options-PhDirRoutines
	ldx	#0
 75$
;	lda	[a0],y
	.byte	$b7,a0
	sta	vtOn,x
	iny
	inx
	cpx	#6
	bcc	75$
	rts

StrTNOptions:
	jsr	ER+Y2Options-PhDirRoutines
	ldx	#0
 75$
	lda	vtOn,x
;	sta	[a0],y
	.byte	$97,a0
	iny
	inx
	cpx	#6
	bcc	75$
	rts

Y2Options:
	ldy	#0
 42$
;	lda	[a0],y
	.byte	$b7,a0
	beq	45$
	iny
	cpy	#31
	bcc	42$
 45$
	iny
	rts

FindNmString:
	jsr	ER+PntA0XMod-PhDirRoutines
 10$
	jsr	ER+CmpNmString-PhDirRoutines
	bcs	50$
 30$
	CmpWI	a0,#xModBuffer+1016-38
	bcc	40$
	lda	#0
 35$
;	sta	[a0],y
	.byte	$97,a0	;delete the last name.
	dey
	bpl	35$
	clc
	rts
 40$
	jsr	ER+AddYA0-PhDirRoutines
;	lda	[a0]
	.byte	$a7,a0	;end of buffer?
	bne	10$	;branch if not.
	clc
 50$
	rts

AddYA0:
	lda	#6
	jsr	ER+AddA2A0-PhDirRoutines
	iny
	tya
AddA2A0:
	clc
	adc	a0L
	sta	a0L
	bcc	20$
	inc	a0H
 20$
	rts

EditNmEntry:
	ldx	#0
 10$
	lda	vtOn,x
	pha
	inx
	cpx	#6
	bcc	10$
	jsr	ER+FindNmString-PhDirRoutines
	jsr	ER+GetTNOptions-PhDirRoutines
	jsr	ER+JDoTrmMode-PhDirRoutines
	bcc	75$
	jsr	ESelProtocol
	bcc	75$
	jsr	ER+FindNmString-PhDirRoutines
	jsr	ER+StrTNOptions-PhDirRoutines
 75$
	ldx	#5
 80$
	pla
	sta	vtOn,x
	dex
	bpl	80$
	rts

EdTNetOptions:
	jsr	ER+JDoTrmMode-PhDirRoutines
	jsr	ESelProtocol
	rts

RmNmEntry:
	jsr	ER+FindNmString-PhDirRoutines
	MoveW	a0,r1
	MoveB	a1L,r3L
	sta	r3H
	iny
	tya
	clc
	adc	#6
	adc	r1L
	sta	r0L
	lda	r1H
	adc	#0
	sta	r0H
	rep	%00100000
	lda	#[(xModBuffer+1016)
	.byte	](xModBuffer+1016)
	sec
	sbc	r0
	sta	r2
	sep	%00100000
	jmp	DoSuperMove

;this compares the string that a0-a1L points at
;to the string at hostName. Carry is set if they
;match. The y register is left pointing at the
;null terminator in the a0 string.
CmpNmString:
	ldy	#0
 10$
;	lda	[a0],y
	.byte	$b7,a0
	beq	80$
	cmp	hostName,y
	bne	90$
	iny
	cpy	#32
	bcc	10$
	clc
	rts
 80$
	cmp	hostName,y
	bne	90$
	sec
	rts
 90$
;	lda	[a0],y
	.byte	$b7,a0
	beq	95$
	iny
	cpy	#32
	bcc	90$
 95$
	clc
	rts

tnetAdrBox:
	.byte	SET_DB_POS
	.byte	DEF_DB_TOP,DEF_DB_BOT+40
.if	C64
	.word	DEF_DB_LEFT,DEF_DB_RIGHT
.else
	.word	DEF_DB_LEFT|DOUBLE_W,DEF_DB_RIGHT|DOUBLE_W|ADD1_W
.endif

	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBGETFILES,6,4

	.byte	OPEN,DBI_X_2,4

	.byte	DBUSRICON
	.byte	DBI_X_2,22
	.word	ER+editNmTable-PhDirRoutines

	.byte	DBUSRICON
	.byte	DBI_X_2,40
	.word	ER+rmvNmTable-PhDirRoutines

	.byte	CANCEL,DBI_X_2,76

	.byte	DB_USR_ROUT
	.word	ER+SetRMargin-PhDirRoutines

	.byte	DBTXTSTR,12,108
	.word	ER+inetNmTxt-PhDirRoutines
	.byte	DBGETSTRING,TXT_LN_X,118
	.byte	r6,32

	.byte	0


inetNmTxt:
	.byte	BOLDON,"Select a telnet address",PLAINTEXT,0

editNmTable:
	.word	ER+editPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	6,16
.else
	.byte	6|DOUBLE_B,16
.endif
	.word	ER+EditNmClicked-PhDirRoutines

rmvNmTable:
	.word	ER+rmvPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	6,16
.else
	.byte	6|DOUBLE_B,16
.endif
	.word	ER+RmvNmClicked-PhDirRoutines

EditNmClicked:
	lda	#40
	.byte	44
RmvNmClicked:
	lda	#41
	ldx	hostName+0
	bne	80$
	rts
 80$
	sta	sysDBData
	jmp	RstrFrmDialog


;this checks to see if there's exactly one ISP file.
IsOneISP:
	ldx	#3
	jsr	SetNewDir
	jsr	OpenPrgDir
	LoadB	r7L,#APPL_DATA
	LoadB	r7H,#2
	LoadW	r10,#ER+ispHeader+77-PhDirRoutines
	LoadW	r6,#userName	;this spot isn't used right now.
	jsr	FindFTypes
	lda	r7H
	cmp	#1
	bne	90$
	ldx	#15
 50$
	lda	userName,x
	sta	reqFileName,x
	dex
	bpl	50$
	jsr	ER+RdBlkPhEntry-PhDirRoutines
	bne	90$
	jsr	OpenSavDir
	sec
	rts
 90$
	jsr	OpenSavDir
	clc
	rts


MakeHstFile:
	LoadW	r0,#ER+wHistName-PhDirRoutines
	jsr	DeleteFile
	LoadW	r0,#ER+histHeader-PhDirRoutines
 20$
	ldy	#0
 30$
	lda	(r0),y
	sta	fileHeader,y
	iny
	cpy	#[(endHistHeader-histHeader)
	bcc	30$
	lda	#0
 40$
	sta	fileHeader,y
	iny
	bne	40$
	LoadW	fileHeader,#ER+wHistName-PhDirRoutines
	LoadW	r9,#fileHeader
	LoadB	r10L,#0
	jsr	SaveFile	;+++do an error message if error.
	txa
	bne	90$
	MoveB	dirEntryBuf+1,r1L
	MoveB	dirEntryBuf+2,r1H
	jsr	RdBlkDskBuf
	bne	90$
	ldx	#2
 50$
	lda	#$00
	sta	diskBlkBuf,x
	inx
	lda	#$ff
	sta	diskBlkBuf,x
	inx
	bne	50$
	jsr	WrBlkDskBuf
 90$
	rts

wHistName:
	.byte	"WaveHistory",0

;this is the header block for the isp phone file.
histHeader:
	.word	$00
	.byte	3,21
	.byte	$bf,$ff,$ff,$ff,$81,$00,$21,$80
	.byte	$80,$41,$82,$61,$91,$84,$1e,$09
	.byte	$80,$80,$41,$80,$12,$01,$80,$00
	.byte	$01,$80,$3f,$c1,$81,$e0,$71,$87
	.byte	$17,$19,$8e,$49,$09,$9c,$a7,$29
	.byte	$b9,$0e,$31,$e0,$0e,$01,$c4,$0f
	.byte	$01,$81,$4b,$81,$ae,$72,$f1,$d5
	.byte	$55,$55,$aa,$aa,$ab,$ff,$ff,$ff

	.byte	$80|USR
	.byte	APPL_DATA
	.byte	VLIR
	.word	$0000
	.word	$ffff
	.word	$00
wHistVersion:
	.byte	"WaveHistory V1.1",0,0,0,0

endHistHeader:

endPhDir:

