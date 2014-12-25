;*****************************************
;
;
;	HTTP1
;
;
;
;*****************************************


	.psect

;structure of the http data:
;first bank:
;  bytes 0,1 points to beginning of data portion.
;  bytes 2-4 points to last byte of data.
;  bytes 5-7 size of data portion.
;  byte 8 first byte of header portion.
;data portion follows the header and will
;continue on into additional banks if needed.

;+++for now, this just fetches one document and
;+++then closes the connection.
JStartHTTP:
	LoadB	srvrTFlag,#0
	MoveW	r0,r0NameSave
	MoveB	r1L,r0NameSave+2
	MoveB	a1L,defHTTPvars+4
	LoadB	a0L,#0
	sta	a0H
	ldy	#0
 10$
	lda	defHTTPvars,y
;	sta	[a0],y
	.byte	$97,a0
	iny
	cpy	#8
	bcc	10$
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	and	#%10111111
;	sta	dloadFlag
	.byte	$8f,[dloadFlag,]dloadFlag,0
	lda	dmnNmField+0
	bne	50$
	ldy	#47
 40$
	lda	dmnNmField+256,y
	sta	dmnNmField,y
	dey
	bpl	40$
 50$
	ldx	#0
	jsr	URLBarMsg	;"Looking up: ..."
	LoadW	r0,#dmnNmField
;	phk
	.byte	$4b
	PopB	r1L
	jsr	JReslvAddress
	bcc	90$
	PushW	r0
	PushB	r1L
	ldx	#1
	jsr	URLBarMsg	;"Connecting to: ..."
	PopB	r1L
	PopW	r0
	LoadW	r2,#$0200	;indicate an http session.
	LoadW	r3,#80	;destination port.
	jsr	JOpnTCPConnection
	bcc	90$
	lda	pathField+0
	cmp	#'/'
	beq	60$
	jsr	FixPathField
 60$
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	bpl	70$
	LoadB	rcvWndwFlag,#%10000000
	MoveW	r0NameSave,r0
	MoveB	r0NameSave+2,r1L
	jsr	StartXFile
 70$
	jsr	ZeroTOD2Clock
	jsr	SndHTTPRequest
	jsr	GetHTTPResponse
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	bpl	80$
	jsr	CloseXFile
	bra	85$
 80$
	jsr	FixEndDPtr
 85$
	lda	respFlag
	sec
	rts
 90$
;+++display error here, if there is one.
	clc
	rts


defHTTPvars:
	.byte	8,0,8,0,3,0,0,0 ;+++the fifth byte can change.

r0NameSave:
	.block	3

dataEnd:
	.block	2

WrHTTPData:
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	bmi	10$
	rts
 10$
	rep	%00110000
	lda	a0
	sta	dataEnd
	ldy	#[0
	.byte	]0
	sty	a0
	sep	%00100000
 20$
;	lda	[a0],y
	.byte	$b7,a0
	cpy	dataEnd
	iny
	phy
	sep	%00010000
	bcs	60$
	jsr	WriteXByte
	rep	%00010000
	ply
	bra	20$
 60$
	rep	%00100000
	pla
	lda	tcpHeader+14
	pha
	lda	#](6*1460)
	.byte	[(6*1460)
	sta	tcpHeader+14
	pla
	beq	80$
	sep	%00100000
	rts
 80$
	sep	%00100000
	jmp	AckThisPacket

FixDataPtrs:
	MoveB	defHTTPvars+4,r1L
	LoadB	r0L,#0
	sta	r0H
	ldy	#0
	lda	httpHdrSize+0
;	sta	[r0],y
	.byte	$97,r0
	ldy	#2
;	sta	[r0],y
	.byte	$97,r0
	ldy	#1
	lda	httpHdrSize+1
;	sta	[r0],y
	.byte	$97,r0
	ldy	#3
;	sta	[r0],y
	.byte	$97,r0
	rts

FixEndDPtr:
	PushB	a1L
	PushB	a0H
	PushB	a0L
	MoveB	defHTTPvars+4,a1L
	LoadB	a0L,#0
	sta	a0H
	ldy	#2
 10$
	pla
;	sta	[a0],y
	.byte	$97,a0
	iny
	cpy	#5
	bcc	10$
	ldx	#0
 20$
;	lda	htmlSize,x
	.byte	$bf,[htmlSize,]htmlSize,0
;	sta	[a0],y
	.byte	$97,a0
	inx
	iny
	cpy	#8
	bcc	20$
	rts

FixPathField:
	ldy	#0
 5$
	lda	pathField+256,y
	sta	pathWork,y
	iny
	cpy	#160
	bcc	5$
	ldx	#0
	ldy	#157
 10$
	lda	pathWork,y
	cmp	#'/'
	beq	20$
	dey
	bne	10$
	lda	#'/'
	sta	pathWork+0
 20$
	iny
 30$
	lda	pathField,x
	beq	60$
	cmp	#'.'
	bne	50$
	lda	pathField+1,x
	cmp	#'.'
	beq	40$
	cmp	#'/'
	bne	45$
	inx
	inx
	bra	30$
 40$
	lda	pathField+2,x
	cmp	#'/'
	bne	45$
	inx
	inx
	inx
	dey
	beq	20$
	dey
	beq	20$
	bne	10$
 45$
	lda	#'.'
 50$
	sta	pathWork,y
	inx
	iny
	cpy	#159
	bcc	30$
 60$
	lda	#0
 65$
	sta	pathWork,y
	iny
	cpy	#160
	bcc	65$
 70$
	sta	pathField+256,y
	iny
	bne	70$	;wipe out the old anchor name field.
	ldy	#0
 80$
	lda	pathWork,y
	sta	pathField,y
	iny
	cpy	#160
	bcc	80$
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	bmi	90$
	ldy	#0
 85$
	lda	pathWork,y
	sta	pathField+256,y
	iny
	cpy	#160
	bcc	85$
 90$
	rts

pathWork:
	.block	160

ShChnkBytes:
	ldx	#0
 10$
;	lda	htmlSize+0
	.byte	$bf,[(htmlSize+0),](htmlSize+0),0
	sta	r0,x
	sta	r3,x
	inx
	cpx	#3
	bcc	10$
	jmp	SBR2

ShBytesRecvd:
	sec
;	lda	htmlSize+0
	.byte	$af,[(htmlSize+0),](htmlSize+0),0
	sbc	pkhtmlSize+0
	sta	r0L
	sta	r3L
;	lda	htmlSize+1
	.byte	$af,[(htmlSize+1),](htmlSize+1),0
	sbc	pkhtmlSize+1
	sta	r0H
	sta	r3H
;	lda	htmlSize+2
	.byte	$af,[(htmlSize+2),](htmlSize+2),0
	sbc	pkhtmlSize+2
	sta	r1L
	sta	r4L
SBR2:
	LoadB	r1H,#0
	sta	r4H
	PushW	r0
	PushW	r1
	jsr	GetBytSec
	MoveW	r0,r2
	PopW	r1
	PopW	r0
	ldx	#2
	jmp	URLBarMsg	;...bytes recvd

SndHTTPRequest:
;	phk
	.byte	$4b
	PopB	r1L
	LoadW	r0,#getTxt
	jsr	StorR0String
	LoadW	r0,#pathField
	jsr	StorR0String
	LoadW	r0,#httpVTxt
	jsr	StorR0String

	LoadW	r0,#hostTxt
	jsr	StorR0String
	LoadW	r0,#dmnNmField
	jsr	StorR0String
	LoadW	r0,#crlfTxt
	jsr	StorR0String

	LoadW	r0,#usrAgntTxt
	jsr	StorR0String
	LoadW	r0,#usrAgntString
	jsr	StorR0String
	LoadW	r0,#crlfTxt
	jsr	StorR0String

;	lda	svpageLoaded
	.byte	$af,[svpageLoaded,]svpageLoaded,0
	and	#%01000000
	beq	80$
	LoadW	r0,#referTxt
	jsr	StorR0String
	LoadW	r0,#refhttpTxt
	jsr	StorR0String
	LoadW	r0,#dmnNmField+256
	jsr	StorR0String
	LoadW	r0,#pathField+256
	jsr	StorR0String
	LoadW	r0,#crlfTxt
	jsr	StorR0String
 80$
	LoadW	r0,#crlfTxt
	jsr	StorR0String
	jmp	SendBufData

StorR0String:
	ldy	#0
 20$
;	lda	[r0],y
	.byte	$b7,r0
	beq	30$
	jsr	StorTCPSpot
	iny
	bne	20$
 30$
	rts

getTxt:
	.byte	"GET ",0
httpVTxt:
	.byte	" HTTP/1.1"
;also a continuation of httpVTxt.
crlfTxt:
	.byte	CR,LF,0
hostTxt:
	.byte	"Host: ",0
usrAgntTxt:
	.byte	"User-Agent: ",0
usrAgntString:
.if	C64
	.byte	"Wave64/"
	.byte	VERSLETTER,VERSMAJOR,".",VERSMINOR
	.byte	" Wheels/Commodore64/CMD_SuperCPU",0
.else
	.byte	"Wave128/"
	.byte	VERSLETTER,VERSMAJOR,".",VERSMINOR
	.byte	" Wheels/Commodore128/CMD_SuperCPU",0
.endif

referTxt:
	.byte	"Referer: ",0
refhttpTxt:
	.byte	"http://",0

GetHTTPResponse:
	jsr	Html0Size
	jsr	ParseHeaders
	php
	jsr	FixDataPtrs
	plp
	bcc	28$
	bit	respFlag
	bvs	28$
	bit	chunkedFlag
	bpl	5$
	jmp	DoChunkPackets
 5$
	MoveB	thtmlSize+0,pkhtmlSize+0
	MoveB	thtmlSize+1,pkhtmlSize+1
	MoveB	thtmlSize+2,pkhtmlSize+2
	MoveB	thtmlSize+3,pkhtmlSize+3
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	bpl	10$
	LoadB	a0L,#0
	sta	a0H
 10$
	jsr	JSLCkAbortKey
	bcc	90$
	jsr	GetHTTPPacket
	bcs	30$
	jsr	SmackServer
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	bpl	25$
 20$
	lda	tcpHeader+14
	ora	tcpHeader+15
	bne	25$
	jsr	WrHTTPData
 25$
;	lda	tcpOpen
	.byte	$af,[tcpOpen,]tcpOpen,0
	bmi	10$
	jsr	WrHTTPData
	bra	90$
 28$
	bra	95$
 30$
	beq	40$
	LoadB	srvrTFlag,#0
	jsr	ShBytesRecvd
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	bpl	10$
	bmi	20$
 40$
	LoadB	srvrTFlag,#0
	jsr	ShBytesRecvd
	jsr	WrHTTPData
	bra	95$
 90$
	sec
;	lda	htmlSize+0
	.byte	$af,[(htmlSize+0),](htmlSize+0),0
	sbc	pkhtmlSize+0
;	sta	htmlSize+0
	.byte	$8f,[(htmlSize+0),](htmlSize+0),0
;	lda	htmlSize+1
	.byte	$af,[(htmlSize+1),](htmlSize+1),0
	sbc	pkhtmlSize+1
;	sta	htmlSize+1
	.byte	$8f,[(htmlSize+1),](htmlSize+1),0
;	lda	htmlSize+2
	.byte	$af,[(htmlSize+2),](htmlSize+2),0
	sbc	pkhtmlSize+2
;	sta	htmlSize+2
	.byte	$8f,[(htmlSize+2),](htmlSize+2),0
 95$
	jsr	FlushHTTP
	jsr	JClsTCPConnection
 96$
	jsr	JSLCkAbortKey
	bcc	96$
	rts

;if a packet is in, this will store it in the buffer
;pointed at by a0-a1L. If no packet is in yet, the
;carry will be clear. Carry is set if at least one byte was received.
GetHTTPPacket:
	lda	pkhtmlSize+0
	ora	pkhtmlSize+1
	ora	pkhtmlSize+2
	ora	pkhtmlSize+3
	beq	80$
 10$
	jsr	JSLGetBufByte
	bcs	30$
	rts
 30$
;	sta	[a0]
	.byte	$87,a0
	inc	a0L
	bne	50$
	inc	a0H
	bne	50$
	ldx	a1L
	jsl	SGetNxtBank,0
	bcs	40$
	LoadB	a0L,#$ff
	sta	a0H
	ina
;	sta	[a0]
	.byte	$87,a0
	beq	50$	;branch always.
 40$
	stx	a1L
	jsl	SClearBank,0
 50$
	lda	pkhtmlSize+0
	bne	65$
	lda	pkhtmlSize+1
	bne	60$
	lda	pkhtmlSize+2
	bne	55$
	dec	pkhtmlSize+3
 55$
	dec	pkhtmlSize+2
 60$
	dec	pkhtmlSize+1
 65$
	dec	pkhtmlSize+0
	bne	70$
	lda	pkhtmlSize+1
	ora	pkhtmlSize+2
	ora	pkhtmlSize+3
	beq	80$
 70$
	jsr	JSLGetBufByte
	bcs	30$
	lda	#1	;clear the zero flag.
 80$
	sec
	rts


DoChunkPackets:
	jsr	Html0Size
	lda	#0
	sta	pkhtmlSize+2
	sta	pkhtmlSize+3
 5$
	jsr	GetChnkSize
	bcc	90$
	MoveB	r2L,pkhtmlSize+0
	sta	thisChunkSize+0
	MoveB	r2H,pkhtmlSize+1
	sta	thisChunkSize+1
	ora	r2L
	beq	60$
 10$
	jsr	JSLCkAbortKey
	bcc	90$
	jsr	GetHTTPPacket
	bcs	30$
	jsr	SmackServer
;	lda	tcpOpen
	.byte	$af,[tcpOpen,]tcpOpen,0
	bmi	10$
	bpl	90$
 30$
	php
	LoadB	srvrTFlag,#0
	plp
	bne	10$	;branch if more data coming.
	clc
;	lda	htmlSize+0
	.byte	$af,[(htmlSize+0),](htmlSize+0),0
	adc	thisChunkSize+0
;	sta	htmlSize+0
	.byte	$8f,[(htmlSize+0),](htmlSize+0),0
;	lda	htmlSize+1
	.byte	$af,[(htmlSize+1),](htmlSize+1),0
	adc	thisChunkSize+1
;	sta	htmlSize+1
	.byte	$8f,[(htmlSize+1),](htmlSize+1),0
;	lda	htmlSize+2
	.byte	$af,[(htmlSize+2),](htmlSize+2),0
	adc	#0
;	sta	htmlSize+2
	.byte	$8f,[(htmlSize+2),](htmlSize+2),0
	jsr	GetCRLF
	bcc	90$
	jsr	ShChnkBytes
	lda	tcpHeader+14
	ora	tcpHeader+15
	bne	5$
	jsr	WrHTTPData
	bra	5$	;go back and check for another chunk.
 60$
	jsr	GetCRLF
 90$
	jsr	WrHTTPData
	jsr	FlushHTTP
	jsr	JClsTCPConnection
 96$
	jsr	JSLCkAbortKey
	bcc	96$
	rts

thisChunkSize:
	.block	2
chnkHexString:
	.block	10

GetChnkSize:
	ldy	#0
 5$
	phy
	jsr	Get1HTTPByte
	ply
	bcc	90$
	cmp	#' '
	beq	5$
	cmp	#TAB
	beq	5$
	bne	15$
 10$
	phy
	jsr	Get1HTTPByte
	ply
	bcc	90$
 15$
	cmp	#CR
	beq	20$
	cmp	#LF
	beq	30$
	cmp	#' '
	beq	20$
	cmp	#TAB
	beq	20$
	sta	chnkHexString,y
	iny
	lda	#0
	sta	chnkHexString,y
	cpy	#9
	bcc	10$
	bcs	90$
 20$
	jsr	Get1HTTPByte
	bcc	90$
	cmp	#LF
	bne	20$
 30$
	LoadW	r0,#chnkHexString
;	phk
	.byte	$4b
	PopB	r1L
	jsl	SHexTo32,0
	rts
 90$
	clc
	rts


GetCRLF:
	jsr	Get1HTTPByte
	bcc	90$
	cmp	#CR
	bne	50$
	jsr	Get1HTTPByte
	bcc	90$
 50$
	cmp	#LF
	bne	90$
	sec
	rts
 90$
	clc
	rts

FlushHTTP:
	jsr	JSLGetBufByte
	bcs	FlushHTTP
	rts

Html0Size:
	lda	#0
;	sta	htmlSize+0
	.byte	$8f,[(htmlSize+0),](htmlSize+0),0
;	sta	htmlSize+1
	.byte	$8f,[(htmlSize+1),](htmlSize+1),0
;	sta	htmlSize+2
	.byte	$8f,[(htmlSize+2),](htmlSize+2),0
	rts

;this will try to wake up a slow server.
SmackServer:
	bit	srvrTFlag
	bmi	20$
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
	sed
;	lda	$dd09
	.byte	$af,[$dd09,]$dd09,0
	clc
	adc	#$05
	and	#%00001111
	sta	curTSeconds
	cld
.if	C64
	PopB	CPU_DATA
.endif
	LoadB	srvrTFlag,#%10000000
	rts
 20$
.if	C64
	ldx	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
.endif
;	lda	$dd09
	.byte	$af,[$dd09,]$dd09,0
.if	C64
	stx	CPU_DATA
.endif
	and	#%00001111
	cmp	curTSeconds
	beq	50$
	rts
 50$
	LoadB	srvrTFlag,#0
	jmp	SendBufData

srvrTFlag:
	.block	1
curTSeconds:
	.block	1


;this is called to receive the first part
;of an HTTP file transfer. It's main purpose
;is to read through the header portion at the
;beginning to derive at various pieces of
;info needed to finish receiving and handling
;the incoming data.
ParseHeaders:
	LoadB	entsParsed,#%00000000
	sta	chunkedFlag
	sta	respFlag
	sta	a0H
	sta	httpHdrSize+1
	LoadB	a0L,#8
	sta	httpHdrSize+0
	MoveB	defHTTPvars+4,a1L
 10$
	jsr	HTTPLine
	bcc	90$
	bne	10$
	MoveW	a0,httpHdrSize
	MoveB	a1L,r1L
	LoadW	r0,#8
 60$
	jsr	PrsHdrEntity
	jsr	NxtHdrEntity
	bcs	60$
	lda	entsParsed
	and	#%00000100	;did we get Content-Length?
	bne	80$	;branch if so.
	bit	chunkedFlag
	bmi	75$
	LoadB	r2L,#$ff
	sta	r2H
	sta	r3L
	sta	r3H
	jsr	R2R3ToSize
	sec
	rts
 75$
	jsr	HSz2HTMLSize
 80$
	sec
	rts
 90$
	jsr	HSz2HTMLSize
	clc
	rts

;this puts one line into the buffer pointed at
;by a0-a1L. If the line was empty (just CR/LF),
;then the equals flag is set.
HTTPLine:
	lda	#0
	.byte	44
 10$
	lda	#1
	sta	emptyLineFlag
	jsr	Get1HTTPByte
	bcc	90$
;	sta	[a0]
	.byte	$87,a0
	inc	a0L
	bne	50$
	inc	a0H
	beq	90$
 50$
	cmp	#CR
	beq	60$
	cmp	#LF
	bne	10$
	beq	65$
 60$
	jsr	Get1HTTPByte
	bcc	90$
;	sta	[a0]
 65$
	.byte	$87,a0
	inc	a0L
	bne	70$
	inc	a0H
	beq	90$
 70$
	cmp	#LF
	bne	50$
	lda	emptyLineFlag
	sec
	rts
 90$
	clc
	rts

emptyLineFlag:
	.block	1


Get1HTTPByte:
 10$
	jsr	JSLCkAbortKey
	bcc	90$
	jsr	JSLGetBufByte
	bcc	20$
	rts
 20$
;	lda	tcpOpen
	.byte	$af,[tcpOpen,]tcpOpen,0
	bmi	10$
 90$
	clc
	rts

PrsHdrEntity:
	ldx	#0
	LoadB	r1H,#%00000001
 10$
	lda	r1H
	and	entsParsed
	beq	20$
 15$
	asl	r1H
	inx
	cpx	#6	;6 entities supported currently.
	bcc	10$
	rts
 20$
	lda	entLTable,x
	sta	r2L
	lda	entHTable,x
	sta	r2H
	jsr	CmpR0R2FStrings
	bne	15$
	PushW	r0
	PushB	r1L
	txa
	asl	a
	tax
;	jsr	(entRoutines,x)
	.byte	$fc,[entRoutines,]entRoutines
	PopB	r1L
	PopW	r0
	rts

CmpR0R2FStrings:
	ldy	#0
 35$
	lda	(r2),y
	beq	40$
;	cmp	[r0],y
	.byte	$d7,r0
	beq	38$
	and	#%11011111
;	cmp	[r0],y
	.byte	$d7,r0
	bne	40$
 38$
	iny
	bne	35$	;branch always.
 40$
	rts

pkhtmlSize:
	.block	4
thtmlSize:
	.block	4
chunkedFlag:
	.block	1
respFlag:
	.block	1
httpHdrSize:
	.block	2
entLTable:
	.byte	[htString,[ctString,[clString
	.byte	[teString,[cLocString,[locString
entHTable:
	.byte	]htString,]ctString,]clString
	.byte	]teString,]cLocString,]locString
entRoutines:
	.word	RespResult,GetMedType,GetHTTPLength
	.word	SetForChunked,GetCurLocation,GetNewLocation
entsParsed:
	.block	1
htString:
	.byte	"http/",0
ctString:
	.byte	"content-type:",0
clString:
	.byte	"content-length:",0
teString:
	.byte	"transfer-encoding:",0
cLocString:
	.byte	"content-"
locString:
	.byte	"location:",0


NxtHdrEntity:
	jsr	NxtHdrLine
	bcc	90$
;	lda	[r0]
	.byte	$a7,r0
	cmp	#CR
	beq	90$
	cmp	#LF
	beq	90$
	sec
	rts
 90$
	clc
	rts

PntHdrParameter:
	ldy	#0
 10$
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#CR
	beq	15$
	cmp	#LF
	beq	15$
	cmp	#':'
	beq	20$
	cmp	#' '
	beq	20$
	cmp	#TAB
	beq	20$
	iny
	bne	10$
 15$
	clc
	rts
 20$
	iny
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#CR
	beq	15$
	cmp	#LF
	beq	15$
	cmp	#' '
	beq	20$
	cmp	#TAB
	beq	20$
	tya
	clc
	adc	r0L
	sta	r0L
	bcc	30$
	inc	r0H
 30$
	sec
	rts

NxtHdrLine:
	ldy	#0
 10$
;	lda	[r0],y
	.byte	$b7,r0
 20$
	cmp	#CR
	beq	25$
	cmp	#LF
	beq	30$
	bne	50$
 25$
	iny
;	lda	[r0],y
	.byte	$b7,r0
	cmp	#LF
	bne	20$
 30$
	iny
	beq	90$
	tya
	clc
	adc	r0L
	sta	r0L
	bcc	40$
	inc	r0H
 40$
	sec
	rts
 50$
	iny
	bne	10$
 90$
	clc
	rts

RespResult:
	jsr	PntHdrParameter
	bcc	90$
;	lda	[r0]
	.byte	$a7,r0
	cmp	#'2'
	beq	80$
	cmp	#'3'
	bne	80$
	lda	#%11000000
	.byte	44
 80$
	lda	#%10000000
	sta	respFlag
 90$
	lda	entsParsed
	ora	#%00000001
	sta	entsParsed
	rts


GetNewLocation:
	lda	entsParsed
	ora	#%00010000
	sta	entsParsed
	bit	respFlag
	bvc	95$
	jsr	PntHdrParameter
	bcc	90$
	jmp	MovPar2HREF
 90$
	LoadB	respFlag,#%10000000 ;make it look like it's OK.
 95$
	rts


GetCurLocation:
	lda	entsParsed
	ora	#%00100000
	sta	entsParsed
	bit	respFlag
	bvs	80$
	jsr	PntHdrParameter
	bcc	80$
	jsr	MovPar2HREF
	ldx	#0
 20$
	lda	anchNmField,x
	sta	anchFldSave,x
	inx
	cpx	#32
	bcc	20$
	jsr	JSepHREFString
	ldx	#0
 30$
	lda	anchFldSave,x
	sta	anchNmField,x
	inx
	cpx	#32
	bcc	30$
 80$
	rts

anchFldSave:
	.block	32

MovPar2HREF:
	ldy	#0
 20$
;	lda	[r0],y
	.byte	$b7,r0
	beq	30$
	cmp	#CR
	beq	30$
	cmp	#LF
	beq	30$
	sta	hrefString,y
	iny
	cpy	#255
	bcc	20$
 30$
	lda	#0
 40$
	sta	hrefString,y
	iny
	bne	40$
	rts

GetMedType:
	lda	entsParsed
	ora	#%00000010
	sta	entsParsed
	jsr	PntHdrParameter
	bcc	90$
	LoadB	txtParString+4,#0
	LoadW	r2,#txtParString
	jsr	CmpR0R2FStrings
	bne	90$
	LoadB	txtParString+4,#'/'
	jsr	CmpR0R2FStrings
	bne	95$
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	and	#%11111100
	ora	#%00000010
;	sta	dloadFlag
	.byte	$8f,[dloadFlag,]dloadFlag,0
	rts
 90$
;	lda	dloadFlag
	.byte	$af,[dloadFlag,]dloadFlag,0
	ora	#%01000000
;	sta	dloadFlag
	.byte	$8f,[dloadFlag,]dloadFlag,0
 95$
	rts

txtParString:
	.byte	"text/html",0

GetHTTPLength:
	jsr	PntHdrParameter
	bcc	90$
	jsr	GetCLParam
	bcc	90$
	jsr	R2R3ToSize
	lda	entsParsed
	ora	#%00000100
	sta	entsParsed
 90$
	rts

R2R3ToSize:
	lda	r2L
	sta	thtmlSize+0
;	sta	htmlSize+0
	.byte	$8f,[(htmlSize+0),](htmlSize+0),0
	lda	r2H
	sta	thtmlSize+1
;	sta	htmlSize+1
	.byte	$8f,[(htmlSize+1),](htmlSize+1),0
	lda	r3L
	sta	thtmlSize+2
;	sta	htmlSize+2
	.byte	$8f,[(htmlSize+2),](htmlSize+2),0
	lda	r3H
	sta	thtmlSize+3
	rts

HSz2HTMLSize:
	lda	httpHdrSize+0
;	sta	htmlSize+0
	.byte	$8f,[(htmlSize+0),](htmlSize+0),0
	lda	httpHdrSize+1
;	sta	htmlSize+1
	.byte	$8f,[(htmlSize+1),](htmlSize+1),0
	lda	#0
;	sta	htmlSize+2
	.byte	$8f,[(htmlSize+2),](htmlSize+2),0
	sta	thtmlSize+0
	sta	thtmlSize+1
	sta	thtmlSize+2
	sta	thtmlSize+3
	rts

GetCLParam:
	ldy	#0
 50$
;	lda	[r0],y
	.byte	$b7,r0
	beq	60$
	cmp	#CR
	beq	60$
	cmp	#LF
	beq	60$
	cmp	#' '
	beq	60$
	cmp	#TAB
	beq	60$
	sta	clLenString,y
	iny
	cpy	#11
	bcc	50$
	clc
	rts
 60$
	lda	#0
	sta	clLenString,y
	LoadW	r0,#clLenString
;	phk
	.byte	$4b
	PopB	r1L
	jsl	SDecTo32,0
	rts

clLenString:
	.block	12


SetForChunked:
	jsr	PntHdrParameter
	bcc	90$
	LoadW	r2,#chunkString
	jsr	CmpR0R2FStrings
	bne	90$
	LoadB	chunkedFlag,#%10000000
	lda	entsParsed
	ora	#%00000100	;ignore Transfer-Length fields now.
	sta	entsParsed
 90$
	rts

chunkString:
	.byte	"chunked",0
