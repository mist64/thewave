;*************************************
;
;	PPP2Link
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

inPPPf:
	.block	2

rPPPFlag:
	.block	1

outPPPPR:
	.block	2
inCRC:
	.block	2
inPPPPR:
	.block	2

inBufLength:
	.block	2

JPPPLinkUp:
	jsr	InitPPPVars
	LoadW	r0,#4
	jsr	JSLOnTimer
	jsr	FireUpPPP
PPPLU2:
 10$
	jsr	JSLCkAbortKey
	bcc	11$
;	lda	ignoreDCD
	.byte	$af,[ignoreDCD,]ignoreDCD,0
	bmi	12$
	jsl	SCheckDCD,0
;	lda	dcdStatus
	.byte	$af,[dcdStatus,]dcdStatus,0
	bmi	12$
 11$
	clc
	rts
 12$
	jsr	JSLCkTimer
	bcc	15$
	bit	rPPPFlag	;is a frame coming in?
	bvs	15$	;branch if so.
	jsr	MntPPP
	lda	ncpFlag
	cmp	#%00001111	;NCP all done yet?
	beq	80$
	LoadW	r0,#4	;set for 4 seconds.
	jsr	JSLOnTimer
 15$
	jsr	RecvPPPFrame
	lda	rPPPFlag
	cmp	#%11111111	;PPP packet received yet?
	bne	10$	;branch if not.
 20$
	LoadB	rPPPFlag,#%10000000
.if	debug
	jsr	StashIncoming
.endif
	ldy	#2
 30$
	lda	prNumLTable,y
	cmp	inPPPPR+1
	bne	40$
	lda	prNumHTable,y
	cmp	inPPPPR+0
	beq	50$
 40$
	dey
	bpl	30$
	jsr	LCPProtRej	;send prot reject
	bra	55$
 50$
	lda	prRtnLTable,y
	ldx	prRtnHTable,y
	jsr	LCallRoutine
;	lda	ignoreDCD
	.byte	$af,[ignoreDCD,]ignoreDCD,0
	bmi	55$
	jsl	SCheckDCD,0
;	lda	dcdStatus
	.byte	$af,[dcdStatus,]dcdStatus,0
	bpl	90$
 55$
	jsr	MntPPP
	lda	ncpFlag
	cmp	#%00001111	;NCP all done yet?
	beq	80$
	jmp	PPPLU2
 80$
	lda	#1
	jsr	WaitPPPFrame	;pause to see if any more frames coming.
	bcc	90$
	beq	20$	;branch if another frame came in.
	sec
	rts
 90$
	clc
	rts

FireUpPPP:
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	LoadB	pppOutBuffer+4,#0
	sta	pppOutBuffer+5
	LoadB	pppOutBuffer+0,#PROTREJECT
	MoveB	lcpIdent,pppOutBuffer+1
	lda	#6
	jsr	SetLength
;	inc	lcpIdent
	jmp	OutPPPFrame

	ldx	#0
 10$
	phx
	lda	fireFrame,x
	jsr	JSLSend1Byte
	plx
	inx
	cpx	#8
	bcc	10$
	rts

fireFrame:
	.byte	$7e,$7d,$df,$7d,$23,$c0,$21,$7e

WaitPPPFrame:
	sta	r0L
	LoadB	r0H
	jsr	JSLOnTimer
 10$
	jsr	JSLCkAbortKey
	bcc	90$
;	lda	ignoreDCD
	.byte	$af,[ignoreDCD,]ignoreDCD,0
	bmi	20$
	jsl	SCheckDCD,0
;	lda	dcdStatus
	.byte	$af,[dcdStatus,]dcdStatus,0
	bpl	90$
 20$
	jsr	JSLCkTimer
	bcs	80$
	jsr	RecvPPPFrame
	lda	rPPPFlag
	cmp	#%11111111	;PPP packet received yet?
	bne	10$	;branch if not.
	sec
	rts
 80$
	lda	#1	;clear zero flag.
	sec
	rts
 90$
	clc
	rts

prNumLTable:
	.byte	[NCP_PROTOCOL,[LCP_PROTOCOL,[PAP_PROTOCOL
prNumHTable:
	.byte	]NCP_PROTOCOL,]LCP_PROTOCOL,]PAP_PROTOCOL
prRtnLTable:
	.byte	[NCP,[LCP,[PAP
prRtnHTable:
	.byte	]NCP,]LCP,]PAP

LCallRoutine:
	sta	LJmpRoutine+1
	stx	LJmpRoutine+2
	txa
	bne	LJmpRoutine
	rts
LJmpRoutine:
	jmp	$1000	;this changes.


InitPPPVars:
.if	debug
	jsr	InitDebug
.endif
	jsr	SetMagNumber
	LoadB	try2,#%00000000
	LoadB	mruSize+0,#]1500
	LoadB	mruSize+1,#[1500
	lda	#0
	sta	lcpRejSent
	sta	lcpFlag
	sta	ncpFlag
	sta	papFlag
	sta	rPPPFlag
	sta	inBufLength+0
	sta	inBufLength+1
	sta	papOn
	ldy	#3
 20$
	sta	aMapRecv,y
	sta	aMapSend,y
	sta	myIP,y
	sta	ncpOptions+2,y
	sta	dnsPrimary,y
	sta	dnsSecondary,y
	dey
	bpl	20$
	ldy	#27
	lda	#$00
 30$
	sta	aMapSend+4,y
	dey
	bpl	30$
;	lda	desDNSPrimary
	.byte	$af,[desDNSPrimary,]desDNSPrimary,0
	beq	40$
	ldx	#3
 35$
;	lda	desDNSPrimary,x
	.byte	$bf,[desDNSPrimary,]desDNSPrimary,0
	sta	dnsPrimary,x
	dex
	bpl	35$
;	lda	desDNSSecondary
	.byte	$af,[desDNSSecondary,]desDNSSecondary,0
	beq	38$
	ldx	#3
 36$
;	lda	desDNSSecondary,x
	.byte	$bf,[desDNSSecondary,]desDNSSecondary,0
	sta	dnsSecondary,x
	dex
	bpl	36$
 38$
	lda	#%10000000
	.byte	44
 40$
	lda	#%11100000
	sta	ncpBitMap
	rts

JSLCkAbortKey:
	phb
	lda	#0
	pha
	plb
	jsl	FCkAbortKey,0
	plb
	rts

JSLSend1Byte:
	phb
	pha
	lda	#0
	pha
	plb
	pla
	jsl	FSend1Byte,0
	plb
	txa
	rts

JSLGetFrmBuf:
	phb
	lda	#0
	pha
	plb
	jsl	FGetFrmBuf,0
	plb
	rts

JSLOnTimer:
	phb
	lda	#0
	pha
	plb
	jsl	FOnTimer,0
	plb
	rts

JSLCkTimer:
	phb
	lda	#0
	pha
	plb
	jsl	FCkTimer,0
	plb
	rts

SetMagNumber:
	jsl	SGetRandom
;	lda	random+0
	.byte	$af,[(random+0),](random+0),0
	sta	magNumber+0
;	lda	random+1
	.byte	$af,[(random+1),](random+1),0
	sta	magNumber+1
	jsl	SGetRandom
;	lda	random+0
	.byte	$af,[(random+0),](random+0),0
	sta	magNumber+2
;	lda	random+1
	.byte	$af,[(random+1),](random+1),0
	sta	magNumber+3
	rts

.if	debug
InitDebug:
	lda	debugBank
	bne	20$
	jsl	SGetNewBank,0
	stx	debugBank
	stx	r6L
 20$
	lda	#0
;	sta	debugEnd+0
	.byte	$8f,[(debugEnd+0),](debugEnd+0),0
	sta	r5L
;	sta	debugEnd+1
	.byte	$8f,[(debugEnd+1),](debugEnd+1),0
	sta	r5H
	rts

debugBank:
	.block	1
inString:
	.byte	"INCOMING"
	.block	3
outString:
	.byte	"OUTGOING"
	.block	3
disString:
	.byte	"DISCARD"
	.block	1

StashIncoming:
	ldy	#0
;	lda	debugEnd+0
	.byte	$af,[(debugEnd+0),](debugEnd+0),0
	sta	r5L
;	lda	debugEnd+1
	.byte	$af,[(debugEnd+1),](debugEnd+1),0
	sta	r5H
	MoveB	debugBank,r6L
	lda	lcpFlag
	sta	inString+8
	lda	ncpFlag
	sta	inString+9
	lda	papFlag
	sta	inString+10
 5$
	lda	inString,y
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	10$
	inc	r5H
 10$
	iny
	cpy	#11
	bcc	5$
	lda	inPPPPR+0
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	14$
	inc	r5H
 14$
	lda	inPPPPR+1
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	15$
	inc	r5H
 15$
	LoadW	r7,#pppInBuffer
 20$
	CmpW	r7,inPPPf
	bcs	25$
;	lda	(r7)
	.byte	$b2,r7
;	sta	[r5]
	.byte	$87,r5
	inc	r7L
	bne	22$
	inc	r7H
 22$
	inc	r5L
	bne	20$
	inc	r5H
	bne	20$
 25$
	lda	r5L
;	sta	debugEnd+0
	.byte	$8f,[(debugEnd+0),](debugEnd+0),0
	lda	r5H
;	sta	debugEnd+1
	.byte	$8f,[(debugEnd+1),](debugEnd+1),0
	rts

StashOutgoing:
	MoveW	r2,outBufLength
	ldy	#0
;	lda	debugEnd+0
	.byte	$af,[(debugEnd+0),](debugEnd+0),0
	sta	r5L
;	lda	debugEnd+1
	.byte	$af,[(debugEnd+1),](debugEnd+1),0
	sta	r5H
	MoveB	debugBank,r6L
	lda	lcpFlag
	sta	outString+8
	lda	ncpFlag
	sta	outString+9
	lda	papFlag
	sta	outString+10
 5$
	lda	outString,y
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	10$
	inc	r5H
 10$
	iny
	cpy	#11
	bcc	5$
	lda	outPPPPR+0
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	14$
	inc	r5H
 14$
	lda	outPPPPR+1
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	15$
	inc	r5H
 15$
	rep	%00010000
	ldy	#[0
	.byte	]0
 20$
	lda	pppOutBuffer,y
;	sta	[r5],y
	.byte	$97,r5
	iny
	cpy	outBufLength
	bcc	20$
	rep	%00110000
	tya
	clc
	adc	r5
	sta	r5
	sep	%00110000
	lda	r5L
;	sta	debugEnd+0
	.byte	$8f,[(debugEnd+0),](debugEnd+0),0
	lda	r5H
;	sta	debugEnd+1
	.byte	$8f,[(debugEnd+1),](debugEnd+1),0
	rts

outBufLength:
	.block	2

StashDiscard:
	ldy	#0
;	lda	debugEnd+0
	.byte	$af,[(debugEnd+0),](debugEnd+0),0
	sta	r5L
;	lda	debugEnd+1
	.byte	$af,[(debugEnd+1),](debugEnd+1),0
	sta	r5H
	MoveB	debugBank,r6L
 5$
	lda	disString,y
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	10$
	inc	r5H
 10$
	iny
	cpy	#8
	bcc	5$
	lda	inPPPPR+0
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	14$
	inc	r5H
 14$
	lda	inPPPPR+1
;	sta	[r5]
	.byte	$87,r5
	inc	r5L
	bne	15$
	inc	r5H
 15$
	LoadW	r7,#pppInBuffer
 20$
	CmpW	r7,inPPPf
	bcs	25$
;	lda	(r7)
	.byte	$b2,r7
;	sta	[r5]
	.byte	$87,r5
	inc	r7L
	bne	22$
	inc	r7H
 22$
	inc	r5L
	bne	20$
	inc	r5H
	bne	20$
 25$
	lda	r5L
;	sta	debugEnd+0
	.byte	$8f,[(debugEnd+0),](debugEnd+0),0
	lda	r5H
;	sta	debugEnd+1
	.byte	$8f,[(debugEnd+1),](debugEnd+1),0
	rts



WriteDebug:
;	lda	debugEnd+0
	.byte	$af,[(debugEnd+0),](debugEnd+0),0
	sta	r2L
;	lda	debugEnd+1
	.byte	$af,[(debugEnd+1),](debugEnd+1),0
	sta	r2H
	ora	r2L
	bne	5$
	MoveW	r5,r2
 5$
	LoadB	r3L,#0
	LoadB	a0L,#0
	sta	a0H
	MoveB	debugBank,a1L
	LoadW	r0,#testTxt
;	phk
	.byte	$4b
	PopB	r1L
	jmp	WrBigBuffer

testTxt:
	.byte	"TEST",0

.endif

RecvPPPFrame:
	bit	rPPPFlag
	bvc	5$
	jmp	RecvPPPData
 5$
	bmi	20$	;branch if waiting for the first packet byte.
;otherwise we haven't received a flag byte yet.
	LoadW	inBufPtr,#pppInBuffer
	LoadB	inCRC+0,#$ff
	sta	inCRC+1
 10$
	jsr	JSLGetFrmBuf
	bcs	15$
 12$
	rts
 15$
	cmp	#PPP_FLAG	;flag byte?
	bne	10$	;branch if not and flush this byte.
	LoadB	rPPPFlag,#%10000000
 20$
	jsr	JSLGetFrmBuf
	bcc	12$
	jsr	CkEscByte
	bcc	Discard0Packet
	cmp	#PPP_FLAG	;another flag byte?
	beq	20$	;branch if so and ignore.
	cmp	#PPP_ADDRESS	;address byte?
	bne	Discard1Packet	;branch if not.
	jsr	Add2CRC
	jsr	GetEscByte
	bcc	Discard2Packet
	cmp	#PPP_CONTROL	;control byte?
	bne	Discard3Packet	;branch if not.
	jsr	Add2CRC
	jsr	GetEscByte
	bcc	Discard4Packet
	sta	inPPPPR+0
	jsr	Add2CRC
	jsr	GetEscByte
	bcc	Discard5Packet
	sta	inPPPPR+1
	jsr	Add2CRC
	LoadB	rPPPFlag,#%11000000
	jmp	RecvPPPData


.if	debug
Discard0Packet:
	lda	#0
	.byte	44
Discard1Packet:
	lda	#1
	.byte	44
Discard2Packet:
	lda	#2
	.byte	44
Discard3Packet:
	lda	#3
	.byte	44
Discard4Packet:
	lda	#4
	.byte	44
Discard5Packet:
	lda	#5
	.byte	44
Discard6Packet:
	lda	#6
	.byte	44
Discard7Packet:
	lda	#7
	.byte	44
Discard8Packet:
	lda	#8
	.byte	44
Discard9Packet:
	lda	#9
	sta	disString+7
	jsr	StashDiscard
.else
Discard0Packet:
Discard1Packet:
Discard2Packet:
Discard3Packet:
Discard4Packet:
Discard5Packet:
Discard6Packet:
Discard7Packet:
Discard8Packet:
Discard9Packet:
.endif
	lda	#$ff
	sta	inCRC+0
	sta	inCRC+1
	LoadB	rPPPFlag,#%00000001 ;indicate bad packet received.
	sta	inBufLength+0
	sta	inBufLength+1
;	ldx	discardColor
;	jsr	ChangeBorder
;	lda	discardColor
;	eor	#%00000001
;	sta	discardColor
	rts

;discardColor:
;	.byte	0


;this is a part of RecvPPPFrame.
RecvPPPData:
 10$
	jsr	JSLGetFrmBuf
	bcc	90$
	jsr	CkEscByte
	bcc	Discard6Packet
	bne	40$	;branch if flag byte encountered.
;	sta	(inBufPtr)
	.byte	$92,inBufPtr
	jsr	Add2CRC
	inc	inBufPtr+0
	bne	10$
	inc	inBufPtr+1
	lda	inBufPtr+1
	cmp	#](pppInBuffer+$700)
	bcc	10$
	bcs	Discard7Packet
 40$
	sec
	lda	inBufPtr+0
	sbc	#2
	sta	inPPPf+0
	lda	inBufPtr+1
	sbc	#0
	sta	inPPPf+1
	lda	inCRC+0
	cmp	#$b8
	bne	Discard8Packet
	lda	inCRC+1
	cmp	#$f0
	bne	Discard9Packet
	sec
	lda	inPPPf+0
	sbc	#[pppInBuffer
	sta	inBufLength+0
	lda	inPPPf+1
	sbc	#]pppInBuffer
	sta	inBufLength+1
	LoadW	inBufPtr,#pppInBuffer
	LoadB	inCRC+0,#$ff
	sta	inCRC+1
	LoadB	rPPPFlag,#%11111111 ;indicate a packet is in.
 90$
	rts

Add2CRC:
	eor	inCRC+0
	tax
	lda	crc0Table,x
	eor	inCRC+1
	sta	inCRC+0
	lda	crc1Table,x
	sta	inCRC+1
	rts

GetEscByte:
 10$
	jsr	JSLGetFrmBuf
	bcs	80$
	jsr	JSLCkAbortKey
	bcs	10$
	rts
 80$
CkEscByte:
	cmp	#PPP_ESCAPE	;is this the escape byte?
	beq	30$	;branch if so.
	cmp	#PPP_FLAG	;is it a flag byte?
	bne	80$
 20$
	tax
	sec
	rts
 30$
	jsr	JSLGetFrmBuf	;get the next byte.
	bcs	40$
	jsr	JSLCkAbortKey
	bcs	30$
	rts
 40$
	cmp	#PPP_FLAG	;is it a flag byte?
	beq	20$	;branch if so.
	eor	#%00100000	;eor the byte.
 80$
	ldx	#0
	sec
	rts

CkASyncRecv:
	pha
	tay
	and	#%00000111
	tax
	tya
	lsr
	lsr
	lsr
	eor	#%00000011
	tay
	lda	aMapRecv,y
	and	aMapMask,x
	bne	90$
	pla
	clc
	rts
 90$
	pla
	sec
	rts

CkASyncSend:
	pha
	tay
	and	#%00000111
	tax
	tya
	lsr
	lsr
	lsr
	eor	#%00011111
	tay
	lda	aMapSend,y
	and	aMapMask,x
	bne	90$
	pla
	clc
	rts
 90$
	pla
	sec
	rts

aMapRecv:
;	.byte	$ff,$ff,$ff,$ff
	.byte	$00,$00,$00,$00
aMapSend:
;	.byte	$ff,$ff,$ff,$ff,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
aMapMask:
	.byte	%00000001
	.byte	%00000010
	.byte	%00000100
	.byte	%00001000
	.byte	%00010000
	.byte	%00100000
	.byte	%01000000
	.byte	%10000000

MntPPP:
	lda	ncpFlag	;reached NCP stage yet?
	beq	20$	;branch if not.
	cmp	#%00001111
	beq	20$
	jsr	MntNCP	;continue with NCP stage.
 20$
	lda	lcpFlag
	cmp	#%00001111
	beq	30$
;	and	#%00001001
;	cmp	#%00001001
;	beq	30$
	jmp	MntLCP	;continue with LCP stage.
 30$
	lda	papFlag
	cmp	#%00000011	;PAP stage all done?
	beq	90$	;branch if so.
;check if using pap
	bit	papOn
	bpl	90$
	jmp	MntPAP	;do PAP stage.
 90$
	rts

papOn:
	.block	1

WhiteBorder:
	ldx	#WHITE
	.byte	44
CyanBorder:
	ldx	#CYAN
	.byte	44
RedBorder:
	ldx	#RED
	.byte	44
BlueBorder:
	ldx	#BLUE
	.byte	44
GreenBorder:
	ldx	#GREEN
	.byte	44
MGrayBorder:
	ldx	#MEDGREY
	.byte	44
BlackBorder:
	ldx	#BLACK
ChangeBorder:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
	txa
;	sta	$d020
	.byte	$8f,[$d020,]$d020,0
	PopB	CPU_DATA
.endif
	rts

;if no config request sent, send now, or send one every 4 seconds.
MntLCP:
	bit	lcpRejSent
	bmi	90$
	lda	lcpFlag
	and	#%00000010	;sent 	any config requests yet?
	beq	50$	;branch if not.
	jsr	JSLCkTimer
	bcc	90$
;send config request.
 50$
	jmp	LCPConReq
 90$
	rts

;same for pap with auth req
MntPAP:
	lda	papFlag
	and	#%00000011
	cmp	#$00000011
	beq	90$
	and	#%00000010	;sent	 any auth reqs yet?
	beq	50$	;branch if not.
	jsr	JSLCkTimer
	bcc	90$
;init timer & send auth req.
 50$
	LoadW	r0,#4	;set for 4 seconds.
	jsr	JSLOnTimer
	jmp	PAPAuthReq
 90$
	rts

;same for ncp
MntNCP:
	lda	ncpFlag
	and	#%00000010	;sent 	any config requests yet?
	beq	50$	;branch if not.
	jsr	JSLCkTimer
	bcc	90$
;init timer & send auth req.
 50$
	LoadW	r0,#4	;set for 4 seconds.
	jsr	JSLOnTimer
	jmp	SendNCPConReq
 90$
	rts


LCP:
	LoadB	lcpRejSent,#%00000000
	lda	pppInBuffer+0
	cmp	#CONFREQUEST	;is it a config	 request?
	beq	LCPCfgReq	;branch if so.
	cmp	#CONFACK	;is it a config ack?
	bne	10$	;branch if not.
	jmp	LCPAk
 10$
	cmp	#TERMREQUEST	;is it a term request?
	bne	20$	;branch if not.
	jmp	LCPTermReq
 20$
	cmp	#ECHOREQUEST	;is it an echo request?
	bne	30$	;branch if not.
	jmp	LCPEchoReq
 30$
	cmp	#CONFREJECT
	beq	LCPInReject
	rts		;ignore the rest.

lcpRejSent:
	.block	1

;this deals with an incoming LCP config reject.
LCPInReject:
	ldy	#4
 10$
	lda	pppInBuffer,y
	cmp	#ASYNCHMAP
	beq	50$
	cmp	#AUTHPROTOCOL
	beq	40$
	cmp	#MRU
	beq	35$
	cmp	#MAGICNUM
	bne	60$
	lda	#%11011111
	.byte	44
 35$
	lda	#%01111111
	.byte	44
 40$
	lda	#%11101111
	.byte	44
 50$
	lda	#%10111111
	and	lcpBitMap
	sta	lcpBitMap
 60$
	iny
	tya
	clc
	adc	pppInBuffer,y
	tay
	dey
	cpy	inBufLength+0	;end of input?
	bcc	10$
	jmp	LCPConReq	;send a new request.

;handle config requests.
LCPCfgReq:
;	LoadB	lcpFlag,#%00000001
	lda	lcpFlag
	and	#%00000110
	ora	#%00000001
	sta	lcpFlag
	MoveB	pppInBuffer+1,pppOutBuffer+1
	LoadB	pppOutBuffer+2,#0
	sta	pppOutBuffer+3
	ldy	#4
	sty	lcpRecPtr	;input pointer
	sty	lcpTrPtr	;output pointer
 20$
	ldy	lcpRecPtr
	cpy	inBufLength+0	;end of input?
	bcs	CkLCPReject	;branch if so.
	lda	pppInBuffer,y
	jsr	CkLCPBitmap
	bcs	60$
;reject this option.
	ldy	lcpRecPtr
	lda	pppInBuffer,y
	ldy	lcpTrPtr
	sta	pppOutBuffer,y	;code
	inc	lcpTrPtr
	ldy	lcpRecPtr
	lda	pppInBuffer+1,y ;length
	ldy	lcpTrPtr
	sta	pppOutBuffer,y	;length
	inc	lcpTrPtr
	tax
	dex
	dex
	beq	60$
	ldy	lcpRecPtr
;copy the option to output
 50$
	phy
	lda	pppInBuffer+2,y
	ldy	lcpTrPtr
	sta	pppOutBuffer,y
	inc	lcpTrPtr
	ply
	iny
	dex
	bne	50$
 60$
	ldy	lcpRecPtr
	tya
	clc
	adc	pppInBuffer+1,y ;length
	sta	lcpRecPtr
	bra	20$

;check if we rejected anything.
CkLCPReject:
	lda	lcpTrPtr
	cmp	#4	;reject anything?
	beq	10$	;branch if not.
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	LoadB	pppOutBuffer+0,#CONFREJECT
	MoveB	pppInBuffer+1,pppOutBuffer+1
	lda	lcpTrPtr
	jsr	SetLength
	jsr	OutPPPFrame
	LoadB	lcpRejSent,#%10000000
;	LoadB	lcpFlag,#0
	lda	lcpFlag
	and	#%00000110
	sta	lcpFlag
	LoadW	r0,#4	;set for 4 seconds.
	jmp	JSLOnTimer
;naks
 10$
	ldy	#4
	sty	lcpRecPtr
	sty	lcpTrPtr
 20$
	ldy	lcpRecPtr
	cpy	inBufLength+0
	bcs	60$
	lda	pppInBuffer,y
	iny
	sty	lcpRecPtr
	cmp	#AUTHPROTOCOL
	bne	40$
	iny
	lda	pppInBuffer,y
	cmp	#]PAP_PROTOCOL
	bne	30$
	iny
	lda	pppInBuffer,y
	cmp	#[PAP_PROTOCOL
	bne	30$
	LoadB	papOn,#%10000000
	bmi	40$
;want pap, so send nak pap
 30$
	ldy	lcpTrPtr
	lda	#AUTHPROTOCOL
	sta	pppOutBuffer,y	;code
	iny
	lda	#4
	sta	pppOutBuffer,y	;len
	iny
	lda	#]PAP_PROTOCOL
	sta	pppOutBuffer,y	;pap
	iny
	lda	#[PAP_PROTOCOL
	sta	pppOutBuffer,y
	iny
	sty	lcpTrPtr
;fall through to skip option
 40$	;accept this
	ldy	lcpRecPtr
	lda	pppInBuffer,y	;len
	tax
	dex
 50$
	iny
	dex
	bne	50$
	sty	lcpRecPtr
	bra	20$
;check if we nak'ed anything
 60$
	lda	lcpTrPtr
	cmp	#4
	beq	70$	;no naks
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	lda	lcpTrPtr
	jsr	SetLength
	LoadB	pppOutBuffer+0,#CONFNAK
	jsr	OutPPPFrame
	LoadW	r0,#4	;set for 4 seconds.
	jmp	JSLOnTimer
;send ak
 70$
	lda	lcpFlag
	ora	#%00001000	;flag sent ak
	sta	lcpFlag
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	jsr	In2OutBuf
	LoadB	pppOutBuffer,#CONFACK
	jmp	OutPPPFrame
;	jmp	LCPConReq	;send our config request.

CkLCPBitmap:
;we support these options
	cmp	#ASYNCHMAP	;asyncharmap
	bne	20$
	ldx	#0
 10$
	lda	pppInBuffer+2,y
	sta	asyncRequest,x
	iny
	inx
	cpx	#4
	bcc	10$
	bcs	55$
 20$
	cmp	#AUTHPROTOCOL	;authenticate
;	beq	60$
	beq	80$
	cmp	#MRU
	beq	65$
	cmp	#MAGICNUM	;magic	 #
	beq	50$
;	cmp	#PROTCOMPRESS	;protfieldcomp
;	cmp	#ADDRCOMPRESS	;addrctrlfldcomp
;reject unsupported
	clc
	rts
 50$
	lda	#%00100000
	.byte	44
 55$
	lda	#%01000000
	.byte	44
 60$
	lda	#%00010000
	.byte	44
 65$
	lda	#%10000000
	ora	lcpBitMap
	sta	lcpBitMap
 80$
	sec
	rts

SetLength:
	sta	pppOutBuffer+3 ;length low byte.
	jsr	SetOutF
	LoadB	pppOutBuffer+2,#0 ;length high byte.
	rts

In2OutBuf:
	ldy	#0
 10$
	cpy	inBufLength+0
	bcs	50$
	lda	pppInBuffer,y
	sta	pppOutBuffer,y
	iny
	bne	10$
 50$
	tya
SetOutF:
	sta	r2L
	LoadB	r2H,#0
	rts


OutPPPFrame:
.if	debug
	PushW	r2
	jsr	StashOutgoing
	PopW	r2
.endif
	ldx	#3
 20$
	lda	outPPPPR+0
	cmp	protoHTable,x
	bne	30$
	lda	outPPPPR+1
	cmp	protoLTable,x
	beq	50$
 30$
	dex
	bpl	20$
	clc
	rts
 50$
	LoadW	r0,#pppOutBuffer
;	phk
	.byte	$4b
	PopB	r1L
	jsl	SSendPPPFrame,0
	rts

protoLTable:
	.byte	[NCP_PROTOCOL,[LCP_PROTOCOL,[PAP_PROTOCOL,[IP_PROTOCOL
protoHTable:
	.byte	]NCP_PROTOCOL,]LCP_PROTOCOL,]PAP_PROTOCOL,]IP_PROTOCOL

;got config ack
LCPAk:
	lda	lcpIdent
	dea
	cmp	pppInBuffer+1
	bne	90$
	lda	lcpFlag
	ora	#%00000100	;received ak
	sta	lcpFlag
 90$
	rts

LCPHandler:
	lda	pppInBuffer+0
	cmp	#TERMREQUEST	;is it a term request?
	beq	LCPTermReq
	clc
	rts
;got a terminate request.
LCPTermReq:
	jsr	SndTrmAck
	jsl	SDisconnect,0
	clc
	rts

SndTrmAck:
	ldy	#0
	sty	ncpFlag	;reset
	sty	lcpFlag
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	LoadB	pppOutBuffer+0,#TERMACK
	MoveB	pppInBuffer+1,pppOutBuffer+1
	lda	#4
	jsr	SetLength
	jsr	OutPPPFrame
	lda	#0
;	sta	commMode
	.byte	$8f,[commMode,]commMode,0
	rts

JSndTrmRequest:
	jsr	JClsTCPConnection
	ldy	#0
	sty	ncpFlag	;reset
	sty	lcpFlag
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	LoadB	pppOutBuffer+0,#TERMREQUEST
	MoveB	lcpIdent,pppOutBuffer+1
	inc	lcpIdent
	lda	#4
	jsr	SetLength
	jsr	OutPPPFrame
	LoadW	r0,#3
	jsr	JSLOnTimer
 20$
	jsr	JSLCkAbortKey
	bcc	90$
;	lda	ignoreDCD
	.byte	$af,[ignoreDCD,]ignoreDCD,0
	bmi	30$
	jsl	SCheckDCD,0
;	lda	dcdStatus
	.byte	$af,[dcdStatus,]dcdStatus,0
	bpl	90$
 30$
	jsr	JSLCkTimer
	bcs	90$
	jsr	RecvPPPFrame
	lda	rPPPFlag
	cmp	#%11111111	;PPP packet received yet?
	bne	20$	;branch if not.
	LoadB	rPPPFlag,#%10000000
.if	debug
	jsr	StashIncoming
.endif
	lda	inPPPPR+0
	cmp	#]LCP_PROTOCOL
	bne	20$
	lda	inPPPPR+1
	cmp	#[LCP_PROTOCOL
	bne	20$
	lda	pppInBuffer+0
	cmp	#TERMACK
	beq	90$	;branch if all done.
	cmp	#TERMREQUEST
	bne	90$
	jmp	SndTrmAck
 90$
	lda	#0
;	sta	commMode
	.byte	$8f,[commMode,]commMode,0
	rts


;got echo request
LCPEchoReq:
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	jsr	In2OutBuf
	jmp	OutPPPFrame

;send a config-request
LCPConReq:
	lda	lcpBitMap
	and	#%00010000
	beq	10$
	LoadB	papOn,#%10000000
 10$
	LoadW	r0,#4	;set for 4 seconds.
	jsr	JSLOnTimer
	lda	lcpFlag
	ora	#%00000010	;flag sent config request.
	sta	lcpFlag
LCPCR2:
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	LoadB	pppOutBuffer+0,#CONFREQUEST
	MoveB	lcpIdent,pppOutBuffer+1
	PushW	r1
	PushB	r2L
	MoveB	lcpBitMap,r1L
	ldy	#4
	ldx	#0
 55$
	lda	lcpOptions,x
	beq	80$
	lda	lcpOptions+1,x
	sta	r1H
	sta	r2L
	asl	r1L
	bcc	70$
	lda	lcpOptions,x
	cmp	#AUTHPROTOCOL
	beq	70$
 60$
	lda	lcpOptions,x
	sta	pppOutBuffer,y
	inx
	iny
	dec	r1H
	bne	60$
	beq	55$
 70$
	txa
	clc
	adc	r2L
	tax
	bne	55$	;branch always.
 80$
	PopB	r2L
	PopW	r1
	tya
	jsr	SetLength
	inc	lcpIdent
	jmp	OutPPPFrame

lcpOptions:

	.byte	MRU,4
mruSize:
	.byte	]1500,[1500

	.byte	ASYNCHMAP,6
asyncRequest:
	.byte	0,0,0,0

	.byte	MAGICNUM,6
magNumber:
	.byte	0,0,0,0

	.byte	AUTHPROTOCOL,4
	.byte	]PAP_PROTOCOL
	.byte	[PAP_PROTOCOL

	.byte	0	;end of list.

lcpBitMap:
	.byte	%11110000	;this changes.

try2:
	.block	1

;send protocol reject
LCPProtRej:
	LoadB	outPPPPR+0,#]LCP_PROTOCOL
	LoadB	outPPPPR+1,#[LCP_PROTOCOL
	MoveB	inPPPPR+0,pppOutBuffer+4
	MoveB	inPPPPR+1,pppOutBuffer+5
	LoadB	pppOutBuffer+0,#PROTREJECT
	MoveB	lcpIdent,pppOutBuffer+1
	lda	#6
	jsr	SetLength
	inc	lcpIdent
	jmp	OutPPPFrame

;receive pointer
lcpRecPtr:
	.byte	0
;transmit pointer
lcpTrPtr:
	.byte	0

;bit 0 recv'd config request
;bit 1 sent config request
;bit 2 recv'd ack
;bit 3 sent ack
lcpFlag:
	.byte	0

lcpIdent:
	.byte	0

;handle pap packets
PAP:
	lda	pppInBuffer+0
	cmp	#CONFACK
	bne	50$
	lda	papFlag
	ora	#%00000001	;got	 ack
	sta	papFlag
 45$
	rts
 50$
	cmp	#CONFREQUEST
	bne	45$
	LoadB	outPPPPR+0,#]PAP_PROTOCOL
	LoadB	outPPPPR+1,#[PAP_PROTOCOL
	ldy	#0
 60$
	lda	papAckString,y
	beq	70$
	sta	pppOutBuffer,y
	iny
	bne	60$
 70$
	tya
	jsr	SetLength
	MoveB	pppInBuffer+1,pppOutBuffer+1
	jmp	OutPPPFrame

papAckString:
	.byte	CONFACK,1,1,1	;make sure no zeros in here yet.
	.byte	23,"WHY ARE YOU LOGGING IN?",0

;send an auth-request
PAPAuthReq:
	ldx	#3
	ldy	#4
	jsr	URLBarMsg	;display "Sending username and password..."
	jsr	FixPassword
	lda	papFlag
	ora	#%00000010	;sent auth-request.
	sta	papFlag
	LoadB	outPPPPR+0,#]PAP_PROTOCOL
	LoadB	outPPPPR+1,#[PAP_PROTOCOL
	clc
	lda	#6
	adc	papIDLen
	adc	papPassLen
	sta	papLen+1
	ldy	#0
	sty	papLen+0
 20$
	lda	papTrString,y
	sta	pppOutBuffer,y
	iny
	cpy	#5
	bne	20$
	ldx	#0
 30$
;	lda	userName,x
	.byte	$bf,[userName,]userName,0
	sta	pppOutBuffer,y
	iny
	inx
	cpx	papIDLen
	bne	30$
	lda	papPassLen
	sta	pppOutBuffer,y
	iny
	ldx	#0
 50$
;	lda	userPassword,x
	.byte	$bf,[userPassword,]userPassword,0
	lsr	a
	eor	#%01111111
	sta	pppOutBuffer,y
	iny
	inx
	cpx	papPassLen
	bne	50$
	tya
	jsr	SetLength
	inc	papIdent
	jsr	OutPPPFrame
	LoadW	r0,#4
	jmp	JSLOnTimer

FixPassword:
	ldx	#0
 10$
;	lda	userName,x
	.byte	$bf,[userName,]userName,0
	beq	20$
	inx
	cpx	#32
	bcc	10$
 20$
	stx	papIDLen
	ldx	#0
 30$
;	lda	userPassword,x
	.byte	$bf,[userPassword,]userPassword,0
	beq	40$
	inx
	cpx	#32
	bcc	30$
 40$
	stx	papPassLen
	rts

;bit 0 sent auth-request.
;bit 1 ack recvd.
papFlag:
	.byte	0

papTrString:
	.byte	1
papIdent:
	.byte	0
papLen:
	.byte	0,0

papIDLen:
	.block	1
papPassLen:
	.block	1

NCP:
	lda	pppInBuffer+0
	cmp	#CONFREQUEST	;config	 request?
	beq	NCPConReq	;branch if so.
	cmp	#CONFACK	;config ack?
	bne	50$	;branch if not.
	jmp	NCPAk
 50$
	cmp	#CONFNAK	;config nak?
	bne	60$	;branch if not.
	jmp	NCPNak
 60$
	cmp	#CONFREJECT
	beq	NCPInReject
	rts		;drop anything else.

;this deals with an incoming NCP config reject.
NCPInReject:
	ldy	#4
 10$
	lda	pppInBuffer,y
	cmp	#PRIDNSREQUEST
	beq	40$
	cmp	#SECDNSREQUEST
	bne	60$
	lda	#%11011111
	.byte	44
 40$
	lda	#%10111111
	and	ncpBitMap
	sta	ncpBitMap
 60$
	iny
	tya
	clc
	adc	pppInBuffer,y
	tay
	dey
	cpy	inBufLength+0	;end of input?
	bcc	10$
	jmp	SendNCPConReq	;send a new request.

NCPConReq:
	LoadB	outPPPPR+0,#]NCP_PROTOCOL
	LoadB	outPPPPR+1,#[NCP_PROTOCOL
	lda	ncpFlag
	ora	#%00000001	;received config request.
	sta	ncpFlag
	MoveB	pppInBuffer+1,pppOutBuffer+1
	LoadB	pppOutBuffer+2,#0
	sta	pppOutBuffer+3
	ldy	#4
	sty	ncpRecv
	sty	ncpTrans
NCP11ConReq:
	ldy	ncpRecv
	cpy	inBufLength+0
	bcs	NCP20ConReq
	lda	pppInBuffer,y
	iny
	sty	ncpRecv
;accept this
	cmp	#3	;address resolution.
	beq	NCP15ConReq
;reject rest
	ldy	ncpTrans
	sta	pppOutBuffer,y	;code
	iny
	sty	ncpTrans
	ldy	ncpRecv
	lda	pppInBuffer,y	;len
	iny
	sty	ncpRecv
	ldy	ncpTrans
	sta	pppOutBuffer,y	;len
	iny
	sty	ncpTrans
	tax
	dex
NCP13ConReq:
	dex
	beq	NCP11ConReq
	ldy	ncpRecv
	lda	pppInBuffer,y
	iny
	sty	ncpRecv
	ldy	ncpTrans
	sta	pppOutBuffer,y
	iny
	sty	ncpTrans
	jmp	NCP13ConReq
NCP15ConReq:	;accept this
	lda	pppInBuffer,y	;len
	tax
	dex
;fall through to next page...

;previous page continues here.
NCP16ConReq:
	iny
	dex
	bne	NCP16ConReq
	sty	ncpRecv
	jmp	NCP11ConReq
NCP20ConReq:
	lda	ncpTrans
	cmp	#4
	beq	NCP30ConReq	;branch if no rejects
	jsr	SetLength
	LoadB	pppOutBuffer+0,#CONFREJECT
	jsr	OutPPPFrame
	LoadB	ncpFlag,#0
	LoadW	r0,#4	;set for 4 seconds.
	jmp	JSLOnTimer
NCP30ConReq:
;send ack
	lda	ncpFlag
	ora	#%00001000	;flag sent ak
	sta	ncpFlag
	jsr	In2OutBuf
	LoadB	pppOutBuffer+0,#CONFACK
	jmp	OutPPPFrame

;got configack
NCPAk:
	lda	ncpFlag
	ora	#%00000100	;receved ak
	sta	ncpFlag
	rts

;got confignak = new ip address.
NCPNak:
	ldx	#0
 10$
	lda	pppInBuffer+6,x
	sta	myIP,x
	sta	ncpCReqString+6,x
	inx
	cpx	#4
	bcc	10$
	bit	ncpBitMap
	bvc	60$
	ldx	#0
 30$
	lda	pppInBuffer+12,x
	sta	dnsPrimary,x
;	sta	desDNSPrimary,x
	.byte	$9f,[desDNSPrimary,]desDNSPrimary,0
	lda	ncpBitMap
	and	#%00100000
	beq	40$
	lda	pppInBuffer+18,x
	sta	dnsSecondary,x
;	sta	desDNSSecondary,x
	.byte	$9f,[desDNSSecondary,]desDNSSecondary,0
 40$
	inx
	cpx	#4
	bcc	30$
 60$
	jsr	DoIPSeed
	jsr	DoTCPSeed

;fall through to SendNCPConReq on next page...


;send config request
SendNCPConReq:
	lda	ncpFlag
	ora	#%00000010	;flag sent cr
	sta	ncpFlag
	MoveB	ncpIdent,ncpCReqString+1
	LoadB	outPPPPR+0,#]NCP_PROTOCOL
	LoadB	outPPPPR+1,#[NCP_PROTOCOL
	PushW	r1
	PushB	r2L
	MoveB	ncpBitMap,r1L
	ldy	#0
 50$
	lda	ncpCReqString,y
	sta	pppOutBuffer,y
	iny
	cpy	#4
	bcc	50$
	ldx	#0
 55$
	lda	ncpOptions+1,x
	sta	r1H
	sta	r2L
	asl	r1L
	bcc	70$
 60$
	lda	ncpOptions,x
	sta	pppOutBuffer,y
	inx
	iny
	dec	r1H
	bne	60$
	beq	75$
 70$
	txa
	clc
	adc	r2L
	tax
 75$
	cpx	#18
	bcc	55$
 80$
	PopB	r2L
	PopW	r1
	sty	pppOutBuffer+3
	tya
	jsr	SetLength
	inc	ncpIdent
	jmp	OutPPPFrame


;config request with our ip
ncpCReqString:
	.byte	CONFREQUEST,0,0,22
ncpOptions:
	.byte	IPADDRREQUEST,6
	.block	4
	.byte	PRIDNSREQUEST,6
dnsPrimary:
	.byte	0,0,0,0
	.byte	SECDNSREQUEST,6
dnsSecondary:
	.byte	0,0,0,0

ncpBitMap:
	.byte	%11100000	;this changes.

ncpRecv:
	.byte	0
ncpTrans:
	.byte	0

;bit 0 recv config request
;bit 1 trans config request
;bit 2 recv ak
;bit 3 trans ak
ncpFlag:
	.byte	0

ncpIdent:
	.byte	0


crc0Table: 
	.byte	$00,$89,$12,$9b,$24,$ad,$36,$bf 
	.byte	$48,$c1,$5a,$d3,$6c,$e5,$7e,$f7 
	.byte	$81,$08,$93,$1a,$a5,$2c,$b7,$3e
	.byte	$c9,$40,$db,$52,$ed,$64,$ff,$76 
	.byte	$02,$8b,$10,$99,$26,$af,$34,$bd 
	.byte	$4a,$c3,$58,$d1,$6e,$e7,$7c,$f5 
	.byte	$83,$0a,$91,$18,$a7,$2e,$b5,$3c 
	.byte	$cb,$42,$d9,$50,$ef,$66,$fd,$74 
	.byte	$04,$8d,$16,$9f,$20,$a9,$32,$bb 
	.byte	$4c,$c5,$5e,$d7,$68,$e1,$7a,$f3 
	.byte	$85,$0c,$97,$1e,$a1,$28,$b3,$3a 
	.byte	$cd,$44,$df,$56,$e9,$60,$fb,$72 
	.byte	$06,$8f,$14,$9d,$22,$ab,$30,$b9 
	.byte	$4e,$c7,$5c,$d5,$6a,$e3,$78,$f1 
	.byte	$87,$0e,$95,$1c,$a3,$2a,$b1,$38 
	.byte	$cf,$46,$dd,$54,$eb,$62,$f9,$70 
	.byte	$08,$81,$1a,$93,$2c,$a5,$3e,$b7 
	.byte	$40,$c9,$52,$db,$64,$ed,$76,$ff 
	.byte	$89,$00,$9b,$12,$ad,$24,$bf,$36 
	.byte	$c1,$48,$d3,$5a,$e5,$6c,$f7,$7e
	.byte	$0a,$83,$18,$91,$2e,$a7,$3c,$b5 
	.byte	$42,$cb,$50,$d9,$66,$ef,$74,$fd 
	.byte	$8b,$02,$99,$10,$af,$26,$bd,$34 
	.byte	$c3,$4a,$d1,$58,$e7,$6e,$f5,$7c 
	.byte	$0c,$85,$1e,$97,$28,$a1,$3a,$b3 
	.byte	$44,$cd,$56,$df,$60,$e9,$72,$fb 
	.byte	$8d,$04,$9f,$16,$a9,$20,$bb,$32 
	.byte	$c5,$4c,$d7,$5e,$e1,$68,$f3,$7a 
	.byte	$0e,$87,$1c,$95,$2a,$a3,$38,$b1 
	.byte	$46,$cf,$54,$dd,$62,$eb,$70,$f9 
	.byte	$8f,$06,$9d,$14,$ab,$22,$b9,$30 
	.byte	$c7,$4e,$d5,$5c,$e3,$6a,$f1,$78 


crc1Table: 
	.byte	$00,$11,$23,$32,$46,$57,$65,$74 
	.byte	$8c,$9d,$af,$be,$ca,$db,$e9,$f8 
	.byte	$10,$01,$33,$22,$56,$47,$75,$64 
	.byte	$9c,$8d,$bf,$ae,$da,$cb,$f9,$e8 
	.byte	$21,$30,$02,$13,$67,$76,$44,$55 
	.byte	$ad,$bc,$8e,$9f,$eb,$fa,$c8,$d9 
	.byte	$31,$20,$12,$03,$77,$66,$54,$45 
	.byte	$bd,$ac,$9e,$8f,$fb,$ea,$d8,$c9 
	.byte	$42,$53,$61,$70,$04,$15,$27,$36 
	.byte	$ce,$df,$ed,$fc,$88,$99,$ab,$ba 
	.byte	$52,$43,$71,$60,$14,$05,$37,$26 
	.byte	$de,$cf,$fd,$ec,$98,$89,$bb,$aa 
	.byte	$63,$72,$40,$51,$25,$34,$06,$17 
	.byte	$ef,$fe,$cc,$dd,$a9,$b8,$8a,$9b 
	.byte	$73,$62,$50,$41,$35,$24,$16,$07 
	.byte	$ff,$ee,$dc,$cd,$b9,$a8,$9a,$8b 
	.byte	$84,$95,$a7,$b6,$c2,$d3,$e1,$f0 
	.byte	$08,$19,$2b,$3a,$4e,$5f,$6d,$7c 
	.byte	$94,$85,$b7,$a6,$d2,$c3,$f1,$e0 
	.byte	$18,$09,$3b,$2a,$5e,$4f,$7d,$6c 
	.byte	$a5,$b4,$86,$97,$e3,$f2,$c0,$d1 
	.byte	$29,$38,$0a,$1b,$6f,$7e,$4c,$5d 
	.byte	$b5,$a4,$96,$87,$f3,$e2,$d0,$c1 
	.byte	$39,$28,$1a,$0b,$7f,$6e,$5c,$4d 
	.byte	$c6,$d7,$e5,$f4,$80,$91,$a3,$b2 
	.byte	$4a,$5b,$69,$78,$0c,$1d,$2f,$3e
	.byte	$d6,$c7,$f5,$e4,$90,$81,$b3,$a2 
	.byte	$5a,$4b,$79,$68,$1c,$0d,$3f,$2e
	.byte	$e7,$f6,$c4,$d5,$a1,$b0,$82,$93 
	.byte	$6b,$7a,$48,$59,$2d,$3c,$0e,$1f 
	.byte	$f7,$e6,$d4,$c5,$b1,$a0,$92,$83 
	.byte	$7b,$6a,$58,$49,$3d,$2c,$1e,$0f 

endOfPPP:
