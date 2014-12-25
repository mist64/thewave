;************************************************************

;	SLDriver

;	Routines for handling the SwiftLink.

;************************************************************

;a5 - this gets set with the base address of the SwiftLink, normally
;  it will contain $de00.
slBase=a5

XON =17
XOFF =19

	.psect


SLJumpTable:
;InitComm:
	jmp	JInitComm
;IsSLThere:
	jmp	JIsSLThere
;OnDTR:
	jmp	JOnDTR
;OnRTS:
	jmp	JOnRTS
;SetDataBits:
	jmp	JSetDataBits
;SetParity:
	jmp	JSetParity
;SetStopBits:
	jmp	JSetStopBits
;SetBPS:
	jmp	JSetBPS
;OffDTR:
	jmp	JOffDTR
;OffRTS:
	jmp	JOffRTS
;Send1Byte:
	jmp	JSend1Byte
;Recv1Byte:
	jmp	JRecv1Byte
;SendMulBytes:
	jmp	JSendMulBytes
;RecvMulBytes:
	jmp	JRecvMulBytes
;CkSend:
	jmp	JCkSend
;CkRecv:
	jmp	JCkRecv
;OnBreak:
	jmp	JOnBreak
;OffBreak:
	jmp	JOffBreak
;MoveNMICode:
.if	C64
	rts
	nop
	nop
.else
	jmp	JMoveNMICode
.endif
;SetNMIInterrupts:
	jmp	JSetNMIInterrupts
;RstrNMIInterrupts:
	jmp	JRstrNMIInterrupts
;OnNMIReceive:
	jmp	JOnNMIReceive
;OffNMIReceive:
	jmp	JOffNMIReceive
;CheckDCD:
	jmp	JCheckDCD
;SendPPPFrame
	jmp	JSendPPPFrame

JInitComm:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	jsr	FindSL
	bne	90$
	jsr	Init1SL
.if	C64
	PopB	CPU_DATA
.endif
	ldx	#0
	rts
 90$
.if	C64
	PopB	CPU_DATA
.endif
	ldx	#128
	rts


Init1SL:
	ldy	#1
	sta	(slBase),y	;reset the SwiftLink.
Init2SL:
	ldy	#2
	lda	#%00000010	;no parity, ints disabled.
	sta	(slBase),y
	iny
	lda	#%00011110
	sta	(slBase),y	;8 data bits, 1 stop bit, 19200
	ldy	#1
	lda	(slBase),y
	dey
	lda	(slBase),y
	rts

;this routine will search for the presence of a SwiftLink and if found,
;will set slBase to point at it's base address. If no SwiftLink is present,
;then slBase will point to a fake address so that subsequent modem routines
;will be able to function without crashing. They will find that a modem
;is not responding and exit reporting an error.

FindSL:
	php
	sei
	sta	openSuperCPU	;open the SuperCPU hardware.
	LoadB	$d280,#0
	LoadB	$d281,#%00000000
	LoadB	$d282,#%00001011
	LoadB	$d283,#%00011111
	sta	closeSuperCPU	;close the SuperCPU hardware.
	plp
	LoadW	slBase,#$de00	;test the most obvious location first.
	jsr	TestForSL	;is it at $de00?
	beq	50$	;branch if so.
	inc	slBase+1	;check at $df00.
	jsr	TestForSL
	beq	50$	;branch if found.
	LoadB	slBase+1,#$d7	;and check at $d700.
	jsr	TestForSL
	beq	50$	;branch if found.
	LoadW	slBase,#$dd40	;now check $dd40,$dd80, and $ddc0.
 30$
	jsr	TestForSL
	beq	50$	;branch if found.
	clc
	lda	slBase+0
	adc	#$40
	sta	slBase+0
	bcc	30$
	LoadW	slBase,#$de20	;test $de20.
	jsr	TestForSL
	beq	50$	;branch if found.
	LoadB	slBase+0,#[$d280 ;otherwise set a phony address
			;in a read-only location.
	sta	slAddress+0
	LoadB	slBase+1,#]$d280
	sta	slAddress+1
	txa
	rts
 50$
	MoveW	slBase,slAddress
	txa
	rts

testSLByte:
	.block	4

TestForSL:
	LoadB	slT232Flag,#0
	jsr	CkCIASID
	bne	5$
	jsr	ReadImages	;do it once in case the modem is sending data.
	jsr	ReadImages	;and this test should be valid.
	beq	10$
 5$
	rts
 10$
	ldy	#2
	lda	(slBase),y
	eor	#%11100000
	and	#%11100010
	ora	#%00001010	;first write a value to the
	sta	(slBase),y	;command register.
	cmp	(slBase),y	;did the value remain?
	bne	60$	;branch if not.
	dey
	lda	(slBase),y
	sta	(slBase),y
	iny
	lda	(slBase),y	;did the command register reset?
	and	#%00001111
	beq	70$	;branch if so.
	ldy	#1
	lda	testSLByte,y
	sta	(slBase),y
 60$
	ldx	#128
	.byte	44
 70$
	ldx	#0
	ldy	#2
	lda	testSLByte,y
	sta	(slBase),y
	txa
	bne	90$
	jsr	CkIfSL
	bne	80$
	lda	#%01000000
	.byte	44
 80$
	lda	#%10000000
	sta	slT232Flag
	ldx	#0
 90$
	rts


JIsSLThere:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	php
	sei
	sta	openSuperCPU	;open the SuperCPU hardware.
	LoadB	$d280,#0
	LoadB	$d281,#%00000000
	LoadB	$d282,#%00001011
	LoadB	$d283,#%00011111
	sta	closeSuperCPU	;close the SuperCPU hardware.
	plp
	LoadB	slT232Flag,#0
	jsr	CkCIASID
	bne	90$
	jsr	ReadImages	;do it once in case the modem is sending data.
	jsr	ReadImages	;and this test should be valid.
	bne	90$
	ldy	#2
	lda	(slBase),y
	eor	#%11100000
	and	#%11100010
	ora	#%00001010	;first write a value to the
	sta	(slBase),y	;command register.
	cmp	(slBase),y	;did the value remain?
	beq	70$	;branch if so.
	ldx	#128
	.byte	44
 70$
	ldx	#0
	ldy	#2
	lda	testSLByte,y
	sta	(slBase),y
	txa
	bne	90$
	jsr	CkIfSL
	bne	80$
	lda	#%01000000
	.byte	44
 80$
	lda	#%10000000
	sta	slT232Flag
	MoveW	slBase,slAddress
	jsr	Init2SL
.if	C64
	PopB	CPU_DATA
.endif
	ldx	#0
	rts
 90$
.if	C64
	PopB	CPU_DATA
.endif
	LoadB	slBase+0,#[$d280 ;otherwise set a phony address
			;in a read-only location.
	sta	slAddress+0
	LoadB	slBase+1,#]$d280
	sta	slAddress+1
	txa
	rts

CkCIASID:
	ldx	#128
	ldy	#0
 5$
	lda	(slBase),y
	cmp	$dd00,y
	bne	10$
	iny
	cpy	#4
	bcc	5$
	txa
	rts
 10$
	ldy	#0
 20$
	lda	(slBase),y
	cmp	$d400,y
	bne	30$
	iny
	cpy	#4
	bcc	20$
	txa
	rts
 30$
	ldx	#0
	rts


ReadImages:
	ldy	#0
 10$
	lda	(slBase),y
	sta	testSLByte,y
	iny
	cpy	#4
	bcc	10$
	ldy	#16
	.byte	44
CkIfSL:
	ldy	#4
	ldx	#0
 30$
	lda	(slBase),y
	cmp	testSLByte,x
	bne	90$
	iny
	inx
	cpx	#4
	bne	30$
	ldx	#0
	rts
 90$
	ldx	#128
	rts

JOnNMIReceive:
	jsr	JOnDTR
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2
	lda	(slBase),y
	and	#%11111101
	sta	(slBase),y
.if	C64
	PopB	CPU_DATA
.endif
	LoadB	intRecvStatus,#%10000000
	rts

JOffNMIReceive:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2
	lda	(slBase),y
	ora	#%00000010
	sta	(slBase),y
.if	C64
	PopB	CPU_DATA
.endif
	LoadB	intRecvStatus,#%00000000
	rts

intRecvStatus:
	.block	1


DoReceive:
	dey
	lda	(slBase),y
	ldy	recvVector+1
	beq	90$
	jmp	(recvVector)
 90$
	rts

.if	C128
JMoveNMICode:
	lda	#[Strt128NMI
	sta	r0L
	sta	r1L
	lda	#]Strt128NMI
	sta	r0H
	sta	r1H
	LoadW	r2,#(End128NMI-Strt128NMI)
	LoadB	r3L,#1
	LoadB	r3H,#0
	jmp	MoveBData


;the routines on this page are special in that copies of them get
;transferred to back ram on the 128, just in case an NMI occurs while the
;machine is running in back ram.

Strt128NMI:
IntNMIRoutine:
	sei
	rep	%00110000
	pha
	phx
	phy
	sep	%00110000
	phb
	lda	#0
	pha
	plb
	PushB	config
	LoadB	config,#$7e
	PushB	$d506
	and	#%11110000
	sta	$d506
	PushB	speedCheck
	sta	set20mhz
	ldy	#1
	lda	(slBase),y
	and	#%00001000	;was this a receive interrupt?
	beq	90$	;branch if not.
	jsr	DoReceive
 90$
	pla
	bpl	95$
	sta	set1mhz
 95$
	PopB	$d506
	PopB	config
	plb
	rep	%00110000
	ply
	plx
	pla
	rti

End128NMI:


JSetNMIInterrupts:
	bit	nmiSet	;are nmi's already set?
	bpl	10$	;branch if not.
	rts
 10$
	LoadB	nmiSet,#%10000000
	LoadW	$ffea,#IntNMIRoutine
	PushB	$d506
	ora	#%00001000
	sta	$d506
	LoadW	$ffea,#IntNMIRoutine
	PopB	$d506
	jmp	SetSNMI

JRstrNMIInterrupts:
	bit	nmiSet	;are nmi's set?
	bmi	10$	;branch if so.
	rts
 10$
	LoadW	$ffea,#$ff25
	PushB	$d506
	ora	#%00001000
	sta	$d506
	LoadW	$ffea,#$ff25
	PopB	$d506
	LoadB	nmiSet,#%00000000
	jmp	RstrSNMI

.endif

.if	C64

IntNMIRoutine:
	sei
	rep	%00110000
	pha
	phx
	phy
	sep	%00110000
	phb
	lda	#0
	pha
	plb
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
	PushB	speedCheck
	sta	set20mhz
	ldy	#1
	lda	(slBase),y
	and	#%00001000	;was this a receive interrupt?
	beq	90$	;branch if not.
	jsr	DoReceive
 90$
	pla
	bpl	95$
	sta	set1mhz
 95$
	PopB	CPU_DATA
	plb
	rep	%00110000
	ply
	plx
	pla
	rti


JSetNMIInterrupts:
	bit	nmiSet	;are nmi's already set?
	bpl	10$	;branch if not.
	rts
 10$
	LoadB	nmiSet,#%10000000
	LoadW	$ffea,#IntNMIRoutine
	jmp	SetSNMI

JRstrNMIInterrupts:
	bit	nmiSet	;are nmi's set?
	bmi	10$	;branch if so.
	rts
 10$
	LoadW	$ffea,#$9fff
	LoadB	nmiSet,#%00000000
	jmp	RstrSNMI


.endif

NNMI1==$fca5
NNMI2==$7ca5
NIRQ1==$fc8d
NIRQ2==$7c8d

SetSNMI:
	ldx	#2
 10$
;	lda	NNMI1,x
	.byte	$bf,[NNMI1,]NNMI1,1
	sta	svNNMI1,x
;	lda	NNMI2,x
	.byte	$bf,[NNMI2,]NNMI2,1
	sta	svNNMI2,x
