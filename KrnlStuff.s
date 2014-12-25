;*************************************
;
;	KrnlStuff
;
;*************************************


	.psect

JPutLongString:
	PushB	r1L
	PushW	r0
 10$
;	lda	[r0]
	.byte	$a7,r0
	beq	80$
	and	#%01111111
	cmp	#32
	bcc	30$
	cmp	#127
	bcc	40$
 30$
	lda	#'?'
 40$
	ldx	r1L
	phx
	jsr	FastPutChar
	PopB	r1L
	CmpW	r11,rightMargin
	bcs	80$
	inc	r0L
	bne	10$
	inc	r0H
	bne	10$
 80$
	PopW	r0
	PopB	r1L
	rts

FastPutChar:
	phb
	ldx	#0
	phx
	plb
	jsl	FSmallPutChar,0
	plb
	rts

JDoURLBar:
;	lda	pageLoaded
	.byte	$af,[pageLoaded,]pageLoaded,0
	and	#%01000000
	beq	50$
	jsr	BldHTTPUrlString
 50$
	jsr	R0ToURLString
	clc
;	lda	urlBufPtr
	.byte	$af,[urlBufPtr,]urlBufPtr,0
	adc	r0L
	sta	r0L
	bcc	60$
	inc	r0H
 60$
	jmp	JPutURLString


BldHTTPUrlString:
	jsr	R0ToURLString
	MoveW	r0,r4
	MoveB	r1L,r5L
	LoadW	r0,#httpTxt
;	phk
	.byte	$4b
	PopB	r1L
	jsr	Add2URLString
	jsr	R0ToDMNString
	jsr	Add2URLString
	jsr	R0ToPthString
	jsr	Add2URLString
	lda	anchNmField+0
	beq	50$
	LoadW	r0,#poundString
;	phk
	.byte	$4b
	PopB	r1L
	jsr	Add2URLString
	jsr	R0ToAncString
	jsr	Add2URLString
 50$
	lda	#0
;	sta	[r4]
	.byte	$87,r4
	rts

poundString:
	.byte	"#",0

Add2URLString:
	lda	r4L
	cmp	#255
	beq	30$
 10$
;	lda	[r0]
	.byte	$a7,r0
	beq	30$
;	sta	[r4]
	.byte	$87,r4
	inc	r0L
	bne	20$
	inc	r0H
 20$
	inc	r4L
	lda	r4L
	cmp	#255
	bcc	10$
 30$
	rts

R0ToURLString:
	LoadW	r0,#urlString
;	phk
	.byte	$4b
	PopB	r1L
	rts

R0ToDMNString:
	LoadW	r0,#dmnNmField
;	phk
	.byte	$4b
	PopB	r1L
	rts

R0ToPthString:
	LoadW	r0,#pathField
;	phk
	.byte	$4b
	PopB	r1L
	rts

R0ToAncString:
	LoadW	r0,#anchNmField
;	phk
	.byte	$4b
	PopB	r1L
	rts

httpTxt:
	.byte	"http://",0

PntLeftURL:
.if	C64
	LoadW	r11,#9
.else
	LoadW	r11,#18
.endif
	clc
	lda	#29
	adc	baselineOffset
	sta	r1H
	rts


ClrURLBar:
;	lda	waveRunning
	.byte	$af,[waveRunning,]waveRunning,0
	bmi	10$
	rts
 10$
.if	C128
	jsl	STempHideMouse,0
.endif
	lda	#0
	jsl	SSetPattern,0
	LoadB	r2L,#29
	LoadB	r2H,#37
.if	C64
	LoadW	r3,#8
	LoadW	r4,#319-16
.else
	LoadW	r3,#16
	LoadW	r4,#639-32
.endif
	jsl	SRectangle,0
	rts


JPutURLString:
	jsr	PntLeftURL
PUS2:
	jsr	PUS3
PUS4:
	LoadB	r2L,#29
	LoadB	r2H,#37
	MoveW	r11,r3
.if	C64
	LoadW	r4,#319-16
.else
	LoadW	r4,#639-32
.endif
	CmpW	r3,r4
	bcs	80$
	lda	#0
	jsl	SSetPattern,0
	jsl	SRectangle,0
 80$
	rts

PUS3:
	PushW	rightMargin
.if	C64
	LoadW	rightMargin,#319-16
.else
	LoadW	rightMargin,#639-32
.endif
	jsr	JPutLongString
	PopW	rightMargin
	rts


JByte2Ascii:
	sed
	ldx	#'0'
	sta	r0L
	and	#%00000111
	asl	r0L
	bcc	10$
	inx
	adc	#$27
 10$
	asl	r0L
	bcc	20$
	adc	#$63
 20$
	asl	r0L
	bcc	30$
	adc	#$31
	bcc	30$
	inx
 30$
	asl	r0L
	bcc	40$
	adc	#$15
	bcc	40$
	inx
 40$
	asl	r0L
	bcc	50$
	adc	#$07
	bcc	50$
	inx
 50$
	cld
	stx	resultString+0
	pha
	and	#%00001111
	ora	#'0'
	sta	resultString+2
	pla
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	ora	#'0'
	sta	resultString+1
	LoadW	r0,#resultString
;	phk
	.byte	$4b
	PopB	r1L
	rts

resultString:
	.block	4


;this will take the 32 bit value in r0-r1 and
;make it into an ascii decimal string. The resulting
;string will have no leading zeros, will be null-terminated
;and located at dec32String and also pointed at by
;r0-r1L.
;+++this is currently limited to 24-bit values.
JSizeToDec:
	sed
	rep	%00100000
	lda	#[0
	.byte	]0
	sta	r2
	sta	r3
	ldx	#0
 10$
	lsr	r1
	ror	r0
	bcc	30$
	clc
	lda	bcd24LTable,x
	adc	r2
	sta	r2
	lda	bcd24HTable,x
	adc	r3
	sta	r3
 30$
	inx
	inx
	cpx	#48
	bcc	10$
	cld
	sep	%00100000
	lda	r3H
	jsr	BCD2Dec
	stx	dec32String+0
	sta	dec32String+1
	lda	r3L
	jsr	BCD2Dec
	stx	dec32String+2
	sta	dec32String+3
	lda	r2H
	jsr	BCD2Dec
	stx	dec32String+4
	sta	dec32String+5
	lda	r2L
	jsr	BCD2Dec
	stx	dec32String+6
	sta	dec32String+7
	ldy	#0
	ldx	#0
 40$
	lda	dec32String,y	;now remove leading zeros.
	cmp	#'0'
	bne	50$
	iny
	cpy	#7
	bcc	40$
 50$
	lda	dec32String,y
	sta	dec32String,x
	inx
	iny
	cpy	#10
	bcc	50$
	lda	#0
	sta	dec32String,x
	LoadW	r0,#dec32String
;	phk
	.byte	$4b
	PopB	r1L
	rts

dec32String:
	.block	11

BCD2Dec:
	pha
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	ora	#'0'
	tax
	pla
	and	#%00001111
	ora	#'0'
	rts

;+++fix these tables for 32 bits.
bcd24LTable:
	.word	$0001
	.word	$0002
	.word	$0004
	.word	$0008
	.word	$0016
	.word	$0032
	.word	$0064
	.word	$0128
	.word	$0256
	.word	$0512
	.word	$1024
	.word	$2048
	.word	$4096
	.word	$8192
	.word	$6384
	.word	$2768
	.word	$5536
	.word	$1072
	.word	$2144
	.word	$4288
	.word	$8576
	.word	$7152
	.word	$4304
	.word	$8608

bcd24HTable:
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0000
	.word	$0001
	.word	$0003
	.word	$0006
	.word	$0013
	.word	$0026
	.word	$0052
	.word	$0104
	.word	$0209
	.word	$0419
	.word	$0838


JRstTermScreen:
;	lda	termRunYet
	.byte	$af,[termRunYet,]termRunYet,0
	bmi	JRstrTxtScreen
;fall through...
JSaveTxtScreen:
	lda	#%10000000
;	sta	termRunYet
	.byte	$8f,[termRunYet,]termRunYet,0
.if	C64
	LoadW	r0,#$a000
	LoadB	r1L,#0
	sta	r1H
	LoadW	r2,#8000
	LoadB	r3L,#0
;	lda	termBank
	.byte	$af,[termBank,]termBank,0
	sta	r3H
	jsl	SDoSuperMove,0
	LoadW	r0,#COLOR_MATRIX
	LoadW	r1,#8000
	LoadW	r2,#1000
	jsl	SDoSuperMove,0
	ldx	#7
 30$
;	lda	ansiBold,x
	.byte	$bf,[ansiBold,]ansiBold,0
;	sta	sBold,x
	.byte	$9f,[sBold,]sBold,0
	dex
	bpl	30$
	rts
.else
	jsl	STempHideMouse,0
	LoadB	r0L,#0
	sta	r0H
	sta	r1L
	sta	r1H
	LoadW	r2,#16000
;	lda	termBank
	.byte	$af,[termBank,]termBank,0
	sta	r3L
	jsl	SFetchVRam,0
;	lda	vdcClrMode
	.byte	$af,[vdcClrMode,]vdcClrMode,0
	beq	50$
	LoadW	r0,#16000
	LoadW	r1,#$4000
	LoadW	r2,#2000
	jsl	SFetchVRam,0
 50$
	ldx	#7
 60$
;	lda	ansiBold,x
	.byte	$bf,[ansiBold,]ansiBold,0
;	sta	sBold,x
	.byte	$9f,[sBold,]sBold,0
	dex
	bpl	60$
	rts
.endif

JRstrTxtScreen:
.if	C64
	LoadB	r0L,#0
	sta	r0H
	LoadW	r1,#$a000
	LoadW	r2,#8000
;	lda	termBank
	.byte	$af,[termBank,]termBank,0
	sta	r3L
	LoadB	r3H,#0
	jsl	SDoSuperMove,0
	LoadW	r0,#8000
	LoadW	r1,#COLOR_MATRIX
	LoadW	r2,#1000
	jsl	SDoSuperMove,0
	ldx	#7
 30$
;	lda	sBold,x
	.byte	$bf,[sBold,]sBold,0
;	sta	ansiBold,x
	.byte	$9f,[ansiBold,]ansiBold,0
	dex
	bpl	30$
;	lda	scursorX+0
	.byte	$af,[(scursorX+0),](scursorX+0),0
;	sta	stringX+0
	.byte	$8f,[(stringX+0),](stringX+0),0
;	lda	scursorX+1
	.byte	$af,[(scursorX+1),](scursorX+1),0
;	sta	stringX+1
	.byte	$8f,[(stringX+1),](stringX+1),0
;	lda	scursorY
	.byte	$af,[scursorY,]scursorY,0
;	sta	stringY
	.byte	$8f,[stringY,]stringY,0
	rts

.else
	jsl	STempHideMouse,0
;	lda	vdcClrMode
	.byte	$af,[vdcClrMode,]vdcClrMode,0
	beq	20$
	LoadW	r0,#16000
	LoadW	r1,#$4000
	LoadW	r2,#2000
;	lda	termBank
	.byte	$af,[termBank,]termBank,0
	sta	r3L
	jsl	SStashVRam,0
 20$
	LoadB	r0L,#0
	sta	r0H
	sta	r1L
	sta	r1H
	LoadW	r2,#16000
;	lda	termBank
	.byte	$af,[termBank,]termBank,0
	sta	r3L
	jsl	SStashVRam,0
	ldx	#7
 60$
;	lda	sBold,x
	.byte	$bf,[sBold,]sBold,0
;	sta	ansiBold,x
	.byte	$9f,[ansiBold,]ansiBold,0
	dex
	bpl	60$
;	lda	scursorX+0
	.byte	$af,[(scursorX+0),](scursorX+0),0
;	sta	stringX+0
	.byte	$8f,[(stringX+0),](stringX+0),0
;	lda	scursorX+1
	.byte	$af,[(scursorX+1),](scursorX+1),0
;	sta	stringX+1
	.byte	$8f,[(stringX+1),](stringX+1),0
;	lda	scursorY
	.byte	$af,[scursorY,]scursorY,0
;	sta	stringY
	.byte	$8f,[stringY,]stringY,0
	rts
.endif


JDoURL2Left:
	jsr	R0ToURLString
;	lda	urlBufPtr
	.byte	$af,[urlBufPtr,]urlBufPtr,0
	tay
	ldx	#0
 10$
;	lda	[r0],y
	.byte	$b7,r0
	beq	20$
	iny
	inx
	cpx	#21
	bcc	10$
 20$
	txa
	bne	30$
 25$
	rts
 30$
	dea
	beq	25$
	clc
;	adc	urlBufPtr
	.byte	$6f,[urlBufPtr,]urlBufPtr,0
;	sta	urlBufPtr
	.byte	$8f,[urlBufPtr,]urlBufPtr,0
	jmp	PutPrtlURL

JDoURL2Right:
;	lda	urlBufPtr	;already shifted all the way to start?
	.byte	$af,[urlBufPtr,]urlBufPtr,0
	bne	5$	;branch if not.
	rts
 5$
	sec
	sbc	#20
	bcs	10$
	lda	#0
 10$
;	sta	urlBufPtr
	.byte	$8f,[urlBufPtr,]urlBufPtr,0
PutPrtlURL:
	jsr	R0ToURLString
	clc
;	lda	urlBufPtr
	.byte	$af,[urlBufPtr,]urlBufPtr,0
	adc	r0L
	sta	r0L
	bcc	20$
	inc	r0H
 20$
	jsr	PntLeftURL
	jmp	PUS2


JURLBarMsg:
	phx
	phy
	PushW	r0
	PushB	r1L
	jsl	SUseSystemFont,0
	PopB	r1L
	PopW	r0
	ply
	plx
	txa
	asl	a
	tax
;	jmp	(urlJmpRoutines,x)
	.byte	$7c,[urlJmpRoutines,]urlJmpRoutines

urlJmpRoutines:
	.word	LkngUpHost,CnctgToHost,BytesURL
	.word	SnglMessage,ClrURLBar,XYModemMsg


;this will display "Looking up:" along with the
;domain name from the domain name field within the url bar.
LkngUpHost:
	LoadW	r0,#lookingTxt
	jmp	CTH2

lookingTxt:
	.byte	"Looking up: ",0

CnctgToHost:
	LoadW	r0,#conntgTxt
CTH2:
;	phk
	.byte	$4b
	PopB	r1L
;	lda	waveRunning
	.byte	$af,[waveRunning,]waveRunning,0
	bpl	10$
	jsr	PntLeftURL
	jsr	PUS3
	jsr	R0ToDMNString
	jmp	PUS2
 10$
	jsr	DrMsgBox
	jsr	PntY0Msg
	jsr	JPutLongString
	jsr	PntY1Msg
	LoadW	r0,#hostName
	LoadB	r1L,#0
	jmp	JPutLongString

conntgTxt:
	.byte	"Connecting to: ",0


;call this with y holding a value for the desired message
;to be displayed in the URL bar.
SnglMessage:
	jsr	PntSnglMsg
;	lda	waveRunning
	.byte	$af,[waveRunning,]waveRunning,0
	bpl	10$
	jsr	PntLeftURL
	jmp	PUS2
 10$
	jsr	DrMsgBox
	jsr	PntY1Msg
	jmp	JPutLongString

PntSnglMsg:
	lda	snglLTable,y
	sta	r0L
	lda	snglHTable,y
	sta	r0H
;	phk
	.byte	$4b
	PopB	r1L
	rts

snglLTable:
	.byte	[dialngTxt,[disconTxt,[logngInTxt,[negPPPTxt
	.byte	[sndgUPTxt,[rstgTxt
snglHTable:
	.byte	]dialngTxt,]disconTxt,]logngInTxt,]negPPPTxt
	.byte	]sndgUPTxt,]rstgTxt

dialngTxt:
	.byte	"Dialing out...",0
disconTxt:
	.byte	"Disconnecting...",0
logngInTxt:
	.byte	"Logging in...",0
negPPPTxt:
	.byte	"Negotiating PPP connection...",0
sndgUPTxt:
	.byte	"Sending username and password...",0
rstgTxt:
	.byte	"Resetting...",0

;call this with r0-r1 loaded with a 32 bit value and this
;will print it in ascii to the URL bar with "bytes recvd" added to it.
BytesURL:
	PushW	r2
	jsr	JSizeToDec
	jsr	PntLeftURL
	jsr	PUS3
	LoadW	r0,#bytesTxt
;	phk
	.byte	$4b
	PopB	r1L
	jsr	JPutLongString
	PopW	r0
	PushB	r1H
	PushW	r11
	LoadB	r1L,#0
	sta	r1H
	jsr	JSizeToDec
	PopW	r11
	PopB	r1H
	jsr	JPutLongString
	LoadW	r0,#bPerSecTxt
;	phk
	.byte	$4b
	PopB	r1L
	jsr	JPutLongString
	lda	#')'
	jsr	FastPutChar
	jmp	PUS4

bytesTxt:
	.byte	" bytes recvd (",0


;call this with y holding the value for the
;desired function to perform with this message
;box.
;0 = draw the box and display "FILE: filename"
;	the filename is pointed at by r0L-r1L.
;1 = add "xxxx total bytes" to the box.
;2 = add "xxxx bytes/sec" to the box.
XYModemMsg:
	tya
	asl	a
	tax
;	jmp	(xyJmpRoutines,x)
	.byte	$7c,[xyJmpRoutines,]xyJmpRoutines

xyJmpRoutines:
	.word	BldXYMBox,AddTotBytes,AddByteSec




BldXYMBox:
	jsr	DrMsgBox
	jsr	PntY0Msg
	PushW	r0
	PushB	r1L
	LoadW	r0,#xyFileTxt
;	phk
	.byte	$4b
	PopB	r1L
	jsr	JPutLongString
	PopB	r1L
	PopW	r0
	jsr	JPutLongString
	jmp	ClrRhtMsg

xyFileTxt:
	.byte	"FILE: ",0

AddTotBytes:
	jsr	JSizeToDec
	jsr	PntY1Msg
	jsr	JPutLongString
	LoadW	r0,#btransTxt
;	phk
	.byte	$4b
	PopB	r1L
	jsr	JPutLongString
	jmp	ClrRhtMsg

btransTxt:
	.byte	" bytes transferred",0

AddByteSec:
	jsr	JSizeToDec
	jsr	PntY2Msg
	jsr	JPutLongString
	LoadW	r0,#bPerSecTxt
;	phk
	.byte	$4b
	PopB	r1L
	jsr	JPutLongString
	jmp	ClrRhtMsg

bPerSecTxt:
	.byte	" avg. bytes/sec",0

ClrRhtMsg:
	lda	r1H
	sec
	sbc	#7
	sta	r2L
	clc
	adc	#9
	sta	r2H
	MoveW	r11,r3
.if	C64
	LoadW	r4,#253
.else
	LoadW	r4,#509
.endif
	CmpW	r3,r4
	bcs	80$
	lda	#0
	jsl	SSetPattern,0
	jsl	SRectangle,0
 80$
	rts

DrMsgBox:
	PushW	r0
	PushB	r1L
	LoadB	r2L,#64
	LoadB	r2H,#127
.if	C64
	LoadW	r3,#64
	LoadW	r4,#255
.else
	LoadW	r3,#128
	LoadW	r4,#511
.endif
	lda	#0
	jsl	SSetPattern,0
	jsl	SRectangle,0
	lda	#%11111111
	jsl	SFrameRectangle,0
	inc	r2L
	inc	r2L
	dec	r2H
	AddVW	#2,r3
	SubVW	#1,r4
	lda	#%11111111
	jsl	SFrameRectangle,0
	jsl	SConvToCards,0
;	lda	appDBColor
	.byte	$af,[appDBColor,]appDBColor,0
	sta	r4H
	jsl	SColorRectangle,0
	PopB	r1L
	PopW	r0
	rts

PntY0Msg:
	lda	#80
	.byte	44
PntY1Msg:
	lda	#96
	.byte	44
PntY2Msg:
	lda	#112
	sta	r1H
.if	C64
	LoadW	r11,#80
.else
	LoadW	r11,#160
.endif
	rts


JURLEdFunction:
;	jmp	(urlEdRoutines,x)
	.byte	$7c,[urlEdRoutines,]urlEdRoutines

urlEdRoutines:
	.word	URLEdStart,InsURLChar,URLCtrlChar

URLEdStart:
	jsl	SUseSystemFont,0
	LoadB	currentMode,#SET_PLAINTEXT
	LoadB	kclrFlag,#0
.if	C64
	PushB	CPU_DATA
	LoadB	CPU_DATA,#IO_IN
;	lda	sysMob0Clr
	.byte	$af,[sysMob0Clr,]sysMob0Clr,0
;	sta	mob0clr
	.byte	$8f,[mob0clr,]mob0clr,0
;	sta	mob1clr
	.byte	$8f,[mob1clr,]mob1clr,0
.endif
;	lda	$d01d
	.byte	$af,[$d01d,]$d01d,0
	ora	#%00000010
;	sta	$d01d
	.byte	$8f,[$d01d,]$d01d,0
.if	C64
	PopB	CPU_DATA
.endif
	jsr	PntMseClick
.if	C64
	lda	#9
.else
	lda	#10
.endif
	jsl	SInitTextPrompt,0
	lda	#%10000000
;	sta	alphaFlag
	.byte	$8f,[alphaFlag,]alphaFlag,0
;	sta	urlEdRunning
	.byte	$8f,[urlEdRunning,]urlEdRunning,0
	jsl	SPrmptOn,0
	rts


PntMseClick:
	jsr	PntURLPtr
;	lda	urlBufPtr
	.byte	$af,[urlBufPtr,]urlBufPtr,0
;	sta	urlEdPtr
	.byte	$8f,[urlEdPtr,]urlEdPtr,0
 20$
;	lda	[r0]
	.byte	$a7,r0
	beq	50$
	jsr	JSLGetCharWidth
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	clc
	adc	r11
;	cmp	mouseXClick
	.byte	$cf,[mouseXClick,]mouseXClick,0
	bcc	30$
	bne	50$
 30$
	sta	r11
	inc	r0
	sep	%00100000
	jsr	IncURLEdPtr
	bra	20$
 50$
R11ToSX:
	rep	%00100000
	lda	r11
;	sta	stringX
	.byte	$8f,[stringX,]stringX,0
	sep	%00100000
	sec
	lda	r1H
	sbc	baselineOffset
;	sta	stringY
	.byte	$8f,[stringY,]stringY,0
	rts

PntURLPtr:
	jsr	R0ToURLString
;	lda	urlBufPtr
	.byte	$af,[urlBufPtr,]urlBufPtr,0
	clc
	adc	r0L
	sta	r0L
	bcc	10$
	inc	r0H
 10$
	jmp	PntLeftURL

JSLGetCharWidth:
	phb
	ldx	#0
	phx
	plb
	jsl	FGetCharWidth
	plb
	rts

InsURLChar:
	sta	r2L
	LoadB	kclrFlag,#0
.if	C128
	jsl	STempHideMouse,0
.endif
	jsr	R0ToURLString
;	lda	urlEdPtr
	.byte	$af,[urlEdPtr,]urlEdPtr,0
	cmp	#255
	beq	15$
	clc
	adc	r0L
	sta	r0L
	bcc	10$
	inc	r0H
 10$
	lda	urlString+254
	beq	20$
 15$
	rts
 20$
	jsr	OffEdCursor
	ldx	#253
 30$
	txa
;	cmp	urlEdPtr
	.byte	$cf,[urlEdPtr,]urlEdPtr,0
	bcc	50$
	lda	urlString,x
	sta	urlString+1,x
	dex
	bne	30$
 50$
	lda	r2L
;	sta	[r0]
	.byte	$87,r0
	jsr	PntEdPtr
	jsr	PUS2
	jsr	IncURLEdPtr
	jsr	PntEdPtr
	jsr	CmpRhtEdge
	bcc	60$
	jsr	JDoURL2Left
 60$
	jsr	PntEdPtr
	jsr	R11ToSX

;fall through to next page...

;previous page falls through to here.

OnEdCursor:
	LoadB	alphaFlag,#%10000000
	jsl	SPrmptOn,0
	rts

OffEdCursor:
	php
	sei
	jsl	SPrmptOff,0
	LoadB	alphaFlag,#0
	plp
	rts

IncURLEdPtr:
;	lda	urlEdPtr
	.byte	$af,[urlEdPtr,]urlEdPtr,0
	ina
;	sta	urlEdPtr
	.byte	$8f,[urlEdPtr,]urlEdPtr,0
	rts


URLCtrlChar:
	ldx	#0
 10$
	cmp	ctrlKeyTable,x
	beq	20$
	inx
	cpx	#[(ctrlKeyRoutines-ctrlKeyTable)
	bcc	10$
	rts
 20$
	txa
	asl	a
	tax
	beq	30$
	LoadB	kclrFlag,#0
 30$
;	jmp	(ctrlKeyRoutines,x)
	.byte	$7c,[ctrlKeyRoutines,]ctrlKeyRoutines

ctrlKeyTable:
	.byte	KEY_CLEAR,KEY_DELETE
	.byte	KEY_HOME,KEY_LEFT
	.byte	KEY_RIGHT,128|KEY_HOME
ctrlKeyRoutines:
	.word	KClrURLBar,KDelURLChar
	.word	KHomeURLBar,KLeft1URLChar
	.word	KRht1URLChar,KEndURLBar


KClrURLBar:
	jsr	OffEdCursor
	jsr	R0ToURLString
	ldy	#0
	lda	kclrFlag
	ina
	cmp	#3
	bcc	20$
	lda	#0
 20$
	sta	kclrFlag
	beq	40$
	cmp	#1
	beq	25$
	lda	#0
	.byte	44
 25$
	lda	#'w'
	sta	clrWHTTP+7
	ldy	#0
 30$
	lda	clrWHTTP,y
	beq	40$
;	sta	[r0],y
	.byte	$97,r0
	iny
	bne	30$
 40$
	tya
;	sta	urlEdPtr
	.byte	$8f,[urlEdPtr,]urlEdPtr,0
	lda	#0
;	sta	urlBufPtr
	.byte	$8f,[urlBufPtr,]urlBufPtr,0
 50$
;	sta	[r0],y
	.byte	$97,r0
	iny
	bne	50$
	jsr	PntURLPtr
	jsr	PUS2
	jsr	PntEdPtr
	jsr	R11ToSX
	jmp	OnEdCursor


clrWHTTP:
	.byte	"http://"
	.byte	"www.",0

kclrFlag:
	.block	1

KHomeURLBar:
	jsr	OffEdCursor
	jsr	R0ToURLString
;	lda	urlBufPtr
	.byte	$af,[urlBufPtr,]urlBufPtr,0
	beq	40$
	jsr	PntLeftURL
	jsr	PUS2
	lda	#0
;	sta	urlBufPtr
	.byte	$8f,[urlBufPtr,]urlBufPtr,0
 40$
;	sta	urlEdPtr
	.byte	$8f,[urlEdPtr,]urlEdPtr,0
	jsr	PntEdPtr
	jsr	R11ToSX
	jmp	OnEdCursor


KEndURLBar:
	jsr	OffEdCursor
	jsr	R0ToURLString
	ldy	#0
 10$
;	lda	[r0],y
	.byte	$b7,r0
	beq	20$
	iny
	bne	10$
 20$
	tya
;	sta	urlEdPtr
	.byte	$8f,[urlEdPtr,]urlEdPtr,0
	jsr	PntEdPtr
	jsr	CmpRhtEdge
	bcc	60$
;	lda	urlEdPtr
	.byte	$af,[urlEdPtr,]urlEdPtr,0
	sec
	sbc	#20
;	sta	urlBufPtr
	.byte	$8f,[urlBufPtr,]urlBufPtr,0
	jsr	PntURLPtr
	jsr	PUS2
 60$
	jsr	PntEdPtr
	jsr	R11ToSX
	jmp	OnEdCursor


KLeft1URLChar:
;	lda	urlEdPtr
	.byte	$af,[urlEdPtr,]urlEdPtr,0
	bne	10$
	rts
 10$
	dea
	pha
	jsr	OffEdCursor
	pla
;	sta	urlEdPtr
	.byte	$8f,[urlEdPtr,]urlEdPtr,0
;	cmp	urlBufPtr
	.byte	$cf,[urlBufPtr,]urlBufPtr,0
	bcs	50$
	jsr	JDoURL2Right
 50$
	jsr	PntEdPtr
	jsr	R11ToSX
	jmp	OnEdCursor

KRht1URLChar:
	jsr	R0ToURLString
;	lda	urlEdPtr
	.byte	$af,[urlEdPtr,]urlEdPtr,0
	cmp	#255
	beq	15$
	tay
;	lda	[r0],y
	.byte	$b7,r0
	bne	20$
 15$
	rts
 20$
	jsr	OffEdCursor
	jsr	IncURLEdPtr
	jsr	PntEdPtr
	jsr	CmpRhtEdge
	bcc	60$
	jsr	JDoURL2Left
 60$
	jsr	PntEdPtr
	jsr	R11ToSX
	jmp	OnEdCursor

CmpRhtEdge:
.if	C64
	CmpWI	r11,#(319-24)
.else
	CmpWI	r11,#(639-48)
.endif
	rts

KDelURLChar:
;	lda	urlEdPtr
	.byte	$af,[urlEdPtr,]urlEdPtr,0
	bne	10$
	rts
 10$
	dea
;	sta	urlEdPtr
	.byte	$8f,[urlEdPtr,]urlEdPtr,0
	pha
	jsr	OffEdCursor
.if	C128
	jsl	STempHideMouse,0
.endif
	plx
 20$
	lda	urlString+1,x
	sta	urlString+0,x
	inx
	cpx	#255
	bcc	20$
;	lda	urlEdPtr
	.byte	$af,[urlEdPtr,]urlEdPtr,0
;	cmp	urlBufPtr
	.byte	$cf,[urlBufPtr,]urlBufPtr,0
	bcs	50$
	jsr	JDoURL2Right
	bra	80$
 50$
	jsr	PntEdPtr
	jsr	PUS2
 80$
	jsr	PntEdPtr
	jsr	R11ToSX
	jmp	OnEdCursor


PntEdPtr:
	jsr	PntURLPtr
;	lda	urlBufPtr
	.byte	$af,[urlBufPtr,]urlBufPtr,0
	sta	r2L
 20$
	lda	r2L
;	cmp	urlEdPtr
	.byte	$cf,[urlEdPtr,]urlEdPtr,0
	beq	50$
	inc	r2L
;	lda	[r0]
	.byte	$a7,r0
	beq	50$
	jsr	JSLGetCharWidth
	rep	%00100000
	and	#[$00ff
	.byte	]$00ff
	clc
	adc	r11
	sta	r11
	inc	r0
	sep	%00100000
	bra	20$
 50$
	rts
