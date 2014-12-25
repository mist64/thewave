;*************************************
;
;	PPP1Link
;
;	routines for getting the PPP link
;	up and running.
;
;*************************************

.if	Pass1

.noeqin
.noglbl

C64=0
C128=0
C64AND128=1

.include	WheelsEquates
.include	WheelsSyms
.include	superMac
.include	TermEquates

.glbl
.eqin

.endif


	.psect

;+++add error messages as to why the connection
;+++might not be successful.
JDialOut:
	jsl	SOpenModem,0
;	lda	waveRunning
	.byte	$af,[waveRunning,]waveRunning,0
	bmi	5$
	jsr	SaveTxtScreen
 5$
	ldx	#3
	ldy	#5
	jsr	URLBarMsg	;display "Resetting..."
;	lda	phDirMode
	.byte	$af,[phDirMode,]phDirMode,0
	pha
	jsl	SDisconnect,0
	pla
;	sta	phDirMode
	.byte	$8f,[phDirMode,]phDirMode,0
	lda	#%00000000
;	sta	commMode
	.byte	$8f,[commMode,]commMode,0
	LoadB	lcpBitMap,#%11100000
;	lda	ispNumber
	.byte	$af,[ispNumber,]ispNumber,0
	bne	10$
	lda	#%10000000
	.byte	44
 10$
	lda	#%00000000
;	sta	ignoreDCD
	.byte	$8f,[ignoreDCD,]ignoreDCD,0
	asl	a
	bcs	40$
	ldx	#3
	ldy	#0
	jsr	URLBarMsg	;display "Dialing out..."
	LoadW	r0,#atdtString
;	phk
	.byte	$4b
	PopB	r1L
	jsr	SndR0String
	beq	20$
 15$
	ldx	#3
	ldy	#1
	jsr	URLBarMsg	;display "Disconnecting..."
 16$
	jsr	JSLCkAbortKey
	bcc	16$
	jsl	SDisconnect,0
	jsl	SDefSLSettings,0
	jsr	RstrMessage
	clc
	rts
 20$
	LoadW	r0,#ispNumber
	LoadB	r1L,#0
	jsr	SndR0String
	bne	15$
	lda	#CR
	jsr	JSLSend1Byte
	bne	15$
 30$
;+++add a timer in here too.
	jsr	JSLCkAbortKey
	bcc	15$
	jsl	SCheckDCD,0
;	lda	dcdStatus
	.byte	$af,[dcdStatus,]dcdStatus,0
	bpl	30$
 40$
;	lda	phDirMode
	.byte	$af,[phDirMode,]phDirMode,0
	bpl	80$

;	lda	manualLogin
	.byte	$af,[manualLogin,]manualLogin,0
	bmi	80$
	beq	50$
	LoadB	lcpBitMap,#%11110000
	bne	60$	;branch always.
 50$
	ldx	#3
	ldy	#2
	jsr	URLBarMsg	;display "Logging in..."
	jsr	ISPLogin
	jsr	JSLCkAbortKey
	bcc	15$
 60$
	ldx	#3
	ldy	#3
	jsr	URLBarMsg	;display "Negotiating PPP link..."
	jsr	JPPPLinkUp
	bcc	15$

	lda	#%10000000
;	sta	commMode
	.byte	$8f,[commMode,]commMode,0
 80$
	jsr	RstrMessage
	sec
	rts

RstrMessage:
;	lda	waveRunning
	.byte	$af,[waveRunning,]waveRunning,0
	bpl	20$
	jmp	DoURLBar
 20$
	jmp	RstrTxtScreen

SndR0String:
 10$
;	lda	[r0]
	.byte	$a7,r0
	beq	20$
	jsr	JSLSend1Byte
	bne	20$
	inc	r0L
	bne	10$
	inc	r0H
	bne	10$	;branch always.
 20$
	rts

atdtString:
	.byte	"ATDT",0

loginString:
	.byte	"login:"
psWdString:
	.byte	"password:"

ISPLogin:
	LoadB	lcpBitMap,#%11100000
 10$
	jsr	GetCkLine
	bcc	90$
	ldy	#8
	ldx	#5
 20$
	lda	ckLine,y
	cmp	loginString,x
	bne	10$
	dey
	dex
	bpl	20$
	jsr	SndUsrName
	bne	90$
 30$
	jsr	GetCkLine
	bcc	90$
	ldy	#8
 40$
	lda	ckLine,y
	cmp	psWdString,y
	bne	30$
	dey
	bpl	40$
	jsr	SndPassWord
	beq	95$
 90$
	jsr	JSLCkAbortKey
	bcc	95$
	LoadB	lcpBitMap,#%11110000 ;enable PAP.
 95$
	rts

GetCkLine:
	LoadW	r0,#4	;set for 4 seconds.
	jsr	JSLOnTimer
 10$
	jsr	JSLCkTimer
	bcs	90$
	jsr	JSLGetFrmBuf
	bcs	30$
	jsr	JSLCkAbortKey
	bcs	10$
	rts
 30$
	sta	ckLine+8
	cmp	#':'
	beq	60$
	cmp	#PPP_FLAG
	beq	90$
	ldy	#0
 40$
	lda	ckLine+1,y
	sta	ckLine+0,y
	iny
	cpy	#8
	bcc	40$
	bcs	10$
 60$
	ldy	#8
 70$
	lda	ckLine,y
	and	#%01111111
	ora	#%00100000
	sta	ckLine,y
	dey
	bpl	70$
	sec
	rts
 90$
	clc
	rts

ckLine:
	.block	9


SndUsrName:
	LoadW	r0,#userName
	LoadB	r1L,#0
	jsr	SndR0String
	bne	90$
	lda	#CR
	jsr	JSLSend1Byte
 90$
	rts

SndPassWord:
	LoadW	r0,#userPassword
	LoadB	r1L,#0
 10$
;	lda	[r0]
	.byte	$a7,r0
	beq	20$
	lsr	a
	eor	#%01111111
	jsr	JSLSend1Byte
	bne	90$
	inc	r0L
	bne	10$
	inc	r0H
	bne	10$	;branch always.
 20$
	lda	#CR
	jsr	JSLSend1Byte
 90$
	rts


