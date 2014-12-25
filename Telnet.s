;************************************************************

;		Telnet

;	Included here are some of the routines specific
;	to the telnet protocol.


;************************************************************

.if	Pass1
.noglbl
.noeqin

C64=0
C128=0
C64AND128=1

.include	WheelsSyms
.include	WheelsEquates
.include	superMac
.include	TermEquates

.eqin
.glbl
.endif


	.psect



JInitTNVars:
	ldx	#39
	lda	#0
 10$
	sta	doSent,x
	sta	willSent,x
	dex
	bpl	10$
	rts


JSndDo:
	pha
	tax
	lda	#%10000000
	sta	doSent,x
	lda	#IAC
	jsr	StorTCPSpot
	lda	#DO
	jsr	StorTCPSpot
	pla
	jsr	StorTCPSpot
	jmp	SendBufData

JSndWill:
	pha
	tax
	lda	#%10000000
	sta	willSent,x
	lda	#IAC
	jsr	StorTCPSpot
	lda	#WILL
	jsr	StorTCPSpot
	pla
	jsr	StorTCPSpot
	jmp	SendBufData

SndDMTelnet:
	lda	#IAC
	jsr	StorTCPSpot
	lda	#DM
	jsr	StorTCPSpot
	jmp	SendBufData

SndDoBinary:
	bit	lcommMode
	bmi	10$
	rts
 10$
	lda	#%10000000
	sta	doSent+0
	lda	#IAC
	jsr	StorTCPSpot
	lda	#DO
	jsr	StorTCPSpot
	lda	#0
	jsr	StorTCPSpot
	lda	#%10000000
	sta	willSent+0
	lda	#IAC
	jsr	StorTCPSpot
	lda	#WILL
	jsr	StorTCPSpot
	lda	#0
	jsr	StorTCPSpot
	jmp	SendBufData


JDoIACMode:
	jsr	SaveTCPData
 5$
	jsr	JSLGetBufByte
	bcs	10$
	jsr	JSLCkAbortKey
	bcs	5$
	bcc	85$
 10$
	cmp	#IAC
	beq	70$
	ldx	#0
 20$
	cmp	iacTable,x
	beq	30$
	inx
	cpx	#[(iacRoutine-iacTable)
	bcc	20$
	rts
 30$
	txa
	asl	a
	tax
;	jsr	(iacRoutine,x)
	.byte	$fc,[iacRoutine,]iacRoutine
	bcs	70$
	jsr	JSLGetBufByte
	bcc	85$
	cmp	#IAC
	beq	5$
 70$
	sec
	rts
 85$
	clc
	rts

iacTable:
	.byte	DO,WILL,SB
	.byte	EC,FF,241
	.byte	DONT,WONT,DM

iacRoutine:
	.word	DoDoList,DoWillList,DoSBList
	.word	IACDelete,IACPageBreak,DoNOP
	.word	DoDont,DoWont,DoDMSync

DoDMSync:
	lda	#0
	sec
	rts

DoNOP:
	clc
	rts

DoWont:
DoDont:
 10$
	jsr	JSLGetBufByte
	bcs	50$
	jsr	JSLCkAbortKey
	bcs	10$
 50$
	clc
	rts

IACDelete:
	lda	#8
	sec
	rts

IACPageBreak:
	lda	#FF
	sec
	rts

DoDoList:
	jsr	JSLGetBufByte
	bcs	10$
	rts
 10$
	pha
	pha
	pha
	tax
	lda	willSent,x
	beq	20$
	lda	#0
	sta	willSent,x
	pla
	pla
	pla
	clc
	rts
 20$
	lda	#IAC
	jsr	StorTCPSpot
	plx
	lda	doRList,x
	jsr	StorTCPSpot
	pla
	jsr	StorTCPSpot
	pla
;fall through...
AddSubNeg:
	cmp	#31
	bne	90$
	ldy	#0
 30$
	phy
	lda	sub31List,y
	jsr	StorTCPSpot
	ply
	iny
	cpy	#9
	bcc	30$
 90$
	clc
	rts

sub31List:
	.byte	IAC,SB,31,0,80,0,NUMTERMLINES,IAC,SE

doRList:
	.byte	WILL,WONT,WONT,WILL,WONT,WONT,WONT,WONT
	.byte	WONT,WONT,WONT,WONT,WONT,WONT,WONT,WONT
	.byte	WONT,WONT,WONT,WONT,WONT,WONT,WONT,WONT
	.byte	WILL,WONT,WONT,WONT,WONT,WONT,WONT,WILL
	.byte	WILL,WONT,WONT,WONT,WONT,WONT,WONT,WONT

doSent:
	.block	40

DoWillList:
	jsr	JSLGetBufByte
	bcs	10$
	rts
 10$
	pha
	pha
	tax
	lda	doSent,x
	beq	20$
	lda	#0
	sta	doSent,x
	pla
	pla
	clc
	rts
 20$
	lda	#IAC
	jsr	StorTCPSpot
	plx
	lda	willRList,x
	jsr	StorTCPSpot
	pla
	jsr	StorTCPSpot
	clc
	rts

willRList:
	.byte	DO,DO,DONT,DO,DONT,DONT,DONT,DONT
	.byte	DONT,DONT,DONT,DONT,DONT,DONT,DONT,DONT
	.byte	DONT,DONT,DONT,DONT,DONT,DONT,DONT,DONT
	.byte	DONT,DONT,DONT,DONT,DONT,DONT,DONT,DONT
	.byte	DONT,DONT,DONT,DONT,DONT,DONT,DONT,DONT

willSent:
	.block	40

DoSBList:
 5$
	jsr	JSLGetBufByte
	bcs	10$
	jsr	JSLCkAbortKey
	bcs	5$
 6$
	clc
	rts
 10$
	pha
	jsr	CkSBReqString
	pla
	bcc	6$
	cmp	#24
	beq	30$
	cmp	#32
	bne	6$
	LoadW	r0,#sub32List
	LoadB	r1L,#[(endS32List-sub32List)
	bra	40$
 30$
	LoadW	r0,#sub24List
	LoadB	r1L,#[(endS24List-sub24List)
;	lda	ansiOn
	.byte	$af,[ansiOn,]ansiOn,0
	bmi	40$
	LoadW	r0,#sub24VTList
	LoadB	r1L,#[(endS24VTList-sub24VTList)
 40$
	ldy	#0
 70$
	phy
	lda	(r0),y
	jsr	StorTCPSpot
	ply
	iny
	cpy	r1L
	bcc	70$
	clc
	rts


CkSBReqString:
	ldy	#0
 10$
	phy
	jsr	JSLGetBufByte
	ply
	bcs	20$
	jsr	JSLCkAbortKey
	bcs	10$
 15$
	clc
	rts
 20$
	cmp	sbRequestString,y
	bne	15$
	iny
	cpy	#3
	bcc	10$
	rts

sbRequestString:
	.byte	1,IAC,SE

sub24List:
	.byte	IAC,SB,24,0,"ansi",IAC,SE
endS24List:

sub24VTList:
	.byte	IAC,SB,24,0,"vt102",IAC,SE
endS24VTList:

sub32List:
	.byte	IAC,SB,TSPEED,0,"19200,19200",IAC,SE
endS32List:

