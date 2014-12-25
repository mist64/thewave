;************************************************************

;		XYModem

;	Included here are the routines for handling
;	the XModem and YModem protocols.


;************************************************************


	.psect



lcommMode:
	.block	1
crcMode:
	.block	1

GetXByte:
	bit	lcommMode
	bpl	JSLGetBufByte
 10$
	jsr	JSLGetBufByte
	bcs	30$
 15$
	rts
 30$
	cmp	#IAC
	bne	80$
	jmp	JDoIACMode
 80$
	sec
	rts

JSLGetBufByte:
	phb
	lda	#0
	pha
	plb
	jsl	FGetBufByte,0
	plb
	rts


SndIfIAC:
	bit	lcommMode
	bmi	10$
	jmp	JSLSend1Byte
 10$
	cmp	#IAC
	bne	20$
	jsr	StorTCPSpot
	lda	#IAC
 20$
	jsr	StorTCPSpot
	jmp	SendBufData

DefIfIAC:
	bit	lcommMode
	bmi	10$
	jmp	JSLSend1Byte
 10$
	cmp	#IAC
	bne	20$
	jsr	StorTCPSpot
	lda	#IAC
 20$
	jmp	StorTCPSpot


CancelXModem:
	ldx	#5
	bit	lcommMode
	bmi	30$
 10$
	phx
	lda	#CAN
	jsr	JSLSend1Byte
	plx
	dex
	bne	10$
	ldx	#5
 20$
	phx
	lda	#8
	jsr	JSLSend1Byte
	plx
	dex
	bne	20$
	rts
 30$
	phx
	lda	#CAN
	jsr	StorTCPSpot
	plx
	dex
	bne	30$
	ldx	#5
 50$
	phx
	lda	#8
	jsr	StorTCPSpot
	plx
	dex
	bne	50$
	jmp	SendBufData

JSendXModem:
	jsr	SendgMsg
	jsr	RelSLNMI
	LoadB	finalPacket,#%00000000
;	lda	autoProtocol
	.byte	$af,[autoProtocol,]autoProtocol,0
	sta	xautoProtocol
	jsr	GetDesStByte
	jsr	SetPktSize
;	lda	commMode
	.byte	$af,[commMode,]commMode,0
	sta	lcommMode
;	lda	dirEntryBuf+1
	.byte	$af,[(dirEntryBuf+1),](dirEntryBuf+1),0
	sta	startBlk+0
;	sta	diskBlkBuf+0
	.byte	$8f,[(diskBlkBuf+0),](diskBlkBuf+0),0
;	lda	dirEntryBuf+2
	.byte	$af,[(dirEntryBuf+2),](dirEntryBuf+2),0
	sta	startBlk+1
;	sta	diskBlkBuf+1
	.byte	$8f,[(diskBlkBuf+1),](diskBlkBuf+1),0
	jsr	SndDoBinary
	jsr	WaitReceiver
	bcc	90$
	LoadB	r5XSave+0,#0
	sta	r5XSave+1
	LoadB	pktNumber+0,#0
	sta	pktNumber+1
;	lda	desProtocol
	.byte	$af,[desProtocol,]desProtocol,0
	cmp	#4	;is this YModem?
	bne	80$	;branch if not.
 50$
	jsr	SendXPacket	;send the header packet.
;	lda	dirEntryBuf+0
	.byte	$af,[(dirEntryBuf+0),](dirEntryBuf+0),0
	bne	60$	;branch if not the last file.
	jsr	WaitYEnd
	bra	90$
 60$
	jsr	Last60Response
	bcc	90$
	cmp	#NAK
	beq	50$
	cmp	#'C'
	bne	60$
	lda	#STX
	jsr	SetPktSize
 80$
	jsr	SendXFile
 90$
	rts

WaitYEnd:
	bit	lcommMode
	bmi	30$
 10$
	jsr	Wait60Response
	bcc	15$
	cmp	#NAK
	bne	20$
	jsr	SendXPacket	;resend the header packet.
	bcs	10$
 15$
	rts
 20$
	sec
	rts
 30$
	jsr	JSLGetBufByte
	bcs	50$
	jsr	JSLCkAbortKey
	bcc	15$
	LoadW	r0,#60
	jsr	JSLOnTimer
 40$
	jsr	JSLGetBufByte
	bcs	50$
	jsr	JSLCkAbortKey
	bcc	15$
;	lda	ignoreTimeouts
	.byte	$af,[ignoreTimeouts,]ignoreTimeouts,0
	bmi	40$
	jsr	JSLCkTimer	;check for timeout.
	bcc	40$
	clc
	rts
 50$
	cmp	#IAC
	bne	60$
	jsr	JDoIACMode
	sec
	rts
 60$
	cmp	#NAK
	bne	70$
	jsr	SendXPacket	;resend the header packet.
	bcs	40$
	rts
 70$
	sec
	rts



SendXFile:
	LoadB	bigTries,#2
	jsr	ClrBTrans
SFX1:
	jsr	LdXModBuf
	bcs	10$
	jmp	EndXSend
 10$
	inc	pktNumber+0
	bne	SFX2
	inc	pktNumber+1
SFX2:
	jsr	SendXPacket
 20$
	jsr	Last60Response
	bcc	35$
	cmp	#ACK
	bne	25$
	jsr	ShByteTrans
	jsr	ShByteSec
	jmp	SFX1
 25$
	cmp	#NAK
	beq	SFX2
	cmp	#CAN
	bne	40$
	jsr	Last5Response
	clc
 35$
	rts
 40$
	bit	xautoProtocol
	bpl	20$
	cmp	#'C'
	beq	50$
	cmp	#'K'
	bne	20$
 50$
	lda	pktNumber+1
	bne	20$
	lda	pktNumber+0
	cmp	#1
	bne	20$
	dec	bigTries
	bne	20$
	lda	#SOH	;switch to 128 byte packets.
	jsr	SetPktSize
	lda	startBlk+0	;rewind the file.
;	sta	diskBlkBuf+0
	.byte	$8f,[(diskBlkBuf+0),](diskBlkBuf+0),0
	lda	startBlk+1
;	sta	diskBlkBuf+1
	.byte	$8f,[(diskBlkBuf+1),](diskBlkBuf+1),0
	LoadB	r5XSave+0,#0
	sta	r5XSave+1
	LoadB	pktNumber+0,#0
	sta	pktNumber+1
	jmp	SendXFile	;try it again.

bigTries:
	.block	1

EndXSend:
	bit	lcommMode
	bmi	20$
 5$
	lda	#EOT
	jsr	SndIfIAC
	jsr	Wait60Response
	bcc	95$
	cmp	#NAK
	beq	5$
	cmp	#CAN
	beq	95$
	sec
	rts
 20$
	lda	#EOT
	jsr	SndIfIAC
	jsr	JSLGetBufByte
	bcs	50$
	jsr	JSLCkAbortKey
	bcc	95$
	LoadW	r0,#60
	jsr	JSLOnTimer
 40$
	jsr	JSLGetBufByte
	bcs	50$
	jsr	JSLCkAbortKey
	bcc	95$
;	lda	ignoreTimeouts
	.byte	$af,[ignoreTimeouts,]ignoreTimeouts,0
	bmi	40$
	jsr	JSLCkTimer	;check for timeout.
	bcc	40$
	clc
	rts
 50$
	cmp	#IAC
	bne	60$
	jsr	JDoIACMode
	sec
	rts
 60$
	cmp	#NAK
	bne	70$
	lda	#EOT
	jsr	SndIfIAC
	bra	40$
 70$
	cmp	#CAN
	beq	95$
	sec
	rts
 95$
	clc
	rts

ShByteTrans:
	rep	%00100000
	lda	pktSize
	clc
	adc	tBytesTrans+0
	sta	tBytesTrans+0
	sta	r0
	bcc	10$
	inc	tBytesTrans+2
 10$
	lda	tBytesTrans+2
	sta	r1
	sep	%00100000
	ldx	#5
	ldy	#1
	jmp	URLBarMsg

ClrBTrans:
	ldx	#3
	lda	#0
 10$
	sta	tBytesTrans,x
	dex
	bpl	10$
;fall through...
ZeroTOD2Clock:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
;	lda	$dd0f
	.byte	$af,[$dd0f,]$dd0f,0
	and	#%01111111
;	sta	$dd0f
	.byte	$8f,[$dd0f,]$dd0f,0
	lda	#%00000001
;	sta	$dd0b
	.byte	$8f,[$dd0b,]$dd0b,0
	lda	#0
;	sta	$dd0a
	.byte	$8f,[$dd0a,]$dd0a,0
;	sta	$dd09
	.byte	$8f,[$dd09,]$dd09,0
;	sta	$dd08
	.byte	$8f,[$dd08,]$dd08,0
.if	C64
	plx
	stx	CPU_DATA
.endif
	rts

;number of file bytes transferred.
tBytesTrans:
	.block	4

ShByteSec:
	ldx	#3
 5$
	lda	tBytesTrans,x
	sta	r3,x
	dex
	bpl	5$
	jsr	GetBytSec
	ldx	#5
	ldy	#2
	jmp	URLBarMsg

GetBytSec:
	LoadB	r2L,#10
	ldx	#r3
	ldy	#r2L
	jsr	XMult32
	jsr	GetElapsed
	lda	r1L
	ora	r8L
	beq	30$
 20$
	lsr	r1L
	ror	r0H
	ror	r0L
	lsr	r8L
	ror	r7H
	ror	r7L
	ror	r6H
	ror	r6L
	lda	r1L
	ora	r8L
	bne	20$
 30$
	lda	r0L
	ora	r0H
	bne	35$
	sta	r1H
	rts
 35$
	ldy	#r0
	jsl	SD32div,0
	ldx	#3
 40$
	lda	r6,x
	sta	r0,x
	dex
	bpl	40$
	rts


GetElapsed:
	ldx	#2
	lda	#0
 10$
	sta	r0,x
	dex
	bpl	10$
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
;	lda	$dd0b
	.byte	$af,[$dd0b,]$dd0b,0
	and	#%00011111
	dea
	beq	30$
	pha
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tax
	beq	20$
	LoadW	r0,#$7e40
	LoadB	r1L,#$05
 20$
	pla
	and	#%00001111
	tax
	beq	30$
	lda	hrLLTable-1,x
	clc
	adc	r0L
	sta	r0L
	lda	hrLMTable-1,x
	adc	r0H
	sta	r0H
	lda	hrLHTable-1,x
	adc	r1L
	sta	r1L
 30$
;	lda	$dd0a
	.byte	$af,[$dd0a,]$dd0a,0
	beq	50$
	pha
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tax
	beq	40$
	lda	mnHLTable-1,x
	clc
	adc	r0L
	sta	r0L
	lda	mnHMTable-1,x
	adc	r0H
	sta	r0H
	bcc	40$
	inc	r1L
 40$
	pla
	and	#%00001111
	tax
	beq	50$
	lda	mnLLTable-1,x
	clc
	adc	r0L
	sta	r0L
	lda	mnLMTable-1,x
	adc	r0H
	sta	r0H
	bcc	50$
	inc	r1L
 50$
;	lda	$dd09
	.byte	$af,[$dd09,]$dd09,0
	beq	70$
	pha
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tax
	beq	60$
	lda	scHLTable-1,x
	clc
	adc	r0L
	sta	r0L
	lda	scHMTable-1,x
	adc	r0H
	sta	r0H
	bcc	60$
	inc	r1L
 60$
	pla
	and	#%00001111
	tax
	beq	70$
	lda	scLLTable-1,x
	clc
	adc	r0L
	sta	r0L
	bcc	70$
	inc	r0H
	bne	70$
	inc	r1L
 70$
;	lda	$dd08
	.byte	$af,[$dd08,]$dd08,0
	beq	80$
	clc
	adc	r0L
	sta	r0L
	bcc	80$
	inc	r0H
	bne	80$
	inc	r1L
 80$
.if	C64
	PopB	CPU_DATA
.endif
	rts

hrLLTable:
	.byte	$a0,$40,$e0,$80,$20,$c0,$60,$00,$a0
hrLMTable:
	.byte	$8c,$19,$a5,$32,$bf,$4b,$d8,$65,$f1
hrLHTable:
	.byte	$00,$01,$01,$02,$02,$03,$03,$04,$04

mnHLTable:
	.byte	$70,$e0,$50,$c0,$30
mnHMTable:
	.byte	$17,$2e,$46,$5d,$75
mnLLTable:
	.byte	$58,$b0,$08,$60,$b8,$10,$68,$c0,$18
mnLMTable:
	.byte	$02,$04,$07,$09,$0b,$0e,$10,$12,$15

scHLTable:
	.byte	$64,$c8,$2c,$90,$f4
scHMTable:
	.byte	$00,$00,$01,$01,$01
scLLTable:
	.byte	$0a,$14,$1e,$28,$32,$3c,$46,$50,$5a

SendXPacket:
	LoadB	nxtXBufByte+0,#0
	sta	nxtXBufByte+1
	LoadB	crc16+0,#0
	sta	crc16+1
	sta	ckSum
	lda	startByte
	jsr	DefIfIAC
	lda	pktNumber+0
	jsr	DefIfIAC
	lda	pktNumber+0
	eor	#%11111111
	jsr	DefIfIAC
 20$
	rep	%00010000
	ldx	nxtXBufByte
	lda	xModBuffer,x
	inx
	stx	nxtXBufByte
	sep	%00010000
	pha
	jsr	DefIfIAC
	pla
	jsr	Add2Cksum
	CmpW	nxtXBufByte,pktSize
	bcc	20$
	jsr	SndCkSum
	bit	lcommMode
	bpl	80$
 30$
	LoadW	r0,#15
	jsr	JSLOnTimer
 40$
	jsr	JLdTCPBlock
	bcs	80$
	jsr	JSLCkAbortKey
	bcc	80$
	jsr	JSLCkTimer
	bcc	40$
	jsr	RepeatPacket
	bra	30$
 80$
	sec
	rts


GetDesStByte:
;	lda	desProtocol
	.byte	$af,[desProtocol,]desProtocol,0
	tax
	cpx	#8
	bcc	5$
	ldx	#3
 5$
	lda	strtByteTable,x
	rts

WaitReceiver:
	bit	xautoProtocol
	bpl	60$
 20$
	jsr	LastXByte
	bcc	40$
	jsr	SetCRCMode
	bcs	45$
 40$
	jsr	Last60Response
	bcc	45$
	jsr	SetCRCMode
	bcc	40$
 45$
	rts
 60$
	jsr	LastXByte
	bcc	70$
	jsr	SetCRCMode
	bcs	45$
 70$
	jsr	Last60Response
	bcc	45$

;fall through...

SetCRCMode:
	cmp	#NAK
	beq	40$
	cmp	#'C'
	beq	30$
	cmp	#'K'
	bne	90$
 30$
	lda	#%10000000
	.byte	44
 40$
	lda	#%00000000
	sta	crcMode
	sec
	rts
 90$
	clc
	rts

Wait1Response:
	lda	#1
	.byte	44
Wait5Response:
	lda	#5
	.byte	44
Wait30Response:
	lda	#30
	.byte	44
Wait60Response:
	lda	#60
WaitResponse:
	sta	WR2+1
	jsr	GetXByte	;go fetch a byte from the incoming buffer.
	bcc	WR2
	rts
WR2:
	lda	#30	;this changes.
	sta	r0L
	LoadB	r0H,#0
;	lda	ignoreTimeouts
	.byte	$af,[ignoreTimeouts,]ignoreTimeouts,0
	bmi	50$
	jsr	JSLOnTimer
 20$
	jsr	GetXByte	;go fetch a byte from the incoming buffer.
	bcs	48$
	jsr	JSLCkAbortKey
	bcc	48$
	jsr	JSLCkTimer	;check for STOP key or timeout.
	bcc	20$	;branch back if timeout has not occurred yet.
 45$
	clc
 48$
	rts
 50$
	jsr	GetXByte	;go fetch a byte from the incoming buffer.
	bcc	60$
	rts
 60$
	jsr	JSLCkAbortKey
	bcs	50$
	rts


Last1Response:
	lda	#1
	.byte	44
Last5Response:
	lda	#5
	.byte	44
Last30Response:
	lda	#30
	.byte	44
Last60Response:
	lda	#60
LastResponse:
	sta	LR2+1
	jsr	LastXByte
	bcc	LR2
	rts
LR2:
	lda	#30	;this changes.
	sta	r0L
	LoadB	r0H,#0
;	lda	ignoreTimeouts
	.byte	$af,[ignoreTimeouts,]ignoreTimeouts,0
	bmi	50$
	jsr	JSLOnTimer
 20$
	jsr	LastXByte
	bcc	30$
	rts
 30$
	jsr	JSLCkAbortKey
	bcc	48$
	jsr	JSLCkTimer	;check for STOP key or timeout.
	bcc	20$	;branch back if timeout has not occurred yet.
	clc
 48$
	rts
 50$
	jsr	LastXByte
	bcs	80$
 60$
	jsr	JSLCkAbortKey
	bcs	50$
 80$
	rts


LastXByte:
	jsr	GetXByte	;go fetch a byte from the incoming buffer.
	bcs	5$
	rts
 5$
	sta	LXB80+1
 10$
	jsr	GetXByte	;go fetch a byte from the incoming buffer.
	bcs	5$
LXB80:
	lda	#0	;this changes.
	sec
	rts

JRecvXModem:
	jsr	StrtTrMsg
	jsr	StartXFile
	jsr	RelSLNMI
	jsr	InitBinary
	jsr	Get1stPByte
	bcc	90$
	jsr	RcvXFile
	bcc	90$
	jsr	CloseXFile
	lda	#ACK
	jsr	SndIfIAC
	bit	lcommMode
	bpl	50$
	jsr	SndDMTelnet
 50$
	sec
	rts
 90$
	jsr	CloseXFile
	jsr	CancelXModem
	bit	lcommMode
	bpl	95$
	jsr	SndDMTelnet
 95$
	clc
	rts

Get1stPByte:
	LoadB	file32Size+0,#$ff
	sta	file32Size+1
	sta	file32Size+2
	sta	file32Size+3
 5$		;flush any bytes accumulated.
	jsr	JSLCkAbortKey
	bcc	90$
	jsr	GetXByte	;go fetch a byte from the incoming buffer.
	bcs	5$	;branch if we got a byte.
 10$
	LoadB	crcMode,#%10000000
	LoadB	crcTglCount,#0
	bit	xautoProtocol
	bmi	30$
;	lda	desProtocol
	.byte	$af,[desProtocol,]desProtocol,0
	cmp	#1
	bne	30$
	LoadB	crcMode,#%00000000
 30$
	LoadB	timeXOut,#5
	bne	50$	;branch always.
 40$
	bit	xautoProtocol
	bpl	50$
	lda	crcMode
	eor	#%10000000
	sta	crcMode
 50$
	LoadW	r0,#3
	jsr	JSLOnTimer
	jsr	CRCStByte
	jsr	SndIfIAC
 60$
	jsr	GetXByte	;go fetch a byte from the incoming buffer.
	bcs	70$	;branch if we got a byte.
	jsr	JSLCkAbortKey
	bcc	90$
	jsr	JSLCkTimer
	bcc	60$	;branch back if timeout has not occurred yet.
	inc	crcTglCount
	lda	crcTglCount
	and	#%00000011
	bne	50$
	dec	timeXOut
	bne	40$
;	lda	ignoreTimeouts
	.byte	$af,[ignoreTimeouts,]ignoreTimeouts,0
	bmi	10$
	bpl	90$
 70$
	cmp	#CAN
	beq	90$
	jsr	SetPktSize
	bcc	60$
	rts
 90$
	clc
	rts

InitBinary:
;	lda	commMode
	.byte	$af,[commMode,]commMode,0
	sta	lcommMode
;	lda	autoProtocol
	.byte	$af,[autoProtocol,]autoProtocol,0
	sta	xautoProtocol
	jmp	SndDoBinary

CRCStByte:
	lda	crcMode
	asl	a
	rol	a
	and	#%00000001
	tax
	lda	crcIndicators,x
	rts

crcIndicators:
	.byte	NAK,"C"
crcTglCount:
	.block	1
timeXOut:
	.block	1
pktNumber:
	.block	2
startByte:
	.block	1
startBlk:
	.block	2
xautoProtocol:
	.block	1

;+++this table is not finished. Bytes
;+++5-7 are not correct.
strtByteTable:
	.byte	0,SOH,SOH,STX,SOH,STX,STX,0

RcvXFile:
	jsr	ClrBTrans
	LoadW	pktNumber,#1
RXF1:
	jsr	RcvXPacket
	bcc	RXF90
	inc	pktNumber+0
	bne	15$
	inc	pktNumber+1
 15$
	jsr	SvXModBuf
	bcc	RXF90
	jsr	ShByteTrans
	jsr	ShByteSec
	lda	#ACK
	jsr	SndIfIAC
RXF2:
 20$
;+++fix this to watch for CAN, CAN.
	jsr	Wait30Response
	bcc	RXF90
	cmp	#EOT
	beq	80$
	jsr	SetPktSize
	bcs	RXF1
	bcc	20$
 80$
	sec
	rts
RXF90:
	clc
	rts

SetPktSize:
	cmp	#STX
	beq	40$
	cmp	#SOH
	bne	90$
	sta	startByte
	LoadW	pktSize,#128
	sec
	rts
 40$
	sta	startByte
	LoadW	pktSize,#1024
	sec
	rts
 90$
	clc
	rts

RcvXPacket:
 5$
	LoadB	nxtXBufByte+0,#0
	sta	nxtXBufByte+1
	sta	crc16+0
	sta	crc16+1
	sta	ckSum
 10$
	jsr	Wait5Response
	bcc	90$
	cmp	pktNumber+0
	bne	50$
	cmp	#CR
	bne	25$
	bit	lcommMode
	bpl	25$
	jsr	Wait1Response
	bcc	90$
	cmp	#0
	bne	30$
 25$
	jsr	Wait1Response
	bcc	90$
 30$
	eor	#%11111111
	cmp	pktNumber+0
 35$
	jsr	Wait1Response
	bcc	90$
	rep	%00010000
	ldx	nxtXBufByte
	sta	xModBuffer,x
	inx
	stx	nxtXBufByte
	sep	%00010000
	jsr	Add2Cksum
	CmpW	nxtXBufByte,pktSize
	bcc	35$
	jsr	RecvCksum
	bcc	90$
	beq	80$
 40$
	lda	#NAK
	jsr	SndIfIAC
 45$
	jsr	Wait30Response
	bcc	90$
	cmp	startByte
	beq	5$
	bne	45$
 50$
	jsr	Wait1Response
	bcc	90$
 60$
	jsr	FlushPkt
	bcs	40$
	rts
 80$
	sec
	rts
 90$
	clc
	rts


;this will flush the remaining incoming bytes
;of a bad packet.
FlushPkt:
 10$
	jsr	Wait1Response
	bcc	90$
	inc	nxtXBufByte+0
	bne	20$
	inc	nxtXBufByte+1
 20$
	lda	nxtXBufByte+1
	cmp	pktSize+1
	bne	30$
	lda	nxtXBufByte+0
	cmp	pktSize+0
 30$
	bcc	10$
	jsr	Wait1Response
	bcc	90$
	bit	crcMode
	bpl	80$
	jsr	Wait1Response
	bcc	90$
 80$
	sec
	rts
 90$
	clc
	rts

crc16:
	.block	2
ckSum:
	.block	1

SndCkSum:
	bit	crcMode
	bmi	50$
	lda	ckSum
	jmp	SndIfIAC
 50$
	lda	#0
	jsr	Add2XCRC
	lda	#0
	jsr	Add2XCRC
	lda	crc16+1
	jsr	DefIfIAC
	lda	crc16+0
	jmp	SndIfIAC

RecvCksum:
	jsr	Wait1Response
	bcc	90$
	bit	crcMode
	bmi	40$
	cmp	ckSum
	sec
	rts
 40$
	sta	ckSum
	lda	#0
	jsr	Add2XCRC
	lda	#0
	jsr	Add2XCRC
	jsr	Wait1Response
	bcc	90$
	cmp	crc16+0
	bne	85$
	lda	ckSum
	cmp	crc16+1
 85$
	sec
	rts
 90$
	clc
	rts

Add2Cksum:
	bit	crcMode
	bmi	5$
	clc
	adc	ckSum
	sta	ckSum
	rts
 5$
;fall through...

;this trashes only r0.
Add2XCRC:
	rep	%00100000
;	xba
	.byte	$eb
	sta	r0
	lda	crc16
	ldx	#8
 10$
	asl	r0
	rol	a
	bcc	40$
	eor	#[$1021
	.byte	]$1021
 40$
	dex
	bne	10$
	sta	crc16
	sep	%00100000
	rts

;call this with dirEntryBuf holding the directory entry of
;the desired file to be sent. If the last file has been sent
;then call this with dirEntryBuf+0 holding a null byte.
JSendYModem:
;	lda	dirEntryBuf+0
	.byte	$af,[(dirEntryBuf+0),](dirEntryBuf+0),0
	beq	60$	;branch if no more files.
	jsr	BuildY0Packet
	bcs	80$
	rts
 60$
	jsr	ClrY0Packet
 80$
	jmp	JSendXModem


JRecvYModem:
	jsr	InitBinary
JRYM:
	jsr	Get1stPByte
	bcc	4$
	LoadB	pktNumber+0,#0
	sta	pktNumber+1
	sta	xModBuffer
	jsr	RcvXPacket
	bcc	4$
	lda	xModBuffer	;is this an empty packet?
	bne	5$	;branch if not.
	lda	#ACK
	jsr	SndIfIAC
	bit	lcommMode
	bpl	3$
	jsr	SndDMTelnet
 3$
	sec
 4$
	rts
 5$
	LoadW	r0,#xModBuffer
;	phk
	.byte	$4b
	PopB	r1L
	jsr	StrtTrMsg
	jsr	StartXFile
	jsr	RelSLNMI
	ldx	#0
 10$
	lda	xModBuffer,x
	beq	20$
	inx
	bne	10$
 20$
	inx
	ldy	#0
 30$
	lda	xModBuffer,x
	sta	asc32String,y
	beq	40$
	cmp	#' '
	beq	40$
	inx
	iny
	cpy	#10
	bcc	30$
 40$
	lda	#0
	sta	asc32String,y
	LoadW	r0,#asc32String
;	phk
	.byte	$4b
	PopB	r1L
	jsl	SDecTo32,0
	bcc	50$
	MoveB	r2L,file32Size+0
	MoveB	r2H,file32Size+1
	MoveB	r3L,file32Size+2
	MoveB	r3H,file32Size+3
 50$
	lda	#ACK
	jsr	SndIfIAC
	jsr	CRCStByte
	jsr	SndIfIAC
	jsr	ClrBTrans
	LoadW	pktNumber,#1
	jsr	RXF2
	bcc	90$
	jsr	CloseXFile
	lda	#ACK
	jsr	SndIfIAC
	jmp	JRYM
 90$
	jsr	CloseXFile
	jsr	CancelXModem
	clc
	rts


JSendZModem:
	rts

JRecvZModem:
	rts


;this builds the first packet (#0) for a YModem file transfer.
;The 128 byte packet is built in xModBuffer.
BuildY0Packet:
	jsr	ClrY0Packet
	jsr	BuildFName
	phx
;	lda	dirEntryBuf+1
	.byte	$af,[(dirEntryBuf+1),](dirEntryBuf+1),0
	sta	r1L
;	lda	dirEntryBuf+2
	.byte	$af,[(dirEntryBuf+2),](dirEntryBuf+2),0
	sta	r1H
	jsr	ChainSize
	php
	jsr	RelSLNMI
	plp
	bcc	90$	;branch if a file error.
	ldx	#3
 10$
	lda	file32Size,x
	sta	r0,x
	dex
	bpl	10$
	jsr	SizeToDec
	plx
	ldy	#0
 20$
;	lda	[r0],y
	.byte	$b7,r0
	beq	30$
	sta	xModBuffer,x
	inx
	iny
	cpy	#10
	bcc	20$
 30$
	sec
	rts
 90$
	plx
ClrY0Packet:
	ldy	#127
	lda	#0
 10$
	sta	xModBuffer,y	;zero out the buffer.
	dey
	bpl	10$
	clc
	rts


RelSLNMI:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	jsl	SCkRecv,0
.if	C64
	PopB	CPU_DATA
.endif
	rts

;this will copy the filename from dirEntryBuf to
;xModBuffer. The filename will be null terminated.
;Upon exit, x will point to the next byte past the
;null terminator.
BuildFName:
	ldx	#0
 10$
;	lda	dirEntryBuf+3,x
	.byte	$bf,[(dirEntryBuf+3),](dirEntryBuf+3),0
	beq	20$
	cmp	#$a0
	beq	20$
	sta	xModBuffer,x
	inx
	cpx	#16
	bcc	10$
 20$
	lda	#0
	sta	xModBuffer,x
	inx
	rts

;point r1L,r1H to the first block in the chain.
;The number of blocks will be returned in blkCount
;while the filesize (in bytes) will be returned
;in file32Size. If an error occurs while reading
;through the chain of blocks, the carry will be clear.
ChainSize:
	LoadB	blkCount+0,#0
	sta	blkCount+1
	jsl	SEnterTurbo,0
	jsl	SInitForIO,0
	LoadW	r4,#diskBlkBuf
 20$
	jsl	SReadLink,0
	bne	90$
	inc	blkCount+0
	bne	30$
	inc	blkCount+1
 30$
;	lda	diskBlkBuf+1
	.byte	$af,[(diskBlkBuf+1),](diskBlkBuf+1),0
	sta	r1H
;	lda	diskBlkBuf+0
	.byte	$af,[(diskBlkBuf+0),](diskBlkBuf+0),0
	sta	r1L
	bne	20$
	jsl	SDoneWithIO,0
	lda	r1H
	beq	40$
	dea
 40$
	pha
	sec
	lda	blkCount+0
	sbc	#1
	sta	r0L
	lda	blkCount+1
	sbc	#0
	sta	r0H
	LoadB	r1L,#254
	ldx	#r0
	ldy	#r1L
	jsl	SBMult,0
	pla
	clc
	adc	r6L
	sta	file32Size+0
	lda	r6H
	adc	#0
	sta	file32Size+1
	lda	r7L
	adc	#0
	sta	file32Size+2
	lda	r7H
	adc	#0
	sta	file32Size+3
	sec
	rts
 90$
	jsl	SDoneWithIO,0
	clc
	rts

blkCount:
	.block	2
file32Size:
	.block	4
asc32String:
	.block	11

;this converts the 5 byte year,month,day,hour,minutes into
;an ascii string representing the number of seconds since 1/1/70.
;If the date is invalid, the carry will be clear and there
;will be no ascii string generated.
AsciiSeconds:
	ldy	#9
	lda	#'0'
 10$
	sta	ascDecSeconds,y
	dey
	bpl	10$
	LoadB	ascDecSeconds+10,#0
	jsr	DateSeconds
	bcc	90$
	jsr	Sec2Ascii
	LoadW	r0,#ascDecSeconds
;	phk
	.byte	$4b
	PopB	r1L
	sec
	rts
 90$
	clc
	rts

seconds70:
	.block	4

ascDecSeconds:
	.block	11

Sec2Ascii:
	LoadB	digitCount,#0
	ldx	#3
 10$
	lda	seconds70,x
	sta	r5,x
	dex
	bpl	10$
 12$
	jsr	SetR3Digit
 15$
	jsr	SubR3R5
	bcc	20$
	ldx	digitCount
	inc	ascDecSeconds,x
	bne	15$	;branch always.
 20$
	inc	digitCount
	lda	digitCount
	cmp	#9
	bcc	12$
	clc
	lda	r5L
	adc	#'0'
	sta	ascDecSeconds+9
;now get rid of leading zeros.
	ldy	#0
	ldx	#0
 30$
	lda	ascDecSeconds,x ;find the first non-zero digit.
	cmp	#'0'
	bne	40$
	inx
	cpx	#9	;stop at the ones digit.
	bcc	30$
 40$
	lda	ascDecSeconds,x
	sta	ascDecSeconds,y
	iny
	inx
	cpx	#10
	bcc	40$
	lda	#0
	sta	ascDecSeconds,y
	rts

digitCount:
	.block	1

SubR3R5:
	rep	%00100000
	sec
	lda	r5
	sbc	r3
	sta	r5
	lda	r6
	sbc	r4
	sta	r6
	bcs	80$
	lda	r5
	adc	r3
	sta	r5
	lda	r6
	adc	r4
	sta	r6
	clc
 80$
	sep	%00100000
	rts

SetR3Digit:
	lda	digitCount
	asl	a
	asl	a
	tay
	ldx	#0
 10$
	lda	digitTable,y
	sta	r3,x
	iny
	inx
	cpx	#4
	bcc	10$
	rts

digitTable:
	.byte	$00,$ca,$9a,$3b ;1,000,000,000
	.byte	$00,$e1,$f5,$05 ;100,000,000
	.byte	$80,$96,$98,$00 ;10,000,000
	.byte	$40,$42,$0f,$00 ;1,000,000
	.byte	$a0,$86,$01,$00 ;100,000
	.byte	$10,$27,$00,$00 ;10,000
	.byte	$e8,$03,$00,$00 ;1,000
	.byte	$64,$00,$00,$00 ;100
	.byte	$0a,$00,$00,$00 ;10
	.byte	$01,$00,$00,$00 ;1



;this calculates a date in seconds since Jan. 1, 1970.
;Call this with r0 (3byte pointer) pointing to 5 bytes representing
;the date to calculate. The 5 bytes should represent the
;following: year,month,day,hour,minute
;These 5 bytes are in the same format and order as found
;in the timestamp on a GEOS file.
DateSeconds:
	jsr	ZeroSeconds
	jsr	Get70Year
	bcc	90$
	jsr	AddYears
	ldy	#1
;	lda	[r0],y	;get the month.
	.byte	$b7,r0
	beq	90$
	cmp	#13
	bcs	90$
	jsr	AddMonths
	jsr	AddDays
	bcc	90$
	ldy	#3
;	lda	[r0],y	;get the hour.
	.byte	$b7,r0
	beq	20$	;skip if within the first hour.
	cmp	#24
	bcs	90$
	jsr	AddHours
 20$
	ldy	#4
;	lda	[r0],y	;get the minutes.
	.byte	$b7,r0
	beq	30$	;branch if within the first minute.
	cmp	#60
	bcs	90$
	jsr	AddMinutes
 30$
	LoadW	r0,#seconds70
;	phk
	.byte	$4b
	PopB	r1L
	sec
	rts
 90$
	jsr	ZeroSeconds
	clc
	rts


ZeroSeconds:
	ldy	#3
	lda	#0
 10$
	sta	seconds70,y
	dey
	bpl	10$
	rts

Get70Year:
	ldy	#0
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#100
	bcs	90$
	sec
	sbc	#70
	bcs	10$
	adc	#100
 10$
	sec
	rts
 90$
	clc
	rts

AddYears:
	sta	r2L
	ldx	#3
 10$
	lda	yearSeconds,x
	sta	r3,x
	dex
	bpl	10$
	ldx	#r3
	ldy	#r2L
	jsr	XMult32
;fall through...
AddR6Seconds:
	clc
	lda	seconds70+0
	adc	r6L
	sta	seconds70+0
	lda	seconds70+1
	adc	r6H
	sta	seconds70+1
	lda	seconds70+2
	adc	r7L
	sta	seconds70+2
	lda	seconds70+3
	adc	r7H
	sta	seconds70+3
	rts

;this 32 bit number represents the number
;of seconds in a 365 day year.
;This is 31,536,000.
yearSeconds:
	.byte	$80,$33,$e1,$01

AddMonths:
	sta	r2L
	dea
	beq	80$	;branch if January.
	dea
	asl	a
	asl	a
	tax
	clc
	lda	monthSeconds+0,x
	adc	seconds70+0
	sta	seconds70+0
	lda	monthSeconds+1,x
	adc	seconds70+1
	sta	seconds70+1
	lda	monthSeconds+2,x
	adc	seconds70+2
	sta	seconds70+2
	lda	monthSeconds+3,x
	adc	seconds70+3
	sta	seconds70+3
	lda	r2L
	cmp	#3	;is this March?
	bne	80$	;branch if leap year calc not needed.
	jsr	Get70Year
	clc
	adc	#2
	and	#%00000011	;is this a leap year?
	bne	80$	;branch if not.
	clc
	lda	#$80	;add another 86,400 to the result.
	adc	seconds70+0
	sta	seconds70+0
	lda	#$51
	adc	seconds70+1
	sta	seconds70+1
	lda	#$01
	adc	seconds70+2
	sta	seconds70+2
	lda	#$00
	adc	seconds70+3
	sta	seconds70+3
 80$
	rts

monthSeconds:
	.byte	$80,$de,$28,$00 ;January
	.byte	$00,$ea,$24,$00 ;February
	.byte	$80,$de,$28,$00 ;March
	.byte	$00,$8d,$27,$00 ;April
	.byte	$80,$de,$28,$00 ;May
	.byte	$00,$8d,$27,$00 ;June
	.byte	$80,$de,$28,$00 ;July
	.byte	$80,$de,$28,$00 ;August
	.byte	$00,$8d,$27,$00 ;September
	.byte	$80,$de,$28,$00 ;October
	.byte	$00,$8d,$27,$00 ;November
			;December not needed here.

AddDays:
	ldy	#1
;	lda	[r0],y	;get the month.
	.byte	$b7,r0
	tax
	ldy	#2
;	lda	[r0],y	;get the day.
	.byte	$b7,r0
	beq	90$
	cmp	maxDays-1,x
	bcc	10$
	bne	90$
 10$
	dea
	beq	80$
	sta	r2L
	LoadB	r3L,#$80	;r3 equals 86,400 (32 bits)
	LoadB	r3H,#$51
	LoadB	r4L,#$01
	LoadB	r4H,#$00
	ldx	#r3
	ldy	#r2L
	jsr	XMult32
	jsr	AddR6Seconds
 80$
	sec
	rts
 90$
	clc
	rts

maxDays:
	.byte	31,28,31,30,31,30,31,31,30,31,30,31

AddHours:
	sta	r2L
	LoadW	r3,#3600
	ldx	#r3
	ldy	#r2L
	jsl	SBMult,0
	jmp	AddR6Seconds

AddMinutes:
	sta	r2L
	LoadW	r3,#60
	ldx	#r3
	ldy	#r2L
	jsl	SBMult,0
	jmp	AddR6Seconds

;this multiplies an 8 bit number with a 32 bit number.
;The result is left in r6L-r8L (40 bits)
XMult32:
	phx
	tyx
	lda	$00,x
	sta	r8H
	plx
	LoadB	r8L,#32
	lda	#0
 20$
	lsr	$03,x
	ror	$02,x
	ror	$01,x
	ror	$00,x
	bcc	50$
	clc
	adc	r8H
 50$
	ror	a
	ror	r7H
	ror	r7L
	ror	r6H
	ror	r6L
	dec	r8L
	bne	20$
	sta	r8L
	rts


;call this with r0 (3bytes) pointing to a null-terminated
;filename. This will then start a new file with the
;first block allocated. This returns with the track and
;sector of the first block to begin writing to in the
;first two bytes of diskBlkBuf.
StartXFile:
	LoadB	xEntBuf+28,#0
	sta	xEntBuf+29
	jsr	MoveFName	;copy the filename to the dir entry.
	jsl	SGetDirHead,0
	LoadW	r2,#254
	LoadW	r6,#fileTrScTab
	jsl	SBlkAlloc,0
	lda	r3L
;	sta	diskBlkBuf+0
	.byte	$8f,[(diskBlkBuf+0),](diskBlkBuf+0),0
	sta	xEntBuf+1
	lda	r3H
;	sta	diskBlkBuf+1
	.byte	$8f,[(diskBlkBuf+1),](diskBlkBuf+1),0
	sta	xEntBuf+2
	ldx	#2
	stx	nxtXByte	;next byte to write.
	lda	#0
 40$
;	sta	diskBlkBuf,x	;clear diskBlkBuf.
	.byte	$9f,[diskBlkBuf,]diskBlkBuf,0
	inx
	bne	40$
	rts

MoveFName:
	ldy	#0
 10$
;	lda	[r0],y
	.byte	$b7,r0
	beq	20$
	sta	xEntBuf+3,y
	iny
	cpy	#16
	bcc	10$
	rts
 20$
	lda	#$a0
 30$
	sta	xEntBuf+3,y
	iny
	cpy	#16
	bcc	30$
	rts

xEntBuf:
	.byte	$82
	.block	2
	.block	16
	.block	4
	.block	5
	.block	2


CloseXFile:
;	lda	diskBlkBuf+0
	.byte	$af,[(diskBlkBuf+0),](diskBlkBuf+0),0
	sta	r1L
;	lda	diskBlkBuf+1
	.byte	$af,[(diskBlkBuf+1),](diskBlkBuf+1),0
	sta	r1H
	lda	#0
;	sta	diskBlkBuf+0
	.byte	$8f,[(diskBlkBuf+0),](diskBlkBuf+0),0
	ldy	nxtXByte
	dey
	tya
;	sta	diskBlkBuf+1
	.byte	$8f,[(diskBlkBuf+1),](diskBlkBuf+1),0
	LoadW	r4,#diskBlkBuf
	jsl	SPutBlock,0
	inc	xEntBuf+28	;increment the block count.
	bne	30$
	inc	xEntBuf+29
 30$
	LoadB	r10L,#0
	jsl	SGetFreeDirBlk,0
	tyx
	ldy	#0
 50$
	lda	xEntBuf,y
;	sta	diskBlkBuf,x
	.byte	$9f,[diskBlkBuf,]diskBlkBuf,0
	inx
	iny
	cpy	#30
	bcc	50$
	jsl	SPutBlock,0
	jsl	SPutDirHead,0
	rts


SvXModBuf:
	LoadB	nxtXBufByte+0,#0
	sta	nxtXBufByte+1
	lda	pktSize+0
	ora	pktSize+1
	beq	80$
	lda	file32Size+0
	ora	file32Size+1
	ora	file32Size+2
	ora	file32Size+3
	beq	80$
 10$
	rep	%00010000
	ldx	nxtXBufByte
	lda	xModBuffer,x
	inx
	stx	nxtXBufByte
	cpx	pktSize
	sep	%00010000
	bcs	50$
	jsr	WriteXByte
	bne	90$
	jsr	DecF32Size
	bne	10$
	sec
	rts
 50$
	jsr	WriteXByte
	bne	90$
	jsr	DecF32Size
 80$
	sec
	rts
 90$
	clc
	rts

DecF32Size:
	lda	file32Size+0
	bne	65$
	lda	file32Size+1
	bne	60$
	lda	file32Size+2
	bne	55$
	dec	file32Size+3
 55$
	dec	file32Size+2
 60$
	dec	file32Size+1
 65$
	dec	file32Size+0
	bne	70$
	lda	file32Size+1
	ora	file32Size+2
	ora	file32Size+3
 70$
	rts

WriteXByte:
	ldx	nxtXByte
	beq	20$
;	sta	diskBlkBuf,x
	.byte	$9f,[diskBlkBuf,]diskBlkBuf,0
	inc	nxtXByte
	ldx	#0
	rts
 20$
	pha
;	lda	diskBlkBuf+0
	.byte	$af,[(diskBlkBuf+0),](diskBlkBuf+0),0
	sta	r3L
	sta	r1L
;	lda	diskBlkBuf+1
	.byte	$af,[(diskBlkBuf+1),](diskBlkBuf+1),0
	sta	r3H
	sta	r1H
	jsl	SSetNextFree,0
	bne	90$
	lda	r3L
;	sta	diskBlkBuf+0
	.byte	$8f,[(diskBlkBuf+0),](diskBlkBuf+0),0
	lda	r3H
;	sta	diskBlkBuf+1
	.byte	$8f,[(diskBlkBuf+1),](diskBlkBuf+1),0
	jsl	SWrBlkDskBuf,0
	bne	90$
	inc	xEntBuf+28	;increment the block count.
	bne	40$
	inc	xEntBuf+29
 40$
	pla
;	sta	diskBlkBuf+2
	.byte	$8f,[(diskBlkBuf+2),](diskBlkBuf+2),0
	ldy	#3
	sty	nxtXByte
	ldx	#0
	rts
 90$
	pla
	txa
	rts


nxtXByte:
	.block	1
nxtXBufByte:
	.block	2
pktSize:
	.block	2
r5XSave:
	.block	2
;number of bytes in the final 128 byte packet.
numInLast:
	.block	1
;the number of 128 byte packets left to send.
shortPkts:
	.block	1
finalPacket:
	.block	1


LdXModBuf:
	bit	finalPacket
	bpl	5$
	jmp	NxtLastPacket
 5$
	LoadB	nxtXBufByte+0,#0
	sta	nxtXBufByte+1
	MoveW	r5XSave,r5
 10$
	jsr	ReadXByte
	bne	20$
	rep	%00010000
	ldx	nxtXBufByte
	sta	xModBuffer,x
	inx
	stx	nxtXBufByte
	cpx	pktSize
	sep	%00010000
	bcc	10$
	MoveW	r5,r5XSave
	sec
	rts
 20$
	cpx	#BUFFER_OVERFLOW
	bne	45$
	lda	nxtXBufByte+0
	ora	nxtXBufByte+1
	bne	50$
	ldx	#0
 45$
	clc
	rts
 50$
	LoadB	finalPacket,#%10000000
	rep	%00100000
	lda	nxtXBufByte
	asl	a
	sta	numInLast	;put high byte in shortPkts.
	sep	%00100000
	lsr	a
	sta	numInLast	;number of bytes in final packet.
	jmp	LastPackets


;this shifts 896 bytes down in xModBuffer.
NxtLastPacket:
;	phk
	.byte	$4b
	pla
	sta	smXBanks+1
	sta	smXBanks+2
	rep	%00110000	;16 bit a,x,y.
	ldx	#[(xModBuffer+128)
	.byte	](xModBuffer+128)
	ldy	#[xModBuffer
	.byte	]xModBuffer
	lda	#[(1024-128-1)
	.byte	](1024-128-1)
smXBanks:
	mvn	2,2	;this can change.
	sep	%00110000	;8 bit a,x,y.

;fall through...

LastPackets:
	lda	#SOH
	jsr	SetPktSize
	lda	shortPkts
	beq	10$
	dec	shortPkts
	ldx	#0
	sec
	rts
 10$
	ldx	numInLast
	beq	90$
	lda	#SUB
 60$
	sta	xModBuffer,x
	inx
	cpx	#128
	bcc	60$
	LoadB	numInLast,#0
	ldx	#0
	sec
	rts
 90$
	ldx	#0
	clc
	rts


;carry indicates a disk error and x will hold the error. If carry is set, yet
;x is non-zero (equals flag cleared), then end of file was reached.
;r1 and r5 must be preserved between calls.
ReadXByte:
 5$
	ldx	r5H
	cpx	r5L
	beq	20$
;	lda	diskBlkBuf,x
	.byte	$bf,[diskBlkBuf,]diskBlkBuf,0
	inc	r5H
	ldx	#0
	sec
	rts
 20$
;	lda	diskBlkBuf+0
	.byte	$af,[(diskBlkBuf+0),](diskBlkBuf+0),0
	beq	80$
	sta	r1L
;	lda	diskBlkBuf+1
	.byte	$af,[(diskBlkBuf+1),](diskBlkBuf+1),0
	sta	r1H
	jsl	SRdBlkDskBuf,0
	php
	jsr	RelSLNMI
	plp
	bne	90$
	LoadB	r5H,#2
;	lda	diskBlkBuf+1
	.byte	$af,[(diskBlkBuf+1),](diskBlkBuf+1),0
	tay
;	lda	diskBlkBuf+0
	.byte	$af,[(diskBlkBuf+0),](diskBlkBuf+0),0
	beq	70$
	ldy	#$ff
 70$
	iny
	sty	r5L
	beq	5$
	cpy	#3
	bcs	5$
 80$
	ldx	#BUFFER_OVERFLOW
	sec
	rts
 90$
	clc
	rts


StrtTrMsg:
	PushW	r0
	PushB	r1L
	jsr	TransMsg
	PopB	r1L
	PopW	r0
	rts

SendgMsg:
	ldx	#0
 10$
;	lda	dirEntryBuf+3,x
	.byte	$bf,[(dirEntryBuf+3),](dirEntryBuf+3),0
	beq	20$
	cmp	#$a0
	beq	20$
	and	#%01111111
	cmp	#127
	beq	15$
	cmp	#32
	bcc	15$
	sta	xfileNBuf,x
 15$
	inx
	cpx	#16
	bcc	10$
 20$
	lda	#0
	sta	xfileNBuf,x
	LoadW	r0,#xfileNBuf
;	phk
	.byte	$4b
	PopB	r1L
;fall through...
TransMsg:
	ldx	#5
	ldy	#0
	jmp	URLBarMsg

xfileNBuf:
	.block	17

endXYModem:

