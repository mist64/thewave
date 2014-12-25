;************************************************************

;		RamSect


;************************************************************

	.ramsect

sramVars:

;SwiftLink/T232 stuff:

recvVector:
	.block	2	;this is set by the main program.
xOutMode:
	.block	1	;bit 7 set if XOFF.
			;bit 6 clear means to ignore XON,XOFF bytes.

;bit7 set indicates a Turbo232.
;bit6 set indicates a SwiftLink.
slT232Flag:
	.block	1
bpsRate:
	.block	1	;default is 38,400 bps.
dataBits:
	.block	1	;default is 8 data bits.
parityBit:
	.block	1	;default is no parity.
stopBits:
	.block	1	;default is 1 stop bit.
dtrStatus:
	.block	1
dcdStatus:
	.block	1
nmiSet:
	.block	1


modemOpen:
	.block	1	;bit7 set means OpenModem has successfully
			;been called. If clear, the modem is not
			;ready for access.

;used primarily with null-modem connections.
ignoreDCD:
	.block	1

;bit 7 set indicates dialed out to network. Clear means
;either not dialed out or dialed out to normal BBS type.
commMode:
	.block	1
phDirMode:
	.block	1
keyPadMode:
	.block	1
tcpInStart:
	.block	1
tcpInEnd:
	.block	1
tcpOutEnd:
	.block	1

tcpOpen:
	.block	1

;this is the protocol determined after examining
;a URL string. e.g. "http:" or "telnet:". It's also
;possible to find "file:" or "A:", etc.
;0=no protocol in the string.
;1=telnet
;2=http
;3=dns
;4=file
;'A'=drive A. Etc. for other drives.
prtclFound:
	.block	1
;if a drive letter was found in the protocol
;field, then this will hold the partition number
;found.
partnFound:
	.block	1

sysFileVersion:
	.block	4

hostName:
	.block	33


;these are loaded in from each phone file.
ispNumber:
	.block	33
desBaudRate:
	.block	1
desDataBits:
	.block	1
desParity:
	.block	1
desStopBits:
	.block	1
userName:
	.block	33
userPassword:
	.block	33
manualLogin:
	.block	1
desDNSPrimary:
	.block	4
desDNSSecondary:
	.block	4

;+++these next 6 bytes must remain together.
vtOn:
	.block	1
ansiOn:
	.block	1
desProtocol:
	.block	1	;0=ascii,1=xmodem,2=xmodem-crc
			;3=xmodem-1k,4=ymodem,5=ymodem-g
			;6=zmodem,7=kermit
autoProtocol:
	.block	1	;bit7 set means auto-detect is on.
ignoreTimeouts:
	.block	1	;bit7 set ignore timeouts in protocols.

;the value here can be 8,127, or 255. If 255, then use the
;telnet "erase character" sequence of IAC,EC but only if in
;telnet mode. If 255 exists in any other mode, then use 8.
deleteValue:
	.block	1


;+++these are used only for debugging.
debugEnd:
	.block	2
inModBuf:
	.block	2
inModBank:
	.block	1
appMain3Save:
	.block	2
cmdrOOpened:
	.block	1



slAddress:
	.block	2	;this is copied to slBase when restarting.

globalBPSRate:
	.block	1

curVtOn:
	.block	1

;this indicates the current browser or terminal
;that is running. Bit 7 set means a browser is
;running. Bits 0-3 indicate the number of the
;current browser or terminal. Bit 6 clear means
;a transition is occuring and neither a terminal
;nor a browser is currently running.
waveRunning:
	.block	1

tmAppMain:
	.block	2

appMTable:
	.block	16

watchMOffset:
	.block	1
dispInOffset:
	.block	1
ckOnTOffset:
	.block	1
flushOffset:
	.block	1


;the variables on this page must remain in this order.

;set bit 3 for BOLD text.
ansiBold:
	.block	1
;the current foreground color in use.
ansiFGColor:
	.block	1
;the current background color in use.
ansiBGColor:
	.block	1
cursorX:
	.block	2
cursorY:
	.block	1
topScrlLine:
	.block	1
botScrlLine:
	.block	1


sBold:
	.block	1
sFGColor:
	.block	1
sBGColor:
	.block	1
scursorX:
	.block	2
scursorY:
	.block	1
stopScrlLine:
	.block	1
sbotScrlLine:
	.block	1

;this identifies if the terminal has been
;run at least once yet so it knows if it should
;be initialized or restored.
termRunYet:
	.block	1



charSetUsed:
	.block	1	;bit7 indicates which character set
			;is currently running in the terminal.
			;0=lower ascii set.
			;1=upper ascii set.
			;bit6 indicates translation mode.
			;0=ansi translation
			;1=vt100 translation.
useG3Set:
	.block	1
nxtChar:
	.block	1
charCount:
	.block	1
sCrsrX:
	.block	2
sCrsrY:
	.block	1
sCharSUsed:
	.block	1
sUseG3Set:
	.block	1
sAnsiBold:
	.block	1
sAnsiFGColor:
	.block	1
sAnsiBGColor:
	.block	1
sCurrentMode:
	.block	1


;bit 7 set means the URL bar editor is running
;and the cursor is blinking.
urlEdRunning:
	.block	1
;current character within the url buffer that cursor
;is blinking on.
urlEdPtr:
	.block	1

;offset to first character appearing in the url bar.
urlBufPtr:
	.block	1

svpageLoaded:
	.block	1
pathPtr:
	.block	1
subPathName:
	.block	18

localEcho:
	.block	1

prgName:
	.block	17

curModule:
	.block	1

stBank:
	.block	1

gwFileFlag:
	.block	1

dirBank:
	.block	1
;these reference the directory that is
;currently loaded into dirBank.
dirBnkDrv:
	.block	1
dirBnkPart:
	.block	1
dirBnkTrack:
	.block	1
dirBnkSector:
	.block	1
dirBnkName:
	.block	18

sramPartition:
	.block	1
sramSize:
	.block	1

prgBank:
	.block	1
prg2Bank:
	.block	1
bufBank:
	.block	1
termBank:
	.block	1
fontBank:
	.block	1
anchorBank:
	.block	1
linkBank:
	.block	1
htmlBank:
	.block	1
pageBank:
	.block	1

endSBank:
	.block	1
ssFirstPage:
	.block	4

numScrFonts:
	.block	1
numFonts:
	.block	1
fListPtr:
	.block	2	;pointer to the list of font names.
fDataPtr:
	.block	2	;pointer to the font data.
fEndData:
	.block	2	;end of font data.


termBufPtr:
	.block	2	;buffer pointer within termBank.

mainTReturn:
	.block	2
mainTStack:
	.block	2
crsrRunning:
	.block	1


ffeaSave:
	.block	2	;native nmi vector saved here.
ffeeSave:
	.block	2	;native irq vector saved here.
ffea128Save:
	.block	2	;used only with the 128.
ffee128Save:
	.block	2	;used only with the 128.

brwsOthPress:
	.block	2
brwsKeyVector:
	.block	2


modRmTable:
	.block	8	;table is built at startup.
			;its size is the number of bank 0 modules
			;times 2, plus 2.

bankBAM:
	.block	256

;bit 7 set means a page is in memory. If bit 6 is clear,
;it's from a local file, otherwise it's from the network.
pageLoaded:
	.block	1

;bit 7 set means to force a download of the http link
;to disk instead of loading it into memory for display. Bit 6
;set means the http routines failed to find "Content-Type: text/"
;in one of the header fields.
;bits 0 and 1:
;00 = auto determine whether to show as-is or to render html.
;01 = show only ascii text as-is.
;10 = force parser to render as html.
;11 = force parser to view http header.
dloadFlag:
	.block	1

baseFntSize:
	.block	1

curOpenDir:
	.block	1
prgDrive:
	.block	1
srcDrive:
	.block	1
desDrive:
	.block	1
savDrive:
	.block	1
urlDrive:
	.block	1
presDrive:
	.block	1
prgPart:
	.block	1
srcPart:
	.block	1
desPart:
	.block	1
savPart:
	.block	1
urlPart:
	.block	1
presPart:
	.block	1
prgTrack:
	.block	1
srcTrack:
	.block	1
desTrack:
	.block	1
savTrack:
	.block	1
urlTrack:
	.block	1
presTrack:
	.block	1
prgSector:
	.block	1
srcSector:
	.block	1
desSector:
	.block	1
savSector:
	.block	1
urlSector:
	.block	1
presSector:
	.block	1

bWinTop:
	.block	1	;top line of browser window.

curPageTop:
	.block	3
endPageTop:
	.block	3
curPageBottom:
	.block	3

htmlSize:
	.block	3

numFrames:
	.block	1
curFrame:
	.block	1
frTopTable:
	.block	16
frBotTable:
	.block	16
frLLeftTable:
	.block	16
frHLeftTable:
	.block	16
frLRightTable:
	.block	16
frHRightTable:
	.block	16

;these 6 must remain together.
frmWidth:
	.block	2
frmTop:
	.block	1
frmBottom:
	.block	1
frmLeft:
	.block	2
frmRight:
	.block	2
frmHeight:
	.block	1

;this is the scrollbar table for the current scrollbar being
;used. The routine calling InitScrBar passes these values from
;a table pointed at by r0.
scrBarTable:
	.block	1	;the first byte indicates what to do.
			;if bit 7 is set, draw the scrollbar.
			;if cleared, then clear the scrollbar.
;this is the screen position for the top of the scrollbar area.
;this is also the highest position the movable part of the
;scrollbar can be moved to.
scrAreaTop:
	.block	1
;this is the bottom of the area where the scrollbar travels.
scrAreaBottom:
	.block	1
;this is the screen position for the left of the scrollbar area.
scrAreaLeft:
	.block	2
scrAreaRight:
	.block	2
;left card where scroll arrows are placed.
scrArwLeft:
	.block	1
;top pixel where scroll arrows are placed.
scrArwTop:
	.block	1
;this is the amount of movement the scrollbar can represent. For instance,
;if the text can be scrolled up and down 1500 lines from top to bottom,
;that is the value stored here.
scrBarVolume:
	.block	3
;this is the current location within the scrBarVolume area that the
;position of the scrollbar represents. In other words, if the scrollbar
;is halfway down its travel, the user will be looking at the halfway
;point of the text or whatever is being scrolled.
scrBarLocation:
	.block	3
;this is the amount of visible area that the scrollbar represents. This
;is used to determine the height of the movable part of the scrollbar.
scrBarSegment:
	.block	1

;the following are routines to call if the mouse is clicked
;on various areas of the scrollbar and scroll arrows.
scrollRoutines:
scrOnRoutine:
	.block	2	;call if clicked directly on scrollbar
			;and if scrollbar is moved.
scrAbvRoutine:
	.block	2	;call if clicked above scrollbar.
scrBlwRoutine:
	.block	2	;call if clicked below scrollbar.
scrUpRoutine:
	.block	2	;call if up arrow clicked.
scrDnRoutine:
	.block	2	;call if down arrow clicked.
app1MnRoutine:	;routine to run during appMain
	.block	2	;if scrollbar not clicked on.
app2MnRoutine:	;routine to run during appMain
	.block	2	;after scrollbar was clicked on.

;InitScrBar calculates the variables in this part of the table
;based on the values placed in the scrollbar table.
;this is the vertical height of the area where the scrollbar travels.
scrAreaHeight:
	.block	1
;this is the height of the movable part of the scrollbar.
scrBarHeight:
	.block	1

;this is the current position of the top of the moving part of the scrollbar.
scrBarTop:
	.block	1
;this is the lowest point on the screen that the top of the
;scrollbar can be moved to.
scrBarBottom:
	.block	1

scrArrsTop:
	.block	1
scrArrsBottom:
	.block	1
scrArrsLeft:
	.block	2
scrArrsRight:
	.block	2


;when the mouse is clicked anywhere on the screen, its location
;is saved here immediately. This value can be checked in case the
;mouse has moved before the routine has a chance to run.
mouseXClick:
	.block	2
mouseYClick:
	.block	1

rcvrSave:
	.block	2	;save RecoverVector here.

xFileName:
	.block	17
reqFileName:
	.block	17
deskName:
	.block	16

;colors for area where menu drops is saved here.
mColor:
	.block	952

endOfRamsect:

