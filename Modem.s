;************************************************************

;	Modem

;	Modem handling routines.

;************************************************************



	.psect


IntRecvRoutine:
;	sta	long
	.byte	$8f
recvLocation:
	.word	$0000
recvBank:
	.byte	$03	;final byte of sta long.
	inc	recvLocation+0
	bne	50$
	inc	recvLocation+1
 50$
	rts

JGetBufByte:
	bit	commMode
	bmi	JGetTCPByte
JGetFrmBuf:
	lda	recvLocation+0
	cmp	getLocation+0
	bne	20$
	lda	recvLocation+1
	cmp	getLocation+1
	bne	20$
	clc
	rts
 20$
;	lda	long
	.byte	$af
getLocation:
	.word	$0000
getBank:
	.byte	$03
	inc	getLocation+0
	bne	50$
	inc	getLocation+1
 50$
	sec
	rts



JGetTCPByte:
	ldx	tcpInStart
	cpx	tcpInEnd
	beq	GTB3
;	lda	tcpInBuf,x
	.byte	$bf,[tcpInBuf,]tcpInBuf
rcvTCPBank:
	.byte	0	;this is set during startup.
	inc	tcpInStart
	sec
	rts
GTB3:
	jsr	LLdTCPBlock	;load the buffer with data.
	bcs	JGetTCPByte
	rts


JPutTCPByte:
	ldx	tcpOutEnd
;	sta	tcpOutBuf,x
	.byte	$9f,[tcpOutBuf,]tcpOutBuf
sndTCPBank:
	.byte	0	;this is set during startup.
	inx
	stx	tcpOutEnd
	cpx	#255
	bcc	80$
	jsr	OutTermBuffer
 80$
	ldx	#0
	rts


OutTermBuffer:
	PushB	r1H
	PushW	r11
	jsr	LOutTCPBuffer
	PopW	r11
	PopB	r1H
	bcs	80$
	bit	flushRunning
	bmi	80$
	ldx	flushOffset
	LoadW	r0,#FlushTCP
	jsr	AddMnRoutine
	stx	flushOffset
	LoadW	r0,#1
	jsr	JOnTimer
	LoadB	flushRunning,#%10000000
 80$
	rts

flushRunning:
	.block	1

FlushTCP:
	jsr	JCkTimer
	bcc	80$
	PushB	r1H
	PushW	r11
	jsr	LOutTCPBuffer
	PopW	r11
	PopB	r1H
	bcs	70$
	LoadW	r0,#2
	jmp	JOnTimer
 70$
	ldx	flushOffset
	jsr	RemvMnRoutine
	LoadB	flushOffset,#0
	sta	flushRunning
 80$
	rts


JOpenModem:
	ldx	desDataBits
	jsr	SetDataBits
	ldx	dataBits
	stx	desDataBits
	lda	desParity
	jsr	SetParity
	lda	parityBit
	sta	desParity
	lda	desStopBits
	jsr	SetStopBits
	lda	stopBits
	sta	desStopBits
	LoadB	recvLocation+1,#0 ;zero out the buffer.
	sta	recvLocation+0
	sta	getLocation+1
	sta	getLocation+0
	jsr	OnDTR
	jsr	OnRTS
	LoadW	recvVector,#IntRecvRoutine
	jsr	SetNMIInterrupts
	jsr	OnNMIReceive
	LoadB	xOutMode,#0	;start out with OK to output.
	LoadB	modemOpen,#%10000000
	jmp	CkRecv	;remove any byte hanging
			;in the SwiftLink.

JCloseModem:
	ldx	flushOffset
	jsr	RemvMnRoutine
	LoadB	flushOffset,#0
	sta	flushRunning
	LoadB	recvVector+1,#0
	sta	recvVector+0
	jsr	OffNMIReceive
	jsr	RstrNMIInterrupts
	jsr	OffRTS
	jsr	OffDTR
	LoadB	modemOpen,#%00000000
	rts


JDefSLSettings:
	lda	defVtOn
	ora	#%01111111
	sta	vtOn
	sta	curVtOn
	MoveB	defAnsiOn,ansiOn
	LoadB	keyPadMode,#%00000000
	LoadB	deleteValue,#$ff
	bit	commMode
	bmi	80$
	LoadB	deleteValue,#8
	MoveB	defDataBits,desDataBits
	MoveB	defParity,desParity
	MoveB	defStopBits,desStopBits
	jsr	JOpenModem
	ldx	defBaudRate
	stx	desBaudRate
	bne	60$
	ldx	globalBPSRate
	beq	80$
 60$
	jsr	SetBPS
 80$
	rts


;while nmi is enabled, if InitForIO must be called,
;call this instead.
JInitIORecv:
	jsr	OffNMIReceive
	jsr	RstrNMIInterrupts
	jsr	InitForIO
	jsr	SetNMIInterrupts
	jmp	OnNMIReceive

;while nmi is enabled, if DoneWithIO must be called,
;call this instead.
JDoneIORecv:
	jsr	OffNMIReceive
	jsr	RstrNMIInterrupts
	jsr	DoneWithIO
	jsr	SetNMIInterrupts
	jmp	OnNMIReceive

JDisconnect:
	lda	ispNumber
	bne	5$
	bit	commMode
	bpl	80$
	jmp	LSndTrmRequest
 5$
	MoveB	ignoreDCD,xignoreDCD
	LoadB	dcdChecks,#3
	bit	commMode
	bpl	10$
	jsr	LSndTrmRequest
 10$
	jsr	OffNMIReceive
	jsr	RstrNMIInterrupts
	jsr	OffRTS
	jsr	OffDTR
	LoadW	r0,#2
	jsr	JOnTimer	;set the timer.
 20$
	jsr	CkAbortKey
	bcc	30$
	jsr	JCkTimer	;has timer run down yet?
	bcc	20$	;branch if not.
 30$
	jsr	OnDTR
	jsr	OnRTS
	jsr	SetNMIInterrupts
	jsr	OnNMIReceive
	LoadB	commMode,#%00000000
	sta	ignoreDCD
	bit	xignoreDCD
	bmi	60$
	jsr	CheckDCD
	bit	dcdStatus
	bpl	60$
	dec	dcdChecks
	bne	10$
 60$
	LoadW	r0,#1
	jsr	JOnTimer	;set the timer.
 70$
	jsr	CkAbortKey
	bcc	80$
	jsr	JCkTimer	;has timer run down yet?
	bcc	70$	;branch if not.
 80$
	LoadB	phDirMode,#0
	rts

dcdChecks:
	.block	1
xignoreDCD:
	.block	1

AutoBaud:
	lda	slT232Flag
	beq	90$
	ldx	#11
 10$
	jsr	SetBPS
	jsr	CkForAT
	bcc	50$
	rts
 50$
	ldx	bpsRate
	dex
	cpx	#3
	bcs	10$	;branch always.
 90$
	ldx	#8
	jmp	SetBPS


CkForAT:
	LoadW	r0,#4
	jsr	JOn16Timer
 10$
	jsr	JGetBufByte
	jsr	CkAbortKey
	bcc	90$
	jsr	JCkTimer
	bcc	10$
	LoadW	r0,#8
	jsr	JOn16Timer
	lda	#'A'
	jsr	TimeSend
	bcc	90$
	lda	#'T'
	jsr	TimeSend
	bcc	90$
	lda	#CR
	jsr	TimeSend
	bcc	90$
	jsr	WaitForAT
	bcc	90$
	jsr	PurgeModem
	sec
 90$
	rts

TimeSend:
 10$
	pha
	jsr	CkSend
	bne	20$
	pla
	sec
	rts
 20$
	jsr	CkAbortKey
	bcc	90$
	jsr	JCkTimer
	bcs	90$
	pla
	bra	10$
 90$
	pla
	clc
	rts

WaitForAT:
 10$
	jsr	GetTimedByte
	bcc	90$
 20$
	cmp	#'A'
	bne	10$
	jsr	GetTimedByte
	bcc	90$
	cmp	#'T'
	bne	20$
 30$
	jsr	GetTimedByte
	bcc	90$
	cmp	#LF
	beq	30$
	cmp	#CR
	beq	30$
	cmp	#'0'
	beq	80$
	cmp	#'O'
	bne	90$
 80$
	sec
	rts
 90$
	clc
	rts


GetTimedByte:
 20$
	jsr	JGetBufByte
	bcs	30$
	jsr	CkAbortKey
	bcc	25$
	jsr	JCkTimer
	bcc	20$
 25$
	clc
 30$
	rts

PurgeModem:
	LoadW	r0,#8
	jsr	JOn16Timer
 20$
	jsr	JGetBufByte
	jsr	CkAbortKey
	bcc	90$
	jsr	JCkTimer
	bcc	20$
 90$
	rts


;set r0 with the desired number of seconds to set the timers
;to count down from. This routine will then load the appropriate
;values into timer A and timer B. When bit 1 at $dd0d is set,
;the time has run out. Interrupts are not enabled. It is up to
;the calling routine to either enable them, if desired, or to
;manually monitor bit 1 at $dd0d. Or CkTimer can be called
;to check it.

JOnTimer:
	ldx	#4
 10$
	asl	r0L	;calculate setting required for
	rol	r0H	;desired number of seconds. (approx.)
	dex
	bne	10$
;enter at this point to set the timer in 1/16 second increments.
JOn16Timer:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	lda	$dd0e	;turn the timers off.
	and	#%10000000
	sta	$dd0e
	lda	#%00000000
	sta	$dd0f
	LoadW	$dd04,#$ffff	;set latch value for timer A.
	MoveW	r0,$dd06	;set latch value for timer B.
	LoadB	$dd0d,#%01111111 ;disable CIA#2 interrupts.
	lda	$dd0d	;clear any current latch values.
	LoadB	$dd0f,#%01011001 ;turn timer B on.
	lda	$dd0e
	ora	#%00010001
	sta	$dd0e	;turn timer A on.
.if	C64
	PopB	CPU_DATA
.endif
	LoadB	timerRunning,#%10000000
	rts

;this just turns the timers off.
JOffTimer:
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	lda	$dd0e	;turn the timers off.
	and	#%10000000
	sta	$dd0e
	lda	#%00000000
	sta	$dd0f
.if	C64
	PopB	CPU_DATA
.endif
	LoadB	timerRunning,#%00000000
	rts


;this checks the timer to see if it's counted
;down yet. If so, the carry will be set upon
;return.
JCkTimer:
	bit	timerRunning
	bmi	20$
	sec
	rts
 20$
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	lda	$dd0d
	lsr	a
	lsr	a
.if	C64
	PopB	CPU_DATA
.endif
	bcc	90$
	LoadB	timerRunning,#%00000000
 90$
	rts

timerRunning:
	.block	1
