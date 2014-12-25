;*************************************************

;		WaveVars


;*************************************************

debug=1

;VERSLETTER=='B'
;VERSMAJOR=='2'
;VERSMINOR=='7'

VERSLETTER=='V'
VERSMAJOR=='1'
VERSMINOR=='0'

;128 irq routines are located at IRQ128 in both 128 banks.
IRQ128==$0400

;SwiftLink/T232 driver begins at COMM_BASE.
COMM_BASE==$0500

InitComm==COMM_BASE
IsSLThere==InitComm+3
OnDTR==IsSLThere+3
OnRTS==OnDTR+3
SetDataBits==OnRTS+3
SetParity==SetDataBits+3
SetStopBits==SetParity+3
SetBPS==SetStopBits+3
OffDTR==SetBPS+3
OffRTS==OffDTR+3
Send1Byte==OffRTS+3
Recv1Byte==Send1Byte+3
SendMulBytes==Recv1Byte+3
RecvMulBytes==SendMulBytes+3
CkSend==RecvMulBytes+3
CkRecv==CkSend+3
OnBreak==CkRecv+3
OffBreak==OnBreak+3
MoveNMICode==OffBreak+3
SetNMIInterrupts==MoveNMICode+3
RstrNMIInterrupts==SetNMIInterrupts+3
OnNMIReceive==RstrNMIInterrupts+3
OffNMIReceive==OnNMIReceive+3
CheckDCD==OffNMIReceive+3
SendPPPFrame==CheckDCD+3

COMMJMPSIZE==25	;number of jump table entries in the driver.


ModemTable==$1800
WaveInit==ModemTable
OpenModem==WaveInit+3
CloseModem==OpenModem+3
InitIORecv==CloseModem+3
DoneIORecv==InitIORecv+3
GetBufByte==DoneIORecv+3
GetTCPByte==GetBufByte+3
PutTCPByte==GetTCPByte+3
GetFrmBuf==PutTCPByte+3
OnTimer==GetFrmBuf+3
On16Timer==OnTimer+3
OffTimer==On16Timer+3
CkTimer==OffTimer+3
Disconnect==CkTimer+3
DefSLSettings==Disconnect+3

defVtOn==DefSLSettings+3
defAnsiOn==defVtOn+1
defBaudRate==defAnsiOn+1
defDataBits==defBaudRate+1
defParity==defDataBits+1
defStopBits==defParity+1
defSLAddress==defStopBits+1	;2 bytes.


MainTable==$2300

DoBrowser==MainTable
ReDoBrowser==DoBrowser+3
ESelProtocol==ReDoBrowser+3
EDoSelBox==ESelProtocol+3
EDoMdmSettings==EDoSelBox+3
CkAbortKey==EDoMdmSettings+3
FullMouse==CkAbortKey+3
FullMargins==FullMouse+3
ClearScreen==FullMargins+3
HideScreen==ClearScreen+3
GrayScreen==HideScreen+3
SetBrdrColor==GrayScreen+3
SuperSwap==SetBrdrColor+3
DoBeep==SuperSwap+3
GoXPartition==DoBeep+3
SetSaveColor==GoXPartition+3
SetRstrColor==SetSaveColor+3
PattScreen==SetRstrColor+3
FrameDB==PattScreen+3
DoColorBox==FrameDB+3
GetNxtBank==DoColorBox+3
NxtBank==GetNxtBank+3
GetNewBank==NxtBank+3
GetPrevBank==GetNewBank+3
FreeBnkChain==GetPrevBank+3
FreeBank==FreeBnkChain+3
ClearBank==FreeBank+3
ImprintScreen==ClearBank+3
OpnPrgFile==ImprintScreen+3
OpnSysFile==OpnPrgFile+3
OpenPrgDir==OpnSysFile+3
OpenSrcDir==OpenPrgDir+3
OpenDesDir==OpenSrcDir+3
OpenSavDir==OpenDesDir+3
OpenURLDir==OpenSavDir+3
OpenCurDir==OpenURLDir+3
SetNewDir==OpenCurDir+3
SvDefaults==SetNewDir+3
SysScrColor==SvDefaults+3
ColrR4H==SysScrColor+3
SetNxtDrive==ColrR4H+3
Set1stDrive==SetNxtDrive+3
ClearTop==Set1stDrive+3
ClearBTop==ClearTop+3
ClearBWindow==ClearBTop+3
LoadAscii==ClearBWindow+3
DoSuperMove==LoadAscii+3
SaveSRamVars==DoSuperMove+3
FtchSRamVars==SaveSRamVars+3
DecTo32==FtchSRamVars+3
HexTo32==DecTo32+3
D32div==HexTo32+3
Mult24==D32div+3
Mult32==Mult24+3
ExitWave==Mult32+3

InitScrBar==ExitWave+3
PosScrBar==InitScrBar+3
ReadReg==PosScrBar+3
WriteReg==ReadReg+3
MoveVData==WriteReg+3
iMoveVData==MoveVData+3
ClearVRam==iMoveVData+3
FillVRam==ClearVRam+3
iFillVRam==FillVRam+3
StashVRam==iFillVRam+3
FetchVRam==StashVRam+3
PokeVRam==FetchVRam+3
PeekVRam==PokeVRam+3
OTempHideMouse==PeekVRam+3

SCkAbortKey==OTempHideMouse+3
SFullMargins==SCkAbortKey+3
SGetNxtBank==SFullMargins+3
SNxtBank==SGetNxtBank+3
SGetNewBank==SNxtBank+3
SFreeBnkChain==SGetNewBank+3
SFreeBank==SFreeBnkChain+3
SClearBank==SFreeBank+3
SClearBWindow==SClearBank+3
SDoSuperMove==SClearBWindow+3
SDecTo32==SDoSuperMove+3
SHexTo32==SDecTo32+3
SD32div==SHexTo32+3
SMult24==SD32div+3
SMult32==SMult24+3

SMoveVData==SMult32+3
SStashVRam==SMoveVData+3
SFetchVRam==SStashVRam+3

;routines within the SLDriver
SCkRecv==SFetchVRam+3
SCheckDCD==SCkRecv+3

;routines within the modem driver.
SOpenModem==SCheckDCD+3
SDefSLSettings==SOpenModem+3

SHorizontalLine==SDefSLSettings+3
SRectangle==SHorizontalLine+3
SFrameRectangle==SRectangle+3
SSetPattern==SFrameRectangle+3
SPutChar==SSetPattern+3
SUseSystemFont==SPutChar+3
SBBMult==SUseSystemFont+3
SBMult==SBBMult+3
SDMult==SBMult+3
SDdiv==SDMult+3
SDabs==SDdiv+3
SDnegate==SDabs+3
SMoveData==SDnegate+3
SGetRandom==SMoveData+3
SMouseUp==SGetRandom+3
SMouseOff==SMouseUp+3
SGetRealSize==SMouseOff+3
SInitTextPrompt==SGetRealSize+3
SLoadCharSet==SInitTextPrompt+3
SPutBlock==SLoadCharSet+3
SGetFreeDirBlk==SPutBlock+3
SBlkAlloc==SGetFreeDirBlk+3
SReadFile==SBlkAlloc+3
SEnterTurbo==SReadFile+3
SReadBlock==SEnterTurbo+3
SGetDirHead==SReadBlock+3
SPutDirHead==SGetDirHead+3
SInitForIO==SPutDirHead+3
SDoneWithIO==SInitForIO+3
SSetNextFree==SDoneWithIO+3
SPrmptOn==SSetNextFree+3
SPrmptOff==SPrmptOn+3
SOpenDisk==SPrmptOff+3
STempHideMouse==SOpenDisk+3
SColorRectangle==STempHideMouse+3
SConvToCards==SColorRectangle+3
SGetOffPgTS==SConvToCards+3
SRdBlkDskBuf==SGetOffPgTS+3
SWrBlkDskBuf==SRdBlkDskBuf+3
SReadLink==SWrBlkDskBuf+3

SSendPPPFrame==SReadLink+3
SDisconnect==SSendPPPFrame+3
SFetchFSegment==SDisconnect+3


;table of addresses for access into extended module code.
SwIf80==SFetchFSegment+3
DoDeskAccessories==SwIf80+3
DoApplication==DoDeskAccessories+3
XModSend==DoApplication+3
XModRecv==XModSend+3
SelProtocol==XModRecv+3
SvHTMLBuffer==SelProtocol+3
DownHTTP==SvHTMLBuffer+3
GetWrDocument==DownHTTP+3
GetNonGEOS==GetWrDocument+3
GetAnyFile==GetNonGEOS+3
GetAppFile==GetAnyFile+3
GetDAFile==GetAppFile+3

BrowseMsg==GetDAFile+3
ClrMsgBox==BrowseMsg+3
DoMsgDB==ClrMsgBox+3
DoDiskError==DoMsgDB+3
DoSelBox==DoDiskError+3

ISPDir==DoSelBox+3
BBSDir==ISPDir+3
InetSession==BBSDir+3
BeginISP==InetSession+3
DoTrmMode==BeginISP+3

;table of addresses for calling extended routines
;from an upper bank.
SSwIf80==DoTrmMode+3
SDoDeskAccessories==SSwIf80+3
SDoApplication==SDoDeskAccessories+3
SXModSend==SDoApplication+3
SXModRecv==SXModSend+3
SSelProtocol==SXModRecv+3
SSvHTMLBuffer==SSelProtocol+3
SDownHTTP==SSvHTMLBuffer+3
SGetWrDocument==SDownHTTP+3
SGetNonGEOS==SGetWrDocument+3
SGetAnyFile==SGetNonGEOS+3
SGetAppFile==SGetAnyFile+3
SGetDAFile==SGetAppFile+3

SBrowseMsg==SGetDAFile+3
SClrMsgBox==SBrowseMsg+3
SDoMsgDB==SClrMsgBox+3
SDoDiskError==SDoMsgDB+3
SDoSelBox==SDoDiskError+3

SISPDir==SDoSelBox+3
SBBSDir==SISPDir+3
SInetSession==SBBSDir+3
SBeginISP==SInetSession+3
SDoTrmMode==SBeginISP+3

LParseHTML==SDoTrmMode+3
LDialOut==LParseHTML+4
LPPPLinkUp==LDialOut+4
LSndTrmRequest==LPPPLinkUp+4
LLdTCPBlock==LSndTrmRequest+4
LOutTCPBuffer==LLdTCPBlock+4
LOpnTCPConnection==LOutTCPBuffer+4
LClsTCPConnection==LOpnTCPConnection+4
LReslvAddress==LClsTCPConnection+4
LSepHREFString==LReslvAddress+4
LStartHTTP==LSepHREFString+4

LDoIACMode==LStartHTTP+4
LInitTNVars==LDoIACMode+4

LSendXModem==LInitTNVars+4
LRecvXModem==LSendXModem+4
LSendYModem==LRecvXModem+4
LRecvYModem==LSendYModem+4
LSendZModem==LRecvYModem+4
LRecvZModem==LSendZModem+4

LReadInDirectory==LRecvZModem+4
LFindLFile==LReadInDirectory+4
LWrBigBuffer==LFindLFile+4
LPutLongString==LWrBigBuffer+4
LDoURLBar==LPutLongString+4
LPutURLString==LDoURLBar+4
LByte2Ascii==LPutURLString+4
LSizeToDec==LByte2Ascii+4
LRstTermScreen==LSizeToDec+4
LSaveTxtScreen==LRstTermScreen+4
LRstrTxtScreen==LSaveTxtScreen+4
LDoURL2Left==LRstrTxtScreen+4
LDoURL2Right==LDoURL2Left+4
LURLBarMsg==LDoURL2Right+4
LURLEdFunction==LURLBarMsg+4
LScrollScreen==LURLEdFunction+4
LScrUpRegion==LScrollScreen+4
LScrDnRegion==LScrUpRegion+4

LAddrTo32Bits==LScrDnRegion+4


LCurFrRegs==LAddrTo32Bits+4
LFrRegs==LCurFrRegs+4
LCurFrHeight==LFrRegs+4
LFrHeight==LCurFrHeight+4
LCurFrBottom==LFrHeight+4
LFrBottom==LCurFrBottom+4
LCurFrWidth==LFrBottom+4
LFrWidth==LCurFrWidth+4
LCurFrDimensions==LFrWidth+4
LFrDimensions==LCurFrDimensions+4
LGetCurFrame==LFrDimensions+4
LGetFrame==LGetCurFrame+4
LGetDesFont==LGetFrame+4

.if	debug
LWriteDebug==LGetDesFont+4
LInitDebug==LWriteDebug+4
;jsl'd from other banks to call a routine quickly.
FSmallPutChar==LInitDebug+4
.else
FSmallPutChar==LGetDesFont+4
.endif

FCkAbortKey==FSmallPutChar+4
FGetFrmBuf==FCkAbortKey+4
FGetBufByte==FGetFrmBuf+4
FSend1Byte==FGetBufByte+4
FGetTCPByte==FSend1Byte+4
FPutTCPByte==FGetTCPByte+4
FOnTimer==FPutTCPByte+4
FCkTimer==FOnTimer+4
FGetCharWidth==FCkTimer+4

;table of routine addresses for the resident
;routines stored in prgBank.
ExtTable==(ModemTable-COMM_BASE) ;currently $1300

ER==$4000		;location in bank 0 where a routine
			;gets loaded from prgBank.

;used by file transfer routines and anything
;else that needs a buffer while transfers
;aren't taking place. This is located in prg2Bank.
xModBuffer==$e000	;1024 byte buffer.

;located in prg2Bank.
;these occupy $ec00-efff.
urlString==$ec00	;256 bytes.
hrefString==urlString+256	;256 bytes.

prtclField==hrefString+256	;16 bytes.
dmnNmField==prtclField+16	;48 bytes.
pathField==dmnNmField+48	;160 bytes.
anchNmField==pathField+160	;32 bytes.

;+++this must always follow the url fields.
urlFldSave==prtclField+256	;256 bytes for temp storage of url fields.


;1792 byte buffer for incoming PPP packets,
;located in prg2Bank.
pppInBuffer==$f000

;1792 byte buffer for outgoing PPP packets,
;located in prg2Bank.
pppOutBuffer==$f700

;data is moved from the incoming tcp packet
;to this buffer in prg2Bank. Individual bytes may
;then be pulled from this buffer.
tcpInBuf==$fe00

;data is placed in this buffer in prg2Bank prior
;to assembling a tcp packet to be sent out.
tcpOutBuf==$ff00

;modules that are loaded into prgBank will immediately follow
;the extended code. The location is determined at boot time.
ModBase==$3500	;location in bank 0 where modules get loaded.

;jump table within the browser code.
StartBrowser==ModBase
ReStartBrowser==StartBrowser+3
FetchFSegment==ReStartBrowser+3


;jump tables within prg2Bank.
LPrgBase==$0100

DOSBase==$4000
ReadInDirectory==DOSBase
FindLFile==ReadInDirectory+3
WrBigBuffer==FindLFile+3
PutLongString==WrBigBuffer+3
DoURLBar==PutLongString+3
PutURLString==DoURLBar+3
Byte2Ascii==PutURLString+3
SizeToDec==Byte2Ascii+3
RstTermScreen==SizeToDec+3
SaveTxtScreen==RstTermScreen+3
RstrTxtScreen==SaveTxtScreen+3
DoURL2Left==RstrTxtScreen+3
DoURL2Right==DoURL2Left+3
URLBarMsg==DoURL2Right+3
URLEdFunction==URLBarMsg+3
ScrollScreen==URLEdFunction+3
ScrUpRegion==ScrollScreen+3
ScrDnRegion==ScrUpRegion+3

ParseHTML==$5000
CurFrRegs==ParseHTML+3
FrRegs==CurFrRegs+3
CurFrHeight==FrRegs+3
FrHeight==CurFrHeight+3
CurFrBottom==FrHeight+3
FrBottom==CurFrBottom+3
CurFrWidth==FrBottom+3
FrWidth==CurFrWidth+3
CurFrDimensions==FrWidth+3
FrDimensions==CurFrDimensions+3
GetCurFrame==FrDimensions+3
GetFrame==GetCurFrame+3
GetDesFont==GetFrame+3

;current browser or terminal font buffer in bank 0.
fontBase==$5000
;buffer for upper ansi set in terminal.
ansiBuffer==(fontBase+$0400)
vtExtraBuffer==(ansiBuffer+$0400)
buf8859==(vtExtraBuffer+$0400)