;	lda	NIRQ1,x
	.byte	$bf,[NIRQ1,]NIRQ1,1
	sta	svNIRQ1,x
;	lda	NIRQ2,x
	.byte	$bf,[NIRQ2,]NIRQ2,1
	sta	svNIRQ2,x
	dex
	bpl	10$
	lda	#[IntNMIRoutine
;	sta	NNMI1+0
	.byte	$8f,[(NNMI1+0),](NNMI1+0),1
;	sta	NNMI2+0
	.byte	$8f,[(NNMI2+0),](NNMI2+0),1
;	sta	NIRQ1+0
	.byte	$8f,[(NIRQ1+0),](NIRQ1+0),1
;	sta	NIRQ2+0
	.byte	$8f,[(NIRQ2+0),](NIRQ2+0),1
	lda	#]IntNMIRoutine
;	sta	NNMI1+1
	.byte	$8f,[(NNMI1+1),](NNMI1+1),1
;	sta	NNMI2+1
	.byte	$8f,[(NNMI2+1),](NNMI2+1),1
;	sta	NIRQ1+1
	.byte	$8f,[(NIRQ1+1),](NIRQ1+1),1
;	sta	NIRQ2+1
	.byte	$8f,[(NIRQ2+1),](NIRQ2+1),1
	lda	#0
;	sta	NNMI1+2
	.byte	$8f,[(NNMI1+2),](NNMI1+2),1
;	sta	NNMI2+2
	.byte	$8f,[(NNMI2+2),](NNMI2+2),1
;	sta	NIRQ1+2
	.byte	$8f,[(NIRQ1+2),](NIRQ1+2),1
;	sta	NIRQ2+2
	.byte	$8f,[(NIRQ2+2),](NIRQ2+2),1
	rts


RstrSNMI:
	ldx	#2
 10$
	lda	svNNMI1,x
;	sta	NNMI1,x
	.byte	$9f,[NNMI1,]NNMI1,1
	lda	svNNMI2,x
;	sta	NNMI2,x
	.byte	$9f,[NNMI2,]NNMI2,1
	lda	svNIRQ1,x
;	sta	NIRQ1,x
	.byte	$9f,[NIRQ1,]NIRQ1,1
	lda	svNIRQ2,x
;	sta	NIRQ2,x
	.byte	$9f,[NIRQ2,]NIRQ2,1
	dex
	bpl	10$
	rts

svNNMI1:
	.block	3
svNNMI2:
	.block	3
svNIRQ1:
	.block	3
svNIRQ2:
	.block	3

;this will wait forever until a byte can be sent unless the
;user presses the STOP key.
;destroys y
;x indicates an error. (user hit STOP key)
JSend1Byte:
	jsr	JCkSend
	beq	80$
	lda	slT232Flag	;is the SL/T232 present?
	bne	10$	;branch if so.
	ldx	#128
	rts
 10$
	jsr	JCS1
	beq	80$
	jsr	CkAbortKey
	bcs	10$
	ldx	#CANCEL_ERR
 80$
	rts

;this will check if a byte can immediately be
;sent. If not, then it will exit with an error in x.
;destroys y
;x indicates not ready to send.

JCkSend:
	sta	JCS2+1
;this is called by JSend1Byte.
JCS1:
	bit	xOutMode	;ignoring XON,XOFF bytes?
	bvc	10$	;branch if so.
	bmi	JCS4	;branch if XOFF is in effect.
 10$
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#1
	lda	(slBase),y
	and	#%00010000
	beq	JCS3
	dey
JCS2:
	lda	#0	;this changes.
	sta	(slBase),y
.if	C64
	PopB	CPU_DATA
.endif
	ldx	#0
	rts
JCS3:
.if	C64
	PopB	CPU_DATA
.endif
JCS4:
	ldx	#128
	rts


.if	C64
JCheckDCD:
	phx
	ldx	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
	jsr	QkCkDCD
	stx	CPU_DATA
	plx
	rts
.else
JCheckDCD:
.endif

QkCkDCD:
	ldy	#1
	lda	(slBase),y
	pha
	and	#%01000000
	eor	#%01000000
	asl	a
	sta	dcdStatus
	pla
	rts


;point r0-r1L at a buffer containing the bytes to send and r2 with
;the number of bytes in the buffer. This routine will then send
;those bytes to the modem. If the equals flag is set,
;the transfer was successful. If not, then the
;user pressed the STOP key to cancel.

JSendMulBytes:
	lda	r2L
	ora	r2H
	beq	80$
 10$
;	lda	[r0]
	.byte	$a7,r0
	jsr	JSend1Byte
	bne	90$
	inc	r0L
	bne	20$
	inc	r0H
 20$
	ldx	#r2
	jsr	Ddec
	bne	10$
 80$
	ldx	#0
 90$
	rts


;this will wait forever until a byte comes in unless the
;user presses the STOP key.

JRecv1Byte:
	jsr	JCkRecv
	beq	80$
	lda	slT232Flag	;is the SL/T232 present?
	bne	10$	;branch if so.
	ldx	#128
	rts
 10$
	jsr	JCkRecv
	beq	80$
	jsr	CkAbortKey
	bcs	10$
	ldx	#CANCEL_ERR
 80$
	rts

;this will check if a byte is immediately ready to be
;received. If not, then it will exit with an error in x.
;If so, the byte will be returned in the accumulator
;and x=0.

JCkRecv:
.if	C64
	ldx	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#1
	lda	(slBase),y
	and	#%00001000
	beq	90$
	dey
	lda	(slBase),y
.if	C64
	stx	CPU_DATA
.endif
	bit	xOutMode	;ignoring XON,XOFF bytes?
	bvc	80$	;branch if so.
	cmp	#XON
	beq	50$
	cmp	#XOFF
	bne	80$
	lda	#%11000000
	.byte	44
 50$
	lda	#%01000000
	sta	xOutMode
	jmp	JCkRecv
 80$
	ldx	#0
	rts
 90$
.if	C64
	stx	CPU_DATA
.endif
 95$
	ldx	#128
	rts

;load r2 with number of bytes and point r0 to
;a buffer. This will fill the buffer with the
;number of bytes. If the equals flag is set,
;the transfer was successful. If not, then the
;user pressed the STOP key to cancel.
JRecvMulBytes:
	lda	r2L
	ora	r2H
	beq	80$
 10$
	jsr	JRecv1Byte
	bne	90$
	ldy	#0
	sta	(r0),y
	inc	r0L
	bne	30$
	inc	r0H
 30$
	lda	r2L
	bne	40$
	dec	r2H
 40$
	dec	r2L
	lda	r2L
	ora	r2H
	bne	10$
 80$
	ldx	#0
 90$
	rts

;this routine will pull the DTR line low.

JOnDTR:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2	;offset to command register.
	lda	(slBase),y	;get the current setting.
	ora	#%00000001	;set bit 0.
	sta	(slBase),y	;and store the new value.
	LoadB	dtrStatus,#%10000000
.if	C64
	PopB	CPU_DATA
.endif
	rts

;this routine will bring the DTR line high.

JOffDTR:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2	;offset to command register.
	lda	(slBase),y	;get the current setting.
	and	#%11111110	;make sure bit 0 is cleared.
	sta	(slBase),y	;and store the new value.
	LoadB	dtrStatus,#%00000000
.if	C64
	PopB	CPU_DATA
.endif
	rts


;this routine will pull the RTS line low.

JOnRTS:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2	;offset to command register.
	lda	(slBase),y	;get the current setting.
	and	#%11110011
;	bit	intSendStatus	;are transmit interrupts set?
;	bmi	10$	;branch if so.
	ora	#%00001000
;	.byte	44
; 10$
;	ora	#%00000100
	sta	(slBase),y	;and store the new value to bring RTS low.
	LoadB	rtsStatus,#%10000000
.if	C64
	PopB	CPU_DATA
.endif
	rts

;this routine will bring the RTS line high.

JOffRTS:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2	;offset to command register.
	lda	(slBase),y	;get the current setting.
	and	#%11110011	;make sure both bits 2 and 3 are cleared.
	sta	(slBase),y	;and store the new value.
	LoadB	rtsStatus,#%00000000
.if	C64
	PopB	CPU_DATA
.endif
	rts

rtsStatus:
	.block	1

JSetDataBits:
	lda	#%00110000
	cpx	#7
	beq	10$
	ldx	#8
	lda	#%00010000
 10$
	sta	SDB2+1
	stx	dataBits
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#3
	lda	(slBase),y
	and	#%10011111
SDB2:
	ora	#%00000000	;this changes.
	sta	(slBase),y
.if	C64
	PopB	CPU_DATA
.endif
	ldx	#0
	rts


;call this with the accumulator holding
;a 1 or 2 for the number of stop bits desired.
;No error is returned.
;destroys x,y.
JSetStopBits:
	ldx	#2
	cmp	#2
	php
	bcs	10$
	dex
 10$
	stx	stopBits
.if	C64
	ldx	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#3
	lda	(slBase),y
	asl	a
	plp
	ror	a
	ora	#%00010000
	sta	(slBase),y
.if	C64
	stx	CPU_DATA
.endif
	rts


;to set the parity, load the accumulator with either zero, an odd number,
;or an even number.
;This doesn't return any error.

JSetParity:
	sta	parityBit
	lsr	a
	bcs	20$	;branch if odd parity.
	beq	40$	;branch if no parity.
	lda	#%01100000	;set even parity.
	.byte	44
 20$
	lda	#%00100000	;set odd parity.
 40$
	sta	parityMask
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2
	lda	(slBase),y
	and	#%00001111
	ora	parityMask
	sta	(slBase),y
.if	C64
	PopB	CPU_DATA
.endif
	rts

parityMask:
	.byte	%00000000


;call this routine with .x holding a value from 1-12.
;Those values indicate the desired baud rate of 300,1200,2400,4800,
;7200,9600,14.4,19.2,38.4,57.6,115.2,or 230.4.
;10-12 is for the T232 only.
JSetBPS:
	txa
	beq	40$
	cpx	#10
	bcc	50$
	bit	slT232Flag
	bpl	45$
	cpx	#13
	bcs	45$
	stx	bpsRate
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#3	;point at control register.
	lda	(slBase),y
	and	#%11110000	;set the high speed mode.
	ora	#%00010000
	sta	(slBase),y
	ldy	#7
	lda	t232BPSTable-10,x
	sta	(slBase),y	;and set the bps rate.
.if	C64
	PopB	CPU_DATA
.endif
	jsr	JCkRecv
	ldx	#0
	rts
 40$
	ldx	#1
	.byte	44
 45$
	ldx	#9
 50$
	stx	bpsRate
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#3	;point at control register.
	lda	(slBase),y
	and	#%11110000	;first clear the lower nybble.
	ora	bpsMaskTable-1,x
	sta	(slBase),y	;and store the new value.
.if	C64
	PopB	CPU_DATA
.endif
	jsr	JCkRecv
	ldx	#0
	rts

t232BPSTable:
	.byte	%00000010,%00000001,%00000000
bpsMaskTable:
	.byte	%00010101,%00010111,%00011000
	.byte	%00011010,%00011011,%00011100
	.byte	%00011101,%00011110,%00011111

;this routine will send a break.

JOnBreak:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2	;offset to command register.
	lda	(slBase),y	;get the current setting.
	ora	#%00001100	;and make sure bits 2 and 3 are set.
	sta	(slBase),y	;and store the new value to send a break.
.if	C64
	PopB	CPU_DATA
.endif
	rts

;this will turn the break off.

JOffBreak:
	bit	rtsStatus
	bpl	50$
;	bit	intSendStatus
;	bmi	40$
	lda	#%00001000
;	.byte	44
; 40$
;	lda	#%00000100
	.byte	44
 50$
	lda	#%00000000
	sta	breakMask
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	ldy	#2
	lda	(slBase),y
	and	#%11110011
	ora	breakMask
	sta	(slBase),y
.if	C64
	PopB	CPU_DATA
.endif
	rts

breakMask:
	.byte	#%00001000


endSLDriver:

