;*************************************************

;		TermEquates


;*************************************************

;if this changes, then the following must be reassembled:
;WaveVars,Main,PPPLink,TCPCode,AscTermB
;VT100,Prg2Jump
;Also change the debug value located in WaveVars.
debug=1

;$d280-$d283 in the protected ram is used for the
;fake SL addresses when the interface is not present.

;a0-a1L - used by routines that read in files.
;a2-a3L - used by PPP input routines.
;a6 - this may be used by any routine as a temporary
;  counter. If another routine is called, be sure to
;  check if that routine might also use this to prevent
;  any possible conflict.

;a5 is reserved for the modem interface only.

;a7L-a8L used for addressing into prgBank. a8L is
;set during startup to point to prgBank.
;a8H-a9H used for addressing into prg2Bank. a9H is
;set during startup to point to prg2Bank.
prg1=a7L
prg2=a8H

;amount of space reserved for the modem
;interface (SL/T232) driver.
COMM_SIZE=$900

;used by the browser.
ESC_STYLE=1
ESC_LMARGIN=2
ESC_RMARGIN=3
ESC_LSTMARGIN=4
ESC_NEWCARDSET=5
ESC_SETMODE=6
ESC_CLRMODE=7
ESC_ONANCHOR=8
ESC_OFFANCHOR=9
ESC_NMANCHOR=10

FONTBUFSIZE=$1200


;128 routine for updating the mouse pointer.
.if	C128
Soft80Handler==$e045
.endif

MENUON_BIT=6
intBotVector==$849f

;SuperCPU specific locations.
firstPage ==$d27c
firstBank ==$d27d
lastPage ==$d27e
lastBank ==$d27f
nmi16 ==$ffea


SOH =1
STX =2
EOT =4
ACK =6
XON =17
XOFF =19
NAK =21
CAN =24
SUB =26
ESC =27

;location of foreground screen.
.if	C64
fore_Screen	=$a000
.else
fore_Screen	=$0000
.endif

;used by the terminal
TOP_LINE=0
TLINEHEIGHT=8
NUMTERMLINES=25
BOT_LINE=TOP_LINE+(NUMTERMLINES*TLINEHEIGHT)-TLINEHEIGHT



;this page has equates for the PPP routines.

PAD_PROTOCOL=$0001
IP_PROTOCOL=$0021
NCP_PROTOCOL=$8021
LCP_PROTOCOL=$c021
PAP_PROTOCOL=$c023
LQR_PROTOCOL=$c025
CHAP_PROTOCOL=$c223

;lcp types
CONFREQUEST=1
CONFACK=2
CONFNAK=3
CONFREJECT=4
TERMREQUEST=5
TERMACK=6
CODEREJECT=7
PROTREJECT=8
ECHOREQUEST=9
ECHOREPLY=10
DISCARDREQUEST=11

;config request types.
MRU=1
ASYNCHMAP=2
AUTHPROTOCOL=3
QUALPROTOCOL=4
MAGICNUM=5
PROTCOMPRESS=7
ADDRCOMPRESS=8

PPP_FLAG=%01111110
PPP_ADDRESS=%11111111
PPP_CONTROL=%00000011
PPP_ESCAPE=%01111101

inBufPtr=a2

;IP protocol numbers:
PR_ICMP=1
PR_TCP=6

IPADDRREQUEST=3
PRIDNSREQUEST=129
SECDNSREQUEST=131


;port numbers, both local and remote.

TELNET_LOCAL=1
TELNET_REMOTE=23
HTTP_LOCAL=2
HTTP_REMOTE=80
DNS_LOCAL=3
DNS_REMOTE=53


;telnet equates

TSPEED=32
DM=242
EC=247
WILL=251
WONT=252
DO=253
DONT=254
IAC=255
SB=250
SE=240
