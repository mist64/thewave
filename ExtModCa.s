;************************************************************

;		ExtModCa


;************************************************************


	.psect


PhDirRoutines:
	jmp	ER+JDoISPDir-PhDirRoutines
	jmp	ER+JDoBBSDir-PhDirRoutines
	jmp	ER+JInetSession-PhDirRoutines
	jmp	ER+JBeginISP-PhDirRoutines
	jmp	ER+JDoTrmMode-PhDirRoutines


;+++this is placed here to keep it out of
;+++the $5000 area.
Get1stTNet:
	ldy	#0
;	lda	[a0],y
	.byte	$b7,a0
	beq	80$
 10$
;	lda	[a0],y
	.byte	$b7,a0
	sta	(r6),y
	beq	40$
	iny
	cpy	#31
	bcc	10$
	lda	#0
	sta	(r6),y
 40$
	iny
	tya
	clc
	adc	#6
	adc	a0L
	sta	a0L
	bcc	60$
	inc	a0H
 60$
	LoadW	r5,#ER+Get1stTNet-PhDirRoutines
	clc
	rts
 80$
	LoadW	r5,#hostName
	sec
	rts


JDoISPDir:
	jsr	ER+ISPDir-PhDirRoutines
	bcs	20$
	rts
 20$
	jmp	ER+Connect-PhDirRoutines

JDoBBSDir:
	jsr	ER+BBSDir-PhDirRoutines
	bcs	20$
	rts
 20$
	jmp	LDialOut


ISPDir:
	lda	#%10000000
	.byte	44
BBSDir:
	lda	#%00000000
	sta	phDirMode
	ldx	#3
	jsr	SetNewDir
	jsr	OpenPrgDir
 10$
	LoadB	reqFileName,#0
	LoadB	r7L,#APPL_DATA
	LoadW	r10,#ER+bbsHeader+77-PhDirRoutines
	bit	phDirMode
	bpl	15$
	LoadW	r10,#ER+ispHeader+77-PhDirRoutines
 15$
	LoadW	r5,#reqFileName
	LoadW	r0,#ER+AvlDBBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#OPEN
	beq	60$
	cmp	#40
	bne	30$
	jsr	ER+EditPhEntry-PhDirRoutines
	bra	10$
 30$
	cmp	#41
	bne	40$
	jsr	ER+RmPhEntry-PhDirRoutines
	bra	10$
 40$
	cmp	#42
	bne	90$
	jsr	ER+AddNewISP-PhDirRoutines
	bra	10$
 60$
	lda	reqFileName+0
	beq	90$
	jsr	ER+RdBlkPhEntry-PhDirRoutines
	bne	90$	;+++display an error if not found.
	jsr	OpenSavDir
	sec
	rts
 90$
	jsr	OpenSavDir
	LoadB	phDirMode,#0
	clc
	rts


RmPhEntry:
	LoadW	r0,#ER+rmPhBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#OK
	bne	90$
	LoadW	r0,#reqFileName
	jsr	DeleteFile
 90$
	rts

rmPhBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	ER+sureTxt-PhDirRoutines

	.byte	OK
	.byte	DBI_X_0,DBI_Y_2
	.byte	CANCEL
	.byte	DBI_X_2,DBI_Y_2

	.byte	0

sureTxt:
	.byte	BOLDON,"Selected entry will be deleted",PLAINTEXT,0

EditPhEntry:
	jsr	ER+RdBlkPhEntry-PhDirRoutines
	beq	30$
	rts
 30$
	ldx	#0
	jsr	EDoSelBox
	cmp	#OK
	beq	60$
	cmp	#CANCEL
	beq	70$
	sec
	sbc	#40
	asl	a
	tax
	bit	phDirMode
	bmi	40$
;	jsr	(ER+chgBBSTable-PhDirRoutines,x)
	.byte	$fc
	.word	ER+chgBBSTable-PhDirRoutines
	bra	30$
 40$
;	jsr	(ER+chgISPTable-PhDirRoutines,x)
	.byte	$fc
	.word	ER+chgISPTable-PhDirRoutines
	bra	30$
 60$
	jsr	ER+SvNewPhFile-PhDirRoutines
 70$
	rts

chgBBSTable:
	.word	ER+ChgISPName-PhDirRoutines
	.word	EDoMdmSettings
	.word	ER+ChgPhNumber-PhDirRoutines
	.word	ER+JDoTrmMode-PhDirRoutines
	.word	ESelProtocol

chgISPTable:
	.word	ER+ChgISPName-PhDirRoutines
	.word	EDoMdmSettings
	.word	ER+ChgPhNumber-PhDirRoutines
	.word	ER+ChgLogin-PhDirRoutines
	.word	ER+DoDNSDB-PhDirRoutines
	.word	ER+DoDNSDB-PhDirRoutines
	.word	ER+ChgUserName-PhDirRoutines
	.word	ER+ChgUserPassword-PhDirRoutines


ChgLogin:
	jsr	ER+DoLogDB-PhDirRoutines
	bcc	90$
	bit	manualLogin
	bmi	90$
	lda	userName+0
	bne	30$
	jsr	ER+EnterUserName-PhDirRoutines
	beq	70$
	jsr	ER+EdStr2UsrNm-PhDirRoutines
 30$
	lda	userPassword+0
	bne	90$
	jsr	ER+EnterPassword-PhDirRoutines
	beq	70$
	jmp	ER+EdStr2PassWd-PhDirRoutines
 70$
	LoadB	manualLogin,#%10000000
	LoadB	userName+0,#0
	sta	userPassword+0
 90$
	rts

RdBlkPhEntry:
	LoadW	r6,#reqFileName
	jsr	FindFile
	txa
	bne	90$	;+++display an error if not found.
	MoveB	dirEntryBuf+1,r1L
	MoveB	dirEntryBuf+2,r1H
	jsr	RdBlkDskBuf
	bne	90$
	lda	#118
	bit	phDirMode
	bpl	10$
	lda	#112
 10$
	sta	r1L
	ldx	#0
 30$
	lda	diskBlkBuf+2,x
	sta	ispNumber,x
	inx
	cpx	r1L
	bcc	30$
	lda	vtOn
	ora	#%01111111	;make sure bits 0-6 are set.
	sta	vtOn
	ldx	#0
 90$
	rts

AddNewISP:
	ldx	#0
	txa
 10$
	sta	ispNumber,x
	inx
	cpx	#112
	bcc	10$
	lda	#%01000000
	sta	manualLogin
	jsr	DefSLSettings
	jsr	ER+ISPNm2EditString-PhDirRoutines
	jsr	ER+EnterISPName-PhDirRoutines
	beq	45$
	jsr	ER+EdStr2ISPNm-PhDirRoutines
	jsr	ER+PhNum2EditString-PhDirRoutines
	jsr	ER+EnterNumber-PhDirRoutines
	bcc	45$
	jsr	ER+EdStr2PhNum-PhDirRoutines
	bit	phDirMode
	bmi	60$
	jsr	ER+JDoTrmMode-PhDirRoutines
	bcc	45$
	jsr	ESelProtocol
	bcs	80$
 45$
	rts
 60$
	jsr	ER+UsrNm2EditString-PhDirRoutines
	jsr	ER+DoLogDB-PhDirRoutines
	bcc	45$
	jsr	ER+DoDNSDB-PhDirRoutines
	bcc	45$
	bit	manualLogin
	bmi	80$
	jsr	ER+EnterUserName-PhDirRoutines
	beq	45$
	jsr	ER+EdStr2UsrNm-PhDirRoutines
	jsr	ER+PassWd2EditString-PhDirRoutines
	jsr	ER+EnterPassword-PhDirRoutines
	beq	45$
	jsr	ER+EdStr2PassWd-PhDirRoutines
 80$
	jmp	ER+SvNewPhFile-PhDirRoutines


SvNewPhFile:
	LoadW	r0,#reqFileName
	jsr	DeleteFile
	LoadW	r0,#ER+bbsHeader-PhDirRoutines
	bit	phDirMode
	bpl	20$
	LoadW	r0,#ER+ispHeader-PhDirRoutines
 20$
	ldy	#0
 30$
	lda	(r0),y
	sta	fileHeader,y
	iny
	cpy	#137
	bcc	30$
	lda	#0
 40$
	sta	fileHeader,y
	iny
	bne	40$
	LoadW	fileHeader,#reqFileName
	LoadW	r9,#fileHeader
	LoadB	r10L,#0
	jmp	SaveFile	;+++do an error message if error.


ISPNm2EditString:
	ldx	#16
 10$
	lda	reqFileName,x
	sta	ER+editString-PhDirRoutines,x
	dex
	bpl	10$
	rts

PhNum2EditString:
	ldx	#32
 10$
	lda	ispNumber,x
	sta	ER+editString-PhDirRoutines,x
	dex
	bpl	10$
	rts

UsrNm2EditString:
	ldx	#32
 10$
	lda	userName,x
	sta	ER+editString-PhDirRoutines,x
	dex
	bpl	10$
	rts

PassWd2EditString:
	ldx	#0
 10$
	lda	userPassword,x
	beq	20$
	lsr	a
	eor	#%01111111
	sta	ER+editString-PhDirRoutines,x
	inx
	cpx	#32
	bcc	10$
	lda	#0
 20$
	sta	ER+editString-PhDirRoutines,x
	rts

EdStr2ISPNm:
	ldx	#16
 10$
	lda	ER+editString-PhDirRoutines,x
	sta	reqFileName,x
	dex
	bpl	10$
	rts

EdStr2PhNum:
	ldx	#32
 10$
	lda	ER+editString-PhDirRoutines,x
	sta	ispNumber,x
	dex
	bpl	10$
	rts

EdStr2UsrNm:
	ldx	#32
 10$
	lda	ER+editString-PhDirRoutines,x
	sta	userName,x
	dex
	bpl	10$
	rts

EdStr2PassWd:
	ldx	#0
 10$
	lda	ER+editString-PhDirRoutines,x
	beq	20$
	eor	#%01111111
	asl	a
	sta	userPassword,x
	inx
	cpx	#32
	bcc	10$
	lda	#0
 20$
	sta	userPassword,x
	rts

;this is the header block for the isp phone file.
ispHeader:
	.word	$00
	.byte	3,21
	.byte	$bf,$ff,$ff,$ff,$80,$00,$01,$83
	.byte	$9d,$c1,$81,$21,$21,$81,$19,$c1
	.byte	$81,$05,$01,$83,$b9,$01,$80,$00
	.byte	$01,$8f,$ff,$f1,$90,$00,$09,$a1
	.byte	$ff,$85,$bf,$7e,$fd,$bf,$24,$fd
	.byte	$81,$5a,$81,$82,$24,$41,$87,$ff
	.byte	$e1,$84,$00,$21,$84,$00,$21,$87
	.byte	$ff,$e1,$80,$00,$01,$ff,$ff,$ff

	.byte	$80|USR
	.byte	APPL_DATA
	.byte	SEQUENTIAL
	.word	ispNumber
	.word	ispNumber+112
	.word	$00
	.byte	"ISPAccount  V1.4",0,0,0,0
	.block	20
	.byte	"WaveTerm",0,0,0,0,0,0,0,0,0,0,0,0

;this is the header block for the bbs phone file.
bbsHeader:
	.word	$00
	.byte	3,21
	.byte	$bf,$ff,$ff,$ff,$80,$00,$01,$87
	.byte	$38,$e1,$84,$a5,$01,$87,$38,$c1
	.byte	$84,$a4,$21,$87,$39,$c1,$80,$00
	.byte	$01,$8f,$ff,$f1,$90,$00,$09,$a1
	.byte	$ff,$85,$bf,$7e,$fd,$bf,$24,$fd
	.byte	$81,$5a,$81,$82,$24,$41,$87,$ff
	.byte	$e1,$84,$00,$21,$84,$00,$21,$87
	.byte	$ff,$e1,$80,$00,$01,$ff,$ff,$ff

	.byte	$80|USR
	.byte	APPL_DATA
	.byte	SEQUENTIAL
	.word	ispNumber
	.word	ispNumber+118
	.word	$00
	.byte	"BBSAccount  V1.4",0,0,0,0
	.block	20
	.byte	"WaveTerm",0,0,0,0,0,0,0,0,0,0,0,0

AvlDBBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBGETFILES
	.byte	6,4

	.byte	OPEN
	.byte	DBI_X_2,4

	.byte	DBUSRICON
	.byte	DBI_X_2,22
	.word	ER+editPhTable-PhDirRoutines

	.byte	DBUSRICON
	.byte	DBI_X_2,40
	.word	ER+rmvPhTable-PhDirRoutines

	.byte	DBUSRICON
	.byte	DBI_X_2,58
	.word	ER+addPhTable-PhDirRoutines

	.byte	CANCEL
	.byte	DBI_X_2,76

	.byte	0


editPhTable:
	.word	ER+editPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	6,16
.else
	.byte	6|DOUBLE_B,16
.endif
	.word	ER+EditPhClicked-PhDirRoutines

editPic:


rmvPhTable:
	.word	ER+rmvPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	6,16
.else
	.byte	6|DOUBLE_B,16
.endif
	.word	ER+RmvPhClicked-PhDirRoutines

rmvPic:


addPhTable:
	.word	ER+addPic-PhDirRoutines
	.byte	0,0
.if	C64
	.byte	6,16
.else
	.byte	6|DOUBLE_B,16
.endif
	.word	ER+AddPhClicked-PhDirRoutines

addPic:


EditPhClicked:
	lda	#40
	.byte	44
RmvPhClicked:
	lda	#41
	ldx	reqFileName+0
	bne	80$
	rts
 80$
	.byte	44
AddPhClicked:
	lda	#42
	sta	sysDBData
	jmp	RstrFrmDialog

ChgISPName:
	jsr	ER+ISPNm2EditString-PhDirRoutines
	jsr	ER+ReISPName-PhDirRoutines
	beq	90$
	jsr	ER+EdStr2ISPNm-PhDirRoutines
 90$
	rts

;this pops up a DB asking the user to enter a filename.
;Equals flag is cleared if a name was entered.
EnterISPName:
	LoadB	ER+editString+0-PhDirRoutines,#0
ReISPName:
	LoadW	r5,#ER+editString-PhDirRoutines
	LoadW	r0,#ER+ispNameBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	lda	ER+editString+0-PhDirRoutines
 90$
	rts

ispNameBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DB_USR_ROUT
	.word	ER+SetRMargin-PhDirRoutines

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	ER+saveAsTxt-PhDirRoutines
	.byte	DBGETSTRING,TXT_LN_X,TXT_LN_3_Y
	.byte	r5,16

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0

saveAsTxt:
	.byte	BOLDON,"Give this account a name:",PLAINTEXT,0 ;this changes.

SetRMargin:
.if	C64
	LoadW	rightMargin,#DEF_DB_RIGHT-16
.else
	LoadW	rightMargin,#((DEF_DB_RIGHT-16)*2)
.endif
	rts

editString:
	.block	33

ChgPhNumber:
	jsr	ER+PhNum2EditString-PhDirRoutines
	jsr	ER+ReISPNumber-PhDirRoutines
	bcc	90$
	jsr	ER+EdStr2PhNum-PhDirRoutines
 90$
	rts

;this pops up a DB asking the user to enter a phone number.
;Equals flag is cleared if a number was entered.
EnterNumber:
	LoadB	ER+editString+0-PhDirRoutines,#0
ReISPNumber:
	jsr	ER+RealOrNull-PhDirRoutines
	bcc	90$
	cmp	#21
	bne	10$
	LoadB	ER+editString+0-PhDirRoutines,#0
	sec
	rts
 10$
	LoadW	r5,#ER+editString-PhDirRoutines
	LoadW	r0,#ER+ispNumBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	lda	ER+editString-PhDirRoutines
	beq	10$
	sec
	rts
 90$
	clc
	rts

ispNumBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DB_USR_ROUT
	.word	ER+SetRMargin-PhDirRoutines

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	ER+phNumTxt-PhDirRoutines
	.byte	DBGETSTRING,TXT_LN_X,TXT_LN_3_Y
	.byte	r5,32

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0

phNumTxt:
	.byte	BOLDON,"Enter a phone number:",PLAINTEXT,0

RealOrNull:
	LoadW	r0,#ER+reNulBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	sec
	rts
 90$
	clc
	rts

realClicked:
	lda	#20
	.byte	44
nullClicked:
	lda	#21
	sta	sysDBData
	jmp	RstrFrmDialog


reNulBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,20
	.word	ER+methodTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,31
	.word	ER+realTable-PhDirRoutines
	.byte	DBTXTSTR,52,37
	.word	ER+useRealTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,43
	.word	ER+nullTable-PhDirRoutines
	.byte	DBTXTSTR,52,49
	.word	ER+useNullTxt-PhDirRoutines

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0

methodTxt:
	.byte	BOLDON,"Communication method",PLAINTEXT,0

realTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	4,31
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+realClicked-PhDirRoutines

useRealTxt:
	.byte	BOLDON,"Use a real modem",PLAINTEXT,0

nullTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	4,43
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+nullClicked-PhDirRoutines

useNullTxt:
	.byte	BOLDON,"Use a null-modem",PLAINTEXT,0


DoLogDB:
	LoadW	r0,#ER+logBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	sec
	rts
 90$
	clc
	rts

ManLogClicked:
	LoadB	userName+0,#0
	sta	userPassword+0
	lda	#%10000000
	.byte	44
AutLogClicked:
	lda	#%00000000
	.byte	44
PapLogClicked:
	lda	#%01000000
	sta	manualLogin
	LoadB	sysDBData,#50
	jmp	RstrFrmDialog


SetLogAppMain:
	LoadW	appMain,#ER+ShowLogType-PhDirRoutines
	rts

ShowLogType:
	LoadB	appMain+0,#0
	sta	appMain+1
	jsr	ER+SetLogPtr-PhDirRoutines
	lda	ER+logTLoc+0-PhDirRoutines,x
	sta	r0L
	lda	ER+logTLoc+1-PhDirRoutines,x
	sta	r0H
	ldy	#3
	lda	(r0),y
	clc
	adc	#32
	adc	#1
	sta	r2L
	adc	#4
	sta	r2H
.if	C64
	LoadW	r3,#97
	LoadW	r4,#109
.else
	LoadW	r3,#193
	LoadW	r4,#219
.endif
	lda	#2
	jsr	SetPattern
	jmp	Rectangle

logTLoc:
	.word	ER+papLogTable-PhDirRoutines
	.word	ER+manLogTable-PhDirRoutines
	.word	ER+autLogTable-PhDirRoutines

SetLogPtr:
	lda	manualLogin
	beq	10$
	bmi	20$
	lda	#0
	.byte	44
 10$
	lda	#2
	.byte	44
 20$
	lda	#1
	asl	a
	tax
	rts

logBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,20
	.word	ER+logTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,31
	.word	ER+papLogTable-PhDirRoutines
	.byte	DBTXTSTR,52,37
	.word	ER+papLogTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,43
	.word	ER+manLogTable-PhDirRoutines
	.byte	DBTXTSTR,52,49
	.word	ER+manLogTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,55
	.word	ER+autLogTable-PhDirRoutines
	.byte	DBTXTSTR,52,61
	.word	ER+autLogTxt-PhDirRoutines

	.byte	DB_USR_ROUT
	.word	ER+SetLogAppMain-PhDirRoutines

	.byte	OK,DBI_X_0,DBI_Y_2
	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0


logTxt:
	.byte	BOLDON,"Select a login method",PLAINTEXT,0

papLogTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	4,31
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+PapLogClicked-PhDirRoutines

papLogTxt:
	.byte	BOLDON,"PAP login",PLAINTEXT,0

manLogTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	4,43
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+ManLogClicked-PhDirRoutines

manLogTxt:
	.byte	BOLDON,"Manual login",PLAINTEXT,0

autLogTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	4,55
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+AutLogClicked-PhDirRoutines

autLogTxt:
	.byte	BOLDON,"Auto login",PLAINTEXT,0


DoDNSDB:
	LoadW	r0,#ER+dnsBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	cmp	#21
	beq	30$
	cmp	#20
	bne	90$
	ldy	#7
	lda	#0
 20$
	sta	desDNSPrimary,y
	dey
	bpl	20$
	sec
	rts
 30$
	jmp	ER+EnterDNSAddresses-PhDirRoutines
 90$
	clc
	rts

dnsISPClicked:
	lda	#20
	.byte	44
dnsManClicked:
	lda	#21
	sta	sysDBData
	jmp	RstrFrmDialog


dnsBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,20
	.word	ER+dnsTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,31
	.word	ER+ispWillTable-PhDirRoutines
	.byte	DBTXTSTR,52,37
	.word	ER+ispWilTxt-PhDirRoutines

	.byte	DBUSRICON
	.byte	4,43
	.word	ER+iWillTable-PhDirRoutines
	.byte	DBTXTSTR,52,49
	.word	ER+iWillTxt-PhDirRoutines

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0


dnsTxt:
	.byte	BOLDON,"Your DNS addresses",PLAINTEXT,0

ispWillTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	4,31
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+dnsISPClicked-PhDirRoutines

ispWilTxt:
	.byte	BOLDON,"My ISP assigns them",PLAINTEXT,0

iWillTable:
	.word	ER+buttonPic-PhDirRoutines
	.byte	4,43
.if	C64
	.byte	2,8
.else
	.byte	2|DOUBLE_B,8
.endif
	.word	ER+dnsManClicked-PhDirRoutines

iWillTxt:
	.byte	BOLDON,"I will enter them",PLAINTEXT,0


EnterDNSAddresses:
 10$
	LoadW	ER+dnsAddrLoc-PhDirRoutines,#ER+priEntTxt-PhDirRoutines
	jsr	ER+EntADNSAddress-PhDirRoutines
	cmp	#CANCEL
	beq	90$
	lda	ER+editString+0-PhDirRoutines
	beq	10$
	jsr	ER+IntTo4Bytes-PhDirRoutines
	bcc	10$
	ldy	#3
 20$
;	lda	[r0],y
	.byte	$b7,r0
	sta	desDNSPrimary,y
	dey
	bpl	20$
 40$
	LoadB	desDNSSecondary+0,#0
	LoadW	ER+dnsAddrLoc-PhDirRoutines,#ER+secEntTxt-PhDirRoutines
	jsr	ER+EntADNSAddress-PhDirRoutines
	cmp	#CANCEL
	beq	80$
	lda	ER+editString+0-PhDirRoutines
	beq	80$
	jsr	ER+IntTo4Bytes-PhDirRoutines
	bcc	40$
	ldy	#3
 50$
;	lda	[r0],y
	.byte	$b7,r0
	sta	desDNSSecondary,y
	dey
	bpl	50$
 80$
	sec
	rts
 90$
	clc
	rts


IntTo4Bytes:
	LoadW	r0,#ER+editString-PhDirRoutines
;	phk
	.byte	$4b
	PopB	r1L
	jmp	LAddrTo32Bits

EntADNSAddress:
	LoadB	ER+editString+0-PhDirRoutines,#0
	LoadW	r5,#ER+editString-PhDirRoutines
	LoadW	r0,#ER+entDNSBox-PhDirRoutines
	jmp	DoColorBox

entDNSBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
dnsAddrLoc:
	.word	ER+priEntTxt-PhDirRoutines
	.byte	DBGETSTRING,TXT_LN_X,TXT_LN_3_Y
	.byte	r5,15

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0

priEntTxt:
	.byte	BOLDON,"Enter primary DNS address",PLAINTEXT,0
secEntTxt:
	.byte	BOLDON,"Enter secondary DNS address",PLAINTEXT,0


ChgUserName:
	bit	manualLogin
	bmi	90$
	jsr	ER+UsrNm2EditString-PhDirRoutines
	jsr	ER+ReUserName-PhDirRoutines
	beq	90$
	jsr	ER+EdStr2UsrNm-PhDirRoutines
 90$
	rts

;this pops up a DB asking the user to enter a username.
;Equals flag is cleared if a username was entered.
EnterUserName:
	LoadB	ER+editString+0-PhDirRoutines,#0
ReUserName:
 10$
	LoadW	r5,#ER+editString-PhDirRoutines
	LoadW	r0,#ER+usrNameBox-PhDirRoutines
	jsr	DoColorBox
	cmp	#CANCEL
	beq	90$
	lda	ER+editString-PhDirRoutines
	beq	10$
 90$
	rts

usrNameBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DB_USR_ROUT
	.word	ER+SetRMargin-PhDirRoutines

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	ER+usrNameTxt-PhDirRoutines
	.byte	DBGETSTRING,TXT_LN_X,TXT_LN_3_Y
	.byte	r5,32

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0

usrNameTxt:
	.byte	BOLDON,"Enter your login username:",PLAINTEXT,0 ;this changes.

ChgUserPassword:
	bit	manualLogin
	bmi	90$
	jsr	ER+PassWd2EditString-PhDirRoutines
	jsr	ER+EnterPassword-PhDirRoutines
	beq	90$
	jsr	ER+EdStr2PassWd-PhDirRoutines
 90$
	rts

;this pops up a DB asking the user to enter a password.
;Equals flag is cleared if a password was entered.
EnterPassword:
 10$
	LoadW	ER+passTxtLoc-PhDirRoutines,#ER+passWdTxt-PhDirRoutines
	jsr	ER+GetPassword-PhDirRoutines
	cmp	#CANCEL
	beq	90$
	lda	ER+password-PhDirRoutines
	beq	10$
	ldx	#32
 20$
	lda	ER+password-PhDirRoutines,x
	sta	ER+editString-PhDirRoutines,x
	dex
	bpl	20$
	LoadW	ER+passTxtLoc-PhDirRoutines,#ER+reenterTxt-PhDirRoutines
	jsr	ER+GetPassword-PhDirRoutines
	cmp	#CANCEL
	beq	90$
	lda	ER+password-PhDirRoutines
	beq	10$
	LoadW	r0,#ER+password-PhDirRoutines
	LoadW	r1,#ER+editString-PhDirRoutines
	ldx	#r0
	ldy	#r1
	jsr	CmpString
	bne	10$
	lda	ER+editString-PhDirRoutines
 90$
	rts


GetPassword:
	LoadB	ER+passOffset-PhDirRoutines,#0
	ldx	#32
 10$
	sta	ER+password-PhDirRoutines,x
	dex
	bpl	10$
	LoadW	r0,#ER+passWdBox-PhDirRoutines
	jmp	DoColorBox

passWdBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DB_USR_ROUT
	.word	ER+SetPassEntry-PhDirRoutines

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
passTxtLoc:
	.word	ER+passWdTxt-PhDirRoutines

	.byte	CANCEL,DBI_X_2,DBI_Y_2

	.byte	0

passWdTxt:
	.byte	BOLDON,"Enter your login password:",PLAINTEXT,0 ;this changes.
reenterTxt:
	.byte	BOLDON,"Reenter password to confirm:",PLAINTEXT,0 ;this changes.

SetPassEntry:
	LoadB	ER+passY-PhDirRoutines,#DEF_DB_TOP+TXT_LN_3_Y
.if	C64
	LoadW	ER+passX-PhDirRoutines,#DEF_DB_LEFT+TXT_LN_X
.else
	LoadW	ER+passX-PhDirRoutines,#((DEF_DB_LEFT+TXT_LN_X)*2)
.endif
	LoadW	keyVector,#ER+GetPassChar-PhDirRoutines
	LoadW	appMain,#ER+StartPCursor-PhDirRoutines
	rts

passOffset:
	.block	1
passX:
	.block	2
passY:
	.block	1

StartPCursor:
	LoadB	appMain+0,#0
	sta	appMain+1
	MoveW	ER+passX-PhDirRoutines,stringX
	MoveB	ER+passY-PhDirRoutines,stringY
	lda	curHeight
	jsr	InitTextPrompt
OnCursor:
	LoadB	alphaFlag,#%10000000
	jmp	PromptOn

OffCursor:
	php
	sei
	jsr	PromptOff
	LoadB	alphaFlag,#0
	plp
	rts

tnetName:
password:
	.block	33

GetPassChar:
	lda	keyData
	cmp	#127
	bcs	90$
	cmp	#CR
	bne	10$
	jmp	RstrFrmDialog
 10$
	cmp	#KEY_DELETE
	bne	50$
	ldx	ER+passOffset-PhDirRoutines
	beq	90$
	dec	ER+passOffset-PhDirRoutines
	dex
	lda	#8
	bne	60$	;branch always.
 50$
	cmp	#32
	bcc	90$
	ldx	ER+passOffset-PhDirRoutines
	cpx	#32
	bcs	90$
	tay
.if	C64
	CmpWI	ER+passX-PhDirRoutines,#DEF_DB_RIGHT-16
.else
	CmpWI	ER+passX-PhDirRoutines,#((DEF_DB_RIGHT-16)*2)
.endif
	bcs	90$
	tya
	inc	ER+passOffset-PhDirRoutines
	sta	ER+password-PhDirRoutines,x
	inx
	lda	#'*'
 60$
	pha
	lda	#0
	sta	ER+password-PhDirRoutines,x
	jsr	ER+OffCursor-PhDirRoutines
	MoveW	ER+passX-PhDirRoutines,r11
	clc
	lda	ER+passY-PhDirRoutines
	adc	baselineOffset
	sta	r1H
	pla
	jsr	PutChar
	MoveB	r11H,ER+passX+1-PhDirRoutines
	sta	stringX+1
	MoveB	r11L,ER+passX+0-PhDirRoutines
	sta	stringX+0
	jsr	ER+OnCursor-PhDirRoutines
 90$
	rts

