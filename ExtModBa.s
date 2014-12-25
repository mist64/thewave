;*********************************************
;
;
;	ExtModB
;
;	message routines and messages.
;
;*********************************************


	.psect



MsgRoutines:
	jmp	ER+JBrowseMsg-MsgRoutines
	jmp	ER+JClrMsgBox-MsgRoutines
	jmp	ER+JDoMsgDB-MsgRoutines
	jmp	ER+JDoDiskError-MsgRoutines
	jmp	ER+JDoSelBox-MsgRoutines

JBrowseMsg:
	stx	ER+msgNumber-MsgRoutines
	jsr	ER+SaveFont-MsgRoutines
	PushB	dispBufferOn
	LoadB	dispBufferOn,#ST_WR_FORE
	jsr	UseSystemFont
	LoadB	currentMode,#SET_PLAINTEXT
	jsr	ER+GetMsgLength-MsgRoutines
	jsr	ER+MsgBoxLocation-MsgRoutines
	jsr	ER+DrawMsgBox-MsgRoutines
	jsr	ER+R0ToMsg-MsgRoutines
	jsr	ER+ShowMsgString-MsgRoutines
	PopB	dispBufferOn
;fall through...
;this restores the 9 byte font table.
RstrFont:
	ldx	#8
 10$
	lda	ER+fontSave-MsgRoutines,x
	sta	fontTable,x
	dex
	bpl	10$
	rts

JClrMsgBox:
	PushB	dispBufferOn
	LoadB	dispBufferOn,#ST_WR_FORE
	lda	#0
	jsr	SetPattern
	jsr	ER+MsgBoxRegs-MsgRoutines
	jsr	Rectangle
	jsr	ConvToCards
	LoadW	r0,#ER+msgClrBuf-MsgRoutines
	jsr	RstrColor
	PopB	dispBufferOn
	rts

msgNumber:
	.block	1
msgLength:
	.block	2
;these next 4 must remain together.
msgBoxTop:
	.block	1
msgBoxBottom:
	.block	1
msgBoxLeft:
	.block	2
msgBoxRight:
	.block	2


GetMsgLength:
	jsr	ER+R0ToMsg-MsgRoutines
GetR0Length:
	ldy	#0
	sty	r1L
	sty	r1H
	sty	r2L
 10$
	ldy	r2L
	lda	(r0),y
	beq	80$
	jsr	GetCharWidth
	clc
	adc	r1L
	sta	r1L
	bcc	20$
	inc	r1H
 20$
	inc	r2L
	bne	10$	;branch always.
 80$
	MoveW	r1,ER+msgLength-MsgRoutines
	rts

R0ToMsg:
	ldx	ER+msgNumber-MsgRoutines
	lda	ER+msgLTable-MsgRoutines,x
	sta	r0L
	lda	ER+msgHTable-MsgRoutines,x
	sta	r0H
	rts

;this saves the 9 byte font table.
SaveFont:
	ldx	#8
 10$
	lda	fontTable,x
	sta	ER+fontSave-MsgRoutines,x
	dex
	bpl	10$
	rts


fontSave:
	.block	9


MsgBoxLocation:
	LoadB	ER+msgBoxTop-MsgRoutines,#168
	LoadB	ER+msgBoxBottom-MsgRoutines,#191
	lda	ER+msgLength+0-MsgRoutines
	and	#%11110000
	sta	r2L
	lda	ER+msgLength+1-MsgRoutines
	sta	r2H
	lsr	r2H
	ror	r2L
.if	C64
	sec
	lda	#140
	sbc	r2L
	and	#%11111000
	sta	ER+msgBoxLeft+0-MsgRoutines
	LoadB	ER+msgBoxLeft+1-MsgRoutines,#0
	clc
	lda	#171
	adc	r2L
	ora	#%00000111
	sta	ER+msgBoxRight+0-MsgRoutines
	lda	#0
	adc	#0
	sta	ER+msgBoxRight+1-MsgRoutines
.else
	sec
	lda	#[296
	sbc	r2L
	and	#%11111000
	sta	ER+msgBoxLeft+0-MsgRoutines
	lda	#]296
	sbc	r2H
	sta	ER+msgBoxLeft+1-MsgRoutines
	clc
	lda	#[327
	adc	r2L
	ora	#%00000111
	sta	ER+msgBoxRight+0-MsgRoutines
	lda	#]327
	adc	r2H
	sta	ER+msgBoxRight+1-MsgRoutines
.endif
	rts


DrawMsgBox:
	jsr	ER+MsgBoxRegs-MsgRoutines
	lda	#0
	jsr	SetPattern
	jsr	Rectangle
	lda	#%11111111
	jsr	FrameRectangle
	inc	r2L
	inc	r2L
	dec	r2H
	AddVW	#2,r3
	SubVW	#1,r4
	lda	#%11111111
	jsr	FrameRectangle
	jsr	ConvToCards
	LoadW	r0,#ER+msgClrBuf-MsgRoutines
	jsr	SaveColor
	MoveB	sysDBColor,r4H
	jmp	ColorRectangle

MsgBoxRegs:
	ldx	#5
 10$
	lda	ER+msgBoxTop-MsgRoutines,x
	sta	r2,x
	dex
	bpl	10$
	rts


ShowMsgString:
	LoadB	r1H,#184
ShowR1HString:
.if	C64
	lda	ER+msgLength+1-MsgRoutines
	lsr	a
	lda	ER+msgLength+0-MsgRoutines
	ror	a
	sta	r5L
	sec
	lda	#156
	sbc	r5L
	sta	r11L
	LoadB	r11H,#0
.else
	lda	ER+msgLength+1-MsgRoutines
	lsr	a
	sta	r5H
	lda	ER+msgLength+0-MsgRoutines
	ror	a
	sta	r5L
	sec
	lda	#[312
	sbc	r5L
	sta	r11L
	lda	#]312
	sbc	r5H
	sta	r11H
.endif
	jmp	PutString

msgLTable:
	.byte	[(ER+ldgPgStr-MsgRoutines)
msgHTable:
	.byte	](ER+ldgPgStr-MsgRoutines)

ldgPgStr:
	.byte	"Loading page...",0



msgClrBuf:
.if	C64
	.block	32*4
.else
	.block	64*4
.endif


JDoDiskError:
	txa
	beq	90$
	stx	ER+msgNumber-MsgRoutines
	LoadW	r0,#ER+dskErrTxt-MsgRoutines
	jsr	ER+Add1stMsg-MsgRoutines
	LoadW	r0,#ER+dskErrs-MsgRoutines
	jsr	ER+PntToMsg-MsgRoutines
	jsr	ER+Add2ndMsg-MsgRoutines
	lda	ER+msgNumber-MsgRoutines
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tax
	lda	ER+hexLookup-MsgRoutines,x
	sta	ER+dskNumTxt+1-MsgRoutines
	lda	ER+msgNumber-MsgRoutines
	and	#%00001111
	tax
	lda	ER+hexLookup-MsgRoutines,x
	sta	ER+dskNumTxt+2-MsgRoutines
	ldx	#1
	jsr	ER+DoMsgBox-MsgRoutines
	ldx	ER+msgNumber-MsgRoutines
 90$
	rts



Add1stMsg:
	MoveW	r0,ER+db1MsgPointer-MsgRoutines
	rts
Add2ndMsg:
	MoveW	r0,ER+db2MsgPointer-MsgRoutines
	rts

msgBox:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB
	.byte	DBTXTSTR,TXT_LN_X	,TXT_LN_2_Y
db1MsgPointer:
	.word	ER+dskErrTxt-MsgRoutines ;this changes.
	.byte	DBTXTSTR,TXT_LN_X	,TXT_LN_3_Y
db2MsgPointer:
	.word	ER+dskErrTxt-MsgRoutines ;this changes.
msg2IPointer:
	.byte	CANCEL,DBI_X_2,DBI_Y_2
msg0IPointer:
	.byte	YES,DBI_X_0,DBI_Y_2
msg1IPointer:
	.byte	NO,DBI_X_1,DBI_Y_2
nullMsg:
	.byte	0


PntToMsg:
 15$
;	lda	(r0)
	.byte	$b2,r0
	bmi	50$
	cmp	ER+msgNumber-MsgRoutines
	beq	50$
	jsr	ER+PntNxtMsg-MsgRoutines
	bra	15$
 50$
	ldy	#1
	jmp	ER+AddYR0-MsgRoutines

PntNxtMsg:
	ldy	#0
 30$
	iny
	lda	(r0),y
	bne	30$
	iny
;fall through...
AddYR0:
	tya
	clc
	adc	r0L
	sta	r0L
	bcc	15$
	inc	r0H
 15$
	rts



dskErrTxt:
	.byte	"Disk Error "
dskNumTxt:
	.byte	"$20",0 ;this changes.
hexLookup:
	.byte	"0123456789ABCDEF"

dskErrs:
	.byte	1,"Not enough blocks",0
	.byte	2,"Invalid track request",0
	.byte	3,"Insufficient space",0
	.byte	4,"Full Directory",0
	.byte	5,"File not found",0
	.byte	6,"Bad BAM",0
	.byte	7,"Unopened VLIR file",0
	.byte	8,"Invalid VLIR record",0
	.byte	9,"Out of VLIR records",0
	.byte	10,"File structure mismatch",0
	.byte	11,"Memory buffer overflow",0
	.byte	12,"Process cancelled",0
	.byte	13,"Device not found",0

	.byte	$20,"Sector header block missing",0
	.byte	$21,"No sync on track",0
	.byte	$23,"Bad sector data checksum",0
	.byte	$25,"Write verification failed",0
	.byte	$26,"Device is write protected",0
	.byte	$27,"Bad sector header checksum",0
	.byte	$29,"Disk ID mismatch",0
	.byte	$2e,"Bad byte decoding",0
	.byte	$73,"DOS mismatch",0

	.byte	$ff,"Unknown type",0

JDoMsgDB:
	stx	ER+msgNumber-MsgRoutines
	LoadW	r0,#ER+msg1Txt-MsgRoutines
	jsr	ER+PntToMsg-MsgRoutines
	jsr	ER+Add1stMsg-MsgRoutines
	LoadW	r0,#ER+msg2Txt-MsgRoutines
	jsr	ER+PntToMsg-MsgRoutines
	jsr	ER+Add2ndMsg-MsgRoutines
	ldx	ER+msgNumber-MsgRoutines
	lda	ER+msgIconTable-1-MsgRoutines,x
	tax
	;fall through...
DoMsgBox:
	lda	ER+sysDBSets+0-MsgRoutines,x
	sta	ER+msg0IPointer-MsgRoutines
	lda	ER+sysDBSets+1-MsgRoutines,x
	sta	ER+msg1IPointer-MsgRoutines
	lda	ER+sysDBSets+2-MsgRoutines,x
	sta	ER+msg2IPointer-MsgRoutines
	LoadW	r0,#ER+msgBox-MsgRoutines
	jsr	DoColorBox
	lda	r0L
	rts


sysDBSets:
	.byte	0,0,OK
	.byte	OK,0,CANCEL
	.byte	YES,NO,CANCEL
	.byte	YES,0,NO

msgIconTable:
	.byte	0,9

msg1Txt:
	.byte	1,"Memory low, unable to",0
	.byte	2,"Invalid HTML document.",0
	.byte	$ff,0
msg2Txt:
	.byte	1,"display complete page.",0
	.byte	2,"Display it anyway?",0
	.byte	$ff,0

