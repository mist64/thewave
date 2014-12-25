;*************************************
;
;	TCPCode
;
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


;20 byte header for ip.
ipHeader:
;version|header length (+0)
	.byte 4<<4|5
;type of service (+1)
	.byte	%00000000
;total length (+2)
	.byte	$00,$00
;identification (+4)
ipIdent:
	.byte $00,$00
;flags|fragment offset (+6)
	.byte	%010<<5|$00,$00
;time to live (+8)
	.byte 64
;protocol (+9)
	.byte	PR_TCP
;header checksum (+10)
	.byte	$00,$00
;source address (+12)
myIP:
	.byte	0,0,0,0
;destination address (+16)
destIP:
	.byte	0,0,0,0

;24 byte header for tcp.
tcpHeader:
;source port (+0)
	.byte	1	;1 for telnet,2 for http (local values)
			;3 for dns lookup.
	.byte	0
;dest port (+2)
	.byte	0
	.byte	23	;this changes.
;sequence number (+4)
	.block	4
;acknowledgment number (+8)
	.block	4
;data offset (+12)
	.byte	6<<4|0
;urg,ack,psh,rst,syn,fin bits (+13)
	.block	1
;window (+14)
	.byte	](1460*6),[(1460*6)
;checksum (+16)
	.block	2
;urgent pointer (+18)
	.block	2
;options (+20)
	.byte	2,4,]1460,[1460

segLength:
	.block	2
remoteWindow:
	.block	2

JOpnTCPConnection:
	LoadB	rcvWndwFlag,#%00000000
	sta	inPktAcked
	LoadB	tcpHeader+14,#](1460*6)
	LoadB	tcpHeader+15,#[(1460*6)
	LoadB	tcpOpnAttempts,#6
	lda	#%01000000
;	sta	tcpOpen
	.byte	$8f,[tcpOpen,]tcpOpen,0
	ldy	#3
 10$
;	lda	[r0],y
	.byte	$b7,r0
	sta	destIP,y
	dey
	bpl	10$
	MoveB	r2L,tcpHeader+1
	MoveB	r2H,tcpHeader+0
	MoveB	r3L,tcpHeader+3
	MoveB	r3H,tcpHeader+2
	lda	stTCPSpot+2
	bne	OTCP2
	jsl	SGetNewBank,0
	stx	stTCPSpot+2
	stx	endTCPSpot+2

;label added for the assembler.
OTCP2:
	LoadB	ackReceived,#%10000000
	LoadB	tcpHeader+12,#(6<<4|0)
	jsr	SetISN
	lda	#%00010100	;psh,syn bits set.
	sta	tcpHeader+13
	LoadB	ipHeader+2,#]40
	LoadB	ipHeader+3,#[40
	jsr	PutSeqNum
	jsr	OTB2	;send just tcp header.(no data)
	lda	#%00001010	;psh,syn bits set.
	sta	tcpHeader+13
	LoadB	ipHeader+2,#]44
	LoadB	ipHeader+3,#[44
 10$
	jsr	PutSeqNum
	jsr	OTB2	;send just tcp header.(no data)
	LoadW	r0,#4	;set for 4 seconds.
	jsr	JSLOnTimer
 15$
	jsr	JSLCkTimer
	bcc	20$
 16$
	dec	tcpOpnAttempts
	bne	10$
	jmp	TCPOpenStoppped
 20$
	jsr	GetTCPPacket
	bcs	35$
	jsr	JSLCkAbortKey
	bcs	15$
 30$
	jmp	TCPOpenStoppped
 35$
	ldy	inBegin
	lda	pppInBuffer+13,y
	and	#%00000100	;rst bit set?
	bne	16$	;branch if so.
	lda	pppInBuffer+13,y
	and	#%00010000	;ack bit set?
	beq	10$	;branch if not.
	LoadB	segLength+0,#0
	sta	segLength+1
	jsr	MvInSegLength
 40$
	ldy	inBegin
	lda	pppInBuffer+13,y
	and	#%00000010	;syn bit set?
	bne	60$	;branch if so.
	LoadW	r0,#4	;set for 4 seconds.
	jsr	JSLOnTimer
 50$
	jsr	JSLCkTimer
	bcs	10$
	jsr	GetTCPPacket
	bcs	40$
	jsr	JSLCkAbortKey
	bcs	50$
	jmp	TCPOpenStoppped
 60$

;label added for the assembler.
OTCP3:
	ldy	inBegin
	lda	pppInBuffer+22,y
	sta	remoteWindow+1
	lda	pppInBuffer+23,y
	sta	remoteWindow+0
	lda	#%00010000	;ack bit set.
	sta	tcpHeader+13
	LoadB	tcpHeader+12,#(5<<4|0)
	LoadB	ipHeader+2,#]40
	LoadB	ipHeader+3,#[40
	LoadW	segLength,#1
	jsr	MvInSegLength
	MoveB	stTCPSpot+0,endTCPSpot+0
	MoveB	stTCPSpot+1,endTCPSpot+1
	MoveB	st32TCP+0,end32TCP+0
	MoveB	st32TCP+1,end32TCP+1
	jsr	PutSeqNum
	jsr	OTB2	;send just tcp header.(no data)
	lda	#%10000000
;	sta	tcpOpen
	.byte	$8f,[tcpOpen,]tcpOpen,0
	sec
	rts

TCPOpenStoppped:
	jsr	JClsTCPConnection
	clc
	rts

tcpOpnAttempts:
	.block	1

SetISN:
;	lda	minutes
	.byte	$af,[minutes,]minutes,0
	sta	st32TCP+1
	sta	end32TCP+1
	sta	lastAckedNum+0
;	lda	seconds
	.byte	$af,[seconds,]seconds,0
	sta	st32TCP+0
	sta	end32TCP+0
	sta	lastAckedNum+1
	lda	#0
	sta	stTCPSpot+1
	sta	stTCPSpot+0
	sta	endTCPSpot+1
	sta	endTCPSpot+0
	sta	lastAckedNum+2
	sta	lastAckedNum+3
	sta	expPacket+0
	sta	expPacket+1
	sta	expPacket+2
	sta	expPacket+3
	rts


CalcInBegin:
	lda	pppInBuffer+0
	and	#%00001111
	asl	a
	asl	a
	sta	inBegin
	tay
	lda	pppInBuffer+12,y
	and	#%11110000
	lsr	a
	lsr	a
	clc
	adc	inBegin
	sta	inDataBegin
	clc
	adc	#[pppInBuffer
	sta	ipTCPInPtr+0
	lda	#]pppInBuffer
	adc	#0
	sta	ipTCPInPtr+1
	MoveW	inPPPf,endTCPInPtr
	rts

inBegin:
	.block	1
inDataBegin:
	.block	1

MvInSegLength:
	ldy	inBegin
	lda	pppInBuffer+7,y
	clc
	adc	segLength+0
	sta	expPacket+3
	lda	pppInBuffer+6,y
	adc	segLength+1
	sta	expPacket+2
	lda	pppInBuffer+5,y
	adc	#0
	sta	expPacket+1
	lda	pppInBuffer+4,y
	adc	#0
	sta	expPacket+0
	rts

expPacket:
	.block	4

PutSeqNum:
	MoveB	stTCPSpot+0,tcpHeader+7
	sta	rptPktNum+3
	MoveB	stTCPSpot+1,tcpHeader+6
	sta	rptPktNum+2
	MoveB	st32TCP+0,tcpHeader+5
	sta	rptPktNum+1
	MoveB	st32TCP+1,tcpHeader+4
	sta	rptPktNum+0
	MoveB	expPacket+0,tcpHeader+8
	MoveB	expPacket+1,tcpHeader+9
	MoveB	expPacket+2,tcpHeader+10
	MoveB	expPacket+3,tcpHeader+11
	rts

FlshOutBuf:
	MoveB	stTCPSpot+0,endTCPSpot+0
	MoveB	stTCPSpot+1,endTCPSpot+1
	MoveB	st32TCP+0,end32TCP+0
	MoveB	st32TCP+1,end32TCP+1
	rts

RstSeqNum:
	MoveB	lastAckedNum+3,stTCPSpot+0
	MoveB	lastAckedNum+2,stTCPSpot+1
	MoveB	lastAckedNum+1,st32TCP+0
	MoveB	lastAckedNum+0,st32TCP+1
	rts

PutRptNum:
	MoveB	rptPktNum+3,stTCPSpot+0
	MoveB	rptPktNum+2,stTCPSpot+1
	MoveB	rptPktNum+1,st32TCP+0
	MoveB	rptPktNum+0,st32TCP+1
	rts

rptPktNum:
	.block	4

;this checks to make sure the incoming packet is the one expected.
;The check will fail if it's not the expected packet.
CkExpPacket:
	ldy	inBegin
	lda	pppInBuffer+4,y
	cmp	expPacket+0
	bne	90$
	lda	pppInBuffer+5,y
	cmp	expPacket+1
	bne	90$
	lda	pppInBuffer+6,y
	cmp	expPacket+2
	bne	90$
	lda	pppInBuffer+7,y
	cmp	expPacket+3
	bne	90$
	sec
	rts
 90$
	clc
	rts

MvInAckSeq:
	ldy	inBegin
	lda	pppInBuffer+11,y
	sta	lastAckedNum+3
	sta	stTCPSpot+0
	lda	pppInBuffer+10,y
	sta	lastAckedNum+2
	sta	stTCPSpot+1
	lda	pppInBuffer+9,y
	sta	lastAckedNum+1
	sta	st32TCP+0
	lda	pppInBuffer+8,y
	sta	lastAckedNum+0
	sta	st32TCP+1
	rts

lastAckedNum:
	.block	4

JClsTCPConnection:
	LoadB	ipHeader+2,#]40
	LoadB	ipHeader+3,#[40
	lda	#%00010001	;fin.
	sta	tcpHeader+13
;	lda	tcpOpen
	.byte	$af,[tcpOpen,]tcpOpen,0
	bne	10$
	ldx	stTCPSpot+2
	beq	5$
	jsl	SFreeBank,0
	lda	#%00000000
	sta	stTCPSpot+2
 5$
	sec
	rts
 10$
	and	#%00000101
	beq	15$
	jmp	CloseStarted
 15$
;	lda	tcpOpen
	.byte	$af,[tcpOpen,]tcpOpen,0
	cmp	#%01000000	;tcp unsuccessfully opened?
	beq	90$	;branch if so.
	LoadW	r0,#5	;set for 5 seconds.
	jsr	JSLOnTimer
 20$
	jsr	PutSeqNum
	jsr	OTB2	;send just tcp header.(no data)
 22$
	jsr	JSLCkTimer
	bcs	90$
	jsr	GetTCPPacket
	bcs	25$
	jsr	JSLCkAbortKey
	bcs	22$
	bcc	90$
 25$
	ldy	inBegin
	lda	pppInBuffer+13,y
	lsr	a
	bcc	22$
	LoadW	segLength,#1
	jsr	MvInSegLength
	lda	#%00010000
	sta	tcpHeader+13
	inc	stTCPSpot+0
	bne	85$
	inc	stTCPSpot+1
	bne	85$
	inc	st32TCP+0
	bne	85$
	inc	st32TCP+1
 85$
	jsr	FlshOutBuf
	jsr	PutSeqNum
	jsr	OTB2	;send just tcp header.(no data)
 90$
	ldx	stTCPSpot+2
	beq	95$
	jsl	SFreeBank,0
 95$
	lda	#%00000000
;	sta	tcpOpen
	.byte	$8f,[tcpOpen,]tcpOpen,0
	sta	stTCPSpot+2
	sec
	rts

CloseStarted:
	lsr	a
	php
	jsr	PutSeqNum
	jsr	OTB2	;send just tcp header.(no data)
	plp
	bcc	90$
	LoadW	r0,#5	;set for 5 seconds.
	jsr	JSLOnTimer
 20$
	jsr	JSLCkTimer
	bcs	90$
	jsr	GetTCPPacket
	bcs	25$
	jsr	JSLCkAbortKey
	bcs	20$
	bcc	90$
 25$
	ldy	inBegin
	lda	pppInBuffer+13,y
	and	#%00010000
	beq	20$
 90$
	ldx	stTCPSpot+2
	jsl	SFreeBank,0
	lda	#%00000000
;	sta	tcpOpen
	.byte	$8f,[tcpOpen,]tcpOpen,0
	sta	stTCPSpot+2
	sec
	rts

CkForTCPPacket:
;	lda	tcpOpen
	.byte	$af,[tcpOpen,]tcpOpen,0
	bpl	15$
	jsr	GetTCPPacket
	bcc	15$
	lda	pppInBuffer+3	;carry already set.
	sbc	inDataBegin
	sta	segLength+0
	lda	pppInBuffer+2
	sbc	#0
	sta	segLength+1
	ora	segLength+0
	beq	85$	;branch if no data.
	ldy	inBegin
	lda	pppInBuffer+13,y
	and	#%00000101
	beq	10$
	lsr	a
	bcc	6$
	inc	segLength+0
	bne	5$
	inc	segLength+1
 5$
	lda	#%00000001
	.byte	44
 6$
	lda	#%00000100
;	sta	tcpOpen
	.byte	$8f,[tcpOpen,]tcpOpen,0
 10$
	jsr	CkExpPacket
	bcs	20$
	jsr	AckThisPacket
 15$
	clc
	rts
 20$
	jsr	MvInSegLength
	jsr	SaveTCPData
	jsr	RstSeqNum
	LoadB	inPktAcked,#%10000000
	sec
	rts
 85$
;continue on next page...

;previous page continues here.
CFTP2:
	ldy	inBegin
	lda	pppInBuffer+13,y
	and	#%00000101
	beq	90$
	lsr	a
	bcc	88$
	LoadW	segLength,#1
	jsr	MvInSegLength
	lda	#%00000001
	.byte	44
 88$
	lda	#%00000100
;	sta	tcpOpen
	.byte	$8f,[tcpOpen,]tcpOpen,0
 90$
	clc
	rts

FixRstPacket:
	PushW	segLength
	LoadB	segLength+0,#0
	sta	segLength+1
	jsr	MvInSegLength
	PopW	segLength
	rts

AckThisPacket:
	lda	#%00010000	;ack,psh bits set.
	sta	tcpHeader+13
	LoadB	ipHeader+2,#]40
	LoadB	ipHeader+3,#[40
	jsr	PutSeqNum
	jmp	OTB2

GetTCPPacket:
	jsr	RecvIPPacket
	bcc	90$
	jsr	TestTCPValid
	bcc	90$
	ldy	inBegin
	lda	pppInBuffer+14,y
	sta	remoteWindow+1
	lda	pppInBuffer+15,y
	sta	remoteWindow+0
	lda	pppInBuffer+13,y
	and	#%00010000
	beq	80$
	jsr	MvInAckSeq
	LoadB	ackReceived,#%10000000
 80$
	sec
	rts
 90$
	clc
	rts


TestTCPValid:
	jsr	CalcInBegin
	ldy	inBegin
	rep	%00100000
	lda	pppInBuffer+0,y
	cmp	tcpHeader+2
	bne	90$
	lda	pppInBuffer+2,y
	cmp	tcpHeader+0
	bne	90$
	lda	pppInBuffer+12
	cmp	ipHeader+16
	bne	90$
	lda	pppInBuffer+14
	cmp	ipHeader+18
	bne	90$
	sep	%00100000
	sec
	rts
 90$
	sep	%00100000
	clc
	rts


stray=0
.if	stray
;+++routine not finished.
ClsStrayConnection:
	ldy	#0
 10$
	lda	ipHeader+16,y
	pha
	lda	pppInBuffer+12,y
	sta	ipHeader+16,y
	lda	tcpHeader+0,y
	pha
	iny
	cpy	#4
	bcc	10$
	ldy	inBegin
	ldx	#0
 20$
	lda	pppInBuffer+0,y
	sta	tcpHeader+2,x
	lda	pppInBuffer+2,y
	sta	tcpHeader+0,x
	iny
	inx
	cpx	#2
	bcc	20$
	ldy	inBegin
	lda	pppInBuffer
+++

	lda	#%00010001
	sta	tcpHeader+13
	LoadB	ipHeader+2,#]40
	LoadB	ipHeader+3,#[40
	jsr	PutSeqNum
	jmp	OTB2

	ldy	#3
 80$
	pla
	sta	tcpHeader+0,y
	pla
	sta	ipHeader+16,y
	dey
	bpl	80$
	rts

.endif

;this will retrieve up to 255 bytes from the IP buffer
;and store them into the buffer at tcpInBuf.
JLdTCPBlock:
	lda	#0
;	sta	tcpInStart	;reset the pointer.
	.byte	$8f,[tcpInStart,]tcpInStart,0
;	sta	tcpInEnd	;reset the pointer.
	.byte	$8f,[tcpInEnd,]tcpInEnd,0
	lda	endTCPInPtr+0
	cmp	ipTCPInPtr+0
	bne	60$
	lda	endTCPInPtr+1
	cmp	ipTCPInPtr+1
	bne	60$
	lda	tcpHeader+14
	ora	tcpHeader+15
	beq	15$
	jsr	CkForTCPPacket
	bcs	30$
 15$
	jsr	IsTCPData
	bcs	20$
	bit	inPktAcked
	bpl	25$
	jsr	AckThisPacket
	bra	25$
 20$
	jsr	SendBufData
 25$
	jmp	RstTCPIn
 30$
	bit	rcvWndwFlag
	bpl	40$
	rep	%00100000
	sec
	lda	endTCPInPtr
	sbc	ipTCPInPtr
	sta	r13
	sec
	lda	tcpHeader+14
;	xba
	.byte	$eb
	sbc	r13
	bcs	35$
	lda	#[0
	.byte	]0
 35$
;	xba
	.byte	$eb
	sta	tcpHeader+14
	sep	%00100000
 40$
	jsr	IsTCPData
	bcc	45$
	jsr	SendBufData
;	bra	50$
 45$
;	jsr	AckThisPacket
; 50$
	lda	endTCPInPtr+0
	cmp	ipTCPInPtr+0
	bne	60$
	lda	endTCPInPtr+1
	cmp	ipTCPInPtr+1
	beq	RstTCPIn	;branch if empty packet.
 60$
;fall through...

LTB2:
	MoveW	ipTCPInPtr,r13
	ldx	#0
 50$
;	lda	(r13)
	.byte	$b2,r13
	sta	tcpInBuf,x
	inc	r13L
	bne	60$
	inc	r13H
 60$
	inx
	lda	endTCPInPtr+0
	cmp	r13L
	bne	70$
	lda	endTCPInPtr+1
	cmp	r13H
	beq	80$
 70$
	cpx	#255
	bcc	50$
 80$
	MoveW	r13,ipTCPInPtr
	txa
;	sta	tcpInEnd
	.byte	$8f,[tcpInEnd,]tcpInEnd,0
	sec
	rts
 90$
RstTCPIn:
	LoadB	ipTCPInPtr+0,#[(pppInBuffer+40)
	sta	endTCPInPtr+0
	LoadB	ipTCPInPtr+1,#](pppInBuffer+40)
	sta	endTCPInPtr+1
	clc
	rts


ipTCPInPtr:
	.block	2
endTCPInPtr:
	.block	2


SaveTCPData:
;	lda	tcpOutEnd
	.byte	$af,[tcpOutEnd,]tcpOutEnd,0
	bne	10$
	clc
	rts
 10$
	sta	STD6+1
	ldy	#0
STD2:
	lda	tcpOutBuf,y
	jsr	StorTCPSpot
	iny
STD6:
	cpy	#0	;this changes.
	bcc	STD2
	lda	#0
;	sta	tcpOutEnd
	.byte	$8f,[tcpOutEnd,]tcpOutEnd,0
	sec
	rts

StorTCPSpot:
;	sta	$030000	;this changes.
	.byte	$8f
endTCPSpot:
	.block	3
	inc	endTCPSpot+0
	bne	10$
	inc	endTCPSpot+1
	bne	10$
	inc	end32TCP+0
	bne	10$
	inc	end32TCP+1
 10$
	rts

st32TCP:
	.block	2
end32TCP:
	.block	2


MoveTCPData:
	jsr	CalcTCPSize
	rep	%00110000
	ldx	#[0
	.byte	]0
MTD2:
;	lda	$030000,x	;this changes.
	.byte	$bf
stTCPSpot:
	.block	3
	sta	pppOutBuffer+40,x
	inx
	inx
	cpx	tcpDataSize
	bcc	MTD2
	clc
	lda	stTCPSpot
	adc	tcpDataSize
	sta	stTCPSpot
	sep	%00110000
	rts

CalcTCPSize:
	rep	%00110000
	sec
	lda	endTCPSpot
	sbc	stTCPSpot
	sta	tcpDataSize
	lda	remoteWindow
	cmp	tcpDataSize
	bcs	20$
	sta	tcpDataSize
 20$
	lda	tcpDataSize
	cmp	#[1461
	.byte	]1461
	bcc	60$
	lda	#[1460
	.byte	]1460
	sta	tcpDataSize
 60$
	sep	%00110000
	rts

tcpDataSize:
	.block	2

;this checks to see if there is any data to send.
IsTCPData:
	lda	endTCPSpot+0
	cmp	stTCPSpot+0
	bne	80$
	lda	endTCPSpot+1
	cmp	stTCPSpot+1
	bne	80$
	clc
	rts
 80$
	sec
	rts



;this will push any data accumulated thus far
;on to the IP routines for sending out to
;the network.
JOutTCPBuffer:
	jsr	SaveTCPData
	bcs	50$
	bit	ackReceived
	bpl	55$
	jsr	IsTCPData	;is there any data to send?
	bcs	55$	;branch if so.
	sec
	rts
 50$
	bit	ackReceived
	bpl	60$
 55$
	lda	remoteWindow+0
	ora	remoteWindow+1
	beq	60$
	jsr	SendBufData
 60$
	clc
	rts

SendBufData:
	jsr	PutSeqNum
	jsr	MoveTCPData
	clc
	lda	tcpDataSize+0
	adc	#40
	sta	ipHeader+3
	lda	tcpDataSize+1
	adc	#0
	sta	ipHeader+2
	lda	#%00011000
	sta	tcpHeader+13
	LoadB	ackReceived,#0
	ldy	#19
 70$
	lda	tcpHeader,y
	sta	pppOutBuffer+20,y
	dey
	bpl	70$
	jsr	DoTCPChksum
	jsr	SendIPPacket
	sec
	rts

ackReceived:
	.block	1
inPktAcked:
	.block	1

OTB2:
	lda	tcpHeader+12
	and	#%11110000
	lsr	a
	lsr	a
	tay
	dey
 50$
	lda	tcpHeader,y
	sta	pppOutBuffer+20,y
	dey
	bpl	50$
	jsr	DoTCPChksum
;fall through to SendIPPacket...

SendIPPacket:
;	lda	tcpOpen
	.byte	$af,[tcpOpen,]tcpOpen,0
	bne	10$
	clc
	rts
 10$
	inc	ipIdent+1
	bne	20$
	inc	ipIdent+0
 20$
	jsr	DoIPChksum
	ldy	#0
 30$
	lda	ipHeader,y
	sta	pppOutBuffer,y
	iny
	cpy	#20
	bcc	30$
RepeatPacket:
	LoadB	outPPPPR+0,#]IP_PROTOCOL
	LoadB	outPPPPR+1,#[IP_PROTOCOL
	MoveB	ipHeader+3,r2L
	MoveB	ipHeader+2,r2H
	ldy	#13
	lda	pppOutBuffer+20,y
	and	#%00010000
	beq	80$
	LoadB	inPktAcked,#%00000000
 80$
	jmp	OutPPPFrame


RecvIPPacket:
	jsr	RecvPPPFrame
	lda	rPPPFlag
	cmp	#%11111111	;PPP packet received yet?
	beq	50$
	clc
	rts
 50$
	LoadB	rPPPFlag,#%10000000
.if	debug
	jsr	StashIncoming
.endif
	lda	inPPPPR+1
	cmp	#[IP_PROTOCOL	;+++watch for other protocols too.
	bne	90$
	lda	inPPPPR+0
	cmp	#]IP_PROTOCOL	;+++watch for other protocols too.
	bne	90$
	sec
	rts
 90$
	lda	inPPPPR+1
	cmp	#[LCP_PROTOCOL	;+++watch for other protocols too.
	bne	95$
	lda	inPPPPR+0
	cmp	#]LCP_PROTOCOL	;+++watch for other protocols too.
	bne	95$
	jsr	LCPHandler
 95$
	clc
	rts

DoIPSeed:
	rep	%00100000	;16 bit acc.
	clc
	lda	ipHeader+0
	adc	ipHeader+8
	adc	myIP+0
	adc	myIP+2
 45$
	adc	#0
	.byte	$00
	bcs	45$
	sta	ipSeed
	sep	%00100000	;8 bit acc.
	rts

ipSeed:
	.block	2

DoTCPSeed:
	rep	%00100000	;16 bit acc.
	clc
	lda	#0
	.byte	PR_TCP
	adc	myIP+0
	adc	myIP+2
 45$
	adc	#0
	.byte	$00
	bcs	45$
	sta	tcpSeed
	sep	%00100000	;8 bit acc.
	rts

tcpSeed:
	.block	2

DoIPChksum:
	rep	%00100000	;16 bit acc.
	clc
	lda	ipSeed
	adc	ipHeader+2
	adc	ipHeader+4
	adc	ipHeader+6
	adc	ipHeader+16
	adc	ipHeader+18
 45$
	adc	#0
	.byte	0
	bcs	45$
	eor	#$ff
	.byte	$ff
	sta	ipHeader+10	;store the checksum.
	sep	%00100000	;8 bit acc.
	rts


DoTCPChksum:
	rep	%00110000	;16 bit a,x,y
	lda	ipHeader+2
;	xba
	.byte	$eb
	sec
	sbc	#20
	.byte	$00
	sta	tcpLength
	lda	#[(pppOutBuffer+20)
	.byte	](pppOutBuffer+20)
	sta	r0
	lda	#0
	.byte	0
	sta	pppOutBuffer+20+16 ;zero out the checksum.
	lda	tcpLength
	lsr	a
	bcc	20$
	ldy	tcpLength
	lda	#0
	.byte	0
	sta	(r0),y	;zero out to 16 bits at the end.
 20$
	lda	tcpLength
;	xba
	.byte	$eb
	clc
	adc	tcpSeed
	adc	destIP+0
	adc	destIP+2
	php
 30$
	plp
;	adc	(r0)
	.byte	$72,r0
	php
	inc	r0
	inc	r0
	dec	tcpLength
	beq	40$
	dec	tcpLength
	bne	30$
 40$
	plp
 45$
	adc	#0
	.byte	0
	bcs	45$
	eor	#$ff
	.byte	$ff
	sta	pppOutBuffer+20+16 ;store the checksum.
	sep	%00110000	;8 bit acc.
	rts

tcpLength:
	.block	2

;this handles resolving the IP address into
;a 32 bit number. It will resolve either from its
;own "learned" cache or it will query a DNS server.
;+++caching isn't ready yet.
JReslvAddress:
	jsr	Test4Address	;see if a 4 digit address was entered.
	bcc	3$	;branch if not and access DNS server.
	rts
 3$
	lda	dnsPrimary
	bne	5$
	jsr	SwapDNSAddresses
	bcs	5$
	jmp	DoDNSError
 5$
	jsr	SetUpQuestion
	ldy	#3
	lda	#0
 10$
	sta	addrResolved,y
	dey
	bpl	10$
 15$
	jsr	QueryDNS
	bcc	30$
 20$
	rts
 30$
	jsr	JSLCkAbortKey
	bcc	90$
	jsr	SwapDNSAddresses
	bcc	90$
	jsr	QueryDNS
	bcs	20$
 90$
;+++indicate an error to the user here.
DoDNSError:
	clc
	rts


QueryDNS:
	LoadB	dnsAttempts,#5
	LoadW	r0,#dnsPrimary
;	phk
	.byte	$4b
	PopB	r1L
	LoadW	r2,#$0300
	LoadW	r3,#53
	inc	queryID+1
	bne	10$
	inc	queryID+0
 10$
	jsr	JOpnTCPConnection
	bcc	55$
	clc
	lda	queryMessage+1
	adc	#2
	sta	r2L
	ldy	#0
 20$
	lda	queryMessage,y
	sta	tcpOutBuf,y
	iny
	cpy	r2L
	bcc	20$
	tya
;	sta	tcpOutEnd
	.byte	$8f,[tcpOutEnd,]tcpOutEnd,0
 30$
	jsr	JOutTCPBuffer
 45$
	LoadW	r0,#4
	jsr	JSLOnTimer
 50$
	jsr	CkForTCPPacket
	bcs	60$
	jsr	JSLCkAbortKey
	bcc	55$
	jsr	JSLCkTimer
	bcc	50$
	LoadB	ackReceived,#%00000000
	jsr	PutRptNum
	dec	dnsAttempts
	bne	30$
 55$
	jsr	JClsTCPConnection
	clc
	rts
 60$
	jsr	AckThisPacket
	jsr	SetDNSPointers
	MoveB	ansPointers+0,r0L
	MoveB	ansPointers+1,r0H
	ora	r0L
	beq	55$
	jsr	GrabRRAddress
	jsr	JClsTCPConnection
	LoadW	r0,#addrResolved
;	phk
	.byte	$4b
	PopB	r1L
	sec
	rts

addrResolved:
	.block	4

dnsAttempts:
	.block	1

SwapDNSAddresses:
	lda	dnsSecondary+0
	bne	5$
	clc
	rts
 5$
	ldy	#0
 10$
	lda	dnsPrimary,y
	pha
	lda	dnsSecondary,y
	sta	dnsPrimary,y
	pla
	sta	dnsSecondary,y
	iny
	cpy	#4
	bcc	10$
	rts

queryMessage:
	.byte	0,28	;this changes.
queryID:
	.byte	$00,$01	;this can be any number since
			;we're doing one at a time.
	.byte	%00000001,%00000000
;qdcount
	.byte	$00,$01	;one question entry.
;ancount
	.byte	$00,$00	;only used in a response.
;nscount
	.byte	$00,$00	;only used in a response.
;arcount
	.byte	$00,$00	;only used in a response.

dnsQuestion:
	.block	64


Test4Address:
	PushW	r0
	PushB	r1L
	jsr	JAddrTo32Bits
	bcc	90$
	pla
	pla
	pla
	ldy	#3
 20$
;	lda	[r0],y
	.byte	$b7,r0
	sta	addrResolved,y
	dey
	bpl	20$
	LoadW	r0,#addrResolved
;	phk
	.byte	$4b
	PopB	r1L
	sec
	rts
 90$
	PopB	r1L
	PopW	r0
	rts


SetUpQuestion:
	ldx	#0
	ldy	#1
 5$
	lda	#0
	sta	dnsQuestion,x
 10$
;	lda	[r0]
	.byte	$a7,r0
	inc	r0L
	bne	15$
	inc	r0H
 15$
	cmp	#0
	beq	30$
	cmp	#'.'
	beq	20$
	sta	dnsQuestion,y
	inc	dnsQuestion,x
	iny
	cpy	#64
	bcc	10$
	clc
	rts
 20$
	tyx
	iny
	cpy	#64
	bcc	5$
	clc
	rts
 30$
	sta	dnsQuestion,y
	iny
	lda	#0
	sta	dnsQuestion,y
	sta	dnsQuestion+2,y
	lda	#1
	sta	dnsQuestion+1,y
	sta	dnsQuestion+3,y
	tya
	clc
	adc	#4
	adc	#12
	sta	queryMessage+1
	rts

SetDNSPointers:
	ldy	#0
	tya
 10$
	sta	ansPointers,y
	iny
	cpy	#84
	bcc	10$
	clc
	lda	#[pppInBuffer
	adc	inDataBegin
	adc	#2
	sta	r0L
	sta	hdrPointer+0
	sta	r1L
	lda	#]pppInBuffer
	adc	#0
	sta	r0H
	sta	hdrPointer+1
	sta	r1H
	lda	#11
	jsr	AddR0Plus1
	jsr	PntPastName
	lda	#3
	jsr	AddR0Plus1
	jsr	PntAnswers
	jsr	PntNSRecords
	jmp	PntARRecords

numDNSAnswers:
	.block	1
hdrPointer:
	.block	2
ansPointers:
	.block	2
	.block	2
nsPointers:
	.block	40
arPointers:
	.block	40

PntPastName:
;	lda	(r0)
	.byte	$b2,r0
	bmi	80$
 20$
;	lda	(r0)
	.byte	$b2,r0
	beq	AddR0Plus1
	jsr	AddR0Plus1
	bra	20$
 80$
	lda	#1
;fall through...
AddR0Plus1:
	clc
	adc	#1
	adc	r0L
	sta	r0L
	bcc	10$
	inc	r0H
 10$
	rts

PntAnswers:
	ldy	#7
	lda	(r1),y
	sta	numDNSAnswers
	beq	90$
 10$
	MoveW	r0,r1
	jsr	PntPastName
	ldy	#1
	lda	(r0),y
	tay
	lda	#7
	jsr	AddR0Plus1
	cpy	#$01
	beq	60$
	ldy	#1
	lda	(r0),y
	ina
	jsr	AddR0Plus1
	dec	numDNSAnswers
	bne	10$
	rts
 60$
	MoveW	r1,ansPointers+0
 90$
	rts


PntNSRecords:
	rts

PntARRecords:
	rts


GrabRRAddress:
	jsr	PntPastName
	lda	#9
	jsr	AddR0Plus1
	ldy	#3
 10$
	lda	(r0),y
	sta	addrResolved,y
	dey
	bpl	10$
	rts


JSepHREFString:
	ldy	#0
	tya
 10$
	sta	prtclField,y
	iny
	bne	10$
	jsr	StPrtclField
	jsr	StDmnNmField
	jsr	StPathField
	cmp	#'#'
	beq	70$
	lda	pathField+0
	bne	60$
	lda	#'/'
	sta	pathField+0
 60$
	rts
 70$
	jsr	StAncNmField
	lda	pathField+0
	bne	80$
	lda	dmnNmField
	beq	80$
	lda	#'/'
	sta	pathField+0
 80$
	rts

StPrtclField:
	lda	#0
;	sta	prtclFound
	.byte	$8f,[prtclFound,]prtclFound,0
	tay
 10$
	lda	hrefString,y
	beq	20$
	cmp	#':'
	beq	30$
	cmp	#'#'
	beq	20$
	iny
	cpy	#13
	bcc	10$
 20$
	ldy	#0
	sty	prtclField+0
	rts
 30$
	phy
 40$
	lda	hrefString,y
	ora	#%00100000	;set to lowercase.
	sta	prtclField,y
	dey
	bpl	40$
	jsr	CkIfProtocol
	bcs	50$
	jsr	CkIfDrvProtocol
	bcs	85$
	pla
	bra	20$
 50$
	txa
;	sta	prtclFound
	.byte	$8f,[prtclFound,]prtclFound,0
 85$
	ply
	iny
	rts

CkIfProtocol:
	ldx	#0
 50$
	lda	prtclLTable,x
	sta	r0L
	lda	prtclHTable,x
	sta	r0H
	ldy	#0
 55$
	lda	(r0),y
	beq	60$
	cmp	prtclField,y
	bne	70$
	iny
	bne	55$
 60$
	cmp	prtclField,y
	beq	80$
 70$
	inx
	cpx	#[(prtclHTable-prtclLTable)
	bcc	50$
	clc
	rts
 80$
	inx
	sec
	rts

prtclLTable:
	.byte	[ptnetString,[phttpString
	.byte	[pfileString,[pdnsString
prtclHTable:
	.byte	]ptnetString,]phttpString
	.byte	]pfileString,]pdnsString

ptnetString:
	.byte	"telnet:",0
phttpString:
	.byte	"http:",0
pdnsString:
	.byte	"dns:",0
pfileString:
	.byte	"file:",0

CkIfDrvProtocol:
	lda	prtclField+0
	cmp	#'a'
	bcc	90$
	cmp	#'d'+1
	bcs	90$
	and	#%11011111
;	sta	prtclFound
	.byte	$8f,[prtclFound,]prtclFound,0
	lda	prtclField+1
	cmp	#':'
	beq	70$
	LoadW	r0,#prtclField+1
;	phk
	.byte	$4b
	PopB	r1L
	jsr	Asc2BinByte
	bcc	90$
	tax
	lda	prtclField+1,y
	cmp	#':'
	bne	90$
	txa
	.byte	44
 70$
	lda	#0
;	sta	partnFound
	.byte	$8f,[partnFound,]partnFound,0
	lda	prtclField+0
	and	#%11011111
	sta	prtclField+0
	sec
	rts
 90$
	clc
	rts


StDmnNmField:
	phy
;	lda	prtclFound
	.byte	$af,[prtclFound,]prtclFound,0
	beq	90$
	cmp	#4
	beq	90$
	cmp	#'A'
	bcs	90$
	cmp	#2
	bne	90$
	lda	hrefString,y
	cmp	#'/'
	bne	90$
	iny
	cmp	hrefString,y
	bne	90$
	iny
	ldx	#0
 20$
	lda	hrefString,y
	beq	25$
	cmp	#'/'
	beq	25$
	cmp	#'#'
	bne	30$
 25$
	pla
	rts
 30$
	sta	dmnNmField,x
	iny
	inx
	cpx	#47
	bcc	20$
 90$
	ply
	LoadB	dmnNmField,#0
	rts

StPathField:
	ldx	#0
 10$
	lda	hrefString,y
	beq	55$
	cmp	#'#'
	beq	50$
	sta	pathField,x
	iny
	beq	45$
	inx
	cpx	#159
	bcc	10$
 45$
	rts
 50$
	iny
 55$
	rts


StAncNmField:
	ldx	#0
 10$
	lda	hrefString,y
	beq	40$
	sta	anchNmField,x
	inx
	iny
	beq	30$
	cpx	#31
	bcc	10$
 30$
	ldx	#0
 40$
	lda	#0
	sta	anchNmField,x
	rts



;point r0-r1L to a string containing an ascii Internet
;address such as "10.0.0.4" and this will convert it
;to a 32 bit value. If the string was invalid such as
;any values higher than 255 or the wrong syntax, the
;carry will be cleared. Otherwise, if the carry is
;set upon exit, then r0-r1L will now be pointing at
;the 32 bit value.
JAddrTo32Bits:
	ldx	#0
 10$
	phx
	jsr	Asc2BinByte
	bcc	90$
	cpx	#0	;null terminator not allowed yet.
	beq	90$	;branch if null encountered.
	plx
	sta	bin32Value,x
	iny		;skip past the period.
	jsr	AddY2R0
	inx
	cpx	#3
	bcc	10$
	jsr	Asc2BinByte
	bcc	95$
	cpx	#0	;null terminator wanted now.
	bne	95$	;branch if not null.
	sta	bin32Value+3	;store the 4th byte.
	LoadW	r0,#bin32Value
;	phk
	.byte	$4b
	PopB	r1L
	sec
	rts
 90$
	pla
 95$
	clc
	rts

AddY2R0:
	tya
	clc
	adc	r0L
	sta	r0L
	bcc	10$
	inc	r0H
 10$
	rts

bin32Value:
	.block	4

;this will take the ascii decimal string pointed at by r0-r1L and
;convert it to an 8-bit binary number. If the string contains
;any invalid characters or exceeds 255, the carry will be clear
;to indicate an error. The result will be left in the accumulator.
;The string being converted must terminate with a null byte,
;a period, or a colon.
;.y will hold the number of characters in the string.
;.x will hold the terminator byte.
;destroys a,x,y,r5-r9
Asc2BinByte:
	ldy	#0
	sty	r7L
	sty	r7H
;	lda	[r0],y
	.byte	$b7,r0
	beq	90$	;branch if null string.
	cmp	#'.'
	beq	90$
	cmp	#':'
	beq	90$
 30$
;	lda	[r0],y
	.byte	$b7,r0
	beq	50$
	cmp	#'.'
	beq	50$
	cmp	#':'
	beq	50$
	jsr	DecToBin
	bcc	90$
	jsr	PutDecDigit
	iny
	cpy	#3
	bcc	30$
;	lda	[r0],y	;make sure next byte
	.byte	$b7,r0	;is a terminator.
	beq	50$	;null is allowed,
	cmp	#'.'	;as well as a period.
	bne	90$
 50$
	tax		;x holds the terminator byte.
	lda	r7H	;greater than 255?
	bne	90$	;branch if so.
	lda	r7L	;return with .a holding the value.
	sec
	rts
 90$
	clc
	rts


;this converts an ascii decimal digit to binary if
;the accumulator holds a valid character. Carry is
;set if successful.
DecToBin:
	cmp	#'9'+1
	bcs	90$
	sec
	sbc	#'0'
	rts
 90$
	clc
	rts

PutDecDigit:
	pha
	phy
	MoveW	r7,r5
	LoadB	r9L,#10
	ldx	#r5
	ldy	#r9L
	jsl	SBMult,0
	ply
	pla
	clc
	adc	r5L
	sta	r7L
	lda	r5H
	adc	#0
	sta	r7H
	rts

