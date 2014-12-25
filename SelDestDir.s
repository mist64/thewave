;************************************************************

;		SelDestDir


;************************************************************


	.psect


SelDestDir:
 10$
	jsr	OpenDesDir
	jsr	ER+SetSubRIcon-FReqRoutines
.if	C64
	LoadW	mouseXPos,#100
.else
	LoadW	mouseXPos,#200
.endif
	LoadB	mouseYPos,#110
	jsr	ER+SetRDrvIcons-FReqRoutines
	LoadW	r0,#ER+destDrvDBTable-FReqRoutines
	jsr	DoColorBox
	cmp	#30
	beq	10$
	cmp	#CANCEL
	beq	90$
	ldx	#2
	jsr	SetNewDir	;make this the new dest dir.
	sec
	rts
 90$
	clc
	rts


SetSubRIcon:
	jsr	ER+CkSubDCapable-FReqRoutines
	sta	ER+subRelOK-FReqRoutines
	rts

subRelOK:
	.block	1

;DB table:
destDrvDBTable:
	.byte	DEF_DB_POS
	.byte	DB_USR_ROUT
	.word	FrameDB
	.byte	DBTXTSTR,16,16
	.word	ER+slctTxt-FReqRoutines
	.byte	OK,2,72
	.byte	CANCEL,16,72
	.byte	DBUSRICON,2,22
	.word	ER+AInfoTable-FReqRoutines
	.byte	DBUSRICON,2,34
	.word	ER+BInfoTable-FReqRoutines
	.byte	DBUSRICON,2,46
	.word	ER+CInfoTable-FReqRoutines
	.byte	DBUSRICON,2,58
	.word	ER+DInfoTable-FReqRoutines
	.byte	DB_USR_ROUT
	.word	ER+SetAppM4-FReqRoutines
	.byte	DBUSRICON,9,72
	.word	ER+subDTable-FReqRoutines
	.byte	0


CkSubDCapable:
	lda	curType
	and	#%00001111
	cmp	#DRV_NATIVE
	beq	50$
	lda	curType
	cmp	#RAM_1581
	bne	40$
	lda	cableType
	bpl	60$
	bmi	50$
 40$
	and	#%11110000
	beq	60$
	cmp	#(TYPE_RL+$10)
	bcs	60$
 50$
	lda	#DBUSRICON
	rts
 60$
	lda	#0
	rts


subDTable:
	.word	ER+subDirPic-FReqRoutines
.if	C64
	.byte	0,0,6,16
.else
	.byte	0,0,6|DOUBLE_B,16
.endif
	.word	ER+SubDSelected-FReqRoutines

subDirPic:


SubDSelected:
	lda	ER+subRelOK-FReqRoutines
	bne	50$
	rts
 50$
	jsr	ER+ChUserDirectory-FReqRoutines
	ldx	#2
	jsr	SetNewDir
	LoadB	sysDBData,#30
	jmp	RstrFrmDialog

ChUserDirectory:
	lda	#(5|64)
	jsr	GetNewKernal
	jsr	ChDiskDirectory
	jmp	RstrKernal


;this forces the OS to help set up the
;DB instead of adding a routine in the
;DB table to do it.
SetAppM4:
	LoadW	appMain,#ER+AppMain4-FReqRoutines
	rts

AppMain4:
	lda	#0
	sta	appMain+1
	sta	appMain+0
	sta	iconSelFlag
	jsr	ER+DBDiskNames-FReqRoutines
	jsr	ER+MarkRelDrive-FReqRoutines
	jmp	ER+PutSubIcon-FReqRoutines


SetRDrvIcons:
	PushB	curDrive
	ldx	#8
 10$
	phx
	lda	ER+relLTable-8-FReqRoutines,x
	sta	r0L
	lda	ER+relHTable-8-FReqRoutines,x
	sta	r0H
	ldy	#0
	tya
	sta	(r0),y
	iny
	sta	(r0),y
	txa
	jsr	SetDevice
	bne	50$
	ldy	#0
	lda	#[(ER+rectglPic-FReqRoutines)
	sta	(r0),y
	iny
	lda	#](ER+rectglPic-FReqRoutines)
	sta	(r0),y
 50$
	plx
	inx
	cpx	#12
	bcc	10$
	pla
	jmp	SetDevice

relLTable:
	.byte	[(ER+AInfoTable-FReqRoutines)
	.byte	[(ER+BInfoTable-FReqRoutines)
	.byte	[(ER+CInfoTable-FReqRoutines)
	.byte	[(ER+DInfoTable-FReqRoutines)
relHTable:
	.byte	](ER+AInfoTable-FReqRoutines)
	.byte	](ER+BInfoTable-FReqRoutines)
	.byte	](ER+CInfoTable-FReqRoutines)
	.byte	](ER+DInfoTable-FReqRoutines)


DBDiskNames:
	PushB	curDrive
	lda	#8
 10$
	pha
	jsr	SetDevice
	bne	50$
	jsr	ER+PutDiskName-FReqRoutines
 50$
	pla
	ina
	cmp	#12
	bcc	10$
	pla
	jmp	SetDevice

PutDiskName:
	ldx	#r0
	jsr	GetPtrCurDkNm
	jsr	ER+EndDiskName-FReqRoutines
	LoadW	r0,#ER+selDName-FReqRoutines
	lda	curDrive
	sec
	sbc	#8
	asl	a
	asl	a
	sta	r1H
	asl	a
	clc
	adc	r1H
	adc	#62
	sta	r1H
.if	C64
	LoadW	r11,#103
.else
	LoadW	r11,#206
.endif
	jsr	PutString
	MoveW	r11,r3
.if	C64
	LoadW	r4,#253
.else
	LoadW	r4,#510
.endif
	sec
	lda	r1H
	sbc	#7
	sta	r2L
	clc
	adc	#9
	sta	r2H
	lda	#0
	jsr	SetPattern
	jmp	Rectangle

selDName:
	.block	17

AInfoTable:
	.word	ER+rectglPic-FReqRoutines
	.byte	0,0
.if	C64
	.byte	2,10
.else
	.byte	2|DOUBLE_B,10
.endif
	.word	ER+ADrvClicked-FReqRoutines

BInfoTable:
	.word	ER+rectglPic-FReqRoutines
	.byte	0,0
.if	C64
	.byte	2,10
.else
	.byte	2|DOUBLE_B,10
.endif
	.word	ER+BDrvClicked-FReqRoutines

CInfoTable:
	.word	ER+rectglPic-FReqRoutines
	.byte	0,0
.if	C64
	.byte	2,10
.else
	.byte	2|DOUBLE_B,10
.endif
	.word	ER+CDrvClicked-FReqRoutines

DInfoTable:
	.word	ER+rectglPic-FReqRoutines
	.byte	0,0
.if	C64
	.byte	2,10
.else
	.byte	2|DOUBLE_B,10
.endif
	.word	ER+DDrvClicked-FReqRoutines

;an icon picture. This is a 10 pixel
;framed rectangle.
rectglPic:
	.byte	$02,$ff,$90,$80,$01,$80
	.byte	$01,$80,$01,$80,$01,$80
	.byte	$01,$80,$01,$80,$01,$80
	.byte	$01,$02,$ff


ADrvClicked:
	lda	#8
	.byte	44
BDrvClicked:
	lda	#9
	.byte	44
CDrvClicked:
	lda	#10
	.byte	44
DDrvClicked:
	lda	#11
	cmp	desDrive
	bne	50$
	rts
 50$
	sta	desDrive
	jsr	ER+MarkRelDrive-FReqRoutines
	lda	desDrive
	jsr	SetDevice
	jsr	OpenDisk
	ldx	#2
	jsr	SetNewDir
	jsr	ER+PutDiskName-FReqRoutines
PutSubIcon:
	jsr	ER+SetSubRIcon-FReqRoutines
	lda	ER+subRelOK-FReqRoutines
	bne	60$
	lda	#0
	jsr	SetPattern
	LoadB	r2L,#(DEF_DB_TOP+72)
	LoadB	r2H,#(DEF_DB_TOP+87)
.if	C64
	LoadW	r3,#(DEF_DB_LEFT+(9*8))
	LoadW	r4,#(DEF_DB_LEFT+(9*8)+47)
.else
	LoadW	r3,#(DEF_DB_LEFT+(9*8))*2
	LoadW	r4,#((DEF_DB_LEFT+(9*8)+47)*2)+1
.endif
	jmp	Rectangle
 60$
	LoadW	r0,#ER+subDirPic-FReqRoutines
	LoadB	r1H,#(DEF_DB_TOP+72)
	LoadB	r2H,#16
.if	C64
	LoadB	r1L,#((DEF_DB_LEFT/8)+9)
	LoadB	r2L,#6
.else
	LoadB	r1L,#((DEF_DB_LEFT/8)+9)*2
	LoadB	r2L,#6|DOUBLE_B
.endif
	jmp	BitmapUp


MarkRelDrive:
	lda	#0
	jsr	SetPattern
	LoadB	ER+curDrvCount-FReqRoutines,#3
.if	C64
	LoadW	r3,#81
	LoadW	r4,#94
.else
	LoadW	r3,#161
	LoadW	r4,#190
.endif
 10$
	ldx	ER+curDrvCount-FReqRoutines
	lda	ER+topDTable-FReqRoutines,x
	sta	r2L
	lda	ER+botDTable-FReqRoutines,x
	sta	r2H
	jsr	Rectangle
	dec	ER+curDrvCount-FReqRoutines
	bpl	10$

	lda	#1
	jsr	SetPattern
	lda	desDrive
	sec
	sbc	#8
	asl	a
	asl	a
	sta	r2L
	asl	a
	clc
	adc	r2L
	adc	#55
	sta	r2L
	adc	#7
	sta	r2H
	jmp	Rectangle	;draw a black square.

curDrvCount:
	.block	1
topDTable:
	.byte	55,67,79,91
botDTable:
	.byte	62,74,86,98


;this will copy the disk name to selDName and
;null terminate it.
EndDiskName:
	ldy	#0
 10$
	lda	(r0),y
	beq	80$
	cmp	#$a0
	beq	80$
	sta	ER+selDName-FReqRoutines,y
	iny
	cpy	#16
	bcc	10$
 80$
	lda	#0
	sta	ER+selDName-FReqRoutines,y
	rts

slctTxt:
	.byte	BOLDON,"Select Destination Drive:",PLAINTEXT,0


endFReq:

