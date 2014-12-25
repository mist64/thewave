.output	System64	;name for output file.
.header	SysHdr64.rel	;name of file containing header block.
.vlir
.ramsect	$1000
.psect	$1800

WaveVars.rel		;jump table equates.
RamSect.rel		;resident ramsect variables.

.mod	1
.psect	LPrgBase
Prg2Jump.rel
PPP1Link.rel
PPP2Link.rel
TCPCode.rel
XYModem64.rel
HTTP64.rel
Telnet.rel

.mod	2
.psect	DOSBase
Dos1Stuff.rel
KrnlStuff64.rel

.mod	3
.psect	ParseHTML
Parse1HTM64.rel	;HTML parser routines.
Parse2HTM64.rel
Parse3HTM64.rel
Parse4HTM64.rel
UpperRam.rel		;ramsect variables for the parser.
