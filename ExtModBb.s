;************************************************************

;		ExtModBb


;************************************************************


	.psect


JDoSelBox:
	stx	ER+xSelRoutine-MsgRoutines
	txa
	asl	a
	tax
	lda	ER+boxTable+0-MsgRoutines,x
	sta	r0L
	lda	ER+boxTable+1-MsgRoutines,x
	sta	r0H
	ora	r0L
	bne	50$
	lda	ER+selRTable+0-MsgRoutines,x
	ora	ER+selRTable+1-MsgRoutines,x
	bne	40$
	LoadB	r0L,#CANCEL
	rts
 40$
;	jmp	(selRTable,x)
	.byte	$7c
	.word	ER+selRTable-MsgRoutines
 50$
	jsr	DoColorBox
	ldx	ER+xSelRoutine-MsgRoutines
	lda	ER+contDBFlags-MsgRoutines,x
	bpl	70$
	lda	r0L
	rts
 70$
	tax
	lda	r0L
;	jmp	(contDBRoutines,x)
	.byte	$7c
	.word	ER+contDBRoutines-MsgRoutines

xSelRoutine:
	.block	1

selRTable:
	.word	0,0
	.word	ER+DoSLAddr-MsgRoutines

boxTable:
	.word	ER+clkOnBox-MsgRoutines
	.word	ER+mdmSetBox-MsgRoutines
	.word	0

contDBFlags:
	.byte	255,0,255

contDBRoutines:
	.word	ER+DoMdmClicks-MsgRoutines

clkOnBox:
	.byte	SET_DB_POS
	.byte	DEF_DB_TOP,DEF_DB_BOT+48
.if	C64
	.word	DEF_DB_LEFT,DEF_DB_RIGHT
.else
	.word	DEF_DB_LEFT|DOUBLE_W,DEF_DB_RIGHT|DOUBLE_W|ADD1_W
.endif

	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DB_USR_ROUT
	.word	ER+SetRBMargin-MsgRoutines

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_1_Y
	.word	ER+clkOnTxt-MsgRoutines

	.byte	DB_USR_ROUT
	.word	ER+ShowPhItems-MsgRoutines

	.byte	DBOPVEC
	.word	ER+CkItemClick-MsgRoutines

	.byte	OK,DBI_X_0,DBI_Y_2+48
	.byte	CANCEL,DBI_X_2,DBI_Y_2+48

	.byte	0

clkOnTxt:
	.byte	BOLDON,"Click on the item to change:",PLAINTEXT,0


SetRBMargin:
.if	C64
	LoadW	rightMargin,#DEF_DB_RIGHT-16
.else
	LoadW	rightMargin,#((DEF_DB_RIGHT-16)*2)
.endif
	rts

ShowPhItems:
	LoadB	r1H,#DEF_DB_TOP+16
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+ispNmString-MsgRoutines
	jsr	PutString
	LoadW	r0,#reqFileName
	jsr	PutString
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+mdmSetString-MsgRoutines
	jsr	PutString
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+phNumString-MsgRoutines
	jsr	PutString
	LoadW	r0,#ispNumber
	lda	ispNumber+0
	bne	40$
	LoadW	r0,#ER+nullMdmString-MsgRoutines
 40$
	jsr	PutString
	bit	phDirMode
	bmi	70$
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+trmOptsString-MsgRoutines
	jsr	PutString
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+prtOptsString-MsgRoutines
	jmp	PutString
 70$
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+logMethString-MsgRoutines
	jsr	PutString
	jsr	ER+PntLogMethod-MsgRoutines
	jsr	PutString
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+priDNSString-MsgRoutines
	jsr	PutString
	jsr	ER+ShowPriDNSAddress-MsgRoutines
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+secDNSString-MsgRoutines
	jsr	PutString
	jsr	ER+ShowSecDNSAddress-MsgRoutines
	bit	manualLogin
	bmi	85$
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+usrNmString-MsgRoutines
	jsr	PutString
	LoadW	r0,#userName
	jsr	PutString
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+passWdString-MsgRoutines
	jsr	PutString
	LoadW	r0,#userPassword
 80$
;	lda	[r0]
	.byte	$b2,r0
	beq	85$
	lda	#'*'
	jsr	PutChar
	inc	r0L
	bne	80$
	inc	r0H
	bne	80$	;branch always.
 85$
	rts

ShowPriDNSAddress:
	jsr	ER+ShowISPAssigned-MsgRoutines
	bcc	10$
	rts
 10$
	ldx	#0
ShowDNSAddress:
	ldy	#4
 10$
	phx
	phy
	lda	desDNSPrimary,x
	sta	r0L
	LoadB	r0H,#0
	lda	#%11000000
	jsr	PutDecimal
	ply
	dey
	beq	80$
	phy
	lda	#'.'
	jsr	PutChar
	ply
	plx
	inx
	bne	10$	;branch always.
 80$
	pla
	rts

ShowSecDNSAddress:
	lda	desDNSPrimary
	beq	80$
	lda	desDNSSecondary
	bne	10$
	rts
 10$
	ldx	#4
	jmp	ER+ShowDNSAddress-MsgRoutines
 80$
ShowISPAssigned:
	LoadW	r0,#ER+ispAssnString-MsgRoutines
	lda	desDNSPrimary
	bne	90$
	jsr	PutString
	sec
	rts
 90$
	clc
	rts


nullMdmString:
	.byte	"[null-modem]",0

ispNmString:
	.byte	BOLDON,"ACCOUNT: ",PLAINTEXT,0
mdmSetString:
	.byte	BOLDON,"MODEM SETTINGS",PLAINTEXT,0
phNumString:
	.byte	BOLDON,"PH NUMBER: ",PLAINTEXT,0
logMethString:
	.byte	BOLDON,"LOGIN METHOD: ",PLAINTEXT,0
priDNSString:
	.byte	BOLDON,"PRIMARY DNS: ",PLAINTEXT,0
secDNSString:
	.byte	BOLDON,"SECONDARY DNS: ",PLAINTEXT,0
usrNmString:
	.byte	BOLDON,"USERNAME: ",PLAINTEXT,0
passWdString:
	.byte	BOLDON,"PASSWORD: ",PLAINTEXT,0
ispAssnString:
	.byte	"[ISP assigned]",0

trmOptsString:
	.byte	BOLDON,"TERMINAL OPTIONS",PLAINTEXT,0
prtOptsString:
	.byte	BOLDON,"PROTOCOL OPTIONS",PLAINTEXT,0


PntLogMethod:
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
	lda	ER+logMethTable+0-MsgRoutines,x
	sta	r0L
	lda	ER+logMethTable+1-MsgRoutines,x
	sta	r0H
	rts

logMethTable:
	.word	ER+papLgTxt-MsgRoutines
	.word	ER+manLgTxt-MsgRoutines
	.word	ER+autLgTxt-MsgRoutines

papLgTxt:
	.byte	"PAP login",0
manLgTxt:
	.byte	"Manual login",0
autLgTxt:
	.byte	"Auto login",0

PntLftDB:
.if	C64
	LoadW	r11,#DEF_DB_LEFT+8
.else
	LoadW	r11,#((DEF_DB_LEFT+8)*2)
.endif
	clc
	lda	r1H
	adc	#12
	sta	r1H
	rts


CkItemClick:
	lda	#44
	bit	phDirMode
	bpl	10$
	lda	#47
	bit	manualLogin
	bpl	10$
	lda	#45
 10$
	jmp	ER+CkClkAreas-MsgRoutines

CkMdmClick:
	lda	#43
;fall through...
CkClkAreas:
	ina
	sta	ER+maxClkItems-MsgRoutines
	bit	mouseData
	bmi	45$
.if	C64
	LoadW	r3,#DEF_DB_LEFT+8
	LoadW	r4,#DEF_DB_RIGHT-8
.else
	LoadW	r3,#((DEF_DB_LEFT+8)*2)
	LoadW	r4,#((DEF_DB_RIGHT-8)*2)
.endif
	ldx	#40
	LoadB	r2L,#DEF_DB_TOP+23
	LoadB	r2H,#DEF_DB_TOP+30
 30$
	jsr	IsMseInRegion
	cmp	#[TRUE
	beq	50$
	clc
	lda	r2L
	adc	#12
	sta	r2L
	adc	#7
	sta	r2H
	inx
	cpx	ER+maxClkItems-MsgRoutines
	bcc	30$
 45$
	rts
 50$
	stx	sysDBData
	jmp	RstrFrmDialog

maxClkItems:
	.block	1

PutTxtButtons:
	PushW	a0
	MoveW	ER+tBtnLocation-MsgRoutines,a0
	lda	#0
 10$
	pha
	sta	r2L
	tax
	lda	ER+tBtnDspMap-MsgRoutines,x
	bmi	70$
	LoadB	r1L,#12
	ldx	#r2L
	ldy	#r1L
	jsr	BBMult
	clc
	lda	r2L
	adc	#63
	sta	r1H
.if	C64
	LoadB	r1L,#12
.else
	LoadB	r1L,#24
.endif
.if	C64
	LoadB	r2L,#2
.else
	LoadB	r2L,#(2|DOUBLE_B)
.endif
	LoadB	r2H,#8
	LoadW	r0,#ER+buttnPic-MsgRoutines
	jsr	BitmapUp
	PopB	r2L
	pha
	asl	a
	tay
	lda	(a0),y
	sta	r0L
	iny
	lda	(a0),y
	sta	r0H
	LoadB	r1L,#12
	ldx	#r2L
	ldy	#r1L
	jsr	BBMult
	clc
	lda	r2L
	adc	#69
	sta	r1H
.if	C64
	LoadW	r11,#116
.else
	LoadW	r11,#232
.endif
	jsr	PutString
 70$
	pla
	ina
	cmp	ER+tBtnLocation+2-MsgRoutines
	bcc	10$
	PopW	a0
MarkTButtons:
	ldx	#0
 10$
	phx
	lda	ER+tBtnDspMap-MsgRoutines,x
	bmi	70$
	jsr	SetPattern
	pla
	pha
	jsr	ER+TBtnHilite-MsgRoutines
 70$
	plx
	inx
	cpx	ER+tBtnLocation+2-MsgRoutines
	bcc	10$
	rts

TBtnHilite:
	sta	r2L
	LoadB	r1L,#12
	ldx	#r2L
	ldy	#r1L
	jsr	BBMult
	clc
	lda	r2L
	adc	#64
	sta	r2L
	adc	#4
	sta	r2H
.if	C64
	LoadW	r3,#97
	LoadW	r4,#109
.else
	LoadW	r3,#194
	LoadW	r4,#219
.endif
	jmp	Rectangle


tBtnLocation:
	.block	2
	.block	1
tBtnRoutine:
	.block	2
tBtnDspMap:
	.block	12

ClrTBtnMap:
	ldx	#11
	lda	#255
 10$
	sta	ER+tBtnDspMap-MsgRoutines,x
	dex
	bpl	10$
	rts


mdmSetBox:
	.byte	SET_DB_POS
	.byte	DEF_DB_TOP,DEF_DB_BOT
.if	C64
	.word	DEF_DB_LEFT,DEF_DB_RIGHT
.else
	.word	DEF_DB_LEFT|DOUBLE_W,DEF_DB_RIGHT|DOUBLE_W|ADD1_W
.endif

	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DB_USR_ROUT
	.word	ER+SetRBMargin-MsgRoutines

	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_1_Y
	.word	ER+clkOnTxt-MsgRoutines

	.byte	DB_USR_ROUT
	.word	ER+ShowMdmItems-MsgRoutines

	.byte	DBOPVEC
	.word	ER+CkMdmClick-MsgRoutines

	.byte	OK,DBI_X_2,DBI_Y_2

	.byte	0



ShowMdmItems:
	LoadB	r1H,#DEF_DB_TOP+16
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+portSpString-MsgRoutines
	jsr	PutString
	lda	desBaudRate
	cmp	#3
	bcc	10$
	cmp	#12
	bcc	20$
 10$
	lda	#0
	sta	desBaudRate
	LoadW	r0,#ER+autoTxt-MsgRoutines
	jsr	PutString
	lda	bpsRate
	cmp	#3
	bcc	30$
	cmp	#12
	bcs	30$
	sec
	sbc	#3
	asl	a
	tax
	lda	ER+pStrTable+0-MsgRoutines,x
	sta	r0L
	lda	ER+pStrTable+1-MsgRoutines,x
	sta	r0H
	lda	#'('
	jsr	PutChar
	jsr	PutString
	lda	#')'
	jsr	PutChar
	bra	30$
 20$
	sec
	sbc	#3
	asl	a
	tax
	lda	ER+pStrTable+0-MsgRoutines,x
	sta	r0L
	lda	ER+pStrTable+1-MsgRoutines,x
	sta	r0H
	jsr	PutString
 30$
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+dtaBitString-MsgRoutines
	jsr	PutString
	lda	desDataBits
	clc
	adc	#'0'
	jsr	PutChar
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+parityString-MsgRoutines
	jsr	PutString
	lda	desParity
	lsr	a
	bcs	35$
	beq	40$
	lda	#2
	.byte	44
 35$
	lda	#1
 40$
	asl	a
	tax
	lda	ER+parStrTable+0-MsgRoutines,x
	sta	r0L
	lda	ER+parStrTable+1-MsgRoutines,x
	sta	r0H
	jsr	PutString
	jsr	ER+PntLftDB-MsgRoutines
	LoadW	r0,#ER+stpBitString-MsgRoutines
	jsr	PutString
	lda	desStopBits
	beq	45$
	cmp	#3
	bcc	50$
 45$
	lda	#1
 50$
	clc
	adc	#'0'
	jmp	PutChar



portSpString:
	.byte	BOLDON,"PORT SPEED: ",PLAINTEXT,0
dtaBitString:
	.byte	BOLDON,"DATA BITS: ",PLAINTEXT,0
parityString:
	.byte	BOLDON,"PARITY: ",PLAINTEXT,0
stpBitString:
	.byte	BOLDON,"STOP BITS: ",PLAINTEXT,0

autoTxt:
	.byte	"AUTO ",0

pStrTable:
	.word	ER+p2400String+1-MsgRoutines
	.word	ER+p4800String+1-MsgRoutines
	.word	ER+p7200String+1-MsgRoutines
	.word	ER+p9600String+1-MsgRoutines
	.word	ER+p14400String+1-MsgRoutines
	.word	ER+p19200String+1-MsgRoutines
	.word	ER+p38400String+1-MsgRoutines
	.word	ER+p57600String+1-MsgRoutines
	.word	ER+p115200String+1-MsgRoutines

p2400String:
	.byte	BOLDON,"2400",PLAINTEXT,0
p4800String:
	.byte	BOLDON,"4800",PLAINTEXT,0
p7200String:
	.byte	BOLDON,"7200",PLAINTEXT,0
p9600String:
	.byte	BOLDON,"9600",PLAINTEXT,0
p14400String:
	.byte	BOLDON,"14400",PLAINTEXT,0
p19200String:
	.byte	BOLDON,"19200",PLAINTEXT,0
p38400String:
	.byte	BOLDON,"38400",PLAINTEXT,0
p57600String:
	.byte	BOLDON,"57600",PLAINTEXT,0
p115200String:
	.byte	BOLDON,"115200",PLAINTEXT,0

parStrTable:
	.word	ER+noneString-MsgRoutines
	.word	ER+oddString-MsgRoutines
	.word	ER+evenString-MsgRoutines

noneString:
	.byte	"NONE",0
oddString:
	.byte	"ODD",0
evenString:
	.byte	"EVEN",0

Word2Hex:
	lda	r0H
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tax
	lda	ER+hexLookup-MsgRoutines,x
	sta	ER+hex16String+1-MsgRoutines
	lda	r0H
	and	#%00001111
	tax
	lda	ER+hexLookup-MsgRoutines,x
	sta	ER+hex16String+2-MsgRoutines
	lda	r0L
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tax
	lda	ER+hexLookup-MsgRoutines,x
	sta	ER+hex16String+3-MsgRoutines
	lda	r0L
	and	#%00001111
	tax
	lda	ER+hexLookup-MsgRoutines,x
	sta	ER+hex16String+4-MsgRoutines
	LoadW	r0,#ER+hex16String-MsgRoutines
	rts

hex16String:
	.byte	"$0000",0	;this changes.

DoMdmClicks:
	cmp	#OK
	bne	10$
 5$
	rts
 10$
	cmp	#44
	bcs	5$
	cmp	#40
	bcc	5$
	sbc	#40
	asl	a
	tax
;	jsr	(mdmClkRoutines,x)
	.byte	$fc
	.word	ER+mdmClkRoutines-MsgRoutines
	ldx	#1
	jmp	ER+JDoSelBox-MsgRoutines

mdmClkRoutines:
	.word	ER+DoPortSpeed-MsgRoutines
	.word	ER+DoDataBits-MsgRoutines
	.word	ER+DoDataBits-MsgRoutines
	.word	ER+DoDataBits-MsgRoutines

DoPortSpeed:
	jsr	ER+ClrTBtnMap-MsgRoutines
	bit	slT232Flag
	bmi	10$
	LoadW	ER+tBtnLocation-MsgRoutines,#ER+slSpdTTable-MsgRoutines
	LoadB	ER+tBtnLocation+2-MsgRoutines,#5
	ldx	#4
	bra	20$
 10$
	LoadW	ER+tBtnLocation-MsgRoutines,#ER+t232SpdTTable-MsgRoutines
	LoadB	ER+tBtnLocation+2-MsgRoutines,#7
	ldx	#6
 20$
	LoadW	ER+tBtnRoutine-MsgRoutines,#ER+SpdClicked-MsgRoutines
	lda	#0
 30$
	sta	ER+tBtnDspMap-MsgRoutines,x
	dex
	bpl	30$
	jsr	ER+SpdDspMap-MsgRoutines
	LoadW	r0,#ER+prtSpdBox-MsgRoutines
	jsr	DoColorBox
	lda	#0
	ldx	ER+tBtnDspMap-MsgRoutines
	bne	60$
	ldx	#1
 50$
	lda	ER+tBtnDspMap-MsgRoutines,x
	bmi	80$
	bne	55$
	inx
	cpx	#7
	bcc	50$
	rts
 55$
	lda	ER+tXSpdTable-MsgRoutines,x
	bit	slT232Flag
	bmi	60$
	lda	ER+sXSpdTable-MsgRoutines,x
 60$
	sta	desBaudRate
 80$
	rts


SpdDspMap:
	lda	desBaudRate
	bne	10$
	lda	#2
	sta	ER+tBtnDspMap-MsgRoutines
	lda	bpsRate
 10$
	bit	slT232Flag
	bmi	50$
	ldx	#4
 20$
	cmp	ER+sXSpdTable-MsgRoutines,x
	beq	30$
	dex
	bne	20$
 30$
	lda	#2
	sta	ER+tBtnDspMap-MsgRoutines,x
	rts
 50$
	ldx	#6
 60$
	cmp	ER+tXSpdTable-MsgRoutines,x
	beq	70$
	dex
	bne	60$
 70$
	lda	#2
	sta	ER+tBtnDspMap-MsgRoutines,x
	rts


SpdClicked:
	sec
	sbc	#40
	bcc	90$
	bne	20$
	lda	ER+tBtnDspMap-MsgRoutines
	eor	#2
	sta	ER+tBtnDspMap-MsgRoutines
	jmp	ER+MarkTButtons-MsgRoutines
 20$
	cmp	#7
	bcs	90$
	pha
	tax
	lda	ER+tXSpdTable-MsgRoutines,x
	bit	slT232Flag
	bmi	25$
	lda	ER+sXSpdTable-MsgRoutines,x
 25$
	tax
	jsr	SetBPS
	ldx	#6
	bit	slT232Flag
	bmi	30$
	ldx	#4
 30$
	lda	#0
 40$
	sta	ER+tBtnDspMap-MsgRoutines,x
	dex
	bne	40$
	plx
	lda	#2
	sta	ER+tBtnDspMap-MsgRoutines,x
	jmp	ER+MarkTButtons-MsgRoutines
 90$
	rts

prtSpdBox:
	.byte	SET_DB_POS
	.byte	DEF_DB_TOP,DEF_DB_BOT+32
.if	C64
	.word	DEF_DB_LEFT,DEF_DB_RIGHT
.else
	.word	DEF_DB_LEFT|DOUBLE_W,DEF_DB_RIGHT|DOUBLE_W|ADD1_W
.endif

	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,20
	.word	ER+prtSpdTxt-MsgRoutines

	.byte	DB_USR_ROUT
	.word	ER+PutTxtButtons-MsgRoutines

	.byte	DBOPVEC
	.word	ER+CkDBClicks-MsgRoutines

	.byte	OK,DBI_X_2,DBI_Y_2+32

	.byte	0

prtSpdTxt:
	.byte	BOLDON,"Select the port speed",PLAINTEXT,0

t232SpdTTable:
	.word	ER+slAutoTxt-MsgRoutines
	.word	ER+p115200String-MsgRoutines
	.word	ER+p57600String-MsgRoutines
	.word	ER+p38400String-MsgRoutines
	.word	ER+p19200String-MsgRoutines
	.word	ER+p9600String-MsgRoutines
	.word	ER+p2400String-MsgRoutines

tXSpdTable:
	.byte	0,11,10,9,8,6,3

slSpdTTable:
	.word	ER+slAutoTxt-MsgRoutines
	.word	ER+p38400String-MsgRoutines
	.word	ER+p19200String-MsgRoutines
	.word	ER+p9600String-MsgRoutines
	.word	ER+p2400String-MsgRoutines

sXSpdTable:
	.byte	0,9,8,6,3

DoDataBits:
	jsr	ER+ClrTBtnMap-MsgRoutines
	LoadW	ER+tBtnLocation-MsgRoutines,#ER+dtaBitTxtTable-MsgRoutines
	LoadB	ER+tBtnLocation+2-MsgRoutines,#2
	LoadW	ER+tBtnRoutine-MsgRoutines,#ER+DtaBitBtnClicked-MsgRoutines
	lda	#0
	sta	ER+tBtnDspMap+0-MsgRoutines
	sta	ER+tBtnDspMap+1-MsgRoutines
	ldx	#1
	lda	desDataBits
	cmp	#7
	beq	10$
	ldx	#0
	lda	#8
	sta	desDataBits
 10$
	lda	#2
	sta	ER+tBtnDspMap-MsgRoutines,x
	LoadW	r0,#ER+dtaBitBox-MsgRoutines
	jsr	DoColorBox
	cmp	#OK
	bne	40$
	lda	desDataBits
	cmp	#7
	beq	60$
	bne	45$
 40$
	cmp	#41
	beq	60$
 45$
	LoadB	desDataBits,#8
	LoadB	desParity,#0
	LoadB	desStopBits,#1
	rts
 60$
	LoadB	desDataBits,#7
	LoadB	desParity,#2
	LoadB	desStopBits,#1
	rts

dtaBitBox:
	.byte	DEF_DB_POS

	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,20
	.word	ER+dtaBtTxt-MsgRoutines

	.byte	DB_USR_ROUT
	.word	ER+PutTxtButtons-MsgRoutines

	.byte	DBOPVEC
	.word	ER+CkDBClicks-MsgRoutines

	.byte	OK,DBI_X_2,DBI_Y_2

	.byte	0

DtaBitBtnClicked:
	sta	sysDBData
	jmp	RstrFrmDialog

dtaBtTxt:
	.byte	BOLDON,"Select data,parity,stop bits",PLAINTEXT,0

dtaBitTxtTable:
	.word	ER+dta8N1Txt-MsgRoutines
	.word	ER+dta7E1Txt-MsgRoutines

dta8N1Txt:
	.byte	BOLDON,"8-N-1 (most common) ",PLAINTEXT,0
dta7E1Txt:
	.byte	BOLDON,"7-E-1",PLAINTEXT,0

DoSLAddr:
	jsr	ER+ClrTBtnMap-MsgRoutines
	LoadW	ER+tBtnLocation-MsgRoutines,#ER+slTxtTable-MsgRoutines
	LoadB	ER+tBtnLocation+2-MsgRoutines,#8
	LoadW	ER+tBtnRoutine-MsgRoutines,#ER+slBtnClicked-MsgRoutines
	ldx	#7
	lda	#0
 10$
	sta	ER+tBtnDspMap-MsgRoutines,x
	dex
	bpl	10$
	lda	defSLAddress+0
	ora	defSLAddress+1
	bne	15$
	lda	#2
	sta	ER+tBtnDspMap-MsgRoutines
 15$
	lda	slT232Flag
	beq	40$
	rep	%00100000
	ldx	#0
	lda	a5
 20$
	cmp	ER+avlSLAddresses-MsgRoutines,x
	beq	30$
	inx
	inx
	cpx	#16
	bcc	20$
	ldx	#0
 30$
	sep	%00100000
	txa
	lsr	a
	tax
	lda	#2
	sta	ER+tBtnDspMap-MsgRoutines,x
 40$
	LoadW	r0,#ER+slBox-MsgRoutines
	jsr	DoColorBox

	ldx	#1
 55$
	lda	ER+tBtnDspMap-MsgRoutines,x
	bmi	90$
	bne	60$
	inx
	cpx	#8
	bcc	55$
	rts
 60$
	txa
	asl	a
	pha
	jsr	OffNMIReceive
	jsr	RstrNMIInterrupts
	plx
	lda	ER+avlSLAddresses+0-MsgRoutines,x
	sta	a5L
	lda	ER+avlSLAddresses+1-MsgRoutines,x
	sta	a5H
	jsr	IsSLThere
	LoadB	defSLAddress+0,#0
	sta	defSLAddress+1
	lda	ER+tBtnDspMap-MsgRoutines
	bne	65$
	lda	slT232Flag
	beq	65$
	MoveW	a5,defSLAddress
 65$
	jsr	SetNMIInterrupts
	jsr	OnNMIReceive
	jmp	OpenModem
 90$
	rts


avlSLAddresses:
	.word	0,$de00,$df00,$d700,$dd40
	.word	$dd80,$ddc0,$de20

slAddrString:
	.byte	BOLDON,"INTERFACE ADDRESS: ",PLAINTEXT,0

SlBtnClicked:
	sec
	sbc	#40
	bcc	90$
	bne	20$
	lda	ER+tBtnDspMap-MsgRoutines
	eor	#2
	sta	ER+tBtnDspMap-MsgRoutines
	jmp	ER+MarkTButtons-MsgRoutines
 20$
	cmp	#8
	bcs	90$
	pha
	ldx	#7
	lda	#0
 40$
	sta	ER+tBtnDspMap-MsgRoutines,x
	dex
	bne	40$
	plx
	lda	#2
	sta	ER+tBtnDspMap-MsgRoutines,x
	jmp	ER+MarkTButtons-MsgRoutines
 90$
	rts

slBox:
	.byte	SET_DB_POS
	.byte	DEF_DB_TOP,DEF_DB_BOT+48
.if	C64
	.word	DEF_DB_LEFT,DEF_DB_RIGHT
.else
	.word	DEF_DB_LEFT|DOUBLE_W,DEF_DB_RIGHT|DOUBLE_W|ADD1_W
.endif

	.byte	DB_USR_ROUT
	.word	FrameDB

	.byte	DBTXTSTR,24,20
	.word	ER+slTxt-MsgRoutines

	.byte	DB_USR_ROUT
	.word	ER+PutTxtButtons-MsgRoutines

	.byte	DBOPVEC
	.word	ER+CkDBClicks-MsgRoutines

	.byte	OK,DBI_X_2,DBI_Y_2+48

	.byte	0

slTxtTable:
	.word	ER+slAutoTxt-MsgRoutines
	.word	ER+slDE00Txt-MsgRoutines
	.word	ER+slDF00Txt-MsgRoutines
	.word	ER+slD700Txt-MsgRoutines
	.word	ER+slDD40Txt-MsgRoutines
	.word	ER+slDD80Txt-MsgRoutines
	.word	ER+slDDC0Txt-MsgRoutines
	.word	ER+slDE20Txt-MsgRoutines

slAutoTxt:
	.byte	BOLDON,"AUTO ",PLAINTEXT,0
slDE00Txt:
	.byte	BOLDON,"$DE00",PLAINTEXT,0
slDF00Txt:
	.byte	BOLDON,"$DF00",PLAINTEXT,0
slD700Txt:
	.byte	BOLDON,"$D700",PLAINTEXT,0
slDD40Txt:
	.byte	BOLDON,"$DD40",PLAINTEXT,0
slDD80Txt:
	.byte	BOLDON,"$DD80",PLAINTEXT,0
slDDC0Txt:
	.byte	BOLDON,"$DDC0",PLAINTEXT,0
slDE20Txt:
	.byte	BOLDON,"$DE20",PLAINTEXT,0


slTxt:
	.byte	BOLDON,"Select an interface address",PLAINTEXT,0


buttnPic:



CkDBClicks:
	bit	mouseData
	bmi	45$
.if	C64
	LoadW	r3,#96
	LoadW	r4,#250
.else
	LoadW	r3,#192
	LoadW	r4,#500
.endif
	LoadB	r2L,#63
	LoadB	r2H,#74
	ldx	#0
 30$
	jsr	IsMseInRegion
	cmp	#[TRUE
	beq	50$
	clc
	lda	r2L
	adc	#12
	sta	r2L
	clc
	lda	r2H
	adc	#12
	sta	r2H
	inx
	cpx	ER+tBtnLocation+2-MsgRoutines
	bcc	30$
 45$
	rts
 50$
	txa
	clc
	adc	#40
	jmp	(ER+tBtnRoutine-MsgRoutines)


endMsgs:

