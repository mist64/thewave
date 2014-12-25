;******************************************

;	UpperRam

;	this is a ramsect area that resides in
;	the program bank.

;******************************************

	.ramsect

gLeftMargin:
	.block	2
gRightMargin:
	.block	2
globalJust:
	.block	1
;bit7 set means currently in <HEAD> area. Bit6 set means
;currently in <BODY> area.
htmlMode:
	.block	1
stuffOnScreen:
	.block	1
crsrY:
	.block	1
;+++this will hold the TITLE if found.
titleString:
	.block	40
lastRdChar:
	.block	1
tallestBaseline:
	.block	1
tallestHeight:
	.block	1
marginWidth:
	.block	2
textInString:
	.block	1
textStrPtr:
	.block	1
textStrLength:
	.block	2
lastPutChar:
	.block	1
charWaiting:
	.block	1
ignoreWrap:
	.block	1
spacePtr:
	.block	1
lastSpcLength:
	.block	2
waitForPrintable:
	.block	1
textString:
	.block	256
justification:
	.block	1	;0 = left justified.
			;1 = centered
			;2 = right justified.
			;3 = full justified. (not supported yet)

lhtmlByte:
	.block	3
htmlCount:
	.block	1
headCount:
	.block	1
bodyCount:
	.block	1
scriptCount:
	.block	1
desFSize:
	.block	1
desISOType:
	.block	1
curISOType:
	.block	1
desFntNum:
	.block	1

stackPointer:
	.block	32

curAttrNum:
	.block	1
signByte:
	.block	1
delimiter:
	.block	1
bqMode:
	.block	1
italicMode:
	.block	1
ulineMode:
	.block	1
boldMode:
	.block	1
anchorMode:
	.block	1
hdlnMode:
	.block	1
centerMode:
	.block	1
listMode:
	.block	1
olNumber:
	.block	1
listMargin:
	.block	2

;these 128 bytes must remain together.
tableRegs:

tableMode:
	.block	1
trMode:
	.block	1
tdMode:
	.block	1
tblClmCounter:
	.block	1
rowTop:
	.block	3
rowBottom:
	.block	3
numTblColumns:
	.block	1
defClmWidth:
	.block	2
maxCellRight:
	.block	2

	.block	31	;reserved.

;room for up to 40 cells horizontally.
tableLeft:
	.block	2	;also location of the leftmost cell.
	.block	78
tableRight:
	.block	2	;also right side of rightmost cell.


captionMode:
	.block	1
tfontMode:
	.block	1
ttMode:
	.block	1
preMode:
	.block	1
addressMode:
	.block	1

;when a string is defined for an attribute,
;it gets copied here for the tag routine to
;access.
attrString:
	.block	256

curTagNum:
	.block	1	;number of tag. 255 means unknown tag.
tagMode:
	.block	1	;bit7 set means closing tag.

tagStack:
	.block	18*256

curTable:
	.block	2
tableStack:
	.block	8*128	;room for 8 embedded tables.

endUpRam:
