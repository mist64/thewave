;*************************************
;
;	Dos1Stuff
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


Dos1Stuff:

;ReadInDirectory:
	jmp	JReadInDirectory
;FindLFile:
	jmp	JFindLFile
;WrBigBuffer:
	jmp	JWrBigBuffer
;PutLongString:
	jmp	JPutLongString
;DoURLBar:
	jmp	JDoURLBar
;PutURLString:
	jmp	JPutURLString
;Byte2Ascii:
	jmp	JByte2Ascii
;SizeToDec:
	jmp	JSizeToDec
;RstTermScreen:
	jmp	JRstTermScreen
;SaveTxtScreen:
	jmp	JSaveTxtScreen
;RstrTxtScreen:
	jmp	JRstrTxtScreen
;DoURL2Left:
	jmp	JDoURL2Left
;DoURL2Right:
	jmp	JDoURL2Right
;URLBarMsg:
	jmp	JURLBarMsg
;URLEdFunction:
	jmp	JURLEdFunction
;ScrollScreen:
	jmp	JScrollScreen
;ScrUpRegion:
	jmp	JScrUpRegion
;ScrDnRegion:
	jmp	JScrDnRegion

;this will read in all the sectors of the current
;directory into dirBank. This can handle up to
;256 sectors which would contain more dir entries
;than the Dashboard can handle. OpenDisk must
;already have been called.
JReadInDirectory:
	LoadB	inBorder,#%00000000
;	lda	dirBank
	.byte	$af,[dirBank,]dirBank,0
	tax
	pha
	jsl	SClearBank,0
	PopB	r3L
	LoadB	r2L,#0
	sta	r2H
	jsl	SInitForIO,0
;+++use Get1stDirEntry here instead...
;	lda	curDirHead+1
	.byte	$af,[(curDirHead+1),](curDirHead+1),0
	sta	r1H
;	lda	curDirHead+0
	.byte	$af,[(curDirHead+0),](curDirHead+0),0
	beq	90$
	sta	r1L
 5$
	LoadW	r4,#diskBlkBuf
	LoadB	r5L,#0
 10$
	jsl	SReadBlock,0
	bne	90$
	ldy	#0
 20$
;	lda	[r4],y
	.byte	$b7,r4
;	sta	[r2],y
	.byte	$97,r2
	iny
	bne	20$
	inc	r2H
	beq	89$
	iny
;	lda	[r4],y
	.byte	$b7,r4
	sta	r1H
	dey
;	lda	[r4],y
	.byte	$b7,r4
	sta	r1L
	bne	10$
 30$
	bit	inBorder
	bmi	89$
	jsl	SDoneWithIO,0
	jsl	SGetOffPgTS,0	;find out if this is a geos disk.
	phx
	phy
	jsl	SInitForIO,0
	ply
	plx
	bne	89$	;branch if any error.
	tya		;so is it a geos disk?
	bne	89$	;branch if not.
	dec	r2H
	lda	#$00
	ldy	#1
;	sta	[r2],y
	.byte	$97,r2
	dey
;	sta	[r2],y
	.byte	$97,r2
	LoadB	inBorder,#%10000000
	inc	r2H
	bne	5$
 89$
	dec	r2H
 90$
	lda	#$ff
	ldy	#1
;	sta	[r2],y
	.byte	$97,r2
	dey
	ina
;	sta	[r2],y
	.byte	$97,r2
	jsl	SDoneWithIO,0
	rts

;this will search through the directory loaded
;into dirBank and find a file pointed at by r6-r7L.
;If the file is not found, a second search is made
;to look for the file ignoring the case of the
;characters. If the file is not found, x will
;contain FILE_NOT_FOUND. If an exact match is found,
;the carry will be set. If a match ignoring case is
;found, the carry will be clear.
;r5-r6L will return pointing to the page containing
;the dir block. The offset to the dir entry will
;be in y. r1L,r1H will point to the track and sector
;of the dir block on disk. The dir entry will also
;be copied to dirEntryBuf.
JFindLFile:
	LoadB	inBorder,#%00000000
	ldy	#15
 5$
;	lda	[r6],y
	.byte	$b7,r6
	sta	ckCaseString,y
	dey
	bpl	5$
	LoadB	r0H,#0
;	lda	dirBank
	.byte	$af,[dirBank,]dirBank,0
	sta	r1L
 10$
	LoadB	r0L,#2
 20$
;	lda	[r0]
	.byte	$a7,r0
	bpl	25$
	jsr	CkIfExact	;does this file match exactly?
	bcs	80$	;branch if so.
 25$
	clc
	lda	r0L
	adc	#32
	sta	r0L
	bcc	20$
	LoadB	r0L,#0
;	lda	[r0]
	.byte	$a7,r0	;last page of directory?
	bne	28$	;branch if not.
	ldy	#1
;	lda	[r0],y	
	.byte	$b7,r0
	bne	30$
	LoadB	inBorder,#%10000000 ;checking sysdir now.
 28$
	inc	r0H	;point to the next page.
	bne	10$	;branch always.
 30$
	LoadB	inBorder,#%00000000
	ldy	#15
 35$
	lda	ckCaseString,y
	and	#%01111111
	sta	ckCaseString,y
	dey
	bpl	35$
	LoadB	r0H,#0
 40$
	LoadB	r0L,#2
 50$
;	lda	[r0]
	.byte	$a7,r0
	bpl	55$
	jsr	CkAnyCase
	bcs	79$
 55$
	clc
	lda	r0L
	adc	#32
	sta	r0L
	bcc	50$
	LoadB	r0L,#0
;	lda	[r0]
	.byte	$a7,r0	;last page of directory?
	bne	70$
	ldy	#1
;	lda	[r0],y	
	.byte	$b7,r0
	bne	75$
	LoadB	inBorder,#%10000000
 70$
	inc	r0H	;point to the next page.
	bne	40$	;branch always.(maybe)
 75$
	ldx	#FILE_NOT_FOUND
	rts
 79$
	clc
 80$
	php
	LoadB	r5L,#0
	MoveB	r0H,r5H
	MoveB	r1L,r6L
	ldy	r0L
	ldx	#0
 85$
;	lda	[r5],y
	.byte	$b7,r5
;	sta	dirEntryBuf,x
	.byte	$9f,[dirEntryBuf,]dirEntryBuf,0
	iny
	inx
	cpx	#30
	bcc	85$
	ldy	r0L
	ldx	#0
	plp
	rts


CkIfExact:
	ldy	#3
 10$
;	lda	[r0],y
	.byte	$b7,r0
	beq	50$
	cmp	#$a0
	beq	50$
	cmp	ckCaseString-3,y
	bne	90$
	iny
	cpy	#19
	bcc	10$
 50$
	lda	ckCaseString-3,y
	bne	90$
	sec
	rts
 90$
	clc
	rts


CkAnyCase:
	ldy	#3
 10$
;	lda	[r0],y
	.byte	$b7,r0
	beq	80$
	cmp	#$a0
	beq	80$
	cmp	ckCaseString-3,y
	beq	70$
	cmp	#'A'
	bcc	90$
	cmp	#'Z'+1
	bcs	40$
	ora	#%00100000
	cmp	ckCaseString-3,y
	beq	70$
	clc
	rts
 40$
	cmp	#'a'
	bcc	90$
	cmp	#'z'+1
	bcs	90$
	and	#%01011111
	cmp	ckCaseString-3,y
	bne	90$
 70$
	iny
	cpy	#19
	bcc	10$
	rts
 80$
	lda	ckCaseString-3,y
	bne	90$
	sec
	rts
 90$
	clc
	rts

inBorder:
	.block	1
ckCaseString:
	.block	17


;point r0-r1L to a filename.
;point a0-a1L to start of buffer.
;load r2-r3L with number of bytes.
;this will then create a file on disk
;in the current directory and then
;it will write the buffer to the file.
JWrBigBuffer:
	MoveW	r2,a2
	MoveB	r3L,a3L
	jsr	OpenWrBuf
	lda	a2L
	ora	a2H
	ora	a3L
	beq	40$
 10$
;	lda	[a0]
	.byte	$a7,a0
	jsr	WriteByte
	inc	a0L
	bne	30$
	inc	a0H
	bne	30$
	ldx	a1L
	jsl	SGetNxtBank,0
	bcc	40$
	stx	a1L
 30$
	jsr	DecA2A3L
	bne	10$
 40$
;	lda	diskBlkBuf+0
	.byte	$af,[(diskBlkBuf+0),](diskBlkBuf+0),0
	sta	r1L
;	lda	diskBlkBuf+1
	.byte	$af,[(diskBlkBuf+1),](diskBlkBuf+1),0
	sta	r1H
	lda	#0
;	sta	diskBlkBuf+0
	.byte	$8f,[(diskBlkBuf+0),](diskBlkBuf+0),0
	ldy	nxtByte
	dey
	tya
;	sta	diskBlkBuf+1
	.byte	$8f,[(diskBlkBuf+1),](diskBlkBuf+1),0
	LoadW	r4,#diskBlkBuf
	jsl	SPutBlock,0
	inc	testEntBuf+28
	bne	60$
	inc	testEntBuf+29
 60$
	jmp	ClsWrBuf


DecA2A3L:
	lda	a2L
	bne	65$
	lda	a2H
	bne	60$
	dec	a3L
 60$
	dec	a2H
 65$
	dec	a2L
	bne	70$
	lda	a2L
	ora	a2H
	ora	a3L
 70$
	rts

WriteByte:
	ldx	nxtByte
	beq	20$
;	sta	diskBlkBuf,x
	.byte	$9f,[diskBlkBuf,]diskBlkBuf,0
	inc	nxtByte
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
	lda	r3L
;	sta	diskBlkBuf+0
	.byte	$8f,[(diskBlkBuf+0),](diskBlkBuf+0),0
	lda	r3H
;	sta	diskBlkBuf+1
	.byte	$8f,[(diskBlkBuf+1),](diskBlkBuf+1),0
	LoadW	r4,#diskBlkBuf
	jsl	SPutBlock,0
	inc	testEntBuf+28
	bne	40$
	inc	testEntBuf+29
 40$
	pla
;	sta	diskBlkBuf+2
	.byte	$8f,[(diskBlkBuf+2),](diskBlkBuf+2),0
	ldy	#3
	sty	nxtByte
	rts


OpenWrBuf:
	ldx	#29
	lda	#0
 10$
	sta	testEntBuf,x
	dex
	bpl	10$
	LoadB	testEntBuf+0,#($80|PRG)
	ldy	#0
 20$
;	lda	[r0],y
	.byte	$b7,r0
	beq	30$
	sta	testEntBuf+3,y
	iny
	cpy	#16
	bcc	20$
	bcs	40$
 30$
	lda	#$a0
 35$
	sta	testEntBuf+3,y
	iny
	cpy	#16
	bcc	35$
 40$
	ldx	#0
 50$
;	lda	year,x
	.byte	$bf,[year,]year,0
	sta	testEntBuf+23,x
	inx
	cpx	#5
	bcc	50$
	jsl	SOpenDisk,0
	LoadW	r2,#254
	LoadW	r6,#fileTrScTab
	jsl	SBlkAlloc,0
	lda	r3L
;	sta	diskBlkBuf+0
	.byte	$8f,[(diskBlkBuf+0),](diskBlkBuf+0),0
	sta	testEntBuf+1
	lda	r3H
;	sta	diskBlkBuf+1
	.byte	$8f,[(diskBlkBuf+1),](diskBlkBuf+1),0
	sta	testEntBuf+2
	ldy	#2
	sty	nxtByte
	rts

nxtByte:
	.block	1
testEntBuf:
	.block	30

ClsWrBuf:
	LoadB	r10L,#0
	jsl	SGetFreeDirBlk,0
	tyx
	ldy	#0
 50$
	lda	testEntBuf,y
;	sta	diskBlkBuf,x
	.byte	$9f,[diskBlkBuf,]diskBlkBuf,0
	inx
	iny
	cpy	#30
	bcc	50$
	jsl	SPutBlock,0
	jsl	SPutDirHead,0
	rts

