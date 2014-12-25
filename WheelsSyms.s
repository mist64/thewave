;****************************

;	WheelsSyms

;****************************


CPU_DDR==$0000
CPU_DATA==$0001

r0==$0002
r0L==r0
r0H==r0+1
r1==$0004
r1L==r1
r1H==r1+1
r2==$0006
r2L==r2
r2H==r2+1
r3==$0008
r3L==r3
r3H==r3+1
r4==$000a
r4L==r4
r4H==r4+1
r5==$000c
r5L==r5
r5H==r5+1
r6==$000e
r6L==r6
r6H==r6+1
r7==$0010
r7L==r7
r7H==r7+1
r8==$0012
r8L==r8
r8H==r8+1
r9==$0014
r9L==r9
r9H==r9+1
r10==$0016
r10L==r10
r10H==r10+1
r11==$0018
r11L==r11
r11H==r11+1
r12==$001a
r12L==r12
r12H==r12+1
r13==$001c
r13L==r13
r13H==r13+1
r14==$001e
r14L==r14
r14H==r14+1
r15==$0020
r15L==r15
r15H==r15+1

curPattern==$0022
string==$0024
fontTable==$0026	;9 bytes describing the current font.
baselineOffset==fontTable+0
curSetWidth==fontTable+1
curHeight==fontTable+3
curIndexTable==fontTable+4
cardDataPntr==fontTable+6
currentMode==fontTable+8
dispBufferOn==$002f
mouseOn==$0030
msePicPtr==$0031
windowTop==$0033
windowBottom==$0034
leftMargin==$0035
rightMargin==$0037
pressFlag==$0039
mouseXPos==$003a
mouseYPos==$003c
returnAddress==$003d

graphicsMode==$003f	;not used on 64.

;$4d-6f unused?

a2==$70
a2L==a2
a2H==a2+1
a3==$72
a3L==a3
a3H==a3+1
a4==$74
a4L==a4
a4H==a4+1
a5==$76
a5L==a5
a5H==a5+1
a6==$78
a6L==a6
a6H==a6+1
a7==$7a
a7L==a7
a7H==a7+1
a8==$7c
a8L==a8
a8H==a8+1
a9==$7e
a9L==a9
a9H==a9+1

;$80-$8f unused?

STATUS==$0090

;$91-$b9 unused?

curDevice==$00ba

;$bb-$fa unused?

a0==$fb
a0L==a0
a0H==a0+1
a1==$fd
a1L==a1
a1H==a1+1

;$ff unused?


irqvec==$0314
bkvec==$0316
nmivec==$0318
KR==$5000		;address where extended kernal loads.
PRINTBASE==$7900
diskBlkBuf==$8000
fileHeader==$8100
curDirHead==$8200
fileTrScTab==$8300
dirEntryBuf==$8400
DrACurDkNm==$841e	;18 bytes.
DrBCurDkNm==$8430	;18 bytes.
dataFileName==$8442	;17 bytes.
dataDiskName==$8453	;17 bytes.
PrntFilename==$8465
PrntDiskName==$8476	;19 bytes.
curDrive==$8489
diskOpenFlg==$848a
isGEOS==$848b
numDrives==$848d
driveType==$848e	;4 bytes.
turboFlags==$8492	;4 bytes.
curRecord==$8496
usedRecords==$8497
fileWritten==$8498
fileSize==$8499
appMain==$849b
mouseVector==$84a1
keyVector==$84a3
otherPressVec==$84a9
StringFaultVec==$84ab
RecoverVector==$84b1
selectionFlash==$84b3
alphaFlag==$84b4
iconSelFlag==$84b5
menuNumber==$84b7
mouseTop==$84b8
mouseBottom==$84b9
mouseLeft==$84ba
mouseRight==$84bc
stringX==$84be
stringY==$84c0
mousePicData==$84c1	;64 bytes.
keyData==$8504
mouseData==$8505
inputData==$8506
random==$850a	;2 bytes.
dblClickCount==$8515
year==$8516
month==$8517
day==$8518
hour==$8519
minutes==$851a
seconds==$851b
alarmSetFlag==$851c
sysDBData==$851d
screencolors==$851e
dlgBoxRamBuf==$851f	;378 bytes total saved here from various areas.
			;($851f-$8698)

getStrPointer==$87cf	;pointer to the next character in GetString buffer.
keyScanChar==$87ea	;character fetched during the last interrupt.
realWidth==$8807	;width of character being worked on.

dbIconTable==$880c	;68 bytes. DB icon table is built here.
dbRetAddress==$8853	;address pulled from the stack when DB is run.
numDBGFiles==$8856	;number of file for the filebox.
dbBoxLeft==$8857	;left side of dialogue box.
dbBoxTop==$8858	;top of dialogue box.
getFBufPtr==$8859	;copy of r5 when DBGETFILES is used in a DB.
topFName==$885b	;the top filename currently displayed in the box.
fNameSelected==$885c	;number of filename selected in DBGETFILES.

vlirDirTrack==$8861	;save track of VLIR directory block.
vlirDirSector==$8862	;save sector of VLIR directory block.
vlirDirEntry==$8863	;save pointer to VLIR dir entry within diskBlkBuf.
vlirTrack==$8865	;save track of VLIR index table.
vlirSector==$8866	;save sector of VLIR index table.
curCPUSpeed==$8867	;current speed of the SuperCPU. (New function)
dtDrive==$8868	;change in V3.0.
dtPartition==$8869
dtType==$886a
dtFound==$886b
dbDblFlag==$888a	;indicates doubling bit used in DB.
numDesktops==$88a6	;number of desktops in the list at $fe00, bank 0.
dblDBData==$88a7	;icon number used for double clicking
			;in the file requestor. Default is OPEN.
minKeyRepeat==$88b0	;minimum key repeat value during accel.
keyAccFlag==$88b1	;zero turns off key acceleration.
keyAccel==$88b2	;used during key acceleration.
keyRptCount==$88b3	;user defined key repeat delay.

;bit 7=time out, run the screensaver.
;bit 6=saver blocked, don't run it yet.
;bit 5=stop the timer.
;bit 4=timer off. Screensaver will never run.
;bits 2,3=unused.
;bit 1=if set then ignore mouse movement.
;bit 0=screensaver is running.
saverStatus==$88b4
saverTimer==$88b5	;time remaining before screensaver.
saverCount==$88b7	;user defined countdown to screensaver.
saverBank==$88b9	;bank in reu holding screensaver.
vdcRamType==$88ba	;bit7 1=64K VDC ram, 0=16K ram.
vdcClrMode==$88be		;used with 128 only.

driveData==$88bf	;not used by drivers. Maintained for
			;backwards compatibility.
ramExpSize==$88c3
sysRAMFlg==$88c4
firstBoot==$88c5
curType==$88c6
ramBase==$88c7	;not used by drivers. Maintained for
			;backwards compatibility.
inputDevName==$88cb	;17 bytes.
DrCCurDkNm==$88dc	;18 bytes.
DrDCurDkNm==$88ee	;18 bytes.
dir2Head==$8900	;for disk driver use only.
spr0pic==$8a00
spr1pic==$8a40
spr2pic==$8a80
spr3pic==$8ac0
spr4pic==$8b00
spr5pic==$8b40
spr6pic==$8b80
spr7pic==$8bc0
COLOR_MATRIX==$8c00	;1000 bytes. ($8c00-$8fe7)

DISK_BASE==$9000	;$9000-$9d7f Disk driver area.
Get1stDirEntry==$9030
GetNxtDirEntry==$9033
GetOffPgTS==$9036
SetLink==$9039
RdBlkDskBuf==$903c
WrBlkDskBuf==$903f
;SendTSBytes==$9042
CheckErrors==$9045
AllocateBlock==$9048
ReadLink==$904b
ddriveType==$904e
driverVersion==$904f


OpenRoot==$9050
OpenDirectory==$9053
GetBamBlock==$9056
PutBamBlock==$9059
dirHeadTrack==$905c
dirHeadSector==$905d
curBamBlock==$905e
lastBamByte==$905f
lastBamSector==$9060
bamAltered==$9061
highestTrack==$9062
GetHeadTS==$9063
PutHeadTS==$9066
GetLink==$9069
GetSysDirBlk==$906c
startBank==$906f
startPage==$9070
pagesUsed==$9071
cableType==$9073
ckdBrdrYet==$9074	;$ff means GetNxtDirEntry is working
			;in the system directory. (read only)
dir3Head==$9c80	;to be used by the disk drivers only.
			;It resides within each driver.
			;($9c80-$9d7f)

GetNewKernal==$9d80
RstrKernal==$9d83


mousePort==$9fd3
reuBank==$9fd4
reuPage==$9fd5

;the values here are restored to the SuperRAM
;so that the ram is deallocated when going to BASIC.
sFirstPage==$9fd6
sFirstBank==$9fd7
sLastPage==$9fd8
sLastBank==$9fd9

sysScrnColors==$9fda
sys80ScrnColors==$9fdb
sysMob0Clr==$9fdc
sysExtClr==$9fdd

sysBorder==$9fde
sys80Border==$9fdf
miscColor==$9fe0
sysDBColor==$9fe1
appDBColor==$9fe2
menuColor==$9fe3
backColor==$9fe4
backSysPattern==$9fe5	;8 byte system pattern.
ramExpType==$9fed
relayDelay==$9fee
modKeyCopy==$9ff0	;SHIFT,CMDR,CTRL key indicator.
extKrnlIn==$9ff1
dbFieldWidth==$9ff2
fftIndicator==$9ff3
;serialNumber==$9ff4
IntRoutine==$9ff6	;128 irq and nmi routine.
IrqRoutine=$9ffa	;64 irq routine.
nmiDefault==$9fff	;64 nmi routine.


version==$c00f
nationality==$c010
;0=USA
;1=Germany
;2=France
;3=Holland
;4=Italy
;5=Switzerland
;6=Spain
;7=Portugal
;8=Finland
;9=UK
;10=Norway
;11=Denmark
;12=Sweden

c128Flag==$c013
dateCopy==$c018


InterruptMain==$c100
InitProcesses==$c103
RestartProcess==$c106
EnableProcess==$c109
BlockProcess==$c10c
UnblockProcess==$c10f
FreezeProcess==$c112
UnfreezeProcess==$c115
HorizontalLine==$c118
InvertLine==$c11b
RecoverLine==$c11e
VerticalLine==$c121
Rectangle==$c124
FrameRectangle==$c127
InvertRectangle==$c12a
RecoverRectangle==$c12d
DrawLine==$c130
DrawPoint==$c133
GraphicsString==$c136
SetPattern==$c139
GetScanLine==$c13c
TestPoint==$c13f
BitmapUp==$c142
PutChar==$c145
PutString==$c148
UseSystemFont==$c14b
StartMouseMode==$c14e
DoMenu==$c151
RecoverMenu==$c154
RecoverAllMenus==$c157
DoIcons==$c15a
DShiftLeft==$c15d
BBMult==$c160
BMult==$c163
DMult==$c166
Ddiv==$c169
DSdiv==$c16c
Dabs==$c16f
Dnegate==$c172
Ddec==$c175
ClearRam==$c178
FillRam==$c17b
MoveData==$c17e
InitRam==$c181
PutDecimal==$c184
GetRandom==$c187
MouseUp==$c18a
MouseOff==$c18d
DoPreviousMenu==$c190
ReDoMenu==$c193
GetSerialNumber==$c196
Sleep==$c199
ClearMouseMode==$c19c

i_Rectangle==$c19f
i_FrameRectangle==$c1a2
i_RecoverRectangle==$c1a5
i_GraphicsString==$c1a8
i_BitmapUp==$c1ab
i_PutString==$c1ae
GetRealSize==$c1b1
i_FillRam==$c1b4
i_MoveData==$c1b7
GetString==$c1ba
GotoFirstMenu==$c1bd
InitTextPrompt==$c1c0
MainLoop==$c1c3
DrawSprite==$c1c6
GetCharWidth==$c1c9
LoadCharSet==$c1cc
PosSprite==$c1cf
EnablSprite==$c1d2
DisablSprite==$c1d5
CallRoutine==$c1d8
CalcBlksFree==$c1db
ChkDkGEOS==$c1de
NewDisk==$c1e1
GetBlock==$c1e4
PutBlock==$c1e7
SetGEOSDisk==$c1ea
SaveFile==$c1ed
SetGDirEntry==$c1f0
BldGDirEntry==$c1f3
GetFreeDirBlk==$c1f6
WriteFile==$c1f9
BlkAlloc==$c1fc
ReadFile==$c1ff
SmallPutChar==$c202
FollowChain==$c205
GetFile==$c208
FindFile==$c20b
CRC==$c20e
LdFile==$c211
EnterTurbo==$c214
LdDeskAcc==$c217
ReadBlock==$c21a
LdApplic==$c21d
WriteBlock==$c220
VerWriteBlock==$c223
FreeFile==$c226
GetFHdrInfo==$c229
EnterDeskTop==$c22c
StartAppl==$c22f
ExitTurbo==$c232
PurgeTurbo==$c235
DeleteFile==$c238
FindFTypes==$c23b

RstrAppl==$c23e
ToBasic==$c241
FastDelFile==$c244
GetDirHead==$c247
PutDirHead==$c24a
NxtBlkAlloc==$c24d
ImprintRectangle==$c250
i_ImprintRectangle==$c253
DoDlgBox==$c256
RenameFile==$c259
InitForIO==$c25c
DoneWithIO==$c25f
DShiftRight==$c262
CopyString==$c265
CopyFString==$c268
CmpString==$c26b
CmpFString==$c26e
FirstInit==$c271
OpenRecordFile==$c274
CloseRecordFile==$c277
NextRecord==$c27a
PreviousRecord==$c27d
PointRecord==$c280
DeleteRecord==$c283
InsertRecord==$c286
AppendRecord==$c289
ReadRecord==$c28c
WriteRecord==$c28f
SetNextFree==$c292
UpdateRecordFile==$c295
GetPtrCurDkNam==$c298
PromptOn==$c29b
PromptOff==$c29e
OpenDisk==$c2a1
DoInlineReturn==$c2a4
GetNextChar==$c2a7
BitmapClip==$c2aa
FindBAMBit==$c2ad
SetDevice==$c2b0
IsMseInRegion==$c2b3
ReadByte==$c2b6
FreeBlock==$c2b9
ChangeDiskDevice==$c2bc
RstrFrmDialog==$c2bf
Panic==$c2c2
BitOtherClip==$c2c5
StashRAM==$c2c8
FetchRAM==$c2cb
SwapRAM==$c2ce
VerifyRAM==$c2d1
DoRAMOp==$c2d4



TempHideMouse==$c2d7
SetMsePic==$c2da
SetNewMode==$c2dd
NormalizeX==$c2e0
MoveBData==$c2e3
SwapBData==$c2e6
VerifyBData==$c2e9
DoBOp==$c2ec
AccessCache==$c2ef
HideOnlyMouse==$c2f2
SetColorMode==$c2f5
ColorCard==$c2f8
ColorBox==$c2fb

InitMachine==$c2fe
GEOSOptimize==$c301
DEFOptimize==$c304
DoOptimize==$c307
NFindFTypes==$c30a
ReadXYPot==$c30d
MainIRQ==$c310
ColorRectangle==$c313
i_ColorRectangle==$c316
SaveColor==$c319
RstrColor==$c31c
ConvToCards==$c31f


;the following are specific to the SuperCPU.
optCheck==$d0b4	;bits 6 & 7, 00=GEOS, 11=DEFAULT.
switchCheck==$d0b5	;bit7=JiffyDos, 1=enabled, bit6=speed, 1=1mhz.
speedCheck==$d0b8	;software switch, bit7, 1=1mhz.
superCheck==$d0bc	;bit7, 0=SuperCPU present.
openSuperCPU==$d07e
closeSuperCPU==$d07f
optModes==$d074
optGEOS==$d074
OPTGEOSOFFSET=0
OPTDEFOFFSET=3
set1mhz==$d07a
set20mhz==$d07b


;these are I/O addresses.
rasreg==$d012
mobenble==$d015
grirq==$d019
grirqen==$d01a
extclr==$d020
mob0clr==$d027
mob1clr==$d028
CLKRATE==$d030
CIAICR=$dc0d 
cia2base==$dd00
C2CCRA=$dd02 
CI2ICR=$dd0d 
CI2CRA=$dd0e 
EXP_BASE==$df00

;special kernal routines within the $e000 jump table.
Conv80Color==$e08d


;mmu stuff

config==$ff00

;CBM kernal calls.
Second==$ff93
Tksa==$ff96
Chkin==$ffc6
Chkout==$ffc9
Chrin==$ffcf
Acptr==$ffa5
Ciout==$ffa8
Untalk==$ffab
Unlsn==$ffae
Listen==$ffb1
Talk==$ffb4
Close==$ffc3
Clrchn==$ffcc
Chrout==$ffd2
Clall==$ffe7


;these are addresses to routines that are in the extended
;kernal that get loaded in at $5000 in groups.

;group 0
GetRAMBam==$5000
PutRAMBam==$5003
AllocAllRAM==$5006
AllocRAMBlock==$5009
FreeRAMBlock==$500c
GetRAMInfo==$500f
RamBlkAlloc==$5012
RemoveDrive==$5015
SvRamDevice==$5018
DelRamDevice==$501b
RamDevInfo==$501e

;group 1
DevNumChange==$5000
SwapDrives==$5003

;group 2
NSetGEOSDisk==$5000
DBFormat==$5000+3
FormatDisk==$5000+6
DBEraseDisk==$5000+9
EraseDisk==$5000+12

;group 3
OReadFile==$5000

;group 4
OWriteFile==$5000

;group 5
ChgParType==$5000
ChPartition==$5000+3
ChSubdir==$5000+6
ChDiskDirectory==$5000+9
GetFEntries==$5000+12
TopDirectory==$5000+15
UpDirectory==$5000+18
DownDirectory==$5000+21
GoPartition==$5000+24
ChPartOnly==$5000+30
FindRamLink==$5000+39

;group 6
MakeDirectory==$5000
MakeSysDir==$5003

;group 7
ValDisk==$5000

;group 8
CopyDisk==$5000
TestCompatibility==$5003

;group 9
CopyFile==$5000

;group 10
NewDesktop==$5000
OEnterDesktop==$5003
InstallDriver==$5006
FindDesktop==$5009
FindAFile==$500c

;group 11
KToBasic==$5000

;these are system addresses within the REU.
;bank 0 addresses:
;these areas are used for saving variables and the screen while
;a system dialogue box is being run just in case a dialogue box
;is already being used.
dirBoxRamBuf==$b900	;378 bytes to save dlgBoxRamBuf.
dBoxVarBuf==dirBoxRamBuf+378 ;81 bytes to save the following:
			;dbIconTable,
			;dbRetAddress, dbStackPointer, numDBGFiles,
			;dbBoxLeft, dbBoxTop, getFBufPtr,
			;topFName, fNameSelected.
			;daRetAddress and daStackPointer are also
			;saved here so that they may be used for
			;temporary purposes.
;there are still 53 available bytes until dirScrnBuf.
dirScrnBuf==$bb00	;screen save area for the dir box.
			;2880 bytes used for the bitmap,
			;and 360 used for the color info.
			;(total area is 3240 bytes.)

;$c7a8-$cfff reserved.

;$c800-$fdff buffer used by disk copier and file copier.

dbGetBuf==$e080	;buffer for DBGETFILES.
			;(total area is 4335 bytes.)
			;(this allows for 255 * 17 character names.)

;$fe00-$feff used by self-installing desktops.

rlBlkBuf==$ff00	;used by the Ramlink routines when
			;working with cpu memory at $e000-$ffff.


;these are locations in the last bank (system bank) of ram.

;these are used with Wheels 64, not with Wheels 128.
prtHdrStorage==$f700	;print driver header stored here.
prtCodeStorage==$f800	;print driver code stored here.


