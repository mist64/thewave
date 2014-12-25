;**************************************

;	Prg2Jump

;**************************************

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

LBankJmpTable:
;LParseHTML:
	jsr	ParseHTML
	rtl
;LDialOut:
	jsr	JDialOut
	rtl
;LPPPLinkUp:
	jsr	JPPPLinkUp
	rtl
;LSndTrmRequest:
	jsr	JSndTrmRequest
	rtl
;LLdTCPBlock:
	jsr	JLdTCPBlock
	rtl
;LOutTCPBuffer:
	jsr	JOutTCPBuffer
	rtl
;LOpnTCPConnection:
	jsr	JOpnTCPConnection
	rtl
;LClsTCPConnection:
	jsr	JClsTCPConnection
	rtl
;LReslvAddress:
	jsr	JReslvAddress
	rtl
;LSepHREFString:
	jsr	JSepHREFString
	rtl
;LStartHTTP:
	jsr	JStartHTTP
	rtl
;LDoIACMode:
	jsr	JDoIACMode
	rtl
;LInitTNVars:
	jsr	JInitTNVars
	rtl

;LSendXModem:
	jsr	JSendXModem
	rtl
;LRecvXModem:
	jsr	JRecvXModem
	rtl
;LSendYModem:
	jsr	JSendYModem
	rtl
;LRecvYModem:
	jsr	JRecvYModem
	rtl
;LSendZModem:
	jsr	JSendZModem
	rtl
;LRecvZModem:
	jsr	JRecvZModem
	rtl


;LReadInDirectory:
	jsr	ReadInDirectory
	rtl
;LFindLFile:
	jsr	FindLFile
	rtl
;LWrBigBuffer:
	jsr	WrBigBuffer
	rtl
;LPutLongString:
	jsr	PutLongString
	rtl
;LDoURLBar:
	jsr	DoURLBar
	rtl
;LPutURLString:
	jsr	PutURLString
	rtl
;LByte2Ascii:
	jsr	Byte2Ascii
	rtl
;LSizeToDec:
	jsr	SizeToDec
	rtl
;LRstTermScreen:
	jsr	RstTermScreen
	rtl
;LSaveTxtScreen:
	jsr	SaveTxtScreen
	rtl
;LRstrTxtScreen:
	jsr	RstrTxtScreen
	rtl
;LDoURL2Left:
	jsr	DoURL2Left
	rtl
;LDoURL2Right:
	jsr	DoURL2Right
	rtl
;LURLBarMsg:
	jsr	URLBarMsg
	rtl
;LURLEdFunction:
	jsr	URLEdFunction
	rtl

;LScrollScreen:
	jsr	ScrollScreen
	rtl
;LScrUpRegion:
	jsr	ScrUpRegion
	rtl
;LScrDnRegion:
	jsr	ScrDnRegion
	rtl

;LAddrTo32Bits:
	jsr	JAddrTo32Bits
	rtl

;LCurFrRegs:
	jsr	CurFrRegs
	rtl
;LFrRegs:
	jsr	FrRegs
	rtl
;LCurFrHeight:
	jsr	CurFrHeight
	rtl
;LFrHeight:
	jsr	FrHeight
	rtl
;LCurFrBottom:
	jsr	CurFrBottom
	rtl
;LFrBottom:
	jsr	FrBottom
	rtl
;LCurFrWidth:
	jsr	CurFrWidth
	rtl
;LFrWidth:
	jsr	FrWidth
	rtl

;LCurFrDimensions:
	jsr	CurFrDimensions
	rtl
;LFrDimensions:
	jsr	FrDimensions
	rtl
;LGetCurFrame:
	jsr	GetCurFrame
	rtl
;LGetFrame:
	jsr	GetFrame
	rtl

;LGetDesFont:
	jsr	GetDesFont
	rtl

.if	debug
;LWriteDebug:
	jsr	WriteDebug
	rtl
;LInitDebug:
	jsr	InitDebug
	rtl
.endif


;reserved area for additions to the jump table.
	.block	30*4

;variable area for PPP, TCP, XYModem, etc.

;if the tcp receive window should remain at full
;capacity, clear bit 7. If it should count down as
;data comes in, set bit 7. This is used when downloading
;files through http. OpnTCPConnection automatically
;clears bit 7. If bit 7 is to be set, it should be
;set after the TCP connection is opened. The calling
;routine should then maintain the bit until the
;connection is closed.
rcvWndwFlag:
	.block	1

